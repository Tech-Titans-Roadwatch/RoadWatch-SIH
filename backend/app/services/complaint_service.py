"""
Business logic for complaints.
The router (routers/complaints.py) handles HTTP in/out.
This module handles the actual work so it's testable without HTTP.
"""
import os
import uuid
from typing import List, Optional

from sqlalchemy.orm import Session

from app._importer import load

Complaint = load("app.models.complaint", "Complaint")
Status    = load("app.models.complaint", "Status")
settings  = load("app.config.settings",  "settings")
analyze_image    = load("app.ml.pothole_detector",  "analyze_image")
find_cluster_id  = load("app.utils.geo_utils",      "find_cluster_id")


def get_all_complaints(db: Session, status_filter: Optional[str] = None) -> List:
    q = db.query(Complaint)
    if status_filter:
        q = q.filter(Complaint.status == status_filter)
    return q.order_by(Complaint.created_at.desc()).all()


def get_complaint_by_id(db: Session, complaint_id: uuid.UUID):
    return db.query(Complaint).filter(Complaint.id == complaint_id).first()


async def create_complaint(
    db: Session,
    photo_bytes: bytes,
    filename: str,
    latitude: float,
    longitude: float,
    description: Optional[str],
    device_token: Optional[str],
):
    # 1. Save photo to disk
    ext = os.path.splitext(filename)[1] or ".jpg"
    saved_name = f"{uuid.uuid4()}{ext}"
    filepath = os.path.join(settings.upload_dir, saved_name)
    with open(filepath, "wb") as f:
        f.write(photo_bytes)

    # 2. Run YOLO detection + severity scoring
    result = analyze_image(filepath)

    # 3. Group with nearby duplicate reports
    cluster_id = find_cluster_id(db, latitude, longitude)

    # 4. Persist
    complaint = Complaint(
        image_url=f"/uploads/{saved_name}",
        latitude=latitude,
        longitude=longitude,
        description=description,
        severity=result.severity,
        ai_confidence=result.confidence,
        detections_count=result.detections_count,
        ai_summary=result.summary,
        status=Status.reported,
        assigned_department="Unassigned",
        cluster_id=cluster_id,
        reporter_device_token=device_token,
    )
    db.add(complaint)
    db.commit()
    db.refresh(complaint)
    return complaint


def update_complaint(
    db: Session,
    complaint,
    status: Optional[str],
    assigned_department: Optional[str],
    notes: Optional[str],
):
    if status is not None:
        complaint.status = status
    if assigned_department is not None:
        complaint.assigned_department = assigned_department
    if notes is not None:
        complaint.notes = notes
    db.commit()
    db.refresh(complaint)
    return complaint


def delete_complaint(db: Session, complaint) -> None:
    db.delete(complaint)
    db.commit()
