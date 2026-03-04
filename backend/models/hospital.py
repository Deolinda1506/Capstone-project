"""Hospital/organization: admins register a hospital, then grant access to clinicians and CHWs."""
from datetime import datetime
from sqlalchemy import Column, DateTime, String
from sqlalchemy.orm import relationship

from backend.database import Base


class Hospital(Base):
    __tablename__ = "hospitals"

    id = Column(String(36), primary_key=True)
    name = Column(String(255), nullable=False)
    address = Column(String(512), nullable=True)
    province = Column(String(128), nullable=True)  # Rwanda: e.g. Kigali, Eastern
    district = Column(String(128), nullable=True)  # e.g. Gasabo, Kicukiro
    sector = Column(String(128), nullable=True)   # e.g. Remera, Niboye
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    users = relationship("User", back_populates="hospital")
