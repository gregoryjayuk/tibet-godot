#!/bin/bash
# Run a shot set (JSON; see tests/shots/draft/set.json) in one Godot window, without taking the keyboard.
# Usage: tools/shots/run_set.sh tests/shots/draft/set.json   (paths relative to the project folder)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SET="${1:?usage: run_set.sh <shot-set.json>}"
export LOG="${LOG:-$ROOT/tests/out/shots.log}"
"$ROOT/tools/run_windowed.sh" --shot-set="$SET"
grep -E "^shot |ERROR" "$LOG" || { echo "no shots recorded; see $LOG"; exit 1; }
! grep -q "ERROR" "$LOG"
