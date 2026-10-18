#!/bin/bash
# Spike S1's heat soak (roadmap RT-06): the draft for MINUTES (default 20) at a fixed CANVAS (default 1920x1080, native
# 1080p), cycling the five viewpoints while turning, with the thermal helper logging. Plugged in, nothing else heavy.
# Output: perf/runs/soak-<stamp>/soak.csv (every frame) and soak.log, whose last line is the verdict.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MIN="${MINUTES:-20}"; CANVAS="${CANVAS:-1920x1080}"
RUN="perf/runs/soak-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$ROOT/$RUN"
"$ROOT/tools/thermal/build.sh" >/dev/null
FIXED_FPS=0 TIMEOUT=$(perl -e "print int($MIN * 60 + 120)") LOG="$ROOT/$RUN/soak.log" "$ROOT/tools/run_windowed.sh" --soak="$MIN" --soak-dir="$RUN" --canvas="$CANVAS"
grep -E "^soak:|telemetry: thermal|ERROR|killed" "$ROOT/$RUN/soak.log"
