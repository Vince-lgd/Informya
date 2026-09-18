"""Affiche les résumés de plusieurs modèles sur un même article, pour comparaison qualitative."""

import asyncio
from sqlalchemy import select
from google import genai
from google.genai import types

from app.core.database import AsyncSessionLocal
from app.core.config import settings
from app.models.article import Article
from app.schemas.ai import ArticleSummary
from app.services.ai_service import clean_html, fetch_full_text
from benchmark.run_benchmark import build_prompt

client = genai.Client(api_key=settings.GEMINI_API_KEY)

MODELS = ["gemini-2.5-flash", "gemini-3.5-flash-lite"]


async def main():
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Article)
            .where(Article.content.isnot(None))
            .order_by(Article.published_at.desc())
            .limit(1)
        )
        article = result.scalar_one_or_none()

    if not article:
        print("Aucun article en base")
        return

    full_text = fetch_full_text(article.url)
    content = (
        full_text
        if full_text and len(full_text.strip()) > 300
        else clean_html(article.content or "")
    )

    print(f"\n📰 {article.title}\n")
    print("=" * 70)

    prompt = build_prompt(article.title, content[:4000])

    for model in MODELS:
        response = client.models.generate_content(
            model=model,
            contents=prompt,
            config=types.GenerateContentConfig(
                max_output_tokens=3000,
                response_mime_type="application/json",
                response_schema=ArticleSummary,
            ),
        )
        summary = ArticleSummary.model_validate_json(response.text)

        print(f"\n── {model} ──")
        print(f"Confiance déclarée : {summary.confidence}\n")
        print(summary.to_display_text())
        print()


if __name__ == "__main__":
    asyncio.run(main())