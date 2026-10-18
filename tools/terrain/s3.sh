#!/bin/bash
# Spike S3, Terrain3D on Metal (tests/terrain/s3.tscn; roadmap RT-12). Builds the terrain data if missing, then runs
# the chosen modes in a window: shots (stills to tests/terrain/out/), perf (uncapped, summaries to perf/history.csv),
# walk (the player on the terrain's collision), ridge (art step A8's stills). Usage: tools/terrain/s3.sh [shots|perf|walk|ridge|all]; EXTRA=... for perf variants
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODE="${1:-all}"
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
if [ ! -f "$ROOT/assets/generated/terrain/valley_t3d.r32" ]; then "$ROOT/tools/py" "$ROOT/tools/terrain/export_t3d.py"; fi
if [ ! -d "$ROOT/world/terrain/t3d" ]; then "$GODOT" --headless --path "$ROOT" --script tools/terrain/import_t3d.gd 2>&1 | grep "import_t3d"; fi
RUN="perf/runs/s3-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$ROOT/$RUN"
COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null)$(git -C "$ROOT" diff --quiet 2>/dev/null || echo +dirty)"
"$ROOT/tools/thermal/build.sh" >/dev/null
run() {  # name, engine args, game args
  TIMEOUT=240 ENGINE_ARGS="res://tests/terrain/s3.tscn $2" LOG="$ROOT/$RUN/$1.log" "$ROOT/tools/run_windowed.sh" --run="$RUN" --commit="$COMMIT" $3
  grep -E "^s3:|ERROR|SCRIPT ERROR|killed" "$ROOT/$RUN/$1.log" | grep -v "Resource file not found: res://\|Error loading resource: ''"  # Terrain3D's own (ISS-030)
}
case "$MODE" in shots|all) run shots "" "--shots"; "$ROOT/tools/py" "$ROOT/tools/terrain/s3_sheet.py" ;; esac
case "$MODE" in walk|all) run walk "" "--walk" ;; esac
# ridge (not in all): art step A8, the ridge shadow crossing the valley at the moments round the town's last sun.
case "$MODE" in ridge) run ridge "" "--ridge" ;; esac
# EXTRA (optional) goes to the game, e.g. EXTRA="--off=t3d_shadows --mesh-size=32" for a perf variant.
case "$MODE" in perf|all) FIXED_FPS=0 run perf "--disable-vsync" "--perf --uncapped ${EXTRA:-}" ;; esac
