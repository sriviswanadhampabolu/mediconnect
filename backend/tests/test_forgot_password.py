import pytest
from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)

def test_forgot_password_unknown_email():
    res = client.post("/api/auth/forgot-password", json={
        "email": "notfound_user_999@test.com"
    })
    assert res.status_code == 404
    data = res.json()
    assert "No account found" in data["detail"]

def test_forgot_password_and_reset_flow():
    email = "rahul@health.in"
    
    # 1. Request forgot password code
    res = client.post("/api/auth/forgot-password", json={"email": email})
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert "dev_code" in data
    code = data["dev_code"]
    assert len(code) == 6
    
    # 2. Try reset with wrong code
    res_wrong = client.post("/api/auth/reset-password", json={
        "email": email,
        "code": "000000",
        "new_password": "NewSecretPassword123!"
    })
    assert res_wrong.status_code == 400
    assert "Invalid verification code" in res_wrong.json()["detail"]
    
    # 3. Reset with correct code
    res_reset = client.post("/api/auth/reset-password", json={
        "email": email,
        "code": code,
        "new_password": "BrandNewPassword123!"
    })
    assert res_reset.status_code == 200
    assert res_reset.json()["success"] is True
    
    # 4. Try logging in with the old password (should fail)
    res_old_login = client.post("/api/auth/login", json={
        "identifier": email,
        "password": "WrongPassword999!"
    })
    assert res_old_login.status_code == 401
    
    # 5. Log in with the newly reset password
    res_new_login = client.post("/api/auth/login", json={
        "identifier": email,
        "password": "BrandNewPassword123!"
    })
    assert res_new_login.status_code == 200
    assert res_new_login.json()["user"]["email"] == email

    # 6. Test role mismatch check (rahul is customer, trying pharmacy_owner login)
    res_role_mismatch = client.post("/api/auth/login", json={
        "identifier": email,
        "password": "BrandNewPassword123!",
        "expected_role": "pharmacy_owner"
    })
    assert res_role_mismatch.status_code == 400
    assert "registered as a Customer" in res_role_mismatch.json()["detail"]

    # 7. Restore password to Demo123! for idempotency
    res_forgot2 = client.post("/api/auth/forgot-password", json={"email": email})
    assert res_forgot2.status_code == 200
    code2 = res_forgot2.json()["dev_code"]
    res_restore = client.post("/api/auth/reset-password", json={
        "email": email,
        "code": code2,
        "new_password": "Demo123!"
    })
    assert res_restore.status_code == 200
