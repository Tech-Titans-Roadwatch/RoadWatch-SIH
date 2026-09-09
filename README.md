# RoadWatch

**Smart India Hackathon 2026 · MB-04 · Team Tech Titans**

RoadWatch is an AI-powered pothole reporting and road maintenance management platform designed to streamline infrastructure repair workflows. It allows citizens to seamlessly report road hazards via mobile devices with automated AI severity scoring and precise GPS tagging, while providing authorities with a centralized dashboard and live severity map.

---

## Key Features

* **AI-Powered Pothole Detection:** Utilizes a custom-trained Ultralytics YOLO model to detect potholes from images and automatically calculate severity scores (Low, Medium, High).
* **Precise Geotagging:** Captures real-time GPS coordinates to map hazards accurately.
* **Live Severity Map:** Visualizes all submitted reports color-coded by hazard severity.
* **Admin Dashboard:** Enables administrators to track complaint statuses, review image evidence, and assign repairs to the appropriate departments.

---

## Tech Stack

* **Frontend:** Flutter (Cross-platform mobile application)
* **Backend:** FastAPI (Python 3.12, asynchronous API routing)
* **AI / Computer Vision:** Ultralytics YOLO, PyTorch
* **Database & Services:** SQLite/PostgreSQL, Local/Tunneling via ngrok for device testing

---

## Project Structure

```text
SIH PROJECT/
├── backend/
│   ├── app/
│   │   ├── ml/                 # YOLO model and detection logic
│   │   ├── models/             # Database models
│   │   ├── routers/            # API endpoints (complaints, admin, etc.)
│   │   ├── services/           # Business logic and coordination
│   │   └── utils/              # Helper utilities (geo-clustering, etc.)
│   ├── ml_weights/             # Trained YOLO model weights (.pt files)
│   └── venv/                   # Python virtual environment
└── frontend/
    ├── assets/
    │   ├── icons/              # Custom UI icons
    │   └── images/             # Logos and graphic assets
    ├── lib/                    # Flutter application screens and widgets
    └── pubspec.yaml            # Flutter dependencies and asset declarations"# RoadWatch-SIH" 
