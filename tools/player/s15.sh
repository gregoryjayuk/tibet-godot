#!/bin/bash
# Spike S15 on the Sky Stair (plan chapter 11, 23; M1 sprint 3, step 3): the third-person player up the stair from
# Tsongra to the Tödé chorten and back down, scripted (tests/terrain/s3.gd --climb). Headless and at a fixed 30 frames
# a second it runs faster than the game's own time (a climb is about 9 minutes of it); with STILLS=1 it runs in a window
# instead and saves the third-person view at five places on the way up (tests/player/out/s15_*.png).
# Usage: tools/player/s15.sh [runs]     (default 1: one climb up and one down); results in tests/player/out/s15.json
#        (every second run at the jog; CLIMB_GAIT=jog or =sprint every run at that gait, and with STILLS=1 its stills as
#        tests/player/out/s15_<gait>_*.png: the sprint two treads a stride until its breath runs out; IMP-043)
#        tools/player/s15.sh ladders  every notched log up to a roof and down again; tests/player/out/s15_ladders.json
#        tools/player/s15.sh route dechen  a walk through Dechen-tsang, gate to garden
#        tools/player/s15.sh route sang  up the Rooftop Way's first pieces to Dechen-tsang's master roof and juniper laid on
#          its burner with the household at 17:12 (sprint 7, step 6); STILLS=1 in a window with its still
#        tools/player/s15.sh route message  the offers carried between Dechen-tsang's counting rooms, three times (sprint 7,
#          step 5); HOUR=14.55 STILLS=1 in a window with a still at each
#        tools/player/s15.sh route stalls  along Tsongra's fuel stalls at nine, a stop to listen at each keeper, and back
#          west: the barks said on the way (sprint 7, step 8); STILLS=1 in a window, a still of the first line at each stop
#        tools/player/s15.sh route tea  into Dechen-tsang's Tibetan room to the guest bench, sat, poured tea, the libation,
#          a sip and its refill, enough (sprint 7, step 4); HOUR=14 STILLS=1 in a window with its stills
#        tools/player/s15.sh route tsokchen_tea  at the general tea (11:03) in at the Tsokchen's door to the guest's place at
#          the west rows' door end, sat, the novice pours, the libation, a sip refilled, enough, a last sip, up with a
#          little left (M3 sprint 6, step 4); STILLS=1 in a window with its stills
#        tools/player/s15.sh route rooms  over Dechen-tsang's threshold and into each of its four rooms and out (sprint 7,
#          step 2: every sill stepped over, never stood on); TIME=1 in a window, every frame timed (no frame over 50 ms,
#          no pipeline compiled at a door)
#        tools/player/s15.sh route rooftop  the Rooftop Way (R-06), Dechen-tsang's guest yard to V-28's roof; STILLS=1 in a
#          window with a still at each piece (tests/player/out/rooftop_*.png)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNS="${1:-1}"
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
LOG="$ROOT/tests/player/out/s15.log"
mkdir -p "$ROOT/tests/player/out"
if [ "${1:-}" = "route" ] && [ "${TIME:-0}" = "1" ]; then  # in a window, each frame timed: TIME=1 tools/player/s15.sh route rooms
  TIMEOUT="${TIMEOUT:-600}" ENGINE_ARGS="res://tests/terrain/s3.tscn" LOG="$LOG" "$ROOT/tools/run_windowed.sh" --route="${2:-rooms}" --town --time ${HOUR:+--hour=$HOUR}
  grep -E "^s3: route|SCRIPT ERROR" "$LOG"
  exit 0
fi
if [ "${1:-}" = "route" ] && [ "${STILLS:-0}" = "1" ]; then
  TIMEOUT="${TIMEOUT:-900}" ENGINE_ARGS="res://tests/terrain/s3.tscn" LOG="$LOG" "$ROOT/tools/run_windowed.sh" --route="${2:-rooftop}" --town $([ "${2:-}" = "tea" ] || [ "${2:-}" = "tsokchen_tea" ] || [ "${2#house_tea}" != "${2:-}" ] || [ "${2#message}" != "${2:-}" ] || [ "${2:-}" = "sang" ] || [ "${2:-}" = "stalls" ] || [ "${2#letter_}" != "${2:-}" ] || [ "${2#chang_}" != "${2:-}" ] || [ "${2#headman_}" != "${2:-}" ] && echo --people) --stills ${HOUR:+--hour=$HOUR} ${FROM:+--from=$FROM} ${STILL0:+--still0=$STILL0}
  grep -E "^s3: route|^s3: climb still|SCRIPT ERROR" "$LOG"
  exit 0
fi
if [ "${1:-}" = "route" ]; then  # a walk through a building by its waypoints (tests/terrain/s3.gd ROUTES), e.g. dechen
  "$GODOT" --headless --path "$ROOT" --fixed-fps 30 --quit-after 72000 --log-file "$LOG" res://tests/terrain/s3.tscn -- --route="${2:-dechen}" --town $([ "${2:-}" = "tea" ] || [ "${2:-}" = "tsokchen_tea" ] || [ "${2#house_tea}" != "${2:-}" ] || [ "${2#message}" != "${2:-}" ] || [ "${2:-}" = "sang" ] || [ "${2:-}" = "stalls" ] || [ "${2#letter_}" != "${2:-}" ] || [ "${2#chang_}" != "${2:-}" ] || [ "${2#headman_}" != "${2:-}" ] && echo --people) > /dev/null 2>&1
  grep -E "^s3: route|SCRIPT ERROR" "$LOG"
  exit 0
fi
if [ "${1:-}" = "ladders" ] && [ "${STILLS:-0}" = "1" ]; then
  TIMEOUT=300 ENGINE_ARGS="res://tests/terrain/s3.tscn" LOG="$LOG" "$ROOT/tools/run_windowed.sh" --ladder --town --stills --only="${2:-LADDER_H-SHL-017}"
  grep -E "^s3: ladder|^s3: climb still|SCRIPT ERROR" "$LOG"
  exit 0
fi
if [ "${1:-}" = "ladders" ]; then
  "$GODOT" --headless --path "$ROOT" --fixed-fps 30 --log-file "$LOG" res://tests/terrain/s3.tscn -- --ladder --town > /dev/null 2>&1
  grep -E "^s3: ladder|SCRIPT ERROR" "$LOG"
  exit 0
fi
if [ "${STILLS:-0}" = "1" ]; then
  TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" LOG="$LOG" "$ROOT/tools/run_windowed.sh" --climb --town --stills
else
  "$GODOT" --headless --path "$ROOT" --fixed-fps 30 --log-file "$LOG" res://tests/terrain/s3.tscn -- --climb --town --runs="$RUNS" > /dev/null 2>&1
fi
grep -E "^s3: climb|SCRIPT ERROR" "$LOG"
