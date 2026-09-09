"""
Firebase Cloud Messaging — sends push to citizen when complaint status changes.

Setup:
  Firebase Console → Project Settings → Service Accounts
  → Generate new private key → save as backend/firebase-service-account.json
  Then set FIREBASE_SERVICE_ACCOUNT_JSON=./firebase-service-account.json in .env

If the file is missing, notifications are silently disabled so the demo never breaks.
"""
import logging
import os

logger = logging.getLogger("roadwatch.notifications")

_ready = False

try:
    import firebase_admin
    from firebase_admin import credentials, messaging

    from app._importer import load
    settings = load("app.config.settings", "settings")

    if os.path.exists(settings.firebase_service_account_json):
        cred = credentials.Certificate(settings.firebase_service_account_json)
        firebase_admin.initialize_app(cred)
        _ready = True
    else:
        logger.warning("Firebase service account not found — push notifications disabled.")
except Exception as exc:
    logger.warning("Firebase init failed: %s", exc)


def notify_status_change(device_token: str | None, complaint_id: str, new_status: str) -> None:
    """Call this after updating a complaint's status."""
    if not _ready or not device_token:
        return
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title="RoadWatch update",
                body=f"Your pothole report is now '{new_status}'.",
            ),
            data={"complaint_id": complaint_id, "status": new_status},
            token=device_token,
        )
        messaging.send(message)
        logger.info("FCM sent to %s — status: %s", device_token[:8], new_status)
    except Exception as exc:
        logger.warning("FCM send failed: %s", exc)
