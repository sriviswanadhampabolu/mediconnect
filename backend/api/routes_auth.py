import os
import json
import secrets
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timezone, timedelta
from typing import Optional, List
from pydantic import BaseModel, Field
from fastapi import APIRouter, HTTPException, Depends
from backend.database import SessionLocal, get_db
from backend.models.entities import User, MedicalRecord, AgentAuditLog, Pharmacy, PasswordResetCode
from backend.security.auth import hash_password, verify_password
from backend.security.crypto import encrypt_list, encrypt_data

router = APIRouter(prefix="/auth", tags=["Authentication"])

class DirectEmailLoginRequest(BaseModel):
    email: str = Field(..., min_length=4, description="Email address for direct / Google sign-in")
    name: Optional[str] = None
    role: Optional[str] = "customer"

class SignupRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    contact: str = Field(..., min_length=8, max_length=30)
    email: Optional[str] = None
    password: str = Field(..., min_length=4)
    role: Optional[str] = "customer"  # "customer" or "pharmacy_owner"
    store_id: Optional[str] = None
    store_name: Optional[str] = None
    address: Optional[str] = "Sector 15, Gurgaon"
    latitude: Optional[float] = 28.6139
    longitude: Optional[float] = 77.2090
    allergies: Optional[List[str]] = []
    payment_limit: Optional[float] = 1500.0

def send_verification_email(recipient_email: str, code: str) -> bool:
    """
    Sends password reset verification code to user's Gmail/email address via SMTP.
    """
    smtp_email = os.getenv("SMTP_EMAIL", "").strip()
    smtp_password = os.getenv("SMTP_PASSWORD", os.getenv("GMAIL_APP_PASSWORD", "")).strip()
    smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com").strip()
    smtp_port = int(os.getenv("SMTP_PORT", "587"))

    if not smtp_email or not smtp_password:
        return False

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = f"MediConnect Verification Code: {code}"
        msg["From"] = f"MediConnect Health <{smtp_email}>"
        msg["To"] = recipient_email

        html = f"""
        <div style="font-family: Arial, sans-serif; max-width: 520px; padding: 24px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff;">
            <div style="display: flex; align-items: center; margin-bottom: 20px;">
                <h2 style="color: #2563eb; margin: 0;">🩺 MediConnect</h2>
            </div>
            <h3 style="color: #1e293b; margin-top: 0;">Password Reset Verification Code</h3>
            <p style="color: #475569; font-size: 14px; line-height: 1.5;">
                We received a request to reset your password. Use the 6-digit verification code below in the mobile app:
            </p>
            <div style="background: #f8fafc; border: 2px dashed #94a3b8; border-radius: 12px; padding: 18px; text-align: center; margin: 24px 0;">
                <span style="font-size: 32px; font-weight: 800; letter-spacing: 6px; color: #0f172a;">{code}</span>
            </div>
            <p style="color: #64748b; font-size: 12.5px; line-height: 1.4;">
                This code is valid for <strong>15 minutes</strong>. If you did not request a password reset, you can safely ignore this email.
            </p>
            <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
            <p style="color: #94a3b8; font-size: 11px;">MediConnect AI Hyperlocal Health Assistant & Pharmacy Network</p>
        </div>
        """
        msg.attach(MIMEText(html, "html"))

        server = smtplib.SMTP(smtp_host, smtp_port, timeout=8)
        server.starttls()
        server.login(smtp_email, smtp_password)
        server.sendmail(smtp_email, [recipient_email], msg.as_string())
        server.quit()
        return True
    except Exception as e:
        print(f"[Email Error] Could not deliver email to {recipient_email}: {e}")
        return False

class LoginRequest(BaseModel):
    identifier: str = Field(..., min_length=2, description="Email or contact phone number")
    password: str = Field(..., min_length=1)
    expected_role: Optional[str] = Field(None, description="Optional chosen role for role enforcement")

class ForgotPasswordRequest(BaseModel):
    email: str = Field(..., min_length=4, description="Registered email address")

class ResetPasswordRequest(BaseModel):
    email: str = Field(..., min_length=4, description="Registered email address")
    code: str = Field(..., min_length=4, max_length=10, description="Verification code sent to email")
    new_password: str = Field(..., min_length=4, description="New password")

