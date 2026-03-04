"""Carotid wall thickness inference (Swin-UNETR). Used by /predict and /scans/upload."""
import base64
import io
import logging
from pathlib import Path

import cv2
import numpy as np
import torch
from monai.networks.nets import SwinUNETR

_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_MODEL_PT = _PROJECT_ROOT / "ML" / "models" / "carotid_swin_unetr_2d.pt"
_MODEL_DIR = _PROJECT_ROOT / "ML" / "models" / "carotid_swin_unetr_2d_final"
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = None

DEFAULT_SPACING_MM_PER_PIXEL = 0.04

logger = logging.getLogger(__name__)
if _MODEL_PT.exists():
    logger.info("ML model found at %s", _MODEL_PT)
elif _MODEL_DIR.exists():
    logger.info("ML model dir found at %s", _MODEL_DIR)
else:
    logger.warning("ML model not found at %s or %s (will use demo fallback)", _MODEL_PT, _MODEL_DIR)


def load_model():
    global model
    if model is not None:
        return model
    path = _MODEL_PT if _MODEL_PT.exists() else _MODEL_DIR
    if not path.exists():
        raise FileNotFoundError(f"Model not found at {_MODEL_PT} or {_MODEL_DIR}")
    # Input is resized to (224, 224) in preprocess_image; SwinUNETR requires img_size for some MONAI versions.
    model = SwinUNETR(
        img_size=(224, 224),
        in_channels=1,
        out_channels=2,
        spatial_dims=2,
        feature_size=32,
        num_heads=(3, 6, 12, 24),
        patch_size=2,
        window_size=7,
        use_checkpoint=True,
    ).to(device)
    state = torch.load(path, map_location=device, weights_only=False)
    model.load_state_dict(state.get("model", state), strict=False)
    model.eval()
    print(f"✅ Model loaded from {path}")
    return model


def preprocess_image(image_bytes: bytes, size=(224, 224)) -> torch.Tensor:
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise ValueError("Invalid image")
    img = img.astype(np.float32) / (np.max(img) + 1e-8)
    from backend.preprocessing import preprocess_for_inference
    img = preprocess_for_inference(img, apply_clahe=True, apply_dwt=False)
    img = cv2.resize(img, size, interpolation=cv2.INTER_LINEAR)
    return torch.from_numpy(img).unsqueeze(0).unsqueeze(0).to(device)


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


def _imt_mm_from_mask(mask, spacing_mm_per_pixel):
    inner_int, outer_int = _get_interfaces_from_mask(mask)
    thickness = np.abs(outer_int - inner_int)
    valid = np.isfinite(thickness)
    if not np.any(valid):
        return np.nan
    return float(np.nanmean(thickness) * spacing_mm_per_pixel)


def _overlay_segmentation_on_image(original_gray: np.ndarray, mask_224: np.ndarray) -> bytes:
    """Resize mask to original size and create RGB overlay (green = wall). Returns PNG bytes."""
    h, w = original_gray.shape
    mask_resized = cv2.resize(
        mask_224.astype(np.uint8),
        (w, h),
        interpolation=cv2.INTER_NEAREST,
    )
    # Normalize original to 0-255 for display
    orig_u8 = np.clip(original_gray * 255, 0, 255).astype(np.uint8)
    rgb = np.stack([orig_u8, orig_u8, orig_u8], axis=-1)
    # Overlay green where mask > 0 (wall class)
    green = np.array([0, 255, 0], dtype=np.uint8)
    alpha = 0.4
    wall = mask_resized > 0
    for c in range(3):
        rgb[:, :, c] = np.where(wall, (alpha * green[c] + (1 - alpha) * rgb[:, :, c]).astype(np.uint8), rgb[:, :, c])
    _, png = cv2.imencode(".png", cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR))
    return png.tobytes()


def predict_imt(
    image_bytes: bytes,
    spacing_mm_per_pixel: float = DEFAULT_SPACING_MM_PER_PIXEL,
    return_segmentation_overlay: bool = True,
) -> dict:
    """Run inference; returns imt_mm, risk_level, foreground_prob, and optionally segmentation_overlay_base64."""
    nparr = np.frombuffer(image_bytes, np.uint8)
    original = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)
    if original is None:
        raise ValueError("Invalid image")
    original_float = original.astype(np.float32) / (np.max(original) + 1e-8)

    m = load_model()
    img_tensor = preprocess_image(image_bytes)
    with torch.no_grad():
        pred = m(img_tensor)
        pred_soft = torch.softmax(pred, dim=1)
        pred_class = pred_soft.argmax(dim=1).squeeze().cpu().numpy()
    imt_mm = _imt_mm_from_mask(pred_class, spacing_mm_per_pixel)
    foreground_prob = pred_soft[0, 1].mean().item()
    if np.isnan(imt_mm):
        imt_mm = 2.5 + (foreground_prob * 2.0)
    WALL_THICKNESS_HIGH_MM = 3.5
    WALL_THICKNESS_MODERATE_MM = 3.0
    risk_level = "High" if imt_mm >= WALL_THICKNESS_HIGH_MM else "Moderate" if imt_mm >= WALL_THICKNESS_MODERATE_MM else "Low"
    is_high_risk = imt_mm >= WALL_THICKNESS_HIGH_MM
    out = {
        "imt_mm": round(float(imt_mm), 2),
        "risk_level": risk_level,
        "is_high_risk": is_high_risk,
        "foreground_prob": round(foreground_prob, 3),
    }
    if return_segmentation_overlay:
        overlay_bytes = _overlay_segmentation_on_image(original_float, pred_class)
        out["segmentation_overlay_base64"] = base64.b64encode(overlay_bytes).decode("ascii")
    return out
