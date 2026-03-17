"""Email/password and Firebase authentication."""
import os
import secrets
from datetime import datetime, timedelta
from uuid import uuid4
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from backend.database import get_db
from backend.models import Hospital, User
from backend.schemas.user import (
    LoginRequest,
    RegisterRequest,
    FirebaseLoginRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    UserResponse,
    TokenResponse,
)
from backend.jwt_utils import create_access_token
from backend import email_service
from backend import sms_alerts

router = APIRouter(prefix="/auth", tags=["auth"])


def _normalize_phone(phone: str | None) -> str | None:
    """Normalize to E.164 for Rwanda (+250...)."""
    if not phone or not isinstance(phone, str):
        return None
    digits = "".join(c for c in phone if c.isdigit())
    if len(digits) < 9:
        return None
    if digits.startswith("250") and len(digits) >= 12:
        return "+" + digits[:12]
    if digits.startswith("0") and len(digits) >= 10:
        return "+250" + digits[1:10]
    if len(digits) == 9 and digits[0] == "7":
        return "+250" + digits
    return "+250" + digits[-9:] if len(digits) >= 9 else None


def _get_approval_codes() -> dict[str, str]:
    """Parse APPROVAL_CODES env (format: 0102:code1,0101:code2). Returns {} if not set."""
    raw = os.getenv("APPROVAL_CODES", "").strip()
    if not raw:
        return {}
    result = {}
    for part in raw.split(","):
        part = part.strip()
        if ":" in part:
            district, code = part.split(":", 1)
            result[district.strip()] = code.strip()
    return result


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def _truncate_for_bcrypt(password: str, max_bytes: int = 72) -> str:
    encoded = password.encode("utf-8")
    if len(encoded) <= max_bytes:
        return password
    return encoded[:max_bytes].decode("utf-8", errors="ignore")


def _user_response(user: User, db: Session) -> UserResponse:
    data = UserResponse.model_validate(user).model_dump()
    if user.hospital_id:
        hospital = db.get(Hospital, user.hospital_id)
        if hospital:
            data["hospital_name"] = hospital.name
    return UserResponse(**data)


