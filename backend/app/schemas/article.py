from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional


# ── Sorties ────────────────────────────────────────────────

class ArticleResponse(BaseModel):
    # Article tel qu'envoyé à React Native
    id: UUID
    title: str
    url: str
    source_name: str
    category: str
    source_bias: str
    image_url: Optional[str] = None
    published_at: Optional[datetime] = None

    # Teaser IA — null si pas encore généré
    ai_teaser: Optional[str] = None

    reading_time: Optional[int] = None

    class Config:
        from_attributes = True


class ArticleDetail(ArticleResponse):
    # Version complète avec contenu — chargée quand on ouvre un article
    content: Optional[str] = None


# ── Entrées ────────────────────────────────────────────────

class BookmarkCreate(BaseModel):
    # Ajouter un article en favoris
    article_id: UUID
    note: Optional[str] = None  # Note personnelle optionnelle


class ShareCreate(BaseModel):
    # Partager un article en interne
    article_id: UUID
    recipient_id: UUID               # ID de l'ami qui reçoit
    message: Optional[str] = None    # Message optionnel


# ── Feed ───────────────────────────────────────────────────

class FeedResponse(BaseModel):
    # Réponse paginée du feed
    articles: list[ArticleResponse]
    total: int
    page: int
    has_more: bool                   # True s'il reste des articles à charger