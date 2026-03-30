# Slide 8 — Preprocessing & training pipeline

Open this file in **VS Code / Cursor** with a Markdown preview that supports Mermaid (built-in preview often works), or paste the diagram into [mermaid.live](https://mermaid.live) to export PNG/SVG for PowerPoint.

---

## Diagram (Mermaid)

```mermaid
flowchart LR
  A[Raw Momot data<br/>Ultrasound PNG + expert mask] --> B[Preprocessing<br/>Grayscale / normalise [0,1]]
  B --> C[Spatial prep<br/>Square pad → 256×256]
  C --> D[Augmentation<br/>Albumentations:<br/>geom · noise · blur · CLAHE · crop]
  D --> E[Train / Val split<br/>80% train · 20% val · seed 42]
  E --> F[Training loop<br/>ViT · Attention U-Net]
  F --> G[Loss & optimiser<br/>α·BCE + (1−α)·Dice<br/>Adam 1e-4 · cosine LR<br/>early stopping on val Dice]
  G --> H[Outputs<br/>Best .keras checkpoints<br/>CSV logs · TensorBoard]
```

---

## Text (numbered steps — paste under diagram on slide)

1. **Dataset & inputs** — Momot (2022) common carotid ultrasound: ~1 100 image–mask pairs from 11 subjects with expert PNG wall masks.

2. **Preprocessing** — Load ultrasound (RGB or grayscale), convert to grayscale if needed, normalise to [0,1]; square-pad and resize images and masks to **256×256** (bilinear for images, nearest-neighbour for masks).

3. **Augmentation** — Albumentations: geometric transforms, noise, blur, small crops, CLAHE to simulate different probes and gain settings.

4. **Train–validation setup** — Split **80 % / 20 %** with **seed 42**; batch size **8** (train) and **4** (val).

5. **Training configuration** — Optimise **ViT** and **Attention U-Net** with **Adam (1e−4)** and a **cosine learning-rate schedule**, up to **30 epochs**, **early stopping** on validation Dice.

6. **Loss function** — α·BCE + (1−α)·Dice: **α = 0.5** (ViT), **α = 0.3** (Attention U-Net).

7. **Outputs & monitoring** — Checkpoints `AttentionViT.keras`, `AttentionUNet.keras`; CSV logs and **TensorBoard** for loss and Dice curves.
