"""Patients: create and list (protected)."""
from uuid import uuid4
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from backend.database import get_db
from backend.models import User, Patient
from backend.schemas.patient import PatientCreate, PatientResponse
from backend.auth import get_current_user_or_dev
from backend import email_service

router = APIRouter(prefix="/patients", tags=["patients"])


def _generate_patient_identifier() -> str:
    """Assign unique ID when client omits identifier (e.g. PT-XXXXXXXX)."""
    return "PT-" + str(uuid4()).replace("-", "")[:8].upper()


@router.post("", response_model=PatientResponse, status_code=status.HTTP_201_CREATED)
def create_patient(
    body: PatientCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user_or_dev)],
):
    # Assign unique ID: use provided identifier (e.g. CC-0001 from Flutter) or generate
    identifier = (body.identifier or "").strip() or _generate_patient_identifier()
    # Idempotent: if patient with same identifier exists for this user, return it
    existing = (
        db.query(Patient)
        .filter(
            Patient.user_id == current_user.id,
            Patient.identifier == identifier,
            Patient.is_deleted == False,
        )
        .first()
    )
    if existing:
        db.refresh(existing)
        return existing
    patient = Patient(
        id=str(uuid4()),
        user_id=current_user.id,
        identifier=identifier,
        email=body.email.strip() if body.email else None,
        facility=body.facility,
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)
    email_service.send_welcome_email(patient)
    return patient


@router.get("", response_model=list[PatientResponse])
def list_patients(
    limit: Annotated[int, Query(ge=1, le=200)] = 100,
    db: Annotated[Session, Depends(get_db)] = ...,
    current_user: Annotated[User, Depends(get_current_user_or_dev)] = ...,
):
    """List patients for the current user (village-filtered by user's facility)."""
    rows = (
        db.query(Patient)
        .filter(Patient.user_id == current_user.id, Patient.is_deleted == False)
        .order_by(Patient.created_at.desc())
        .limit(limit)
        .all()
    )
    return rows
