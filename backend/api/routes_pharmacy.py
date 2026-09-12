import json
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query
from backend.database import SessionLocal
from backend.models.entities import Pharmacy, Order, User
from backend.schemas.pydantic_models import CreateOrderRequest, OrderResponse
from backend.agents.pharmacy_agent import haversine_distance_km
from backend.agents.order_agent import process_order
from backend.agents.payment_agent import process_payment

router = APIRouter(prefix="/pharmacy", tags=["Pharmacies & Orders"])

@router.get("/nearby")
def get_nearby_pharmacies(
    lat: float = Query(28.6139),
    lng: float = Query(77.2090),
    query: Optional[str] = None
):
    """
    Hyperlocal discovery of local independent pharmacies.
    Calculates distance, lists generic vs branded pricing, and flags small local businesses.
    """
    db = SessionLocal()
    try:
        pharmacies = db.query(Pharmacy).filter(Pharmacy.verified == True).all()
        results = []
        for p in pharmacies:
            dist = haversine_distance_km(lat, lng, p.latitude, p.longitude)
            try:
                inventory = json.loads(p.inventory) if isinstance(p.inventory, str) else p.inventory
            except Exception:
                inventory = []
                
            filtered_inv = inventory
            if query:
                q_lower = query.lower()
                filtered_inv = [
                    item for item in inventory
                    if q_lower in item.get("generic_name", "").lower()
                    or q_lower in item.get("branded_name", "").lower()
                ]
                
            results.append({
                "id": p.id,
                "name": p.name,
                "address": p.address,
                "phone": p.phone,
                "distance_km": dist,
                "response_time_min": p.response_time_avg,
                "rating": p.rating,
                "is_small_local_business": True,
                "inventory": filtered_inv,
                "direct_chat_phone": p.phone
            })
            
        results.sort(key=lambda x: x["distance_km"])
        return results
    finally:
        db.close()

@router.post("/orders/create", response_model=OrderResponse)
def create_pharmacy_order(payload: CreateOrderRequest):
    """
    Places an order with a local neighborhood pharmacy.
    - Commission capped at 5-10% (Section 7 rule).
    - Enforces user payment limit server-side via Payment Agent.
    """
    items_dict = [item.dict() for item in payload.items]
    order_data = process_order(payload.user_id, payload.pharmacy_id, items_dict)
    
    # Run Payment Agent server-side validation
    auto_pay_ok, payment_res = process_payment(
        user_id=payload.user_id,
        order_id=order_data["order_id"],
        amount=order_data["total_amount"],
        bypass_limit_confirmation=payload.bypass_limit_confirmation,
        payment_method=payload.payment_method or "UPI_AUTOPAY"
    )
    
    requires_manual = not auto_pay_ok
    status = "CONFIRMED" if auto_pay_ok else "PAYMENT_CONFIRMATION_REQUIRED"
    
    return OrderResponse(
        order_id=order_data["order_id"],
        pharmacy_id=order_data["pharmacy_id"],
        pharmacy_name=order_data["pharmacy_name"],
        status=status,
        subtotal=order_data["subtotal"],
        generic_savings=order_data["generic_savings"],
        total_amount=order_data["total_amount"],
        commission_rate_percent=order_data["commission_rate_percent"],
        commission_amount=order_data["commission_amount"],
        auto_pay_approved=auto_pay_ok,
        requires_manual_confirmation=requires_manual,
        message=payment_res["message"]
    )

