#!/bin/bash
# Spike S4 end to end: bake with Pillow + raqm, render every row and route in Godot, then build the contact sheets.
# Output for Greg: tests/text/out/sheets/all.png and one sheet per row.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
tools/py tools/text/bake_text.py tests/text/strings.json tests/text/out/baked || exit 1
ENGINE_ARGS="res://tests/text/shaping_test.tscn" LOG="$ROOT/tests/out/s4.log" tools/run_windowed.sh
grep -E "^s4:|ERROR" tests/out/s4.log
tools/py tools/text/contact_sheet.py
