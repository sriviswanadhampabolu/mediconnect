from fastapi import APIRouter, HTTPException
from backend.database import SessionLocal
from backend.models.entities import EmergencyEvent
from backend.schemas.pydantic_models import EmergencyTriggerRequest
from backend.agents.state import AgentState
from backend.agents.emergency_agent import emergency_agent_node
from backend.agents.hospital_agent import hospital_agent_node
import json

router = APIRouter(prefix="/emergency", tags=["Emergency Services"])

@router.post("/trigger")
def trigger_manual_emergency(payload: EmergencyTriggerRequest):
    """
    One-tap manual emergency SOS trigger.
    Bypasses all routine triage, immediately dispatches ambulance, auto-books nearest emergency ER hospital appointment, and broadcasts to emergency contacts.
    """
    state = AgentState(
        user_id=payload.user_id,
        message=f"MANUAL SOS TRIGGER: {payload.reason}",
        latitude=payload.latitude or 28.6139,
        longitude=payload.longitude or 77.2090,
        emergency_detected=True,
        emergency_reason=payload.reason or "Manual Emergency SOS Pressed"
    )
    
    state = emergency_agent_node(state)
    state = hospital_agent_node(state)
    
    return {
        "status": "DISPATCHED",
        "emergency_event_id": state.emergency_event_id,
        "summary": state.summary,
        "hospital_appointment_details": state.hospital_appointment_details,
        "routing_info": state.routing_path[-1] if state.routing_path else {}
    }

@router.get("/{event_id}")
def get_emergency_event(event_id: str):
    db = SessionLocal()
    try:
        event = db.query(EmergencyEvent).filter(EmergencyEvent.id == event_id).first()
        if not event:
            raise HTTPException(status_code=404, detail="Emergency event not found")
            
        contacts = []
        if event.contacts_alerted:
            try:
                contacts = json.loads(event.contacts_alerted)
            except Exception:
                contacts = []
                
        return {
            "id": event.id,
            "user_id": event.user_id,
            "status": event.status,
            "ambulance_booking_id": event.ambulance_booking_id,
            "hospital_name": event.hospital_name,
            "location": event.location,
            "latitude": event.latitude,
            "longitude": event.longitude,
            "contacts_alerted": contacts,
            "timestamp": str(event.timestamp)
        }
    finally:
        db.close()

@router.get("/user/{user_id}/appointments")
def get_user_appointments(user_id: str):
    """
    Returns all booked emergency ER passes and clinical appointments for a patient.
    """
    db = SessionLocal()
    try:
        events = db.query(EmergencyEvent).filter(EmergencyEvent.user_id == user_id).order_by(EmergencyEvent.timestamp.desc()).all()
        results = []
        for ev in events:
            token = getattr(ev, "token_id", None) or ev.ambulance_booking_id.replace("AMB-", "ER-")[:8]
            appt_type = getattr(ev, "appointment_type", None) or "EMERGENCY_PRIORITY_ADMISSION"
            results.append({
                "id": ev.id,
                "hospital_name": ev.hospital_name or "Apollo Emergency & Cardiac Trauma Centre",
                "token_id": token,
                "appointment_type": appt_type,
                "ambulance_booking_id": ev.ambulance_booking_id,
                "location": ev.location,
                "status": ev.status,
                "timestamp": str(ev.timestamp)
            })
        return results
    finally:
        db.close()
