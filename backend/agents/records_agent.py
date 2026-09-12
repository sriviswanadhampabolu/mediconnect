import json
from datetime import datetime, timezone
from backend.agents.state import AgentState
from backend.database import SessionLocal
from backend.models.entities import MedicalRecord, SymptomSession, AgentAuditLog
from backend.security.crypto import encrypt_data, encrypt_list

def records_agent_node(state: AgentState) -> AgentState:
    """
    Records Agent:
    Only persists data securely. Never provides read access for triage logic.
    Encrypts sensitive diagnosis notes and stores complete audit logs.
    """
    db = SessionLocal()
    try:
        # Create SymptomSession record
        session_record = SymptomSession(
            user_id=state.user_id,
            transcript=state.message,
            severity_classification=state.severity,
            recommended_action=state.summary or (
                "Emergency dispatched" if state.emergency_detected
                else f"Condition: {state.candidate_condition} | {len(state.recommended_medicines)} meds recommended"
            ),
            agents_path=json.dumps(state.routing_path)
        )
        db.add(session_record)
        
        # If a non-emergency routine condition was triaged, persist to encrypted MedicalRecord
        if not state.emergency_detected and state.candidate_condition:
            med_notes = {
                "session_id": session_record.id,
                "candidate_condition": state.candidate_condition,
                "remedies": state.home_remedies,
                "medicines": [m.get("generic_name") for m in state.recommended_medicines],
                "contraindications": state.contraindication_warnings
            }
            new_record = MedicalRecord(
                user_id=state.user_id,
                condition=state.candidate_condition,
                diagnosis_date=datetime.now(timezone.utc),
                prescribing_source="AI_Triage_System",
                encrypted_notes=encrypt_data(med_notes),
                encrypted_allergies=encrypt_list(state.allergies),
                encrypted_chronic_conditions=encrypt_list(state.chronic_conditions)
            )
            db.add(new_record)
            
        # Write all accumulated audit logs
        for log in state.audit_logs:
            audit_entry = AgentAuditLog(
                agent_name=log.get("agent", "Unknown"),
                user_id=state.user_id,
                action_type=log.get("action", "ACTION"),
                input_summary=json.dumps(log.get("input", ""))[:500],
                output_summary=json.dumps(log.get("output", ""))[:500]
            )
            db.add(audit_entry)
            
        db.commit()
        
        state.routing_path.append({
            "agent_name": "Records Agent",
            "status": "ENCRYPTED_PERSISTENCE_COMPLETE",
            "details": f"Session and audit logs securely encrypted and persisted."
        })
        
    finally:
        db.close()
        
    return state
