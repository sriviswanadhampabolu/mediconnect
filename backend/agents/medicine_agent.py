from typing import List, Dict, Any
from backend.agents.state import AgentState

# Section 5 Hardcoded Denylist: Formulations prohibited from automated OTC recommendations
FORBIDDEN_FORMULATIONS = [
    "eye drop", "eye ointment", "ear drop", "nasal spray", "nasal drop",
    "injectable", "injection", "iv infusion", "suppository", "inhaler"
]

# Section 5 Hardcoded Denylist: Prescription-only scheduled classes
PRESCRIPTION_ONLY_CLASSES = [
    "antibiotic", "amoxicillin", "azithromycin", "ciprofloxacin", "doxycycline",
    "steroid", "prednisolone", "dexamethasone", "betamethasone",
    "sedative", "alprazolam", "clonazepam", "diazepam", "tramadol", "codeine"
]

# Standard OTC catalogue with safety metadata & generic pricing
OTC_MEDICINE_CATALOGUE = {
    "paracetamol": {
        "generic_name": "Paracetamol 500mg Tablet",
        "branded_name": "Crocin 500 / Calpol 500",
        "class": "analgesic_antipyretic",
        "allergens": ["paracetamol", "acetaminophen"],
        "contraindicated_conditions": ["severe liver disease", "cirrhosis"],
        "dosage_and_usage": "1 tablet every 6-8 hours as needed after meals. Max 3000mg/day.",
        "rationale": "First-line safe analgesic and antipyretic for mild pain and fever reduction.",
        "average_generic_price": 18.0,
        "average_branded_price": 45.0,
        "requires_prescription": False
    },
    "ibuprofen": {
        "generic_name": "Ibuprofen 400mg Tablet",
        "branded_name": "Brufen 400",
        "class": "nsaid",
        "allergens": ["ibuprofen", "nsaid", "nsaids", "aspirin"],
        "contraindicated_conditions": ["peptic ulcer", "gastritis", "kidney disease"],
        "dosage_and_usage": "1 tablet after meals with plenty of water. Do not take on empty stomach.",
        "rationale": "Anti-inflammatory pain relief for muscular pain or joint stiffness.",
        "average_generic_price": 22.0,
        "average_branded_price": 52.0,
        "requires_prescription": False
    },
    "cetirizine": {
        "generic_name": "Cetirizine 10mg Tablet",
        "branded_name": "Zyrtec / Cetzine 10",
        "class": "antihistamine",
        "allergens": ["cetirizine", "hydroxyzine"],
        "contraindicated_conditions": ["severe renal impairment"],
        "dosage_and_usage": "1 tablet at bedtime. May cause mild drowsiness.",
        "rationale": "Second-generation antihistamine to relieve runny nose, sneezing, and itching.",
        "average_generic_price": 15.0,
        "average_branded_price": 40.0,
        "requires_prescription": False
    },
    "famotidine": {
        "generic_name": "Famotidine 20mg Tablet",
        "branded_name": "Famocid 20",
        "class": "h2_blocker",
        "allergens": ["famotidine", "ranitidine"],
        "contraindicated_conditions": [],
        "dosage_and_usage": "1 tablet 30 minutes before meal or before bedtime.",
        "rationale": "H2-receptor antagonist that reduces gastric acid production.",
        "average_generic_price": 16.0,
        "average_branded_price": 38.0,
        "requires_prescription": False
    },
    "antacid gel": {
        "generic_name": "Magnesium & Aluminium Hydroxide Gel",
        "branded_name": "Digene / Gelusil Liquid",
        "class": "antacid",
        "allergens": [],
        "contraindicated_conditions": [],
        "dosage_and_usage": "1-2 teaspoons (5-10 ml) 30-60 minutes after meals and at bedtime.",
        "rationale": "Rapid neutralizer of stomach acid for acute heartburn and dyspepsia.",
        "average_generic_price": 60.0,
        "average_branded_price": 140.0,
        "requires_prescription": False
    },
    "diclofenac gel": {
        "generic_name": "Diclofenac Diethylamine 1.16% Gel",
        "branded_name": "Volini / Moov Gel",
        "class": "topical_nsaid",
        "allergens": ["diclofenac", "nsaid", "nsaids", "aspirin"],
        "contraindicated_conditions": ["open wounds"],
        "dosage_and_usage": "Apply a thin layer gently to affected area 3-4 times daily.",
        "rationale": "Localized topical pain relief without significant systemic absorption.",
        "average_generic_price": 45.0,
        "average_branded_price": 115.0,
        "requires_prescription": False
    }
}

def is_denylisted(candidate: str) -> bool:
    c_lower = candidate.lower()
    for forbidden in FORBIDDEN_FORMULATIONS:
        if forbidden in c_lower:
            return True
    for pres in PRESCRIPTION_ONLY_CLASSES:
        if pres in c_lower:
            return True
    return False

