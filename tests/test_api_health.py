"""
API smoke tests via TestClient (runs FastAPI lifespan: DB init + optional model preload).

Requires Python 3.10+ (Pydantic v2 + PEP 604 unions in backend schemas). Render uses 3.11.

Skip with: pytest tests/ -m "not api"   (if you add marker)
"""

from __future__ import annotations

import sys

import pytest

if sys.version_info < (3, 10):
    pytest.skip(
        "test_api_health requires Python 3.10+ (run: python3.11 -m pytest tests/test_api_health.py)",
        allow_module_level=True,
    )

from fastapi.testclient import TestClient


@pytest.fixture(scope="module")
def client() -> TestClient:
    from backend.main import app

    with TestClient(app) as c:
        yield c


def test_root(client: TestClient):
    r = client.get("/")
    assert r.status_code == 200
    data = r.json()
    assert "CarotidCheck" in data.get("message", "")
    assert data.get("docs") == "/docs"


def test_health(client: TestClient):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_latency_shape(client: TestClient):
    r = client.get("/latency")
    assert r.status_code == 200
    body = r.json()
    assert "count" in body
    assert "samples_sec" in body
    assert isinstance(body["samples_sec"], list)
