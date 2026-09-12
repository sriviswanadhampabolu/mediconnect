import pytest
from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)

def test_login_demo_user():
    res = client.post("/api/auth/login", json={
        "identifier": "rahul@health.in",
        "password": "Demo123!"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["user"]["name"] == "Rahul Sharma"
    assert data["user"]["id"] == "usr-sample-001"

def test_demo_login_endpoint():
    res = client.post("/api/auth/demo-login")
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["user"]["name"] == "Rahul Sharma"

def test_signup_new_user():
    contact = "+91 99999 88888"
    email = "testuser@health.in"
    res = client.post("/api/auth/signup", json={
        "name": "Dr. Priya Sen",
        "contact": contact,
        "email": email,
        "password": "SecurePass123!",
        "address": "Sector 42, Gurgaon",
        "allergies": ["Sulfa Drugs"],
        "payment_limit": 2000.0
    })
    # If already exists in previous test runs, it may be 400 or 200
    if res.status_code == 200:
        data = res.json()
        assert data["success"] is True
        assert data["user"]["name"] == "Dr. Priya Sen"
        assert data["user"]["payment_limit"] == 2000.0
    else:
        assert res.status_code == 400

def test_login_invalid_credentials():
    res = client.post("/api/auth/login", json={
        "identifier": "nonexistent@health.in",
        "password": "wrongpassword"
    })
    assert res.status_code == 401
