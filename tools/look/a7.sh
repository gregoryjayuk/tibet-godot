#!/bin/bash
# Art step A7: the whole day on the draft street from the kit, thirteen moments from 04:30 to 01:00 from the street and
# from above (tests/look/a7.tscn), then two sheets (tests/look/out/a7_street.jpg, a7_above.jpg). Usage: tools/look/a7.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG="$ROOT/tests/out/a7.log" TIMEOUT=240 ENGINE_ARGS="res://tests/look/a7.tscn" "$ROOT/tools/run_windowed.sh"
grep -E "^a7:|SHADER ERROR|SCRIPT ERROR|killed" "$ROOT/tests/out/a7.log"
"$ROOT/tools/py" "$ROOT/tools/look/a7_sheet.py"
