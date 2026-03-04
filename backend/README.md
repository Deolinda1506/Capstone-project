# CarotidCheck API

**Stack:** FastAPI · SQLAlchemy · Pydantic v2 · JWT  
**DB:** SQLite (dev) · PostgreSQL (prod via `DATABASE_URL`)

## Setup (first time): virtual environment + dependencies

The project uses **`.venv`** (see root README). From **project root**:

```bash
# Create virtual environment (from project root)
python3.12 -m venv .venv

# Activate it (macOS/Linux)
source .venv/bin/activate
# On Windows:
# .venv\Scripts\activate

# Install dependencies (can take a few minutes: torch, monai, etc.)
pip install -r backend/requirements.txt
```

If you already have `.venv` with dependencies installed, just activate it and run (see below).

## Run

**Important:** Run from the **project root** (the folder that contains `lib/` and `backend/`), so Python can find the `backend` module. With `.venv` activated:

```bash
cd "/path/to/CarotidCheck app"
source backend/.venv/bin/activate
# Or: .venv at project root
source .venv/bin/activate
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

If you run from another directory, set `PYTHONPATH` to the project root:

```bash
PYTHONPATH="/path/to/CarotidCheck app" uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

- Docs: http://localhost:8000/docs  
- **POST /auth/login** — JSON body: `{ "email", "password" }` → returns `access_token` and `user`.  
- **POST /patients** — body: `{ "identifier?" (e.g. CC-0001 from Flutter), "email?", "facility?" }`. Identifier is optional; auto-generated if omitted.  
- Use **Authorize** in Swagger with `Bearer <access_token>` for protected routes.

**If you have an existing SQLite DB**, add any missing columns, e.g.:  
`ALTER TABLE users ADD COLUMN staff_id VARCHAR(128);`  
`ALTER TABLE users ADD COLUMN facility VARCHAR(255);`  
For password reset:  
`ALTER TABLE users ADD COLUMN password_reset_token VARCHAR(255);`  
`ALTER TABLE users ADD COLUMN password_reset_expires DATETIME;`

## Env

- **DATABASE_URL** — optional. Default: `sqlite:///data/carotidcheck.db`. For prod: `postgresql://user:pass@host:5432/dbname`.  
- **SECRET_KEY** — optional. Default dev key; set in prod (e.g. `openssl rand -hex 32`).

Tables are created on app startup if they don’t exist.

## Deploy on Render

See **docs/DEPLOY_RENDER.md** (in project root) for one-click Blueprint (`render.yaml`) or manual steps. You need a PostgreSQL URL and the ML model at `ML/models/`.
