from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User, UserSource
from app.models.article import Bookmark, Article
from app.schemas.article import BookmarkCreate, ArticleResponse
from app.schemas.user import UserUpdateStyle, UserResponse

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


@router.patch("/me", response_model=UserResponse)
async def update_profile(
    data: UserUpdateStyle,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Valide que le style envoyé est autorisé
    valid_styles = ["bullet", "journalistic", "simple"]
    if data.reading_style not in valid_styles:
        raise HTTPException(status_code=400, detail="Style de lecture invalide")

    current_user.reading_style = data.reading_style
    await db.commit()
    await db.refresh(current_user)

    return UserResponse.model_validate(current_user)


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


@router.get("/sources")
async def get_favorite_sources(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(UserSource.source_name)
        .where(UserSource.user_id == current_user.id)
        .order_by(UserSource.created_at.desc())
    )
    return {"sources": result.scalars().all()}


@router.post("/sources", status_code=201)
async def add_favorite_source(
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    source_name = data.get("source_name", "").strip()
    if not source_name:
        raise HTTPException(status_code=400, detail="Nom de source invalide")

    # Vérifie si déjà en favori
    existing = await db.execute(
        select(UserSource).where(
            UserSource.user_id == current_user.id,
            UserSource.source_name == source_name
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Source déjà en favori")

    source = UserSource(user_id=current_user.id, source_name=source_name)
    db.add(source)
    await db.commit()
    return {"message": f"{source_name} ajouté aux favoris"}


@router.delete("/sources/{source_name}", status_code=204)
async def remove_favorite_source(
    source_name: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(UserSource).where(
            UserSource.user_id == current_user.id,
            UserSource.source_name == source_name
        )
    )
    source = result.scalar_one_or_none()
    if not source:
        raise HTTPException(status_code=404, detail="Source non trouvée")

    await db.delete(source)
    await db.commit()