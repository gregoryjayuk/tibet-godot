#!/bin/bash
# Art step A1: the Type B house at noon at 2, 20 and 50 m, weathering off and on (tests/look/a1.tscn), then a sheet
# pairing them (tests/look/out/a1_sheet.jpg). Usage: tools/look/a1.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG="$ROOT/tests/out/a1.log" TIMEOUT=120 ENGINE_ARGS="res://tests/look/a1.tscn" "$ROOT/tools/run_windowed.sh"
grep -E "^a1:|SHADER ERROR|SCRIPT ERROR|killed" "$ROOT/tests/out/a1.log" | grep -v "a1: shot"
"$ROOT/tools/py" "$ROOT/tools/look/a1_sheet.py"
