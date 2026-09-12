import pytest
from backend.seed_data import init_db_and_seed, SAMPLE_USER_ID
from backend.agents.state import AgentState
from backend.agents.master_graph import run_master_orchestrator
from backend.agents.medicine_agent import is_denylisted
from backend.agents.order_agent import calculate_order_financials
from backend.agents.payment_agent import process_payment
from backend.security.crypto import encrypt_data, decrypt_data
from backend.config import settings

@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    init_db_and_seed()

@pytest.mark.asyncio
async def test_safety_agent_emergency_veto():
    """Verify emergency symptoms immediately trigger safety veto and ambulance dispatch."""
    state = AgentState(
        user_id=SAMPLE_USER_ID,
        message="I have severe crushing chest pain and feel like I am having a heart attack",
        latitude=28.6139,
        longitude=77.2090
    )
    result = await run_master_orchestrator(state)
    
    assert result.emergency_detected is True
    assert result.severity == "emergency"
    assert result.emergency_event_id is not None
    assert "EMERGENCY" in result.summary
    # Ensure routine medicine agent was bypassed entirely
    assert len(result.recommended_medicines) == 0

@pytest.mark.asyncio
async def test_medical_history_allergy_crosscheck():
    """Verify Medical History Agent runs before Medicine Agent and blocks allergic medicines."""
    # User has Aspirin and NSAIDs allergy in seed data
    state = AgentState(
        user_id=SAMPLE_USER_ID,
        message="I have a terrible tension headache and muscular strain",
        latitude=28.6139,
        longitude=77.2090
    )
    result = await run_master_orchestrator(state)
    
    assert result.emergency_detected is False
    assert len(result.allergies) > 0
    # Any NSAID (Ibuprofen / Aspirin) must be blocked
    med_names = [m["generic_name"].lower() for m in result.recommended_medicines]
    for name in med_names:
        assert "ibuprofen" not in name
        assert "aspirin" not in name
        
    # Contraindication warning should be present
    assert any("ALLERGY CONTRAINDICATION" in w for w in result.contraindication_warnings)
    # Safe alternative should be recommended (e.g. Paracetamol)
    assert any("paracetamol" in name for name in med_names)

def test_restricted_formulations_denylist():
    """Verify Section 5 prohibition of eye/ear/nasal drops and scheduled antibiotics."""
    assert is_denylisted("Ofloxacin Eye Drop") is True
    assert is_denylisted("Neomycin Ear Drop") is True
    assert is_denylisted("Xylometazoline Nasal Spray") is True
    assert is_denylisted("Amoxicillin 500mg Antibiotic") is True
    assert is_denylisted("Paracetamol 500mg Tablet") is False

@pytest.mark.asyncio
async def test_long_term_symptom_routing():
    """Verify symptoms lasting weeks/months are flagged for clinic booking without auto-meds."""
    state = AgentState(
        user_id=SAMPLE_USER_ID,
        message="I have had persistent severe back and joint pain for 3 months continuously",
        latitude=28.6139,
        longitude=77.2090
    )
    result = await run_master_orchestrator(state)
    
    assert result.is_long_term_or_specialist is True
    assert result.hospital_booking_suggested is True
    assert result.hospital_appointment_details is not None
    # No auto-medication should be issued
    assert len(result.recommended_medicines) == 0

def test_commission_rate_guardrails():
    """Verify pharmacy order commission is strictly between 5% and 10%."""
    items = [
        {"unit_price": 100.0, "quantity": 2, "is_generic": True, "branded_price_reference": 250.0}
    ]
    fin = calculate_order_financials(items)
    rate = fin["commission_rate"]
    assert 0.05 <= rate <= 0.10
    assert fin["commission_amount"] == round(200.0 * rate, 2)
    assert fin["generic_savings"] == 300.0  # (250-100)*2

