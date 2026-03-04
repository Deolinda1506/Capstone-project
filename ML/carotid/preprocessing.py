"""
Medical imaging preprocessing for carotid artery ultrasound.
CLAHE for localized contrast enhancement + DWT denoising to preserve intima-media boundaries.
"""

from __future__ import annotations

import numpy as np
from typing import Tuple, Optional, Union
import cv2
import pywt


class MedicalDataCleaner:
    """
    Preprocessing for carotid ultrasound: CLAHE + DWT denoising.
    Preserves intima-media boundaries while reducing speckle noise.
    """

    def __init__(
        self,
        clahe_clip_limit: float = 2.0,
        clahe_grid_size: Tuple[int, int] = (8, 8),
        dwt_wavelet: str = "db4",
        dwt_level: int = 1,
        dwt_mode: str = "soft",
        dwt_threshold_scale: float = 1.0,
    ):
        self.clahe_clip_limit = clahe_clip_limit
        self.clahe_grid_size = clahe_grid_size
        self.dwt_wavelet = dwt_wavelet
        self.dwt_level = dwt_level
        self.dwt_mode = dwt_mode
        self.dwt_threshold_scale = dwt_threshold_scale

    def _clahe(self, img: np.ndarray) -> np.ndarray:
        """Apply CLAHE for localized contrast enhancement."""
        img = np.asarray(img, dtype=np.float64)
        if img.max() > 1.0:
            img = img / (img.max() + 1e-8)
        img_uint8 = (np.clip(img, 0, 1) * 255).astype(np.uint8)
        clahe = cv2.createCLAHE(
            clipLimit=self.clahe_clip_limit,
            tileGridSize=self.clahe_grid_size,
        )
        if img_uint8.ndim == 2:
            out = clahe.apply(img_uint8)
        else:
            out = cv2.cvtColor(img_uint8, cv2.COLOR_RGB2LAB)
            out[..., 0] = clahe.apply(out[..., 0])
            out = cv2.cvtColor(out, cv2.COLOR_LAB2RGB)
        return out.astype(np.float64) / 255.0

    def _dwt_denoise(self, img: np.ndarray) -> np.ndarray:
        """
        DWT denoising block: remove speckle while preserving edges (intima-media).
        Uses discrete wavelet transform, threshold detail coefficients, reconstruct.
        """
        img = np.asarray(img, dtype=np.float64)
        if img.ndim == 3:
            out = np.zeros_like(img)
            for c in range(img.shape[-1]):
                out[..., c] = self._dwt_denoise_2d(img[..., c])
            return out
        return self._dwt_denoise_2d(img)

    def _dwt_denoise_2d(self, img: np.ndarray) -> np.ndarray:
        """Single-channel 2D DWT denoising."""
        # Multilevel decomposition
        coeffs = pywt.wavedec2(img, self.dwt_wavelet, level=self.dwt_level)
        # coeffs: [cA_n, (cH_n, cV_n, cD_n), ..., (cH_1, cV_1, cD_1)]
        cA = coeffs[0]
        detail_list = list(coeffs[1:])
        # Universal threshold on detail coefficients (soft thresholding)
        sigma = np.median(np.abs(cA)) / 0.6745 if cA.size else 1.0
        thresh_arg = max(1.0, cA.size)
        thresh = self.dwt_threshold_scale * sigma * np.sqrt(2 * np.log(thresh_arg))
        detail_list = [
            tuple(
                pywt.threshold(d, thresh, mode=self.dwt_mode) if d is not None else None
                for d in level
            )
            for level in detail_list
        ]
        new_coeffs = [cA] + detail_list
        return pywt.waverec2(new_coeffs, self.dwt_wavelet)[: img.shape[0], : img.shape[1]]

    def __call__(
        self,
        img: np.ndarray,
        apply_clahe: bool = True,
        apply_dwt: bool = False,
    ) -> np.ndarray:
        """
        Clean image: optional CLAHE then DWT denoising.
        img: (H, W) or (H, W, C), float [0,1] or uint8.
        """
        out = np.asarray(img, dtype=np.float64)
        if out.max() > 1.0:
            out = out / (out.max() + 1e-8)
        if apply_clahe:
            out = self._clahe(out)
        if apply_dwt:
            out = self._dwt_denoise(out)
        return np.clip(out, 0, 1).astype(np.float32)
