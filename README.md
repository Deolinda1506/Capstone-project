# CarotidCheck

AI-powered carotid ultrasound screening for stroke risk assessment in Rwanda. Community health workers capture scans, get instant IMT (intima-media thickness) and risk levels, and refer high-risk patients to hospitals.

**Live API:** [https://carotidcheck-api.onrender.com](https://carotidcheck-api.onrender.com) · [API docs](https://carotidcheck-api.onrender.com/docs) · [Health](https://carotidcheck-api.onrender.com/health) · [Latency stats](https://carotidcheck-api.onrender.com/latency) · **Web dashboard (Render static site):** after blueprint deploy, typically [https://carotidcheck-dashboard.onrender.com](https://carotidcheck-dashboard.onrender.com) (see `render.yaml`) · **Android APK (Google Drive):** [app-release.apk](https://drive.google.com/file/d/13zI5Jj2Ycf1280hRFSSBl9bhABMODMUz/view?usp=sharing) · **Demo video:** [5-min demo](https://drive.google.com/file/d/1cF0XLiqFo-9NMABwXhOqR2R74O_6UWwN/view?usp=sharing)

---

## Quick Start

### Prerequisites

- **Python 3.12** (3.13 not supported by PyTorch)
- **Flutter 3.x** with Dart 3.10+
- **Git**

### Step 1: Clone the Repository

```bash
git clone https://github.com/<your-org>/CarotidCheck.git
cd CarotidCheck
# or
cd "CarotidCheck app"
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

**Backend unit tests (pytest):** from the repo root, with dependencies installed (`pip install -r backend/requirements.txt` or API-only plus `pytest`):

```bash
python3 -m pytest tests/ -v
```

**Flutter tests:** from `app/`:

```bash
cd app && flutter test
# optional integration_test (needs a device target, e.g. macOS desktop — not web):
cd app && flutter test -d macos integration_test/smoke_test.dart
```

On macOS you may see `Failed to foreground app; open returned 1` while tests still **pass**—that only means the runner could not bring the window to the front; the run itself succeeded.

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

### Optional: SMS alerts (sandbox, free)

To test high-risk SMS alerts and CHW ID delivery:

1. Register at [Africa's Talking](https://account.africastalking.com/auth/register)
2. Go to **Sandbox** → **Settings** → **API Key** → Generate
3. Copy `.env.example` to `.env` and set:
   ```
   AFRICAS_TALKING_USERNAME=sandbox
   AFRICAS_TALKING_API_KEY=your_sandbox_api_key
   AFRICAS_TALKING_CLINICIAN_PHONES=+250791948534
   ```
4. Restart the backend. Messages are simulated (not delivered to real phones).

---

## Project Structure

```
CarotidCheck app/
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

---

## Use Case to Implementation Mapping

This section maps the functional requirements (use cases) from the system design to their implementation in code. It describes *how* each use case is implemented, not the results or validation.

| Use Case | FR | Implementation |
|----------|-----|----------------|
| **Register and log in** | FR1 | `POST /auth/register` → `backend/routers/auth.py`; `POST /auth/login` → JWT. Flutter: `app/lib/screens/login/login_screen.dart`, `register/register_screen.dart`. Offline login: cached credentials in `AuthService` (`app/lib/core/services/auth_service.dart`). |
| **Create and manage patients** | FR2 | `POST /patients` → `backend/routers/patients.py`; `GET /patients` for list. Flutter: `patient_capture_screen.dart`, `patients_screen.dart`. Patient identifier (e.g. CC-0001) or auto-generated PT-XXXXXXXX. |
| **Capture or upload carotid ultrasound** | FR3 | `POST /scans/upload` (multipart: `patient_id`, `file`). Flutter: `scan_screen.dart` → `image_picker` (camera/gallery) → `ApiClient.uploadScan()`. Image stored in `uploads/` for clinician review. |
| **Segment artery walls and return IMT, risk, stenosis** | FR4 | `backend/inference.py` → `predict_imt()`: pad → resize 256×256 → Attention U-Net → mask → IMT (mm). Risk: Low &lt;0.9 mm, Moderate 0.9–1.2 mm, High &gt;1.2 mm. NASCET stenosis in `inference.py`. |
| **Display AI segmentation overlay** | FR5 | `ScanUploadResponse.segmentation_overlay_base64` returned from `/scans/upload`; `ResultScreen` displays `Image.memory(base64Decode(...))`. Stored overlay: `GET /scans/{id}/image` for clinician dashboard. |
| **High-risk SMS and email** | FR6 | `backend/sms_alerts.py`, `email_service.py`; triggered in `scans.py` when `pred["is_high_risk"]`. Africa's Talking sandbox; clinician phones from `AFRICAS_TALKING_CLINICIAN_PHONES`. |
| **Clinician view high-risk referrals and past scan results** | FR7 | `GET /scans/high-risk` → `hospital_dashboard_screen.dart`; `GET /scans/with-results` → `analyses_screen.dart`. `GET /scans/{id}/image` fetches stored overlay for result view. `ReferralCard` → `ResultScreen` with image. |
| **Store scan and result for longitudinal tracking** | FR8 | `Scan` and `Result` models in `backend/models/`; `scans.py` stores scan + result in DB. Image stored in `uploads/{scan_id}.png`. `image_path` in DB; `has_image` in list responses. |

---

## Related Files

| File / Folder | Purpose |
|--------------|---------|
| `backend/main.py` | FastAPI app entry, `/health`, `/ml-status` |
| `backend/inference.py` | Attention U-Net inference, overlay generation |
| `backend/routers/` | Auth, patients, scans endpoints |
| `app/lib/screens/` | Flutter UI (login, dashboard, scan, result, referral, hospital dashboard) |
| `app/lib/core/` | Config, API client, services, theme |
| `ML/notebooks/Carotid_Artery_Segmentation_Models_Comparison.ipynb` | ViT vs Attention U-Net comparison, IMT, stroke risk |
| `ML/AttentionUNet.keras` | Trained Attention U-Net model (best from ViT vs U-Net comparison) |
| `render.yaml` | Render deployment blueprint |

---

## Core Functionality

| Feature | Description |
|---------|-------------|
| **Patient registration** | Create patients with identifier (e.g. CC-0001) |
| **Carotid scan upload** | Camera or gallery → upload to backend |
| **AI analysis** | IMT (mm), risk level (Low/Moderate/High), plaque detection |
| **Segmentation overlay** | Green overlay on scan (when ML model is loaded) |
| **Referrals** | High-risk patients → referral list, hospital map |
| **Hospital dashboard** | High-risk referrals, analyses, quick actions |
| **Role-based dashboards** | CHW, Clinician, Admin views |

---

## Analysis

**Figure 5.3 (thesis) from your database:** after scans exist in SQLite/Postgres, run  
`PYTHONPATH=. python3 scripts/render_figure_5_3_from_db.py`  
(requires `sqlalchemy`, `python-dotenv`; uses `DATABASE_URL` or `data/carotidcheck.db`). Refreshes `thesis/figures/figure-5.3-risk-distribution.svg` and `.png` (macOS `qlmanage`). See also `GET /scans/risk-distribution`.

**Mapping implementation (CarotidCheck/StrokeLink) to proposal objectives:**

### Objective 1: Literature review and technical baselines
- **Achieved:** Attention U-Net selected as best model (vs ViT) from comparison; Momot dataset used for training (see `ML/notebooks/Carotid_Artery_Segmentation_Models_Comparison.ipynb`); IMT thresholds defined (Low <0.9 mm, Moderate 0.9–1.2 mm, High >1.2 mm; NASCET-aligned); preprocessing with padding, resize, Albumentations.
- **How:** ViT and Attention U-Net were compared; Attention U-Net achieved higher Dice/IoU. The Momot dataset (1100 image–mask pairs) enabled training. IMT thresholds align with clinical guidelines for stroke risk stratification.
- **Status:** Met.

### Objective 2: Develop the cloud-integrated solution
- **Achieved:** Preprocessing pipeline (pad, resize, normalize); FastAPI backend with Attention U-Net; Flutter app for CHWs with patient registration, scan upload, risk stratification, referral list, hospital dashboard.
- **How:** CHWs upload scans via the app → backend preprocesses and runs Attention U-Net inference → IMT and risk level are returned → high-risk patients can be added to the referral list; clinicians see incoming referrals on the hospital dashboard. Cloud-synchronized data flows through the FastAPI backend.
- **Status:** Met.

### Objective 3: Verify and validate with measurable metrics
- **Achieved:** Technical metrics (IMT in mm, risk level, plaque heuristic); problem-centric validation (high-risk referral flow, hospital dashboard, Gasabo District scope).
- **How:** IMT measurement replaces subjective FAST checklist with an objective biomarker. The referral chain connects community health posts to Gasabo District Hospital, enabling faster triage and addressing the 72-hour "Treatment Vacuum."
- **Status:** Met.

### Objectives partially met
- **Real-time AI overlay:** Depends on ML model availability; demo mode provides stub results when model is not loaded. *Why partial:* Model size (~2–3 GB) limits deployment on free-tier hosting; overlay works when model is present.
- **SMS/Africa's Talking alerts:** Use sandbox (free) for testing: set `AFRICAS_TALKING_USERNAME=sandbox` and your sandbox API key in `.env`. See `.env.example`.

### Objectives not met / deferred
- **Field pilot (30–50 participants, Kimironko/Bumbogo):** Scheduled for Jan–Mar 2026. *Why deferred:* Deployment and field testing required more time than the sprint allowed; the system is now ready for pilot.

---

## Pushing the Full Product to GitHub

The repository should contain everything needed to run CarotidCheck locally or deploy it. Excluded (via `.gitignore`):

- `venv/`, `data/`, `uploads/` — local runtime data
- `ML/models/` — large model files (download separately or use Git LFS)
- `.env` — secrets (use `.env.example` as template)

**Recommended repo contents:**

- `app/` — Flutter app
- `backend/` — FastAPI backend
- `ML/` — notebooks, training scripts; **AttentionUNet.keras** (add via Git LFS if >100 MB)
- `thesis/`, `report/` — documentation
- `README.md`, `render.yaml`, `.env.example`

**Clone and run:**

```bash
git clone https://github.com/<org>/CarotidCheck.git
cd CarotidCheck
# Follow Quick Start above
```

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

**Pre-built release (download):** [Google Drive — app-release.apk](https://drive.google.com/file/d/13zI5Jj2Ycf1280hRFSSBl9bhABMODMUz/view?usp=sharing) *(install on Android; allow installs from Drive / your browser if prompted).*

**Build locally:**
```bash
cd app
flutter build apk --release --dart-define=API_BASE_URL=https://carotidcheck-api.onrender.com
# Output: app/build/app/outputs/flutter-apk/app-release.apk
```

**Install on Android device:**
1. Transfer `app-release.apk` to your phone (USB, email, [Google Drive link above](https://drive.google.com/file/d/13zI5Jj2Ycf1280hRFSSBl9bhABMODMUz/view?usp=sharing), or download from a release).
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

---


