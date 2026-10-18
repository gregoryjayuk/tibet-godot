#!/bin/bash
# The slice's codex sites (M1 sprint 7, step 7; world/codex_sites.gd): each look or enter site found in the built town,
# headless with the town and its people (tests/terrain/s3.gd --codex); PASS if every one is found. About a minute.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG="$ROOT/tests/terrain/out/codex.log"
mkdir -p "$ROOT/tests/terrain/out"
/Applications/Godot.app/Contents/MacOS/Godot --headless --path "$ROOT" --fixed-fps 30 --quit-after 20000 --log-file "$LOG" res://tests/terrain/s3.tscn -- --codex --town --people > /dev/null 2>&1
grep -E "^s3: codex|SCRIPT ERROR" "$LOG"
