#!/bin/bash
# The terrain, rebuilt from the elevation tiles and chapter 02 (plan chapter 11, 8.2; PLAN step 8), in the passes' order
# of dependence: the gazetteer as data; passes 2-3, the valley's shape (sculpt.py); pass 6, the horizons, shaped only near
# the valley (horizons.py; Greg kept the real mountains, 25 Sep 2026, 22:14); the town builder's generic houses
# (tools/town/builder.py, on the shaped ground); passes 4-5, pads and the slice's road beds (pads.py); the retaining
# walls on the pads' steps and the lanes' sides (tools/town/walls.py, then ../tibet-blender/export_walls.py: kit step K6) and the lanes' flights (export_lanes.py, IMP-023); the barkor's mani wall on the Mani Lane's bed (tools/town/mani.py, sprint 4 step 3); the notched logs up to the roofs (tools/town/ladders.py, sprint 3 step 3); the Rooftop Way over the roofs and lanes (tools/town/rooftop.py, sprint 4 step 1); the street graph and the first walkers' routes (tools/town/graph.py, sprint 4 step 4); the plank-and-rope bridge over the Sky Stair and the ways onto its roofs (tools/town/bridges.py, then ../tibet-blender/export_bridges.py: IMP-023 (3)); a way onto every roof the town can reach (tools/town/roof_ways.py: IMP-026); pass 8, the Terrain3D heights and the ring mesh (export_t3d.py), the ground's classes (control.py), then import_t3d.gd; the horizon map and the
# sun report (horizon.py); pass 7, the checks (terrain_check.py -> docs/terrain/terrain-report.md). About 5 minutes.
# The base (pass 1, fetch.py) runs only when its rasters are missing: it needs the six approved elevation tiles.
# Usage: tools/terrain/build.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PY="$ROOT/tools/py"
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
cd "$ROOT/tools/terrain"
[ -f "$ROOT/assets/generated/terrain/valley_1m.tif" ] || nice -n 10 "$PY" fetch.py
"$PY" "$ROOT/tools/town/gazetteer.py"
nice -n 10 "$PY" sculpt.py | grep -v "carved"
nice -n 10 "$PY" horizons.py | grep "How far"
"$PY" peak.py  # Dungri Karpo raised into the shaped ring, in the gorge's notch from the Gorge Rim Lookout (M2 sprint 6, step 5)
"$PY" "$ROOT/tools/town/castle_ramp.py"  # the Castle Ramp's lanes and its yards' places, for the builder (Samkha's houses by it) and pads.py (M2 sprint 11)
VALLEY=valley_shaped_1m "$PY" "$ROOT/tools/town/builder.py"
"$PY" "$ROOT/tools/town/north_ramp.py"  # Samkha's north ramp's lanes, for pads.py to carve (sprint 6, step 5)
"$PY" "$ROOT/tools/town/south_ramp.py"  # and its south ramp's (M2 sprint 3, step 1)
"$PY" "$ROOT/tools/town/gardens.py"  # upper Shöl's gardens and the lane through them to the Gorge Rim Lookout, for pads.py to carve (M2 sprint 6, step 4)
"$PY" "$ROOT/tools/town/caravan_ground.py"  # the Caravan Ramp's lanes, the Caravan Ground's levels and things, for pads.py (M2 sprint 9, step 1)
"$PY" "$ROOT/tools/town/hejie.py"  # Hejie's pads on the real ground, its wall and its generic houses, for pads.py (M2 sprint 9, step 4)
"$PY" serchu_road.py  # R-01's last kilometre from the Serchu Zampa down the south bank to SER-20, its lanes for pads.py (M2 sprint 12, step 1)
"$PY" "$ROOT/tools/town/serchu_mills.py"  # the north bank's leat, mills, footbridge, paths and the Yak Road's foot, for pads.py (M2 sprint 12, step 5)
"$PY" "$ROOT/tools/town/dungrong.py"  # the 1,080 steps from the Conch Bridge to the South Gate, for the monastery's planner and pads.py (M3 sprint 1)
"$PY" "$ROOT/tools/town/gorge_stair.py"  # the Gorge Stair from the Lookout over the upper bridge to the West Gate, for the monastery's planner and pads.py (M3 sprint 2)
"$PY" "$ROOT/tools/town/gonpa_ways.py"  # the monastery's way up from the South Gate to the Tsokchen's courtyard, for the monastery's planner and pads.py (M3 sprint 3)
"$PY" "$ROOT/tools/town/monastery.py"  # Dungkar Gönpa's monks' houses on the spur's rows, for pads.py (M2 sprint 13, step 2)
"$PY" "$ROOT/tools/town/gonkor.py"  # the Gönkor round the monastery beyond its south stretch, for pads.py (M3 sprint 7, step 1)
"$PY" "$ROOT/tools/town/tode_stair.py"  # the Tödé Stair from the Sky Stair's head up the band into Tödé, for tode.py and pads.py (M3 sprint 4, step 2)
"$PY" "$ROOT/tools/town/tode.py"  # Tödé's 68 houses, its empty tower-house and its named places on the real ground, for pads.py (M3 sprint 4, step 1)
"$PY" "$ROOT/tools/town/tode_leat.py"  # Tödé's leat TOD-10, its mills and water prayer wheels, for pads.py (M3 sprint 4, step 4)
"$PY" "$ROOT/tools/town/tode_things.py"  # Tödé's threshing floors, byres, racks, walnut grove and window stall (M3 sprint 4, step 5)
"$PY" arrival.py  # the arrival's lines for the game (data/arrival.json); pads.py shapes its ground (pass 5c)
"$PY" samkha.py  # Samkha's bridge, ward and passage for the kit and the game (data/samkha.json); pads.py shapes its ground (pass 5d)
nice -n 10 "$PY" pads.py | grep -E "pads cut|Road beds|The arrival|Samkha|The confluence"
"$PY" rivers.py  # the rivers as water for the game, fitted to the built ground (data/rivers.json; M2 sprint 5, step 1)
"$PY" "$ROOT/tools/town/samkha_rim.py"  # the Leat Fall's outlet and path, the latrine's midden, on the slot's face (M2 sprint 11, step 4)
"$PY" "$ROOT/tools/town/forest.py"  # the Shade Wood's trees on the built ground (M2 sprint 12, step 4)
"$PY" "$ROOT/tools/town/walls.py"
"$PY" "$ROOT/tools/town/mani.py"  # the barkor's mani wall on the Mani Lane's bed (sprint 4, step 3)
"$PY" "$ROOT/tools/town/ladders.py" || echo "build: no ladders (export the kit's houses and notched logs: their sidecars give the roofs' heights)"
"$PY" "$ROOT/tools/town/rooftop.py" || echo "build: no Rooftop Way (tools/town/rooftop.py found none; docs/town/rooftop-report.md)"
"$PY" "$ROOT/tools/town/graph.py"  # the street graph and the first walkers' routes (sprint 4, step 4)
"$PY" "$ROOT/tools/town/bridges.py" || echo "build: no bridges (tools/town/bridges.py; docs/town/bridges-report.md)"  # over the Sky Stair (IMP-023 (3))
"$PY" "$ROOT/tools/town/roof_ways.py"  # a way onto every roof (IMP-026); it opens the yards' parapets its planks cross, so before the walls' export
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python "$ROOT/../tibet-blender/export_walls.py" 2>&1 | grep "^DONE"
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python "$ROOT/../tibet-blender/export_lanes.py" 2>&1 | grep "^DONE"  # each lane's flight its own (IMP-023)
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python "$ROOT/../tibet-blender/export_bridges.py" 2>&1 | grep "^DONE"
"$PY" "$ROOT/tools/town/arrival_faces.py"  # the arrival's rock faces from the built ground (M2 sprint 3, step 2)
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python "$ROOT/../tibet-blender/export_arrival.py" 2>&1 | grep "^DONE"  # the cliff gallery, the cutting's rock
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python "$ROOT/../tibet-blender/export_samkha.py" 2>&1 | grep "^DONE"  # the chain bridge (M2 sprint 4)
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python "$ROOT/../tibet-blender/export_serchu.py" 2>&1 | grep "^DONE"  # the leat's channel, chutes, weir, culvert, footbridge (M2 sprint 12, step 5)
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python "$ROOT/../tibet-blender/export_serchu.py" -- --data tode_leat.json --out tode_leat 2>&1 | grep "^DONE"  # Tödé's leat's channel, chutes, races and culverts (M3 sprint 4, step 4)
export VALLEY=valley_padded_1m RING=ring_shaped_30m
nice -n 10 "$PY" export_t3d.py | tail -2
"$PY" control.py  # pass 8: the ground's classes on the export's grid (sprint 3, step 6)
rm -rf "${ROOT:?}/world/terrain/t3d"
"$GODOT" --headless --path "$ROOT" --script tools/terrain/import_t3d.gd 2>&1 | grep "import_t3d" || true
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true  # the walls' new files
nice -n 10 "$PY" horizon.py | grep -E "within the gate|outside the gate"
CHECK_REPORT=terrain-report.md nice -n 10 "$PY" terrain_check.py > /dev/null
"$GODOT" --headless --path "$ROOT" --script "$ROOT/tools/town/households_dump.gd" 2>/dev/null | grep "^households_dump"  # each house as the town draws it (world/households.gd)
"$PY" "$ROOT/tools/town/population.py"  # the population as data, its households away where the houses are shut (M2 sprint 10, step 1)
DRAW_WAS=$(cat "$ROOT/data/roster.json" "$ROOT/data/market.json" 2>/dev/null | md5 -q)
"$PY" "$ROOT/tools/town/roster.py"  # the day's 300 (step 2), drawn from the population
"$PY" "$ROOT/tools/town/market.py"  # Tsongra's market's stalls and their keepers (step 4)
if [ "$(cat "$ROOT/data/roster.json" "$ROOT/data/market.json" | md5 -q)" != "$DRAW_WAS" ]; then  # a new draw or market: the
  "$PY" "$ROOT/tools/town/graph.py" | grep -E "^graph: [0-9]+ nodes|day's drawn"  # street graph's walkers again
fi
"$PY" "$ROOT/tools/town/tode_days.py"  # Tödé's people's day from their doors, from the population and the built ground (M3 sprint 4, step 6)
echo "terrain: built; reports in docs/terrain/ (sculpt, horizons, pads, control, sun, terrain)"
