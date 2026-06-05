from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    # Configuration de l'application
    APP_NAME: str = "Informya"
    DEBUG: bool = False

    # Configuration de la base de données et des services externes
    DATABASE_URL: str
    REDIS_URL: str

    # Clés API et secrets
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7

    ANTHROPIC_API_KEY: str = ""
    NEWS_API_KEY: str = ""
    ALPHA_VANTAGE_KEY: str = ""

    FEED_CACHE_TTL: int = 900
    AI_SUMMARY_CACHE_TTL: int = 3600

    # En dev → accepte tout, en prod → restreindre aux vraies URLs
    ALLOWED_ORIGINS: List[str] = ["*"]

    # Règles mot de passe
    PASSWORD_MIN_LENGTH: int = 8

    class Config:
        env_file = ".env"


settings = Settings()