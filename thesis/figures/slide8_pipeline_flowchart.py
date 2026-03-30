"""
Slide 8 — Preprocessing & training pipeline (layout inspired by screening-data flowchart).
Run: python slide8_pipeline_flowchart.py
Requires: matplotlib
Outputs: slide8_pipeline_flowchart.png, slide8_pipeline_flowchart.svg
"""

from __future__ import annotations

import matplotlib.pyplot as plt
from matplotlib.patches import Circle, FancyBboxPatch, FancyArrowPatch, Polygon

# Colours (light purple / slate theme, similar to reference slide)
NODE_FILL = "#e8e4f0"
NODE_EDGE = "#4c3d6b"
ACCENT = "#6b5a8c"
DIAMOND_FILL = "#f0eef5"
TITLE = "#2d2640"


def rounded_box(ax, x, y, w, h, text, fontsize=7.5, facecolor=NODE_FILL):
    p = FancyBboxPatch(
        (x, y),
        w,
        h,
        boxstyle="round,pad=0.015,rounding_size=0.08",
        facecolor=facecolor,
        edgecolor=NODE_EDGE,
        linewidth=1.2,
    )
    ax.add_patch(p)
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fontsize, color=TITLE, wrap=True)


def diamond(ax, cx, cy, w, h, text, fontsize=7):
    hw, hh = w / 2, h / 2
    verts = [(cx, cy + hh), (cx + hw, cy), (cx, cy - hh), (cx - hw, cy)]
    poly = Polygon(verts, closed=True, facecolor=DIAMOND_FILL, edgecolor=NODE_EDGE, linewidth=1.2)
    ax.add_patch(poly)
    ax.text(cx, cy, text, ha="center", va="center", fontsize=fontsize, color=TITLE)


def arrow(ax, x1, y1, x2, y2):
    ax.add_patch(
        FancyArrowPatch(
            (x1, y1),
            (x2, y2),
            arrowstyle="-|>",
            mutation_scale=10,
            color=NODE_EDGE,
            linewidth=1.0,
            shrinkA=2,
            shrinkB=2,
        )
    )


def main():
    fig, ax = plt.subplots(figsize=(12.5, 6.2), dpi=150)
    ax.set_xlim(0, 12.5)
    ax.set_ylim(0, 6.2)
    ax.axis("off")
    fig.patch.set_facecolor("white")
    ax.set_facecolor("white")

    # Title banner
    ax.text(6.25, 5.85, "PREPROCESSING & TRAINING PIPELINE", ha="center", va="center", fontsize=12, fontweight="bold", color=TITLE)

    # Central circle (root)
    cx, cy, r = 1.15, 2.55, 0.55
    circ = Circle((cx, cy), r, facecolor=NODE_FILL, edgecolor=NODE_EDGE, linewidth=1.5)
    ax.add_patch(circ)
    ax.text(cx, cy, "CAROTID IMT\nMODEL\nTRAINING", ha="center", va="center", fontsize=7.5, fontweight="bold", color=TITLE)

    # Top branches (Overview | Rationale)
    rounded_box(ax, 0.15, 4.35, 2.0, 0.95, "Overview & statistics\n~1 100 pairs · 11 subjects\nExpert PNG masks", fontsize=6.8)
    rounded_box(ax, 2.45, 4.35, 2.0, 0.95, "Rationale\nSubject-aware split\nReproducibility (seed 42)", fontsize=6.8)

    arrow(ax, 1.15, 4.35, 1.15, 3.25)
    arrow(ax, 3.45, 4.35, 2.0, 3.05)

    # Main horizontal flow from circle to right
    y_main = 2.35
    h_box = 0.85

    # STEP 1
    rounded_box(ax, 2.05, y_main, 1.45, h_box, "STEP 1\nInput\nMomot image + mask", fontsize=6.8)
    arrow(ax, cx + r, cy, 2.05, y_main + h_box / 2)

    # STEP 2 — diamond: preprocessing
    d2x, d2y = 4.05, y_main + h_box / 2
    diamond(ax, d2x, d2y, 1.15, 0.75, "STEP 2\nNorm [0,1]\n256×256", fontsize=6.5)
    arrow(ax, 3.5, y_main + h_box / 2, d2x - 0.58, d2y)

    # STEP 3 — diamond: augmentation + split
    d3x = 5.95
    diamond(ax, d3x, d2y, 1.15, 0.75, "STEP 3\nAugment\n80/20 val", fontsize=6.5)
    arrow(ax, d2x + 0.58, d2y, d3x - 0.58, d2y)

    # STEP 4
    rounded_box(ax, 6.85, y_main, 1.35, h_box, "STEP 4\nTrain loop\nViT · Attn U-Net", fontsize=6.8)
    arrow(ax, d3x + 0.58, d2y, 6.85, y_main + h_box / 2)

    # STEP 5 — diamond: loss + optim
    d5x = 8.95
    diamond(ax, d5x, d2y, 1.2, 0.8, "STEP 5\nα·BCE+(1−α)·Dice\nAdam · cosine LR", fontsize=5.8)
    arrow(ax, 8.2, y_main + h_box / 2, d5x - 0.62, d2y)

    # FINAL OUTPUT
    rounded_box(ax, 10.15, y_main - 0.05, 1.95, 1.0, "FINAL OUTPUT\nAttentionViT / AttentionUNet\n.keras · CSV · TensorBoard", fontsize=6.5, facecolor="#ede9f5")
    arrow(ax, d5x + 0.62, d2y, 10.15, y_main + h_box / 2)

    # Validation-style box (bottom right)
    rounded_box(
        ax,
        7.85,
        0.35,
        4.25,
        1.15,
        "Validation: Momot val Dice / IoU · Early stopping on Dice\n"
        "Note: n=11 subjects → cautious generalisation claims",
        fontsize=6.8,
        facecolor="#f5f0fa",
    )

    out_base = __file__.replace(".py", "")
    plt.tight_layout()
    plt.savefig(out_base + ".png", bbox_inches="tight", facecolor="white")
    plt.savefig(out_base + ".svg", bbox_inches="tight", facecolor="white")
    print(f"Saved {out_base}.png and {out_base}.svg")


if __name__ == "__main__":
    main()
