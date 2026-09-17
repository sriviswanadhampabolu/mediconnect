from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field

class AgentState(BaseModel):
    user_id: str
    message: str
    voice_transcript: Optional[str] = None
    latitude: float = 28.6139
    longitude: float = 77.2090
    village: Optional[str] = None
    address: Optional[str] = None
    
    # Safety assessment
    severity: str = "normal"  # "normal", "urgent", "emergency"
    emergency_detected: bool = False
    emergency_reason: Optional[str] = None
    emergency_event_id: Optional[str] = None
    
    # Medical history context (pulled by Medical History Agent before medicine triage)
    allergies: List[str] = []
    chronic_conditions: List[str] = []
    active_medications: List[Dict[str, Any]] = []
    
    # Symptom diagnosis
    candidate_condition: Optional[str] = None
    condition_rationale: Optional[str] = None
    is_long_term_or_specialist: bool = False
    
    # Recommendations & Guardrails
    home_remedies: List[str] = []
    recommended_medicines: List[Dict[str, Any]] = []
    contraindication_warnings: List[str] = []
    doctor_referral_needed: bool = False
    summary: str = ""
    
    # Hyperlocal discovery
    nearby_pharmacies: List[Dict[str, Any]] = []
    best_discount_pharmacy: Optional[Dict[str, Any]] = None
    hospital_booking_suggested: bool = False
    hospital_appointment_details: Optional[Dict[str, Any]] = None
    
    # Order & Payment
    order_id: Optional[str] = None
    payment_status: Optional[str] = None
    
    # Execution breadcrumbs & audit logging
    routing_path: List[Dict[str, str]] = []
    audit_logs: List[Dict[str, Any]] = []
