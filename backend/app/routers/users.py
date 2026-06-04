from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.article import Bookmark, Article
from app.schemas.article import BookmarkCreate, ArticleResponse

router = APIRouter()

@router.get("/bookmarks", response_model=list[ArticleResponse])
async def get_bookmarks(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Récupère tous les articles bookmarkés par l'utilisateur
    result = await db.execute(
        select(Article)
        .join(Bookmark, Bookmark.article_id == Article.id)
        .where(Bookmark.user_id == current_user.id)
        .order_by(Bookmark.created_at.desc())  # Les plus récents en premier
    )
    return [ArticleResponse.model_validate(a) for a in result.scalars().all()]


@router.post("/bookmarks", status_code=201)
async def add_bookmark(
    data: BookmarkCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Vérifie que l'article existe 
    result = await db.execute(select(Article).where(Article.id == data.article_id))
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Article introuvable")
    
    # Vérifie si déjà bookmarké — évite les doublons
    existing = await db.execute(
        select(Bookmark).where(
            Bookmark.user_id == current_user.id,
            Bookmark.article_id == data.article_id
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Article déjà dans les favoris")
    
    bookmark = Bookmark(
        user_id=current_user.id,
        article_id=data.article_id,
        note=data.note
    )
    db.add(bookmark)
    await db.commit()
    return {"message": "Article ajouté aux favoris"}


@router.delete("/bookmarks/{article_id}", status_code=204)
async def remove_bookmark(
    article_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Récupère et supprime le bookmark s'il existe
    result = await db.execute(
        select(Bookmark).where(
            Bookmark.user_id == current_user.id,
            Bookmark.article_id == article_id
        )
    )
    bookmark = result.scalar_one_or_none()
    if not bookmark:
        raise HTTPException(status_code=404, detail="Favori introuvable")
    
    await db.delete(bookmark)
    await db.commit()