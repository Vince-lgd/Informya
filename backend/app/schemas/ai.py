from pydantic import BaseModel, Field
from typing import Literal


class ArticleSummary(BaseModel):
    """
    Structure attendue en sortie du modèle IA.
    Validée par Pydantic — toute réponse non conforme est rejetée.
    """

    key_points: list[str] = Field(
        min_length=2,
        max_length=5,
        description="Points clés du résumé, 2 à 5 éléments",
    )

    confidence: Literal["high", "medium", "low"] = Field(
        description="Fiabilité du résumé selon la richesse du contenu source",
    )

    def to_display_text(self) -> str:
        """Convertit la structure en texte affichable côté mobile."""
        return "\n".join(f"• {point}" for point in self.key_points)