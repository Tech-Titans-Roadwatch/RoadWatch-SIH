import torch

# Patch torch.load to default weights_only to False for local YOLO model compatibility
_original_torch_load = torch.load
def _patched_torch_load(*args, **kwargs):
    if 'weights_only' not in kwargs:
        kwargs['weights_only'] = False
    return _original_torch_load(*args, **kwargs)

torch.load = _patched_torch_load
import importlib

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Load config and DB via importlib (numbered folder names)
_cfg = importlib.import_module("app.config.settings")
_db  = importlib.import_module("app.database.connection")
_mdl = importlib.import_module("app.models.complaint")   # registers model with Base
_rtr = importlib.import_module("app.routers.complaints")

settings = _cfg.settings
Base     = _db.Base
engine   = _db.engine
router   = _rtr.router

# Create all tables on startup (safe to run repeatedly)
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="RoadWatch API",
    description="AI-powered pothole reporting — SIH 2026 MB-04",
    version="1.0.0",
)


 
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for your handoff/demo
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



# Serve uploaded photos as static files at /uploads/<filename>
app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")

app.include_router(router, )

@app.get("/health")
def health():
    return {"status": "ok", "service": "RoadWatch API"}
