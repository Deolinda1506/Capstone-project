#!/usr/bin/env python3
"""
Rebuild thesis/figures/figure-5.3-risk-distribution.svg (+ .png) from the CarotidCheck database.

Uses DATABASE_URL from .env or environment; default is sqlite:///.../data/carotidcheck.db

Dependencies: python-dotenv, sqlalchemy (and psycopg2-binary for PostgreSQL URLs).

  pip install python-dotenv sqlalchemy psycopg2-binary
  PYTHONPATH=. python3 scripts/render_figure_5_3_from_db.py

  # When your thesis uses local SQLite but real data lives on Render Postgres, either set
  # DATABASE_URL to production or pass dashboard totals explicitly:
  PYTHONPATH=. python3 scripts/render_figure_5_3_from_db.py --low 2 --moderate 1 --high 6
"""
from __future__ import annotations

import argparse
import math
import os
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.chdir(ROOT)

from dotenv import load_dotenv  # noqa: E402

load_dotenv(ROOT / ".env")

FIG_DIR = ROOT / "thesis" / "figures"
SVG_OUT = FIG_DIR / "figure-5.3-risk-distribution.svg"
PNG_OUT = FIG_DIR / "figure-5.3-risk-distribution.png"


def fetch_counts() -> tuple[dict[str, int], int]:
    from sqlalchemy import func

    from backend.database import SessionLocal
    from backend.models import Result, Scan

    db = SessionLocal()
    try:
        rows = (
            db.query(Result.risk_level, func.count(Result.id))
            .join(Scan, Scan.id == Result.scan_id)
            .filter(Scan.is_deleted.is_(False))
            .group_by(Result.risk_level)
            .all()
        )
    finally:
        db.close()

    by_level = {"Low": 0, "Moderate": 0, "High": 0}
    for level, n in rows:
        k = (str(level) if level is not None else "").strip()
        if k in by_level:
            by_level[k] = int(n)
    total = sum(by_level.values())
    return by_level, total


def y_axis_max(m: int) -> int:
    if m <= 0:
        return 10  # empty chart: sensible scale (not 0–1, which looks like “one case”)
    if m <= 10:
        return max(5, math.ceil(m / 5) * 5)
    if m <= 50:
        return math.ceil(m / 10) * 10
    if m <= 200:
        return math.ceil(m / 25) * 25
    return math.ceil(m / 100) * 100


