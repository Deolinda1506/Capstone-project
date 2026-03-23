from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import relationship

from backend.database import Base


class Scan(Base):
    __tablename__ = "scans"

    id = Column(String(36), primary_key=True)
    patient_id = Column(String(36), ForeignKey("patients.id"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    # image_path is now optional - images are processed in-memory only (not stored permanently)
    image_path = Column(String(1024), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    deleted_at = Column(DateTime, nullable=True)  # Soft delete: when scan was deleted
    is_deleted = Column(Boolean, default=False, index=True)  # Soft delete: flag
    # Clinician dashboard: high-risk referrals pending review vs reviewed (hospital-side)
    clinician_review_status = Column(String(20), default="pending", nullable=False)  # pending | reviewed | not_applicable
    clinician_reviewed_at = Column(DateTime, nullable=True)
    clinician_reviewed_by_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    clinical_notes = Column(Text, nullable=True)

    patient = relationship("Patient", back_populates="scans")
    user = relationship("User", back_populates="scans", foreign_keys=[user_id])
    reviewed_by = relationship("User", foreign_keys=[clinician_reviewed_by_id])
    result = relationship("Result", back_populates="scan", uselist=False, cascade="all, delete-orphan")
