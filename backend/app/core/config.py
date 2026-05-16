from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    #Base 

    # Nom affiché dans la doc FastAPI
    APP_NAME: str = "Informya"
    # Active les logs SQL si TRUE - utile en dev, désactiver en prod
    DEBUG: bool = False


    #Base de données

    # URL de connexion - lues depuis .env
    # "db" et "redis" = noms des services dans docker-compose.yml
    DATABASE_URL: str 
    REDIS_URL: str


    #Auth JWT 

    # Clé secrète pour signer les tokens JWT (connexion utilisateurs)
    SECRET_KEY: str

    # Algorithme de chiffrement pour les tokens JWT
    ALGORITHM: str = "HS256"

    # Durée de validité des tokens JWT (en minutes)
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 jours


    #APIs 

    # Clés APIs externes — vides par défaut, remplies dans .env
    ANTHROPIC_API_KEY: str = ""
    NEWS_API_KEY: str = ""
    ALPHA_VANTAGE_KEY: str = ""


    #Cache TTL (en secondes)

    # Durée de vie du cache Redis en secondes
    FEED_CACHE_TTL: int = 900 # 15 minutes
    AI_SUMMARY_CACHE_TTL: int = 3600 # 1 heure


    class Config:
        # Fichier où lire les variables d'environnement
        env_file = ".env"


# Instance unique importée partout dans le projet
# -> from app.core.config import settings
settings = Settings()