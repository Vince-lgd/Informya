from anthropic import Anthropic
from app.core.config import settings

client = Anthropic(api_key=settings.ANTHROPIC_API_KEY)

# Instruction différente selon le style choisi par l'utilisateur
STYLE_PROMPTS = {
    "bullet": "Réponds uniquement avec 3 à 4 points clés, un par ligne, commençant par '•'. Pas de phrase d'intro.",
    "journalistic": "Réponds avec un résumé fluide de 3-4 phrases, ton journalistique neutre.",
    "simple": "Réponds avec une explication simple en 3-4 phrases, comme à quelqu'un qui découvre le sujet.",
}


def generate_summary(title: str, content: str | None, style: str) -> str:
    instruction = STYLE_PROMPTS.get(style, STYLE_PROMPTS["bullet"])

    # Limite l'extrait envoyé — réduit le coût de l'appel
    excerpt = (content or "")[:1500]

    prompt = f"""Voici un article de presse.

Titre: {title}
Extrait: {excerpt}

{instruction}

Important: reformule entièrement avec tes propres mots, ne copie jamais de phrases de l'extrait."""

    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=300,
        messages=[{"role": "user", "content": prompt}],
    )

    return response.content[0].text.strip()