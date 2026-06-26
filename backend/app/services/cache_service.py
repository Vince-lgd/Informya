from sqlalchemy.ext.asyncio import AsyncSession
from app.models.article import Article
from app.core.config import settings

ALLOWED_STYLES = ["bullet", "journalistic", "simple"]


def get_safe_style(reading_style: str | None) -> str:
    """Valide et retourne le style de lecture, bullet par défaut."""
    return reading_style if reading_style in ALLOWED_STYLES else "bullet"


def get_cache_key(article_id: str, style: str) -> str:
    """Génère la clé de cache Redis pour un résumé."""
    return f"ai_summary:{article_id}:{style}"


# Dans cache_service.py -> get_cached_summary()
async def get_cached_summary(redis, article: Article, style: str) -> str | None:
    cache_key = get_cache_key(str(article.id), style)

    # L1 — Redis
    cached = await redis.get(cache_key)
    if cached:
        # 🟢 AJOUT : On force le décodage en string si Redis renvoie des bytes
        return cached.decode('utf-8') if isinstance(cached, bytes) else cached

    # L2 — PostgreSQL
    db_summary = getattr(article, f"summary_{style}", None)
    if db_summary:
        await redis.set(cache_key, db_summary, ex=settings.AI_SUMMARY_CACHE_TTL)
        return db_summary

    return None


async def store_summary(
    redis,
    db: AsyncSession,
    article: Article,
    style: str,
    summary: str,
    ttl: int = None,
) -> None:
    """
    Sauvegarde un résumé dans Redis + PostgreSQL.
    En cas d'échec (fallback), utilise un TTL court pour ne pas bloquer.
    """
    cache_key = get_cache_key(str(article.id), style)
    effective_ttl = ttl or settings.AI_SUMMARY_CACHE_TTL

    # Sauvegarde Redis
    await redis.set(cache_key, summary, ex=effective_ttl)

    # Sauvegarde PostgreSQL uniquement si c'est un vrai résumé (pas un fallback)
    if ttl is None:
        setattr(article, f"summary_{style}", summary)
        db.add(article)
        await db.commit()