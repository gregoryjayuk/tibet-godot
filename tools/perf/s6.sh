#!/bin/bash
# Spikes S6 and S18, streaming and tiers (tests/perf/s6.tscn; roadmap RT-14). Builds the test cells and chapel if
# missing, then runs the chosen modes in a window at the 30 fps cap. Usage: tools/perf/s6.sh [stream|tiers|shots|all]
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODE="${1:-all}"
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
[ -f "$ROOT/world/cells/c_0_0.scn" ] || "$GODOT" --headless --path "$ROOT" --script tools/build/make_test_cells.gd 2>&1 | grep make_test_cells
[ -f "$ROOT/interiors/test/chapel.tscn" ] || "$GODOT" --headless --path "$ROOT" --script tools/build/make_test_chapel.gd 2>&1 | grep make_test_chapel
RUN="perf/runs/s6-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$ROOT/$RUN"
COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null)$(git -C "$ROOT" diff --quiet 2>/dev/null || echo +dirty)"
"$ROOT/tools/thermal/build.sh" >/dev/null
run() {  # name, game args
  FIXED_FPS=0 TIMEOUT=400 ENGINE_ARGS="res://tests/perf/s6.tscn" LOG="$ROOT/$RUN/$1.log" "$ROOT/tools/run_windowed.sh" --run="$RUN" --commit="$COMMIT" $2
  grep -E "^s6:|ERROR|SCRIPT ERROR|killed" "$ROOT/$RUN/$1.log" | grep -v "Resource file not found: res://\|Error loading resource: ''"
}
case "$MODE" in shots|all) run shots "--shots" ;; esac
case "$MODE" in stream|all) run stream "--stream" ;; esac
case "$MODE" in tiers|all) run tiers "--tiers" ;; esac
