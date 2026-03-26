"""Optional ML integration: real Attention U-Net checkpoint + one forward pass.

Skipped automatically when ML/AttentionUNet.keras is missing (e.g. shallow clone without LFS).

Quick CI / unit-only runs:
  pytest tests/ -m "not ml"

Run ML tests explicitly:
  pytest tests/ -m ml
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parent.parent
MODEL_PATH = ROOT / "ML" / "AttentionUNet.keras"


def _model_on_disk() -> bool:
    return MODEL_PATH.is_file()


@pytest.mark.ml
@pytest.mark.skipif(not _model_on_disk(), reason=f"No checkpoint at {MODEL_PATH} (skip or add model file)")
def test_attention_unet_loads_and_forward_pass():
    """End-to-end smoke: load_model() + batch (1,256,256,3) produces a mask tensor."""
    import backend.inference as inf

    inf.model = None
    m = inf.load_model()
    assert m is not None

    x = np.zeros((1, 256, 256, 3), dtype=np.float32)
    out = m.predict(x, verbose=0)
    assert out.ndim >= 2
    assert out.shape[0] == 1


@pytest.mark.ml
@pytest.mark.skipif(not _model_on_disk(), reason=f"No checkpoint at {MODEL_PATH}")
def test_predict_imt_pipeline_real_model(minimal_png_bytes: bytes):
    """Full predict_imt on a tiny PNG using the real model (may be Unknown if mask too small)."""
    import backend.inference as inf

    inf.model = None
    result = inf.predict_imt(
        minimal_png_bytes,
        spacing_mm_per_pixel=inf.DEFAULT_SPACING_MM_PER_PIXEL,
        return_segmentation_overlay=False,
        patient_age=None,
    )
    assert "risk_level" in result
    assert "inference_time_sec" in result
    assert result["risk_level"] in ("Low", "Moderate", "High", "Unknown")
    # Real model may fail structural check on a blank 64×64 PNG — still a valid pipeline response
    assert "success" in result
