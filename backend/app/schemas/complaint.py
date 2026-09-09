import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class ComplaintOut(BaseModel):
    id: uuid.UUID
    image_url: str
    latitude: float
    longitude: float
    description: Optional[str] = None

    severity: Optional[str] = None
    ai_confidence: Optional[float] = None
    detections_count: int = 0
    ai_summary: Optional[str] = None

    status: str
    assigned_department: str
    notes: Optional[str] = None

    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ComplaintUpdate(BaseModel):
    status: Optional[str] = None
    assigned_department: Optional[str] = None
    notes: Optional[str] = None
