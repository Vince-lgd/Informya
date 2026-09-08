import pytest


async def test_register_success(client):
    response = await client.post("/auth/register", json={
        "email": "new@informya.com",
        "username": "newuser",
        "password": "ValidPass1!",
    })
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert data["user"]["email"] == "new@informya.com"
    assert data["user"]["invite_code"]  # code généré automatiquement


async def test_register_duplicate_email(client):
    payload = {
        "email": "dup@informya.com",
        "username": "user1",
        "password": "ValidPass1!",
    }
    await client.post("/auth/register", json=payload)

    # Deuxième inscription avec le même email
    payload["username"] = "user2"
    response = await client.post("/auth/register", json=payload)
    assert response.status_code == 400


async def test_register_weak_password(client):
    response = await client.post("/auth/register", json={
        "email": "weak@informya.com",
        "username": "weakuser",
        "password": "abc",  # trop court, pas de majuscule ni chiffre
    })
    assert response.status_code == 422


async def test_login_success(client):
    await client.post("/auth/register", json={
        "email": "login@informya.com",
        "username": "loginuser",
        "password": "ValidPass1!",
    })

    response = await client.post("/auth/login", json={
        "email": "login@informya.com",
        "password": "ValidPass1!",
    })
    assert response.status_code == 200
    assert "access_token" in response.json()


async def test_login_wrong_password(client):
    await client.post("/auth/register", json={
        "email": "wrong@informya.com",
        "username": "wronguser",
        "password": "ValidPass1!",
    })

    response = await client.post("/auth/login", json={
        "email": "wrong@informya.com",
        "password": "WrongPass1!",
    })
    assert response.status_code == 401


async def test_me_requires_auth(client):
    response = await client.get("/auth/me")
    assert response.status_code == 401


async def test_me_with_valid_token(client, auth_headers):
    response = await client.get("/auth/me", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["email"] == "test@informya.com"