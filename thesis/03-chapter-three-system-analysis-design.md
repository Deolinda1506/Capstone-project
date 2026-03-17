# CHAPTER THREE: SYSTEM ANALYSIS AND DESIGN

## 3.1 Introduction

This chapter outlines the technical framework and design strategies used to develop StrokeLink. The system is designed to bridge the "Treatment Vacuum" in Rwanda by shifting stroke screening from subjective observation to objective, AI-driven analysis. The research follows a Quantitative and Experimental Research Methodology, where the performance of the machine learning model is measured against established clinical benchmarks for Intima-Media Thickness (IMT). To ensure the software is reliable and scalable, the design focuses on a cloud-native architecture that connects community health posts directly to district hospitals.

## 3.2 Research Design

The development of StrokeLink follows the Agile Development Model. This approach is ideal for machine learning projects because it allows for an iterative cycle of training, testing, and refining. Since medical images can be unpredictable, an Agile approach lets the developer adjust the AI model's accuracy based on real-world data feedback before the final deployment.

- **Phase 1: Sprint One (Data & Preprocessing)** — The first phase involves gathering the Momot (2022) dataset and applying Wavelet Transforms to ensure the images are clean enough for the AI to read.

- **Phase 2: Sprint Two (AI Model Development)** — In this stage, the Swin-UNETR Vision Transformer is trained. The goal is to reach a high accuracy level in identifying the carotid artery walls.

- **Phase 3: Sprint Three (System Integration)** — The trained model is connected to the FastAPI backend, and the Flutter interface is built so health workers can interact with the system.

- **Phase 4: Sprint Four (Deployment & Testing)** — The final stage involves testing the real-time referral alerts to ensure they correctly notify the Gasabo District hospital.

## 3.3 Class Diagram

The StrokeLink system is designed using Object-Oriented principles to ensure that medical data is handled securely and that the AI diagnostic logic is decoupled from the user interface. This structure allows for easy updates to the machine learning model without disrupting the rest of the application.

*See Figure 3.1: StrokeLink UML Class Diagram*

## 3.4 System Architecture

The StrokeLink platform follows a Client-Server Architecture. Unlike hybrid models, this design requires an active internet connection to perform any diagnostic tasks. This ensures that the mobile application remains lightweight and that all heavy computations are handled by high-performance cloud servers.

*See Figure 3.2: Client-Server Architecture*

## 3.5 UML Diagrams

The ERD for StrokeLink defines the logical structure of the database. It is designed to support longitudinal tracking, meaning the system doesn't just process a scan and forget it; it builds a historical health profile for every patient to help doctors in the Gasabo District see trends in stroke risk.

*See Figure 3.3: StrokeLink Entity-Relationship Diagram (ERD)*

## 3.6 Development Tools

| Tool | Purpose |
|------|---------|
| **Integrated Development Environment (IDE)** | VS Code & Google Colab serves as the primary hub for building the Flutter app and FastAPI backend. Google Colab is used specifically for the ML Track requirements, providing the GPU power needed to train the Swin-UNETR model on the Momot (2022) dataset. |
| **Mobile Framework** | Flutter (Dart) — Chosen for its "Thin Client" efficiency. Since the app is online-only, Flutter handles the UI and the secure transmission of carotid images to the cloud without needing heavy local processing. |
| **Backend Framework** | FastAPI (Python) — A high-performance web framework used to create the StrokeLink API. Its asynchronous capabilities allow it to receive an ultrasound image, send it to the AI model, and save results to the database simultaneously, reducing the triage time. |
| **Medical AI Library** | MONAI (Medical Open Network for AI) — Instead of using a generic AI library, MONAI is used because it is specifically optimized for healthcare. It provides the pre-built Swin-UNETR architecture, which is essential for accurate carotid artery segmentation. |
| **Cloud Hosting** | Render (Free Tier) |
| **Database & Auth** | Firebase — A managed cloud database used for real-time synchronization. When a caregiver in Bumbogo saves a patient's medical history, it is instantly visible to doctors at the Gasabo District Hospital. |
| **Design & Prototyping** | Figma — Used in the initial phase to design the StrokeLink user interface, ensuring the app is easy to navigate for health workers who may not be tech-savvy. |
