import pytest
from app.models.article import Article
from uuid import uuid4
from datetime import datetime, timezone


@pytest.fixture
async def sample_articles(db_session):
    """Insère quelques articles de test."""
    articles = [
        Article(
            id=uuid4(),
            title="Article politique",
            url="https://test.com/politique-1",
            url_hash="hash1",
            content="Contenu politique",
            source_name="Le Monde",
            source_url="lemonde.fr",
            category="politique",
            source_bias="center",
            reading_time=2,
            content_type="article",
            published_at=datetime.now(timezone.utc),
        ),
        Article(
            id=uuid4(),
            title="Article sport",
            url="https://test.com/sport-1",
            url_hash="hash2",
            content="Contenu sport",
            source_name="L'Équipe",
            source_url="lequipe.fr",
            category="sport",
            source_bias="center",
            reading_time=5,
            content_type="analyse",
            published_at=datetime.now(timezone.utc),
        ),
    ]
    for a in articles:
        db_session.add(a)
    await db_session.commit()
    return articles


async def test_feed_requires_auth(client):
    response = await client.get("/feed")
    assert response.status_code == 401


async def test_feed_returns_articles(client, auth_headers, sample_articles):
    response = await client.get("/feed", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 2
    assert len(data["articles"]) == 2


async def test_feed_filter_by_category(client, auth_headers, sample_articles):
    response = await client.get("/feed?category=sport", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["articles"][0]["category"] == "sport"


async def test_feed_filter_by_reading_time(client, auth_headers, sample_articles):
    response = await client.get("/feed?max_reading_time=3", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["articles"][0]["reading_time"] == 2


async def test_feed_favorites_only_empty(client, auth_headers, sample_articles):
    """Sans source favorite, l'onglet favoris doit être vide."""
    response = await client.get("/feed?favorites_only=true", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["total"] == 0


async def test_bookmark_flow(client, auth_headers, sample_articles):
    article_id = str(sample_articles[0].id)

    # Ajout
    response = await client.post(
        "/users/bookmarks",
        headers=auth_headers,
        json={"article_id": article_id},
    )
    assert response.status_code == 201

    # Liste
    response = await client.get("/users/bookmarks", headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json()) == 1

    # Doublon refusé
    response = await client.post(
        "/users/bookmarks",
        headers=auth_headers,
        json={"article_id": article_id},
    )
    assert response.status_code == 400

    # Suppression
    response = await client.delete(
        f"/users/bookmarks/{article_id}",
        headers=auth_headers,
    )
    assert response.status_code == 204

    # Liste vide
    response = await client.get("/users/bookmarks", headers=auth_headers)
    assert len(response.json()) == 0


async def test_favorite_sources_flow(client, auth_headers):
    # Ajout
    response = await client.post(
        "/users/sources",
        headers=auth_headers,
        json={"source_name": "Sud Ouest"},
    )
    assert response.status_code == 201

    # Liste
    response = await client.get("/users/sources", headers=auth_headers)
    assert "Sud Ouest" in response.json()["sources"]

    # Suppression
    response = await client.delete("/users/sources/Sud%20Ouest", headers=auth_headers)
    assert response.status_code == 204