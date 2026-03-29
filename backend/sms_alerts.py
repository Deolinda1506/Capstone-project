"""
SMS is not used in this project. These functions are no-op stubs so callers
(routers, alert queue) keep working; high-risk and CHW flows rely on email instead.
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


def notify_high_risk(
    scan_id: str,
    patient_id: str,
    imt_mm: float,
    risk_level: str,
) -> None:
    """SMS not used; high-risk notification is via email in scans router."""
    logger.debug(
        "notify_high_risk skipped (SMS disabled): scan_id=%s patient_id=%s",
        scan_id,
        patient_id,
    )


def notify_high_risk_direct(
    scan_id: str,
    patient_id: str,
    imt_mm: float,
    risk_level: str,
) -> None:
    """No-op for queued sms_high_risk jobs."""
    logger.debug("notify_high_risk_direct skipped (SMS disabled)")


def send_chw_id_sms(phone: str, staff_id: str) -> bool:
    """CHW ID is delivered by email when provided; SMS not used."""
    logger.debug("send_chw_id_sms skipped (SMS disabled)")
    return False


def send_chw_id_sms_direct(phone: str, staff_id: str) -> bool:
    """No-op for queued sms_chw_id jobs."""
    return False
