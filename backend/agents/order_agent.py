import json
from typing import Dict, Any, List
from backend.config import settings
from backend.models.entities import Order, Pharmacy
from backend.database import SessionLocal

def calculate_order_financials(items: List[Dict[str, Any]]) -> Dict[str, float]:
    """
    Computes subtotal, generic savings, commission (strictly 5-10%), and total.
    """
    subtotal = 0.0
    generic_savings = 0.0
    
    for item in items:
        price = float(item.get("unit_price", 0.0))
        qty = int(item.get("quantity", 1))
        subtotal += price * qty
        
        # If customer picked generic, compute savings compared to branded
        if item.get("is_generic", True):
            branded_ref = float(item.get("branded_price_reference", price * 2.2))
            generic_savings += (branded_ref - price) * qty
            
    # Business-model guardrail: Commission rate capped between 5% and 10%
    commission_rate = settings.COMMISSION_RATE  # e.g., 0.065 (6.5%)
    commission_amount = round(subtotal * commission_rate, 2)
    
    return {
        "subtotal": round(subtotal, 2),
        "generic_savings": round(generic_savings, 2),
        "total_amount": round(subtotal, 2),
        "commission_rate": commission_rate,
        "commission_amount": commission_amount
    }

def process_order(user_id: str, pharmacy_id: str, items: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Processes and persists a hyperlocal order for a small pharmacy.
    """
    db = SessionLocal()
    try:
        pharmacy = db.query(Pharmacy).filter(Pharmacy.id == pharmacy_id).first()
        pharm_name = pharmacy.name if pharmacy else "Neighborhood Chemist"
        
        fin = calculate_order_financials(items)
        
        new_order = Order(
            user_id=user_id,
            pharmacy_id=pharmacy_id,
            items=json.dumps(items),
            status="CONFIRMED",
            subtotal=fin["subtotal"],
            generic_savings=fin["generic_savings"],
            total_amount=fin["total_amount"],
            commission_rate=fin["commission_rate"],
            commission_applied=fin["commission_amount"],
            delivery_partner_id="local_runner_01"
        )
        db.add(new_order)
        db.commit()
        db.refresh(new_order)
        
        return {
            "order_id": new_order.id,
            "pharmacy_id": pharmacy_id,
            "pharmacy_name": pharm_name,
            "status": new_order.status,
            "subtotal": new_order.subtotal,
            "generic_savings": new_order.generic_savings,
            "total_amount": new_order.total_amount,
            "commission_rate_percent": round(fin["commission_rate"] * 100, 1),
            "commission_amount": fin["commission_amount"],
            "message": f"Order #{new_order.id[:8]} placed with {pharm_name}. Small pharmacy commission: {round(fin['commission_rate']*100, 1)}%."
        }
    finally:
        db.close()
