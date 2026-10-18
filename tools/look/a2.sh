#!/bin/bash
# Art step A2: the draft street from the kit at viewpoints 1-3 under K05 and K08, M0's light and M1's
# (tests/look/a2.tscn), then a sheet (tests/look/out/a2_sheet.jpg). Usage: tools/look/a2.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG="$ROOT/tests/out/a2.log" TIMEOUT=180 ENGINE_ARGS="res://tests/look/a2.tscn" "$ROOT/tools/run_windowed.sh"
grep -E "^a2:|SHADER ERROR|SCRIPT ERROR|killed" "$ROOT/tests/out/a2.log"
"$ROOT/tools/py" "$ROOT/tools/look/a2_sheet.py"
