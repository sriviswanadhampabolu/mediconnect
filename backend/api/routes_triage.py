import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException
from backend.schemas.pydantic_models import TriageMessageRequest, TriageResponse, MedicineRecommendation, AgentStepBreadcrumb
from backend.agents.state import AgentState
from backend.agents.master_graph import run_master_orchestrator

router = APIRouter(prefix="/triage", tags=["Triage & Agents"])

@router.post("/message", response_model=TriageResponse)
async def process_triage_message(payload: TriageMessageRequest):
    """
    HTTP endpoint to process a user symptom or health message through
    the multi-agent pipeline with hardcoded safety vetoes.
    """
    initial_state = AgentState(
        user_id=payload.user_id,
        message=payload.message,
        voice_transcript=payload.voice_transcript,
        latitude=payload.latitude or 28.6139,
        longitude=payload.longitude or 77.2090,
        village=payload.village,
        address=payload.address
    )
    
    final_state = await run_master_orchestrator(initial_state)
    
    # Format response
    meds = [
        MedicineRecommendation(
            generic_name=m["generic_name"],
            branded_name=m["branded_name"],
            dosage_and_usage=m["dosage_and_usage"],
            rationale=m["rationale"],
            requires_prescription=m.get("requires_prescription", False),
            average_generic_price=m["average_generic_price"],
            average_branded_price=m["average_branded_price"],
            savings_amount=m["savings_amount"]
        )
        for m in final_state.recommended_medicines
    ]
    
    crumbs = [
        AgentStepBreadcrumb(
            agent_name=c["agent_name"],
            status=c["status"],
            details=c["details"]
        )
        for c in final_state.routing_path
    ]
    
    return TriageResponse(
        session_id=final_state.routing_path[-1].get("details", "")[:8] if final_state.routing_path else "session-001",
        user_id=final_state.user_id,
        severity=final_state.severity,
        emergency_detected=final_state.emergency_detected,
        summary=final_state.summary,
        candidate_condition=final_state.candidate_condition,
        home_remedies=final_state.home_remedies,
        medicines=meds,
        contraindication_warnings=final_state.contraindication_warnings,
        doctor_referral_needed=final_state.doctor_referral_needed or final_state.is_long_term_or_specialist,
        routing_path=crumbs,
        emergency_event_id=final_state.emergency_event_id,
        hospital_appointment_suggested=final_state.hospital_booking_suggested,
        hospital_appointment_details=final_state.hospital_appointment_details,
        best_discount_pharmacy=final_state.best_discount_pharmacy
    )

@router.websocket("/ws/{user_id}")
async def triage_websocket_stream(websocket: WebSocket, user_id: str):
    """
    WebSocket endpoint that streams real-time agent execution breadcrumbs
    as each specialist agent in the LangGraph evaluates the user request.
    """
    await websocket.accept()
    try:
        while True:
            raw_data = await websocket.receive_text()
            data = json.loads(raw_data)
            user_msg = data.get("message", "")
            lat = float(data.get("latitude", 28.6139))
            lng = float(data.get("longitude", 77.2090))
            
            async def send_step_update(step_data):
                await websocket.send_text(json.dumps({
                    "type": "AGENT_STEP",
                    "step": step_data
                }))
                
            state = AgentState(
                user_id=user_id,
                message=user_msg,
                voice_transcript=data.get("voice_transcript"),
                latitude=lat,
                longitude=lng
            )
            
            final_state = await run_master_orchestrator(state, on_step_update=send_step_update)
            
            # Send final completion event
            await websocket.send_text(json.dumps({
                "type": "TRIAGE_COMPLETE",
                "severity": final_state.severity,
                "emergency_detected": final_state.emergency_detected,
                "summary": final_state.summary,
                "candidate_condition": final_state.candidate_condition,
                "home_remedies": final_state.home_remedies,
                "medicines": final_state.recommended_medicines,
                "contraindications": final_state.contraindication_warnings,
                "emergency_event_id": final_state.emergency_event_id,
                "hospital_suggested": final_state.hospital_booking_suggested,
                "pharmacies_found": len(final_state.nearby_pharmacies)
            }))
    except WebSocketDisconnect:
        pass
