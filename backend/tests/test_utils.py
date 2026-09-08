from app.utils.text import calculate_reading_time, detect_content_type
from app.services.ai_service import clean_html, _clean_summary
from app.services.cache_service import get_safe_style, get_cache_key


def test_calculate_reading_time():
    # 200 mots = 1 minute
    text = " ".join(["mot"] * 200)
    assert calculate_reading_time(text) == 1

    # 600 mots = 3 minutes
    text = " ".join(["mot"] * 600)
    assert calculate_reading_time(text) == 3

    # Texte très court = minimum 1 minute
    assert calculate_reading_time("court") == 1


def test_detect_content_type():
    assert detect_content_type(50) == "brève"
    assert detect_content_type(200) == "article"
    assert detect_content_type(500) == "analyse"


def test_clean_html():
    html = '<p>Bonjour <strong>monde</strong></p>'
    assert clean_html(html) == "Bonjour monde"

    # Espaces multiples normalisés
    assert clean_html("a    b\n\nc") == "a b c"


def test_clean_summary_removes_intro():
    raw = "Voici un résumé en 3 points :\n* Premier point\n* Second point"
    result = _clean_summary(raw)
    assert "Voici" not in result
    assert "• Premier point" in result


def test_clean_summary_normalizes_bullets():
    raw = "* Point un\n- Point deux"
    result = _clean_summary(raw)
    assert result.count("•") == 2


def test_get_safe_style():
    assert get_safe_style("bullet") == "bullet"
    assert get_safe_style("journalistic") == "journalistic"
    assert get_safe_style("invalide") == "bullet"  # fallback
    assert get_safe_style(None) == "bullet"


def test_get_cache_key():
    key = get_cache_key("abc-123", "bullet")
    assert key == "ai_summary:abc-123:bullet"