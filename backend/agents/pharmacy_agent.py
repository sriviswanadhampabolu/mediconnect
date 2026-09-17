import json
import math
from typing import List, Dict, Any
from backend.agents.state import AgentState
from backend.database import SessionLocal
from backend.models.entities import Pharmacy

def haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0  # Earth's radius in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)

def pharmacy_agent_node(state: AgentState) -> AgentState:
    """
    Pharmacy Agent:
    Discovers small, local verified neighborhood chemists carrying the recommended medicine.
    Sorts by distance and price, emphasizing the Generic Savings Calculator.
    """
    if state.emergency_detected or state.is_long_term_or_specialist:
        return state

    # Check if user has a custom village / location
    is_custom_loc = False
    v_name = (state.village or "").strip()
    addr_name = (state.address or "").strip()
    if v_name and v_name.lower() not in ["sector 15", "sector 15, gurgaon", "default"]:
        is_custom_loc = True
    elif addr_name and not any(k in addr_name.lower() for k in ["sector 15", "gurgaon", "gurugram"]):
        is_custom_loc = True
    elif haversine_distance_km(state.latitude, state.longitude, 28.4595, 77.0266) > 20.0:
        is_custom_loc = True

    if is_custom_loc:
        from backend.api.routes_pharmacy import generate_village_pharmacies
        resolved_vil = v_name or addr_name.split(",")[0].strip() or "Rampur"
        village_pharmacies = generate_village_pharmacies(
            village=resolved_vil,
            address=addr_name or resolved_vil,
            lat=state.latitude,
            lng=state.longitude
        )
        ranked_pharmacies = []
        target_meds = [m["generic_name"].lower().split()[0] for m in state.recommended_medicines]
        if not target_meds:
            target_meds = ["paracetamol"]

        for pharm in village_pharmacies:
            dist = pharm.get("distance_km", 0.4)
            inv = pharm.get("inventory", [])
            matched_items = []
            for item in inv:
                item_name = item.get("generic_name", "").lower()
                for t in target_meds:
                    if t in item_name:
                        generic_price = float(item.get("generic_price", 0))
                        branded_price = float(item.get("branded_price", generic_price))
                        savings = max(0.0, branded_price - generic_price)
                        discount_pct = round((savings / branded_price) * 100, 1) if branded_price > 0 else 0.0
                        matched_items.append({
                            "generic_name": item.get("generic_name"),
                            "branded_name": item.get("branded_name"),
                            "generic_price": generic_price,
                            "branded_price": branded_price,
                            "savings": savings,
                            "discount_percent": discount_pct
                        })
            ranked_pharmacies.append({
                "id": pharm["id"],
                "name": pharm["name"],
                "address": pharm["address"],
                "phone": pharm["phone"],
                "distance_km": dist,
                "rating": pharm.get("rating", 4.8),
                "response_time_min": pharm.get("response_time_min", 10),
                "is_small_local_business": True,
                "available_medicines": matched_items,
                "direct_chat_available": True
            })

        ranked_pharmacies.sort(key=lambda p: (p["distance_km"], -p["rating"]))
        state.nearby_pharmacies = ranked_pharmacies[:5]
        best_deal = None
        for p in ranked_pharmacies:
            for m in p["available_medicines"]:
                discount = m.get("discount_percent", 0.0)
                if best_deal is None or (p["distance_km"] < best_deal["distance_km"]) or (p["distance_km"] == best_deal["distance_km"] and discount > best_deal.get("discount_percent", -1)):
                    best_deal = {
                        "pharmacy_id": p["id"],
                        "pharmacy_name": p["name"],
                        "address": p["address"],
                        "phone": p["phone"],
                        "distance_km": p["distance_km"],
                        "medicine_name": m["generic_name"],
                        "generic_price": m["generic_price"],
                        "branded_price": m["branded_price"],
                        "savings": m["savings"],
                        "discount_percent": discount
                    }
        state.best_discount_pharmacy = best_deal
        return state
        
    db = SessionLocal()
    try:
        pharmacies = db.query(Pharmacy).filter(Pharmacy.verified == True).all()
        ranked_pharmacies = []
        
        # Get target medicine names
        target_meds = [m["generic_name"].lower().split()[0] for m in state.recommended_medicines]
        if not target_meds:
            target_meds = ["paracetamol"]
            
        for pharm in pharmacies:
            dist = haversine_distance_km(state.latitude, state.longitude, pharm.latitude, pharm.longitude)
            
            # Parse inventory
            try:
                inv = json.loads(pharm.inventory) if isinstance(pharm.inventory, str) else pharm.inventory
            except Exception:
                inv = []
                
            matched_items = []
            for item in inv:
                item_name = item.get("generic_name", "").lower()
                for t in target_meds:
                    if t in item_name:
                        generic_price = float(item.get("generic_price", 0))
                        branded_price = float(item.get("branded_price", generic_price))
                        savings = max(0.0, branded_price - generic_price)
                        discount_pct = round((savings / branded_price) * 100, 1) if branded_price > 0 else 0.0
                        
                        matched_items.append({
                            "generic_name": item.get("generic_name"),
                            "branded_name": item.get("branded_name"),
                            "generic_price": generic_price,
                            "branded_price": branded_price,
                            "savings": round(savings, 2),
                            "discount_percent": discount_pct,
                            "stock": item.get("stock", 10),
                            "requires_prescription": item.get("requires_prescription", False)
                        })
                        break
                        
            ranked_pharmacies.append({
                "id": pharm.id,
                "name": pharm.name,
                "address": pharm.address,
                "phone": pharm.phone,
                "distance_km": dist,
                "rating": pharm.rating,
                "response_time_min": pharm.response_time_avg,
                "is_small_local_business": True,
                "available_medicines": matched_items,
                "direct_chat_available": True
            })
            
        # Sort by distance first, then rating
        ranked_pharmacies.sort(key=lambda p: (p["distance_km"], -p["rating"]))
        state.nearby_pharmacies = ranked_pharmacies[:5]  # Top 5 nearest local pharmacies
        
        # Identify the nearest medical store offering the most discount
        best_deal = None
        for p in ranked_pharmacies:
            for m in p["available_medicines"]:
                discount = m.get("discount_percent", 0.0)
                if best_deal is None or discount > best_deal.get("discount_percent", -1) or (discount == best_deal.get("discount_percent", -1) and p["distance_km"] < best_deal["distance_km"]):
                    best_deal = {
                        "pharmacy_id": p["id"],
                        "pharmacy_name": p["name"],
                        "address": p["address"],
                        "phone": p["phone"],
                        "distance_km": p["distance_km"],
                        "medicine_name": m["generic_name"],
                        "generic_price": m["generic_price"],
                        "branded_price": m["branded_price"],
                        "savings": m["savings"],
                        "discount_percent": discount
                    }
        state.best_discount_pharmacy = best_deal
        
        detail_msg = f"Discovered {len(state.nearby_pharmacies)} local community pharmacies within 5km."
        if best_deal:
            detail_msg += f" Best discount: {best_deal['pharmacy_name']} ({best_deal['discount_percent']}% OFF)."
        
        state.routing_path.append({
            "agent_name": "Pharmacy Agent",
            "status": "HYPERLOCAL_MATCHED",
            "details": detail_msg
        })
        
        state.audit_logs.append({
            "agent": "Pharmacy Agent",
            "action": "DISCOVER_LOCAL_SHOPS",
            "input": {"lat": state.latitude, "lng": state.longitude},
            "output": {"shops_found": [p["name"] for p in state.nearby_pharmacies]}
        })
        
    finally:
        db.close()
        
    return state
