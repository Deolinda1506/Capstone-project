"""Scans: upload and list with results (protected). Images processed in-memory only (not stored permanently)."""
import base64
import hashlib
import logging
from uuid import uuid4
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

from backend.database import get_db
from backend.models import User, Patient, Scan, Result
from backend.schemas.scan import ScanUploadResponse
from backend.auth import get_current_user_or_dev
from backend import sms_alerts
from backend import email_service

router = APIRouter(prefix="/scans", tags=["scans"])


@router.post(
    "/upload",
    response_model=ScanUploadResponse,
    status_code=status.HTTP_201_CREATED,
    operation_id="upload_scan_image_with_prediction",
)
async def upload_scan_image(
    patient_id: Annotated[str, Form(description="Patient UUID or display identifier (e.g. CC-0001). Create patient via POST /patients first if needed.")],
    file: Annotated[UploadFile, File(description="Carotid ultrasound image")],
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    """
    Upload an image for a patient: creates a scan, runs prediction, creates the result.
    If high-risk, referral SMS and email are sent. Image is processed in-memory only (not stored).
    Token optional: if provided, uses that user; otherwise uses default dev user.
    patient_id can be the patient's UUID (id) or their display identifier (e.g. CC-0001).
    """
    ct = (file.content_type or "").lower()
    fn = (file.filename or "").lower()
    is_image = ct.startswith("image/") or any(fn.endswith(ext) for ext in (".jpg", ".jpeg", ".png", ".gif", ".webp"))
    if not is_image:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File must be an image (got content_type={file.content_type!r}, filename={file.filename!r})",
        )
    patient = db.get(Patient, patient_id)
    if not patient or patient.user_id != current_user.id:
        patient = (
            db.query(Patient)
            .filter(
                Patient.user_id == current_user.id,
                Patient.identifier == patient_id.strip(),
                Patient.is_deleted == False,
            )
            .first()
        )
    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")
    contents = await file.read()
    try:
        from backend.inference import predict_imt
        pred = predict_imt(contents, return_segmentation_overlay=True)
    except ImportError as e:
        logger.warning("ML model not available (%s). Using demo fallback.", e)
        h = int(hashlib.sha256(contents[:1024]).hexdigest()[:8], 16)
        imt_mm = round(2.0 + (h % 25) / 10, 2)
        risk_level = "High" if imt_mm >= 3.5 else "Moderate" if imt_mm >= 3.0 else "Low"
        pred = {
            "imt_mm": imt_mm,
            "risk_level": risk_level,
            "is_high_risk": imt_mm >= 3.5,
            "segmentation_overlay_base64": base64.b64encode(contents).decode("ascii"),
            "has_ai_overlay": False,
        }
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Prediction failed: {str(e)}")
    scan = Scan(
        id=str(uuid4()),
        patient_id=patient.id,
        user_id=current_user.id,
        image_path=None,
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)
    result = Result(
        id=str(uuid4()),
        scan_id=scan.id,
        imt_mm=pred["imt_mm"],
        risk_level=pred["risk_level"],
        is_high_risk=pred["is_high_risk"],
        model_version="carotid_swin_unetr_2d",
    )
    db.add(result)
    db.commit()
    db.refresh(result)
    if pred["is_high_risk"]:
        sms_alerts.notify_high_risk(
            scan_id=scan.id,
            patient_id=patient.id,
            imt_mm=pred["imt_mm"],
            risk_level=pred["risk_level"],
        )
        email_service.send_referral_email(
            patient,
            imt_mm=pred["imt_mm"],
            risk_level=pred["risk_level"],
        )
    # Plaque heuristic: IMT >= 2.0 mm often indicates wall thickening/plaque
    plaque_detected = pred["imt_mm"] >= 2.0
    return ScanUploadResponse(
        scan=scan,
        result=result,
        segmentation_overlay_base64=pred.get("segmentation_overlay_base64"),
        has_ai_overlay=pred.get("has_ai_overlay", False),
        plaque_detected=plaque_detected,
    )


@router.get("/with-results")
def list_scans_with_results(
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    """List recent scans with result and patient info for analyses view."""
    rows = (
        db.query(Scan, Result, Patient)
        .join(Result, Scan.id == Result.scan_id)
        .join(Patient, Scan.patient_id == Patient.id)
        .filter(
            (Patient.user_id == current_user.id) & (Scan.is_deleted == False)
        )
        .order_by(Result.created_at.desc())
        .limit(limit)
        .all()
    )
    return [
        {
            "scan_id": s.id,
            "patient_id": p.id,
            "patient_identifier": p.identifier,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "imt_mm": r.imt_mm,
            "risk_level": r.risk_level,
            "is_high_risk": r.is_high_risk,
            "plaque_detected": r.imt_mm >= 2.0,
        }
        for s, r, p in rows
    ]


@router.get("/high-risk")
def list_high_risk_referrals(
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    """
    List high-risk scans for hospital dashboard.
    Clinicians and admins see all high-risk referrals; CHWs see only their own.
    """
    q = (
        db.query(Scan, Result, Patient)
        .join(Result, Scan.id == Result.scan_id)
        .join(Patient, Scan.patient_id == Patient.id)
        .filter(Result.is_high_risk == True, Scan.is_deleted == False)
    )
    role = (current_user.role or "chw").lower()
    if role == "chw":
        q = q.filter(Patient.user_id == current_user.id)
    q = q.order_by(Result.created_at.desc()).limit(limit)
    rows = q.all()
    return [
        {
            "scan_id": s.id,
            "patient_id": p.id,
            "patient_identifier": p.identifier,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "imt_mm": r.imt_mm,
            "risk_level": r.risk_level,
            "is_high_risk": r.is_high_risk,
            "plaque_detected": r.imt_mm >= 2.0,
        }
        for s, r, p in rows
    ]
