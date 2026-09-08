class InformyaError(Exception):
    """Erreur de base de l'application."""
    pass


# ── Erreurs IA ────────────────────────────────────────────

class AIServiceError(InformyaError):
    """Erreur générique lors de la génération du résumé IA."""
    pass


class AIQuotaExceededError(AIServiceError):
    """Quota API dépassé (429) — inutile de retenter immédiatement."""
    pass


class AIContentBlockedError(AIServiceError):
    """Contenu bloqué par les filtres de sécurité du modèle."""
    pass


class AIEmptyResponseError(AIServiceError):
    """Le modèle a renvoyé une réponse vide."""
    pass


class InsufficientContentError(InformyaError):
    """Contenu source insuffisant pour générer un résumé."""
    pass