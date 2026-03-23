"""
SMS alerts to clinicians (Africa's Talking) when a high-risk scan result is recorded.
Configure via env: AFRICAS_TALKING_USERNAME, AFRICAS_TALKING_API_KEY, AFRICAS_TALKING_CLINICIAN_PHONES (comma-separated).
If not configured, alerts are skipped (no error).

Sandbox (free): Use AFRICAS_TALKING_USERNAME=sandbox and your sandbox API key.
Messages are simulated and not delivered to real phones. See .env.example.
"""
from __future__ import annotations

import os
import logging
import time

logger = logging.getLogger(__name__)

_CLINICIAN_PHONES: list[str] = []
_SMS_ENABLED = False

def _init():
    global _CLINICIAN_PHONES, _SMS_ENABLED
    if _CLINICIAN_PHONES:
        return
    username = os.getenv("AFRICAS_TALKING_USERNAME", "").strip()
    api_key = os.getenv("AFRICAS_TALKING_API_KEY", "").strip()
    phones = os.getenv("AFRICAS_TALKING_CLINICIAN_PHONES", "").strip()
    if username and api_key:
        _CLINICIAN_PHONES = [p.strip() for p in phones.split(",") if p.strip()] if phones else []
        try:
            import africastalking
            africastalking.initialize(username, api_key)
            _SMS_ENABLED = True
            logger.info("SMS enabled (Africa's Talking); %d clinician number(s) for high-risk alerts.", len(_CLINICIAN_PHONES))
        except Exception as e:
            logger.warning("Africa's Talking init failed: %s. SMS disabled.", e)
    else:
        logger.info("SMS disabled (set AFRICAS_TALKING_USERNAME and API_KEY to enable).")


def notify_high_risk(
    scan_id: str,
    patient_id: str,
    imt_mm: float,
    risk_level: str,
) -> None:
    """Enqueue (or send) SMS to clinicians for high-risk scans."""
    _init()
    if not _SMS_ENABLED or not _CLINICIAN_PHONES:
        return

    try:
        from backend.alert_queue import is_enabled as _aq_enabled, enqueue_alert as _enqueue

        if _aq_enabled():
            if _enqueue(
                "sms_high_risk",
                {
                    "scan_id": scan_id,
                    "patient_id": patient_id,
                    "imt_mm": imt_mm,
                    "risk_level": risk_level,
                },
            ):
                logger.info("Enqueued sms_high_risk for scan_id=%s", scan_id)
                return
    except Exception:
        # Fall back to direct sending if queue enqueue fails.
        logger.exception("Queue enqueue failed; falling back to direct SMS send.")

    notify_high_risk_direct(scan_id, patient_id, imt_mm, risk_level)


def notify_high_risk_direct(
    scan_id: str,
    patient_id: str,
    imt_mm: float,
    risk_level: str,
) -> None:
    """Send SMS to configured clinician numbers (direct, no queue)."""
    _init()
    if not _SMS_ENABLED or not _CLINICIAN_PHONES:
        return
    message = (
        f"CarotidCheck: High-risk carotid scan. "
        f"Wall thickness {imt_mm:.1f} mm ({risk_level}). "
        f"Scan ID: {scan_id}. Refer to Gasabo District."
    )
    for attempt in range(1, 4):
        try:
            import africastalking
            sms = africastalking.SMS
            response = sms.send(message, _CLINICIAN_PHONES)
            logger.info("High-risk SMS sent (attempt %d): %s", attempt, response)
            return
        except Exception as e:
            if attempt == 3:
                logger.exception("Failed to send high-risk SMS after retries: %s", e)
                return
            time.sleep(0.6 * attempt)


def send_chw_id_sms(phone: str, staff_id: str) -> bool:
    """
    Send CHW their unique ID via SMS after registration.
    Phone should be E.164 (e.g. +250788123456). Safe to call when SMS disabled (returns False).
    """
    _init()
    if not _SMS_ENABLED or not phone or not staff_id:
        return False
    phone = _normalize_phone(phone)
    if not phone:
        return False

    try:
        from backend.alert_queue import is_enabled as _aq_enabled, enqueue_alert as _enqueue

        if _aq_enabled():
            if _enqueue(
                "sms_chw_id",
                {
                    "phone": phone,
                    "staff_id": staff_id,
                },
            ):
                logger.info("Enqueued sms_chw_id for phone=%s", phone)
                return True
    except Exception:
        logger.exception("Queue enqueue failed; falling back to direct CHW SMS send.")

    return send_chw_id_sms_direct(phone, staff_id)


def send_chw_id_sms_direct(phone: str, staff_id: str) -> bool:
    """Send CHW ID SMS (direct, no queue)."""
    _init()
    if not _SMS_ENABLED:
        return False
    message = (
        f"CarotidCheck: Your login ID is {staff_id}. "
        f"Use it with your password to sign in. Keep this message for your records."
    )
    for attempt in range(1, 4):
        try:
            import africastalking
            sms = africastalking.SMS
            response = sms.send(message, [phone])
            logger.info("CHW ID SMS sent to %s (attempt %d): %s", phone, attempt, response)
            return True
        except Exception as e:
            if attempt == 3:
                logger.exception("Failed to send CHW ID SMS after retries: %s", e)
                return False
            time.sleep(0.6 * attempt)
    return False


def _normalize_phone(phone: str) -> str:
    """Normalize to E.164 for Rwanda (+250...)."""
    phone = "".join(c for c in phone if c.isdigit() or c == "+")
    if not phone:
        return ""
    if phone.startswith("+250"):
        return phone
    if phone.startswith("250"):
        return "+" + phone
    if phone.startswith("0"):
        return "+250" + phone[1:]
    if len(phone) == 9 and phone.startswith("7"):
        return "+250" + phone
    return "+250" + phone if len(phone) >= 9 else ""
