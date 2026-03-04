# CarotidCheck (StrokeLink)

AI-driven carotid ultrasound analysis for enhanced stroke triage in Rwanda. RBC-compliant Flutter frontend with role-based access control.

## Features

### 1. Role-Based Access Control (RBAC)

| Level | Role | UI Focus |
|-------|------|----------|
| 1 | Community Health Worker (CHW) | Scan → Result (Color) → Refer. Village-filtered patients only. |
| 2 | Hospital Clinician | Review AI Segmentation → Clinical Validation → Treatment Plan |
| 3 | Administrator/Researcher (ALU/RBC) | Anonymized stats → System Health → AI Accuracy Monitoring |

### 2. Simple Login & Registration

- **Login**: Email + password (via backend API)
- **Register**: Name, email, password (min 6 characters)
- Backend: FastAPI at `http://localhost:8000` (configurable via `API_BASE_URL`)

### 3. Hospital-Linked Account Creation

- Province → District → Sector → Health Center selection
- Account stays **Pending** until supervisor/admin approves

### 4. Patient Linking (NID Integration)

- Camera OCR placeholder for Rwandan National ID
- Privacy consent: digital signature or thumbprint
- Required for University Research ethics

### 5. Security

- **Encrypted storage**: `flutter_secure_storage` for tokens; app-private folder for images (not in Photo Gallery)
- **Watermarking**: User ID + Timestamp metadata on each scan
### 6. Sync Status

- **Grey**: Offline
- **Green**: Online (backend reachable)

## Project Structure

```
app/                 # Flutter app
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── models/       # User, Patient, Location, UserRole
│   │   ├── router/       # go_router config
│   │   ├── security/     # Encrypted image storage
│   │   ├── services/     # Auth, Sync, SecureStorage
│   │   ├── theme/
│   │   └── widgets/      # SyncStatusIndicator
│   ├── screens/
│   │   ├── dashboard/   # CHW, Clinician, Admin
│   │   ├── login/       # Login, OTP
│   │   ├── patient/     # Capture, Consent
│   │   ├── register/
│   │   ├── referral/
│   │   ├── result/
│   │   └── scan/
│   └── main.dart
backend/             # FastAPI backend
ML/                  # ML models and training
```

## Run

**1. Start the backend** (from project root):

```bash
cd "/path/to/CarotidCheck app"
python3.12 -m venv .venv
source .venv/bin/activate
# Lightweight (~50 MB) - use when disk space is low. Scan returns stub result.
pip install -r backend/requirements-api.txt
# Or full install (~2–3 GB) for real ML inference:
# pip install -r backend/requirements.txt
python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```
Run from project root so Python finds the `backend` module.

**2. Run the Flutter app**:

```bash
cd app
flutter pub get
flutter run
```

For Android emulator, the backend is at `10.0.2.2:8000`. Set when building:
```bash
cd app && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Demo Login

1. Tap **Register** and create an account (name, email, password)
2. Tap **Login** and enter your email and password
3. Backend must be running at `http://localhost:8000` (or configured URL)

## Responsive Design

- **Phones**: Compact padding (16px), scrollable content
- **Tablets**: Wider padding (24–32px), max-width 600px for readability
- **Orientations**: Portrait and landscape supported
- **SafeArea**: Respects notches and system UI

## Tech Stack

- Flutter 3.x
- go_router, Provider
- flutter_secure_storage
- connectivity_plus
- image_picker, camera, signature
- Simple email/password auth
- **google_mlkit_text_recognition** (Rwandan NID OCR)
- **flutter_map** (OpenStreetMap – no API key)

## Configuration

### Maps

Uses **OpenStreetMap** via `flutter_map` – **no API key required**. The map shows Gasabo District Hospital. "Get Directions" opens Google Maps in the browser.
