# CarotidCheck

AI-powered carotid ultrasound screening for stroke risk assessment in Rwanda. Community health workers capture scans, get instant IMT (intima-media thickness) and risk levels, and refer high-risk patients to hospitals.

**Live API:** [https://carotidcheck-api.onrender.com](https://carotidcheck-api.onrender.com) · [API docs](https://carotidcheck-api.onrender.com/docs) · [Health](https://carotidcheck-api.onrender.com/health) · [Latency stats](https://carotidcheck-api.onrender.com/latency) · **Web dashboard (Render static site):** after blueprint deploy, typically [https://carotidcheck-dashboard.onrender.com/dashboard](https://carotidcheck-dashboard.onrender.com/dashboard) (see `render.yaml`) · **Android APK (Google Drive):** [app-release.apk](https://drive.google.com/file/d/1ZEFX7sM3_fsFJEZmSHGprKq9zI0tH5wm/view?usp=sharing) · **Demo video:** [5-min demo](https://drive.google.com/file/d/1cF0XLiqFo-9NMABwXhOqR2R74O_6UWwN/view?usp=sharing) · **UI (Figma):** [CarotidCheck design file](https://www.figma.com/design/2RBiCJEMMr291thKV9nfnI/CarotidCheck?node-id=0-1)

**Course submission — source repository:** [https://github.com/Deolinda1506/Capstone-project](https://github.com/Deolinda1506/Capstone-project) · **Clone URL:** `https://github.com/Deolinda1506/Capstone-project.git` (branch `main`).

---

## Contents

| Section | What it is for |
|---------|----------------|
| **[Installation and dependencies](#installation-and-dependencies)** | What to install on your machine before running anything |
| **[Reviewer and moderator guide](#reviewer-and-moderator-guide)** | Shortest path to clone, run API, and verify |
| **[Quick Start](#quick-start)** | Full step-by-step (backend, Flutter, dashboard, tests) |
| **[Project structure](#project-structure)** | Folders and main files |
| **[API overview](#api-inputoutput-mapping)** | Main REST endpoints (full detail in Swagger `/docs`) |
| **[Requirements and testing](#requirements-and-testing-summary)** | Tests and where to read evaluation details (comparison table, ML notebook) |
| **[Comparative results](#comparative-results-attention-u-net-vs-vision-transformer)** | ViT vs Attention U-Net (validation metrics) |
| **[Configuration](#configuration)** | Environment variables (`backend/.env`) |
| **[Deployment](#deployment)** | Render / APK / Flutter web |

---

## Installation and dependencies

Install tools **once** per machine, then use the **virtual environment** for Python so project packages do not conflict with system Python.

### 1. System tools (install in this order)

| Tool | Minimum / recommended | Role | Where to get it |
|------|------------------------|------|-----------------|
| **Git** | 2.x | Clone the repo | [git-scm.com](https://git-scm.com) |
| **Python** | **3.10, 3.11, or 3.12** | Backend API, tests, ML | [python.org](https://www.python.org/downloads/) or `pyenv` (this repo’s `.python-version` pins **3.11.11** for consistency with production) |
| **pip** | Bundled with Python | Installs Python packages | — |
| **Node.js** | **18.x or 20.x LTS** | Clinician web dashboard (`web-dashboard/`) | [nodejs.org](https://nodejs.org) |
| **npm** | Comes with Node | Installs JS dependencies | — |
| **Flutter** | **3.x**, Dart **3.10+** | Mobile/web CHW app (`app/`) | [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) — run `flutter doctor` and fix any reported issues |

**Optional:** **Docker** is not required; the project runs natively with `uvicorn` and local SQLite/Postgres.

### 2. Python: two dependency bundles (pick one)

All commands below assume you are in the **repository root** (`Capstone-project/`) and use a **venv**.

```bash
# Create venv (use python3.11 or python3.12 if available)
python3 -m venv venv

# macOS / Linux
source venv/bin/activate

# Windows (Command Prompt / PowerShell)
# venv\Scripts\activate
```

| File | Command | Approx. install size | When to use |
|------|---------|----------------------|-------------|
| [`backend/requirements.txt`](backend/requirements.txt) | `pip install -r backend/requirements.txt` | **~2–3 GB** (TensorFlow, OpenCV, etc.) | **Full CarotidCheck:** real Attention U-Net inference, IMT, green overlay on `/scans/upload`. Requires [`ML/AttentionUNet.keras`](ML/AttentionUNet.keras) at runtime. |
| [`backend/requirements-api.txt`](backend/requirements-api.txt) | `pip install -r backend/requirements-api.txt` | **~50 MB** | **API + DB + auth** only; inference may use **stub/demo** behaviour without TensorFlow. Good for reviewers with limited disk or quick API smoke tests. |

**Tests:** `requirements.txt` includes **pytest** and **httpx**. If you only installed `requirements-api.txt`, run `pip install pytest httpx` before `pytest`.

### 3. Flutter app dependencies

From repo root:

```bash
cd app
flutter pub get
```

This installs everything declared in [`app/pubspec.yaml`](app/pubspec.yaml). No extra global tools beyond the Flutter SDK.

### 4. Web dashboard dependencies

```bash
cd web-dashboard
npm ci
```

Use **`npm ci`** for a clean, reproducible install from the lockfile; **`npm install`** also works if you prefer.

### 5. ML model file (real AI overlay)

- **Path:** `ML/AttentionUNet.keras`  
- **Purpose:** Loaded by `backend/inference.py` for segmentation and IMT.  
- **Size:** Large (may be tracked with **Git LFS** or added locally—see repo notes). If missing, `/ml-status` reports the model as unavailable and behaviour falls back per `backend/main.py` / inference stubs.

### 6. Environment file (backend)

- Copy [`backend/.env.example`](backend/.env.example) to `backend/.env` and adjust **SECRET_KEY**, **DATABASE_URL**, and optional **SMTP_*** for your environment.  
- Never commit `.env` (secrets).

### 7. End-to-end “everything installed” checklist

| Step | Command / check |
|------|------------------|
| 1 | `git clone https://github.com/Deolinda1506/Capstone-project.git` && `cd Capstone-project` |
| 2 | Create venv, `pip install -r backend/requirements.txt` **or** `requirements-api.txt` |
| 3 | `cp backend/.env.example backend/.env` (optional for local dev) |
| 4 | `uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000` → open `/docs` |
| 5 | `cd app && flutter pub get` → `flutter run` with correct `API_BASE_URL` |
| 6 | `cd web-dashboard && npm ci && npm run dev` → open Vite dev server |
| 7 | `PYTHONPATH=. python3 -m pytest tests/ -v -m "not ml"` (from repo root, venv active) |

For a **minimal** moderator path (API + health check only), follow **[Reviewer and moderator guide](#reviewer-and-moderator-guide)** below.

---

## Reviewer and moderator guide

Use this section to **review and run** the project without reading the whole README. Estimated time: **~10 minutes** for API-only smoke checks; **~30–45 minutes** for backend + Flutter + dashboard + tests (depending on downloads).

### What this repository contains

| Layer | Path | Purpose |
|--------|------|---------|
| Mobile client | [`app/`](app/) | Flutter (CHW flows: login, patients, scan upload, results, referrals) |
| REST API | [`backend/`](backend/) | FastAPI, JWT auth, PostgreSQL/SQLite, inference |
| ML assets | [`ML/`](ML/) | `AttentionUNet.keras` (deployed model), notebooks, training helpers |
| Clinician UI | [`web-dashboard/`](web-dashboard/) | React + Vite (referrals, analyses) |
| Docs | [`docs/system-architecture.md`](docs/system-architecture.md) | Architecture overview |

### Prerequisites (install before clone)

| Tool | Version | Notes |
|------|---------|--------|
| **Git** | any | Required |
| **Python** | **3.10–3.12** recommended | Match [`render.yaml`](render.yaml) / production; 3.9 may skip some API tests |
| **Node.js** | **18+** | For `web-dashboard` (`npm ci`) |
| **Flutter** | **3.x**, Dart **3.10+** | For `app/`; optional if you only verify the API |
| **TensorFlow** | via `pip` | Only if using `backend/requirements.txt` (full ML); large download |

### Step A — Clone and open the repo

```bash
git clone https://github.com/Deolinda1506/Capstone-project.git
cd Capstone-project
```

### Step B — Backend (choose one)

**B1 — Fastest review (API + stub inference, small install)**

```bash
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r backend/requirements-api.txt
cp backend/.env.example backend/.env   # optional; edit SECRET_KEY for anything beyond local smoke tests
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

- Open **http://127.0.0.1:8000/docs** — interactive API.
- **http://127.0.0.1:8000/health** → `{"status":"ok"}`.
- **http://127.0.0.1:8000/ml-status** — shows whether a real model is loaded (without `ML/AttentionUNet.keras`, overlay may be unavailable).

**B2 — Full stack matching production (real segmentation overlay)**

```bash
pip install -r backend/requirements.txt
# Ensure ML/AttentionUNet.keras is present (large file; may use Git LFS — see .gitattributes / project notes)
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

Re-check **`/ml-status`**: `ml_ready` / `overlay_available` should reflect a loaded model.

### Step C — Automated tests (from repo root)

`backend/requirements.txt` includes **pytest** and **httpx**. If you only installed `requirements-api.txt`, add test tools first:

```bash
pip install pytest httpx
```

Then:

```bash
source venv/bin/activate
PYTHONPATH=. python3 -m pytest tests/ -v -m "not ml"
```

- **Fast suite** (no full TensorFlow graph load): `-m "not ml"`.
- **Full ML smoke** (requires `ML/AttentionUNet.keras`, slow on CPU):  
  `PYTHONPATH=. python3 -m pytest tests/ -v -m ml`

### Step D — Flutter app (optional)

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Use **`http://10.0.2.2:8000`** as `API_BASE_URL` when the backend runs on the host and the app runs on an **Android emulator**. For a quick review without a device, **Swagger** (`/docs`) plus the **web dashboard** (Step E) is enough.

### Step E — Clinician web dashboard (optional)

```bash
cd web-dashboard
npm ci
# Optional: echo 'VITE_API_URL=http://localhost:8000' > .env
npm run dev
```

Open **http://localhost:5173** — login with a **staff** account created via your environment (see backend seeding / registration flow in [`backend/README.md`](backend/README.md) if present, or register through the API).

### Step F — How to know it “worked”

| Check | URL / command | Success |
|--------|----------------|--------|
| API up | `GET /health` | `status: ok` |
| Docs | `/docs` | Swagger UI loads |
| ML | `GET /ml-status` | JSON explains model/overlay readiness |
| Tests | `pytest tests/ -m "not ml"` | Exit code 0 |
| Latency stats | `GET /latency` | JSON with counts (after some inference calls) |

### Common issues

| Symptom | Likely cause | What to do |
|---------|----------------|------------|
| `ModuleNotFoundError` | Wrong venv / skipped `pip install` | Activate `venv` and install the chosen `requirements*.txt` |
| Port 8000 in use | Another process | Use `--port 8001` and set `API_BASE_URL` / `VITE_API_URL` accordingly |
| Flutter `ERR_CONNECTION_REFUSED` | Backend not running or wrong URL | Start `uvicorn`; use `--dart-define=API_BASE_URL=...` matching your host |
| No overlay / Unknown risk on real scans | Model missing, QC failed, or view not long-axis | Confirm `ML/AttentionUNet.keras`; see `backend/inference.py` plausibility checks |
| `pytest` skips on Python 3.9 | Version guard | Use **Python 3.10+** for the full app test import path |

### Deeper documentation

- **Architecture:** [`docs/system-architecture.md`](docs/system-architecture.md)  
- **Backend env vars:** [`backend/.env.example`](backend/.env.example)  
- **Deployment:** [`render.yaml`](render.yaml) and the **Deployment** section below  

---

## Quick Start

### Prerequisites

- **Python 3.12** (3.13 not supported by PyTorch)
- **Flutter 3.x** with Dart 3.10+
- **Git**

### Step 1: Clone the Repository

```bash
git clone https://github.com/Deolinda1506/Capstone-project.git
cd Capstone-project
```

### Step 2: Backend Setup

```bash
# Create and activate virtual environment
python3.12 -m venv venv
source venv/bin/activate   # On Windows: venv\Scripts\activate

# Install dependencies — choose ONE:
```

**Option A: Full ML stack** (`backend/requirements.txt`) — ~2–3 GB  
- TensorFlow, OpenCV for real AI inference  
- Real IMT, risk level, segmentation overlay  
- Requires model at `ML/AttentionUNet.keras`

```bash
pip install -r backend/requirements.txt
```

**Option B: API only** (`backend/requirements-api.txt`) — ~50 MB  
- Auth, patients, scans work  
- Demo/stub results (no real AI overlay)  
- Use when disk space is low or for quick testing

```bash
pip install -r backend/requirements-api.txt
```

### Step 3: Run the Backend

```bash
# From project root (folder containing app/ and backend/)
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

- **API docs:** http://localhost:8000/docs  
- **Health:** http://localhost:8000/health  
- **ML status:** http://localhost:8000/ml-status  

**Backend unit tests (pytest):** from the repo root, with `pip install -r backend/requirements.txt` (includes `pytest` and `httpx` for `TestClient`):

```bash
PYTHONPATH=. python3 -m pytest tests/ -v
```

- **`tests/test_inference.py`** and **`tests/test_latency_unit.py`** run on **Python 3.9+** (mocked model, no checkpoint).
- **`tests/test_ml_model_integration.py`** (**`-m ml`**) loads **`ML/AttentionUNet.keras`** and runs TensorFlow. **Skipped** if the file is missing. Can take **tens of seconds** on CPU.
  - Default fast run (exclude ML): `PYTHONPATH=. python3 -m pytest tests/ -m "not ml"`
  - Full ML smoke: `PYTHONPATH=. python3 -m pytest tests/ -m ml`
- **`tests/test_api_health.py`** (imports the full FastAPI app) requires **Python 3.10+** (same family as production / Render `PYTHON_VERSION` 3.11). On 3.9 it is **skipped** automatically.

**Clinician web-dashboard (Vitest + Testing Library):** from `web-dashboard/`:

```bash
cd web-dashboard && npm ci && npm test
```

**Clinician web-dashboard E2E (Playwright, real API):** builds a preview bundle (default API base matches production when `VITE_API_URL` is unset), starts `vite preview`, and logs in with a **real** staff account. Set `E2E_IDENTIFIER` and `E2E_PASSWORD` (and optionally `E2E_API_URL` for a different backend). Do not commit credentials; use CI secrets. First run: `cd web-dashboard && npx playwright install chromium`.

```bash
cd web-dashboard && npm ci && E2E_IDENTIFIER='…' E2E_PASSWORD='…' npm run test:e2e
```

**Flutter tests:** from `app/`:

```bash
cd app && flutter test
# optional integration_test (needs a device target, e.g. macOS desktop — not web):
cd app && flutter test -d macos integration_test/smoke_test.dart
```

**Flutter E2E (real API):** `integration_test/login_real_api_test.dart` clears local prefs/secure storage, marks onboarding complete, logs in, and asserts the role dashboard is shown. **Skipped** unless you pass staff credentials via `--dart-define` (same API as `API_BASE_URL` / default deploy). Do not commit secrets.

```bash
cd app && flutter test -d macos integration_test/login_real_api_test.dart \
  --dart-define=E2E_IDENTIFIER='…' \
  --dart-define=E2E_PASSWORD='…'
# optional: --dart-define=API_BASE_URL=https://carotidcheck-api.onrender.com
```

**macOS Keychain / unsigned desktop builds:** Flutter integration tests may need Keychain clearing or a signed app build; see Flutter secure-storage docs if `E2E_*` tests behave oddly.

**Key endpoints (Swagger):**
- [Create patient](http://localhost:8000/docs#/patients/create_patient_patients_post) — `POST /patients`
- [Upload scan & predict](http://localhost:8000/docs#/scans/upload_scan_image_with_prediction) — `POST /scans/upload` (patient_id + file)  

### Step 4: Run the Flutter App

```bash
cd app
flutter pub get
flutter run -d chrome    # Web
# or
flutter run              # Default device (iOS/Android)
```

**Android emulator:** Backend is at `10.0.2.2:8000`:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**Production API URL:**
```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://carotidcheck-api.onrender.com
flutter run --dart-define=API_BASE_URL=https://carotidcheck-api.onrender.com
```

**`ERR_CONNECTION_REFUSED` on `:8000/auth/...`:** The app defaults to `http://localhost:8000`. Nothing is listening there unless you started the API (`uvicorn`) on the same machine. For Flutter **web**, use the command above with your deployed API, or run the backend locally first. Messages like `DDC is about to load … scripts` are normal debug output, not failures.

### Step 5: Run the Hospital Dashboard (Web)

Clinician-facing web dashboard for high-risk referrals:

```bash
cd web-dashboard
npm install
npm run dev
```

Open http://localhost:5173. Login with Staff ID (e.g. `0102-001`) and password. Set `VITE_API_URL` in `.env` if the API is not at `http://localhost:8000`.

### Notifications

- **In-app (web dashboard):** Pending high-risk referrals surface in the header (**bell**, **badge**, optional **banner**) by polling the API (`PendingReferralsContext`). Optional **browser** notifications if enabled in Settings.
- **Email (SMTP):** Referral and CHW ID messages when `SMTP_*` is configured. See `backend/.env.example` and `backend/email_service.py`.

---

## Project Structure

```
Capstone-project/   # repository root
├── app/                    # Flutter frontend
│   ├── lib/
│   │   ├── core/           # Config, models, router, services, theme
│   │   └── screens/        # Login, dashboard, scan, result, referral, etc.
│   ├── assets/             # Logo, images
│   └── pubspec.yaml
├── backend/                # FastAPI backend
│   ├── main.py             # App entry, /health, /ml-status
│   ├── inference.py        # Attention U-Net inference, overlay generation
│   ├── routers/            # auth, patients, scans
│   ├── models/             # User, Patient, Scan, Result, Hospital
│   ├── requirements.txt    # Full ML stack (TensorFlow, OpenCV)
│   └── requirements-api.txt # API only, no ML (~50 MB)
├── ML/                     # Models and training
│   ├── AttentionUNet.keras # Best model from ViT vs U-Net comparison
│   ├── notebooks/          # Carotid_Artery_Segmentation_Models_Comparison.ipynb
│   └── carotid/            # Training scripts
├── web-dashboard/          # React + Vite web dashboard (clinicians)
├── data/                   # SQLite DB (created on first run)
├── uploads/                # Stored scan images (overlay) for clinician review
└── README.md
```

**Layered architecture (clients → API → data & AI → deployment):** see [docs/system-architecture.md](docs/system-architecture.md).

---

## API Input/Output Mapping

| Endpoint | Method | Input | Output |
|----------|--------|-------|--------|
| `/auth/login` | POST | `identifier`, `password` | `access_token`, `user` (id, role, staff_id, display_name) |
| `/auth/register` | POST | `password`, `district_id`, `display_name`, `phone`, `email`, `approval_code` | `access_token`, `user` |
| `/auth/forgot-password` | POST | `email` | `{ "message": "..." }` |
| `/auth/reset-password` | POST | `token`, `new_password` | `{ "message": "..." }` |
| `/patients` | POST | `identifier`, `email`, `facility` | `Patient` (id, identifier, user_id, created_at) |
| `/patients` | GET | `limit` (query) | `[Patient]` |
| `/scans/upload` | POST | `patient_id` (form), `file` (image) | `scan`, `result` (imt_mm, risk_level, is_high_risk), `segmentation_overlay_base64`, `plaque_detected`, `stenosis_pct`, `inference_time_sec` |
| `/scans/risk-distribution` | GET | — | `{ total, by_risk_level: { Low, Moderate, High }, scope }` — counts from stored analyses (CHW: own patients only; clinician/admin: all) |
| `/scans/with-results` | GET | `limit` (query) | `[{ scan_id, patient_id, patient_identifier, created_at, imt_mm, risk_level, is_high_risk, plaque_detected, has_image }]` |
| `/scans/high-risk` | GET | `limit` (query) | `[{ scan_id, patient_id, patient_identifier, created_at, imt_mm, risk_level, is_high_risk, plaque_detected, has_image }]` |
| `/scans/{scan_id}/image` | GET | — | PNG image (binary) |
| `/health` | GET | — | `{ "status": "ok" }` |
| `/ml-status` | GET | — | `{ "ml_ready", "overlay_available", "error" }` |
| `/latency` | GET | — | `{ "count", "mean_sec", "min_sec", "max_sec", "samples_sec" }` (last ≤100 inference times, oldest first) |

**Auth:** All protected endpoints except `/auth/*`, `/health` require `Authorization: Bearer <token>`.

**Use cases and FR traceability:** See [`docs/system-architecture.md`](docs/system-architecture.md).

---

## Requirements and testing summary

| Topic | Where to look |
|-------|----------------|
| Automated tests | `tests/` — run `PYTHONPATH=. python3 -m pytest tests/ -v -m "not ml"` (fast; add `-m ml` if `ML/AttentionUNet.keras` is present). |
| Segmentation metrics (Dice, IoU) | [Comparative results](#comparative-results-attention-u-net-vs-vision-transformer) table below and [`ML/notebooks/Carotid_Artery_Segmentation_Models_Comparison.ipynb`](ML/notebooks/Carotid_Artery_Segmentation_Models_Comparison.ipynb) |
| Latency | [`GET /latency`](https://carotidcheck-api.onrender.com/latency) when the API is deployed; a design target of &lt; 5 s per scan may be exceeded on free-tier CPU. |

---

## Comparative results: Attention U-Net vs Vision Transformer

Validation-style metrics from the model comparison (training pipeline / Momot dataset; details in `ML/notebooks/Carotid_Artery_Segmentation_Models_Comparison.ipynb`). **Attention U-Net** is deployed in `backend/inference.py` because it leads on **Dice**, **Jaccard / IoU**, and **loss**.

| Model | Loss | Accuracy | Dice coefficient | Jaccard index | Mean IoU |
|-------|------|----------|------------------|---------------|----------|
| **Attention U-Net** | 0.0409 | 0.9977 | 0.9461 | 0.9001 | 0.9489 |
| **Vision Transformer** | 0.0937 | 0.9934 | 0.8406 | 0.7441 | 0.8687 |
| **Absolute difference** (U-Net − ViT) | 0.0528 | 0.0043 | 0.1055 | 0.1559 | 0.0801 |

*Accuracy* here is **pixel-level** classification accuracy on the segmentation task (foreground/background labels), not clinical diagnostic accuracy.

---

## Configuration

### Backend

- **DATABASE_URL** — Default: `sqlite:///data/carotidcheck.db`. For prod: PostgreSQL.
- **SECRET_KEY** — JWT signing. Default dev key; set in prod: `openssl rand -hex 32`
- **DISABLE_AUTH** — Set `1` for local testing without login

### Frontend

- **API_BASE_URL** — Default: `http://localhost:8000`. Override via `--dart-define=API_BASE_URL=...`

---

## Deployment

### Backend (Render)

1. Set env vars: `SECRET_KEY`, `DATABASE_URL` (PostgreSQL)
2. Start: `uvicorn backend.main:app --host 0.0.0.0 --port $PORT`
3. Ensure `ML/AttentionUNet.keras` is available for real AI overlay

### Flutter Web

```bash
cd app
flutter build web
# Deploy the build/web/ folder to Firebase Hosting, Vercel, Netlify, etc.
```

### Android APK

**Pre-built release (download):** [Google Drive — app-release.apk](https://drive.google.com/file/d/1ZEFX7sM3_fsFJEZmSHGprKq9zI0tH5wm/view?usp=sharing) *(install on Android; allow installs from Drive / your browser if prompted).*

**Build locally:**
```bash
cd app
flutter build apk --release --dart-define=API_BASE_URL=https://carotidcheck-api.onrender.com
# Output: app/build/app/outputs/flutter-apk/app-release.apk
```

**Install on Android device:**
1. Transfer `app-release.apk` to your phone (USB, email, [Google Drive link above](https://drive.google.com/file/d/1ZEFX7sM3_fsFJEZmSHGprKq9zI0tH5wm/view?usp=sharing), or download from a release).
2. On your Android device: **Settings → Security** → enable **Install from unknown sources** (or **Install unknown apps** for the file manager/browser you use).
3. Open the APK file and tap **Install**.
4. The APK built with the command above has the deployed API URL (`https://carotidcheck-api.onrender.com`) compiled in via `--dart-define`.

---

## Demo Video

A 5-minute demo video should cover:

1. **Onboarding** (brief)
2. **Patient creation** — New patient, identifier
3. **Scan capture** — Camera/gallery, upload
4. **Analysis result** — IMT, risk level, overlay (if available)
5. **Referrals** — Add to referral list, view hospitals
6. **Hospital dashboard** — High-risk cases, analyses
7. **Settings** — Language, analyses, patients

---

## Tech Stack

- **Frontend:** Flutter, go_router, Provider, image_picker, flutter_map
- **Backend:** FastAPI, SQLAlchemy, Pydantic v2, JWT
- **ML:** TensorFlow (Attention U-Net), OpenCV
- **UI design:** [Figma — CarotidCheck](https://www.figma.com/design/2RBiCJEMMr291thKV9nfnI/CarotidCheck?node-id=0-1)

---


