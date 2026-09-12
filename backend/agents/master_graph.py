import asyncio
from typing import Callable, Optional, Dict, Any
from backend.agents.state import AgentState
from backend.agents.safety_agent import safety_agent_node
from backend.agents.history_agent import medical_history_agent_node
from backend.agents.symptom_agent import symptom_agent_node
from backend.agents.medicine_agent import medicine_recommendation_agent_node
from backend.agents.home_remedy_agent import home_remedy_agent_node
from backend.agents.pharmacy_agent import pharmacy_agent_node
from backend.agents.emergency_agent import emergency_agent_node
from backend.agents.hospital_agent import hospital_agent_node
from backend.agents.records_agent import records_agent_node

StepCallback = Optional[Callable[[Dict[str, str]], Any]]

async def run_master_orchestrator(
    state: AgentState,
    on_step_update: StepCallback = None
) -> AgentState:
    """
    Master Agent:
    Orchestrates the multi-agent graph with strict routing rules:
    
    1. Safety Agent runs FIRST on every turn.
    2. If EMERGENCY:
       - Interrupts routine flow immediately.
       - Dispatches Emergency Agent (Ambulance + SOS contacts).
       - Routes to Hospital Agent.
       - Persists via Records Agent.
       - Done.
    3. If CLEAR / NORMAL / URGENT:
       - Runs Medical History Agent to pull allergies & active meds.
       - Runs Symptom Agent to diagnose and flag long-term vs routine.
       - If LONG-TERM / CHRONIC:
         - Hospital Agent organizes clinical appointment (No auto-meds).
       - If ROUTINE:
         - Runs Medicine Recommendation Agent (applies allergy & formulation denylists).
         - Runs Home Remedy Agent (pre-approved mild care).
         - Runs Pharmacy Agent (hyperlocal neighborhood discovery + generic savings).
       - Runs Records Agent (writes encrypted record & audit trail).
    """
    async def notify_step(agent_name: str, status: str, details: str):
        if on_step_update:
            data = {"agent_name": agent_name, "status": status, "details": details}
            if asyncio.iscoroutinefunction(on_step_update):
                await on_step_update(data)
            else:
                on_step_update(data)

    # 1. Master Agent initialization
    state.routing_path.append({
        "agent_name": "Master Agent",
        "status": "INITIALIZED",
        "details": "Parsed intent and dispatched message to Safety Guardrails."
    })
    await notify_step("Master Agent", "INITIALIZED", "Triage session initialized.")

    # 2. Safety Agent (Always runs first with VETO power)
    state = safety_agent_node(state)
    last_step = state.routing_path[-1]
    await notify_step("Safety Agent", last_step["status"], last_step["details"])

    # Branch: Emergency Flow
    if state.emergency_detected:
        # Emergency Agent (Ambulance + SOS)
        state = emergency_agent_node(state)
        last_step = state.routing_path[-1]
        await notify_step("Emergency Agent", last_step["status"], last_step["details"])

        # Hospital Agent (Trauma auto-connect)
        state = hospital_agent_node(state)
        last_step = state.routing_path[-1]
        await notify_step("Hospital Agent", last_step["status"], last_step["details"])

        # Records Agent (Persistence)
        state = records_agent_node(state)
        last_step = state.routing_path[-1]
        await notify_step("Records Agent", last_step["status"], last_step["details"])

        return state

    # Branch: Routine & Non-Emergency Flow
    # 3. Medical History Agent (MUST run before medicine recommendation)
    state = medical_history_agent_node(state)
    last_step = state.routing_path[-1]
    await notify_step("Medical History Agent", last_step["status"], last_step["details"])

    # 4. Symptom Agent
    state = symptom_agent_node(state)
    last_step = state.routing_path[-1]
    await notify_step("Symptom Agent", last_step["status"], last_step["details"])

    # Check if flagged as long-term/chronic
    if state.is_long_term_or_specialist:
        state = hospital_agent_node(state)
        last_step = state.routing_path[-1]
        await notify_step("Hospital Agent", last_step["status"], last_step["details"])
        
        state.summary = (
            f"Your symptoms have been present for an extended period. "
            f"Automated medication is held for your safety. "
            f"A specialist consultation has been prepared at {state.hospital_appointment_details.get('hospital_name', 'Clinic')}."
        )
    else:
        # 5. Medicine Recommendation Agent (cross-checks history, allergies & denylists)
        state = medicine_recommendation_agent_node(state)
        last_step = state.routing_path[-1]
        await notify_step("Medicine Recommendation Agent", last_step["status"], last_step["details"])

        # 6. Home Remedy Agent
        state = home_remedy_agent_node(state)
        last_step = state.routing_path[-1]
        await notify_step("Home Remedy Agent", last_step["status"], last_step["details"])

        # 7. Pharmacy Agent (Hyperlocal local chemists + generic savings)
        state = pharmacy_agent_node(state)
        last_step = state.routing_path[-1]
        await notify_step("Pharmacy Agent", last_step["status"], last_step["details"])

        med_summary = f"{len(state.recommended_medicines)} safe OTC options evaluated"
        if state.contraindication_warnings:
            med_summary += f" ({len(state.contraindication_warnings)} allergy warning(s) applied)"
            
        state.summary = (
            f"Based on your symptoms, we identified likely {state.candidate_condition}. "
            f"{med_summary} and discovered {len(state.nearby_pharmacies)} local verified pharmacies nearby."
        )

    # 8. Records Agent (Encrypt and write audit logs)
    state = records_agent_node(state)
    last_step = state.routing_path[-1]
    await notify_step("Records Agent", last_step["status"], last_step["details"])

    return state
