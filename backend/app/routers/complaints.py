from PIL import Image
import io
import importlib
import uuid
import os
from typing import List, Optional

import cv2
import numpy as np
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session
from ultralytics import YOLO

# Load all dependencies via importlib (numbered folder names can't be imported directly)
_db_mod      = importlib.import_module("app.database.connection")
_schema_mod  = importlib.import_module("app.schemas.complaint")
_svc_mod     = importlib.import_module("app.services.complaint_service")
_notif_mod   = importlib.import_module("app.services.notification_service")

get_db                 = _db_mod.get_db
ComplaintOut         = _schema_mod.ComplaintOut
ComplaintUpdate      = _schema_mod.ComplaintUpdate
notify_status_change = _notif_mod.notify_status_change

router = APIRouter(prefix="/api/complaints", tags=["complaints"])


@router.get("", response_model=List[ComplaintOut])
@router.get("/", response_model=List[ComplaintOut])
def list_complaints(status_filter: Optional[str] = None, db: Session = Depends(get_db)):
    return _svc_mod.get_all_complaints(db, status_filter)


@router.get("/{complaint_id}", response_model=ComplaintOut)
def get_complaint(complaint_id: uuid.UUID, db: Session = Depends(get_db)):
    c = _svc_mod.get_complaint_by_id(db, complaint_id)
    if not c:
        raise HTTPException(status_code=404, detail="Complaint not found")
    return c


@router.post("", response_model=ComplaintOut)
async def create_complaint(
    photo: UploadFile = File(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    description: Optional[str] = Form(None),
    device_token: Optional[str] = Form(None),
    db: Session = Depends(get_db),
):
    photo_bytes = await photo.read()
    
    # ── Image Integrity & EXIF Verification ──────────────────────────────
    try:
        img = Image.open(io.BytesIO(photo_bytes))  # type: ignore
        exif_data = img.getexif()
        if not exif_data:
            print("Warning: Uploaded image lacks standard camera EXIF metadata.")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file format.")
    # ─────────────────────────────────────────────────────────────────────

   # ── YOLO Pothole Detection Validation ────────────────────────────────
    weights_path = os.getenv("YOLO_WEIGHTS_PATH", "app/ml_weights/best.pt")
    conf_threshold = float(os.getenv("YOLO_CONFIDENCE_THRESHOLD", 0.25))
    
    nparr = np.frombuffer(photo_bytes, np.uint8)
    img_cv = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if img_cv is None:
        raise HTTPException(status_code=400, detail="Invalid image file format.")
        
    model = YOLO(weights_path)
    results = model(img_cv, conf=conf_threshold)  # type: ignore
    
    # Check if any objects were detected
    detections = results[0].boxes  # type: ignore
    if len(detections) == 0:
        raise HTTPException(
            status_code=400, 
            detail="No pothole detected in this image. Please upload a valid road image."
        )
    # ─────────────────────────────────────────────────────────────────────
        
    return await _svc_mod.create_complaint(
        db=db,
        photo_bytes=photo_bytes,
        filename=photo.filename or "upload.jpg",
        latitude=latitude,
        longitude=longitude,
        description=description,
        device_token=device_token,
    )


@router.patch("/{complaint_id}", response_model=ComplaintOut)
def update_complaint(
    complaint_id: uuid.UUID,
    update: ComplaintUpdate,
    db: Session = Depends(get_db),
):
    c = _svc_mod.get_complaint_by_id(db, complaint_id)
    if not c:
        raise HTTPException(status_code=404, detail="Complaint not found")
    updated = _svc_mod.update_complaint(
        db, c, update.notes
    )
    return updated


@router.delete("/{complaint_id}")
def delete_complaint(complaint_id: uuid.UUID, db: Session = Depends(get_db)):
    c = _svc_mod.get_complaint_by_id(db, complaint_id)
    if not c:
        raise HTTPException(status_code=404, detail="Complaint not found")
    _svc_mod.delete_complaint(db, c)
    return {"deleted": True}