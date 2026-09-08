import pytest
from app.core.exceptions import (
    AIQuotaExceededError,
    AIContentBlockedError,
    AIServiceError,
    InformyaError,
)
from app.services.ai_service import should_retry, _classify_gemini_error


def test_quota_error_stops_retry():
    """Un quota dépassé ne doit pas être retenté."""
    assert should_retry(AIQuotaExceededError("quota")) is False


def test_blocked_content_stops_retry():
    """Un contenu bloqué ne doit pas être retenté."""
    assert should_retry(AIContentBlockedError("blocked")) is False


def test_generic_error_allows_retry():
    """Une erreur technique doit être retentée."""
    assert should_retry(AIServiceError("timeout")) is True
    assert should_retry(ConnectionError("network")) is True


def test_classify_quota_error():
    error = _classify_gemini_error(Exception("429 RESOURCE_EXHAUSTED"))
    assert isinstance(error, AIQuotaExceededError)


def test_classify_blocked_error():
    error = _classify_gemini_error(Exception("Response blocked by SAFETY filter"))
    assert isinstance(error, AIContentBlockedError)


def test_classify_generic_error():
    error = _classify_gemini_error(Exception("Connection timeout"))
    assert isinstance(error, AIServiceError)
    assert not isinstance(error, AIQuotaExceededError)


def test_exception_hierarchy():
    """Toutes les erreurs IA héritent de InformyaError."""
    assert issubclass(AIServiceError, InformyaError)
    assert issubclass(AIQuotaExceededError, AIServiceError)