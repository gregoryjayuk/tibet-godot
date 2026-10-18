#!/bin/bash
# The town's walkers on the street graph (M1 sprint 4, step 4; plan chapter 11, 12.3-12.4): spike S5, for twenty then, for the
# day's drawn since M2 sprint 10 (tools/town/roster.py: some 220 walkers).
# Usage: tools/town/walkers.sh          headless, half an hour of their time (tests/terrain/s3.gd --walkers): TownSim and
#                                       the crowd's time a frame, their feet against the game's ground, the mani wall's
#                                       way, the great wheel turned; about a minute. The log: tests/player/out/walkers.log
#        tools/town/walkers.sh stills   in a window: Tsongra, the Sky Stair, the Mani Lane and the great wheel at the
#                                       moment most walkers are in each, then the sheet with the graph's map
#                                       (tests/terrain/out/walkers_sheet.jpg)
# The graph and the routes come from tools/town/graph.py (run by tools/terrain/build.sh).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
if [ "${1:-}" = "stills" ]; then
  RETURN_FOCUS="${RETURN_FOCUS:-0}" TIMEOUT=400 ENGINE_ARGS="res://tests/terrain/s3.tscn" "$ROOT/tools/run_windowed.sh" --shots --town --people \
    --only=people_tsongra,people_stair,people_mani,people_wheel
  grep -E "townspeople at|SCRIPT ERROR" "$ROOT/tests/out/last_run.log"
  "$ROOT/tools/py" "$ROOT/tools/town/walkers_sheet.py"
  exit 0
fi
"$GODOT" --headless --path "$ROOT" --fixed-fps 30 --quit-after 120000 --log-file "$ROOT/tests/player/out/walkers.log" res://tests/terrain/s3.tscn -- --walkers --town > /dev/null 2>&1
grep -E "^s3: walkers (PASS|FAIL)|SCRIPT ERROR" "$ROOT/tests/player/out/walkers.log"
