#!/bin/bash
# Spike S5, the crowd (tests/perf/s5.tscn; roadmap RT-13). Builds the stand-ins if missing (../tibet-blender, people2/
# stand_ins.py), then runs the chosen modes in a window. Usage: tools/perf/s5.sh [perf|capped|shots|pop|all]
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODE="${1:-all}"
if [ ! -f "$ROOT/assets/generated/people/monk_vat.bin" ]; then
  /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python "$ROOT/../tibet-blender/people2/stand_ins.py" 2>&1 | grep "stand_ins:"
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path "$ROOT" --import >/dev/null 2>&1
fi
RUN="perf/runs/s5-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$ROOT/$RUN"
COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null)$(git -C "$ROOT" diff --quiet 2>/dev/null || echo +dirty)"
"$ROOT/tools/thermal/build.sh" >/dev/null
run() {  # name, engine args, game args
  TIMEOUT=300 ENGINE_ARGS="res://tests/perf/s5.tscn $2" LOG="$ROOT/$RUN/$1.log" "$ROOT/tools/run_windowed.sh" --run="$RUN" --commit="$COMMIT" $3
  grep -E "^s5:|ERROR|SCRIPT ERROR|killed" "$ROOT/$RUN/$1.log" | grep -v "Resource file not found: res://\|Error loading resource: ''"
}
case "$MODE" in shots|all) run shots "" "--shots" ;; esac
case "$MODE" in pop|all) run pop "" "--pop"; "$ROOT/tools/py" "$ROOT/tools/perf/s5_pop.py" ;; esac
# EXTRA (optional) goes to the game, e.g. EXTRA="--no-vat-shadows" to measure the VAT tier without shadows.
case "$MODE" in perf|all) FIXED_FPS=0 run perf "--disable-vsync" "--perf --uncapped ${EXTRA:-}" ;; esac
case "$MODE" in capped|all) FIXED_FPS=0 run capped "" "--capped ${EXTRA:-}" ;; esac
