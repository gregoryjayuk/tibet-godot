#!/bin/bash
# Art step A8: the ridge shadow. The horizon map (tools/terrain/horizon.py, baked if missing), then the draft street set
# down at Tsongra from 15:50 to 16:30 (tests/look/a8.tscn), then the real valley from above the west bank from 15:30 to
# 17:00 (tools/terrain/s3.sh ridge), then one sheet: tests/look/out/a8_sheet.jpg. Usage: tools/look/a8.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if [ ! -f "$ROOT/assets/generated/terrain/horizon.json" ]; then (cd "$ROOT/tools/terrain" && nice -n 10 ../py horizon.py | tail -3); fi
LOG="$ROOT/tests/out/a8.log" TIMEOUT=240 ENGINE_ARGS="res://tests/look/a8.tscn" "$ROOT/tools/run_windowed.sh"
grep -E "^a8:|SHADER ERROR|SCRIPT ERROR|killed" "$ROOT/tests/out/a8.log"
"$ROOT/tools/terrain/s3.sh" ridge
"$ROOT/tools/py" "$ROOT/tools/look/a8_sheet.py"
