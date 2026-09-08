import re
import trafilatura

from google import genai
from google.genai import types
from app.core.config import settings
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception
from app.core.exceptions import (
    AIServiceError,
    AIQuotaExceededError,
    AIContentBlockedError,
    AIEmptyResponseError,
    InsufficientContentError,
)

client = genai.Client(api_key=settings.GEMINI_API_KEY)

STYLE_PROMPTS = {
    "bullet": "Rédige un résumé en 3-4 points, chaque point commençant par •. Ne mets pas de phrase d'introduction ni de conclusion.",
    "journalistic": "Rédige un résumé fluide de 3-4 phrases, ton journalistique neutre. Pas d'intro, pas de conclusion.",
    "simple": "Rédige une explication simple en 3-4 phrases, pour quelqu'un qui découvre le sujet. Pas d'intro, pas de conclusion.",
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
def _call_gemini(prompt: str) -> str:
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                max_output_tokens=3000,
            ),
        )
    except Exception as e:
        typed_error = _classify_gemini_error(e)
        print(f"🔥 {type(typed_error).__name__}: {typed_error}")
        raise typed_error from e

    text = response.text
    if not text:
        raise AIEmptyResponseError("Réponse vide de Gemini")

    return text.strip()


def _clean_summary(raw: str) -> str:
    """
    Nettoie la sortie brute de Gemini :
    retire l'intro, normalise les puces markdown, supprime les lignes orphelines.
    """
    lines = raw.split("\n")
    cleaned_lines = []
    started = False

    for line in lines:
        stripped = line.strip()
        # On commence à garder dès la première puce rencontrée
        if stripped.startswith(("*", "•", "-")):
            started = True
        if started and stripped:
            cleaned_lines.append(line)

    # Si aucune puce trouvée (styles journalistic / simple), on garde le texte tel quel
    if cleaned_lines:
        raw = "\n".join(cleaned_lines)

    # Normalise les puces markdown en puces propres
    raw = re.sub(r'^\s*[\*\-]\s+', '• ', raw, flags=re.MULTILINE)

    # Supprime les lignes ne contenant qu'une puce orpheline
    raw = re.sub(r'^\s*[•\*\-]\s*$', '', raw, flags=re.MULTILINE)

    # Réduit les sauts de ligne multiples
    raw = re.sub(r'\n{3,}', '\n\n', raw)

    return raw.strip()


def generate_summary(title: str, content: str | None, url: str, style: str) -> str:
    instruction = STYLE_PROMPTS.get(style, STYLE_PROMPTS["bullet"])

    # Nettoyage HTML du contenu RSS
    cleaned_content = clean_html(content or "")

    # Tente d'abord de récupérer le texte complet de la page
    full_text = fetch_full_text(url)

    # Si trafilatura retourne assez de contenu → on l'utilise
    # Sinon → fallback sur le contenu RSS nettoyé
    if full_text and len(full_text.strip()) > 300:
        source_text = full_text
    else:
        source_text = cleaned_content

    excerpt = source_text[:4000]

    if not excerpt.strip():
        raise InsufficientContentError("Contenu source insuffisant")

    prompt = f"""Voici un article de presse.

Titre: {title}
Contenu: {excerpt}

{instruction}

Important:
- Base-toi UNIQUEMENT sur le contenu fourni ci-dessus.
- Reformule entièrement avec tes propres mots, ne copie jamais de phrases du texte.
- Ne t'arrête JAMAIS au milieu d'une phrase.
- Réponds directement, sans phrase d'introduction du type "Voici un résumé"."""

    # Les exceptions typées remontent au routeur qui décide du traitement
    raw_summary = _call_gemini(prompt)

    return _clean_summary(raw_summary)