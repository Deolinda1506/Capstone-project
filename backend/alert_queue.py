"""DB-backed alert queue with a simple in-process worker.

Purpose: avoid blocking critical user flows (registration/password reset/scan)
on potentially flaky delivery (SMTP/SMS gateways). Alerts are enqueued and
retried until they either succeed or hit max attempts.
"""

from __future__ import annotations

import json
import logging
import os
import uuid
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import and_
from sqlalchemy.orm import Session

from backend.database import SessionLocal
from backend.models import AlertQueue, Patient

logger = logging.getLogger(__name__)


def _env_bool(name: str, default: bool) -> bool:
    raw = os.getenv(name, "").strip().lower()
    if raw == "":
        return default
    return raw in ("1", "true", "yes", "y", "on")


def _env_int(name: str, default: int) -> int:
    raw = os.getenv(name, "").strip()
    if not raw:
        return default
    try:
        return int(raw)
    except ValueError:
        return default


ALERT_QUEUE_ENABLED = _env_bool("ALERT_QUEUE_ENABLED", True)
ALERT_QUEUE_POLL_SECONDS = _env_int("ALERT_QUEUE_POLL_SECONDS", 5)
ALERT_QUEUE_MAX_ATTEMPTS = _env_int("ALERT_QUEUE_MAX_ATTEMPTS", 5)
ALERT_QUEUE_MAX_BATCH_SIZE = _env_int("ALERT_QUEUE_MAX_BATCH_SIZE", 20)
ALERT_QUEUE_BACKOFF_BASE_SECONDS = float(os.getenv("ALERT_QUEUE_BACKOFF_BASE_SECONDS", "2").strip() or "2")


def is_enabled() -> bool:
    return ALERT_QUEUE_ENABLED


def enqueue_alert(alert_type: str, payload: dict[str, Any]) -> bool:
    """Enqueue an alert for async delivery."""
    if not ALERT_QUEUE_ENABLED:
        return False

    alert_id = payload.get("id") or str(uuid.uuid4())

    row = AlertQueue(
        id=str(alert_id),
        type=alert_type,
        payload=json.dumps(payload, default=str),
        status="pending",
        attempts=0,
        next_attempt_at=datetime.utcnow(),
        last_error=None,
    )

    db = SessionLocal()
    try:
        db.add(row)
        db.commit()
        return True
    except Exception as e:
        db.rollback()
        logger.exception("Failed to enqueue alert %s: %s", alert_type, e)
        return False
    finally:
        db.close()


def _compute_next_attempt(attempts: int) -> datetime:
    # Exponential-ish backoff: base * attempt (keeps jitter simple).
    seconds = ALERT_QUEUE_BACKOFF_BASE_SECONDS * max(1, attempts)
    return datetime.utcnow() + timedelta(seconds=seconds)


def _deserialize_payload(row: AlertQueue) -> dict[str, Any]:
    try:
        return json.loads(row.payload)
    except Exception:
        return {}


def _send_one_alert(db: Session, row: AlertQueue) -> None:
    payload = _deserialize_payload(row)
    alert_type = row.type

    # Import inside function to avoid circular imports at module load time.
    from backend import email_service, sms_alerts

    if alert_type == "sms_high_risk":
        sms_alerts.notify_high_risk_direct(
            scan_id=str(payload.get("scan_id", "")),
            patient_id=str(payload.get("patient_id", "")),
            imt_mm=float(payload.get("imt_mm", 0.0)),
            risk_level=str(payload.get("risk_level", "")),
        )
        return

    if alert_type == "email_referral":
        patient_id = str(payload.get("patient_id", ""))
        patient = db.get(Patient, patient_id)
        if not patient:
            raise ValueError("Patient not found for email_referral")
        email_service.send_referral_email_direct(
            patient,
            imt_mm=float(payload.get("imt_mm", 0.0)),
            risk_level=str(payload.get("risk_level", "")),
        )
        return

    if alert_type == "sms_chw_id":
        sms_alerts.send_chw_id_sms_direct(
            phone=str(payload.get("phone", "")),
            staff_id=str(payload.get("staff_id", "")),
        )
        return

    if alert_type == "email_chw_id":
        email_service.send_chw_id_email_direct(
            to_email=str(payload.get("email", "")),
            staff_id=str(payload.get("staff_id", "")),
        )
        return

    if alert_type == "email_password_reset":
        email_service.send_password_reset_email_direct(
            to_email=str(payload.get("email", "")),
            reset_link_or_token=str(payload.get("reset_link_or_token", "")),
        )
        return

    if alert_type == "email_welcome":
        patient_id = str(payload.get("patient_id", ""))
        patient = db.get(Patient, patient_id)
        if not patient:
            raise ValueError("Patient not found for email_welcome")
        email_service.send_welcome_email_direct(patient)
        return

    raise ValueError(f"Unknown alert type: {alert_type}")


def process_due_alerts(batch_size: int | None = None) -> int:
    """Process pending/failed alerts that are due. Returns number processed."""
    if not ALERT_QUEUE_ENABLED:
        return 0

    limit = batch_size or ALERT_QUEUE_MAX_BATCH_SIZE
    now = datetime.utcnow()
    processed = 0

    db = SessionLocal()
    try:
        due_rows = (
            db.query(AlertQueue)
            .filter(
                and_(
                    AlertQueue.status.in_(["pending", "failed", "processing"]),
                    AlertQueue.next_attempt_at <= now,
                    AlertQueue.attempts < ALERT_QUEUE_MAX_ATTEMPTS,
                )
            )
            .order_by(AlertQueue.next_attempt_at.asc())
            .limit(limit)
            .all()
        )

        for row in due_rows:
            processed += 1
            try:
                row.status = "processing"
                row.attempts = int(row.attempts or 0) + 1
                row.last_error = None
                db.commit()

                _send_one_alert(db, row)

                row.status = "sent"
                row.last_error = None
                db.commit()
            except Exception as e:
                db.rollback()
                attempts = int(row.attempts or 0)
                row.status = "failed"
                row.last_error = str(e)[:2000]
                row.next_attempt_at = _compute_next_attempt(attempts)
                db.commit()

    finally:
        db.close()

    return processed


def snapshot_failed(limit: int = 50) -> dict[str, Any]:
    """Return counts + recent failed alerts for admin UI."""
    if not ALERT_QUEUE_ENABLED:
        return {"enabled": False, "failed_count": 0, "recent": []}

    db = SessionLocal()
    try:
        failed_count = db.query(AlertQueue).filter(AlertQueue.status == "failed").count()
        recent = (
            db.query(AlertQueue)
            .filter(AlertQueue.status == "failed")
            .order_by(AlertQueue.next_attempt_at.desc())
            .limit(limit)
            .all()
        )
        return {
            "enabled": True,
            "failed_count": int(failed_count),
            "recent": [
                {
                    "id": r.id,
                    "type": r.type,
                    "attempts": r.attempts,
                    "next_attempt_at": r.next_attempt_at.isoformat() if r.next_attempt_at else None,
                    "last_error": r.last_error,
                    "payload": _deserialize_payload(r).get("hint"),
                }
                for r in recent
            ],
        }
    finally:
        db.close()

