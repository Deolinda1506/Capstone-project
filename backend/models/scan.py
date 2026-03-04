from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String
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
    
    patient = relationship("Patient", back_populates="scans")
    user = relationship("User", back_populates="scans")
    result = relationship("Result", back_populates="scan", uselist=False, cascade="all, delete-orphan")
