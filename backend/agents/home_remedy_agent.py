from backend.agents.state import AgentState

def home_remedy_agent_node(state: AgentState) -> AgentState:
    """
    Home Remedy Agent:
    For mild/normal symptoms only, offers safe, non-invasive, pre-approved
    evidence-based supportive home care.
    Never applied during emergency or long-term escalation.
    """
    if state.emergency_detected or state.is_long_term_or_specialist or state.severity == "emergency":
        return state
        
    remedies = getattr(state, "_temp_remedies", [])
    if not remedies:
        remedies = [
            "Stay well-hydrated with warm water or oral rehydration fluids",
            "Get 7-8 hours of restful sleep in a well-ventilated room",
            "Monitor symptoms over the next 24 hours"
        ]
        
    state.home_remedies = remedies
    
    state.routing_path.append({
        "agent_name": "Home Remedy Agent",
        "status": "REMEDIES_ATTACHED",
        "details": f"Provided {len(remedies)} safe supportive home remedies."
    })
    
    state.audit_logs.append({
        "agent": "Home Remedy Agent",
        "action": "SUGGEST_REMEDIES",
        "input": state.candidate_condition,
        "output": remedies
    })
    
    return state