def build_svg(low: int, mod: int, high: int, total: int, *, footnote: str | None = None) -> str:
    ymax = y_axis_max(max(low, mod, high))
    plot_h = 260
    base_y = 360

    def bar_y_h(count: int) -> tuple[int, int]:
        if count <= 0:
            return base_y, 0
        h = max(2, int(round((count / ymax) * plot_h)))
        return base_y - h, h

    yl, hl = bar_y_h(low)
    ym, hm = bar_y_h(mod)
    yh, hh = bar_y_h(high)

    tick_vals = [int(round(ymax * i / 4)) for i in range(5)] if ymax > 0 else [0]
    tick_vals = sorted(set(tick_vals))
    tick_lines = []
    tick_labels = []
    for tv in tick_vals:
        yy = int(round(base_y - (tv / ymax) * plot_h)) if ymax else base_y
        tick_lines.append(f'    <line x1="80" y1="{yy}" x2="560" y2="{yy}" class="grid"/>')
        tick_labels.append(f'    <text x="72" y="{min(yy + 4, base_y + 4)}" text-anchor="end" class="axis">{tv}</text>')

    today = date.today().isoformat()
    title = "Figure 5.3 - Risk level distribution (CarotidCheck database)"
    if footnote:
        note = footnote
    elif total == 0:
        note = f"No analyses in database yet (n=0), {today}. Run uploads or set DATABASE_URL to production, or use --low/--moderate/--high from the dashboard. Thresholds: Low &lt;0.9 mm, Moderate 0.9-1.2 mm, High &gt;1.2 mm IMT."
    else:
        note = f"Source: stored analyses in database, total n={total}, generated {today}. Thresholds: Low &lt;0.9 mm, Moderate 0.9-1.2 mm, High &gt;1.2 mm IMT."

    # Count labels: above bar top, or mid-chart when bar height 0 (avoid overlap with category names)
    def count_label_y(bar_top_y: int, bar_h: int) -> int:
        if bar_h > 0:
            return bar_top_y - 6
        return 220

    label_low_y = count_label_y(yl, hl)
    label_mod_y = count_label_y(ym, hm)
    label_high_y = count_label_y(yh, hh)

    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 420" font-family="system-ui, Segoe UI, Helvetica, Arial, sans-serif">
  <defs>
    <style><![CDATA[
      .title {{ font-size: 15px; font-weight: 600; fill: #1a1a1a; }}
      .axis {{ font-size: 11px; fill: #333; }}
      .note {{ font-size: 9px; fill: #555; font-style: italic; }}
      .grid {{ stroke: #e8e8e8; stroke-width: 1; }}
      .bar-low {{ fill: #2e7d4a; }}
      .bar-mod {{ fill: #c9a227; }}
      .bar-high {{ fill: #b33a3a; }}
    ]]></style>
  </defs>
  <text x="320" y="30" text-anchor="middle" class="title">{title}</text>
  <line x1="80" y1="100" x2="80" y2="360" stroke="#333" stroke-width="1.5"/>
  <line x1="80" y1="360" x2="560" y2="360" stroke="#333" stroke-width="1.5"/>
{chr(10).join(tick_lines)}
{chr(10).join(tick_labels)}
  <text x="40" y="240" text-anchor="middle" class="axis" transform="rotate(-90 40 240)">Number of analyses</text>
  <rect x="110" y="{yl}" width="100" height="{hl}" class="bar-low" rx="4"/>
  <rect x="270" y="{ym}" width="100" height="{hm}" class="bar-mod" rx="4"/>
  <rect x="430" y="{yh}" width="100" height="{hh}" class="bar-high" rx="4"/>
  <text x="160" y="{label_low_y}" text-anchor="middle" class="axis" font-weight="600">{low}</text>
  <text x="320" y="{label_mod_y}" text-anchor="middle" class="axis" font-weight="600">{mod}</text>
  <text x="480" y="{label_high_y}" text-anchor="middle" class="axis" font-weight="600">{high}</text>
  <text x="160" y="392" text-anchor="middle" class="axis">Low</text>
  <text x="320" y="392" text-anchor="middle" class="axis">Moderate</text>
  <text x="480" y="392" text-anchor="middle" class="axis">High</text>
  <text x="320" y="404" text-anchor="middle" class="axis">Risk category (IMT thresholds)</text>
  <text x="320" y="416" text-anchor="middle" class="note">{note}</text>
</svg>
"""


def try_png() -> None:
    try:
        subprocess.run(
            ["qlmanage", "-t", "-s", "2400", "-o", str(FIG_DIR), str(SVG_OUT)],
            check=True,
            capture_output=True,
            text=True,
        )
        tmp = FIG_DIR / (SVG_OUT.name + ".png")
        if tmp.is_file():
            tmp.replace(PNG_OUT)
    except (FileNotFoundError, subprocess.CalledProcessError):
        pass


def main() -> int:
    parser = argparse.ArgumentParser(description="Build Figure 5.3 from DB or explicit counts.")
    parser.add_argument("--low", type=int, help="Override: Low count (use with --moderate and --high)")
    parser.add_argument("--moderate", type=int, help="Override: Moderate count")
    parser.add_argument("--high", type=int, help="Override: High count")
    args = parser.parse_args()

    FIG_DIR.mkdir(parents=True, exist_ok=True)
    manual = [args.low, args.moderate, args.high]
    if any(x is not None for x in manual):
        if any(x is None for x in manual):
            parser.error("With manual counts, pass all three: --low --moderate --high")
        low, mod, high = args.low, args.moderate, args.high
        total = low + mod + high
        today = date.today().isoformat()
        foot = (
            f"Counts match production dashboard totals (same as web Overview), total n={total}, {today}. "
            "Thresholds: Low &lt;0.9 mm, Moderate 0.9-1.2 mm, High &gt;1.2 mm IMT."
        )
        svg = build_svg(low, mod, high, total, footnote=foot)
        SVG_OUT.write_text(svg, encoding="utf-8")
        print(f"Wrote {SVG_OUT} (manual counts from CLI)")
        print(f"Low={low} Moderate={mod} High={high} total={total}")
        try_png()
        if PNG_OUT.is_file():
            print(f"Wrote {PNG_OUT}")
        return 0

    try:
        by_level, total = fetch_counts()
    except Exception as e:
        print(f"Database error: {e}", file=sys.stderr)
        print("Set DATABASE_URL to Render Postgres, or use: --low N --moderate N --high N", file=sys.stderr)
        return 1

    low, mod, high = by_level["Low"], by_level["Moderate"], by_level["High"]
    svg = build_svg(low, mod, high, total)
    SVG_OUT.write_text(svg, encoding="utf-8")
    print(f"Wrote {SVG_OUT}")
    print(f"Low={low} Moderate={mod} High={high} total={total}")
    try_png()
    if PNG_OUT.is_file():
        print(f"Wrote {PNG_OUT}")
    else:
        print("(PNG not generated: qlmanage unavailable; open SVG or export manually.)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
