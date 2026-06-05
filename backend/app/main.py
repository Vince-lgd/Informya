from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.core.database import init_db
from app.core.config import settings
from app.core.limiter import limiter
from app.models import User, Article, ReadHistory, Bookmark, SharedArticle
from app.routers import auth, articles, feed, users
from app.services.scraper import run_scraper

scheduler = AsyncIOScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialisation de la base de données et lancement du scraper au démarrage de l'application
    await init_db()
    await run_scraper()
    scheduler.add_job(run_scraper, "interval", minutes=30)
    scheduler.start()
    yield
    scheduler.shutdown()

# Création de l'application FastAPI
app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    lifespan=lifespan,
)

# ── Rate limiting ───────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── CORS ────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Taille des requêtes — max 1MB ───────────────────────────
@app.middleware("http")
async def limit_request_size(request: Request, call_next):
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > 1_000_000:
        return JSONResponse(
            status_code=413,
            content={"detail": "Requête trop volumineuse"}
        )
    return await call_next(request)


# ── Headers de sécurité ─────────────────────────────────────
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    # Empêche le navigateur de deviner le type MIME
    response.headers["X-Content-Type-Options"] = "nosniff"
    # Empêche l'intégration dans une iframe — protection clickjacking
    response.headers["X-Frame-Options"] = "DENY"
    # Force HTTPS pendant 1 an en production
    response.headers["Strict-Transport-Security"] = "max-age=31536000"
    # Bloque les attaques XSS dans les anciens navigateurs
    response.headers["X-XSS-Protection"] = "1; mode=block"
    return response


# ── Logs de sécurité ────────────────────────────────────────
@app.middleware("http")
async def security_logger(request: Request, call_next):
    response = await call_next(request)
    # Log toutes les tentatives échouées sur les routes sensibles
    if response.status_code in [401, 403, 429] and "/auth" in request.url.path:
        client_ip = request.client.host if request.client else "unknown"
        print(f"⚠️  [{response.status_code}] {request.method} {request.url.path} — IP: {client_ip}")
    return response


app.include_router(auth.router,     prefix="/auth",     tags=["Auth"])
app.include_router(feed.router,     prefix="/feed",     tags=["Feed"])
app.include_router(articles.router, prefix="/articles", tags=["Articles"])
app.include_router(users.router,    prefix="/users",    tags=["Users"])


@app.get("/health")
async def health():
    return {"status": "ok", "app": settings.APP_NAME}