def test_payment_agent_server_side_limit():
    """Verify payment agent blocks auto-pay if amount exceeds configured payment limit."""
    # Under limit (Limit is ₹1500)
    approved, res = process_payment(SAMPLE_USER_ID, "ord-001", 850.0, bypass_limit_confirmation=False)
    assert approved is True
    assert res["auto_approved"] is True
    
    # Over limit
    approved_over, res_over = process_payment(SAMPLE_USER_ID, "ord-002", 2200.0, bypass_limit_confirmation=False)
    assert approved_over is False
    assert res_over["auto_approved"] is False
    assert res_over["status"] == "PENDING_CONFIRMATION"

def test_encryption_at_rest():
    """Verify sensitive health notes and allergy data encrypt properly with Fernet/AES."""
    sensitive_data = {"allergies": ["Sulfa drugs", "Peanuts"], "chronic": "Type 2 Diabetes"}
    token = encrypt_data(sensitive_data)
    assert token != str(sensitive_data)
    decrypted = decrypt_data(token)
    assert decrypted == sensitive_data

@pytest.mark.asyncio
async def test_small_symptom_best_discount_and_remedies():
    """Verify small/mild symptoms return home remedies and the nearest medical store with highest discount."""
    state = AgentState(
        user_id=SAMPLE_USER_ID,
        message="I have a mild runny nose and mild cold since morning",
        latitude=28.6139,
        longitude=77.2090
    )
    result = await run_master_orchestrator(state)
    
    assert result.emergency_detected is False
    assert result.severity == "normal"
    # Must provide safe home remedies
    assert len(result.home_remedies) > 0
    # Must provide suitable safe OTC medicine
    assert len(result.recommended_medicines) > 0
    # Must compute best discount pharmacy
    assert result.best_discount_pharmacy is not None
    assert result.best_discount_pharmacy["discount_percent"] > 0
    assert result.best_discount_pharmacy["pharmacy_id"] is not None

@pytest.mark.asyncio
async def test_severe_symptom_hospital_booking():
    """Verify severe symptoms automatically book an emergency appointment at the nearest hospital."""
    state = AgentState(
        user_id=SAMPLE_USER_ID,
        message="I have severe sudden chest pain and I cannot breathe",
        latitude=28.6139,
        longitude=77.2090
    )
    result = await run_master_orchestrator(state)
    
    assert result.emergency_detected is True
    assert result.hospital_booking_suggested is True
    assert result.hospital_appointment_details is not None
    assert "token_id" in result.hospital_appointment_details
    assert "hospital_name" in result.hospital_appointment_details

def test_user_orders_and_appointments_endpoints():
    """Verify endpoints for user past orders and booked hospital appointments."""
    from fastapi.testclient import TestClient
    from backend.main import app
    client = TestClient(app)
    
    # 1. Past orders endpoint
    res_orders = client.get(f"/api/pharmacy/orders/user/{SAMPLE_USER_ID}")
    assert res_orders.status_code == 200
    assert isinstance(res_orders.json(), list)
    
    # 2. Booked appointments endpoint
    res_appts = client.get(f"/api/emergency/user/{SAMPLE_USER_ID}/appointments")
    assert res_appts.status_code == 200
    assert isinstance(res_appts.json(), list)

def test_user_profile_location_update():
    """Verify user can update address and manual GPS coordinates."""
    from fastapi.testclient import TestClient
    from backend.main import app
    client = TestClient(app)
    
    # Update profile address and coordinates
    payload = {
        "address": "45 Park Avenue, Sector 15, Gurgaon",
        "latitude": 28.4595,
        "longitude": 77.0266,
        "email": "rahul@health.in"
    }
    res = client.put(f"/api/records/user/{SAMPLE_USER_ID}/profile", json=payload)
    assert res.status_code == 200
    assert res.json()["status"] == "SUCCESS"
    
    # Verify read
    res_get = client.get(f"/api/records/user/{SAMPLE_USER_ID}")
    assert res_get.status_code == 200
    data = res_get.json()
    assert data["address"] == "45 Park Avenue, Sector 15, Gurgaon"
    assert data["latitude"] == 28.4595
    assert data["longitude"] == 77.0266
    assert data["email"] == "rahul@health.in"
    assert "created_at" in data
