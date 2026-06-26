from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, not_, func

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User, UserSource
from app.models.article import Article, ReadHistory
from app.schemas.article import FeedResponse, ArticleResponse

router = APIRouter()


@router.get("", response_model=FeedResponse)
async def get_feed(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    category: str = Query(None),
    content_type: str = Query(None),
    max_reading_time: int = Query(None),
    source_bias: str = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Articles déjà lus
    read_result = await db.execute(
        select(ReadHistory.article_id).where(ReadHistory.user_id == current_user.id)
    )
    read_ids = list(read_result.scalars().all())

    # Sources favorites
    fav_result = await db.execute(
        select(UserSource.source_name).where(UserSource.user_id == current_user.id)
    )
    fav_sources = list(fav_result.scalars().all())

    def apply_filters(q):
        if read_ids:
            q = q.where(not_(Article.id.in_(read_ids)))
        if category:
            q = q.where(Article.category == category)
        if content_type:
            q = q.where(Article.content_type == content_type)
        if max_reading_time:
            q = q.where(
                (Article.reading_time <= max_reading_time) | (Article.reading_time == None)
            )
        if source_bias:
            q = q.where(Article.source_bias == source_bias)
        return q

    offset = (page - 1) * limit

    if fav_sources:
        # Sources favorites en premier, puis le reste
        fav_query = apply_filters(
            select(Article).where(Article.source_name.in_(fav_sources))
        ).order_by(Article.published_at.desc())

        other_query = apply_filters(
            select(Article).where(not_(Article.source_name.in_(fav_sources)))
        ).order_by(Article.published_at.desc())

        fav_result = await db.execute(fav_query)
        fav_articles = list(fav_result.scalars().all())

        other_result = await db.execute(other_query)
        other_articles = list(other_result.scalars().all())

        # Combine : favoris en tête
        all_articles = fav_articles + other_articles
        total = len(all_articles)
        articles = all_articles[offset:offset + limit]
    else:
        # Pas de favoris — comportement normal
        query = apply_filters(select(Article)).order_by(Article.published_at.desc())
        query = query.offset(offset).limit(limit)
        result = await db.execute(query)
        articles = list(result.scalars().all())

        count_query = apply_filters(select(func.count()).select_from(Article))
        total = await db.scalar(count_query)

    return FeedResponse(
        articles=[ArticleResponse.model_validate(a) for a in articles],
        total=total,
        page=page,
        has_more=(offset + limit) < total
    )