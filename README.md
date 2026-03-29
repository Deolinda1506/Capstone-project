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

**macOS Keychain (`-34018`) / unsigned desktop builds:** the test clears prefs and best-effort clears secure storage before login. On a **sandboxed, unsigned** macOS app, `FlutterSecureStorage.deleteAll()` may hit *“A required entitlement isn’t present”*; the test ignores that error and continues. If a **saved session** is still in Keychain, you may skip the login screen and see a confusing failure—pick one of these:

1. **Manual reset:** Keychain Access → search `com.carotidcheck.carotidCheck` or “CarotidCheck” → remove related items → run again with real `E2E_*` defines.
2. **Other devices:** run the same test on **Android or iOS** (`flutter test … -d <device>`), where `deleteAll()` usually works.
3. **Signed macOS:** in Xcode, set a **Development Team** for the Runner target, add **`keychain-access-groups`** to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements` (array entry `$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`), then rebuild—Keychain clear works without manual cleanup (**requires** proper signing, not `CODE_SIGN_IDENTITY = -`).

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

### Notifications

- **In-app (web dashboard):** Pending high-risk referrals surface in the header (**bell**, **badge**, optional **banner**) by polling the API (`PendingReferralsContext`). Optional **browser** notifications if enabled in Settings.
- **Email (SMTP):** Referral and CHW ID messages when `SMTP_*` is configured. See `backend/.env.example` and `backend/email_service.py`.

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
| **High-risk visibility + alerts** | FR6 | **In-app:** web dashboard polls `GET /scans/high-risk` → bell, badge, banner (`web-dashboard/src/context/PendingReferralsContext.jsx`). **Email:** `backend/email_service.py` when `pred["is_high_risk"]` and SMTP configured. SMS not used. |
| **Clinician view high-risk referrals and past scan results** | FR7 | `GET /scans/high-risk` → `hospital_dashboard_screen.dart`; `GET /scans/with-results` → `analyses_screen.dart`. `GET /scans/{id}/image` fetches stored overlay for result view. `ReferralCard` → `ResultScreen` with image. |
| **Store scan and result for longitudinal tracking** | FR8 | `Scan` and `Result` models in `backend/models/`; `scans.py` stores scan + result in DB. Image stored in `uploads/{scan_id}.png`. `image_path` in DB; `has_image` in list responses. |

---

## Requirements traceability and validation

This section supports **requirements traceability** (each FR is tied to evidence) and **user acceptance testing (UAT)** (stakeholders confirm behaviour in realistic conditions). It complements [Use Case to Implementation Mapping](#use-case-to-implementation-mapping), which describes *where* features live in code.

### Requirements traceability matrix (RTM)

| FR | Use case | Verification method | Evidence / artifact |
|----|----------|---------------------|---------------------|
| **FR1** | Register and log in | Automated E2E; API/unit where applicable | Flutter: `app/integration_test/login_real_api_test.dart` (real API). Web: `web-dashboard/e2e/login-dashboard.spec.js` (Playwright). Backend: exercise `POST /auth/login`, `POST /auth/register` via `/docs` or scripted calls. |
| **FR2** | Create and manage patients | Manual / integration; API contract | `POST /patients`, `GET /patients` (`/docs`). Flutter: patient capture and list screens in `app/lib/screens/patient/`, `patients/`. |
| **FR3** | Capture or upload ultrasound | Manual UAT; E2E optional | Flutter `scan_screen.dart` + `POST /scans/upload`. Confirm stored file and DB row in test environment. |
| **FR4** | Segment artery, IMT, risk, stenosis | Automated unit & ML integration | `tests/test_inference.py`, `tests/test_latency_unit.py`; full graph: `tests/test_ml_model_integration.py` (`pytest -m ml`, requires `ML/AttentionUNet.keras`). |
| **FR5** | Display AI segmentation overlay | Automated (pipeline); UI UAT | Upload response / `GET /scans/{id}/image` includes overlay; `ResultScreen` + web dashboard image column. |
| **FR6** | High-risk in-app + optional email | Manual / UAT | Web: bell, badge, poll (`PendingReferralsContext`). Email: SMTP when configured (see `.env.example`). |
| **FR7** | Clinician referrals and past results | Automated E2E; manual walkthrough | Web: Playwright login + dashboard (`web-dashboard` E2E). Flutter: hospital dashboard / analyses flows. API: `GET /scans/high-risk`, `GET /scans/with-results`. |
| **FR8** | Store scan and result for tracking | API / DB checks | Persistence via `scans` router and models; confirm with repeated `GET` and file under `uploads/` after upload. |

**Coverage gaps (honest scope):** the RTM lists the *primary* evidence for each FR; several areas still rely on manual checks, Swagger, or a single E2E path rather than exhaustive automation.

| Area | Current state | Typical next step |
|------|----------------|-------------------|
| **Backend API** | `tests/test_api_health.py` exercises `/`, `/health`, `/latency` only—not full auth/patient/scan flows. | Add pytest cases with `TestClient`: register/login, `POST /patients`, `POST /scans/upload` (small fixture image), role-scoped list endpoints. |
| **Inference / ML** | Strong unit coverage in `test_inference.py` / `test_latency_unit.py`; optional real checkpoint in `test_ml_model_integration.py`. | Keep `-m ml` in CI when the `.keras` file is available; optional golden-output tolerances for regression. |
| **Flutter** | A few unit/widget tests (`test/widget_test.dart`, model tests under `test/core/`); no broad screen coverage. | More widget specs for login, scan, and result flows; keep `integration_test/login_real_api_test.dart` as API smoke. |
| **Web dashboard** | Vitest: `LandingPage.test.jsx`; Playwright: login → dashboard when env creds are set. | Add component tests for critical tables/cards; optional second E2E for referral detail. |
| **FR6 (in-app + email)** | In-app list/badge verified in UI; email validated via SMTP when enabled. | UAT walkthrough; optional integration test behind env flags. |
| **UAT** | By definition not fully automatable; scenarios in the table below are the formal acceptance layer. | Maintain a short signed checklist per release or pilot. |

### User acceptance testing (UAT)

**Goal:** Confirm that **real users** (or proxies such as clinical supervisors) can complete end-to-end workflows on a **staging or pilot** deployment without blocking defects.

| Element | Guidance |
|--------|----------|
| **Roles** | **CHW:** register/login (if applicable), create patient, capture/upload scan, view result, refer if high risk. **Clinician:** login to web dashboard, open high-risk list, open analysis detail / image. **Admin** (if used): access admin views per role design. |
| **Environment** | Same API base as pilot (e.g. Render deployment); test accounts only; SMTP/email test inboxes where possible. |
| **Scenario format** | For each scenario: *preconditions*, *steps*, *expected result* (map to FR ID), *pass/fail*, *date*, *tester*, *notes*. |
| **Example scenarios (map to RTM)** | (1) CHW logs in → creates patient → uploads image → sees IMT/risk/overlay (FR1–FR5, FR8). (2) Clinician logs into dashboard → sees referral/high-risk data → opens stored scan image (FR7). (3) New high-risk case appears in **in-app** notifications (bell/badge); referral email only if SMTP is on (FR6). |
| **Exit criteria** | Agreed set of scenarios **passed**; critical defects **fixed or waived** with documented risk; optional **sign-off** (name, role, date) on a short UAT summary or checklist. |

UAT is **not** a substitute for automated regression tests: use the RTM above to keep automated checks and UAT scenarios aligned so changes do not silently break requirements.

### Test metrics (targets vs achieved)

Use this style of table in reports and capstone documentation: **metric**, **acceptance target**, **measured value**, **status**. Numbers below tie to the evaluation in `thesis/CAROTIDCHECK-FINAL-REPORT.md` (§5.1); refresh **Achieved** when you re-run validation or read [`GET /latency`](https://carotidcheck-api.onrender.com/latency).

| Test metric | Target | Achieved | Status |
|-------------|--------|----------|--------|
| **Segmentation quality (Dice, Attention U-Net, Momot validation)** | ≥ 0.85 | ~0.946 ([Comparative results](#comparative-results-attention-u-net-vs-vision-transformer)) | ✓ Passed |
| **Mean IoU (Attention U-Net, validation)** | — (reported for comparison) | ~0.949 ([same table](#comparative-results-attention-u-net-vs-vision-transformer)) | Recorded |
| **Inference latency (end-to-end, design goal)** | &lt; 5 s per scan | Environment-dependent; CPU cloud samples may **exceed** 5 s (e.g. mean ~6.6 s for *n* = 6 in §5.1.2) | ⚠ See note |
| **Usability (e.g. SUS or structured UAT score)** | ≥ 80% (if you adopt this threshold) | From pilot / UAT (fill in) | — |

**Latency note:** The **&lt; 5 s** goal is a design target for responsive triage; free-tier / CPU-only hosting often misses it. Improve with GPU, paid tier, quantization, or warm-up—see thesis discussion.

**Example (generic QA-style row set — illustrative only):** some submissions use classification-style “accuracy” and response-time rows; replace targets and achieved values with definitions that match your study (e.g. Dice as “model accuracy”, API p95 from load tests, SUS from questionnaires).

| Test metric | Target | Achieved | Status |
|-------------|--------|----------|--------|
| Accuracy | ≥ 95% | 97% | ✓ Passed |
| Response time | &lt; 2 seconds | 1.5 seconds | ✓ Passed |
| Usability score | ≥ 80% | 85% | ✓ Passed |

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

## Comparative results: Attention U-Net vs Vision Transformer

Validation-style metrics from the model comparison (training pipeline / Momot dataset; details in `ML/notebooks/Carotid_Artery_Segmentation_Models_Comparison.ipynb`). **Attention U-Net** is deployed in `backend/inference.py` because it leads on **Dice**, **Jaccard / IoU**, and **loss**.

| Model | Loss | Accuracy | Dice coefficient | Jaccard index | Mean IoU |
|-------|------|----------|------------------|---------------|----------|
| **Attention U-Net** | 0.0409 | 0.9977 | 0.9461 | 0.9001 | 0.9489 |
| **Vision Transformer** | 0.0937 | 0.9934 | 0.8406 | 0.7441 | 0.8687 |
| **Absolute difference** (U-Net − ViT) | 0.0528 | 0.0043 | 0.1055 | 0.1559 | 0.0801 |

*Accuracy* here is **pixel-level** classification accuracy on the segmentation task (foreground/background labels), not clinical diagnostic accuracy.

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
- **Notifications:** Clinicians get **in-app** referral alerts on the web dashboard (API polling); configure SMTP in `.env` (see `backend/.env.example`) for **email** as well. SMS is not used.

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


