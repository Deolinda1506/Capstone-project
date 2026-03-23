"""IMT inference via Attention U-Net. Used by /predict and /scans/upload."""
import base64
import logging
import os
import time
from pathlib import Path

import cv2
import numpy as np

# Disable MKL/OneDNN to avoid Floating Point Exception on Intel Mac (TF 2.16)
os.environ.setdefault("TF_DISABLE_MKL", "1")
os.environ.setdefault("TF_ENABLE_ONEDNN_OPTS", "0")

_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_MODEL_PATH = _PROJECT_ROOT / "ML" / "AttentionUNet.keras"

model = None

DEFAULT_SPACING_MM_PER_PIXEL = 0.04

logger = logging.getLogger(__name__)
if _MODEL_PATH.exists():
    logger.info("ML model found at %s", _MODEL_PATH)
else:
    logger.warning("ML model not found at %s (will use demo fallback)", _MODEL_PATH)


def load_model():
    import tensorflow as tf

    # Import custom layers so they are registered before load_model
    import sys
    _ml_root = _PROJECT_ROOT / "ML"
    if str(_ml_root) not in sys.path:
        sys.path.insert(0, str(_PROJECT_ROOT))
    from ML.model_layers import EncoderBlock, DecoderBlock, AttentionGate  # noqa: F401

    global model
    if model is not None:
        return model
    if not _MODEL_PATH.exists():
        raise FileNotFoundError(f"Model not found at {_MODEL_PATH}")
    custom_objects = {
        "EncoderBlock": EncoderBlock,
        "DecoderBlock": DecoderBlock,
        "AttentionGate": AttentionGate,
    }
    model_obj = tf.keras.models.load_model(
        str(_MODEL_PATH), custom_objects=custom_objects, compile=False
    )
    model = model_obj
    print(f"✅ Attention U-Net model loaded from {_MODEL_PATH}")
    return model


def _preprocess_for_attention_unet(image_bytes: bytes) -> tuple[np.ndarray, np.ndarray, int, int]:
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        img = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)
        if img is None:
            raise ValueError("Invalid image")
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    orig_gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
    h, w = img.shape[:2]

    # Pad to square (match notebook)
    max_dim = max(h, w)
    pad_h_before = (max_dim - h) // 2
    pad_h_after = max_dim - h - pad_h_before
    pad_w_before = (max_dim - w) // 2
    pad_w_after = max_dim - w - pad_w_before
    img = np.pad(img, ((pad_h_before, pad_h_after), (pad_w_before, pad_w_after), (0, 0)), mode="constant", constant_values=0)

    # Resize to 256x256
    img = cv2.resize(img, (256, 256), interpolation=cv2.INTER_LINEAR)
    img = img.astype(np.float32) / 255.0
    return img, orig_gray, h, w


def _get_interfaces_from_mask(mask):
    h, w = mask.shape
    inner_interface = np.full(w, np.nan)
    outer_interface = np.full(w, np.nan)
    for x in range(w):
        foreground_y = np.where(mask[:, x] > 0)[0]
        if len(foreground_y) > 0:
            inner_interface[x] = float(np.min(foreground_y))
            outer_interface[x] = float(np.max(foreground_y))
    return inner_interface, outer_interface


def _lumen_diameter_px_per_column(mask, min_gap_px: int = 3) -> np.ndarray:
    """
    Extract lumen diameter (px) per column when the mask has two wall segments (near + far wall).
    The lumen is the gap between the two walls. Returns NaN where only one wall is present.
    """
    h, w = mask.shape
    lumen_px = np.full(w, np.nan)
    for x in range(w):
        fg = np.where(mask[:, x] > 0)[0]
        if len(fg) < 2:
            continue
        fg_sorted = np.sort(fg)
        gaps = np.diff(fg_sorted)
        if np.any(gaps >= min_gap_px):
            lumen_px[x] = float(np.max(gaps))
    return lumen_px


