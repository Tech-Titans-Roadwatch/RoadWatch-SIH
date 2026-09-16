"""
Business logic for complaints.
The router (routers/complaints.py) handles HTTP in/out.
This module handles the actual work so it's testable without HTTP.
"""
import os
import uuid
from typing import Any, List, Optional

import cv2
import numpy as np
from fastapi import HTTPException
from PIL import Image  # type: ignore
from sqlalchemy.orm import Session
from geopy.geocoders import Nominatim  # type: ignore
from ultralytics import YOLO  # type: ignore

from app._importer import load

Complaint = load("app.models.complaint", "Complaint")
Status    = load("app.models.complaint", "Status")
settings  = load("app.config.settings",  "settings")
analyze_image     = load("app.ml.pothole_detector", "analyze_image")
find_cluster_id = load("app.utils.geo_utils",       "find_cluster_id")


def _detect_screen_spoof(filepath: str) -> bool:
    """
    Stricter screen-spoof detection using 2D Fast Fourier Transform (FFT) 
    with a lower sensitivity threshold to catch laptop/phone monitor grids immediately.
    """
    try:
        img = cv2.imread(filepath, cv2.IMREAD_GRAYSCALE)
        if img is None:
            return False
        
        # Resize to standard dimensions for consistent frequency analysis
        img = cv2.resize(img, (512, 512))
        
        # Compute 2D Fast Fourier Transform
        f = np.fft.fft2(img)
        fshift = np.fft.fftshift(f)
        magnitude_spectrum = 20 * np.log(np.abs(fshift) + 1)
        
        h, w = magnitude_spectrum.shape
        center_h, center_w = h // 2, w // 2
        
        # Mask out the center (low frequencies / general image gradients)
        mask = np.ones((h, w), np.uint8)
        cv2.circle(mask, (center_w, center_h), 25, 0, -1)
        
        high_freq_spectrum = magnitude_spectrum * mask
        max_peak = np.max(high_freq_spectrum)
        mean_high = np.mean(high_freq_spectrum[high_freq_spectrum > 0])
        
        # Stricter thresholds for screen pixel grids and Moiré patterns
        if max_peak > 130 or mean_high > 30:
            return True
    except Exception as e:
        print(f"Strict screen detection check error: {e}")
    return False


def get_all_complaints(db: Session, status_filter: Optional[str] = None) -> List[Any]:
    q = db.query(Complaint)
    if status_filter:
        q = q.filter(Complaint.status == status_filter)
    return q.order_by(Complaint.created_at.desc()).all()


def get_complaint_by_id(db: Session, complaint_id: uuid.UUID):
    return db.query(Complaint).filter(Complaint.id == complaint_id).first()

def _validate_image_quality(filepath: str) -> Optional[str]:
  """Validates minimum resolution, brightness, and blur using OpenCV."""
  try:
    img = cv2.imread(filepath)
    if img is None:
      return "Invalid image file."

    h, w = img.shape[:2]
    # Minimum Resolution Check (1280x720)
    if w < 1280 or h < 720:
      return (
          f"Resolution too low ({w}x{h}). Minimum required is 1280x720 pixels."
      )

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Brightness / Dim Check
    avg_brightness = float(gray.mean())  # type: ignore
    if avg_brightness < 40.0:
      return "Photo is too dim or dark. Please use better lighting or flash."

    # Blur Detection (Laplacian Variance)
    laplacian_var = float(
        cv2.Laplacian(gray, cv2.CV_64F).var()
    )  # type: ignore
    if laplacian_var < 100.0:
      return "Image is too blurry. Please hold the camera steady and retake."

  except Exception as e:
    print(f"Image quality validation error: {e}")
  return None

async def create_complaint(
    db: Session,
    photo_bytes: bytes,
    filename: str,
    latitude: float,
    longitude: float,
    description: Optional[str],
    device_token: Optional[str],
):
  ext = os.path.splitext(filename)[1] or ".jpg"
  saved_name = f"{uuid.uuid4()}{ext}"
  filepath = os.path.join(settings.upload_dir, saved_name)
  with open(filepath, "wb") as f:
    f.write(photo_bytes)

  # 1. Strict Anti-Spoofing Check: Instantly reject screen captures or monitor photos
  if _detect_screen_spoof(filepath):
    if os.path.exists(filepath):
      os.remove(filepath)
    raise HTTPException(
        status_code=400,
        detail=(
            "Security Error: Photos taken of computer or mobile screens are"
            " strictly blocked. Please photograph a real road pothole."
        ),
    )

  # 2. Camera Quality Validation (Resolution, Brightness, and Blur Check)
  quality_error = _validate_image_quality(filepath)
  if quality_error:
    if os.path.exists(filepath):
      os.remove(filepath)
    raise HTTPException(status_code=400, detail=quality_error)

  result = analyze_image(filepath)

  try:
    weights_path = os.getenv("YOLO_WEIGHTS_PATH", "app/ml_weights/best.pt")
    model = YOLO(weights_path)  # type: ignore
    img_cv = cv2.imread(filepath)
    if img_cv is not None:
      yolo_results: Any = model(  # type: ignore
          img_cv, conf=float(os.getenv("YOLO_CONFIDENCE_THRESHOLD", 0.25))
      )
      if yolo_results and len(yolo_results) > 0:
        annotated_img = yolo_results[0].plot()  # type: ignore
        cv2.imwrite(filepath, annotated_img)  # type: ignore
  except Exception as e:
    print(f"Error drawing bounding boxes: {e}")

  place_name = "Unknown Location"
  try:
    geolocator = Nominatim(user_agent="roadwatch_app")
    location = geolocator.reverse((latitude, longitude))  # type: ignore
    if location:
      place_name = str(location)  # type: ignore
  except Exception as e:
    print(f"Geocoding error: {e}")

  cluster_id = find_cluster_id(db, latitude, longitude)

  complaint = Complaint(
      image_url=f"/uploads/{saved_name}",
      latitude=latitude,
      longitude=longitude,
      place_name=place_name,
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
  db.refresh(complaint)  # type: ignore
  return complaint

def update_complaint(
    db: Session,
    complaint: Any,
    notes: Optional[str],
):
    if notes is not None:
        complaint.notes = notes
    db.commit()
    db.refresh(complaint)  # type: ignore
    return complaint


def delete_complaint(db: Session, complaint: Any) -> None:
    db.delete(complaint)  # type: ignore
    db.commit()