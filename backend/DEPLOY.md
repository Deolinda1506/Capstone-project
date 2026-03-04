# Deploy CarotidCheck API

Yes, you can deploy the backend. Follow this checklist.

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
