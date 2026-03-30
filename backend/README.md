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

# Install dependencies (can take a few minutes: tensorflow, etc.)
pip install -r backend/requirements.txt
```

**If TensorFlow fails to install** (`No matching distribution found`):
- **Intel Mac (x86_64):** TensorFlow 2.17+ dropped macOS x86 builds. Use **Python 3.11** with `.venv311` (matches `requirements.txt`, which pins **TensorFlow 2.16.2** + `TF_USE_LEGACY_KERAS` for this checkpoint):
  ```bash
  python3.11 -m venv .venv311
  .venv311/bin/pip install -r backend/requirements.txt
  ```
- **Apple Silicon:** Use `pip install tensorflow` (2.13+ has native support).
- **Unit tests run without TensorFlow** — the model integration test skips when TensorFlow is unavailable.

**Intel Mac: use `.venv311` for real ML model.** On Intel Mac, TensorFlow can crash with "Floating point exception" unless MKL/OneDNN are disabled. The inference module sets `TF_DISABLE_MKL=1` and `TF_ENABLE_ONEDNN_OPTS=0` automatically, but for manual runs:
```bash
export TF_DISABLE_MKL=1 TF_ENABLE_ONEDNN_OPTS=0
```

If you already have `.venv` with dependencies installed, just activate it and run (see below).

## Run

**Important:** Run from the **project root** (the folder that contains `app/` and `backend/`), so Python can find the `backend` module.

- **Real ML model (Intel Mac):** Use `.venv311` (TensorFlow 2.16.2 + Python 3.11)
- **Other platforms:** Use `.venv` or `venv`

```bash
cd "/path/to/CarotidCheck app"
# Intel Mac: real Attention U-Net model
source .venv311/bin/activate
# Or: .venv / venv
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
