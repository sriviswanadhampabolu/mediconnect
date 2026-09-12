import re
from backend.agents.state import AgentState

# Indicators for symptoms that represent chronic, long-term, or specialist needs
LONG_TERM_INDICATORS = [
    r"\b(weeks?|months?|years?|chronic|recurring|constant for \d+|frequent episodes)\b",
    r"\b(unexplained weight loss|chronic joint pain|persistent back pain|constant dizziness)\b",
    r"\b(lump|growth|night sweats|chronic fatigue)\b"
]

COMMON_CONDITIONS = [
    {
        "name": "Mild Fever & General Body Weakness",
        "keywords": [r"\bfever\b", r"\bmild fever\b", r"\btemperature\b", r"\bchills\b", r"\bhot body\b", r"\bshivering\b"],
        "severity": "normal",
        "is_chronic": False,
        "otc_candidates": ["Paracetamol"],
        "remedies": ["Drink plenty of lukewarm water", "Rest in bed with a light blanket", "Cool cloth sponge on forehead"]
    },
    {
        "name": "Tension Headache / Head Pain",
        "keywords": [r"\bheadache\b", r"\bhead ache\b", r"\bmild head pain\b", r"\btemple throbbing\b", r"\bhead heavy\b", r"\bmigraine\b"],
        "severity": "normal",
        "is_chronic": False,
        "otc_candidates": ["Paracetamol", "Ibuprofen"],
        "remedies": ["Drink a tall glass of cool water", "Rest in a quiet, dark room for 20 minutes", "Gentle massage around temples"]
    },
    {
        "name": "Common Cold, Cough & Sore Throat",
        "keywords": [r"\bcold\b", r"\brunny nose\b", r"\bsneezing\b", r"\bsore throat\b", r"\bmild cough\b", r"\bthroat tickle\b", r"\bcough\b", r"\bthroat pain\b", r"\bflu\b"],
        "severity": "normal",
        "is_chronic": False,
        "otc_candidates": ["Cetirizine", "Paracetamol"],
        "remedies": ["Gargle with warm salt water 3 times a day", "Steam inhalation from a bowl of hot water", "Warm water with honey and ginger"]
    },
    {
        "name": "Stomach Acidity, Gas & Heartburn",
        "keywords": [r"\bacidity\b", r"\bheartburn\b", r"\bgas\b", r"\bstomach burn\b", r"\bindigestion\b", r"\bacid reflux\b", r"\bbloat\b", r"\bstomach pain\b"],
        "severity": "normal",
        "is_chronic": False,
        "otc_candidates": ["Magnesium & Aluminium Hydroxide Gel", "Famotidine"],
        "remedies": ["Sip a small glass of chilled milk", "Avoid lying flat for 2 hours after food", "Eat light meals like khichdi or toast"]
    },
    {
        "name": "Muscular Strain & Body Ache",
        "keywords": [r"\bbody ache\b", r"\bmuscle pain\b", r"\bsprain\b", r"\bworkout soreness\b", r"\bback ache\b", r"\bleg pain\b", r"\bneck pain\b", r"\bpain\b"],
        "severity": "normal",
        "is_chronic": False,
        "otc_candidates": ["Paracetamol", "Diclofenac Gel"],
        "remedies": ["Apply warm compress or hot water bag", "Gentle stretching and rest", "Avoid heavy lifting"]
    },
    {
        "name": "Mild Allergic Rhinitis & Eye Itching",
        "keywords": [r"\ballergy\b", r"\bitche?y eyes\b", r"\bdust allergy\b", r"\bpollen\b", r"\ballergic cough\b", r"\bskin rash\b"],
        "severity": "normal",
        "is_chronic": False,
        "otc_candidates": ["Cetirizine"],
        "remedies": ["Wash face with cool sterile water", "Avoid dusting or outdoor smoke", "Stay in clean indoor air"]
    }
]

def symptom_agent_node(state: AgentState) -> AgentState:
    """
    Symptom Agent:
    Predicts likely condition, asks clarifying questions if needed,
    and flags long-term / chronic conditions for hospital routing.
    """
    text = f"{state.message} {state.voice_transcript or ''}".lower()
    
    # Check for long-term indicators
    for pattern in LONG_TERM_INDICATORS:
        if re.search(pattern, text):
            state.is_long_term_or_specialist = True
            state.candidate_condition = "Persistent Health Issue (>2 Weeks)"
            state.condition_rationale = (
                "Symptoms have been present for multiple weeks. "
                "Taking medicines without a physical doctor checkup is not safe. We have organized a clinic visit for you."
            )
            state.routing_path.append({
                "agent_name": "Symptom Agent",
                "status": "LONG_TERM_FLAGGED",
                "details": state.condition_rationale
            })
            state.audit_logs.append({
                "agent": "Symptom Agent",
                "action": "DIAGNOSE_LONG_TERM",
                "input": text,
                "output": {"condition": state.candidate_condition, "is_chronic": True}
            })
            return state

    # Match routine conditions
    matched_condition = None
    for cond in COMMON_CONDITIONS:
        for kw in cond["keywords"]:
            if re.search(kw, text):
                matched_condition = cond
                break
        if matched_condition:
            break
            
    if matched_condition:
        state.candidate_condition = matched_condition["name"]
        state.condition_rationale = f"Your symptoms match {matched_condition['name']}."
        state._temp_otc_candidates = matched_condition["otc_candidates"]
        state._temp_remedies = matched_condition["remedies"]
    else:
        state.candidate_condition = "Mild General Discomfort"
        state.condition_rationale = "Your symptoms are mild and can be managed with safe rest and supportive care."
        state._temp_otc_candidates = ["Paracetamol"]
        state._temp_remedies = ["Drink plenty of warm water", "Get a good night's rest in a comfortable room"]

    state.routing_path.append({
        "agent_name": "Symptom Agent",
        "status": "CONDITION_IDENTIFIED",
        "details": f"Condition: {state.candidate_condition}"
    })
    
    state.audit_logs.append({
        "agent": "Symptom Agent",
        "action": "DIAGNOSE_ROUTINE",
        "input": text,
        "output": {"condition": state.candidate_condition}
    })
    
    return state
