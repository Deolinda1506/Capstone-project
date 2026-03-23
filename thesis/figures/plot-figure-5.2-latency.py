#!/usr/bin/env python3
"""
Figure 5.2 — Inference latency over sequential requests.

Uses the six inference times that reproduce the production /latency snapshot:
  {"count":6,"mean_sec":6.639,"min_sec":5.894,"max_sec":8.167}

If you later have `samples_sec` from GET /latency, replace LATENCIES with that list.
"""
from __future__ import annotations

from pathlib import Path

# Reconstructs min, max, and mean of the reported n=6 sample (see CAROTIDCHECK §5.1.2).
LATENCIES_SEC = [5.894, 5.894, 6.2, 6.5, 7.18, 8.167]

OUT = Path(__file__).resolve().parent / "figure-5.2-inference-latency.png"


def main() -> None:
    import matplotlib.pyplot as plt

    n = len(LATENCIES_SEC)
    x = list(range(1, n + 1))

    fig, ax = plt.subplots(figsize=(8, 4.5), dpi=150)
    ax.plot(x, LATENCIES_SEC, marker="o", linewidth=2, markersize=8, color="#1a5f7a")
    ax.axhline(5.0, color="#c45c26", linestyle="--", linewidth=1.5, label="Design target (5 s)")
    ax.set_xlabel("Sequential inference request", fontsize=11)
    ax.set_ylabel("Inference time (seconds)", fontsize=11)
    ax.set_title("Figure 5.2 — Inference latency over time (CarotidCheck, Render production sample)", fontsize=12)
    ax.set_xticks(x)
    ax.set_ylim(0, max(LATENCIES_SEC) * 1.12)
    ax.grid(True, alpha=0.35)
    ax.legend(loc="upper right", fontsize=9)
    fig.text(
        0.5,
        0.02,
        "Series reconstructed from n=6 aggregate snapshot (mean ≈6.64 s, min 5.89 s, max 8.17 s). "
        "Replace with samples_sec from GET /latency when available.",
        ha="center",
        fontsize=7.5,
        color="#444444",
        style="italic",
    )
    plt.tight_layout()
    plt.subplots_adjust(bottom=0.18)
    fig.savefig(OUT, bbox_inches="tight")
    plt.close()
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
