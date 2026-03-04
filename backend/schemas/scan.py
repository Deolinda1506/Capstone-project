from datetime import datetime
from pydantic import BaseModel, Field


class ScanCreate(BaseModel):
    patient_id: str
    image_path: str | None = Field(None, max_length=1024, description="Optional: legacy field. Images processed in-memory only.")


class ScanResponse(BaseModel):
    id: str
    patient_id: str
    image_path: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ResultCreate(BaseModel):
    scan_id: str
    imt_mm: float
    risk_level: str
    is_high_risk: bool
    model_version: str | None = None


class ResultResponse(BaseModel):
    id: str
    scan_id: str
    imt_mm: float
    risk_level: str
    is_high_risk: bool
    model_version: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ScanUploadResponse(BaseModel):
    """Response for POST /scans/upload: scan + result from uploaded image."""
    scan: ScanResponse
    result: ResultResponse
    segmentation_overlay_base64: str | None = None  # PNG overlay (green = wall) for display
    has_ai_overlay: bool = False  # True when overlay is from AI segmentation (green mask)
    plaque_detected: bool | None = None  # Derived from IMT: True if IMT >= 2.0 mm
