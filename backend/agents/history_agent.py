from typing import List
from backend.agents.state import AgentState
from backend.database import SessionLocal
from backend.models.entities import MedicalRecord, MedicationHistory
from backend.security.crypto import decrypt_list, decrypt_data

def medical_history_agent_node(state: AgentState) -> AgentState:
    """
    Medical History Agent:
    Must run BEFORE final medicine recommendation.
    Fetches encrypted past allergies, chronic conditions, and active medications
    to cross-check drug interactions and contraindications.
    """
    db = SessionLocal()
    try:
        # Fetch medical records for the user
        records = db.query(MedicalRecord).filter(MedicalRecord.user_id == state.user_id).all()
        allergies: List[str] = []
        chronic_conditions: List[str] = []
        
        for rec in records:
            if rec.encrypted_allergies:
                allergies.extend(decrypt_list(rec.encrypted_allergies))
            if rec.encrypted_chronic_conditions:
                chronic_conditions.extend(decrypt_list(rec.encrypted_chronic_conditions))
            if rec.condition and rec.condition not in chronic_conditions:
                chronic_conditions.append(rec.condition)
                
        # Deduplicate
        state.allergies = list(dict.fromkeys(allergies))
        state.chronic_conditions = list(dict.fromkeys(chronic_conditions))
        
        # Fetch active medications
        meds = db.query(MedicationHistory).filter(
            MedicationHistory.user_id == state.user_id,
            MedicationHistory.active == True
        ).all()
        
        state.active_medications = [
            {
                "medicine_name": m.medicine_name,
                "generic_name": m.generic_name,
                "dosage": m.dosage,
                "prescribed_by": m.prescribed_by
            }
            for m in meds
        ]
        
        details = (
            f"Loaded {len(state.allergies)} allergy alert(s) ({', '.join(state.allergies) if state.allergies else 'None'}), "
            f"{len(state.chronic_conditions)} chronic condition(s), "
            f"{len(state.active_medications)} active prescription(s)."
        )
        
        state.routing_path.append({
            "agent_name": "Medical History Agent",
            "status": "PROFILE_LOADED",
            "details": details
        })
        
        state.audit_logs.append({
            "agent": "Medical History Agent",
            "action": "READ_ENCRYPTED_HISTORY",
            "input": f"User ID: {state.user_id}",
            "output": {
                "allergies_count": len(state.allergies),
                "chronic_count": len(state.chronic_conditions),
                "active_meds_count": len(state.active_medications)
            }
        })
        
    finally:
        db.close()
        
    return state
