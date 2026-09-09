import os
from pydantic_settings import BaseSettings, SettingsConfigDict



class Settings(BaseSettings):
    # ── Database ─────────────────────────────────────────────────────────────
    database_url: str = "postgresql://postgres:password@localhost:5432/roadwatch"

    # ── File storage ─────────────────────────────────────────────────────────
    upload_dir: str = "./uploads"

    # ── YOLO ─────────────────────────────────────────────────────────────────
    # Default: yolov8n.pt (auto-downloads on first run, generic pretrained).
    # After Colab fine-tuning change this to: ./ml_weights/best.pt
    yolo_weights_path: str = "yolov8n.pt"
    yolo_confidence_threshold: float = 0.25

    # ── Firebase ─────────────────────────────────────────────────────────────
    firebase_service_account_json: str = "./firebase-service-account.json"

    # ── CORS ─────────────────────────────────────────────────────────────────
    allowed_origins: str = "http://localhost:8080,http://localhost:3000"

    # Pydantic v2 settings configuration
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",  # Prevents crashing if extra variables exist in .env
    )

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",") if o.strip()]


settings = Settings()
os.makedirs(settings.upload_dir, exist_ok=True)