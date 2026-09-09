import math
import uuid
from typing import Optional

from sqlalchemy.orm import Session


def haversine_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Returns the distance in metres between two GPS coordinates."""
    R = 6_371_000  # Earth radius in metres
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * R * math.asin(math.sqrt(a))


def find_cluster_id(
    db: Session,
    lat: float,
    lon: float,
    radius_meters: float = 25.0,
) -> Optional[uuid.UUID]:
    """
    Returns the cluster_id of an existing unresolved complaint within
    `radius_meters` of the given GPS point, or None if no match.
    Reports within this radius are considered duplicates and grouped together
    so the admin dashboard shows '1 issue, N reports' instead of N rows.
    """
    from app._importer import load
    Complaint = load("app.models.complaint", "Complaint")
    Status = load("app.models.complaint", "Status")

    nearby = db.query(Complaint).filter(Complaint.status != Status.resolved).all()
    for c in nearby:
        if haversine_meters(lat, lon, c.latitude, c.longitude) <= radius_meters:
            return c.cluster_id or c.id
    return None
