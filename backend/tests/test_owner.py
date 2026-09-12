import json
from fastapi.testclient import TestClient
from backend.main import app
from backend.seed_data import init_db_and_seed

client = TestClient(app)

def setup_module():
    init_db_and_seed()

def test_owner_demo_login():
    res = client.post("/api/auth/owner-demo-login")
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["user"]["role"] == "pharmacy_owner"
    assert data["user"]["store_id"] == "pharm-001"

def test_owner_dashboard():
    res = client.get("/api/pharmacy/owner/dashboard/pharm-001")
    assert res.status_code == 200
    data = res.json()
    assert "pharmacy" in data
    assert data["pharmacy"]["id"] == "pharm-001"
    assert "sales_summary" in data
    assert data["sales_summary"]["daily_sales"] > 0
    assert "highest_ordered_medicines" in data
    assert len(data["highest_ordered_medicines"]) > 0
    assert "inventory" in data
    assert len(data["inventory"]) > 0

def test_owner_update_stock():
    # Update Paracetamol 650 stock
    res = client.post(
        "/api/pharmacy/owner/inventory/pharm-001/update-stock",
        json={"medicine_id": "med-p02", "delta": 10}
    )
    assert res.status_code == 200
    assert res.json()["success"] is True

def test_persistent_chat():
    # Send chat from customer
    res = client.post("/api/pharmacy/chat/send", json={
        "pharmacy_id": "pharm-001",
        "user_id": "usr-sample-001",
        "sender_role": "customer",
        "sender_name": "Rahul Sharma",
        "message": "Do you have Dolo 650 available today?"
    })
    assert res.status_code == 200
    assert res.json()["message"] == "Do you have Dolo 650 available today?"

    # Fetch messages
    res_get = client.get("/api/pharmacy/chat/messages?pharmacy_id=pharm-001&user_id=usr-sample-001")
    assert res_get.status_code == 200
    messages = res_get.json()
    assert len(messages) >= 1
