# CarotidCheck

AI-powered carotid ultrasound screening for stroke risk assessment in Rwanda. Community health workers capture scans, get instant IMT (intima-media thickness) and risk levels, and refer high-risk patients to hospitals.

**Live API:** [https://carotidcheck-api.onrender.com](https://carotidcheck-api.onrender.com) · [API docs](https://carotidcheck-api.onrender.com/docs) · **Demo video:** [5-min demo](https://drive.google.com/file/d/1cF0XLiqFo-9NMABwXhOqR2R74O_6UWwN/view?usp=sharing)

---

## Quick Start

### Prerequisites

- **Python 3.12** (3.13 not supported by PyTorch)
- **Flutter 3.x** with Dart 3.10+
- **Git**

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
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
- PyTorch, MONAI, OpenCV for real AI inference  
- Real IMT, risk level, segmentation overlay  
- Requires model at `ML/models/carotid_swin_unetr_2d.pt`

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
│   ├── inference.py        # Swin-UNETR inference, overlay generation
│   ├── routers/            # auth, patients, scans
│   ├── models/             # User, Patient, Scan, Result, Hospital
│   ├── requirements.txt    # Full ML stack (PyTorch, MONAI, OpenCV)
│   └── requirements-api.txt # API only, no ML (~50 MB)
├── ML/                     # Models and training
│   ├── models/             # carotid_swin_unetr_2d.pt (place model here)
│   ├── notebooks/         # Deolinda_M4_Untitled38.ipynb (training, IMT validation)
│   └── carotid/            # Training scripts
├── data/                   # SQLite DB (created on first run)
└── README.md
```

---

## Related Files

| File / Folder | Purpose |
|--------------|---------|
| `backend/main.py` | FastAPI app entry, `/health`, `/ml-status` |
| `backend/inference.py` | Swin-UNETR inference, overlay generation |
| `backend/preprocessing.py` | CLAHE, DWT image preprocessing |
| `backend/routers/` | Auth, patients, scans endpoints |
| `app/lib/screens/` | Flutter UI (login, dashboard, scan, result, referral, hospital dashboard) |
| `app/lib/core/` | Config, API client, services, theme |
| `ML/notebooks/Deolinda_M4_Untitled38.ipynb` | ML training, IMT validation, Momot dataset |
| `ML/models/carotid_swin_unetr_2d.pt` | Trained Swin-UNETR model |
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

**Mapping implementation (CarotidCheck/StrokeLink) to proposal objectives:**

### Objective 1: Literature review and technical baselines
- **Achieved:** Swin-UNETR architecture selected; Momot dataset used for training (see `ML/notebooks/Deolinda_M4_Untitled38.ipynb`); IMT thresholds defined (High ≥3.5 mm, Moderate ≥3.0 mm, Low <3.0 mm); CLAHE and DWT in preprocessing pipeline.
- **How:** Swin-UNETR was chosen for its strong performance on medical imaging and suitability for 2D carotid slices. The Momot dataset (1100 image–mask pairs) enabled training with CLAHE/DWT preprocessing, which improved segmentation on low-quality ultrasound. IMT thresholds align with clinical guidelines for stroke risk stratification.
- **Status:** Met.

### Objective 2: Develop the cloud-integrated solution
- **Achieved:** Image-processing engine (CLAHE, DWT in `backend/preprocessing.py`); FastAPI backend with Swin-UNETR; Flutter app for CHWs with patient registration, scan upload, risk stratification, referral list, hospital dashboard.
- **How:** CHWs upload scans via the app → backend processes with CLAHE/DWT and runs Swin-UNETR inference → IMT and risk level are returned → high-risk patients can be added to the referral list; clinicians see incoming referrals on the hospital dashboard. Cloud-synchronized data flows through the FastAPI backend.
- **Status:** Met.

### Objective 3: Verify and validate with measurable metrics
- **Achieved:** Technical metrics (IMT in mm, risk level, plaque heuristic); problem-centric validation (high-risk referral flow, hospital dashboard, Gasabo District scope).
- **How:** IMT measurement replaces subjective FAST checklist with an objective biomarker. The referral chain connects community health posts to Gasabo District Hospital, enabling faster triage and addressing the 72-hour "Treatment Vacuum."
- **Status:** Met.

### Objectives partially met
- **Real-time AI overlay:** Depends on ML model availability; demo mode provides stub results when model is not loaded. *Why partial:* Model size (~2–3 GB) limits deployment on free-tier hosting; overlay works when model is present.
- **SMS/Africa's Talking alerts:** Integrated but requires API configuration for production. *Why partial:* Needs API keys and production setup; code is ready.

### Objectives not met / deferred
- **Field pilot (30–50 participants, Kimironko/Bumbogo):** Scheduled for Jan–Mar 2026. *Why deferred:* Deployment and field testing required more time than the sprint allowed; the system is now ready for pilot.

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
3. Ensure `ML/models/carotid_swin_unetr_2d.pt` is available for real AI overlay

### Flutter Web

```bash
cd app
flutter build web
# Deploy the build/web/ folder to Firebase Hosting, Vercel, Netlify, etc.
```

### Android APK

```bash
cd app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

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
- **ML:** PyTorch, MONAI (Swin-UNETR), OpenCV

---