def format_user_response(user: User):
    contacts = []
    if user.emergency_contacts:
        try:
            contacts = json.loads(user.emergency_contacts)
        except Exception:
            contacts = []
            
    return {
        "id": user.id,
        "name": user.name,
        "contact": user.contact,
        "email": user.email,
        "role": getattr(user, "role", "customer") or "customer",
        "store_id": getattr(user, "store_id", None),
        "address": user.address,
        "latitude": user.latitude,
        "longitude": user.longitude,
        "emergency_contacts": contacts,
        "payment_limit": user.payment_limit,
        "created_at": str(user.created_at)
    }

@router.post("/signup")
def signup(req: SignupRequest):
    """
    Register a new user (customer or pharmacy owner) and initialize their profile.
    """
    db = SessionLocal()
    try:
        # Check contact uniqueness
        existing_contact = db.query(User).filter(User.contact == req.contact.strip()).first()
        if existing_contact:
            raise HTTPException(status_code=400, detail="Phone number is already registered. Please log in.")
        
        # Check email uniqueness if provided
        if req.email and req.email.strip():
            existing_email = db.query(User).filter(User.email == req.email.strip().lower()).first()
            if existing_email:
                raise HTTPException(status_code=400, detail="Email address is already registered. Please log in.")
        
        user_role = req.role if req.role in ["customer", "pharmacy_owner"] else "customer"
        store_id = req.store_id

        # Create user
        new_user = User(
            name=req.name.strip(),
            contact=req.contact.strip(),
            email=req.email.strip().lower() if req.email else None,
            password_hash=hash_password(req.password),
            role=user_role,
            store_id=store_id,
            address=req.address.strip() if req.address else "Sector 15, Gurgaon",
            latitude=req.latitude or 28.4682,
            longitude=req.longitude or 77.0425,
            payment_limit=req.payment_limit or 1500.0,
            emergency_contacts=json.dumps([
                {"name": "Emergency Contact", "phone": req.contact.strip(), "relation": "Self"}
            ])
        )
        db.add(new_user)
        db.flush()  # to get new_user.id
        
        # If user is a pharmacy owner, attach or create their pharmacy store
        if user_role == "pharmacy_owner":
            if not store_id:
                # Create custom pharmacy for this new owner
                from backend.seed_data import COMPREHENSIVE_MEDICINE_CATALOG
                initial_inv = []
                for m in COMPREHENSIVE_MEDICINE_CATALOG:
                    item = dict(m)
                    initial_inv.append(item)

                store_name = req.store_name.strip() if req.store_name else f"{new_user.name}'s Medical Store"
                new_pharmacy = Pharmacy(
                    name=store_name,
                    latitude=new_user.latitude,
                    longitude=new_user.longitude,
                    address=new_user.address,
                    phone=new_user.contact,
                    inventory=json.dumps(initial_inv),
                    owner_user_id=new_user.id,
                    response_time_avg=10,
                    verified=True,
                    rating=4.8
                )
                db.add(new_pharmacy)
                db.flush()
                new_user.store_id = new_pharmacy.id
            else:
                pharm = db.query(Pharmacy).filter(Pharmacy.id == store_id).first()
                if pharm:
                    pharm.owner_user_id = new_user.id

        # Initialize encrypted medical record for patient/customer
        if user_role == "customer":
            allergies = [a.strip() for a in req.allergies if a.strip()] if req.allergies else []
            med_rec = MedicalRecord(
                user_id=new_user.id,
                condition="Initial Patient Profile",
                diagnosis_date=datetime.now(timezone.utc),
                prescribing_source="patient_signup",
                encrypted_notes=encrypt_data("Profile created via MediConnect secure signup."),
                encrypted_allergies=encrypt_list(allergies) if allergies else encrypt_list([]),
                encrypted_chronic_conditions=encrypt_list([])
            )
            db.add(med_rec)
        
        # Log signup in immutable audit trail
        audit = AgentAuditLog(
            agent_name="API_Auth_Controller",
            user_id=new_user.id,
            action_type="USER_SIGNUP",
            input_summary=f"User signed up as {user_role}: {new_user.name} ({new_user.contact})",
            output_summary="User account created and role assigned"
        )
        db.add(audit)
        
        db.commit()
        db.refresh(new_user)
        return {
            "success": True,
            "message": f"Account created successfully for {new_user.name}!",
            "user": format_user_response(new_user)
        }
    finally:
        db.close()

