from datetime import datetime
from pydantic import BaseModel, Field


class PatientCreate(BaseModel):
    identifier: str | None = Field(None, min_length=1, max_length=255, description="Unique ID (e.g. CC-0001). Auto-generated if omitted.")
    name: str | None = Field(None, max_length=255, description="Patient name (for clinician verification)")
    age: int | None = Field(None, ge=0, le=150, description="Patient age in years")
    email: str | None = Field(None, max_length=255, description="For welcome and referral emails")
    facility: str | None = None


class PatientResponse(BaseModel):
    id: str
    user_id: str | None
    identifier: str
    name: str | None = None
    age: int | None = None
    email: str | None = None
    facility: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
