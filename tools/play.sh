#!/bin/bash
# Walk the game as it stands, in its own window (the controls since 14 Oct 2026, IMP-044: autoload/controls.gd). The keys
# and the mouse as World of Warcraft has them: W and S forward and back, A and D turn, the left button held and dragged
# looks round, the right held steers (A and D then step aside), both walk on, the wheel zooms; a jog by default, Shift
# held sprints, Option toggles a walk; E use, C sit, V first person, R fists up, G sling, L ledger, K codex. A PS4
# controller GTA's way: the left stick moves (a light tilt walks), the right stick looks, cross held sprints, square
# jumps, triangle uses, circle sits. F to fly (E/Q up and down), the number keys for viewpoints; close the window to stop.
#   tools/play.sh street   the draft street, rebuilt from the kit with M1's new look (weathering, painted light)
#   tools/play.sh town     300 kit buildings on a slope with 300 people, a grazing herd, a caravan and 300 birds
#   tools/play.sh valley   the designed valley on the real ground (tools/terrain/build.sh), the mountains out to 15 km,
#                          and the town the kit can build so far (lower Shöl's houses since kit step K5), with its first
#                          twenty townspeople on their rounds (sprint 4, step 4); HOUR=15.2 tools/play.sh valley starts
#                          the day at 15:12 (the caravan on the ramp), HOUR=16 at 16:00 (Tsongra, Nyima); AT=yak_gate
#                          or AT=tsongra starts the player there; AT=dechen before Dechen-tsang's gate (sprint 7);
#                          MIST=sea gives the dawn the mist sea (chapter 08, V-22) instead of the river mist (HOUR=6.5);
#                          SNOW=dust|v31|town|falling the weather's snow (world/day.gd SNOW: town and falling lie in the lanes);
#                          DATE=MM-DD starts the clock on that day (DATE=11-05 HOUR=13.9 AT=gorge: the full moon, the tulku's
#                          afternoon home, M3 sprint 2, step 6);
#                          AT=house at the foot of a town house's outside stair, its kitchen's door open at the top
#                          (sprint 8, step 7; the others to enter: H-SHL-054 by the Mani Lhakhang, H-SHL-004 east of
#                          the Sky Stair's foot); AT=bridge before the ladder up H-SHL-080's wall to the plank-and-rope
#                          bridge over the Sky Stair (IMP-023 (3): W climbs, across, down H-SHL-061's plank to the lane);
#                          AT=serchu by the road chorten at the cliff gallery's east end (M2 sprint 3: NEW=1 HOUR=14.67
#                          AT=serchu walks the arrival, the gallery, the Gate Chorten, V-01, the caravan's bells ahead)
#                          AT=samkha in the south pavilion, the chain bridge ahead to Samkha Khar's gate passage; AT=castle
#                          in the castle's ward by the passage's steps (M2 sprint 4; the gate is barred 17:30-05:30)
#                          AT=pema on the Conch terrace at the foot of Pema Ö Lhakhang's stair (M2 sprint 5: up it, into
#                          the hall through the porch, round the kora corridor turning its wheels; the pool over the lip)
#                          AT=spring at the foot of the path up to the Lukhang spring (M2 sprint 6, step 3: HOUR=5.6 for the
#                          women's queue at its spouts at first light, HOUR=15.5 for the afternoon's; the naga's niche at the back)
#                          AT=lookout at the garden lane's foot by H-SHL-095's yard (M2 sprint 6, step 4: up the lane between the
#                          orchards' walls to the Gorge Rim Lookout; HOUR=16.8 for the old woman's juniper at dusk)
#                          AT=poor before H-SHL-142's door on the west edge, a poor family's one room (ISS-105: walk in
#                          and the player ducks under its lintel); AT=chang on the lane before the chang house SHL-24
#                          (M2 sprint 2: up its stair to the drinking room; Jiang Deshun from 16:30, the bard at 19:30)
#                          AT=headman outside the headman's yard gate (M2 sprint 7: the stable from the yard, its log up
#                          through the kitchen's trapdoor, the stair to the second floor, the hatch's log to the roof room)
#                          AT=ramp at the head of the Caravan Ramp past the south pavilion's front (M2 sprint 9: down its
#                          six legs and five switchbacks to the Caravan Ground); AT=camp at the ramp's foot by the fodder
#                          yard, the camp ahead (HOUR=16 for CV-02's tea stacked into windbreaks and its yak's hay)
#                          AT=hejie inside Hejie's Water Gate (M2 sprint 9, step 4: up River Street between its shops to
#                          the East Gate; HOUR=17.5 for its lanterns and windows lit; not entered)
#                          AT=castle_ramp outside Hejie's East Gate at the Castle Ramp's foot (M2 sprint 11, step 1: up its
#                          three legs to Samkha Khar's ward, round its north-east corner and in at its gate)
#                          AT=zampa on R-01 on the north bank before the Serchu Zampa's gateway chorten (M2 sprint 12:
#                          through it and over the deck, the road's last kilometre down the south bank to the cliff
#                          gallery and on; the new game's start, NEW=1 HOUR=14.42 AT=zampa, or HOUR=10.5 to walk with
#                          CV-02 over the Zampa at 11:00); AT=mills on R-01 at the head of the path down to the mills'
#                          footbridge (step 5: over it, up the Yak Road)
#                          AT=gonpa in Dungkar Gönpa's courtyard before the Tsokchen (M2 sprint 13: the halls at their far
#                          form, the khamtsen, the monks' houses down the flank and up the west face)
#                          AT=chora on the flagged walk from the Tsenyi Dratsang's side door to the Chöra's gate (M3 sprint 3, step 2: the debate courtyard, its poplars and the teacher's platform; V-31 by its west wall, C to sit)
#                          AT=steps at the foot of the 1,080 steps by the Conch Bridge (M3 sprint 1: up their 23 flights,
#                          by the Lhabab Chorten's landing and across the face, to the South Gate's forecourt)
#                          LOAD=quick (or auto_1..3, or latest) starts from a save (F5 saves, F9 loads the last;
#                          autosaves at 05:00, 12:00 and 17:00 and every ten minutes; M2 sprint 1, step 1)
#                          NEW=1 a new game: the story from its start, the house's letter in the chuba (best with
#                          HOUR=15.2 AT=yak_gate, the caravan coming in); E talks, 1-4 answer, L the ledger
#   tools/play.sh fight    the practice yard (spike S19): a sparring partner, pots on a wall, a straw target
# A second word sets the sharpness: sharp (the 3D at 1440p, QT-FULL) or native (the screen's own pixels, QT-NATIVE,
# heavier); without it, the default 1080p budget (QT-BAL), upscaled to the window.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIER=""
case "${2:-}" in
  sharp) TIER="--tier=QT-FULL" ;;
  native) TIER="--tier=QT-NATIVE" ;;
esac
case "${1:-street}" in
  street) open -n -a /Applications/Godot.app --args --path "$ROOT" -- --kit $TIER ;;
  town) open -n -a /Applications/Godot.app --args --path "$ROOT" res://tests/perf/s5.tscn -- --play $TIER ;;
  valley) open -n -a /Applications/Godot.app --args --path "$ROOT" res://tests/terrain/s3.tscn -- --play --town --people $TIER ${HOUR:+--hour=$HOUR} ${DATE:+--date=$DATE} ${AT:+--at=$AT} ${LOAD:+--load=$LOAD} ${NEW:+--new} ${MIST:+--mist=$MIST} ${SNOW:+--snow=$SNOW} ;;
  fight) open -n -a /Applications/Godot.app --args --path "$ROOT" res://tests/player/fight.tscn -- --play $TIER ;;
  *) echo "usage: tools/play.sh [street|town|valley|fight]"; exit 1 ;;
esac
