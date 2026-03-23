#!/usr/bin/env python3
"""
Print risk-level counts from the CarotidCheck database (same logic as GET /scans/risk-distribution).

Usage (from repo root, with backend deps available):
  cd /path/to/Capstone-project
  PYTHONPATH=. python3 scripts/export_risk_distribution.py

Uses DATABASE_URL from the environment (see backend/.env or Render config).
For SQLite dev default, run from machine that has data/carotidcheck.db populated.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

os.chdir(ROOT)

from sqlalchemy import func  # noqa: E402

from backend.database import SessionLocal  # noqa: E402
from backend.models import Patient, Result, Scan  # noqa: E402


def counts_all_patients():
    db = SessionLocal()
    try:
        rows = (
            db.query(Result.risk_level, func.count(Result.id))
            .join(Scan, Scan.id == Result.scan_id)
            .filter(Scan.is_deleted == False)
            .group_by(Result.risk_level)
            .all()
        )
        by_level = {"Low": 0, "Moderate": 0, "High": 0}
        for level, n in rows:
            k = (level or "").strip()
            if k in by_level:
                by_level[k] = int(n)
        return {"total": sum(by_level.values()), "by_risk_level": by_level, "scope": "all_patients"}
    finally:
        db.close()


def main():
    data = counts_all_patients()
    print(json.dumps(data, indent=2))
    b = data["by_risk_level"]
    print(
        "\nFor Figure 5.3 (thesis): Low={}, Moderate={}, High={}, total={}".format(
            b["Low"], b["Moderate"], b["High"], data["total"]
        ),
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
