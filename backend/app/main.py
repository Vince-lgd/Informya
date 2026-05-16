from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.database import init_db
from app.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Code exécuté au démarrage du serveur
    # Crée les tables PostgreSQL si elles n'existent pas encore
    await init_db()
    yield
    # Code exécuté à l'arrêt du serveur (nettoyage si besoin)


app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    # Lance http://localhost:8000/docs pour voir la doc interactive
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    # Autorise React Native à appeler l'API depuis n'importe quelle origine
    # À restreindre en production avec les vraies URLs
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Route de santé — vérifie que le serveur tourne
# Utilisée par Docker et Railway pour monitorer l'app
@app.get("/health")
async def health():
    return {"status": "ok", "app": settings.APP_NAME}