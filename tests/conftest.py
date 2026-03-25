"""Pytest configuration: project root on sys.path, shared fixtures."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


@pytest.fixture
def minimal_png_bytes() -> bytes:
    """Tiny valid PNG for cv2.imdecode (predict_imt preprocessing)."""
    import cv2

    img = np.zeros((64, 64, 3), dtype=np.uint8)
    ok, buf = cv2.imencode(".png", img)
    assert ok
    return buf.tobytes()
