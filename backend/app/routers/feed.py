from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, not_

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.article import Article, ReadHistory
from app.schemas.article import FeedResponse, ArticleResponse

router = APIRouter()

@router.get("", response_model=FeedResponse)
async def get_feed(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    category: str = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Récupère les IDs des articles déjà lus par l'utilisateur
    read_result = await db.execute(
        select(ReadHistory.article_id).where(ReadHistory.user_id == current_user.id)
    )
    read_ids = [r for r in read_result.scalars().all()]

    # Construire la requête de base pour les articles - exclut les articles déjà lus 
    query = select(Article)
    if read_ids: 
        query = query.where(not_(Article.id.in_(read_ids)))

    # Filtre par catégorie si demandé 
    if category: 
        query = query.where(Article.category == category)

    # Tri par date de publication - les plus récents en premier
    query = query.order_by(Article.published_at.desc())

    # Pagination
    offset = (page - 1) * limit
    query = query.offset(offset).limit(limit)

    result = await db.execute(query)
    articles = result.scalars().all()

    # Compte total pour savoir s'il reste des articles 
    count_result = await db.execute(
        select(Article).where(
            not_(Article.id.in_(read_ids)) if read_ids else True
        )
    )
    total = len(count_result.scalars().all())


    return FeedResponse(
        articles=[ArticleResponse.model_validate(a) for a in articles],
        total=total,
        page=page,  
        has_more=(offset + limit) < total
    )