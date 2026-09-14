import enum
import uuid
from datetime import datetime, timezone  # Include timezone

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


from datetime import datetime, timezone  # Include timezone
# ... other imports ...

class Complaint(Base):
    __tablename__ = "complaints"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    image_url = Column(String, nullable=False)
    latitude = Column(Float, nullable=False)  # type: ignore
    longitude = Column(Float, nullable=False)  # type: ignore
    place_name = Column(Text, nullable=True)
    description = Column(Text, nullable=True)

    # AI output
    severity = Column(Enum(Severity), nullable=True)
    ai_confidence = Column(Float, nullable=True)  # type: ignore
    detections_count = Column(Integer, default=0)
    ai_summary = Column(Text, nullable=True)

    # Timestamps (replace .utcnow with timezone.utc to clear deprecation warnings)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Workflow ───────────────────────────────────────────────────────────────
    status = Column(Enum(Status), default=Status.reported)
    assigned_department = Column(String, default="Unassigned")
    notes = Column(Text, nullable=True)

    # Duplicate clustering ───────────────────────────────────────────────────
    # Reports within DUPLICATE_RADIUS_METERS are grouped by the same cluster_id
    cluster_id = Column(UUID(as_uuid=True), nullable=True)

    # Push notifications ─────────────────────────────────────────────────────
    reporter_device_token = Column(String, nullable=True)

    