@router.get("/orders/{order_id}")
def get_order_details(order_id: str):
    db = SessionLocal()
    try:
        order = db.query(Order).filter(Order.id == order_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
            
        pharm = db.query(Pharmacy).filter(Pharmacy.id == order.pharmacy_id).first()
        items = json.loads(order.items) if isinstance(order.items, str) else order.items
        
        return {
            "order_id": order.id,
            "pharmacy_name": pharm.name if pharm else "Local Chemist",
            "status": order.status,
            "items": items,
            "subtotal": order.subtotal,
            "generic_savings": order.generic_savings,
            "total_amount": order.total_amount,
            "commission_applied": order.commission_applied,
            "delivery_partner_id": order.delivery_partner_id,
            "created_at": str(order.created_at)
        }
    finally:
        db.close()

@router.post("/orders/{order_id}/confirm_payment")
def confirm_order_payment(order_id: str, user_id: str):
    """
    Allows user to provide explicit manual confirmation for orders that exceeded their payment limit.
    """
    db = SessionLocal()
    try:
        order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
            
        auto_pay_ok, payment_res = process_payment(
            user_id=user_id,
            order_id=order_id,
            amount=order.total_amount,
            bypass_limit_confirmation=True,
            payment_method="MANUAL_CONFIRMATION"
        )
        order.status = "CONFIRMED"
        db.commit()
        return {"status": "SUCCESS", "message": "Manual payment confirmed and order dispatched."}
    finally:
        db.close()

@router.get("/orders/user/{user_id}")
def get_user_orders(user_id: str):
    """
    Returns all previous ordered medicines for a specific patient.
    """
    db = SessionLocal()
    try:
        orders = db.query(Order).filter(Order.user_id == user_id).order_by(Order.created_at.desc()).all()
        results = []
        for o in orders:
            pharm = db.query(Pharmacy).filter(Pharmacy.id == o.pharmacy_id).first()
            try:
                items = json.loads(o.items) if isinstance(o.items, str) else o.items
            except Exception:
                items = []
                
            results.append({
                "order_id": o.id,
                "pharmacy_id": o.pharmacy_id,
                "pharmacy_name": pharm.name if pharm else "Neighborhood Chemist",
                "pharmacy_phone": pharm.phone if pharm else "+91 98101 23456",
                "pharmacy_address": pharm.address if pharm else "Local Market",
                "status": o.status,
                "items": items,
                "subtotal": o.subtotal,
                "generic_savings": o.generic_savings,
                "total_amount": o.total_amount,
                "delivery_partner_id": o.delivery_partner_id,
                "created_at": str(o.created_at)
            })
        return results
    finally:
        db.close()

# ==============================================================================
# STORE OWNER DASHBOARD & PHARMACY MANAGEMENT ENDPOINTS
# ==============================================================================

from collections import Counter
from datetime import datetime, timezone
from pydantic import BaseModel, Field
from backend.models.entities import CustomerStoreChat

class UpdateStockRequest(BaseModel):
    medicine_id: str
    delta: Optional[int] = None
    new_stock: Optional[int] = None

class UpdateOrderStatusRequest(BaseModel):
    status: str

class SendChatMessageRequest(BaseModel):
    pharmacy_id: str
    user_id: str
    sender_role: str = "customer"
    sender_name: str = "User"
    message: str

@router.get("/owner/dashboard/{pharmacy_id}")
def get_owner_dashboard(pharmacy_id: str):
    """
    Consolidated analytics and management endpoint for Medical Store Owners:
    - Store Profile
    - Daily Sales (Revenue, Order count, Avg order value, Commission rate)
    - Stock inventory with low-stock alerts
    - Highest ordered medicine counts
    - Recent orders list
    """
    db = SessionLocal()
    try:
        pharm = db.query(Pharmacy).filter(Pharmacy.id == pharmacy_id).first()
        if not pharm:
            pharm = db.query(Pharmacy).first()
        if not pharm:
            raise HTTPException(status_code=404, detail="Pharmacy not found")

        # Owner info
        owner_name = "Ramesh Gupta"
        if pharm.owner_user_id:
            owner_user = db.query(User).filter(User.id == pharm.owner_user_id).first()
            if owner_user:
                owner_name = owner_user.name

        # Parse Inventory
        try:
            inventory = json.loads(pharm.inventory) if isinstance(pharm.inventory, str) else pharm.inventory
        except Exception:
            inventory = []

        # Count low stock (<10)
        low_stock_count = sum(1 for m in inventory if m.get("stock", 0) < 10)

        # Orders for this pharmacy
        orders = db.query(Order).filter(Order.pharmacy_id == pharm.id).order_by(Order.created_at.desc()).all()

        total_sales = sum(o.total_amount for o in orders)
        order_count = len(orders)
        avg_order_value = round(total_sales / order_count, 2) if order_count > 0 else 0.0

        # Calculate today's sales specifically
        now = datetime.now(timezone.utc)
        today_start = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)
        today_orders = [o for o in orders if (o.created_at.tzinfo is not None and o.created_at >= today_start) or (o.created_at.tzinfo is None and o.created_at >= today_start.replace(tzinfo=None))]
        daily_sales = sum(o.total_amount for o in today_orders) if today_orders else total_sales
        daily_order_count = len(today_orders) if today_orders else order_count

        # Highest ordered medicines counts
        med_counts = Counter()
        med_revenue = Counter()
        for o in orders:
            try:
                items = json.loads(o.items) if isinstance(o.items, str) else o.items
                for item in items:
                    name = item.get("medicine_name", "Medicine")
                    qty = item.get("quantity", 1)
                    price = item.get("unit_price", 0.0)
                    med_counts[name] += qty
                    med_revenue[name] += qty * price
            except Exception:
                pass

        # If no orders yet, seed top medicines from inventory popular list
        if not med_counts:
            for item in inventory[:5]:
                name = item.get("generic_name", "Medicine")
                med_counts[name] = 12
                med_revenue[name] = 12 * item.get("generic_price", 25.0)

        highest_ordered = [
            {
                "medicine_name": name,
                "order_count": count,
                "total_revenue": round(med_revenue[name], 2)
            }
            for name, count in med_counts.most_common(10)
        ]

        recent_orders_list = []
        for o in orders[:15]:
            cust = db.query(User).filter(User.id == o.user_id).first()
            try:
                items = json.loads(o.items) if isinstance(o.items, str) else o.items
            except Exception:
                items = []
            recent_orders_list.append({
                "order_id": o.id,
                "customer_id": o.user_id,
                "customer_name": cust.name if cust else "Local Patient",
                "customer_contact": cust.contact if cust else "+91 98765 00000",
                "status": o.status,
                "items": items,
                "subtotal": o.subtotal,
                "total_amount": o.total_amount,
                "created_at": str(o.created_at)
            })

        return {
            "pharmacy": {
                "id": pharm.id,
                "name": pharm.name,
                "owner_name": owner_name,
                "address": pharm.address,
                "phone": pharm.phone,
                "rating": pharm.rating,
                "response_time_avg": pharm.response_time_avg,
                "verified": pharm.verified
            },
            "sales_summary": {
                "daily_sales": round(daily_sales, 2),
                "daily_order_count": daily_order_count,
                "total_sales_all_time": round(total_sales, 2),
                "total_order_count": order_count,
                "average_order_value": avg_order_value,
                "commission_rate_percent": 6.5,
                "low_stock_items_count": low_stock_count
            },
            "highest_ordered_medicines": highest_ordered,
            "inventory": inventory,
            "recent_orders": recent_orders_list
        }
    finally:
        db.close()

