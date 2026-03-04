from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, String
from sqlalchemy.orm import relationship

from backend.database import Base


class Result(Base):
    __tablename__ = "results"

    id = Column(String(36), primary_key=True)
    scan_id = Column(String(36), ForeignKey("scans.id"), nullable=False, unique=True, index=True)
    imt_mm = Column(Float, nullable=False)
    risk_level = Column(String(20), nullable=False)  # "Low", "Moderate", "High"
    is_high_risk = Column(Boolean, nullable=False)
    model_version = Column(String(64))
    created_at = Column(DateTime, default=datetime.utcnow)

    scan = relationship("Scan", back_populates="result")
