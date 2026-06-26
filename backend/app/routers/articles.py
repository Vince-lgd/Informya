from fastapi import APIRouter, Depends, HTTPException
from fastapi.concurrency import run_in_threadpool
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

from app.core.database import get_db, get_redis
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.article import Article, ReadHistory
from app.schemas.article import ArticleDetail, ArticleResponse, FeedResponse, BookmarkCreate
from app.models.article import Bookmark
from app.services.ai_service import generate_summary
from app.services.cache_service import get_safe_style, get_cached_summary, store_summary

router = APIRouter()


@router.get("/{article_id}", response_model=ArticleDetail)
async def get_article(
    article_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Article).where(Article.id == article_id))
    article = result.scalar_one_or_none()
    if not article:
        raise HTTPException(status_code=404, detail="Article introuvable")
    return ArticleDetail.model_validate(article)


@router.get("/{article_id}/summary")
async def get_article_summary(
    article_id: UUID,
    db: AsyncSession = Depends(get_db),
    redis=Depends(get_redis),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Article).where(Article.id == article_id))
    article = result.scalar_one_or_none()
    if not article:
        raise HTTPException(status_code=404, detail="Article introuvable")

    style = get_safe_style(current_user.reading_style)

    # L1 Redis → L2 PostgreSQL
    cached = await get_cached_summary(redis, article, style)
    if cached:
        return {"summary": cached, "style": style}

   # Génération Gemini
    try:
        # TODO: retirer ces print avant le déploiement Railway
        # 🔍 ON AJOUTE CES LIGNES POUR ESPIONNER LE TEXTE AVANT L'IA :
        texte_content = str(article.content) if article.content else ""
        print(f"\n--- 🕵️‍♂️ TEXTE ENVOYÉ À GEMINI (Longueur: {len(texte_content)}) ---")
        print(texte_content[:500] + "...\n") 
        
        summary = await run_in_threadpool(
            generate_summary, article.title, article.content, article.url, style
        )
        
        # 🔍 ON AJOUTE CES LIGNES POUR ESPIONNER LE RÉSULTAT DE L'IA :
        print(f"--- 🤖 RÉPONSE DE GEMINI (Style attendu: {style}) ---")
        print(summary + "\n")
        
        await store_summary(redis, db, article, style, summary)
        return {"summary": summary, "style": style, "source": "gemini"}

    except Exception as e:
        print(f"❌ Erreur génération résumé pour {article_id}: {repr(e)}")
        fallback = article.ai_teaser or "Résumé indisponible pour le moment."
        # TTL court — on réessaiera dans 10s
        await store_summary(redis, db, article, style, fallback, ttl=10)
        return {"summary": fallback, "style": style, "source": "fallback"}


@router.post("/{article_id}/read", status_code=204)
async def mark_as_read(
    article_id: UUID,
    read_duration_seconds: float = 0,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Article).where(Article.id == article_id))
    article = result.scalar_one_or_none()
    if not article:
        raise HTTPException(status_code=404, detail="Article introuvable")

    existing = await db.execute(
        select(ReadHistory).where(
            ReadHistory.user_id == current_user.id,
            ReadHistory.article_id == article_id
        )
    )
    if existing.scalar_one_or_none():
        return

    read = ReadHistory(
        user_id=current_user.id,
        article_id=article_id,
        read_duration_seconds=read_duration_seconds
    )
    db.add(read)
    await db.commit()