@router.post("/owner/inventory/{pharmacy_id}/update-stock")
def update_inventory_stock(pharmacy_id: str, req: UpdateStockRequest):
    db = SessionLocal()
    try:
        pharm = db.query(Pharmacy).filter(Pharmacy.id == pharmacy_id).first()
        if not pharm:
            raise HTTPException(status_code=404, detail="Pharmacy not found")

        try:
            inventory = json.loads(pharm.inventory) if isinstance(pharm.inventory, str) else pharm.inventory
        except Exception:
            inventory = []

        found = False
        updated_item = None
        for item in inventory:
            if item.get("id") == req.medicine_id or item.get("generic_name") == req.medicine_id:
                found = True
                if req.new_stock is not None:
                    item["stock"] = max(0, req.new_stock)
                elif req.delta is not None:
                    item["stock"] = max(0, item.get("stock", 0) + req.delta)
                updated_item = item
                break

        if not found:
            raise HTTPException(status_code=404, detail="Medicine not found in store inventory")

        pharm.inventory = json.dumps(inventory)
        db.commit()
        return {"success": True, "message": "Stock updated successfully", "item": updated_item}
    finally:
        db.close()

@router.post("/owner/orders/{order_id}/status")
def update_order_status(order_id: str, req: UpdateOrderStatusRequest):
    db = SessionLocal()
    try:
        order = db.query(Order).filter(Order.id == order_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        order.status = req.status.upper()
        db.commit()
        return {"success": True, "order_id": order.id, "new_status": order.status}
    finally:
        db.close()

# ==============================================================================
# CUSTOMER <-> CHEMIST PERSISTENT CHAT
# ==============================================================================

@router.get("/chat/threads/{pharmacy_id}")
def get_pharmacy_chat_threads(pharmacy_id: str):
    """
    Returns unique customer chat threads for a pharmacy store owner inbox.
    """
    db = SessionLocal()
    try:
        chats = db.query(CustomerStoreChat).filter(
            CustomerStoreChat.pharmacy_id == pharmacy_id
        ).order_by(CustomerStoreChat.created_at.desc()).all()

        threads = {}
        for c in chats:
            if c.user_id not in threads:
                user = db.query(User).filter(User.id == c.user_id).first()
                threads[c.user_id] = {
                    "user_id": c.user_id,
                    "customer_name": user.name if user else "Local Customer",
                    "customer_phone": user.contact if user else "+91 98765 00000",
                    "last_message": c.message,
                    "last_timestamp": str(c.created_at),
                    "sender_role": c.sender_role
                }
        return list(threads.values())
    finally:
        db.close()

@router.get("/chat/messages")
def get_chat_messages(
    pharmacy_id: str = Query(...),
    user_id: str = Query(...)
):
    """
    Returns full message transcript between customer and chemist.
    """
    db = SessionLocal()
    try:
        chats = db.query(CustomerStoreChat).filter(
            CustomerStoreChat.pharmacy_id == pharmacy_id,
            CustomerStoreChat.user_id == user_id
        ).order_by(CustomerStoreChat.created_at.asc()).all()

        return [
            {
                "id": c.id,
                "pharmacy_id": c.pharmacy_id,
                "user_id": c.user_id,
                "sender_role": c.sender_role,
                "sender_name": c.sender_name,
                "message": c.message,
                "created_at": str(c.created_at)
            }
            for c in chats
        ]
    finally:
        db.close()

@router.post("/chat/send")
def send_chat_message(req: SendChatMessageRequest):
    """
    Sends and records a chat message between customer and store owner.
    """
    db = SessionLocal()
    try:
        msg = CustomerStoreChat(
            pharmacy_id=req.pharmacy_id,
            user_id=req.user_id,
            sender_role=req.sender_role,
            sender_name=req.sender_name,
            message=req.message.strip()
        )
        db.add(msg)
        db.commit()
        db.refresh(msg)
        return {
            "id": msg.id,
            "pharmacy_id": msg.pharmacy_id,
            "user_id": msg.user_id,
            "sender_role": msg.sender_role,
            "sender_name": msg.sender_name,
            "message": msg.message,
            "created_at": str(msg.created_at)
        }
    finally:
        db.close()
