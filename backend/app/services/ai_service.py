import trafilatura
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


def fetch_full_text(url: str) -> str | None:
    """
    Récupère le texte principal d'une page web, sans pub ni menus.
    Usage éphémère uniquement : ce texte n'est jamais stocké ni affiché tel quel,
    il sert uniquement de matière première au résumé IA.
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
    Renvoie False pour stopper immédiatement le retry si l'API est saturée (429).
    Renvoie True pour autoriser le retry sur les autres erreurs (timeouts, 5xx).
    """
    error_msg = str(exception)
    if "429" in error_msg or "RESOURCE_EXHAUSTED" in error_msg:
        return False  # Pas de retry, inutile de harceler Google
    return True


@retry(
    stop=stop_after_attempt(3), 
    wait=wait_exponential(multiplier=1, min=2, max=10),
    retry=retry_if_exception(should_retry),
    reraise=True  # Remonte la vraie erreur (ex: ClientError) au lieu d'une RetryError globale
)
def _call_gemini(prompt: str) -> str:
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                max_output_tokens=500,  # 💡 Offre assez d'espace pour ne pas couper le français
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

    # Tente d'abord de récupérer le texte complet de l'article
    full_text = fetch_full_text(url)

    # 💡 Sécurité : Si trafilatura renvoie un contenu trop court (ex: paywall ou cookie-wall),
    # on rejette l'extraction pour forcer le repli sur la description du flux RSS.
    if full_text and len(full_text.strip()) > 300:
        source_text = full_text
    else:
        source_text = content or ""
        
    excerpt = source_text[:4000]  # Limite la taille envoyée à l'API

    # Si malgré tout le texte source reste vide, on donne une base à l'IA
    if not excerpt.strip():
        excerpt = f"Aucun détail fourni. Base-toi sur le titre suivant : {title}"

    # Prompt enrichi avec tes instructions de secours
    prompt = f"""Voici un article de presse.

Titre: {title}
Contenu: {excerpt}

{instruction}

Important:
- Base-toi sur le contenu fourni ci-dessus pour résumer.
- Si le contenu fourni est trop court, vide ou illisible, n'essaie pas de faire des points clés. Au lieu de cela, fais une phrase explicative générale basée sur le titre de manière fluide.
- Reformule entièrement avec tes propres mots, ne copie jamais de phrases du texte original.
- Ne t'arrête JAMAIS au milieu d'une phrase."""

    try:
        raw_summary = _call_gemini(prompt)
    except Exception:
        # En cas de crash persistant (comme un 429 immédiat), on renvoie un fallback propre
        return "Résumé indisponible actuellement (quota de l'API atteint)."

    # Filet de sécurité : Gemini ignore parfois l'instruction "pas d'intro"
    lines_to_strip = ["voici", "bien sûr", "voilà"]
    first_line = raw_summary.split("\n")[0].lower()
    if any(raw_summary.lower().startswith(w) for w in lines_to_strip) and ":" in first_line:
        raw_summary = raw_summary.split(":", 1)[1].strip()

    return raw_summary