from datetime import datetime
from sqlalchemy import Column, DateTime, Integer, String, Text

from backend.database import Base


class AlertQueue(Base):
    __tablename__ = "alert_queue"

    id = Column(String(36), primary_key=True)
    type = Column(String(64), nullable=False, index=True)
    payload = Column(Text, nullable=False)

    # pending | processing | sent | failed
    status = Column(String(20), nullable=False, default="pending", index=True)
    attempts = Column(Integer, nullable=False, default=0)
    next_attempt_at = Column(DateTime, nullable=False, default=datetime.utcnow, index=True)
    last_error = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

