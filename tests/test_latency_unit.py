"""Unit tests for latency stats (no FastAPI import)."""

from __future__ import annotations

import pytest

import backend.latency as lat


@pytest.fixture(autouse=True)
def clear_latency_samples():
    """Isolate tests that touch the in-process deque."""
    with lat._lock:
        lat._samples.clear()
    yield
    with lat._lock:
        lat._samples.clear()


def test_get_latency_stats_empty():
    out = lat.get_latency_stats()
    assert out["count"] == 0
    assert out["mean_sec"] is None
    assert out["min_sec"] is None
    assert out["max_sec"] is None
    assert out["samples_sec"] == []


def test_record_and_stats_round_trip():
    lat.record_inference_latency(1.0)
    lat.record_inference_latency(3.0)
    out = lat.get_latency_stats()
    assert out["count"] == 2
    assert out["mean_sec"] == 2.0
    assert out["min_sec"] == 1.0
    assert out["max_sec"] == 3.0
    assert out["samples_sec"] == [1.0, 3.0]


def test_record_ignores_invalid():
    lat.record_inference_latency(None)
    lat.record_inference_latency(-1.0)
    lat.record_inference_latency("bad")
    assert lat.get_latency_stats()["count"] == 0
