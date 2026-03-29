from datetime import datetime
from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    email: EmailStr
    display_name: str | None = None
    role: str = "chw"  # chw or clinician


class LoginRequest(BaseModel):
    """Login with district ID (e.g. 0102-001) and password."""
    identifier: str  # Assigned district ID from registration
    password: str


class IdentifierLoginRequest(BaseModel):
    """Login with phone / staff ID / email identifier."""
    identifier: str
    password: str


class RegisterRequest(BaseModel):
    password: str
    display_name: str | None = None
    role: str = "chw"
    staff_id: str | None = None  # Professional / national ID
    facility: str | None = None  # Hospital or health facility (legacy)
    district_id: str | None = None  # Rwanda district ID code (e.g. 0101, 0102)
    approval_code: str | None = None  # District approval code from supervisor (required when APPROVAL_CODES set)
    phone: str | None = None  # E.164 or local format; duplicate check (optional)
    email: str | None = None  # Optional; for email ID delivery (if different from placeholder)


class RegisterHospitalRequest(BaseModel):
    """Hospital admin registers the hospital and becomes the first admin user."""
    hospital_name: str
    admin_email: EmailStr
    password: str
    display_name: str | None = None
    province: str | None = None  # Rwanda: e.g. Kigali, Eastern
    district: str | None = None  # e.g. Gasabo, Kicukiro
    sector: str | None = None    # e.g. Remera, Niboye


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str  # min length enforced in endpoint


class ProfileUpdateRequest(BaseModel):
    """Update current user's profile. All fields optional."""
    display_name: str | None = None
    facility: str | None = None


class InviteUserRequest(BaseModel):
    """Hospital admin creates a user (CHW or clinician) under their hospital."""
    email: EmailStr
    password: str
    display_name: str | None = None
    role: str = "chw"  # chw | clinician
    staff_id: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class UserResponse(BaseModel):
    id: str
    firebase_uid: str | None
    email: str
    display_name: str | None
    role: str
    staff_id: str | None = None
    facility: str | None = None
    hospital_id: str | None = None
    hospital_name: str | None = None  # Set when building response from User with hospital
    status: str | None = None  # pending | approved
    # Older rows / edge cases: avoid 500 on response validation
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


TokenResponse.model_rebuild()

