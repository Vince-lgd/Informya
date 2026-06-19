from sqlalchemy import Column, String, Float, DateTime, Text, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
import uuid

from app.core.database import Base


class Article(Base):
    __tablename__ = "articles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Contenu original — jamais modifié par l'IA
    title = Column(String, nullable=False)
    content = Column(Text, nullable=True)
    url = Column(String, unique=True, nullable=False)

    # Hash SHA-256 (titre + url) → déduplication par le scraper
    url_hash = Column(String, unique=True, nullable=False)

    # Infos source
    source_name = Column(String, nullable=False)
    source_url = Column(String, nullable=False)
    category = Column(String, nullable=False)

    # Biais politique de la source → algorithme anti-biais
    # Valeurs : "left" | "center" | "right" | "unknown"
    source_bias = Column(String, default="unknown")

    # Teaser 2 lignes généré par Claude API — null jusqu'à génération
    ai_teaser = Column(Text, nullable=True)

    # 🟢 AJOUT : Le résumé complet généré par Gemini (Bullet, Simple ou Journalistic)
    # Null tant que l'utilisateur n'a pas cliqué sur l'article pour la première fois
    summary_bullet = Column(Text, nullable=True)
    summary_journalistic = Column(Text, nullable=True)
    summary_simple = Column(Text, nullable=True)

    image_url = Column(String, nullable=True)
    published_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Relations
    read_by = relationship("ReadHistory", back_populates="article", lazy="select")
    bookmarks = relationship("Bookmark", back_populates="article", lazy="select")
    shares = relationship("SharedArticle", back_populates="article", lazy="select")


class ReadHistory(Base):
    # Enregistre chaque article lu — alimente le scoring de personnalisation
    __tablename__ = "read_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    article_id = Column(UUID(as_uuid=True), ForeignKey("articles.id"), nullable=False)

    # Temps de lecture → article lu 30s vs 3min = intérêt très différent
    read_duration_seconds = Column(Float, default=0)
    read_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="read_history")
    article = relationship("Article", back_populates="read_by")


class Bookmark(Base):
    # Favoris personnels — articles sauvegardés pour relire plus tard
    __tablename__ = "bookmarks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    article_id = Column(UUID(as_uuid=True), ForeignKey("articles.id"), nullable=False)

    # Note personnelle optionnelle sur l'article
    note = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="bookmarks")
    article = relationship("Article", back_populates="bookmarks")


class SharedArticle(Base):
    # Partage interne entre utilisateurs Informya
    __tablename__ = "shared_articles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Qui envoie → qui reçoit
    sender_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    recipient_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    article_id = Column(UUID(as_uuid=True), ForeignKey("articles.id"), nullable=False)

    # Message optionnel accompagnant le partage — "Pense à toi !"
    message = Column(Text, nullable=True)

    # False = pas encore vu par le destinataire → badge notification dans l'app
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    sender = relationship("User", foreign_keys=[sender_id], back_populates="sent_shares")
    recipient = relationship("User", foreign_keys=[recipient_id], back_populates="received_shares")
    article = relationship("Article", back_populates="shares")