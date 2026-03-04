"""App config. SQLite (dev) by default; PostgreSQL (prod) via DATABASE_URL."""
import os
from pathlib import Path

from dotenv import load_dotenv

_root = Path(__file__).resolve().parent.parent
load_dotenv(_root / ".env")

# Local SQLite in data/ for dev
_data_dir = _root / "data"
_data_dir.mkdir(parents=True, exist_ok=True)
_default_sqlite = f"sqlite:///{_data_dir / 'carotidcheck.db'}"


def get_database_url() -> str:
    url = os.getenv("DATABASE_URL", _default_sqlite)
    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql://", 1)
    return url


# Auth: set DISABLE_AUTH=0 to require tokens. Default: no token required (dev mode).
DISABLE_AUTH = os.getenv("DISABLE_AUTH", "1").strip().lower() in ("1", "true", "yes")

# JWT (email/password login)
SECRET_KEY = os.getenv("SECRET_KEY", "change-me-in-production-use-openssl-rand")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", str(60 * 24)))  # 24 hours
