from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from apscheduler.schedulers.asyncio import AsyncIOScheduler

from app.core.database import init_db
from app.core.config import settings
from app.models import User, Article, ReadHistory, Bookmark, SharedArticle
from app.routers import auth, articles, feed, users
from app.services.scraper import run_scraper

# Scheduler pour lancer le scraper automatiquement
scheduler = AsyncIOScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()

    # Lance le scraper au démarrage
    await run_scraper()

    # Programme le scraper toutes les 30 minutes
    scheduler.add_job(run_scraper, "interval", minutes=30)
    scheduler.start()

    yield

    scheduler.shutdown()


app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,     prefix="/auth",     tags=["Auth"])
app.include_router(feed.router,     prefix="/feed",     tags=["Feed"])
app.include_router(articles.router, prefix="/articles", tags=["Articles"])
app.include_router(users.router,    prefix="/users",    tags=["Users"])


@app.get("/health")
async def health():
    return {"status": "ok", "app": settings.APP_NAME}