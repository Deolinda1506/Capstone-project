# Exploratory data analysis — Momot common carotid ultrasound (thesis snippet)

*Paste into Chapter 3 (data / methodology) or the final report. Adjust figure numbers to match your document.*

---

## Dataset summary

Training and validation use the **Momot (2022) Common Carotid Artery Ultrasound** public dataset (Mendeley Data), comprising **approximately 1 100 registered image–mask pairs** derived from **11 volunteers**. Masks are **expert-drawn segmentations** supplied as **PNG** (binary or near-binary vessel-wall regions), paired with B-mode ultrasound frames. This resource supports reproducible segmentation and IMT-oriented pipelines without collecting new patient imaging for the model-development phase.

---

## Exploratory data analysis (EDA)

EDA was performed **before** fixing train/validation splits and augmentation policy, to understand label geometry and imaging variability.

**Mask statistics (your figure).**  
For each mask, summary quantities included **foreground pixel coverage** (percentage of the frame labelled as vessel wall), **basic shape descriptors** (e.g. bounding box extent, connected components where relevant), and **per-subject counts** of usable pairs after quality filters. These plots show that wall annotations occupy a **limited fraction** of the image plane (typical of thin structures), motivating loss weighting or sampling strategies that avoid trivial “background-only” solutions. They also make **subject-level imbalance** visible: with only **11 subjects**, some individuals contribute many more frames than others, so **i.i.d. random splits** would **leak** appearance across train and validation; **subject-aware splitting** (or reporting subject-blocked metrics) is the appropriate interpretation.

**Intensity and image quality (your figure).**  
Ultrasound frames were summarised with **histograms or density plots of grey-level intensity**, **contrast proxies** (e.g. inter-quartile range or entropy), and optional **sharpness / blur proxies** if computed. The goal is to show **spread across acquisitions**: gain settings, speckle, and depth differences produce **non-stationary appearance** even within the same public corpus. That spread motivates **preprocessing** (e.g. normalisation, CLAHE) and **augmentation** used in training, and sets expectations for **field deployment** where probes and operators differ from the dataset.

Together, the EDA figures support the design choices in the preprocessing and training pipeline and document **what the model actually saw** during development.

---

## Generalisation and claims

The **small number of distinct subjects (n = 11)** is a **hard ceiling** on diversity of anatomy, pathology, device, and operator style. Validation metrics on Momot-style splits therefore reflect **performance under that distribution**, not guaranteed performance on **Rwandan field populations** or **pathology-rich** cohorts. Thesis and product language should **avoid over-claiming** external validity; **prospective field validation** (or larger, multi-site public data) is the scientific path to stronger generalisation statements.

---

## Ethics, privacy, and product alignment

**Research phase.** Use of the **public Momot dataset** follows the **licence and citation** requirements of the data publisher; no re-identification of the original volunteers is attempted.

**Product phase (CarotidCheck).** Operational imaging in the app is tied to **internal UUIDs** and **organisation-scoped** records, not to the Momot subject IDs. This supports **data minimisation** and **access control** in line with good practice and with **Rwanda’s personal data protection framework (Law No. 058/2021)**—including purpose limitation, security measures, and accountable processing when clinical workflows are deployed under institutional approval.

---

## Suggested figure captions (edit numbers)

- **Figure X.Y — Mask statistics (Momot corpus).** Distribution of mask foreground coverage and related label statistics across image–mask pairs; vertical lines or facets may indicate **per-subject** contribution. Illustrates thin-structure labelling and imbalance across the 11 subjects.

- **Figure X.Z — Ultrasound intensity and quality spread.** Grey-level and contrast summaries across frames (e.g. histograms, violin plots, or 2D density). Shows acquisition variability motivating preprocessing and augmentation.

---

## Reference

Momot, A. (2022). *Common carotid artery ultrasound dataset for automated intima-media thickness measurement* [Data set]. Mendeley Data. https://data.mendeley.com/datasets/d4xt63mgjm/1
