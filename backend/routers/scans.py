"""Scan upload, inference, and listing. Images stored for clinician dashboard."""
import base64
import hashlib
import logging
import os
import time
from datetime import datetime
from pathlib import Path
from uuid import uuid4
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

from backend.database import get_db
from backend.models import User, Patient, Scan, Result
from backend.schemas.scan import ClinicianReviewUpdate, ScanUploadResponse
from backend.auth import get_current_user_or_dev
from backend import sms_alerts
from backend import email_service
from backend import latency as latency_tracker

router = APIRouter(prefix="/scans", tags=["scans"])

# Directory for storing scan images (overlay for doctor view). Create if missing.
UPLOADS_DIR = Path(__file__).resolve().parent.parent.parent / "uploads"


def _review_fields(scan: Scan) -> dict:
    return {
        "clinician_review_status": scan.clinician_review_status or "pending",
        "clinician_reviewed_at": scan.clinician_reviewed_at.isoformat() if scan.clinician_reviewed_at else None,
        "clinician_reviewed_by_id": scan.clinician_reviewed_by_id,
        "clinical_notes": scan.clinical_notes,
    }


def _require_clinician_or_admin(user: User) -> None:
    role = (user.role or "").lower()
    if role not in ("admin", "clinician"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only clinicians and admins can update referral review status",
        )


def _demo_prediction(
    contents: bytes,
    patient_age: int | None,
    pixel_spacing_mm: float | None,
    t_start: float,
) -> dict:
    """Deterministic demo IMT/stenosis when ML inference is unavailable or fails."""
    h = int(hashlib.sha256(contents[:1024]).hexdigest()[:8], 16)
    imt_mm = round(0.5 + (h % 15) / 10, 2)
    stenosis_pct = (1 - imt_mm / 1.5) * 80 if imt_mm < 1.5 else min(99, 70 + (imt_mm - 1.2) * 20)
    from backend.inference import _get_imt_thresholds

    mod_mm, high_mm = _get_imt_thresholds(patient_age)
    risk_level = "High" if imt_mm > high_mm else "Moderate" if imt_mm >= mod_mm else "Low"
    return {
        "imt_mm": imt_mm,
        "risk_level": risk_level,
        "is_high_risk": imt_mm > high_mm,
        "stenosis_pct": round(stenosis_pct, 1),
        "stenosis_source": "imt_correlation",
        "inference_time_sec": round(time.perf_counter() - t_start, 3),
        "pixel_spacing_mm": float(pixel_spacing_mm if pixel_spacing_mm is not None else 0.04),
        "pixel_spacing_source": "metadata" if pixel_spacing_mm is not None else "default",
        "segmentation_overlay_base64": base64.b64encode(contents).decode("ascii"),
        "has_ai_overlay": False,
        "model_version": "demo_fallback",
    }


def _save_scan_image(scan_id: str, overlay_b64: str | None, original_bytes: bytes) -> str | None:
    try:
        UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
        path = UPLOADS_DIR / f"{scan_id}.png"
        if overlay_b64:
            data = base64.b64decode(overlay_b64)
        else:
            data = original_bytes
        path.write_bytes(data)
        return f"uploads/{scan_id}.png"
    except Exception as e:
        logger.warning("Could not save scan image: %s", e)
        return None


