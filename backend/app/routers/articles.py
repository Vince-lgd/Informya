from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.article import Article, ReadHistory, Bookmark
from app.schemas.article import ArticleDetail, BookmarkCreate, FeedResponse, ArticleResponse

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