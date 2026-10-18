#!/bin/bash
# Spike S19, fists and the sling (tests/player/fight.tscn): the scripted sequence's stills to tests/player/out/fight_*.png,
# laid out on tests/player/out/fight_sheet.jpg.
# Usage: tools/player/fight.sh   (play it yourself: tools/play.sh fight)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
rm -f "$ROOT"/tests/player/out/fight_*.png
LOG="$ROOT/tests/out/fight.log" TIMEOUT=180 ENGINE_ARGS="res://tests/player/fight.tscn" "$ROOT/tools/run_windowed.sh"
grep -E "^fight:|SCRIPT ERROR|ERROR|killed" "$ROOT/tests/out/fight.log" | grep -v "Resource file not found: res://\|Error loading resource: ''"
"$ROOT/tools/py" "$ROOT/tools/player/fight_sheet.py"
