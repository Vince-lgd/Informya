from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.article import Article, ReadHistory, Bookmark
from app.schemas.article import ArticleDetail, BookmarkCreate, FeedResponse, ArticleResponse
from app.core.database import get_redis
from app.services.ai_service import generate_summary
from app.core.config import settings

router = APIRouter()


@router.get("/{article_id}", response_model=ArticleDetail)
async def get_article(
    article_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Récupère l'article complet par son ID
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

    # Le style vient du profil utilisateur — c'est ici qu'il sert enfin !
    style = current_user.reading_style or "bullet"
    cache_key = f"ai_summary:{article_id}:{style}"

    # Vérifie le cache Redis avant d'appeler Claude — économise des appels
    cached = await redis.get(cache_key)
    if cached:
        return {"summary": cached, "style": style}

    try:
        summary = generate_summary(article.title, article.content, style)
    except Exception:
        raise HTTPException(
            status_code=503,
            detail="Le résumé IA est temporairement indisponible"
        )

    # Cache 1h — défini dans settings.AI_SUMMARY_CACHE_TTL
    await redis.set(cache_key, summary, ex=settings.AI_SUMMARY_CACHE_TTL)

    return {"summary": summary, "style": style}


@router.post("/{article_id}/read", status_code=204)
async def mark_as_read(
    article_id: UUID,
    read_duration_seconds: float = 0,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Vérifie que l'article existe
    result = await db.execute(select(Article).where(Article.id == article_id))
    article = result.scalar_one_or_none()
    if not article:
        raise HTTPException(status_code=404, detail="Article introuvable")

    # Vérifie si déjà lu — évite les doublons dans l'historique
    existing = await db.execute(
        select(ReadHistory).where(
            ReadHistory.user_id == current_user.id,
            ReadHistory.article_id == article_id
        )
    )
    if existing.scalar_one_or_none():
        return  # Déjà lu, on ne recrée pas

    # Enregistre dans l'historique avec la durée de lecture
    read = ReadHistory(
        user_id=current_user.id,
        article_id=article_id,
        read_duration_seconds=read_duration_seconds
    )
    db.add(read)
    await db.commit()