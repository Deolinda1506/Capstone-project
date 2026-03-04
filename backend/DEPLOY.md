# Deploy CarotidCheck API

Yes, you can deploy the backend. Follow this checklist.

---

## Render (recommended)

### One-click Blueprint

1. Push your repo to GitHub (e.g. `https://github.com/Deolinda1506/Capstone-project`).
2. Go to [Render Dashboard → Blueprints](https://dashboard.render.com/blueprints).
3. Click **New Blueprint Instance** and connect your GitHub repo.
4. Render will detect `render.yaml` and create:
   - A **PostgreSQL** database (free tier)
   - A **Web Service** for the API
5. After deploy, your API is live at `https://carotidcheck-api.onrender.com` (or similar).

### What the Blueprint does

- **Build**: `pip install -r backend/requirements-api.txt` (lightweight, ~50 MB)
- **Start**: `uvicorn backend.main:app --host 0.0.0.0 --port $PORT`
- **Env vars**: `DATABASE_URL` (from Postgres), `SECRET_KEY` (auto-generated), `DISABLE_AUTH=0`

### ML model (optional)

The Blueprint uses `requirements-api.txt` (no PyTorch/MONAI) so it fits Render’s free tier. Auth, patients, and scans work; `/predict` and AI overlay return stub results.

To enable full ML on a paid plan:

1. In Render Dashboard → your service → **Settings** → change **Build Command** to: `pip install -r backend/requirements.txt`.
2. Add the model file `ML/models/carotid_swin_unetr_2d.pt` to your repo (or fetch it at build time). Allocate at least 2GB RAM for the service.

### Flutter app

Build with your Render API URL:

```bash
cd app
flutter build web --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com
```

Or for mobile: `flutter build apk --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com`

---

## 1. Production environment variables

Set these on your host or platform:

- **SECRET_KEY** — required in prod. Generate: `openssl rand -hex 32`
- **DATABASE_URL** — use PostgreSQL in prod, e.g. `postgresql://user:pass@host:5432/carotidcheck`
- Optional: **SMTP_HOST**, **SMTP_PORT**, **SMTP_USER**, **SMTP_PASSWORD**, **EMAIL_FROM** (for welcome/referral emails)
- Optional: **AFRICAS_TALKING_*** (for SMS alerts when high-risk)

## 2. ML model

Ensure `ML/models/carotid_swin_unetr_2d.pt` (or `carotid_swin_unetr_2d_final/`) is present in the deployed environment so `/predict` works. If missing, the server starts but the first `/predict` call will fail. When using Docker, the Dockerfile copies the `ML/` folder.

## 3. Docker (from project root)

```bash
docker build -t carotidcheck-api .
docker run -p 8000:8000 \
  -e SECRET_KEY="your-secret-from-openssl-rand-hex-32" \
  -e DATABASE_URL="postgresql://user:pass@host:5432/dbname" \
  carotidcheck-api
```

## 4. Platforms

You can deploy the same image or run uvicorn directly on:

- **Railway / Render / Fly.io** — connect repo, set env vars, start: `uvicorn backend.main:app --host 0.0.0.0 --port $PORT`
- **AWS ECS, Google Cloud Run** — use the Dockerfile; allocate enough memory (e.g. 2GB) for the ML model
- **VPS** — clone repo, `pip install -r backend/requirements.txt`, run uvicorn with a process manager (systemd, supervisor)

## 5. CORS

The API currently allows all origins (`allow_origins=["*"]`). For production you may want to restrict this to your app’s domain(s) in `backend/main.py`.
