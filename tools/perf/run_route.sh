#!/bin/bash
# Spike S0's performance route over the draft's five viewpoints (plan chapter 11, 19.7; roadmap RT-04).
# At each viewpoint the game settles 2 s, then logs every frame to CSV for 240 frames while turning a full circle,
# in real time (no fixed fps), at play quality (the tier's 3D pixel budget) with the thermal helper running.
# Passes: capped (30 fps: pacing and heat) and uncapped (vsync off, no cap: a GPU-bound frame then lasts as long as
# the GPU's work, which is the only GPU estimate available on Metal here; docs/ISSUES.md, ISS-011).
# Output: perf/runs/<stamp>/v<N>_<mode>.csv, the run's logs, and one summary line per viewpoint in perf/history.csv.
# Usage: [TIER=QT-NATIVE] tools/perf/run_route.sh [capped|uncapped|both]   (default capped, QT-BAL). About a minute per pass.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODE="${1:-capped}"
TIER="${TIER:-QT-BAL}"  # e.g. TIER=QT-NATIVE for the window's full resolution
# Optional fixed render: CANVAS=3840x2160 SCALE3D=1.0 [UPSCALER=metalfx_spatial] renders at exactly that size, whatever the window.
EXTRA=""
[ -n "${CANVAS:-}" ] && EXTRA="$EXTRA --canvas=$CANVAS"
[ -n "${SCALE3D:-}" ] && EXTRA="$EXTRA --scale3d=$SCALE3D"
[ -n "${UPSCALER:-}" ] && EXTRA="$EXTRA --upscaler=$UPSCALER"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="perf/runs/$STAMP"
COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo none)$(git -C "$ROOT" diff --quiet 2>/dev/null || echo +dirty)"
mkdir -p "$ROOT/$RUN"
"$ROOT/tools/thermal/build.sh" >/dev/null
pass() {
  local name="$1" engine="$2" flag="$3"
  FIXED_FPS=0 ENGINE_ARGS="$engine" LOG="$ROOT/$RUN/$name.log" "$ROOT/tools/run_windowed.sh" --perf-route="$RUN" $flag --perf-commit="$COMMIT" --tier="$TIER" $EXTRA
  grep -E "^perf:|ERROR|telemetry: thermal" "$ROOT/$RUN/$name.log"
}
case "$MODE" in capped|both) pass capped "" "" ;; esac
case "$MODE" in uncapped|both) pass uncapped "--disable-vsync" "--perf-uncapped" ;; esac
echo "CSVs and logs: $RUN; summaries appended to perf/history.csv"
