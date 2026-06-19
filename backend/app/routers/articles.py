from fastapi import APIRouter, Depends, HTTPException
from fastapi.concurrency import run_in_threadpool # 🟢 AJOUT IMPORTANT
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

    # On sécurise le style (au cas où current_user.reading_style renvoie n'importe quoi)
    allowed_styles = ["bullet", "journalistic", "simple"]
    style = current_user.reading_style if current_user.reading_style in allowed_styles else "bullet"
    
    # ---------------------------------------------------------
    # 1. NIVEAU DE CACHE 1 : REDIS (Ultra-rapide, en RAM)
    # ---------------------------------------------------------
    cache_key = f"ai_summary:{article_id}:{style}"
    cached = await redis.get(cache_key)
    if cached:
        return {"summary": cached, "style": style, "source": "redis"}

    # ---------------------------------------------------------
    # 2. NIVEAU DE CACHE 2 : POSTGRESQL (Persistant)
    # ---------------------------------------------------------
    target_column = f"summary_{style}"
    db_summary = getattr(article, target_column)
    
    if db_summary:
        # On a trouvé le résumé en base de données ! 
        # On le remet dans Redis pour que le prochain appel soit encore plus rapide.
        await redis.set(cache_key, db_summary, ex=settings.AI_SUMMARY_CACHE_TTL)
        return {"summary": db_summary, "style": style, "source": "postgresql"}

    # ---------------------------------------------------------
    # 3. GÉNÉRATION VIA GEMINI (Si aucun cache n'a fonctionné)
    # ---------------------------------------------------------
    try:
        # 🟢 SÉCURITÉ : run_in_threadpool empêche la fonction synchrone de bloquer FastAPI
        summary = await run_in_threadpool(
            generate_summary, article.title, article.content, article.url, style
        )
        
        # ✅ SAUVEGARDE REDIS (temporaire)
        await redis.set(cache_key, summary, ex=settings.AI_SUMMARY_CACHE_TTL)
        
        # ✅ SAUVEGARDE POSTGRESQL (définitive)
        setattr(article, target_column, summary)
        db.add(article)
        await db.commit()
        
    except Exception as e:
        print(f"❌ Erreur génération résumé pour {article_id}: {repr(e)}")  
        summary = article.ai_teaser or "Résumé indisponible pour le moment."
        
        # ⏱️ ÉCHEC : On cache l'erreur seulement 10s dans Redis (et on ne touche pas à Postgres)
        await redis.set(cache_key, summary, ex=10) 
    
    return {"summary": summary, "style": style, "source": "gemini"}


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