"""
Send welcome email when a patient is created and referral email when they are referred to hospital.
Configure via env: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, EMAIL_FROM.
Optional: REFERRAL_HOSPITAL_NAME (e.g. Gasabo District Hospital).
If not configured, emails are skipped (no error).
"""
from __future__ import annotations

import os
import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

logger = logging.getLogger(__name__)

_EMAIL_ENABLED = False
_SMTP_HOST = ""
_SMTP_PORT = 587
_SMTP_USER = ""
_SMTP_PASS = ""
_EMAIL_FROM = ""
_REFERRAL_HOSPITAL = "Gasabo District Hospital"


def _init() -> None:
    global _EMAIL_ENABLED, _SMTP_HOST, _SMTP_PORT, _SMTP_USER, _SMTP_PASS, _EMAIL_FROM, _REFERRAL_HOSPITAL
    if _EMAIL_ENABLED or _SMTP_HOST:
        return
    _SMTP_HOST = os.getenv("SMTP_HOST", "").strip()
    _SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
    _SMTP_USER = os.getenv("SMTP_USER", "").strip()
    _SMTP_PASS = os.getenv("SMTP_PASSWORD", "").strip()
    _EMAIL_FROM = os.getenv("EMAIL_FROM", _SMTP_USER or "carotidcheck@example.com").strip()
    _REFERRAL_HOSPITAL = os.getenv("REFERRAL_HOSPITAL_NAME", _REFERRAL_HOSPITAL).strip()
    if _SMTP_HOST and _SMTP_USER and _SMTP_PASS:
        _EMAIL_ENABLED = True
        logger.info("Email service enabled (SMTP).")
    else:
        logger.info("Email disabled (set SMTP_HOST, SMTP_USER, SMTP_PASSWORD to enable).")


def _send(to: str, subject: str, body_text: str, body_html: str | None = None) -> bool:
    _init()
    if not _EMAIL_ENABLED or not to or "@" not in to:
        return False
    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = _EMAIL_FROM
        msg["To"] = to
        msg.attach(MIMEText(body_text, "plain"))
        if body_html:
            msg.attach(MIMEText(body_html, "html"))
        with smtplib.SMTP(_SMTP_HOST, _SMTP_PORT) as server:
            server.starttls()
            server.login(_SMTP_USER, _SMTP_PASS)
            server.sendmail(_EMAIL_FROM, [to], msg.as_string())
        logger.info("Email sent to %s: %s", to, subject)
        return True
    except Exception as e:
        logger.exception("Failed to send email: %s", e)
        return False


def send_welcome_email(patient) -> None:
    """
    Send welcome email to patient when they are first registered.
    Includes their unique patient ID (identifier).
    """
    email = getattr(patient, "email", None) if patient else None
    if not email or not isinstance(email, str) or "@" not in email:
        return
    identifier = getattr(patient, "identifier", "—") or "—"
    subject = "Welcome to CarotidCheck – Your Patient ID"
    text = (
        f"Hello,\n\n"
        f"You have been registered in the CarotidCheck carotid screening system.\n\n"
        f"Your unique Patient ID is: {identifier}\n\n"
        f"Please keep this ID for your records and for any follow-up visits.\n\n"
        f"If you have questions, contact your health facility.\n\n"
        f"— CarotidCheck Team"
    )
    _send(email, subject, text)


def send_password_reset_email(to_email: str, reset_link_or_token: str) -> bool:
    """
    Send password reset email. reset_link_or_token can be a full URL
    (e.g. https://yourapp.com/reset-password?token=...) or a token to copy.
    Returns True if sent, False if email disabled or send failed.
    """
    if not to_email or "@" not in to_email:
        return False
    subject = "CarotidCheck – Reset your password"
    text = (
        f"Hello,\n\n"
        f"You requested a password reset for your CarotidCheck account.\n\n"
        f"Use the information below to set a new password (valid for 1 hour):\n\n"
        f"{reset_link_or_token}\n\n"
        f"If you did not request this, you can ignore this email.\n\n"
        f"— CarotidCheck Team"
    )
    return _send(to_email, subject, text)


def send_referral_email(patient, imt_mm: float, risk_level: str) -> None:
    """
    Send email to patient when they are referred to hospital (high-risk result).
    """
    email = getattr(patient, "email", None) if patient else None
    if not email or not isinstance(email, str) or "@" not in email:
        return
    identifier = getattr(patient, "identifier", "—") or "—"
    subject = "CarotidCheck – Referral to Hospital for Follow-up"
    text = (
        f"Hello,\n\n"
        f"Your recent carotid ultrasound screening result indicates that a follow-up visit is recommended.\n\n"
        f"Patient ID: {identifier}\n"
        f"Wall thickness: {imt_mm:.1f} mm\n"
        f"Risk level: {risk_level}\n\n"
        f"You have been referred to: {_REFERRAL_HOSPITAL}\n\n"
        f"Please visit within 48 hours for a comprehensive cardiovascular assessment.\n\n"
        f"If you have questions, contact your health worker or the facility.\n\n"
        f"— CarotidCheck Team"
    )
    _send(email, subject, text)