@router.post("/login", response_model=TokenResponse)
def login(
    body: LoginRequest,
    db: Annotated[Session, Depends(get_db)],
):
    """Login with district ID (e.g. 0102-001) and password. Returns JWT access_token and user."""
    identifier = (body.identifier or "").strip()
    user = db.query(User).filter(User.staff_id == identifier, User.is_deleted == False).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid District ID or password",
        )
    if not user.password_hash:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This account uses Firebase. Sign in with Google or your Firebase provider instead.",
        )
    if (user.status or "approved") != "approved":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account pending approval. Contact your supervisor.",
        )
    if not pwd_context.verify(_truncate_for_bcrypt(body.password), user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid District ID or password",
        )
    token = create_access_token(subject=user.id)
    return TokenResponse(access_token=token, user=_user_response(user, db))


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(
    body: RegisterRequest,
    db: Annotated[Session, Depends(get_db)],
):
    """Registration: name, district, password. Assigns unique ID. Optional phone/email for ID delivery."""
    district = body.district_id or body.facility
    if not district:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="District is required",
        )
    # District approval code: if APPROVAL_CODES env is set, require matching code
    approval_codes = _get_approval_codes()
    if approval_codes:
        expected = approval_codes.get(district)
        provided = (body.approval_code or "").strip()
        if not expected:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Registration for this district is not open. Contact your supervisor.",
            )
        if provided != expected:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid approval code. Get the code from your district supervisor.",
            )
    phone = _normalize_phone(body.phone) if body.phone else None
    email_for_send = (body.email or "").strip() if body.email and "@" in (body.email or "") else None

    # Duplicate check: if phone provided and already registered, send ID and reject
    if phone:
        existing = db.query(User).filter(User.phone == phone, User.is_deleted == False).first()
        if existing and existing.staff_id:
            sms_alerts.send_chw_id_sms(phone, existing.staff_id)
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"You already have an account. Your ID is {existing.staff_id}. We've sent it to your phone.",
            )

    count = db.query(User).filter(User.facility == district).count()
    assigned_id = f"{district}-{count + 1:03d}"
    email = f"{assigned_id}@carotidcheck.local"  # Internal placeholder (DB requires unique email)
    user = User(
        id=str(uuid4()),
        email=email,
        password_hash=pwd_context.hash(_truncate_for_bcrypt(body.password)),
        display_name=body.display_name or assigned_id,
        role=body.role or "chw",
        staff_id=assigned_id,
        facility=district,
        phone=phone,
        status="approved",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # Send ID via SMS and/or email
    if phone:
        sms_alerts.send_chw_id_sms(phone, assigned_id)
    if email_for_send:
        email_service.send_chw_id_email(email_for_send, assigned_id)

    token = create_access_token(subject=user.id)
    return TokenResponse(access_token=token, user=_user_response(user, db))


@router.post("/firebase", response_model=TokenResponse)
def firebase_login(
    body: FirebaseLoginRequest,
    db: Annotated[Session, Depends(get_db)],
):
    """Firebase ID token login. Verifies token, creates user if first sign-in, returns JWT."""
    try:
        from backend.firebase_config import _decode_firebase_token
    except ImportError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Firebase auth not configured. Install firebase-admin and add firebase-key.json.",
        )
    try:
        decoded = _decode_firebase_token(body.id_token)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )
    firebase_uid = decoded.get("uid")
    if not firebase_uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase token",
        )
    email = decoded.get("email") or ""
    name = decoded.get("name") or decoded.get("email", "").split("@")[0] or "User"
    user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
    if not user:
        if db.query(User).filter(User.email == email).first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered with password. Use email/password login.",
            )
        user = User(
            id=str(uuid4()),
            firebase_uid=firebase_uid,
            email=email or f"{firebase_uid}@firebase.local",
            display_name=name,
            role="chw",
            status="approved",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    elif user.is_deleted or (user.status or "approved") != "approved":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account not approved or has been deactivated.",
        )
    token = create_access_token(subject=user.id)
    return TokenResponse(access_token=token, user=_user_response(user, db))


@router.post("/forgot-password")
def forgot_password(
    body: ForgotPasswordRequest,
    db: Annotated[Session, Depends(get_db)],
):
    """Request password reset. Always returns 200 (don't reveal if email exists). Sends reset email if user found."""
    email = (body.email or "").strip().lower()
    user = db.query(User).filter(User.email == email, User.is_deleted == False).first()
    if user and user.password_hash:
        token = secrets.token_urlsafe(32)
        user.password_reset_token = token
        user.password_reset_expires = datetime.utcnow() + timedelta(hours=1)
        db.commit()
        base_url = os.getenv("PASSWORD_RESET_BASE_URL", "").strip()
        if base_url:
            reset_link = f"{base_url.rstrip('/')}/reset-password?token={token}"
            email_service.send_password_reset_email(email, reset_link)
        else:
            email_service.send_password_reset_email(
                email,
                f"(Copy this token and paste it in the app: {token})",
            )
    return {"message": "If an account exists with this email, you will receive reset instructions."}


@router.post("/reset-password")
def reset_password(
    body: ResetPasswordRequest,
    db: Annotated[Session, Depends(get_db)],
):
    """Reset password using token from forgot-password email."""
    if len(body.new_password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 6 characters",
        )
    user = (
        db.query(User)
        .filter(
            User.password_reset_token == body.token,
            User.password_reset_expires > datetime.utcnow(),
        )
        .first()
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token",
        )
    user.password_hash = pwd_context.hash(_truncate_for_bcrypt(body.new_password))
    user.password_reset_token = None
    user.password_reset_expires = None
    db.commit()
    return {"message": "Password reset successfully"}