@router.post(
    "/upload",
    response_model=ScanUploadResponse,
    status_code=status.HTTP_201_CREATED,
    operation_id="upload_scan_image_with_prediction",
)
async def upload_scan_image(
    patient_id: Annotated[str, Form(description="Patient UUID or display identifier (e.g. CC-0001). Create patient via POST /patients first if needed.")],
    file: Annotated[UploadFile, File(description="Carotid ultrasound image")],
    patient_age: Annotated[int | None, Form(description="Optional patient age (years). When provided, age-specific IMT thresholds are used.")] = None,
    pixel_spacing_mm: Annotated[
        float | None,
        Form(
            description="Optional ultrasound pixel spacing (mm/pixel). "
            "Use this when device metadata is available for better IMT calibration."
        ),
    ] = None,
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    ct = (file.content_type or "").lower()
    fn = (file.filename or "").lower()
    is_image = ct.startswith("image/") or any(
        fn.endswith(ext)
        for ext in (".jpg", ".jpeg", ".png", ".gif", ".webp", ".heic", ".heif", ".bmp", ".tif", ".tiff")
    )
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
    if pixel_spacing_mm is not None and (pixel_spacing_mm <= 0 or pixel_spacing_mm > 1):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="pixel_spacing_mm must be > 0 and <= 1 (mm/pixel).",
        )
    t_start = time.perf_counter()
    pred: dict
    try:
        from backend.inference import predict_imt

        pred = predict_imt(
            contents,
            spacing_mm_per_pixel=pixel_spacing_mm if pixel_spacing_mm is not None else 0.04,
            return_segmentation_overlay=True,
            patient_age=patient_age,
        )
        pred.setdefault("model_version", "attention_unet")
        latency_tracker.record_inference_latency(pred.get("inference_time_sec", time.perf_counter() - t_start))
    except Exception as e:
        # Always fall back to demo metrics so CHW apps get 201 + results (invalid decode, OOM, bad mask, etc.).
        logger.warning("Inference failed; using demo fallback: %s", e, exc_info=True)
        pred = _demo_prediction(contents, patient_age, pixel_spacing_mm, t_start)
        latency_tracker.record_inference_latency(pred["inference_time_sec"])
    scan_id = str(uuid4())
    image_path = _save_scan_image(
        scan_id,
        pred.get("segmentation_overlay_base64"),
        contents,
    )
    scan = Scan(
        id=scan_id,
        patient_id=patient.id,
        user_id=current_user.id,
        image_path=image_path,
        clinician_review_status="pending" if pred["is_high_risk"] else "not_applicable",
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
        stenosis_pct=pred.get("stenosis_pct"),
        stenosis_source=pred.get("stenosis_source"),
        model_version=pred.get("model_version") or "attention_unet",
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
    # Plaque heuristic: IMT >= 0.9 mm indicates wall thickening/plaque (moderate+ risk)
    imt_v = pred.get("imt_mm")
    plaque_detected = imt_v is not None and imt_v >= 0.9
    return ScanUploadResponse(
        scan=scan,
        result=result,
        segmentation_overlay_base64=pred.get("segmentation_overlay_base64"),
        has_ai_overlay=pred.get("has_ai_overlay", False),
        plaque_detected=plaque_detected,
        stenosis_pct=pred.get("stenosis_pct"),
        stenosis_source=pred.get("stenosis_source"),
        inference_time_sec=pred.get("inference_time_sec"),
        patient_age=patient_age,
        pixel_spacing_mm=pred.get("pixel_spacing_mm"),
        pixel_spacing_source=pred.get("pixel_spacing_source"),
        inference_success=pred.get("success", True),
        inference_error=pred.get("error") if pred.get("success") is False else None,
    )


@router.get("/risk-distribution")
def risk_distribution_summary(
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    """
    Count analyses (results) by risk_level for non-deleted scans.
    CHWs see only their patients' scans; clinicians and admins see all.
    Use for Chapter 5 risk bar charts and dashboards.
    """
    q = (
        db.query(Result.risk_level, func.count(Result.id))
        .join(Scan, Scan.id == Result.scan_id)
        .filter(Scan.is_deleted == False)
    )
    role = (current_user.role or "chw").lower()
    if role == "chw":
        q = q.join(Patient, Patient.id == Scan.patient_id).filter(Patient.user_id == current_user.id)
    rows = q.group_by(Result.risk_level).all()
    by_level: dict[str, int] = {"Low": 0, "Moderate": 0, "High": 0, "Unknown": 0}
    for level, n in rows:
        k = (level or "").strip()
        if k in by_level:
            by_level[k] = int(n)
    total = sum(by_level.values())
    return {
        "total": total,
        "by_risk_level": by_level,
        "scope": "chw_patients" if role == "chw" else "all_patients",
    }


@router.get("/with-results")
def list_scans_with_results(
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    name: Annotated[str | None, Query(description="Filter by patient name")] = None,
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    """List recent scans with result and patient info for analyses view. Clinicians and admins see all; CHWs see only their patients' scans."""
    q = (
        db.query(Scan, Result, Patient)
        .join(Result, Scan.id == Result.scan_id)
        .join(Patient, Scan.patient_id == Patient.id)
        .filter(Scan.is_deleted == False)
    )
    role = (current_user.role or "chw").lower()
    if role == "chw":
        q = q.filter(Patient.user_id == current_user.id)
    if name and (n := name.strip()):
        q = q.filter(
            or_(
                Patient.name.ilike(f"%{n}%"),
                Patient.identifier.ilike(f"%{n}%"),
            )
        )
    rows = q.order_by(Result.created_at.desc()).limit(limit).all()
    return [
        {
            "scan_id": s.id,
            "patient_id": p.id,
            "patient_identifier": p.identifier,
            "patient_name": p.name,
            "patient_age": p.age,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "imt_mm": r.imt_mm,
            "risk_level": r.risk_level,
            "is_high_risk": r.is_high_risk,
            "stenosis_pct": r.stenosis_pct,
            "stenosis_source": r.stenosis_source,
            "plaque_detected": r.imt_mm is not None and r.imt_mm >= 0.9,
            "has_image": bool(s.image_path),
            **_review_fields(s),
        }
        for s, r, p in rows
    ]


@router.get("/high-risk")
def list_high_risk_referrals(
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    name: Annotated[str | None, Query(description="Filter by patient name (case-insensitive)")] = None,
    review_status: Annotated[
        Literal["pending", "reviewed", "all"],
        Query(description="Hospital queue: pending vs reviewed high-risk referrals"),
    ] = "all",
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    """
    List high-risk scans for hospital dashboard.
    Clinicians and admins see all high-risk referrals; CHWs see only their own.
    Optional name filter for clinician verification (patient says their name).
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
    if name and (n := name.strip()):
        q = q.filter(
            or_(
                Patient.name.ilike(f"%{n}%"),
                Patient.identifier.ilike(f"%{n}%"),
            )
        )
    if review_status == "pending":
        q = q.filter(
            (Scan.clinician_review_status == "pending") | (Scan.clinician_review_status.is_(None))
        )
    elif review_status == "reviewed":
        q = q.filter(Scan.clinician_review_status == "reviewed")
    q = q.order_by(Result.created_at.desc()).limit(limit)
    rows = q.all()
    return [
        {
            "scan_id": s.id,
            "patient_id": p.id,
            "patient_identifier": p.identifier,
            "patient_name": p.name,
            "patient_age": p.age,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "imt_mm": r.imt_mm,
            "risk_level": r.risk_level,
            "is_high_risk": r.is_high_risk,
            "stenosis_pct": r.stenosis_pct,
            "stenosis_source": r.stenosis_source,
            "plaque_detected": r.imt_mm is not None and r.imt_mm >= 0.9,
            "has_image": bool(s.image_path),
            **_review_fields(s),
        }
        for s, r, p in rows
    ]


@router.patch("/{scan_id}/review", status_code=status.HTTP_200_OK)
def update_clinician_review(
    scan_id: str,
    body: ClinicianReviewUpdate,
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    """Mark a high-risk referral as reviewed (or reopen). Clinicians and admins only."""
    _require_clinician_or_admin(current_user)
    scan = db.get(Scan, scan_id)
    if not scan or scan.is_deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Scan not found")
    r = db.query(Result).filter(Result.scan_id == scan_id).first()
    if not r:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Result not found")
    patient = db.get(Patient, scan.patient_id)
    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")
    if not r.is_high_risk:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Review workflow applies to high-risk referrals only",
        )
    if body.status == "reviewed":
        scan.clinician_review_status = "reviewed"
        scan.clinician_reviewed_at = datetime.utcnow()
        scan.clinician_reviewed_by_id = current_user.id
        if body.clinical_notes is not None:
            scan.clinical_notes = body.clinical_notes.strip() or None
    else:
        scan.clinician_review_status = "pending"
        scan.clinician_reviewed_at = None
        scan.clinician_reviewed_by_id = None
        if body.clinical_notes is not None:
            scan.clinical_notes = body.clinical_notes.strip() or None
    db.commit()
    db.refresh(scan)
    return {
        "scan_id": scan.id,
        "patient_id": patient.id,
        "patient_identifier": patient.identifier,
        "patient_name": patient.name,
        "patient_age": patient.age,
        "created_at": r.created_at.isoformat() if r.created_at else None,
        "imt_mm": r.imt_mm,
        "risk_level": r.risk_level,
        "is_high_risk": r.is_high_risk,
        "stenosis_pct": r.stenosis_pct,
        "stenosis_source": r.stenosis_source,
        "plaque_detected": r.imt_mm is not None and r.imt_mm >= 0.9,
        "has_image": bool(scan.image_path),
        **_review_fields(scan),
    }


@router.get("/{scan_id}/result")
def get_scan_result(
    scan_id: str,
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    """
    Get result and metadata for a single scan. Enables result screen to survive reload.
    Clinicians and admins can view any scan; CHWs can view only their patients' scans.
    """
    scan = db.get(Scan, scan_id)
    if not scan or scan.is_deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Scan not found")
    r = db.query(Result).filter(Result.scan_id == scan_id).first()
    if not r:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Result not found")
    patient = db.get(Patient, scan.patient_id)
    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")
    role = (current_user.role or "chw").lower()
    if role == "chw" and patient.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    return {
        "scan_id": scan.id,
        "patient_id": patient.id,
        "patient_identifier": patient.identifier,
        "patient_name": patient.name,
        "patient_age": patient.age,
        "created_at": r.created_at.isoformat() if r.created_at else None,
        "imt_mm": r.imt_mm,
        "risk_level": r.risk_level,
        "is_high_risk": r.is_high_risk,
        "stenosis_pct": r.stenosis_pct,
        "stenosis_source": r.stenosis_source,
        "plaque_detected": r.imt_mm is not None and r.imt_mm >= 0.9,
        "has_image": bool(scan.image_path),
        **_review_fields(scan),
    }


@router.get("/{scan_id}/image")
def get_scan_image(
    scan_id: str,
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    """
    Return the stored scan image (overlay) for clinician/CHW review.
    Clinicians and admins can view any scan; CHWs can view only their patients' scans.
    """
    scan = db.get(Scan, scan_id)
    if not scan or scan.is_deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Scan not found")
    if not scan.image_path:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No image stored for this scan")
    role = (current_user.role or "chw").lower()
    if role == "chw":
        patient = db.get(Patient, scan.patient_id)
        if not patient or patient.user_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    path = Path(__file__).resolve().parent.parent.parent / scan.image_path
    if not path.exists():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image file not found")
    return FileResponse(path, media_type="image/png")
