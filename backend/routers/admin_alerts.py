from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from backend.auth import get_current_user
from backend.database import get_db
from backend.models import User
from backend import alert_queue

router = APIRouter(prefix="/admin/alerts", tags=["admin-alerts"])


@router.get("/queue")
def queue_snapshot(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),  # noqa: ARG001
):
    if (current_user.role or "").lower() != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    return {
        "queue": alert_queue.snapshot_failed(),
    }


@router.post("/process")
def process_due(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),  # noqa: ARG001
):
    if (current_user.role or "").lower() != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    processed = alert_queue.process_due_alerts()
    return {"processed": processed}

