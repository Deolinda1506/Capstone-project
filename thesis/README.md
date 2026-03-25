# CarotidCheck thesis & report

**CarotidCheck: AI-Driven Carotid Ultrasound Analysis for Enhanced Stroke Triage in Rwanda**

BSc. in Software Engineering | Gnon Deolinda Bio Bogore | Supervisor: Tunde Isiaq Gbadamosi | January 2026

---

## Full capstone report (PDF-ready Markdown)

| File | Content |
|------|---------|
| **[CAROTIDCHECK-FINAL-REPORT.md](CAROTIDCHECK-FINAL-REPORT.md)** | **Single document:** declaration, abstract, TOC, acronyms, Chapters 1–6, references (implementation, testing, results, conclusions). Export to Word/PDF from your editor or Pandoc. |

---

## Earlier chapter drafts (modular)

| File | Content |
|------|---------|
| [00-front-matter.md](00-front-matter.md) | Title page, table of contents, acronyms |
| [01-chapter-one-introduction.md](01-chapter-one-introduction.md) | Introduction (draft; report uses CarotidCheck naming in `CAROTIDCHECK-FINAL-REPORT.md`) |
| [02-chapter-two-literature-review.md](02-chapter-two-literature-review.md) | Literature review draft |
| [03-chapter-three-system-analysis-design.md](03-chapter-three-system-analysis-design.md) | System analysis & design draft |
| [04-references.md](04-references.md) | APA-formatted references (draft) |

---

## Figures

- Figure 1.1: `figures/figure-1.1.svg` — CarotidCheck 3-month Gantt (Jan–Mar 2026)  
- Figure 5.1: `figures/figure-5.1-dice-comparison.png` (source: `figure-5.1-dice-comparison.svg`) — Dice bar chart ViT vs. Attention U-Net  
- Figure 5.2: `figures/figure-5.2-inference-latency.png` (source: `figure-5.2-inference-latency.svg`) — inference latency line chart; edit SVG then re-rasterize or use `plot-figure-5.2-latency.py` with matplotlib  
- Figure 5.3: `figures/figure-5.3-risk-distribution.png` (source: `figure-5.3-risk-distribution.svg`) — risk bar chart; regenerate from DB: `PYTHONPATH=. python3 scripts/render_figure_5_3_from_db.py`  
- Figure 4.7: `figures/figure-4.7-web-dashboard.png` — clinician **web dashboard** Overview (deployed dashboard screenshot)  
- Figures 3.x, 4.1–4.6, other 4.x: embed screenshots and diagrams when building the final PDF  

---

## Related project

This folder documents **CarotidCheck**: Flutter app, FastAPI backend, React `web-dashboard`, and ML assets in `ML/`.
