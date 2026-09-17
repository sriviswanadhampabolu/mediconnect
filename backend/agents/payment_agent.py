from typing import Dict, Any, Tuple
from backend.database import SessionLocal
from backend.models.entities import User, Payment, AgentAuditLog

def process_payment(
    user_id: str,
    order_id: str,
    amount: float,
    bypass_limit_confirmation: bool = False,
    payment_method: str = "UPI_AUTOPAY"
) -> Tuple[bool, Dict[str, Any]]:
    """
    Payment Agent:
    Enforces user-configured payment limits SERVER-SIDE.
    Amounts <= payment_limit: Auto-approved.
    Amounts > payment_limit: Strictly blocked unless manual user confirmation is passed.
    """
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        limit = user.payment_limit if user else 1000.0
        
        exceeds_limit = amount > limit
        
        if exceeds_limit and not bypass_limit_confirmation:
            # Deny auto-pay
            audit = AgentAuditLog(
                agent_name="Payment Agent",
                user_id=user_id,
                action_type="PAYMENT_LIMIT_EXCEEDED",
                input_summary=f"Order {order_id}: Amount ₹{amount} > Limit ₹{limit}",
                output_summary="Requires manual confirmation. Auto-pay blocked."
            )
            db.add(audit)
            db.commit()
            
            return False, {
                "status": "PENDING_CONFIRMATION",
                "auto_approved": False,
                "amount": amount,
                "user_limit": limit,
                "message": f"Payment amount (₹{amount:.2f}) exceeds your configured limit (₹{limit:.2f}). Please provide manual confirmation."
            }
            
        # Payment approved
        new_payment = Payment(
            user_id=user_id,
            order_id=order_id,
            amount=amount,
            auto_approved=not exceeds_limit,
            payment_method=payment_method,
            status="COMPLETED"
        )
        db.add(new_payment)

        # Deduct ordered amount from user's safe auto-pay limit guardrail
        remaining_limit = limit
        if user and not exceeds_limit:
            remaining_limit = max(0.0, float(user.payment_limit or 1000.0) - float(amount))
            user.payment_limit = remaining_limit
        
        audit = AgentAuditLog(
            agent_name="Payment Agent",
            user_id=user_id,
            action_type="PAYMENT_APPROVED",
            input_summary=f"Order {order_id}: Amount ₹{amount} (Limit: ₹{limit}, Remaining: ₹{remaining_limit:.2f})",
            output_summary=f"Payment {new_payment.id} processed via {payment_method}"
        )
        db.add(audit)
        db.commit()
        db.refresh(new_payment)
        
        return True, {
            "payment_id": new_payment.id,
            "status": "COMPLETED",
            "auto_approved": not exceeds_limit,
            "amount": amount,
            "user_limit": limit,
            "remaining_payment_limit": remaining_limit,
            "message": f"Payment of ₹{amount:.2f} processed successfully. Remaining Auto-Pay Limit: ₹{remaining_limit:.2f}."
        }
    finally:
        db.close()