def check_allergy_contraindications(med_key: str, allergies: List[str], chronic_conditions: List[str]) -> List[str]:
    warnings = []
    med_info = OTC_MEDICINE_CATALOGUE.get(med_key, {})
    med_allergens = med_info.get("allergens", [])
    med_contra = med_info.get("contraindicated_conditions", [])
    
    user_allergies_lower = [a.lower().strip() for a in allergies]
    user_chronic_lower = [c.lower().strip() for c in chronic_conditions]
    
    for allergen in med_allergens:
        for user_allergy in user_allergies_lower:
            if allergen in user_allergy or user_allergy in allergen:
                warnings.append(f"ALLERGY CONTRAINDICATION: Patient has documented allergy to '{user_allergy}'. '{med_info['generic_name']}' is strictly blocked.")
                
    for contra in med_contra:
        for user_cond in user_chronic_lower:
            if contra in user_cond or user_cond in contra:
                warnings.append(f"CONDITION CONTRAINDICATION: Patient has '{user_cond}'. '{med_info['generic_name']}' is unsafe.")
                
    return warnings

def medicine_recommendation_agent_node(state: AgentState) -> AgentState:
    """
    Medicine Recommendation Agent:
    Evaluates candidate OTC medications against strict hardcoded guardrails,
    delivery-route denylists, and user-specific medical history / allergy contraindications.
    """
    if state.emergency_detected or state.is_long_term_or_specialist:
        # Do not recommend OTC medicines during emergency or long-term chronic clinical flags
        return state
        
    candidates = getattr(state, "_temp_otc_candidates", ["Paracetamol"])
    approved_meds = []
    contraindications = []
    
    for cand in candidates:
        cand_lower = cand.lower()
        
        # Check hardcoded denylist (nose/ear/eye/injectable/scheduled drugs)
        if is_denylisted(cand_lower):
            contraindications.append(
                f"SAFETY RESTRICTION: '{cand}' is on the restricted list (ear/eye/nasal drop or prescription-only). Automated recommendation forbidden."
            )
            state.doctor_referral_needed = True
            continue
            
        # Match against catalogue
        matched_key = None
        for key in OTC_MEDICINE_CATALOGUE:
            if key in cand_lower or cand_lower in key:
                matched_key = key
                break
                
        if not matched_key:
            # Safe default fallback if candidate recognized as paracetamol
            matched_key = "paracetamol"
            
        med_meta = OTC_MEDICINE_CATALOGUE[matched_key]
        
        # Cross-check allergies and conditions
        conflicts = check_allergy_contraindications(matched_key, state.allergies, state.chronic_conditions)
        if conflicts:
            contraindications.extend(conflicts)
            state.doctor_referral_needed = True
            
            # If NSAID was blocked due to allergy, try safe Paracetamol substitute if not allergic
            if "nsaid" in med_meta.get("class", "") and "paracetamol" not in [a.lower() for a in state.allergies]:
                sub_conflicts = check_allergy_contraindications("paracetamol", state.allergies, state.chronic_conditions)
                if not sub_conflicts:
                    sub_meta = OTC_MEDICINE_CATALOGUE["paracetamol"]
                    savings = sub_meta["average_branded_price"] - sub_meta["average_generic_price"]
                    approved_meds.append({
                        "generic_name": sub_meta["generic_name"],
                        "branded_name": sub_meta["branded_name"],
                        "dosage_and_usage": sub_meta["dosage_and_usage"],
                        "rationale": f"Safe non-NSAID alternative due to allergy: {sub_meta['rationale']}",
                        "requires_prescription": False,
                        "average_generic_price": sub_meta["average_generic_price"],
                        "average_branded_price": sub_meta["average_branded_price"],
                        "savings_amount": round(savings, 2)
                    })
            continue
            
        savings = med_meta["average_branded_price"] - med_meta["average_generic_price"]
        approved_meds.append({
            "generic_name": med_meta["generic_name"],
            "branded_name": med_meta["branded_name"],
            "dosage_and_usage": med_meta["dosage_and_usage"],
            "rationale": med_meta["rationale"],
            "requires_prescription": med_meta["requires_prescription"],
            "average_generic_price": med_meta["average_generic_price"],
            "average_branded_price": med_meta["average_branded_price"],
            "savings_amount": round(savings, 2)
        })
        
    state.recommended_medicines = approved_meds
    state.contraindication_warnings.extend(contraindications)
    
    status_detail = (
        f"Approved {len(approved_meds)} safe OTC option(s). "
        f"{len(contraindications)} safety restriction(s) triggered."
    )
    
    state.routing_path.append({
        "agent_name": "Medicine Recommendation Agent",
        "status": "EVALUATED_SAFE_OTC",
        "details": status_detail
    })
    
    state.audit_logs.append({
        "agent": "Medicine Recommendation Agent",
        "action": "CROSS_CHECK_RECOMMENDATION",
        "input": {"candidates": candidates, "allergies": state.allergies},
        "output": {
            "approved": [m["generic_name"] for m in approved_meds],
            "contraindications": contraindications
        }
    })
    
    return state
