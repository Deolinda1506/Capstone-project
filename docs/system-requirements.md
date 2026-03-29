# System requirements (CarotidCheck)

High-level requirements used for design, validation, and reporting. Detailed use-case mapping lives in the root [`README.md`](../README.md) (FR1–FR8, API tables, RTM).

---

## Functional requirements

| Area | Description | CarotidCheck alignment |
|------|-------------|------------------------|
| **User registration and authentication** | Identify users securely; issue sessions/tokens; role-appropriate access. | JWT auth (`POST /auth/register`, `POST /auth/login`); Flutter `AuthService` + secure storage; web dashboard login; optional offline cached login after first online success. |
| **Data input and processing** | Capture or upload domain data; validate; run business/AI pipeline; persist results. | Patient registration (`POST /patients`); carotid scan upload (`POST /scans/upload`); Attention U-Net inference (IMT, risk, overlay, optional stenosis); SQLite/Postgres persistence and stored images. |
| **Reporting and analytics** | Summaries, charts, and operational metrics for decision-makers. | Web dashboard: risk distribution, scans over time, inference latency stats (`GET /latency`); high-risk and “all analyses” lists; `GET /scans/risk-distribution` API. |
| **System administration** | Configure service, roles, notifications, and operational policies where applicable. | Admin role in Flutter; **clinician in-app notifications** on web dashboard (poll API); optional email (SMTP); Render/hosting config; optional alert queue (`backend` alert modules). |
| **Referral / clinical workflow** | Surface high-risk cases to clinicians; support review. | High-risk lists, referral flows, clinician review fields on scans, dashboard triage (see FR6–FR8 in README). |

*Additional functional items can be listed the same way (table or bullet) for your thesis or SRS appendix.*

---

## Non-functional requirements

| Category | Target / intent | Notes for this project |
|----------|-----------------|-------------------------|
| **Performance** | Fast enough response for interactive use; define layers clearly. | **Light API calls** (health, auth, small JSON): often sub-second on a warm instance. **ML inference** is heavier: design discussion in the thesis uses a **~5 s** scan-level goal on suitable hardware; free-tier cloud CPU may be slower—see `/latency` and README. If your document states **&lt; 2 s**, scope it (e.g. *non-inference* endpoints or *p95* under defined load). |
| **Security** | Protect data in transit and at rest; least-privilege access. | **HTTPS** in production; **JWT** for API; passwords hashed server-side; scan images tied to internal IDs; Flutter **secure storage** for tokens on device; follow org policies for PHI. |
| **Usability** | Intuitive flows for CHWs and clinicians; learnable with minimal training. | Mobile onboarding and dashboards; web dashboard charts and tables; optional **SUS** and task-based tests—see `docs/usability/usability-test-session-template.md`. |
| **Scalability** | Grow with user and data volume within cost constraints. | Stateless API behind a load balancer; **Postgres** for production DB; background/worker patterns for alerts; large assets (model, uploads) may need object storage and paid tier for heavy load. A **1000+ user** target is plausible with proper DB indexing, connection limits, and hosting plan—validate with load testing if required. |
| **Reliability / availability** | Dependable service for triage workflows. | Health checks (`/health`, `/ml-status`); graceful degradation when ML model is absent (stub/demo paths); monitoring via host (e.g. Render) and logs. |
| **Maintainability** | Clear structure and tests for change. | Layered backend (`routers`, `models`, `inference`); pytest, Vitest, Playwright, Flutter integration tests as described in README. |

Adjust numeric targets (2 s, 1000 users) in your official SRS or thesis to match what you actually measure and commit to.

---

## Requirements gathering

Typical methods used (or planned) for this class of system:

| Method | Purpose |
|--------|--------|
| **Interviews** | Elicit workflows, pain points, and constraints from CHWs, clinicians, and administrators. |
| **Surveys** | Broader sampling on priorities, training burden, and feature importance. |
| **Document analysis** | Align with national/digital health guidelines, ethics, and data-protection law (e.g. local privacy requirements); review literature on IMT triage and stroke pathways. |
| **Observation / contextual inquiry** | Optional: shadow screening sessions to see real device and connectivity conditions. |
| **Prototypes & walkthroughs** | Validate understanding before full build; feed into usability/UAT scripts. |

Record *who* was consulted, *when*, and *how* findings trace to FR/NFR rows for traceability.

---

## Traceability

Link each requirement ID (if you use FR1–FR8 or custom IDs) to:

- **Design** — README “Use Case to Implementation” and API tables.  
- **Verification** — README RTM (automated tests, E2E, manual).  
- **Acceptance** — UAT scenarios and usability session logs under `docs/usability/`.