@router.post("/login")
def login(req: LoginRequest):
    """
    Authenticate an existing user via contact phone number or email and password.
    """
    db = SessionLocal()
    try:
        ident = req.identifier.strip()
        user = db.query(User).filter(
            (User.contact == ident) | (User.email == ident.lower())
        ).first()
        
        if not user:
            raise HTTPException(status_code=401, detail="Invalid phone/email or password.")

        # Check expected role if provided
        if req.expected_role:
            actual_role = getattr(user, "role", "customer") or "customer"
            if actual_role != req.expected_role:
                expected_str = "Pharmacy Owner" if req.expected_role == "pharmacy_owner" else "Customer / Patient"
                actual_str = "Pharmacy Owner" if actual_role == "pharmacy_owner" else "Customer / Patient"
                raise HTTPException(
                    status_code=400,
                    detail=f"This account is registered as a {actual_str}. Please switch role to {actual_str} to sign in."
                )
            
        # Verify password hash
        if user.password_hash:
            if not verify_password(user.password_hash, req.password):
                raise HTTPException(status_code=401, detail="Invalid phone/email or password.")
        else:
            # Fallback for demo users seeded before password hashing was introduced
            if req.password not in ["Demo123!", "password", "123456"]:
                raise HTTPException(status_code=401, detail="Invalid password for demo account. Use Demo123!")
            # Update password hash
            user.password_hash = hash_password(req.password)
            db.commit()
            
        # Log login in audit trail
        audit = AgentAuditLog(
            agent_name="API_Auth_Controller",
            user_id=user.id,
            action_type="USER_LOGIN",
            input_summary=f"Login via identifier: {ident}",
            output_summary=f"Authentication successful for role {getattr(user, 'role', 'customer')}"
        )
        db.add(audit)
        db.commit()
        
        return {
            "success": True,
            "message": f"Welcome back, {user.name}!",
            "user": format_user_response(user)
        }
    finally:
        db.close()

@router.post("/forgot-password")
def forgot_password(req: ForgotPasswordRequest):
    """
    Generate and send a 6-digit verification code to the user's registered email.
    """
    db = SessionLocal()
    try:
        clean_email = req.email.strip().lower()
        user = db.query(User).filter(User.email == clean_email).first()
        if not user:
            raise HTTPException(
                status_code=404,
                detail="No account found with this email address. Please check your registered email."
            )
            
        # Invalidate previous unused codes for this email
        db.query(PasswordResetCode).filter(
            PasswordResetCode.email == clean_email,
            PasswordResetCode.used == False
        ).update({"used": True})
        
        # Generate 6-digit code
        code = f"{secrets.randbelow(900000) + 100000}"
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
        
        reset_entry = PasswordResetCode(
            email=clean_email,
            code=code,
            expires_at=expires_at,
            used=False
        )
        db.add(reset_entry)
        
        audit = AgentAuditLog(
            agent_name="API_Auth_Controller",
            user_id=user.id,
            action_type="PASSWORD_RESET_REQUEST",
            input_summary=f"Password reset code requested for {clean_email}",
            output_summary="6-digit code generated (expires in 15 mins)"
        )
        db.add(audit)
        db.commit()

        # Send actual verification email via Gmail / SMTP if configured
        email_sent = send_verification_email(clean_email, code)
        
        status_msg = f"Verification code sent to {clean_email}."
        if email_sent:
            status_msg += " Please check your Gmail/email inbox."
        else:
            status_msg += " (SMTP not yet configured; code preview enabled for testing)."

        return {
            "success": True,
            "message": status_msg,
            "email": clean_email,
            "email_sent": email_sent,
            "dev_code": code
        }
    finally:
        db.close()

