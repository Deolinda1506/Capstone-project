"""
Inference-time image preprocessing: CLAHE + DWT (matches ML/carotid and training).
Used so backend inference matches the training pipeline.
"""
from __future__ import annotations

import numpy as np
import cv2
import pywt
from typing import Tuple


def _clahe(img: np.ndarray, clip_limit: float = 2.0, grid_size: Tuple[int, int] = (8, 8)) -> np.ndarray:
    img = np.asarray(img, dtype=np.float64)
    if img.max() > 1.0:
        img = img / (img.max() + 1e-8)
    u8 = (np.clip(img, 0, 1) * 255).astype(np.uint8)
    clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=grid_size)
    out = clahe.apply(u8)
    return out.astype(np.float64) / 255.0


def _dwt_denoise_2d(img: np.ndarray, wavelet: str = "db4", level: int = 1, mode: str = "soft") -> np.ndarray:
    coeffs = pywt.wavedec2(img, wavelet, level=level)
    cA = coeffs[0]
    detail_list = list(coeffs[1:])
    sigma = np.median(np.abs(cA)) / 0.6745 if cA.size else 1.0
    thresh_arg = max(1.0, cA.size)
    thresh = 1.0 * sigma * np.sqrt(2 * np.log(thresh_arg))
    detail_list = [
        tuple(
            pywt.threshold(d, thresh, mode=mode) if d is not None else None
            for d in level_coeffs
        )
        for level_coeffs in detail_list
    ]
    return pywt.waverec2([cA] + detail_list, wavelet)[: img.shape[0], : img.shape[1]]


def preprocess_for_inference(
    img: np.ndarray,
    apply_clahe: bool = True,
    apply_dwt: bool = False,
) -> np.ndarray:
    """
    Apply CLAHE and optionally DWT to a grayscale image (H, W).
    Returns float32 in [0, 1]. Matches ML/carotid/preprocessing.py defaults.
    """
    out = np.asarray(img, dtype=np.float64)
    if out.max() > 1.0:
        out = out / (out.max() + 1e-8)
    if apply_clahe:
        out = _clahe(out)
    if apply_dwt:
        out = _dwt_denoise_2d(out)
    return np.clip(out, 0, 1).astype(np.float32)
