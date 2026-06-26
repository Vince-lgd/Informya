import uuid
from app.core.database import Base

from sqlalchemy import Column, ForeignKey, String, Boolean, DateTime, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime, timezone
from sqlalchemy import UniqueConstraint
from sqlalchemy.orm import relationship

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False)
    username = Column(String, unique=True, nullable=False)
    hashed_password = Column(String, nullable=False)

    # Code d'invitation 8 caractères → partagé aux proches pour rejoindre
    invite_code = Column(String, unique=True, default=lambda: uuid.uuid4().hex[:8])

    # Style de lecture pour l'IA : "bullet" | "journalistic" | "simple"
    reading_style = Column(String, default="bullet")

    # Scores par catégorie mis à jour à chaque lecture
    # Ex: {"politique": 0.8, "sport": 0.3}
    interest_scores = Column(String, default="{}")

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                        onupdate=lambda: datetime.now(timezone.utc))

    # Historique de lecture → alimente le scoring de personnalisation
    read_history = relationship("ReadHistory", back_populates="user", lazy="select")

    # Favoris personnels
    bookmarks = relationship("Bookmark", back_populates="user", lazy="select")

    # Articles partagés envoyés et reçus
    sent_shares = relationship("SharedArticle", foreign_keys="SharedArticle.sender_id",
                               back_populates="sender", lazy="select")
    received_shares = relationship("SharedArticle", foreign_keys="SharedArticle.recipient_id",
                                   back_populates="recipient", lazy="select")
    
class UserSource(Base):
    __tablename__ = "user_sources"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    source_name = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Un utilisateur ne peut pas ajouter deux fois la même source
    __table_args__ = (
        UniqueConstraint("user_id", "source_name", name="uq_user_source"),
    )      