@router.post("/email-login")
def direct_email_login(req: DirectEmailLoginRequest):
    """
    Direct passwordless 1-click login with Email or Google Account.
    If account does not exist, seamlessly auto-registers customer profile.
    """
    db = SessionLocal()
    try:
        clean_email = req.email.strip().lower()
        user = db.query(User).filter(User.email == clean_email).first()

        if not user:
            # Auto-register user
            disp_name = req.name.strip() if req.name and req.name.strip() else clean_email.split('@')[0].capitalize()
            contact_phone = "+91 98" + "".join([str(secrets.randbelow(10)) for _ in range(8)])
            user_role = req.role if req.role in ["customer", "pharmacy_owner"] else "customer"

            user = User(
                name=disp_name,
                contact=contact_phone,
                email=clean_email,
                password_hash=hash_password("MediConnect123!"),
                role=user_role,
                address="Sector 15, Gurgaon",
                latitude=28.4682,
                longitude=77.0425,
                payment_limit=1500.0,
                emergency_contacts=json.dumps([
                    {"name": "Emergency Contact", "phone": contact_phone, "relation": "Self"}
                ])
            )
            db.add(user)
            db.flush()

            # Initialize health record
            med_rec = MedicalRecord(
                user_id=user.id,
                condition="Initial Patient Profile",
                diagnosis_date=datetime.now(timezone.utc),
                prescribing_source="google_email_direct_login",
                encrypted_notes=encrypt_data("Profile created via direct email/Google authentication."),
                encrypted_allergies=encrypt_list(["Aspirin (Strict Block)", "Penicillin"]),
                encrypted_chronic_conditions=encrypt_list([])
            )
            db.add(med_rec)

            audit = AgentAuditLog(
                agent_name="API_Auth_Controller",
                user_id=user.id,
                action_type="DIRECT_EMAIL_SIGNUP",
                input_summary=f"User signed up via direct email: {clean_email}",
                output_summary="Account auto-provisioned"
            )
            db.add(audit)
            db.commit()
            db.refresh(user)

        audit = AgentAuditLog(
            agent_name="API_Auth_Controller",
            user_id=user.id,
            action_type="DIRECT_EMAIL_LOGIN",
            input_summary=f"Direct login for email: {clean_email}",
            output_summary="Successful authentication via direct email/Google"
        )
        db.add(audit)
        db.commit()

        return {
            "success": True,
            "message": f"Welcome back, {user.name}!",
            "user": format_user_response(user)
        }
    finally:
        db.close()

@router.post("/reset-password")
def reset_password(req: ResetPasswordRequest):
    """
    Verify the 6-digit code sent to the registered email and update the password.
    """
    db = SessionLocal()
    try:
        clean_email = req.email.strip().lower()
        clean_code = req.code.strip()
        
        user = db.query(User).filter(User.email == clean_email).first()
        if not user:
            raise HTTPException(status_code=404, detail="User account not found.")
            
        now = datetime.now(timezone.utc)
        
        # Find active reset code
        reset_record = db.query(PasswordResetCode).filter(
            PasswordResetCode.email == clean_email,
            PasswordResetCode.code == clean_code,
            PasswordResetCode.used == False
        ).order_by(PasswordResetCode.created_at.desc()).first()
        
        if not reset_record:
            raise HTTPException(status_code=400, detail="Invalid verification code. Please check the code and try again.")
            
        record_expiry = reset_record.expires_at
        if record_expiry.tzinfo is None:
            record_expiry = record_expiry.replace(tzinfo=timezone.utc)
            
        if record_expiry < now:
            reset_record.used = True
            db.commit()
            raise HTTPException(status_code=400, detail="Verification code has expired. Please request a new one.")
            
        # Update user password
        user.password_hash = hash_password(req.new_password)
        reset_record.used = True
        
        audit = AgentAuditLog(
            agent_name="API_Auth_Controller",
            user_id=user.id,
            action_type="PASSWORD_RESET_COMPLETE",
            input_summary=f"Password reset successfully completed for {clean_email}",
            output_summary="Password updated"
        )
        db.add(audit)
        db.commit()
        
        return {
            "success": True,
            "message": "Password reset successfully! You can now log in with your new password."
        }
    finally:
        db.close()

@router.post("/demo-login")
def demo_login():
    """
    1-click fast login for the primary sample customer (Rahul Sharma).
    """
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == "usr-sample-001").first()
        if not user:
            user = db.query(User).filter(User.role == "customer").first()
        if not user:
            raise HTTPException(status_code=404, detail="No demo users available.")
            
        return {
            "success": True,
            "message": f"Logged in as demo customer {user.name}",
            "user": format_user_response(user)
        }
    finally:
        db.close()

@router.post("/owner-demo-login")
def owner_demo_login():
    """
    1-click fast login for the demo medical store owner (Ramesh Gupta - Sanjeevani Local Chemist).
    """
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == "usr-owner-001").first()
        if not user:
            user = db.query(User).filter(User.role == "pharmacy_owner").first()
        if not user:
            raise HTTPException(status_code=404, detail="No demo store owner available.")
            
        return {
            "success": True,
            "message": f"Logged in as store owner {user.name}",
            "user": format_user_response(user)
        }
    finally:
        db.close()

@router.get("/me/{user_id}")
def get_me(user_id: str):
    """
    Fetch basic profile info for the currently authenticated session.
    """
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User session not found.")
        return format_user_response(user)
    finally:
        db.close()
