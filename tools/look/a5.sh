#!/bin/bash
# Art step A5: the ink pass on the draft street from the kit, the draft's outline against ink_air, at the five viewpoints
# under K05 (tests/look/a5.tscn), then a sheet (tests/look/out/a5_sheet.jpg). Usage: tools/look/a5.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG="$ROOT/tests/out/a5.log" TIMEOUT=180 ENGINE_ARGS="res://tests/look/a5.tscn" "$ROOT/tools/run_windowed.sh"
grep -E "^a5:|SHADER ERROR|SCRIPT ERROR|killed" "$ROOT/tests/out/a5.log"
"$ROOT/tools/py" "$ROOT/tools/look/a5_sheet.py"
