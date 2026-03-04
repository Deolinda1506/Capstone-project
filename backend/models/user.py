from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String
from sqlalchemy.orm import relationship

from backend.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True)
    firebase_uid = Column(String(128), unique=True, nullable=True, index=True)  # None for email/password users
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=True)  # For email/password login
    display_name = Column(String(255))
    role = Column(String(50), default="chw", nullable=False)  # admin | clinician | chw
    staff_id = Column(String(128), nullable=True)  # Professional / national ID
    facility = Column(String(255), nullable=True)  # Legacy / site name; prefer hospital.name
    hospital_id = Column(String(36), ForeignKey("hospitals.id"), nullable=True, index=True)  # Set when registered via hospital
    status = Column(String(20), default="approved", nullable=False)  # pending | approved
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    deleted_at = Column(DateTime, nullable=True)  # Soft delete: when user requested deletion
    is_deleted = Column(Boolean, default=False, index=True)  # Soft delete: flag
    password_reset_token = Column(String(255), nullable=True, index=True)
    password_reset_expires = Column(DateTime, nullable=True)

    hospital = relationship("Hospital", back_populates="users")
    patients = relationship("Patient", back_populates="user", cascade="all, delete-orphan")
    scans = relationship("Scan", back_populates="user")
