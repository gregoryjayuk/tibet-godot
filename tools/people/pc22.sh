#!/bin/bash
# PC-22 (plan chapter 09): the townspeople's silhouettes at 40 m in grey (tests/people/pc22.gd), then the sheet:
# tests/people/out/pc22_sheet.jpg, the 40 m view greyed and enlarged beside the 10 m view in colour.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RETURN_FOCUS="${RETURN_FOCUS:-0}" TIMEOUT=200 ENGINE_ARGS="res://tests/people/pc22.tscn" "$ROOT/tools/run_windowed.sh"
grep -E "^pc22:|SCRIPT ERROR" "$ROOT/tests/out/last_run.log"
"$ROOT/tools/py" "$ROOT/tools/people/pc22_sheet.py"
