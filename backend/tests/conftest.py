import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

from app.main import app
from app.core.database import Base, get_db, get_redis
from app.core.limiter import limiter



# Base SQLite en mémoire — isolée, rapide, détruite après chaque test
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


class FakeRedis:
    """Redis simulé en mémoire pour les tests."""

    def __init__(self):
        self._store = {}

    async def get(self, key):
        return self._store.get(key)

    async def set(self, key, value, ex=None):
        self._store[key] = value

    async def delete(self, key):
        self._store.pop(key, None)


@pytest.fixture(autouse=True)
def disable_rate_limit():
    """Désactive le rate limiting pendant les tests."""
    limiter.enabled = False
    yield
    limiter.enabled = True


@pytest_asyncio.fixture
async def db_session():
    """Crée une base de test vierge pour chaque test."""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with session_maker() as session:
        yield session

    await engine.dispose()


@pytest_asyncio.fixture
async def client(db_session):
    """Client HTTP de test avec base et Redis simulés."""

    async def override_get_db():
        yield db_session

    async def override_get_redis():
        return FakeRedis()

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_redis] = override_get_redis

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def auth_headers(client):
    """Crée un utilisateur et retourne les headers d'authentification."""
    await client.post("/auth/register", json={
        "email": "test@informya.com",
        "username": "testuser",
        "password": "TestPass1!",
    })

    response = await client.post("/auth/login", json={
        "email": "test@informya.com",
        "password": "TestPass1!",
    })

    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}