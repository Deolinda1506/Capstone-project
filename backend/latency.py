"""Rolling inference latency samples for `/latency` stats (last 100 requests)."""
from __future__ import annotations

import threading
from collections import deque
from statistics import mean

_MAX_SAMPLES = 100

_samples: deque[float] = deque(maxlen=_MAX_SAMPLES)
_lock = threading.Lock()


def record_inference_latency(sec: float | None) -> None:
    if sec is None:
        return
    try:
        value = float(sec)
    except (TypeError, ValueError):
        return
    if value < 0:
        return
    with _lock:
        _samples.append(value)


def get_latency_stats() -> dict:
    with _lock:
        samples = list(_samples)
    if not samples:
        return {"count": 0, "mean_sec": None, "min_sec": None, "max_sec": None}
    return {
        "count": len(samples),
        "mean_sec": mean(samples),
        "min_sec": min(samples),
        "max_sec": max(samples),
    }
