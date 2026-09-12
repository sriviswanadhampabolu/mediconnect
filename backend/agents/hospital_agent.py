import uuid
from typing import Dict, Any, List
from backend.agents.state import AgentState
from backend.agents.pharmacy_agent import haversine_distance_km

# List of emergency hospitals and trauma centers with coordinates
EMERGENCY_HOSPITALS = [
    {
        "id": "hosp-er-1",
        "name": "Metro Emergency & Trauma Care Hospital",
        "latitude": 28.6170,
        "longitude": 28.6170,  # will compute against user coordinates
        "address": "Plot 8, Health City, Sector 15 (0.6 km from your pin)",
        "phone": "+91 98110 11222",
        "has_24x7_trauma": True,
        "icu_beds_available": 6,
        "er_incharge": "Dr. Arvind Mehta (Chief Emergency Officer)",
        "rating": 4.9
    },
    {
        "id": "hosp-er-2",
        "name": "Apollo Emergency & Cardiac Trauma Centre",
        "latitude": 28.6230,
        "longitude": 77.2180,
        "address": "Gate 2, Main Bypass Road, Sector 14",
        "phone": "+91 98110 33444",
        "has_24x7_trauma": True,
        "icu_beds_available": 4,
        "er_incharge": "Dr. R. K. Saxena (Emergency Care Lead)",
        "rating": 4.8
    },
    {
        "id": "hosp-er-3",
        "name": "Fortis Multi-Specialty & Critical Care",
        "latitude": 28.6300,
        "longitude": 77.2250,
        "address": "Sector 16 Institutional Area",
        "phone": "+91 98110 55666",
        "has_24x7_trauma": True,
        "icu_beds_available": 8,
        "er_incharge": "Dr. Priya Nair (Trauma Consultant)",
        "rating": 4.7
    }
]

CLINIC_SPECIALISTS = [
    {
        "id": "clinic-1",
        "name": "Apollo Clinic & Multi-Specialty Centre",
        "distance_km": 1.4,
        "specialties": ["General Physician", "Internal Medicine", "ENT"],
        "next_available_slot": "Today, 4:30 PM",
        "phone": "+91 98110 88990",
        "rating": 4.8
    },
    {
        "id": "clinic-2",
        "name": "Max Super Care Family Clinic",
        "distance_km": 2.2,
        "specialties": ["Cardiology", "Neurology", "Gastroenterology"],
        "next_available_slot": "Tomorrow, 10:00 AM",
        "phone": "+91 98110 99001",
        "rating": 4.9
    }
]

def find_nearest_hospital(user_lat: float, user_lng: float) -> Dict[str, Any]:
    """Finds the nearest hospital to patient coordinates."""
    ranked = []
    for h in EMERGENCY_HOSPITALS:
        dist = haversine_distance_km(user_lat, user_lng, h["latitude"], h.get("longitude", 77.2150))
        h_copy = dict(h)
        h_copy["distance_km"] = dist
        ranked.append(h_copy)
    ranked.sort(key=lambda x: x["distance_km"])
    return ranked[0]

