from pydantic import BaseModel, EmailStr
from uuid import UUID
from datetime import datetime
from typing import Optional


# ── Entrées (ce que l'utilisateur envoie) ──────────────────

class UserRegister(BaseModel): 
    # Données requises à l'inscription 
    email: EmailStr
    username: str
    password: str
    invite_code: Optional[str] = None  # Code d'invitation facultatif


class UserLogin(BaseModel): 
    # Données requises à la connexion 
    email: EmailStr
    password: str


class UserUpdateStyle(BaseModel):
    # Mise à jour du style de lecture
    # Valeurs acceptées : "bullet" | "journalistic" | "simple"
    reading_style: str



# ── Sorties (ce que l'API renvoie) ─────────────────────────

class UserResponse(BaseModel):
    # Profil publiqie - on ne renvoie JAMAIS hashed_password 
    id: UUID
    email: EmailStr
    username: str
    reading_style: str 
    invite_code: str
    created_at: datetime

    class Config: 
        # Permet de lire les attributs SQLAlchemy directement 
        from_attributes = True



# ── Auth ───────────────────────────────────────────────────

class TokenResponse(BaseModel):
    # Réponse après login réussi
    access_token: str
    token_type: str = "bearer"
    user: UserResponse