"""
Basic smoke tests for the complaints API.
Run with:  pytest tests/
"""
import importlib
from unittest.mock import MagicMock, patch

import pytest

# We load via importlib because the service lives in a numbered folder
_svc = importlib.import_module("app.services.complaint_service")

def _mock_db():
    db = MagicMock()
    return db


def test_get_all_complaints_no_filter():
    db = _mock_db()
    db.query.return_value.filter.return_value = db.query.return_value
    db.query.return_value.order_by.return_value.all.return_value = []
    result = _svc.get_all_complaints(db, status_filter=None)
    assert result == []


def test_get_complaint_by_id_not_found():
    import uuid
    db = _mock_db()
    db.query.return_value.filter.return_value.first.return_value = None
    result = _svc.get_complaint_by_id(db, uuid.uuid4())
    assert result is None


def test_update_complaint_status():
    db = _mock_db()
    complaint = MagicMock()
    complaint.status = "Reported"

    _svc.update_complaint(db, complaint, status="Verified",
                          assigned_department=None, notes=None)

    assert complaint.status == "Verified"
    db.commit.assert_called_once()
