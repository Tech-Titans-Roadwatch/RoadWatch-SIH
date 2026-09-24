import asyncio 
from PIL import Image
import io
import importlib
import uuid
import os
import math
from typing import List, Optional, Any

import cv2
import numpy as np
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session
from ultralytics import YOLO  # type: ignore

# Load all dependencies via importlib (numbered folder names can't be imported directly)[cite: 13]
_db_mod = importlib.import_module("app.database.connection")
_schema_mod = importlib.import_module("app.schemas.complaint")
_svc_mod = importlib.import_module("app.services.complaint_service")
_notif_mod = importlib.import_module("app.services.notification_service")

get_db = _db_mod.get_db
ComplaintOut = _schema_mod.ComplaintOut
ComplaintUpdate = _schema_mod.ComplaintUpdate
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

def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return R * c

@router.post("", response_model=ComplaintOut)
@router.post("/", response_model=ComplaintOut)
async def create_complaint(
    photo: UploadFile = File(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    description: Optional[str] = Form(None),
    device_token: Optional[str] = Form(None),
    db: Session = Depends(get_db),
):
    photo_bytes = await photo.read()

    # 1. Non-blocking EXIF check
    try:
        img = Image.open(io.BytesIO(photo_bytes))  # type: ignore
        exif_data = img.getexif()
        if not exif_data:
            print("Warning: Uploaded image lacks standard camera EXIF metadata.")
    except Exception:
        pass

    nparr = np.frombuffer(photo_bytes, np.uint8)
    img_cv = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img_cv is None:
        raise HTTPException(status_code=400, detail="Invalid image file format.")

    # 1.5 Balanced Screen Capture / Monitor Guardrail
    gray_screen_check = cv2.cvtColor(img_cv, cv2.COLOR_BGR2GRAY)
    
    # Fourier Transform to detect screen grid moiré patterns
    f = np.fft.fft2(gray_screen_check)
    fshift = np.fft.fftshift(f)
    magnitude_spectrum = 20 * np.log(np.abs(fshift) + 1)
    
    h, w = magnitude_spectrum.shape
    center_h, center_w = h // 2, w // 2
    outer_region = np.copy(magnitude_spectrum)
    # Exclude low-frequency center content
    outer_region[center_h-20:center_h+20, center_w-20:center_w+20] = 0
    
    # Strict threshold calibration: only triggers on clear monitor grid lines, leaving natural asphalt alone
    if np.max(outer_region) > 155.0:
        raise HTTPException(
            status_code=400,
            detail="Screen capture detected. Please capture a live outdoor photo of a real road."
        )

    # 2. YOLOv8 Pothole Validation & Confidence Filtering
    weights_path = os.getenv("YOLO_WEIGHTS_PATH", "app/ml_weights/best.pt")
    conf_threshold = float(os.getenv("YOLO_CONFIDENCE_THRESHOLD", "0.40"))

    model = YOLO(weights_path)  # type: ignore
    results: Any = model(img_cv, conf=conf_threshold)  # type: ignore

    detections: Any = results[0].boxes  # type: ignore
    valid_detections = []
    for box in detections:
        conf = float(box.conf[0])
        if conf >= conf_threshold:
            valid_detections.append(conf)

    if len(valid_detections) == 0:
        raise HTTPException(
            status_code=400,
            detail="No valid pothole detected in this image. Please upload a valid road photo."
        )

    # 3. Proximity Duplicate Check (Safely handled to prevent 500 crashes)
    try:
        existing_complaints = _svc_mod.get_all_complaints(db, status_filter=None)
        if existing_complaints:
            for comp in existing_complaints:
                comp_lat = getattr(comp, 'latitude', None) or (comp.get('latitude') if isinstance(comp, dict) else None)
                comp_lon = getattr(comp, 'longitude', None) or (comp.get('longitude') if isinstance(comp, dict) else None)
                comp_status = getattr(comp, 'status', 'reported') or (comp.get('status') if isinstance(comp, dict) else 'reported')

                if comp_lat is not None and comp_lon is not None:
                    distance = calculate_distance(latitude, longitude, float(comp_lat), float(comp_lon))
                    if distance < 5.0 and str(comp_status).lower() != 'resolved':
                        raise HTTPException(
                            status_code=409,
                            detail="This pothole is already reported. You can check it in the Admin Dashboard."
                        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"Duplicate check warning: {e}")

    # 4. Save to Database securely with 'await'
    return await _svc_mod.create_complaint(
        db=db,
        photo_bytes=photo_bytes,
        filename=photo.filename or "upload.jpg",
        latitude=latitude,
        longitude=longitude,
        description=description,
        device_token=device_token,
    )

@router.post("/video", response_model=ComplaintOut)
@router.post("/video/", response_model=ComplaintOut)
async def create_video_complaint(
    video: UploadFile = File(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    description: Optional[str] = Form(None),
    device_token: Optional[str] = Form(None),
    db: Session = Depends(get_db),
):
    video_bytes = await video.read()
    filename = video.filename or "upload.mp4"

    # Safely route through create_complaint without assuming it's async or sync
    if asyncio.iscoroutinefunction(_svc_mod.create_complaint):
        return await _svc_mod.create_complaint(
            db=db,
            photo_bytes=video_bytes,
            filename=filename,
            latitude=latitude,
            longitude=longitude,
            description=description,
            device_token=device_token,
        )
    else:
        return _svc_mod.create_complaint(
            db=db,
            photo_bytes=video_bytes,
            filename=filename,
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