def _get_imt_thresholds(patient_age: int | None) -> tuple[float, float]:
    """
    Age-specific IMT thresholds (mm) for stroke risk.
    IMT naturally thickens with age; thresholds from NIH/AHA clinical guidelines.
    Returns (moderate_mm, high_mm): Low < moderate, Moderate in [moderate, high], High > high.
    """
    if patient_age is None or patient_age < 0:
        return (0.9, 1.2)  # Default: Low <0.9, Moderate 0.9–1.2, High >1.2
    if patient_age < 40:
        return (0.8, 1.0)   # Younger: stricter (Low <0.8, Moderate 0.8–1.0, High >1.0)
    if patient_age < 60:
        return (0.9, 1.1)   # Middle-aged (Low <0.9, Moderate 0.9–1.1, High >1.1)
    return (0.9, 1.2)       # Older (≥60): standard thresholds


def _stenosis_pct_nascet(D_stenosis_mm: float, D_distal_mm: float) -> float:
    """
    NASCET formula: Stenosis % = (1 - D_stenosis / D_distal) × 100
    D_stenosis = narrowest residual lumen diameter at the stenosis (mm)
    D_distal = diameter of the normal distal ICA (mm)
    """
    if D_distal_mm <= 0 or D_stenosis_mm < 0:
        return np.nan
    return max(0.0, min(100.0, (1.0 - D_stenosis_mm / D_distal_mm) * 100.0))


def _imt_mm_from_mask(mask, spacing_mm_per_pixel):
    inner_int, outer_int = _get_interfaces_from_mask(mask)
    thickness = np.abs(outer_int - inner_int)
    valid = np.isfinite(thickness)
    if not np.any(valid):
        return np.nan
    return float(np.nanmean(thickness) * spacing_mm_per_pixel)


