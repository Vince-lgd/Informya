import trafilatura
import re

from google import genai
from google.genai import types
from app.core.config import settings
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception

client = genai.Client(api_key=settings.GEMINI_API_KEY)

STYLE_PROMPTS = {
    "bullet": "Rédige un résumé en 3-4 points (puces •). Ne mets pas de phrase d'introduction ni de conclusion.",
    "journalistic": "Rédige un résumé fluide de 3-4 phrases, ton journalistique neutre. Pas d'intro, pas de conclusion.",
    "simple": "Rédige une explication simple en 3-4 phrases, pour quelqu'un qui découvre le sujet. Pas d'intro, pas de conclusion.",
}


def clean_html(text: str) -> str:
    """Retire les balises HTML et nettoie les espaces."""
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def fetch_full_text(url: str) -> str | None:
    """
    Récupère le texte principal d'une page web, sans pub ni menus.
    Usage éphémère uniquement — jamais stocké ni affiché tel quel.
    """
    try:
        downloaded = trafilatura.fetch_url(url, no_ssl=True)
        if not downloaded:
            return None
        text = trafilatura.extract(downloaded, include_comments=False, include_tables=False)
        return text
    except Exception:
        return None


def should_retry(exception) -> bool:
    """
    Stoppe immédiatement si l'API est saturée (429).
    Autorise le retry sur les autres erreurs.
    """
    error_msg = str(exception)
    if "429" in error_msg or "RESOURCE_EXHAUSTED" in error_msg:
        return False
    return True


@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    retry=retry_if_exception(should_retry),
    reraise=True
)
def _call_gemini(prompt: str) -> str:
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                max_output_tokens=1000,  # ← monté pour éviter les coupures
                thinking_config=types.ThinkingConfig(thinking_budget=0),
            ),
        )
    except Exception as e:
        print(f"🔥 Détail erreur Gemini: {repr(e)}")
        raise

    text = response.text
    if not text:
        raise ValueError("Réponse vide de Gemini")
    return text.strip()


def generate_summary(title: str, content: str | None, url: str, style: str) -> str:
    instruction = STYLE_PROMPTS.get(style, STYLE_PROMPTS["bullet"])

    # Nettoyage HTML du contenu RSS avant tout traitement
    cleaned_content = clean_html(content or "")

    # Tente de récupérer le texte complet de la page
    full_text = fetch_full_text(url)

    # Si trafilatura retourne assez de contenu → on l'utilise
    # Sinon → fallback sur le contenu RSS nettoyé
    if full_text and len(full_text.strip()) > 300:
        source_text = full_text
    else:
        source_text = cleaned_content

    excerpt = source_text[:4000]

    if not excerpt.strip():
        return "Résumé indisponible : contenu source insuffisant."

    prompt = f"""Voici un article de presse.

Titre: {title}
Contenu: {excerpt}

{instruction}

Important:
- Base-toi UNIQUEMENT sur le contenu fourni ci-dessus.
- Reformule entièrement avec tes propres mots, ne copie jamais de phrases du texte.
- Ne t'arrête JAMAIS au milieu d'une phrase."""

    try:
        raw_summary = _call_gemini(prompt)
    except Exception:
        return "Résumé indisponible pour le moment."

    # Retire les introductions inutiles que Gemini ajoute parfois
    lines_to_strip = ["voici", "bien sûr", "voilà"]
    first_line = raw_summary.split("\n")[0].lower()
    if any(raw_summary.lower().startswith(w) for w in lines_to_strip) and ":" in first_line:
        raw_summary = raw_summary.split(":", 1)[1].strip()

    return raw_summary