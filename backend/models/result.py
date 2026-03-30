from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, String
from sqlalchemy.orm import relationship

from backend.database import Base


class Result(Base):
    __tablename__ = "results"

    id = Column(String(36), primary_key=True)
    scan_id = Column(String(36), ForeignKey("scans.id"), nullable=False, unique=True, index=True)
    imt_mm = Column(Float, nullable=True)  # None when segmentation does not support IMT (no synthetic fill)
    risk_level = Column(String(20), nullable=False)  # "Low", "Moderate", "High"
    is_high_risk = Column(Boolean, nullable=False)
    stenosis_pct = Column(Float, nullable=True)  # NASCET % when available
    stenosis_source = Column(String(32), nullable=True)  # "nascet" | "imt_correlation"
    has_ai_overlay = Column(Boolean, nullable=False, default=False)  # True when stored image is green segmentation overlay
    model_version = Column(String(64))
    created_at = Column(DateTime, default=datetime.utcnow)

    scan = relationship("Scan", back_populates="result")
