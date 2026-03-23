"""Lightweight in-process observability helpers (no external deps)."""
from __future__ import annotations

import threading
import time
from collections import defaultdict, deque

_lock = threading.Lock()
_request_count = 0
_error_count = 0
_latency_ms = deque(maxlen=500)
_status_counts: dict[str, int] = defaultdict(int)
_path_counts: dict[str, int] = defaultdict(int)
_started_at = time.time()


def record_request(path: str, status_code: int, elapsed_ms: float) -> None:
    global _request_count, _error_count
    code = int(status_code)
    p = (path or "").strip() or "/"
    with _lock:
        _request_count += 1
        if code >= 500:
            _error_count += 1
        _latency_ms.append(float(elapsed_ms))
        _status_counts[str(code)] += 1
        _path_counts[p] += 1


def snapshot() -> dict:
    with _lock:
        count = _request_count
        lat = list(_latency_ms)
        statuses = dict(_status_counts)
        top_paths = sorted(_path_counts.items(), key=lambda kv: kv[1], reverse=True)[:20]
        uptime = max(0.0, time.time() - _started_at)
    avg = (sum(lat) / len(lat)) if lat else 0.0
    p95 = sorted(lat)[int(0.95 * (len(lat) - 1))] if lat else 0.0
    err_rate = (_error_count / count) if count else 0.0
    return {
        "uptime_sec": round(uptime, 2),
        "requests_total": count,
        "errors_5xx_total": _error_count,
        "error_rate": round(err_rate, 4),
        "latency_ms_avg": round(avg, 2),
        "latency_ms_p95": round(p95, 2),
        "status_counts": statuses,
        "top_paths": [{"path": p, "count": c} for p, c in top_paths],
    }
