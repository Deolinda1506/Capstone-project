"""FastAPI app: SQLAlchemy · Pydantic v2 · JWT · Attention U-Net. SQLite (dev) / PostgreSQL (prod)."""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

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
    try:
        with engine.connect() as conn:
            r = conn.execute(text("PRAGMA table_info(scans)"))
            scan_cols = {row[1] for row in r}
        if "clinician_review_status" not in scan_cols:
            with engine.begin() as conn:
                conn.execute(
                    text(
                        "ALTER TABLE scans ADD COLUMN clinician_review_status VARCHAR(20) DEFAULT 'pending'"
                    )
                )
        if "clinician_reviewed_at" not in scan_cols:
            with engine.begin() as conn:
                conn.execute(text("ALTER TABLE scans ADD COLUMN clinician_reviewed_at DATETIME"))
        if "clinician_reviewed_by_id" not in scan_cols:
            with engine.begin() as conn:
                conn.execute(text("ALTER TABLE scans ADD COLUMN clinician_reviewed_by_id VARCHAR(36)"))
        if "clinical_notes" not in scan_cols:
            with engine.begin() as conn:
                conn.execute(text("ALTER TABLE scans ADD COLUMN clinical_notes TEXT"))
    except Exception:
        pass


def _ensure_postgres_schema():
    """
    Add missing columns on PostgreSQL (e.g. Render) when the DB predates model changes.
    Each ALTER runs in its own transaction so one failure does not roll back the rest
    (a single failed DDL in a batch would previously undo all earlier ADD COLUMNs).
    """
    import logging
    from sqlalchemy import text
    from backend.database import engine

    log = logging.getLogger(__name__)
    if "postgresql" not in str(engine.url).lower():
        return

    _pg_tables = frozenset({"users", "hospitals", "patients", "scans", "results"})

    def _table_exists(table: str) -> bool:
        if table not in _pg_tables:
            return False
        with engine.connect() as conn:
            r = conn.execute(
                text(
                    "SELECT EXISTS (SELECT FROM information_schema.tables "
                    "WHERE table_schema = 'public' AND table_name = '"
                    + table
                    + "')"
                )
            )
            return bool(r.scalar())

    def _column_names(table: str) -> set:
        if table not in _pg_tables:
            return set()
        with engine.connect() as conn:
            r = conn.execute(
                text(
                    "SELECT column_name FROM information_schema.columns "
                    "WHERE table_schema = 'public' AND table_name = '"
                    + table
                    + "'"
                )
            )
            return {row[0] for row in r}

    def _ddl(sql: str) -> None:
        try:
            with engine.begin() as conn:
                conn.execute(text(sql))
        except Exception:
            log.warning("Postgres DDL failed (non-fatal): %s", sql[:160], exc_info=True)

    try:
        # Users first so /auth/login and /auth/forgot-password work even if later DDL fails.
        if _table_exists("users"):
            ucols = _column_names("users")
            for col, ddl in (
                ("firebase_uid", "VARCHAR(128)"),
                ("password_hash", "VARCHAR(255)"),
                ("display_name", "VARCHAR(255)"),
                ("role", "VARCHAR(50) DEFAULT 'chw'"),
                ("staff_id", "VARCHAR(128)"),
                ("phone", "VARCHAR(20)"),
                ("facility", "VARCHAR(255)"),
                ("hospital_id", "VARCHAR(36)"),
                ("status", "VARCHAR(20) DEFAULT 'approved'"),
                ("created_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
                ("updated_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
                ("deleted_at", "TIMESTAMP"),
                ("is_deleted", "BOOLEAN DEFAULT FALSE"),
                ("password_reset_token", "VARCHAR(255)"),
                ("password_reset_expires", "TIMESTAMP"),
            ):
                if col not in ucols:
                    _ddl(f"ALTER TABLE users ADD COLUMN IF NOT EXISTS {col} {ddl}")

        if _table_exists("hospitals"):
            hcols = _column_names("hospitals")
            for col, ddl in (
                ("address", "VARCHAR(512)"),
                ("province", "VARCHAR(128)"),
                ("district", "VARCHAR(128)"),
                ("sector", "VARCHAR(128)"),
                ("created_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
                ("updated_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
            ):
                if col not in hcols:
                    _ddl(f"ALTER TABLE hospitals ADD COLUMN IF NOT EXISTS {col} {ddl}")

        if _table_exists("patients"):
            pcols = _column_names("patients")
            for col, ddl in (
                ("name", "VARCHAR(255)"),
                ("age", "INTEGER"),
                ("email", "VARCHAR(255)"),
                ("deleted_at", "TIMESTAMP"),
                ("is_deleted", "BOOLEAN DEFAULT FALSE"),
                ("updated_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
            ):
                if col not in pcols:
                    _ddl(f"ALTER TABLE patients ADD COLUMN IF NOT EXISTS {col} {ddl}")

        if _table_exists("scans"):
            scols = _column_names("scans")
            for col, ddl in (
                ("deleted_at", "TIMESTAMP"),
                ("is_deleted", "BOOLEAN DEFAULT FALSE"),
                ("clinician_review_status", "VARCHAR(20) DEFAULT 'pending'"),
                ("clinician_reviewed_at", "TIMESTAMP"),
                ("clinician_reviewed_by_id", "VARCHAR(36)"),
                ("clinical_notes", "TEXT"),
            ):
                if col not in scols:
                    _ddl(f"ALTER TABLE scans ADD COLUMN IF NOT EXISTS {col} {ddl}")

        if _table_exists("results"):
            rcols = _column_names("results")
            for col, ddl in (
                ("stenosis_pct", "DOUBLE PRECISION"),
                ("stenosis_source", "VARCHAR(32)"),
            ):
                if col not in rcols:
                    _ddl(f"ALTER TABLE results ADD COLUMN IF NOT EXISTS {col} {ddl}")
    except Exception:
        log.exception("Postgres schema introspection failed (non-fatal)")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Create DB tables on startup (use Alembic in prod for migrations)."""
    Base.metadata.create_all(bind=engine)
    _ensure_postgres_schema()
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
    allow_origins=["*"],
    allow_credentials=False,
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


@app.get("/health/db")
def health_db():
    """DB connectivity + rough schema sanity (for ops; no secrets)."""
    from sqlalchemy import text

    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
            dialect = engine.dialect.name
            out = {"status": "ok", "dialect": dialect}
            if dialect == "postgresql":
                r = conn.execute(
                    text(
                        "SELECT COUNT(*) FROM information_schema.columns "
                        "WHERE table_schema = 'public' AND table_name = 'users'"
                    )
                )
                out["users_column_count"] = int(r.scalar() or 0)
                r2 = conn.execute(
                    text(
                        "SELECT EXISTS (SELECT FROM information_schema.tables "
                        "WHERE table_schema = 'public' AND table_name = 'users')"
                    )
                )
                out["users_table_exists"] = bool(r2.scalar())
            return out
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={"status": "error", "error": str(e)},
        )


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
