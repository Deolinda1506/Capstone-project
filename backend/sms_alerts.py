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
    """
    Send SMS to configured clinician numbers when a high-risk result is saved.
    Safe to call even when SMS is disabled (no-op).
    """
    _init()
    if not _SMS_ENABLED or not _CLINICIAN_PHONES:
        return
    message = (
        f"CarotidCheck: High-risk carotid scan. "
        f"Wall thickness {imt_mm:.1f} mm ({risk_level}). "
        f"Scan ID: {scan_id}. Refer to Gasabo District."
    )
    try:
        import africastalking
        sms = africastalking.SMS
        response = sms.send(message, _CLINICIAN_PHONES)
        logger.info("High-risk SMS sent: %s", response)
    except Exception as e:
        logger.exception("Failed to send high-risk SMS: %s", e)


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
    message = (
        f"CarotidCheck: Your login ID is {staff_id}. "
        f"Use it with your password to sign in. Keep this message for your records."
    )
    try:
        import africastalking
        sms = africastalking.SMS
        response = sms.send(message, [phone])
        logger.info("CHW ID SMS sent to %s: %s", phone, response)
        return True
    except Exception as e:
        logger.exception("Failed to send CHW ID SMS: %s", e)
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
