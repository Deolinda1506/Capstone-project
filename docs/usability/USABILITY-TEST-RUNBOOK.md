# Usability test — runbook (CarotidCheck)

Use this with **`usability-test-session-template.md`**. Duplicate the template per participant into `sessions/` (see naming below).

---

## Before the day

1. **Pick environment** (one per study — keep consistent across participants):
   - **API:** production `https://carotidcheck-api.onrender.com` *or* local `http://localhost:8000` (must be running).
   - **Mobile:** release/debug APK or `flutter run` with `--dart-define=API_BASE_URL=...` matching that API.
   - **Web dashboard:** `https://carotidcheck-dashboard.onrender.com` *or* `npm run dev` / `vite preview` pointing at the same API.

2. **Test accounts** (do **not** commit passwords; use a password manager or paper):
   - At least **one CHW** account (patient + scan flow).
   - At least **one clinician** account (dashboard + referral review).
   - Optional: **admin** if you test team invites.

3. **Sample data**
   - **Non‑patient** ultrasound PNGs you are allowed to use (e.g. Momot-style or anonymised test images).
   - Fake patient names/IDs only (e.g. `CC-TEST-01`).

4. **Duplicate the template** per participant:
   - `sessions/YYYY-MM-DD-P01-chw.md`
   - `sessions/YYYY-MM-DD-P02-clinician.md`

5. **Devices**
   - Phone charged; **screen recording** optional (with consent).
   - For web: Chrome + one backup browser.

---

## Session flow (45–60 min)

| Phase | Time | What you do |
|--------|------|-------------|
| Intro | 5 min | Explain purpose, think‑aloud, right to stop; no wrong answers. |
| CHW tasks | 20–25 min | Tasks T1–T5 from template (adapt to your build). |
| **Break** | 2 min | — |
| Clinician tasks (same person or second session) | 15–20 min | Web dashboard tasks. |
| SUS (optional) | 10 min | 10 questions in template; compute score after. |
| Debrief | 5 min | “What was hardest?” “What would you change?” |

**Facilitator rules:** Do not take the phone from the participant unless safety. Count **hints** only when you give a *new* explicit hint after a stall.

---

## After all sessions

1. Fill **session summary** in each file (success rate, mean time, top 3 issues).
2. Aggregate **mean SUS** if you collected it (n ≥ 3 is more credible for a class report).
3. Add **one paragraph** to your thesis/report: n, roles, environment, main findings, limitations (small n, non‑random sample).

---

## What to put on the defense slide (honest)

- `n = ?` participants  
- Task success rate (% tasks completed without abandonment)  
- Mean SUS = ? / 100 (only if you computed it)  
- **Top 1–3 usability issues** (shows you learned something)

If you run **0 sessions** before defense, say: **Protocol and template prepared; formal sessions were not completed in time.**

---

## Files

| File | Purpose |
|------|---------|
| `usability-test-session-template.md` | One record per participant |
| `sessions/` | Store copies; **no real patient IDs or passwords** in git |
