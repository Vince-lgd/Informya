from pydantic import BaseModel, EmailStr, field_validator
from uuid import UUID
from datetime import datetime
from typing import Optional


class UserRegister(BaseModel):
    email: EmailStr
    username: str
    password: str
    invite_code: Optional[str] = None

    @field_validator("password")
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError("Minimum 8 caractères")
        if not any(c.isdigit() for c in v):
            raise ValueError("Au moins un chiffre requis")
        if not any(c.isupper() for c in v):
            raise ValueError("Au moins une majuscule requise")
        if not any(c.islower() for c in v):
            raise ValueError("Au moins une minuscule requise")
        if not any(c in "!@#$%^&*()-+" for c in v):
            raise ValueError("Au moins un caractère spécial requis (!@#$%^&*()-+)")
        return v

    @field_validator("username")
    @classmethod
    def validate_username(cls, v):
        if len(v) < 3:
            raise ValueError("Le username doit faire au moins 3 caractères")
        if " " in v:
            raise ValueError("Le username ne peut pas contenir d'espaces")
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserUpdateStyle(BaseModel):
    reading_style: str


class UserResponse(BaseModel):
    id: UUID
    email: EmailStr
    username: str
    reading_style: str
    invite_code: str
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse