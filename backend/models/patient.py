from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from backend.database import Base


class Patient(Base):
    __tablename__ = "patients"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    identifier = Column(String(255), nullable=False)  # Unique patient ID
    name = Column(String(255), nullable=True)  # Patient name (for clinician verification)
    age = Column(Integer, nullable=True)  # Patient age in years (for clinician verification)
    email = Column(String(255), nullable=True)  # For welcome and referral emails
    facility = Column(String(255))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    deleted_at = Column(DateTime, nullable=True)  # Soft delete: when patient was deleted
    is_deleted = Column(Boolean, default=False, index=True)  # Soft delete: flag
    
    user = relationship("User", back_populates="patients")
    scans = relationship("Scan", back_populates="patient", order_by="Scan.created_at", cascade="all, delete-orphan")
