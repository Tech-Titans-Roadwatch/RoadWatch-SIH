"""
Utility to import from numbered subfolders (e.g. app/config/settings.py).
Python identifiers cannot start with digits, so we use importlib.
Usage:
    from app._importer import load
    settings = load("app.config.settings", "settings")
"""
import importlib


def load(module_path: str, attr: str):
    mod = importlib.import_module(module_path)
    return getattr(mod, attr)