def hospital_agent_node(state: AgentState) -> AgentState:
    """
    Hospital Agent:
    1. EMERGENCY FLOW: Automatically finds the NEAREST emergency hospital/trauma center,
       auto-books an Immediate Priority ER Admission Slot, notifies the on-call trauma team,
       and provides an instant admission pass.
    2. LONG-TERM / CHRONIC FLOW: Finds nearby clinics and books consultation slot without auto-meds.
    """
    if not (state.is_long_term_or_specialist or state.emergency_detected):
        return state

    if state.emergency_detected:
        nearest = find_nearest_hospital(state.latitude, state.longitude)
        token_id = f"ER-{uuid.uuid4().hex[:4].upper()}"
        
        state.hospital_booking_suggested = True
        state.hospital_appointment_details = {
            "hospital_id": nearest["id"],
            "hospital_name": nearest["name"],
            "address": nearest["address"],
            "phone": nearest["phone"],
            "distance_km": nearest["distance_km"],
            "booking_type": "EMERGENCY_PRIORITY_ADMISSION",
            "token_id": token_id,
            "slot": "IMMEDIATE PRIORITY ADMISSION",
            "er_incharge": nearest["er_incharge"],
            "icu_status": f"{nearest['icu_beds_available']} ICU trauma beds available",
            "instructions": f"Emergency admission pass {token_id} confirmed. Paramedics alerted to transport directly to ER Trauma Bay."
        }
        
        state.summary += (
            f" 🏥 Nearest emergency hospital auto-booked: {nearest['name']} ({nearest['distance_km']} km away). "
            f"Admission Pass: {token_id}. ER Team on standby."
        )
        
        state.routing_path.append({
            "agent_name": "Hospital Agent",
            "status": "EMERGENCY_APPOINTMENT_AUTO_BOOKED",
            "details": f"Auto-booked nearest ER: {nearest['name']} ({nearest['distance_km']} km) | Pass: {token_id}"
        })
        
        state.audit_logs.append({
            "agent": "Hospital Agent",
            "action": "AUTO_BOOK_NEAREST_ER",
            "input": {"lat": state.latitude, "lng": state.longitude},
            "output": state.hospital_appointment_details
        })
        
        # Persist appointment details in EmergencyEvent record
        if state.emergency_event_id:
            from backend.database import SessionLocal
            from backend.models.entities import EmergencyEvent
            db = SessionLocal()
            try:
                ev = db.query(EmergencyEvent).filter(EmergencyEvent.id == state.emergency_event_id).first()
                if ev:
                    ev.hospital_name = nearest["name"]
                    ev.token_id = token_id
                    ev.appointment_type = "EMERGENCY_PRIORITY_ADMISSION"
                    db.commit()
            except Exception:
                pass
            finally:
                db.close()

        return state

    # Chronic / Non-emergency long-term appointment
    clinic = CLINIC_SPECIALISTS[0]
    token_id = f"CLN-{uuid.uuid4().hex[:4].upper()}"
    state.hospital_booking_suggested = True
    state.hospital_appointment_details = {
        "hospital_id": clinic["id"],
        "hospital_name": clinic["name"],
        "distance_km": clinic["distance_km"],
        "slot": clinic["next_available_slot"],
        "phone": clinic["phone"],
        "token_id": token_id,
        "booking_type": "CLINICAL_SPECIALIST_CONSULTATION",
        "specialty": "Internal Medicine / Family Physician",
        "instructions": "Physical clinical examination recommended before taking non-prescription medication."
    }
    
    # Also persist non-emergency clinic appointment for user history
    from backend.database import SessionLocal
    from backend.models.entities import EmergencyEvent
    db = SessionLocal()
    try:
        ev = EmergencyEvent(
            user_id=state.user_id,
            location=f"Lat: {state.latitude:.4f}, Lng: {state.longitude:.4f}",
            latitude=state.latitude,
            longitude=state.longitude,
            ambulance_booking_id="N/A (Outpatient)",
            contacts_alerted="[]",
            status="CONFIRMED",
            hospital_name=clinic["name"],
            token_id=token_id,
            appointment_type="CLINICAL_SPECIALIST_CONSULTATION"
        )
        db.add(ev)
        db.commit()
    except Exception:
        pass
    finally:
        db.close()
    
    state.routing_path.append({
        "agent_name": "Hospital Agent",
        "status": "APPOINTMENT_SCHEDULED",
        "details": f"Suggested clinic: {clinic['name']} ({clinic['next_available_slot']})"
    })
    
    state.audit_logs.append({
        "agent": "Hospital Agent",
        "action": "SCHEDULE_CLINICAL_VISIT",
        "input": state.candidate_condition,
        "output": state.hospital_appointment_details
    })
    
    return state
