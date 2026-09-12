from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime

class ContactItem(BaseModel):
    name: str
    phone: str
    relation: Optional[str] = "Family"

class UserProfileUpdate(BaseModel):
    name: Optional[str] = None
    contact: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    emergency_contacts: Optional[List[ContactItem]] = None
    payment_limit: Optional[float] = None

class MedicalRecordCreate(BaseModel):
    condition: Optional[str] = None
    prescribing_source: Optional[str] = "doctor"
    notes: Optional[str] = None
    allergies: List[str] = []
    chronic_conditions: List[str] = []

class MedicationHistoryItem(BaseModel):
    medicine_name: str
    generic_name: str
    dosage: Optional[str] = None
    prescribed_by: Optional[str] = "Doctor"
    active: bool = True

class TriageMessageRequest(BaseModel):
    user_id: str
    message: str
    latitude: Optional[float] = 28.6139
    longitude: Optional[float] = 77.2090
    voice_transcript: Optional[str] = None

class MedicineRecommendation(BaseModel):
    generic_name: str
    branded_name: str
    dosage_and_usage: str
    rationale: str
    requires_prescription: bool = False
    average_generic_price: float
    average_branded_price: float
    savings_amount: float

class AgentStepBreadcrumb(BaseModel):
    agent_name: str
    status: str
    details: str

class TriageResponse(BaseModel):
    session_id: str
    user_id: str
    severity: str  # "normal", "urgent", "emergency"
    emergency_detected: bool
    summary: str
    candidate_condition: Optional[str] = None
    home_remedies: List[str] = []
    medicines: List[MedicineRecommendation] = []
    contraindication_warnings: List[str] = []
    doctor_referral_needed: bool = False
    routing_path: List[AgentStepBreadcrumb] = []
    emergency_event_id: Optional[str] = None
    hospital_appointment_suggested: bool = False
    hospital_appointment_details: Optional[Dict[str, Any]] = None
    best_discount_pharmacy: Optional[Dict[str, Any]] = None

class OrderItem(BaseModel):
    medicine_name: str
    is_generic: bool = True
    unit_price: float
    quantity: int = 1

class CreateOrderRequest(BaseModel):
    user_id: str
    pharmacy_id: str
    items: List[OrderItem]
    payment_method: Optional[str] = "UPI_AUTOPAY"
    bypass_limit_confirmation: bool = False

class OrderResponse(BaseModel):
    order_id: str
    pharmacy_id: str
    pharmacy_name: str
    status: str
    subtotal: float
    generic_savings: float
    total_amount: float
    commission_rate_percent: float
    commission_amount: float
    auto_pay_approved: bool
    requires_manual_confirmation: bool
    message: str

class EmergencyTriggerRequest(BaseModel):
    user_id: str
    location_label: Optional[str] = "Current GPS Location"
    latitude: Optional[float] = 28.6139
    longitude: Optional[float] = 77.2090
    reason: Optional[str] = "Manual One-Tap SOS"
