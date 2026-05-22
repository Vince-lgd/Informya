from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import settings

# Contexte de hashage pour les mots de passe - bcrypt est l'algorithme recommandé
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    # Transforme "monmotdepasse" en "$2b$12$xxxx..." — irréversible
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    # Compare le mot de passe saisi avec le hash stocké en base de données
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(user_id: str) -> str: 
    # Génère un token JWT signé avec la SECRET_KEY, contenant l'ID de l'utilisateur et une date d'expiration
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    # Payload — données encodées dans le token
    payload = {
        "sub": user_id,   # "sub" = subject, convention JWT pour l'ID utilisateur
        "exp": expire     # Date d'expiration
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def decode_access_token(token: str) -> str | None:
    # Décode et vérifie un token — retourne l'user_id ou None si invalide
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None
