import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, Text, DateTime, ForeignKey
)
from backend.database import Base

def gen_uuid():
    return str(uuid.uuid4())

def utc_now():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True, default=gen_uuid)
    name = Column(String(100), nullable=False)
    contact = Column(String(30), nullable=False, unique=True)
    email = Column(String(120), nullable=True, unique=True)
    password_hash = Column(String(255), nullable=True)
    address = Column(String(255), default="123 Local Street, Sector 4")
    latitude = Column(Float, default=28.6139)
    longitude = Column(Float, default=77.2090)
    # JSON list of emergency contact dicts: [{"name": "Dad", "phone": "+919876543210"}]
    emergency_contacts = Column(Text, default="[]")
    payment_limit = Column(Float, default=1000.0)
    role = Column(String(30), default="customer")  # "customer" or "pharmacy_owner"
    store_id = Column(String(36), nullable=True)  # Associated pharmacy ID if user is an owner
    created_at = Column(DateTime, default=utc_now)

class MedicalRecord(Base):
    __tablename__ = "medical_records"
    
    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    condition = Column(String(200), nullable=True)
    diagnosis_date = Column(DateTime, default=utc_now)
    prescribing_source = Column(String(50), default="agent")  # "agent" or "doctor"
    # Sensitive medical fields stored ENCRYPTED at rest
    encrypted_notes = Column(Text, nullable=True)
    encrypted_allergies = Column(Text, nullable=True)  # encrypted JSON list
    encrypted_chronic_conditions = Column(Text, nullable=True)  # encrypted JSON list
    created_at = Column(DateTime, default=utc_now)

class MedicationHistory(Base):
    __tablename__ = "medications_history"
    
    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    medicine_name = Column(String(150), nullable=False)
    generic_name = Column(String(150), nullable=False)
    dosage = Column(String(100), nullable=True)
    prescribed_by = Column(String(100), default="Dr. Sharma")
    date = Column(DateTime, default=utc_now)
    active = Column(Boolean, default=True)

class Pharmacy(Base):
    __tablename__ = "pharmacies"
    
    id = Column(String(36), primary_key=True, default=gen_uuid)
    name = Column(String(150), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address = Column(String(255), nullable=False)
    phone = Column(String(30), default="+91 98110 00000")
    # Inventory JSON: [{"id": "med-1", "generic_name": "Paracetamol 500mg", "branded_name": "Crocin 500", "generic_price": 18.0, "branded_price": 45.0, "stock": 50, "dosage_form": "tablet", "requires_prescription": false}]
    inventory = Column(Text, default="[]")
    generic_price_list = Column(Text, default="{}")
    branded_price_list = Column(Text, default="{}")
    response_time_avg = Column(Integer, default=12)  # minutes
    verified = Column(Boolean, default=True)
    rating = Column(Float, default=4.7)
    owner_user_id = Column(String(36), nullable=True)  # Links to User.id of the store owner

class Order(Base):
    __tablename__ = "orders"
    
    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    pharmacy_id = Column(String(36), ForeignKey("pharmacies.id"), nullable=False)
    items = Column(Text, nullable=False)  # JSON list of order items
    status = Column(String(50), default="PLACED")  # PLACED, CONFIRMED, OUT_FOR_DELIVERY, DELIVERED, CANCELLED
    subtotal = Column(Float, default=0.0)
    generic_savings = Column(Float, default=0.0)
    total_amount = Column(Float, default=0.0)
    delivery_partner_id = Column(String(50), default="hyperlocal_runner_01")
    commission_rate = Column(Float, default=0.065)
    commission_applied = Column(Float, default=0.0)
    created_at = Column(DateTime, default=utc_now)

class SymptomSession(Base):
    __tablename__ = "symptom_sessions"
    
    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    transcript = Column(Text, nullable=False)
    severity_classification = Column(String(30), default="normal")  # normal, urgent, emergency
    recommended_action = Column(Text, nullable=True)
    agents_path = Column(Text, default="[]")  # JSON list of agent breadcrumbs
    created_at = Column(DateTime, default=utc_now)

class EmergencyEvent(Base):
    __tablename__ = "emergency_events"
    
    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    location = Column(String(200), nullable=False)
    latitude = Column(Float, default=28.6139)
    longitude = Column(Float, default=77.2090)
    ambulance_booking_id = Column(String(50), default=gen_uuid)
    contacts_alerted = Column(Text, default="[]")  # JSON list of phone numbers alerted
    status = Column(String(50), default="DISPATCHED")
    hospital_name = Column(String(100), default="City Emergency Trauma Center")
    token_id = Column(String(50), nullable=True)
    appointment_type = Column(String(60), default="EMERGENCY_PRIORITY_ADMISSION")
    timestamp = Column(DateTime, default=utc_now)

class Payment(Base):
    __tablename__ = "payments"
    
    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    order_id = Column(String(64), nullable=True)
    amount = Column(Float, nullable=False)
    auto_approved = Column(Boolean, default=True)
    payment_method = Column(String(50), default="UPI_AUTOPAY")
    status = Column(String(50), default="COMPLETED")  # PENDING_CONFIRMATION, COMPLETED, REJECTED
    created_at = Column(DateTime, default=utc_now)

class AgentAuditLog(Base):
    __tablename__ = "agent_audit_logs"
    
    id = Column(String(36), primary_key=True, default=gen_uuid)
    agent_name = Column(String(60), nullable=False)
    user_id = Column(String(36), nullable=False)
    action_type = Column(String(60), nullable=False)
    input_summary = Column(Text, nullable=True)
    output_summary = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=utc_now)

class CustomerStoreChat(Base):
    __tablename__ = "customer_store_chats"
    
    id = Column(String(36), primary_key=True, default=gen_uuid)
    pharmacy_id = Column(String(36), ForeignKey("pharmacies.id"), nullable=False)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    sender_role = Column(String(20), default="customer")  # "customer" or "owner"
    sender_name = Column(String(100), default="Customer")
    message = Column(Text, nullable=False)
    created_at = Column(DateTime, default=utc_now)

class PasswordResetCode(Base):
    __tablename__ = "password_reset_codes"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    email = Column(String(120), nullable=False, index=True)
    code = Column(String(10), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    used = Column(Boolean, default=False)
    created_at = Column(DateTime, default=utc_now)

