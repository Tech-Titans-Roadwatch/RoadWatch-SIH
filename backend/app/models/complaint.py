import enum
import uuid
from datetime import datetime

from sqlalchemy import Column, String, Float, DateTime, Enum, Text, Integer
from sqlalchemy.dialects.postgresql import UUID

from app._importer import load
Base = load("app.database.connection", "Base")


class Severity(str, enum.Enum):
    low = "Low"
    medium = "Medium"
    high = "High"


class Status(str, enum.Enum):
    reported = "Reported"
    verified = "Verified"
    assigned = "Assigned"
    repair_in_progress = "Repair in Progress"
    resolved = "Resolved"


class Complaint(Base):
    __tablename__ = "complaints"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    image_url = Column(String, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    description = Column(Text, nullable=True)

    # AI output ─────────────────────────────────────────────────────────────
    severity = Column(Enum(Severity), nullable=True)
    ai_confidence = Column(Float, nullable=True)
    detections_count = Column(Integer, default=0)
    ai_summary = Column(Text, nullable=True)

    # Workflow ───────────────────────────────────────────────────────────────
    status = Column(Enum(Status), default=Status.reported)
    assigned_department = Column(String, default="Unassigned")
    notes = Column(Text, nullable=True)

    # Duplicate clustering ───────────────────────────────────────────────────
    # Reports within DUPLICATE_RADIUS_METERS are grouped by the same cluster_id
    cluster_id = Column(UUID(as_uuid=True), nullable=True)

    # Push notifications ─────────────────────────────────────────────────────
    reporter_device_token = Column(String, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