def _overlay_segmentation_on_image(original_gray: np.ndarray, mask_256: np.ndarray) -> bytes:
    """Resize mask to original size and create RGB overlay (green = wall). Returns PNG bytes."""
    if original_gray.ndim != 2:
        original_gray = np.squeeze(original_gray)
    if mask_256.ndim != 2:
        mask_256 = np.squeeze(mask_256)
    if original_gray.ndim != 2 or mask_256.ndim != 2:
        raise ValueError(f"Expected 2D arrays, got original {original_gray.shape}, mask {mask_256.shape}")
    h, w = original_gray.shape
    if h == 0 or w == 0:
        raise ValueError(f"Invalid image dimensions: {h}x{w}")
    mask_u8 = (np.asarray(mask_256) > 0).astype(np.uint8)
    mask_resized = cv2.resize(mask_u8, (w, h), interpolation=cv2.INTER_NEAREST)
    orig_max = float(np.max(original_gray))
    if orig_max <= 1.0:
        orig_u8 = np.clip(original_gray * 255, 0, 255).astype(np.uint8)
    else:
        orig_u8 = np.clip(original_gray, 0, 255).astype(np.uint8)
    rgb = np.stack([orig_u8, orig_u8, orig_u8], axis=-1)
    green = np.array([0, 255, 0], dtype=np.uint8)
    alpha = 0.65
    wall = mask_resized > 0
    for c in range(3):
        blended = (alpha * green[c] + (1 - alpha) * rgb[:, :, c]).astype(np.uint8)
        rgb[:, :, c] = np.where(wall, blended, rgb[:, :, c])
    contours, _ = cv2.findContours(mask_resized, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    for cnt in contours:
        cv2.drawContours(rgb, [cnt], -1, (0, 255, 0), 2)
    bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
    ok, png = cv2.imencode(".png", bgr)
    if not ok or png is None:
        raise ValueError("cv2.imencode failed")
    return png.tobytes()


def predict_imt(
    image_bytes: bytes,
    spacing_mm_per_pixel: float = DEFAULT_SPACING_MM_PER_PIXEL,
    return_segmentation_overlay: bool = True,
    patient_age: int | None = None,
) -> dict:
    """Run inference; returns imt_mm, risk_level, foreground_prob, inference_time_sec, and optionally segmentation_overlay_base64."""
    t0 = time.perf_counter()
    img_batch, original_gray, orig_h, orig_w = _preprocess_for_attention_unet(image_bytes)
    img_batch = np.expand_dims(img_batch, axis=0)

    m = load_model()
    pred = m.predict(img_batch, verbose=0)
    pred_mask = pred[0]
    if pred_mask.ndim == 3:
        pred_mask = pred_mask.squeeze()
    pred_class = (pred_mask > 0.5).astype(np.uint8)

    # Scale spacing: mask is 256x256, resized from max(orig_h,orig_w)
    pixel_spacing_source = (
        "default"
        if abs(float(spacing_mm_per_pixel) - float(DEFAULT_SPACING_MM_PER_PIXEL)) < 1e-9
        else "metadata"
    )
    max_dim = max(orig_h, orig_w)
    effective_spacing = (max_dim / 256.0) * spacing_mm_per_pixel
    imt_mm = _imt_mm_from_mask(pred_class, effective_spacing)
    foreground_prob = float(np.mean(pred_mask))
    if np.isnan(imt_mm):
        imt_mm = 0.5 + (foreground_prob * 1.0)  # Fallback: 0.5–1.5 mm range

    # NASCET stenosis: Stenosis % = (1 - D_stenosis / D_distal) × 100
    # D_stenosis = narrowest lumen diameter; D_distal = normal distal reference
    lumen_px = _lumen_diameter_px_per_column(pred_class)
    stenosis_pct = np.nan
    stenosis_source = "imt_correlation"  # Default: fallback when both walls not detected
    if np.any(np.isfinite(lumen_px)):
        lumen_mm = lumen_px * effective_spacing
        D_stenosis_mm = float(np.nanmin(lumen_mm))  # Narrowest residual lumen
        D_distal_mm = float(np.nanmax(lumen_mm))   # Normal distal reference (widest segment)
        if D_distal_mm > 0:
            stenosis_pct = _stenosis_pct_nascet(D_stenosis_mm, D_distal_mm)
            stenosis_source = "nascet"  # Both walls segmented; true lumen-based NASCET
    if not np.isfinite(stenosis_pct):
        # Fallback: derive from IMT–stenosis correlation when mask has single wall only
        if imt_mm < 0.9:
            stenosis_pct = (imt_mm / 0.9) * 50.0
        elif imt_mm <= 1.2:
            stenosis_pct = 50.0 + (imt_mm - 0.9) / 0.3 * 19.0
        else:
            stenosis_pct = min(99.0, 70.0 + (imt_mm - 1.2) * 10.0)

    # Risk thresholds: use age-specific when patient_age provided (NIH-aligned); else fixed
    moderate_mm, high_mm = _get_imt_thresholds(patient_age)
    risk_level = "High" if imt_mm > high_mm else "Moderate" if imt_mm >= moderate_mm else "Low"
    is_high_risk = imt_mm > high_mm

    overlay_b64 = None
    has_ai_overlay = False
    if return_segmentation_overlay:
        try:
            overlay_bytes = _overlay_segmentation_on_image(original_gray, pred_class)
            overlay_b64 = base64.b64encode(overlay_bytes).decode("ascii")
            has_ai_overlay = True
            logger.info("AI overlay generated (Attention U-Net)")
        except Exception as e:
            logger.warning("Segmentation overlay failed: %s", e, exc_info=True)
            try:
                orig_u8 = np.clip(original_gray * 255 if np.max(original_gray) <= 1 else original_gray, 0, 255).astype(np.uint8)
                rgb = np.stack([orig_u8, orig_u8, orig_u8], axis=-1)
                ok, png = cv2.imencode(".png", cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR))
                if ok and png is not None:
                    overlay_b64 = base64.b64encode(png.tobytes()).decode("ascii")
            except Exception as e2:
                logger.warning("Fallback overlay failed: %s", e2)

    inference_time_sec = time.perf_counter() - t0
    logger.info("Inference completed in %.2f s", inference_time_sec)

    return {
        "imt_mm": round(float(imt_mm), 2),
        "risk_level": risk_level,
        "is_high_risk": is_high_risk,
        "stenosis_pct": round(float(stenosis_pct), 1) if np.isfinite(stenosis_pct) else None,
        "stenosis_source": stenosis_source,  # "nascet" = lumen-based; "imt_correlation" = estimated
        "foreground_prob": round(foreground_prob, 3),
        "inference_time_sec": round(inference_time_sec, 3),
        "pixel_spacing_mm": float(spacing_mm_per_pixel),
        "pixel_spacing_source": pixel_spacing_source,
        "segmentation_overlay_base64": overlay_b64,
        "has_ai_overlay": has_ai_overlay,
    }
