#!/usr/bin/env bash
set -euo pipefail

INPUT_FILE="${1:-/Users/macbookpro2020m1/Capstone-project/thesis/figures/chapter-3-diagrams.md}"
OUT_DIR="${2:-/Users/macbookpro2020m1/Capstone-project/thesis/figures}"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Input file not found: $INPUT_FILE" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

extract_mermaid_block() {
  local input="$1"
  local index="$2"
  local output="$3"
  awk -v want="$index" '
    BEGIN { in_block=0; count=0 }
    /^```mermaid[[:space:]]*$/ { in_block=1; count++; next }
    /^```[[:space:]]*$/ { if (in_block) in_block=0; next }
    in_block && count==want { print }
  ' "$input" > "$output"
}

render_svg() {
  local input_mmd="$1"
  local output_svg="$2"
  npx -y @mermaid-js/mermaid-cli -i "$input_mmd" -o "$output_svg" -b transparent
}

render_png() {
  local input_mmd="$1"
  local output_png="$2"
  npx -y @mermaid-js/mermaid-cli -i "$input_mmd" -o "$output_png" -b transparent
}

MMD1="$TMP_DIR/figure-3.1.mmd"
MMD2="$TMP_DIR/figure-3.2.mmd"
MMD3="$TMP_DIR/figure-3.3.mmd"

extract_mermaid_block "$INPUT_FILE" 1 "$MMD1"
extract_mermaid_block "$INPUT_FILE" 2 "$MMD2"
extract_mermaid_block "$INPUT_FILE" 3 "$MMD3"

for f in "$MMD1" "$MMD2" "$MMD3"; do
  if [[ ! -s "$f" ]]; then
    echo "Failed to extract all three Mermaid blocks from: $INPUT_FILE" >&2
    exit 1
  fi
done

render_svg "$MMD1" "$OUT_DIR/figure-3.1.svg"
render_svg "$MMD2" "$OUT_DIR/figure-3.2.svg"
render_svg "$MMD3" "$OUT_DIR/figure-3.3.svg"

render_png "$MMD1" "$OUT_DIR/figure-3.1.png"
render_png "$MMD2" "$OUT_DIR/figure-3.2.png"
render_png "$MMD3" "$OUT_DIR/figure-3.3.png"

echo "Export complete:"
echo " - $OUT_DIR/figure-3.1.svg"
echo " - $OUT_DIR/figure-3.2.svg"
echo " - $OUT_DIR/figure-3.3.svg"
echo " - $OUT_DIR/figure-3.1.png"
echo " - $OUT_DIR/figure-3.2.png"
echo " - $OUT_DIR/figure-3.3.png"
