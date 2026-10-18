#!/bin/bash
# The third-person player on the kit street (tests/player/tp.tscn): stills to tests/player/out/. Usage: tools/player/tp.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if [ ! -f "$ROOT/assets/generated/people/player_man.glb" ]; then
  /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python "$ROOT/../tibet-blender/people2/stand_ins.py" -- player 2>&1 | grep "stand_ins:"
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path "$ROOT" --import >/dev/null 2>&1
fi
rm -f "$ROOT"/tests/player/out/tp_*.png
LOG="$ROOT/tests/out/tp.log" TIMEOUT=180 ENGINE_ARGS="res://tests/player/tp.tscn" "$ROOT/tools/run_windowed.sh"
grep -E "^tp:|SHADER ERROR|SCRIPT ERROR|killed" "$ROOT/tests/out/tp.log"
"$ROOT/tools/py" "$ROOT/tools/player/tp_sheet.py"
