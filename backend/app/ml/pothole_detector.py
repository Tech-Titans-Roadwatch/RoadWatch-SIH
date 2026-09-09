"""
YOLO pothole detection + severity scoring.

SWAP MODEL INSTRUCTIONS (one step):
  After Colab fine-tuning, copy best.pt to backend/ml_weights/best.pt
  then set YOLO_WEIGHTS_PATH=./ml_weights/best.pt in .env and restart.
  Nothing else changes.
"""
from dataclasses import dataclass
from dataclasses import dataclass
from typing import List

from ultralytics import YOLO
import torch
from ultralytics.nn.tasks import DetectionModel
from torch.nn.modules.container import Sequential

torch.serialization.add_safe_globals([DetectionModel, Sequential])
from app._importer import load
settings = load("app.config.settings", "settings")
# ── Singleton model ──────────────────────────────────────────────────────────
_model: YOLO | None = None


def get_model() -> YOLO:
    global _model
    if _model is None:
        _model = YOLO(settings.yolo_weights_path)
    return _model


# ── Data classes ─────────────────────────────────────────────────────────────

@dataclass
class Detection:
    confidence: float
    box_area_ratio: float   # fraction of full image area covered by this box


@dataclass
class SeverityResult:
    severity: str           # "Low" | "Medium" | "High"
    confidence: float
    detections_count: int
    summary: str


# ── Core detection ───────────────────────────────────────────────────────────

def run_detection(image_path: str) -> List[Detection]:
    model = get_model()
    results = model.predict(
        source=image_path,
        conf=settings.yolo_confidence_threshold,
        verbose=False,
    )
    detections: List[Detection] = []
    if not results:
        return detections

    r = results[0]
    img_area = float(r.orig_shape[0] * r.orig_shape[1])

    for box in r.boxes:
        conf = float(box.conf[0])
        x1, y1, x2, y2 = [float(v) for v in box.xyxy[0]]
        box_area = max(0.0, x2 - x1) * max(0.0, y2 - y1)
        detections.append(
            Detection(confidence=conf, box_area_ratio=box_area / img_area)
        )
    return detections


# ── Severity scoring ─────────────────────────────────────────────────────────

def score_severity(detections: List[Detection]) -> SeverityResult:
    """
    Converts raw YOLO detections into Low / Medium / High.

    Scoring formula (tune thresholds using the Colab calibration step):
      score = (largest_box_area_ratio × 0.60)
            + (avg_confidence         × 0.25)
            + (detection_count / 5    × 0.15)   capped at 5

    Thresholds (from Colab Step 5 calibration output):
      score >= 0.45  →  High
      score >= 0.20  →  Medium
      else           →  Low
    """
    if not detections:
        return SeverityResult(
            severity="Low",
            confidence=0.0,
            detections_count=0,
            summary="No pothole detected — recommend manual review.",
        )

    largest = max(detections, key=lambda d: d.box_area_ratio)
    avg_conf = sum(d.confidence for d in detections) / len(detections)
    count = len(detections)

    score = (
        largest.box_area_ratio * 0.60
        + avg_conf * 0.25
        + min(count, 5) / 5 * 0.15
    )

    if score >= 0.45:
        severity = "High"
    elif score >= 0.20:
        severity = "Medium"
    else:
        severity = "Low"

    return SeverityResult(
        severity=severity,
        confidence=round(avg_conf, 3),
        detections_count=count,
        summary=(
            f"Detected {count} pothole region(s). "
            f"Largest covers {largest.box_area_ratio * 100:.1f}% of frame, "
            f"avg confidence {avg_conf:.2f}."
        ),
    )


# ── Public entry point ───────────────────────────────────────────────────────

def analyze_image(image_path: str) -> SeverityResult:
    """Call this from the complaints router. Returns severity + summary."""
    return score_severity(run_detection(image_path))
