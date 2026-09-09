import importlib

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Numbered folders can't be imported directly in Python (names start with digit).
# We load them via importlib so the numbered folder structure stays intact
# for human readability in the file explorer.
_cfg = importlib.import_module("app.config.settings")
settings = _cfg.settings

engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """FastAPI dependency — yields a DB session and closes it after the request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()