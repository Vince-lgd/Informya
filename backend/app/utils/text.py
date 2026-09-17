def calculate_reading_time(text: str) -> int:
    """Estime le temps de lecture en minutes depuis un texte (~200 mots/min)."""
    word_count = len(text.split())
    return max(1, word_count // 200)


def calculate_reading_time_from_words(word_count: int) -> int:
    """
    Estime le temps de lecture en minutes depuis un nombre de mots déjà compté.
    Utilisé quand le texte complet a été récupéré par trafilatura.
    """
    return max(1, round(word_count / 200))


def detect_content_type(word_count: int) -> str:
    """Déduit le type de contenu depuis le nombre de mots."""
    if word_count < 80:
        return "brève"
    elif word_count < 300:
        return "article"
    return "analyse"