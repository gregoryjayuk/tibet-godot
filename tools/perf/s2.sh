#!/bin/bash
# Spike S2, the town-scale draw test (tests/perf/s2.tscn): capped, and uncapped if asked. Summaries to perf/history.csv.
# Usage: tools/perf/s2.sh [capped|uncapped|both]
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODE="${1:-both}"
RUN="perf/runs/s2-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$ROOT/$RUN"
COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null)$(git -C "$ROOT" diff --quiet 2>/dev/null || echo +dirty)"
"$ROOT/tools/thermal/build.sh" >/dev/null
pass() {
  FIXED_FPS=0 TIMEOUT=300 ENGINE_ARGS="res://tests/perf/s2.tscn $2" LOG="$ROOT/$RUN/$1.log" "$ROOT/tools/run_windowed.sh" --run="$RUN" --commit="$COMMIT" $3
  grep -E "^s2:|telemetry: s2|ERROR|killed" "$ROOT/$RUN/$1.log"
}
case "$MODE" in capped|both) pass capped "" "" ;; esac
case "$MODE" in uncapped|both) pass uncapped "--disable-vsync" "--uncapped" ;; esac
