import pytest
from pydantic import ValidationError
from app.schemas.ai import ArticleSummary


def test_valid_summary():
    summary = ArticleSummary(
        key_points=["Premier point factuel.", "Second point factuel."],
        confidence="high",
    )
    assert len(summary.key_points) == 2
    assert summary.confidence == "high"


def test_to_display_text_formats_bullets():
    summary = ArticleSummary(
        key_points=["Point A.", "Point B."],
        confidence="medium",
    )
    result = summary.to_display_text()
    assert result == "• Point A.\n• Point B."


def test_rejects_too_few_points():
    """Moins de 2 points doit être rejeté."""
    with pytest.raises(ValidationError):
        ArticleSummary(key_points=["Un seul point."], confidence="high")


def test_rejects_too_many_points():
    """Plus de 5 points doit être rejeté."""
    with pytest.raises(ValidationError):
        ArticleSummary(
            key_points=[f"Point {i}." for i in range(6)],
            confidence="high",
        )


def test_rejects_invalid_confidence():
    """Une valeur de confiance hors énumération doit être rejetée."""
    with pytest.raises(ValidationError):
        ArticleSummary(key_points=["A.", "B."], confidence="très sûr")


def test_parses_valid_json():
    """Le parsing depuis le JSON brut de Gemini doit fonctionner."""
    raw = '{"key_points": ["Point un.", "Point deux."], "confidence": "low"}'
    summary = ArticleSummary.model_validate_json(raw)
    assert summary.confidence == "low"
    assert len(summary.key_points) == 2


def test_rejects_malformed_json():
    with pytest.raises(ValidationError):
        ArticleSummary.model_validate_json('{"key_points": "pas une liste"}')