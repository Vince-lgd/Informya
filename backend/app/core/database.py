from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
import redis.asyncio as redis

from app.core.config import settings


# ── PostgreSQL ──────────────────────────────────────────────

# Moteur de connexion async vers PostgreSQL
# echo=DEBUG → affiche les requêtes SQL dans les logs si DEBUG=True
engine = create_async_engine(settings.DATABASE_URL, echo=settings.DEBUG)

# Fabrique de sessions — chaque requête API ouvre sa propre session
# expire_on_commit=False → les objets restent accessibles après un commit
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


# Classe de base dont héritent tous les modèles SQLAlchemy
# Ex: class User(Base) → crée automatiquement la table "users"
class Base(DeclarativeBase):
    pass


async def init_db():
    # Crée toutes les tables en base au démarrage si elles n'existent pas
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def get_db():
    # Dépendance FastAPI — injectée dans chaque route qui a besoin de la BDD
    # Le "yield" garantit que la session est fermée après chaque requête
    async with AsyncSessionLocal() as session:
        yield session


# ── Redis ───────────────────────────────────────────────────

# Connexion persistante Redis — réutilisée pour tout le cache de l'app
# decode_responses=True → retourne des strings plutôt que des bytes
redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)


async def get_redis():
    # Dépendance FastAPI — injectée dans les routes qui utilisent le cache
    return redis_client