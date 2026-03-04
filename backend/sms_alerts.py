"""
SMS alerts to clinicians (Africa's Talking) when a high-risk scan result is recorded.
Configure via env: AFRICAS_TALKING_USERNAME, AFRICAS_TALKING_API_KEY, AFRICAS_TALKING_CLINICIAN_PHONES (comma-separated).
If not configured, alerts are skipped (no error).
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
    if username and api_key and phones:
        _CLINICIAN_PHONES = [p.strip() for p in phones.split(",") if p.strip()]
        try:
            import africastalking
            africastalking.initialize(username, api_key)
            _SMS_ENABLED = True
            logger.info("SMS alerts enabled (Africa's Talking); %d clinician number(s).", len(_CLINICIAN_PHONES))
        except Exception as e:
            logger.warning("Africa's Talking init failed: %s. SMS alerts disabled.", e)
    else:
        logger.info("SMS alerts disabled (set AFRICAS_TALKING_USERNAME, API_KEY, CLINICIAN_PHONES to enable).")


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
