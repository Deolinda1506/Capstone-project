"""FastAPI app: SQLAlchemy · Pydantic v2 · JWT · Attention U-Net. SQLite (dev) / PostgreSQL (prod)."""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.database import engine, Base
import backend.models  # noqa: F401 — register models
from backend.routers import auth, patients, scans

def _ensure_sqlite_columns():
    """Add missing columns to existing SQLite tables (e.g. after model changes)."""
    from sqlalchemy import text
    from backend.database import engine
    url = str(engine.url)
    if "sqlite" not in url:
        return
    try:
        with engine.connect() as conn:
            r = conn.execute(text("PRAGMA table_info(users)"))
            cols = {row[1] for row in r}
        need_alter = any(c not in cols for c in ("password_reset_token", "password_reset_expires", "staff_id", "facility", "status", "hospital_id"))
        if need_alter:
            with engine.begin() as conn:
                if "password_reset_token" not in cols:
                    conn.execute(text("ALTER TABLE users ADD COLUMN password_reset_token VARCHAR(255)"))
                if "password_reset_expires" not in cols:
                    conn.execute(text("ALTER TABLE users ADD COLUMN password_reset_expires DATETIME"))
                if "staff_id" not in cols:
                    conn.execute(text("ALTER TABLE users ADD COLUMN staff_id VARCHAR(128)"))
                if "facility" not in cols:
                    conn.execute(text("ALTER TABLE users ADD COLUMN facility VARCHAR(255)"))
                if "status" not in cols:
                    conn.execute(text("ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'approved'"))
                if "hospital_id" not in cols:
                    conn.execute(text("ALTER TABLE users ADD COLUMN hospital_id VARCHAR(36)"))
    except Exception:
        pass
    try:
        with engine.connect() as conn:
            r = conn.execute(text("PRAGMA table_info(patients)"))
            pat_cols = {row[1] for row in r}
        if "name" not in pat_cols:
            with engine.begin() as conn:
                conn.execute(text("ALTER TABLE patients ADD COLUMN name VARCHAR(255)"))
        if "age" not in pat_cols:
            with engine.begin() as conn:
                conn.execute(text("ALTER TABLE patients ADD COLUMN age INTEGER"))
    except Exception:
        pass
    try:
        with engine.connect() as conn:
            r = conn.execute(text("PRAGMA table_info(results)"))
            res_cols = {row[1] for row in r}
        if "stenosis_pct" not in res_cols:
            with engine.begin() as conn:
                conn.execute(text("ALTER TABLE results ADD COLUMN stenosis_pct REAL"))
        if "stenosis_source" not in res_cols:
            with engine.begin() as conn:
                conn.execute(text("ALTER TABLE results ADD COLUMN stenosis_source VARCHAR(32)"))
    except Exception:
        pass


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Create DB tables on startup (use Alembic in prod for migrations)."""
    Base.metadata.create_all(bind=engine)
    _ensure_sqlite_columns()
    # Preload ML model so first /scans/upload is faster (avoids Swagger timeout)
    try:
        from backend.inference import load_model
        load_model()
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning("Could not preload ML model: %s. First scan may be slow.", e)
    yield
    # shutdown if needed


app = FastAPI(
    title="CarotidCheck API",
    description="Carotid ultrasound analysis for stroke triage. FastAPI · SQLAlchemy · Pydantic v2 · JWT.",
    version="1.0.0",
    lifespan=lifespan,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Includes localhost:* for Flutter web
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

app.include_router(auth.router)
app.include_router(patients.router)
app.include_router(scans.router)


@app.get("/")
def root():
    return {"message": "CarotidCheck API", "docs": "/docs"}


@app.get("/health")
def health():
    """Lightweight check that the server is up. Use this to verify connectivity."""
    return {"status": "ok"}


@app.get("/ml-status")
def ml_status():
    """Check if ML model is loaded (required for real AI overlay)."""
    try:
        from backend.inference import load_model
        load_model()
        return {"ml_ready": True, "overlay_available": True}
    except Exception as e:
        return {"ml_ready": False, "overlay_available": False, "error": str(e)}


@app.get("/latency")
def latency():
    """
    Latency statistics for inference (rolling window of last 100 requests).
    Used for real-time triage latency analysis.
    """
    from backend.latency import get_latency_stats
    return get_latency_stats()
