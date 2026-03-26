# Usability test — session record (CarotidCheck)

**How to use:** Duplicate this file per session (e.g. `2026-03-26-P01-chw.md`) or print and write by hand. Complete the **session header**, then one **row per task**. After tasks, optionally complete **SUS** (System Usability Scale).

---

## Session header

| Field | Value |
|-------|--------|
| **Session ID** | e.g. P01 |
| **Date** | YYYY-MM-DD |
| **Start time** | |
| **End time** | |
| **Participant role** | CHW / Clinician / Admin |
| **Device & OS** | e.g. Android 14 phone / Chrome on macOS |
| **App / build** | e.g. Flutter debug, web dashboard `npm run dev`, API URL |
| **Facilitator** | name |
| **Observer** (optional) | name |
| **Consent** | e.g. verbal / signed (Y) |
| **Think-aloud** | Y / N |

**Context (1–2 lines):** e.g. first time using the app / familiar with ultrasound / language used.

---

## Task-by-task log

**Definitions**

- **Success:** participant reaches the **expected end state** for the task **without the facilitator solving the task for them** (minor wording hints allowed—count as *hints*).
- **Time on task:** wall-clock from “start” (task understood) to success or abandonment. Use `mm:ss` or seconds.
- **Errors / confusion:** brief notes (wrong tap, back navigation loop, “where is…?”, long pause > ~10 s at one step).
- **Hints:** number of **explicit hints** given after a stall (e.g. “try the blue button”, “scroll down”). `0` = no hints.

| Task ID | Task description (expected end state) | FR (optional) | Success Y/N | Time (mm:ss) | Errors / confusion (notes) | Hints (#) | Notes |
|---------|----------------------------------------|---------------|---------------|----------------|-----------------------------|-----------|-------|
| T1 | | | | | | | |
| T2 | | | | | | | |
| T3 | | | | | | | |
| T4 | | | | | | | |
| T5 | | | | | | | |

**Example row (illustrative):**

| Task ID | Task description | FR | Success Y/N | Time | Errors / confusion | Hints (#) | Notes |
|---------|------------------|----|-------------|------|---------------------|-----------|-------|
| T2 | Log in with test staff ID and password; land on home/dashboard | FR1 | Y | 01:12 | Hesitated 15s on identifier field | 1 | Hint: “Staff ID is like 0102-001” |

---

## Session summary (fill after tasks)

| Metric | Value |
|--------|--------|
| Tasks attempted | |
| Tasks successful (Y) | |
| **Success rate** | __ / __ = ___% |
| **Total hints** (sum of Hints column) | |
| **Mean time on task** (avg of completed tasks) | |
| **Severe issues** (blockers, safety, data loss) | Y/N — describe |

**Top 3 usability issues (for backlog):**

1.  
2.  
3.  

---

## Optional: System Usability Scale (SUS)

Ask **after** tasks. For each item: **1** = strongly disagree … **5** = strongly agree (use the standard SUS wording).

| # | Statement | 1 | 2 | 3 | 4 | 5 |
|---|-----------|---|---|---|---|---|
| 1 | I think that I would like to use this system frequently. | | | | | |
| 2 | I found the system unnecessarily complex. | | | | | |
| 3 | I thought the system was easy to use. | | | | | |
| 4 | I think that I would need the support of a technical person to be able to use this system. | | | | | |
| 5 | I found the various functions in this system were well integrated. | | | | | |
| 6 | I thought there was too much inconsistency in this system. | | | | | |
| 7 | I would imagine that most people would learn to use this system very quickly. | | | | | |
| 8 | I found the system very cumbersome to use. | | | | | |
| 9 | I felt very confident using the system. | | | | | |
| 10 | I needed to learn a lot of things before I could get going with this system. | | | | | |

**SUS score (0–100):** use the [standard SUS formula](https://measuringu.com/sus/) (odd items: score − 1; even items: 5 − score; sum × 2.5).  
**Computed SUS:** ___ / 100 (facilitator calculates after session).

---

## Suggested default tasks (edit to match your build)

**CHW (mobile)**  
T1 — Complete onboarding (if shown) and reach login.  
T2 — Log in with test credentials.  
T3 — Create or select patient → open scan flow.  
T4 — Upload or capture scan → wait for result → read IMT/risk.  
T5 — (If high-risk path exists) Open referral or hospital list.

**Clinician (web)**  
T1 — Open dashboard URL → log in.  
T2 — Locate high-risk or pending referral.  
T3 — Open one case → view image or details.  
T4 — (If applicable) Mark reviewed or use search.

---

*Do not store real patient identifiers or passwords in this file; use test accounts and anonymized participant IDs (P01, P02).*
