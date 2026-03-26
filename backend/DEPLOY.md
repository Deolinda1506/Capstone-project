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

- **Build**: `pip install -r backend/requirements.txt` (includes TensorFlow for Attention U-Net)
- **Start**: `sh -c 'exec uvicorn backend.main:app --host 0.0.0.0 --port "${PORT}"'`
- **Env vars**: `DATABASE_URL` (from Postgres), `SECRET_KEY` (auto-generated), `DISABLE_AUTH=0`

### Render troubleshooting

**Port scan timeout / “no open ports detected”**

- The service must listen on Render’s **`PORT`** (set automatically). The Blueprint uses `sh -c` so `"${PORT}"` is always expanded.
- TensorFlow startup can be slow; the app **skips ML preload when `RENDER=true`** so `/health` comes up quickly. The model loads on the first scan or `/ml-status`. To warm the model at boot (after deploy works), set **`SKIP_ML_PRELOAD=0`** in the service environment.

**`Could not preload ML model` / BatchNormalization “expected 4 variables, received 0”**

- Use the **pinned TensorFlow range** in `backend/requirements.txt` (below 2.20). TF **2.21+** often fails to load this `.keras` graph with custom layers on Linux.
- Custom layers (`EncoderBlock`, `DecoderBlock`) implement `build()` so nested BN/Conv weights load under **Keras 3**.

### ML model (optional)

The Blueprint uses `requirements-api.txt` (no TensorFlow) so it fits Render’s free tier. Auth, patients, and scans work; `/predict` and AI overlay return stub results.

To enable full ML on a paid plan:

1. In Render Dashboard → your service → **Settings** → change **Build Command** to: `pip install -r backend/requirements.txt`.
2. Add the model file `ML/AttentionUNet.keras` to your repo (or fetch it at build time). Allocate at least 2GB RAM for the service.

### Render free tier: slow first request (cold start)

Render free tier services **spin down after ~15 min of inactivity**. The first request can take **1–2 minutes** to wake up. To reduce this:

1. **Keep-alive ping** — Use [UptimeRobot](https://uptimerobot.com) (free) to ping `https://your-api.onrender.com/health` every 5–10 minutes.
2. **Render Cron Job** — Add a cron job that hits `/health` every 10 min.
3. **Upgrade** — Paid plans don't spin down.

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
- Optional: **AFRICAS_TALKING_USERNAME**, **AFRICAS_TALKING_API_KEY**, **AFRICAS_TALKING_CLINICIAN_PHONES** (for SMS alerts when high-risk and CHW ID delivery)
  - **Sandbox (free):** Use `AFRICAS_TALKING_USERNAME=sandbox` and your sandbox API key from [Africa's Talking](https://account.africastalking.com/). Messages are simulated and not delivered to real phones. Copy `.env.example` to `.env` and fill in the sandbox values.
- Optional: **APPROVAL_CODES** — district approval codes to restrict registration (format: `0102:gasabo2024,0101:nyarugenge2024`). Only CHWs with the correct code from their supervisor can register for that district.

## 2. ML model

Ensure `ML/AttentionUNet.keras` is present in the deployed environment so `/scans/upload` and AI overlay work. If missing, the server starts but the first scan upload will fail. When using Docker, the Dockerfile copies the `ML/` folder.

**Database migrations:** If upgrading an existing deployment, add columns to `results` (PostgreSQL): `stenosis_pct REAL`, `stenosis_source VARCHAR(32)`. SQLite (dev) auto-adds these on startup.

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

## 5. Database schema (phone column)

If you have an existing database, add the `phone` column for CHW registration and duplicate prevention:

```sql
-- PostgreSQL
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
CREATE INDEX ix_users_phone ON users(phone);

-- If column already exists, you may see an error; that's fine.
```

## 6. CORS

The API currently allows all origins (`allow_origins=["*"]`). For production you may want to restrict this to your app’s domain(s) in `backend/main.py`.
