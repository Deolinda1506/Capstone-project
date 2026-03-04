# Final Version Submission – CarotidCheck

Use this template for your report (Testing Results, Analysis, Discussion, Recommendations).

---

## Testing Results [Screenshots with relevant demos]

### 1. Functionality under different testing strategies

| Strategy | Description | Screenshot/Result |
|----------|-------------|-------------------|
| Unit/Integration | [e.g. API endpoints, auth flow] | |
| End-to-end | [e.g. Full scan → result → referral flow] | |
| UI/UX | [e.g. Responsive layout, role-based dashboards] | |

### 2. Functionality with different data values

| Test Case | Input | Expected | Actual |
|-----------|-------|----------|--------|
| Low-risk scan | [e.g. IMT < 3.0 mm] | Low risk, green overlay | |
| Moderate-risk scan | [e.g. IMT 3.0–3.5 mm] | Moderate risk | |
| High-risk scan | [e.g. IMT ≥ 3.5 mm] | High risk, referral option | |
| Invalid image | Non-ultrasound image | Error handling | |

### 3. Performance on different hardware/software

| Environment | Specs | Result |
|-------------|-------|--------|
| Web (Chrome) | [e.g. macOS, 8GB RAM] | |
| Android | [e.g. Emulator / physical device] | |
| Backend | [e.g. Local vs deployed] | |

---

## Analysis

**Mapping implementation (CarotidCheck/StrokeLink) to proposal objectives:**

### Objective 1: Literature review and technical baselines
- **Achieved:** Swin-UNETR architecture selected; Momot dataset used for training; IMT thresholds defined (High ≥3.5 mm, Moderate ≥3.0 mm, Low &lt;3.0 mm); CLAHE and DWT in preprocessing pipeline.
- **Status:** Met.

### Objective 2: Develop the cloud-integrated solution
- **Image-Processing Engine:** CLAHE (Contrast Limited Adaptive Histogram Equalization) and optional DWT in `backend/preprocessing.py`.
- **FastAPI Backend:** Hosts Swin-UNETR model; endpoints for patients, scans, auth, high-risk referrals.
- **Mobile Interface:** Flutter app for CHWs — patient registration, scan upload, real-time risk stratification, referral list, hospital dashboard.
- **Status:** Met.

### Objective 3: Verify and validate with measurable metrics
- **Technical metrics:** IMT (mm), risk level, plaque heuristic (IMT ≥2.0 mm); segmentation overlay when model is loaded.
- **Problem-centric:** High-risk patients trigger referral flow; hospital dashboard shows incoming referrals; cloud-synchronized data.
- **Status:** Met (pilot validation with Gasabo District scope).

### Objectives partially met
- **Real-time AI overlay:** Depends on ML model availability; demo mode provides stub results when model is not loaded.
- **SMS/Africa's Talking alerts:** Integrated but requires API configuration for production.

### Objectives not met / deferred
- **Field pilot (30–50 participants, Kimironko/Bumbogo):** Scheduled for Jan–Mar 2026; deployment and field testing pending.

---

## Discussion

**Milestones and impact (per proposal):**

- **Sprint 1 (Data & Preprocessing):** Momot dataset, CLAHE/DWT pipeline — enables robust segmentation on low-quality ultrasound.
- **Sprint 2 (AI Model):** Swin-UNETR trained for carotid wall segmentation — objective IMT measurement replaces subjective FAST checklist.
- **Sprint 3 (Integration):** FastAPI + Flutter — CHWs upload scans; cloud returns risk; referral chain connects community to Gasabo District Hospital.
- **Sprint 4 (Deployment):** System deployable; hospital dashboard for clinicians; addresses 72-hour "Treatment Vacuum" by enabling faster triage.

**Impact:** Shifts stroke screening from reactive (symptoms) to predictive (IMT biomarker); bridges community health posts and urban specialists via cloud-synchronized referrals.

---

## Recommendations

### For the community

- Deploy StrokeLink/CarotidCheck in Gasabo District pilot (Kimironko, Bumbogo) with 5 CHWs and 2–3 clinicians.
- Configure Africa's Talking SMS for high-risk alerts to clinicians in Kigali.
- Provide mobile data bundles (MTN/Airtel) for CHWs during field testing.

### Future work

- Validate on Rwandan-specific carotid ultrasound data (beyond Momot dataset).
- Integrate National ID (NID) OCR for patient registration.
- Scale to additional districts; evaluate reduction in time-to-hospital (target: &lt;4.5 hours).

---

## Submission Checklist

- [ ] **Attempt 1:** Repo with README (install, run, related files)
- [ ] **Attempt 1:** 5-minute demo video (focus on core functionalities)
- [ ] **Attempt 1:** Deployed link OR APK/.exe
- [ ] **Attempt 2:** Zip file of the repo
