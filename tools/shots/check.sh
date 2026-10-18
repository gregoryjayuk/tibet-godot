#!/bin/bash
# Regression check: run a shot set, then compare its output folder with the approved references.
# Usage: tools/shots/check.sh tests/shots/draft/set.json tests/shots/out/draft tests/shots/draft/ref
# Approving new references (copying out/ over ref/) is Greg's or the main session's decision, never automatic.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SET="${1:?set.json}"; OUT="${2:?output folder}"; REF="${3:?reference folder}"
cd "$ROOT"
rm -rf "$OUT"
tools/shots/run_set.sh "$SET" >/dev/null || { echo "shot run failed; see tests/out/shots.log"; exit 1; }
tools/shots/compare "$REF" "$OUT" --out "$OUT/compare"
