import re
import trafilatura
import json

from google import genai
from google.genai import types
from app.core.config import settings
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception
from app.core.exceptions import (
    AIServiceError,
    AIQuotaExceededError,
    AIContentBlockedError,
    AIEmptyResponseError,
    AISchemaValidationError,
    InsufficientContentError,
)
from pydantic import ValidationError
from app.schemas.ai import ArticleSummary


client = genai.Client(api_key=settings.GEMINI_API_KEY)

STYLE_PROMPTS = {
    "bullet": "Rédige 3 à 4 points clés factuels et concis.",
    "journalistic": "Rédige 3 à 4 points au ton journalistique neutre, phrases complètes et fluides.",
    "simple": "Rédige 3 à 4 points en langage simple, accessible à quelqu'un qui découvre le sujet.",
}


def clean_html(text: str) -> str:
    """Retire les balises HTML et normalise les espaces."""
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def fetch_full_text(url: str) -> str | None:
    """
    Récupère le texte principal d'une page web, sans pub ni menus.
    Usage éphémère uniquement — jamais stocké ni affiché tel quel,
    sert uniquement de matière première au résumé IA.
    """
    try:
        downloaded = trafilatura.fetch_url(url, no_ssl=True)
        if not downloaded:
            return None
        text = trafilatura.extract(
            downloaded,
            include_comments=False,
            include_tables=False,
        )
        return text
    except Exception:
        return None


def should_retry(exception) -> bool:
    """
    Ne retente pas si le quota est dépassé ou le contenu bloqué.
    Retente sur les erreurs transitoires (timeout, 5xx).
    """
    if isinstance(exception, (AIQuotaExceededError, AIContentBlockedError)):
        return False
    return True


def _classify_gemini_error(exception: Exception) -> AIServiceError:
    """Traduit une erreur brute de l'API en exception métier typée."""
    msg = str(exception)

    if "429" in msg or "RESOURCE_EXHAUSTED" in msg:
        return AIQuotaExceededError("Quota API Gemini dépassé")

    if "SAFETY" in msg.upper() or "blocked" in msg.lower():
        return AIContentBlockedError("Contenu bloqué par les filtres de sécurité")

    return AIServiceError(f"Erreur Gemini: {msg}")


@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    retry=retry_if_exception(should_retry),
    reraise=True,
)
def _call_gemini(prompt: str) -> ArticleSummary:
    """
    Appelle Gemini en mode sortie structurée.
    Retourne un objet validé par Pydantic, jamais du texte brut.
    """
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                max_output_tokens=3000,
                response_mime_type="application/json",
                response_schema=ArticleSummary,
            ),
        )
    except Exception as e:
        typed_error = _classify_gemini_error(e)
        print(f"🔥 {type(typed_error).__name__}: {typed_error}")
        raise typed_error from e

    if not response.text:
        raise AIEmptyResponseError("Réponse vide de Gemini")

    # Validation stricte du schéma — rien de non conforme n'entre en base
    try:
        return ArticleSummary.model_validate_json(response.text)
    except ValidationError as e:
        raise AISchemaValidationError(f"Schéma invalide: {e}") from e
    except json.JSONDecodeError as e:
        raise AISchemaValidationError(f"JSON malformé: {e}") from e


def generate_summary(
    title: str,
    content: str | None,
    url: str,
    style: str,
) -> tuple[str, int | None]:
    """
    Retourne (résumé, nombre de mots du texte source).
    Le word_count vaut None si on n'a pas pu récupérer le texte complet.
    """
    instruction = STYLE_PROMPTS.get(style, STYLE_PROMPTS["bullet"])

    cleaned_content = clean_html(content or "")
    full_text = fetch_full_text(url)

    # On ne compte les mots que si l'extraction complète a réussi
    word_count = None
    if full_text and len(full_text.strip()) > 300:
        source_text = full_text
        word_count = len(full_text.split())
    else:
        source_text = cleaned_content

    excerpt = source_text[:4000]

    if not excerpt.strip():
        raise InsufficientContentError("Contenu source insuffisant")

    prompt = f"""Voici un article de presse.

Titre: {title}
Contenu: {excerpt}

{instruction}

Contraintes:
- Base-toi UNIQUEMENT sur le contenu fourni ci-dessus.
- Reformule entièrement avec tes propres mots, ne copie jamais de phrases du texte.
- Chaque point doit être une phrase complète.
- Indique "high" si le contenu source est riche, "medium" s'il est partiel, "low" s'il est très pauvre."""

    summary = _call_gemini(prompt)

    return summary.to_display_text(), word_count