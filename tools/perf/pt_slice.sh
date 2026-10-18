#!/bin/bash
# The performance route PT-slice (plan chapter 12, 4.2; chapter 11, 19.7; M1 sprint 4, step 7): the Yak Gate to Tsongra,
# up the Sky Stair to the Mani Lhakhang, the Rooftop Way to V-28 and a turn there, at 17:05 with the townspeople and the
# sang's smoke (tests/terrain/s3.gd --pt-slice), on QT-BAL (the 3D at 1080p). Passes: capped (30 fps: does 30 hold, with
# a 1% low of 25) and uncapped (vsync off: the GPU's cost). CSVs and logs in perf/runs/<stamp>/, the summaries in
# perf/history.csv. About six minutes capped and four uncapped.
# Usage: tools/perf/pt_slice.sh [capped|uncapped|both]   (default both)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODE="${1:-both}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="perf/runs/$STAMP"
COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo none)$(git -C "$ROOT" diff --quiet 2>/dev/null || echo +dirty)"
if "$ROOT/tools/perf/screen_locked.py"; then  # a locked screen throttles the window's frames: the run would measure macOS
  echo "pt_slice: the screen is locked; macOS throttles the game's frames then (a stall every 7-8 frames). Unlock it and run again."
  exit 2
fi
mkdir -p "$ROOT/$RUN"
"$ROOT/tools/thermal/build.sh" >/dev/null
pass() {
  local name="$1" engine="$2" flag="$3"
  RETURN_FOCUS="${RETURN_FOCUS:-0}" FIXED_FPS=0 TIMEOUT=900 ENGINE_ARGS="$engine res://tests/terrain/s3.tscn" LOG="$ROOT/$RUN/$name.log" \
    "$ROOT/tools/run_windowed.sh" --pt-slice --town --run="$RUN" --commit="$COMMIT" $flag
  grep -E "^s3: pt-slice|^s3: s3_pt|SCRIPT ERROR|telemetry: thermal" "$ROOT/$RUN/$name.log" | tail -4
}
case "$MODE" in capped|both) pass capped "" "" ;; esac
case "$MODE" in uncapped|both) pass uncapped "--disable-vsync" "--uncapped" ;; esac
echo "CSVs and logs: $RUN; summaries appended to perf/history.csv"
