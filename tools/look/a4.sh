#!/bin/bash
# Art step A4: painted gold on the draft street's gilded roofs, under K05 and K08, before and after (tests/look/a4.tscn),
# then a sheet (tests/look/out/a4_sheet.jpg). Usage: tools/look/a4.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG="$ROOT/tests/out/a4.log" TIMEOUT=180 ENGINE_ARGS="res://tests/look/a4.tscn" "$ROOT/tools/run_windowed.sh"
grep -E "^a4:|SHADER ERROR|SCRIPT ERROR|killed" "$ROOT/tests/out/a4.log"
"$ROOT/tools/py" "$ROOT/tools/look/a4_sheet.py"
