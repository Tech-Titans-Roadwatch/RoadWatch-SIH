"""
Unit tests for YOLO severity scoring (no real model needed — mocks detections).
Run with:  pytest tests/
"""
import importlib

_det = importlib.import_module("app.ml.pothole_detector")
Detection    = _det.Detection
score_severity = _det.score_severity


def test_no_detections_returns_low():
    result = score_severity([])
    assert result.severity == "Low"
    assert result.detections_count == 0


def test_small_detection_returns_low():
    detections = [Detection(confidence=0.3, box_area_ratio=0.02)]
    result = score_severity(detections)
    assert result.severity == "Low"


def test_medium_detection():
    detections = [Detection(confidence=0.6, box_area_ratio=0.20)]
    result = score_severity(detections)
    assert result.severity in ("Medium", "High")


def test_large_detection_returns_high():
    detections = [Detection(confidence=0.9, box_area_ratio=0.60)]
    result = score_severity(detections)
    assert result.severity == "High"


def test_multiple_detections_increases_score():
    single   = score_severity([Detection(confidence=0.5, box_area_ratio=0.10)])
    multiple = score_severity([Detection(confidence=0.5, box_area_ratio=0.10)] * 5)
    # More detections should produce a higher or equal score
    assert multiple.detections_count == 5
    assert single.detections_count == 1