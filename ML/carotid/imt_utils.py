"""
Wall thickness calculation from segmentation masks (binary: 0=background, >0=foreground).
Matches Deolinda_F28_Untitled38.ipynb: total wall thickness from inner/outer interfaces.
"""

from __future__ import annotations

import numpy as np
from typing import Tuple


def get_interfaces_from_mask(mask: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    """
    Extract inner and outer interfaces from a binary segmentation mask (0=background, >0=foreground).
    Interprets the foreground as the entire vessel wall complex.

    Args:
        mask: (H, W) binary segmentation mask. 0=background, >0=foreground.

    Returns:
        inner_interface: (W,) array of Y-coordinates for the inner boundary of the foreground
        outer_interface: (W,) array of Y-coordinates for the outer boundary of the foreground
    """
    h, w = mask.shape
    inner_interface = np.full(w, np.nan)
    outer_interface = np.full(w, np.nan)

    for x in range(w):
        foreground_y_indices = np.where(mask[:, x] > 0)[0]
        if len(foreground_y_indices) > 0:
            inner_interface[x] = float(np.min(foreground_y_indices))
            outer_interface[x] = float(np.max(foreground_y_indices))

    return inner_interface, outer_interface


def imt_pixels_per_column(
    inner_interface: np.ndarray,
    outer_interface: np.ndarray,
) -> np.ndarray:
    """Calculate vertical distance in pixels between interfaces."""
    valid = np.isfinite(inner_interface) & np.isfinite(outer_interface)
    thickness = np.abs(outer_interface - inner_interface)
    thickness[~valid] = np.nan
    return thickness


def imt_mm_from_mask(mask: np.ndarray, spacing_mm_per_pixel: float) -> float:
    """
    Calculate mean wall thickness in mm from segmentation mask.
    """
    inner_int, outer_int = get_interfaces_from_mask(mask)
    thickness_px = imt_pixels_per_column(inner_int, outer_int)
    valid = np.isfinite(thickness_px)
    if not np.any(valid):
        return np.nan
    return float(np.nanmean(thickness_px) * spacing_mm_per_pixel)


def imt_mae_mm(
    pred_masks: np.ndarray,
    true_masks: np.ndarray,
    spacing_mm_per_pixel: float,
) -> float:
    """Calculate mean absolute error of wall thickness (mm) across a batch."""
    errors = []
    for pred, true in zip(pred_masks, true_masks):
        pred_imt = imt_mm_from_mask(pred, spacing_mm_per_pixel)
        true_imt = imt_mm_from_mask(true, spacing_mm_per_pixel)
        if np.isfinite(pred_imt) and np.isfinite(true_imt):
            errors.append(abs(pred_imt - true_imt))
    return float(np.mean(errors)) if errors else np.nan
