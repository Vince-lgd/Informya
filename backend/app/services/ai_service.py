from google import genai
from google.genai import types
from app.core.config import settings
from tenacity import retry, stop_after_attempt, wait_exponential

# Initialisation du client
client = genai.Client(api_key=settings.GEMINI_API_KEY)

STYLE_PROMPTS = {
    "bullet": "Rédige un résumé accrocheur en 3-4 points. Si le contenu est court, extrapole intelligemment le contexte probable pour donner une vision complète. Ne mets pas de phrases de l'article, ne fais pas de phrase d'introduction, ne fais pas de conclusion.",
    "journalistic": "Rédige un résumé fluide de 3-4 phrases avec un ton journalistique neutre. Si le contenu est court, extrapole le contexte pour donner une vision complète. Ne mets pas de phrases de l'article, pas d'intro, pas de conclusion.",
    "simple": "Rédige une explication simple en 3-4 phrases, comme à quelqu'un qui découvre le sujet. Si le contenu est court, extrapole le contexte. Pas de phrases de l'article, pas d'intro, pas de conclusion.",
}

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
def generate_summary(title: str, content: str | None, style: str) -> str:
    instruction = STYLE_PROMPTS.get(style, STYLE_PROMPTS["bullet"])
    
    excerpt = (content or "")[:1500]
    
    # Le prompt est maintenant plus propre et suit une logique claire
    prompt = f"""
Titre de l'article: {title}
Extrait du contenu: {excerpt}

{instruction}
Rédige un résumé instructif en 4 points maximum, en utilisant uniquement des puces (•).
SI le contenu fourni est trop court ou peu clair, base-toi uniquement sur le titre pour expliquer le sujet de manière détaillée et logique, comme si tu étais un expert.
NE JAMAIS répondre par une phrase coupée.
NE JAMAIS introduire ou conclure le résumé.
Réponds uniquement avec le contenu des points.
"""
    
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            max_output_tokens=500,
        ),
    )
    return response.text.strip()