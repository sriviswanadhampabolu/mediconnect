import json
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Query
from backend.database import SessionLocal
from backend.models.entities import User, MedicalRecord, MedicationHistory, AgentAuditLog, SymptomSession
from backend.schemas.pydantic_models import UserProfileUpdate, MedicalRecordCreate, MedicationHistoryItem
from backend.security.crypto import encrypt_list, decrypt_list, encrypt_data, decrypt_data

router = APIRouter(prefix="/records", tags=["Medical Records & Profile"])

@router.get("/user/{user_id}")
def get_user_full_profile(user_id: str):
    """
    Fetches the user's decrypted profile, allergies, chronic conditions,
    active medication history, and past triage sessions.
    Every read access is logged in the audit trail.
    """
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        # Log read audit
        audit = AgentAuditLog(
            agent_name="API_Records_Controller",
            user_id=user_id,
            action_type="PATIENT_RECORD_VIEW",
            input_summary=f"Read full profile for {user_id}",
            output_summary="Decrypted record delivered to authorized client"
        )
        db.add(audit)
        db.commit()
        
        # Medical records
        med_records = db.query(MedicalRecord).filter(MedicalRecord.user_id == user_id).all()
        allergies = []
        conditions = []
        notes_history = []
        for r in med_records:
            if r.encrypted_allergies:
                allergies.extend(decrypt_list(r.encrypted_allergies))
            if r.encrypted_chronic_conditions:
                conditions.extend(decrypt_list(r.encrypted_chronic_conditions))
            if r.encrypted_notes:
                notes_history.append({
                    "date": str(r.diagnosis_date),
                    "condition": r.condition,
                    "prescribing_source": r.prescribing_source,
                    "notes": decrypt_data(r.encrypted_notes)
                })
                
        # Medications
        meds = db.query(MedicationHistory).filter(MedicationHistory.user_id == user_id).all()
        med_list = [
            {
                "id": m.id,
                "medicine_name": m.medicine_name,
                "generic_name": m.generic_name,
                "dosage": m.dosage,
                "prescribed_by": m.prescribed_by,
                "active": m.active
            }
            for m in meds
        ]
        
        # Past triage sessions
        sessions = db.query(SymptomSession).filter(SymptomSession.user_id == user_id).order_by(SymptomSession.created_at.desc()).limit(10).all()
        session_list = [
            {
                "id": s.id,
                "transcript": s.transcript,
                "severity": s.severity_classification,
                "recommended_action": s.recommended_action,
                "created_at": str(s.created_at)
            }
            for s in sessions
        ]
        
        contacts = []
        if user.emergency_contacts:
            try:
                contacts = json.loads(user.emergency_contacts)
            except Exception:
                contacts = []
                
        return {
            "id": user.id,
            "name": user.name,
            "contact": user.contact,
            "email": getattr(user, "email", None),
            "address": user.address,
            "latitude": user.latitude,
            "longitude": user.longitude,
            "emergency_contacts": contacts,
            "payment_limit": user.payment_limit,
            "allergies": list(dict.fromkeys(allergies)),
            "chronic_conditions": list(dict.fromkeys(conditions)),
            "active_medications": med_list,
            "clinical_notes": notes_history,
            "recent_sessions": session_list,
            "created_at": str(user.created_at) if user.created_at else str(datetime.now(timezone.utc))
        }
    finally:
        db.close()

@router.put("/user/{user_id}/profile")
def update_user_profile(user_id: str, payload: UserProfileUpdate):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        if payload.name:
            user.name = payload.name
        if payload.contact:
            user.contact = payload.contact
        if payload.email:
            user.email = payload.email
        if payload.address:
            user.address = payload.address
        if payload.latitude is not None:
            user.latitude = payload.latitude
        if payload.longitude is not None:
            user.longitude = payload.longitude
        if payload.payment_limit is not None:
            user.payment_limit = payload.payment_limit
        if payload.emergency_contacts is not None:
            user.emergency_contacts = json.dumps([c.dict() for c in payload.emergency_contacts])
            
        db.commit()
        return {"status": "SUCCESS", "message": "Profile updated successfully"}
    finally:
        db.close()

@router.post("/user/{user_id}/allergy")
def add_user_allergy(user_id: str, allergy: str):
    """
    Adds a verified allergen to the patient's encrypted record.
    """
    db = SessionLocal()
    try:
        record = MedicalRecord(
            user_id=user_id,
            condition="Allergy Record",
            diagnosis_date=datetime.now(timezone.utc),
            prescribing_source="patient_update",
            encrypted_allergies=encrypt_list([allergy.strip()]),
            encrypted_notes=encrypt_data(f"Allergy to '{allergy.strip()}' recorded.")
        )
        db.add(record)
        
        audit = AgentAuditLog(
            agent_name="Records Agent",
            user_id=user_id,
            action_type="ALLERGY_ADDED",
            input_summary=f"Added allergy: {allergy}",
            output_summary="Saved to encrypted medical records"
        )
        db.add(audit)
        db.commit()
        return {"status": "SUCCESS", "allergy_added": allergy.strip()}
    finally:
        db.close()

@router.get("/audit_logs")
def get_audit_logs(limit: int = 50):
    """
    Returns audit logs of agent decisions, inputs, and outputs for regulatory compliance.
    """
    db = SessionLocal()
    try:
        logs = db.query(AgentAuditLog).order_by(AgentAuditLog.timestamp.desc()).limit(limit).all()
        return [
            {
                "id": l.id,
                "agent_name": l.agent_name,
                "user_id": l.user_id,
                "action_type": l.action_type,
                "input_summary": l.input_summary,
                "output_summary": l.output_summary,
                "timestamp": str(l.timestamp)
            }
            for l in logs
        ]
    finally:
        db.close()
