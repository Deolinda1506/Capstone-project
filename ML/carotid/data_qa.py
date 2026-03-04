"""
Data quality assurance for carotid ultrasound dataset.
- Removal/flagging of bad images
- Mask consistency checks (non-empty, reasonable coverage, shape match)
- Handling of corrupted or invalid files
"""

from __future__ import annotations

from pathlib import Path
from typing import Dict, List, Optional, Tuple
import numpy as np
import cv2


def validate_image_readable(path: str | Path) -> Tuple[bool, Optional[str]]:
    """Check if image loads and is not corrupted. Returns (ok, error_msg)."""
    try:
        img = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
        if img is None:
            img = cv2.imread(str(path))
            if img is None:
                return False, "Failed to load image"
            img = img[:, :, 0] if img.ndim == 3 else img
        if img.size == 0 or img.ndim != 2:
            return False, f"Invalid shape: {getattr(img, 'shape', 'unknown')}"
        if np.all(img == img.flat[0]):
            return False, "Image is constant (possibly corrupted)"
        return True, None
    except Exception as e:
        return False, str(e)


def validate_mask_readable(path: str | Path) -> Tuple[bool, Optional[str]]:
    """Check if mask loads and is not corrupted. Returns (ok, error_msg)."""
    try:
        mask = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
        if mask is None:
            mask = cv2.imread(str(path))
            if mask is None:
                return False, "Failed to load mask"
            mask = mask[:, :, 0] if mask.ndim == 3 else mask
        if mask.size == 0 or mask.ndim != 2:
            return False, f"Invalid shape: {getattr(mask, 'shape', 'unknown')}"
        return True, None
    except Exception as e:
        return False, str(e)


def check_mask_consistency(
    mask: np.ndarray,
    img_shape: Optional[Tuple[int, int]] = None,
    min_coverage_pct: float = 0.001,
    max_coverage_pct: float = 0.95,
) -> Tuple[bool, Optional[str]]:
    """
    Mask consistency checks:
    - Non-empty (has foreground)
    - Reasonable coverage (not almost-empty or almost-full)
    - Shape matches image (if img_shape provided)
    Returns (ok, error_msg).
    """
    h, w = mask.shape
    if img_shape is not None and (h, w) != img_shape:
        return False, f"Mask shape {mask.shape} != image shape {img_shape}"
    foreground = np.sum(mask > 127) if mask.dtype in (np.float32, np.float64) else np.sum(mask > 0)
    total = h * w
    coverage = foreground / total
    if coverage < min_coverage_pct:
        return False, f"Mask nearly empty (coverage={coverage:.4f})"
    if coverage > max_coverage_pct:
        return False, f"Mask nearly full (coverage={coverage:.4f})"
    return True, None


def validate_pair(
    img_path: str | Path,
    mask_path: str | Path,
    min_coverage_pct: float = 0.001,
    max_coverage_pct: float = 0.95,
    require_shape_match: bool = True,
) -> Tuple[bool, Optional[str]]:
    """
    Validate image/mask pair: readability + consistency.
    Returns (ok, error_msg).
    """
    ok, err = validate_image_readable(img_path)
    if not ok:
        return False, f"Image: {err}"
    img = cv2.imread(str(img_path), cv2.IMREAD_GRAYSCALE)
    if img is None:
        img = cv2.imread(str(img_path))[:, :, 0]
    img_shape = img.shape[:2]

    ok, err = validate_mask_readable(mask_path)
    if not ok:
        return False, f"Mask: {err}"
    mask = cv2.imread(str(mask_path), cv2.IMREAD_GRAYSCALE)
    if mask is None:
        mask = cv2.imread(str(mask_path))[:, :, 0]

    ok, err = check_mask_consistency(
        mask,
        img_shape=img_shape if require_shape_match else None,
        min_coverage_pct=min_coverage_pct,
        max_coverage_pct=max_coverage_pct,
    )
    if not ok:
        return False, err
    return True, None


def filter_and_flag_pairs(
    pairs: List[Tuple[str, str]],
    min_coverage_pct: float = 0.001,
    max_coverage_pct: float = 0.95,
) -> Tuple[List[Tuple[str, str]], List[Dict]]:
    """
    Validate all pairs; keep valid, flag invalid with reason.
    Returns (valid_pairs, flagged_list).
    flagged_list: [{"img": ..., "mask": ..., "reason": ...}, ...]
    """
    valid = []
    flagged = []
    for img_path, mask_path in pairs:
        ok, err = validate_pair(
            img_path,
            mask_path,
            min_coverage_pct=min_coverage_pct,
            max_coverage_pct=max_coverage_pct,
        )
        if ok:
            valid.append((img_path, mask_path))
        else:
            flagged.append({"img": img_path, "mask": mask_path, "reason": err})
    return valid, flagged
