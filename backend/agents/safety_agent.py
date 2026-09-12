import re
from typing import Tuple
from backend.agents.state import AgentState

# Explicit emergency keywords and clinical indicators (fails toward caution)
EMERGENCY_PATTERNS = [
    r"\b(chest pain|crushing pain|pressure in chest|heart attack|cardiac arrest|chest tightness)\b",
    r"\b(can'?t breathe|unable to breathe|gasping|severe breathlessness|shortness of breath|blue lips|asphyxi)\b",
    r"\b(anaphylax|throat closing|throat swelling|swollen tongue|cannot swallow air)\b",
    r"\b(stroke|face droop|facial drooping|slurred speech|sudden paralysis|arm numb(ness)?)\b",
    r"\b(unconscious|passed out|fainted and won'?t wake|collapsed|seizure|convulsion)\b",
    r"\b(vomiting blood|coughing blood|severe bleeding|arterial bleed|gushing blood)\b",
    r"\b(suicid|kill myself|overdose|drank poison|swallowed bleach|cyanide|pesticide)\b",
    r"\b(thunderclap headache|worst headache of my life|stiff neck and high fever)\b",
    r"\b(compound fracture|deep stab|gunshot)\b",
    r"\b(severe\b.*?\b(chest|breath|bleeding|pain|headache|fever|abdomen|stomach)|severe|unbearable pain|critical emergency)\b"
]

URGENT_PATTERNS = [
    r"\b(high fever|fever above 103|vomiting continuously|severe abdominal pain|appendicitis|dehydration|bloody stool)\b",
    r"\b(burn|deep cut|sprain|dislocation|asthma flare)\b"
]

def evaluate_safety(text: str) -> Tuple[str, bool, str]:
    """
    Evaluates message severity with hardcoded guardrails.
    Fails toward caution: If there's any suspicion of life-threatening distress,
    emergency is triggered immediately.
    """
    cleaned = text.lower()
    is_chronic = bool(re.search(r"\b(weeks?|months?|years?|chronic|recurring)\b", cleaned))
    
    # Check for emergency patterns
    for pattern in EMERGENCY_PATTERNS:
        match = re.search(pattern, cleaned, re.IGNORECASE)
        if match:
            # If it's a chronic/long-term non-cardiac complaint, let Symptom Agent route to clinical specialist
            if is_chronic and not re.search(r"\b(chest|breath|stroke|bleed|suicid|unconscious|heart)\b", cleaned):
                continue
            reason = f"Emergency clinical marker identified: '{match.group(0)}'. Immediate medical escalation required."
            return "emergency", True, reason

    # Check for urgent patterns
    for pattern in URGENT_PATTERNS:
        match = re.search(pattern, cleaned, re.IGNORECASE)
        if match:
            reason = f"Urgent symptom identified: '{match.group(0)}'. Prompt doctor evaluation recommended."
            return "urgent", False, reason

    return "normal", False, ""

def safety_agent_node(state: AgentState) -> AgentState:
    """
    Safety Agent node: Executes BEFORE any other agent.
    Has absolute VETO power over routine flow.
    """
    input_text = f"{state.message} {state.voice_transcript or ''}".strip()
    severity, is_emergency, reason = evaluate_safety(input_text)
    
    state.severity = severity
    state.emergency_detected = is_emergency
    state.emergency_reason = reason
    
    if is_emergency:
        breadcrumb_detail = f"EMERGENCY VETO TRIGGERED: {reason}"
    else:
        breadcrumb_detail = f"Triage level cleared: {severity.upper()} severity."
        
    state.routing_path.append({
        "agent_name": "Safety Agent",
        "status": "EMERGENCY_INTERRUPT" if is_emergency else "CLEARED",
        "details": breadcrumb_detail
    })
    
    state.audit_logs.append({
        "agent": "Safety Agent",
        "action": "SEVERITY_TRIAGE",
        "input": input_text,
        "output": {"severity": severity, "is_emergency": is_emergency, "reason": reason}
    })
    
    return state
