extends Node3D
## Spike S3 (plan chapter 11, 8.4 and 23; roadmap RT-12): Terrain3D 1.0.2 on Metal. The valley map at 1 m in 150
## regions of 256 m (tools/terrain/export_t3d.py, then import_t3d.gd), drawn by shaders/terrain.gdshader (Terrain3D's
## minimum shader with chapter 09's colour rules and the stylized light), inside the 30 m ring out to 15 km as one mesh
## (shaders/terrain_far.gdshader). The ground is the REAL ground at today's anchor (docs/terrain/base-report.md), not
## chapter 02's designed valley, which is not sculpted yet: this spike asks only whether the engine carries it.
## Modes (after --):
##   --shots  stills from Tsongra, a Pharkha stand-in and a high station to tests/terrain/out/ (1920 x 1080, frozen)
##   --perf   per station, turning a full circle over 240 frames each: frame times with everything, without the
##            Terrain3D valley, and with neither valley nor ring (run uncapped: the terrain's GPU cost is the
##            difference); memory before and after the terrain loads. Summaries to perf/history.csv
##   --play   walk it yourself from Tsongra (tools/play.sh valley), the day running with its ridge shadows (art steps A7, A8)
##   --ridge  art step A8: the ridge shadow crossing the real valley, stills from above the west bank at the
##            moments round the town's last sun (docs/terrain/sun-report.md) to tests/terrain/out/s3_ridge_HHMM.png
##   --walk   the player on Terrain3D's dynamic collision, running for 25 s from Tsongra towards the hillside 600 m
##            west; pass if it moved more than 60 m, climbed more than 5 m and never fell through the ground
##   --town   with any mode: the town the kit can build so far, placed from data/town.json and the town builder's
##            data/town_generic.json (world/town.gd; kit step K5: lower Shöl's town houses, the poor houses, the stalls)
##   --climb  spike S15 on the Sky Stair (plan chapter 11, 23; M1 sprint 3, step 3; needs --town): the third-person
##            player walks from the foot of the talkers' steps up the stair to the Tödé chorten and back down, steered
##            along its line, --runs=N times (default 1), each run on its own line across the stair (0.4 m either side
##            of the middle) and every second one at the jog (until 14 Oct 2026 "hurried", Shift). Per climb: the time a step takes on the flights against
##            the player's pace (at the walk 0.5 s up, 0.38 s down since Greg's verdict of 26 Sep 2026; chapter 11 had 0.75 and 0.5; at the jog 0.25 and 0.2 since 14 Oct 2026, IMP-043; within 10%), stalls (under 0.3 m in 3 s), the lowest the feet go under
##            the stair's ramps and the highest over them (the terrain poking through), the widest it strays. --stills
##            instead walks the first 46 m only, saving the third-person view at the gateway chorten, inside it, in the
##            tunnel and at its window, and a side view of the legs on a flight (tests/player/out/s15_*.png).
##            tools/player/s15.sh runs it.
##   --route=<id> a scripted walk through a building of the town by its waypoints (ROUTES, in the building's own frame),
##            the player steered to each in turn: pass if it reaches every one without a stall (3 s under 0.3 m) and ends
##            at the last one's level. dechen: in at Dechen-tsang's gate, over its threshold, through the front yard, up
##            the steps to the guest yard and on up to the garden (kit step K7). tsongra: from Tsongra's lower level up
##            the flight to its upper level (terrain pass 8). rooftop: spike S15 on the Rooftop Way (R-06; sprint 4, step 1),
##            from Dechen-tsang's guest yard to V-28's roof by tools/town/rooftop.py's legs, at a walk (a child's pace),
##            up and down its logs and stair-ladders, over its steps and planks; pass also if it never fell (the ground
##            under it never more than 1.2 m lower than a moment before, off a ladder); --stills a still as each piece
##            is reached and one on the last roof (tests/player/out/rooftop_NN_<piece>.png). wheel: the Mani Lhakhang's
##            great wheel (sprint 4, step 3): up the Sky Stair to the gap in its east cheek, over the forecourt, in at the
##            door, three turns clockwise round the wheel at its bars and one the other way; pass also if the wheel went
##            round with the walker (2.5 turns or more), its bell rang each turn, and walked the other way it did not turn
##            (under 0.3 of a turn, its run-down); --stills on the forecourt, at the door and at the wheel
##            (tests/player/out/s15_wheel_NN_<where>.png).
##   --ladder spike S15 on the notched logs (sprint 3, step 3, part 2; needs --town): at every log up to a roof
##            (tools/town/ladders.py), the player walks into its foot, climbs it, steps over the parapet onto the roof,
##            walks a metre in, comes back, climbs down and steps off; per log the time up against the climb's pace (player.gd CLIMB: 0.75 m/s since 14 Oct 2026, 0.5 before),
##            and whether it reached the roof and the ground again. tools/player/s15.sh ladders runs it; with --stills
##            and --only=<log>, a window's stills of that one climb (tests/player/out/s15_ladder_*.png).
## Run: tools/terrain/s3.sh [shots|perf|walk|all]

const Ink := preload("res://world/ink.gd")
const Vignette := preload("res://world/vignette.gd")
const PlayerScript := preload("res://player/player.gd")
const Hud := preload("res://ui/hud.gd")
const Crowd := preload("res://characters/crowd.gd")
const Named := preload("res://characters/named.gd")
const Caravan := preload("res://world/caravan.gd")
const Herd := preload("res://world/herd.gd")
const CampAnimals := preload("res://world/camp_animals.gd")
const Rivers := preload("res://world/rivers.gd")
const LeatFall := preload("res://world/leat_fall.gd")
const Leat := preload("res://world/leat.gd")
const PEOPLE_KINDS: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]  ## TM and TW, two of each (people2/body.py, sprint 4 step 5); the monk a stand-in
const STREETS := "res://assets/generated/terrain/street_graph.json"
const DayCycle := preload("res://world/day.gd")
const Horizon := preload("res://world/horizon.gd")
const Town := preload("res://world/town.gd")
const InteriorStack := preload("res://world/interior_stack.gd")
const Households := preload("res://world/households.gd")
const TERRAIN_SHADER := preload("res://shaders/terrain.gdshader")
const FAR_SHADER := preload("res://shaders/terrain_far.gdshader")
const DATA := "res://world/terrain/t3d"
const RING := "res://assets/generated/terrain/ring_t3d"
const OUT := "res://tests/terrain/out"
const CANVAS := Vector2i(1920, 1080)
const WALK_TARGET := Vector3(-600.0, 0.0, 0.0)
const SETTLE_MS := 2000
const FRAMES := 240
const HISTORY := "res://perf/history.csv"
const HISTORY_COLUMNS := ["date", "commit", "route", "view", "mode", "frames", "p50_ms", "p95_ms", "p99_ms", "worst_ms",
		"engine_process_ms", "engine_physics_ms", "render_cpu_ms", "draw_calls", "primitives_max", "objects", "mem_static_mb_max",
		"mem_video_mb_max", "mpx_3d", "tier", "thermal", "valid"]
## Stations: [name, town-grid x (east), y (north), eye height above the ground, bearing clockwise from north, pitch].
## Art step A8's view: 200 m above the west bank south of the town, looking north-north-east over the river to Tsongra
## and up the spur to the monastery, the western ridge behind the camera; and the moments, on the default day (game day 7).
const RIDGE_STATION := ["ridge", -300.0, -900.0, 200.0, 25.0, -10.0]
const RIDGE_TIMES := [[15, 30], [15, 50], [16, 0], [16, 10], [16, 20], [16, 40], [17, 0]]
const STATIONS := [
	["tsongra_ne", 0.0, 0.0, 1.6, 40.0, 3.0],  # up the Dungchu gorge, where Dungri Karpo should stand (chapter 02, 2.7)
	["tsongra_w", 0.0, 0.0, 1.6, 265.0, 2.0],  # across the river to Pharkha's side
	["tsongra_s", 0.0, 0.0, 1.6, 175.0, 3.0],  # to the south ridge and the tea road
	["pharkha_e", -700.0, -140.0, 1.6, 80.0, 2.0],  # from the Pharkha dues house (chapter 02, 2.7) back towards the town
	["high_sw", 900.0, 700.0, 40.0, 225.0, -9.0],  # 40 m above the spur, looking down the valley
	# the slice's street (kit step K5; chapter 12, 4.2): from Tsongra up into lower Shöl, back down from the Sky Stair's
	# top (V-14), over the roofs (V-28), and from above Samkha
	["slice_tsongra_n", 0.0, -8.0, 1.6, 350.0, 6.0],
	["slice_v14", -20.0, 255.0, 1.6, 170.0, -8.0, "on top"],  # on the stair's top landing
	["slice_v28", -95.0, 205.0, 1.6, 160.0, -12.0, "on top"],  # on the roof there: "evening on the roofs", the top of R-06
	["slice_above", -60.0, -160.0, 45.0, 15.0, -14.0],
	["slice_stair_foot", -2.0, 6.0, 1.6, 356.0, 12.0],  # up the Sky Stair from Tsongra's upper steps, through the gateway chorten
	["slice_stair_mid", -8.0, 110.0, 1.6, 176.0, -14.0],  # down the stair from above the tunnel
	["slice_tunnel", -1.6, 33.0, 1.6, 355.0, 16.0],  # up the stair from above the gateway into the tunnel under its houses
	# kit step K7: Dechen-tsang (SHL-04), its gate from Netsang Lam, its front yard, the compound from above
	["tsongra_levels", 14.0, -24.0, 1.6, 330.0, 2.0],  # terrain pass 8: Tsongra's lower level, its step and flight up to the upper
	["tode_fields", 160.0, 330.0, 30.0, 330.0, -16.0],  # Tödé's benches of barley and buckwheat stubble
	["dechen_gate", -73.0, -75.0, 1.6, 358.0, 7.0],
	["dechen_yard", -66.0, -57.0, 1.6, 318.0, 4.0],
	["dechen_above", -20.0, 20.0, 30.0, 222.0, -21.0],
	# sprint 4, step 2: the slice's named houses (the headman's gate and yard, the three workshops), Tsongra's basin and darchen
	# ("abs": the third number is the height above sea level: level with the house over its narrow ledge's drop)
	["headman_gate", -85.8, 21.6, 2656.7, 282.0, 6.0, "abs"],  # outside the yard's east gate (its socket GATE)
	["headman_above", -103.0, 11.0, 2675.0, 38.0, -35.0, "abs"],
	# M2 sprint 7: the headman's house carved, every floor (chapter 04, 4.1): its yard from the gate, the stable from its
	# door, the kitchen from the hall's doorway
	["headman_yard", -93.0, 20.5, 2656.6, 318.0, 14.0, "abs"],
	["headman_stable_in", -98.3, 26.5, 2656.7, 40.0, -6.0, "abs"],
	["headman_kitchen_in", -95.1, 28.9, 2659.0, 15.0, -4.0, "abs"],
	["headman_copper_wall", -94.6, 30.6, 2659.0, 78.0, -2.0, "abs"],
	["headman_stove", -91.4, 30.3, 2659.0, 302.0, -10.0, "abs"],
	["headman_reception_in", -94.1, 28.4, 2659.0, 112.0, -8.0, "abs"],
	["headman_shrine_in", -96.9, 30.9, 2661.7, 298.0, -6.0, "abs"],
	["headman_guest_in", -97.6, 27.1, 2661.7, 250.0, -8.0, "abs"],
	["headman_roofroom_in", -93.4, 27.86, 2664.8, 85.0, -10.0, "abs"],
	["headman_roof", -97.5, 33.5, 2664.8, 135.0, -12.0, "abs"],
	["headman_bay_in", -98.4, 28.3, 2661.9, 180.0, -4.0, "abs"],
	["headman_bay_out", -98.4, 20.5, 2657.0, 0.0, 24.0, "abs"],
	# step 4: its household on chapter 04's day (with --people; their hours in STATION_HOUR)
	["headman_yard_morning", -93.0, 20.5, 2656.6, 318.0, 6.0, "abs"],
	["headman_stable_groom", -98.3, 26.5, 2656.7, 40.0, -10.0, "abs"],
	["headman_kitchen_polish", -94.6, 30.6, 2659.0, 78.0, -6.0, "abs"],
	["headman_reception_trader", -94.1, 28.4, 2659.0, 112.0, -10.0, "abs"],
	["headman_shrine_reader", -96.9, 30.9, 2661.7, 290.0, -12.0, "abs"],
	["headman_roofroom_pema", -93.4, 27.86, 2664.8, 85.0, -14.0, "abs"],
	["headman_roof_juniper", -94.0, 27.5, 2664.9, 335.0, -10.0, "abs"],
	["headman_supper", -91.4, 30.3, 2659.0, 290.0, -12.0, "abs"],
	["headman_dog_yard", -95.4, 24.3, 2658.7, 112.0, -24.0, "abs"],  # step 5: the mastiff on its chain from the landing
	["saddler", -61.5, 5.5, 2671.0, 350.0, -14.0, "abs"],  # before each workshop's front, level with its first floor
	["turner", -31.5, 30.5, 2683.0, 350.0, -14.0, "abs"],
	["tailor", -38.5, -24.5, 2661.0, 355.0, -8.0, "abs"],
	["tsongra_basin", 8.0, 5.5, 2663.7, 40.0, -14.0, "abs"],  # on Tsongra's upper level
	["tsongra_darchen", -2.0, 1.5, 1.6, 300.0, 24.0],
	# sprint 4, step 3: the Mani Lhakhang (SHL-08), its great wheel, the barkor's mani wall (SHL-09), Pasang's pitch (SHL-27)
	["mani_overview", -45.0, 30.0, 2760.0, 22.0, -34.0, "abs"],  # the Mani Lane from above the town, the Lhakhang beyond
	["lhakhang_sw", -25.0, 70.0, 2718.0, 50.0, -12.0, "abs"],  # the Lhakhang on its platform, its forecourt on the Sky Stair
	["mani_lane_w", -84.0, 97.2, 1.6, 88.0, 2.0],  # up the Mani Lane on the wall's north side, the wall on the right
	["mani_pitch", -66.0, 97.6, 1.7, 238.0, -14.0],  # Pasang's pitch against the wall's north face
	["lhakhang_bell", 13.6, 90.0, 2706.4, 316.0, 16.0, "abs"],  # in the hall: the wheel, and the bell its peg strikes
	# sprint 4, step 4: the townspeople on the street graph (--people), each still at the moment most of them are in it
	# (PEOPLE_AT: the town-grid point and radius TownSim.busiest_time looks round)
	["people_tsongra", 2.0, -13.0, 1.6, 356.0, 3.0],  # Tsongra from its lower level: the square, its steps, the stair beyond
	["people_mani", -92.0, 104.0, 2712.0, 108.0, -14.0, "abs"],  # the Mani Lane from above its west end
	["people_stair", -8.0, 124.0, 2721.0, 176.0, -15.0, "abs"],  # down the Sky Stair past the Lhakhang's gap, over its axis
	["people_wheel", 13.6, 90.0, 2706.4, 316.0, 12.0, "abs"],  # a walker at the great wheel
	# Greg's walk, 27 Sep 2026 (ISS-095): the Sky Stair's lower half, where its steps seemed to face the wrong way
	["stair_low_up", -0.17, 17.0, 2667.9, 355.2, 22.0, "abs"],  # on its first flight, 2 m up, looking up it
	["stair_low_front", 0.5, 9.0, 2666.7, 355.2, 16.0, "abs"],  # from Tsongra before its foot
	["stair_low_down", -1.33, 30.9, 2675.0, 175.2, -24.0, "abs"],  # on its first landing, looking down the first flight
	["stair_side_10", 12.12, 26.05, 2680.3, 265.2, -30.0, "abs"],  # from the east and above, down on its flights
	["stair_side_45", 9.22, 60.92, 2697.4, 265.2, -30.0, "abs"],
	["stair_side_80", 6.31, 95.80, 2712.6, 265.2, -30.0, "abs"],
	["stair_side_115", 3.40, 130.68, 2730.0, 265.2, -30.0, "abs"],
	["stair_over_6", -0.50, 20.98, 2680.8, 355.2, -89.0, "abs"],  # over its axis, straight down
	["stair_over_24", -1.99, 38.92, 2689.7, 355.2, -89.0, "abs"],  # over its axis, straight down
	["stair_over_55", -4.57, 69.81, 2704.3, 355.2, -89.0, "abs"],  # over its axis, straight down
	["stair_over_95", -7.89, 109.67, 2722.8, 355.2, -89.0, "abs"],  # over its axis, straight down
	["flags_stair", -1.4, 31.0, 2677.2, 250.0, -12.0, "abs"],  # sprint 8: the flags over Shöl's roofs from the stair's first landing
	["flags_roofs", -40.0, 30.0, 2692.0, 200.0, -18.0, "abs"],  # and from above the roofs, looking south over Tsongra
	# sprint 8, step 2: the birds (world/birds.gd), each station aimed at a bird where it is at the stills' 20 s
	["birds_close", 42.0, -6.0, 2695.0, 60.6, 15.4, "abs"],  # a chough of the Shöl party, 15 m off
	["birds_tsongra", 2.0, -13.0, 2663.6, 69.4, 34.6, "abs"],  # the Shöl party from Tsongra, at the player's eye
	["birds_pigeons", 2.0, -13.0, 2663.6, 292.9, 35.1, "abs"],  # the pigeons wheeling over Tsongra, at the player's eye
	["birds_gonpa_s", 540.0, 60.0, 2995.0, 49.9, 1.5, "abs"],  # the monastery's south flock
	["birds_ritro", 960.0, 300.0, 3385.0, 79.8, -14.6, "abs"],  # the ritro flock along the cliff
	# sprint 8, step 2: the hearths' smoke (world/hearths.gd) up the slope over the Sky Stair at the morning fires, the
	# midday meal and the evening's (STATION_HOUR), the same view each time
	["hearths_close", -12.0, 20.0, 2690.0, 27.7, 17.8, "abs"],  # 07:40
	["hearths_noon", -12.0, 20.0, 2690.0, 27.7, 17.8, "abs"],  # 12:15
	["hearths_dusk", -12.0, 20.0, 2690.0, 27.7, 17.8, "abs"],  # 17:25, the sang burning too
	# sprint 8, step 7: the town houses' kitchens (world/interiors.gd), from their doors inside, and each open door from its landing
	["house_007_in", -47.06, 29.11, 2671.80, 10.6, -10.0, "abs"],  # in the kitchen from its door
	["house_007_door", -47.71, 25.62, 2671.80, 10.6, -4.0, "abs"],  # its door, open, from the landing
	["house_007_shut", -47.71, 25.62, 2671.80, 10.6, -4.0, "abs"],  # its door shut (world/doors.gd; ISS-105)
	["house_054_in", -25.52, 111.07, 2716.30, 12.9, -10.0, "abs"],  # in the kitchen from its door
	["house_054_door", -26.31, 107.61, 2716.30, 12.9, -4.0, "abs"],  # its door, open, from the landing
	["house_054_shut", -26.31, 107.61, 2716.30, 12.9, -4.0, "abs"],  # shut: a rich house's leaves, the ring and straps
	["house_004_in", 14.38, 47.67, 2684.60, 12.0, -10.0, "abs"],  # in the kitchen from its door
	["house_004_door", 13.64, 44.20, 2684.60, 12.0, -4.0, "abs"],  # its door, open, from the landing
	["house_004_shut", 13.64, 44.20, 2684.60, 12.0, -4.0, "abs"],  # shut
	["house_007_back", -45.61, 33.17, 2671.90, 198.1, -8.0, "abs"],  # from the kitchen's back, its door open
	["house_007_back_shut", -45.61, 33.17, 2671.90, 198.1, -8.0, "abs"],  # and shut, the room in its own light
	["house_007_dusk", -47.06, 29.11, 2671.80, 10.6, -10.0, "abs"],  # its kitchen at 18:00, the fire lit
	["guide_wait", -71.3, -27.2, 2652.65, 231.9, -9.1, "abs"],  # sprint 8, step 8: the child of the house waiting at the Rooftop Way's foot at 16:45
	["guide_ladder", -80.4, -33.4, 2654.60, 230.2, -7.3, "abs"],  # and on the first stair-ladder up from the guest yard, leading, from beside it at the gallery's height
	["stair_greg", 1.41, 22.14, 2673.93, 250.0, -62.0, "abs"],  # as in Greg's screenshot of 27 Sep 2026: down on the first flight from the east at 08:59
	["stair_close_down", -0.66, 22.97, 2673.57, 355.2, -89.0, "abs"],
	["stair_close_south", -0.66, 22.97, 2673.07, 175.2, -55.0, "abs"],
	["stair_close_north", -0.33, 18.99, 2670.53, 355.2, -40.0, "abs"],
	# sprint 4, step 6: V-28's dusk (STATION_HOUR)
	["west_edge", -292.0, -12.0, 1.7, 2.0, 14.0],  # ISS-105: the west edge's fifteen poor houses (SHL-37) up the slope from below
	["west_edge_above", -240.0, 52.0, 2652.0, 262.0, -16.0, "abs"],  # and along them from above on their east, Hejie's roofs below
	["house_142", -275.7, 41.6, 2635.1, 0.0, -3.0, "abs"],  # H-SHL-142 from its yard, chapter 04's poor family's one-room home
	["house_142_door", -276.03, 45.67, 2635.10, 357.0, -4.0, "abs"],  # its door, open: one plank of raw wood (chapter 04, 4.2)
	["house_142_in", -276.09, 49.44, 2635.00, 30.3, -14.0, "abs"],  # in at the door: the hearth, the log, the beds rolled
	["house_142_back", -273.15, 51.78, 2634.95, 228.8, -12.0, "abs"],  # from the back corner to the door, the day coming in
	["house_142_back_shut", -273.15, 51.78, 2634.95, 228.8, -12.0, "abs"],  # the door shut: the smoke hole and the fire
	["house_142_back_w", -277.30, 52.04, 2634.95, 108.6, -14.0, "abs"],  # from the other corner, over the beds to the fire
	["house_142_up", -275.93, 51.13, 2634.70, 81.2, 55.0, "abs"],  # up at the smoke hole over the fire
	["house_142_dusk", -276.09, 49.44, 2635.00, 30.3, -14.0, "abs"],  # at 18:00: the fire, and the lamp lit on its shelf
	["chang_out", 68.5, 20.5, 2680.0, 5.0, 6.0, "abs"],  # M2 sprint 2: the chang house SHL-24 from its lane, its stair up to the drinking room
	["chang_in", 70.63, 27.4, 2682.0, 345.0, -12.0, "abs"],  # in at its door: the benches round three walls, the stove and its pan
	["chang_back", 73.5, 32.6, 2682.0, 232.0, -12.0, "abs"],  # from the back corner to the stove and the door
	["chang_dusk", 69.4, 28.6, 2682.0, 41.0, -10.0, "abs"],  # at 19:40: from the door's side to the back bench, the bard (seat 9) and the muleteer who plays (seat 7)
	["chang_window", 73.5, 32.6, 2682.0, 232.0, -12.0, "abs"],  # at 19:40 from the back corner to the stove, the door and the window's paper (ISS-136)
	# M2 sprint 3: the arrival by the Serchu road (tools/terrain/arrival.py; data/arrival.json)
	["arrival_v19", 340.0, -189.0, 2706.6, 305.0, -6.0, "abs"],  # V-19 on the cliff gallery's line, along it to the west (the rock on the left, the slot on the right)
	["arrival_gallery_side", 388.0, -168.0, 2716.0, 214.0, -14.0, "abs"],  # from over the slot's north bank, across to the gallery's rock face
	["arrival_cutting", 268.0, -152.5, 2701.4, 258.0, -3.0, "abs"],  # in the cutting through the nose, towards the Gate Chorten
	["arrival_v01", 166.0, -175.0, 2695.6, 290.0, -6.0, "abs"],  # V-01: out of the chorten, the town (chapter 02, V-01)
	["arrival_v01_turn", 166.0, -175.0, 2695.6, 52.0, 24.0, "abs"],  # and turning right and up to the monastery's face at 052, 27 degrees up
	["arrival_row", 150.0, -170.0, 2694.0, 280.0, -8.0, "abs"],  # down past the eight chortens' row to the south pavilion
	["arrival_ramp", -55.0, -88.0, 2654.0, 180.0, -18.0, "abs"],  # from over the north ramp, across the slot to the south ramp's legs
	["arrival_from_town", 20.0, -40.0, 2672.0, 120.0, 2.0, "abs"],  # from Tsongra's south edge, the south rim and the gallery's rock
	["arrival_chorten_east", 192.0, -170.5, 2694.8, 262.0, 2.0, "abs"],  # out of the cutting, the Gate Chorten's east portal ahead
	["arrival_mandala", 170.0, -175.0, 2693.4, 282.0, 72.0, "abs"],  # in its passage, the mandala on its ceiling
	["arrival_ser20", 441.0, -259.0, 2719.4, 300.0, -6.0, "abs"],  # SER-20 at the gallery's east end, the gallery beyond
	["arrival_eight", 142.0, -163.0, 2691.0, 290.0, -5.0, "abs"],  # the eight chortens from birth to nirvana, the road splitting round them
	["arrival_eight_side", 95.0, -168.0, 2685.5, 0.0, 4.0, "abs"],  # across the south branch to the row's middle: many doors, miracles, descent, reconciliation
	["arrival_caravan_gallery", 388.0, -168.0, 2716.0, 214.0, -14.0, "abs"],  # 13:12, the caravan in file on the gallery, from across the slot
	["arrival_caravan_row", 150.0, -170.0, 2694.0, 280.0, -8.0, "abs"],  # 13:42, past the eight chortens to the toll
	["arrival_caravan_ramp", -55.0, -88.0, 2654.0, 180.0, -18.0, "abs"],  # 14:30, down the south ramp's legs
	# M2 sprint 4: Samkha (tools/terrain/samkha.py; data/samkha.json)
	["samkha_v10_up", -130.0, -119.0, 2649.4, 87.0, -6.0, "abs"],  # V-10 at the chain bridge's middle, up the slot: the lower bridge, the Conch Fall
	["samkha_v10_down", -130.0, -119.0, 2649.4, 262.0, -8.0, "abs"],  # and down it: the fan, Hejie, the Yalong
	["samkha_bridge_side", -98.0, -133.0, 2657.5, 292.0, -6.0, "abs"],  # the chain bridge across the slot, from the south rim east of it
	["samkha_bridge_north", -130.0, -89.0, 2652.4, 180.0, -5.0, "abs"],  # along its deck from the gate passage's end
	["samkha_lower_bridge", -82.0, -110.0, 2617.0, 88.0, 9.0, "abs"],  # the lower cantilever bridge from down in the slot, west of it
	["samkha_caravan_lower", -82.0, -110.0, 2617.0, 88.0, 9.0, "abs"],  # 14:57, the caravan's yak on it
	["samkha_castle_v10", -130.0, -119.0, 2649.4, 0.0, 15.0, "abs"],  # M2 sprint 4, step 4: V-10 ahead, the castle rising from the rim, the gate's dark mouth
	["samkha_castle_south", -100.0, -150.0, 2669.5, 334.0, -8.0, "abs"],  # the castle on its rim and the bridge sagging into its gate, from the south rim
	["samkha_mouth", -130.0, -101.0, 2650.5, 0.0, 8.0, "abs"],  # the passage's mouth from the deck, its lintels and panel, the inner door beyond
	["samkha_passage", -130.0, -93.0, 2652.1, 0.0, 0.0, "abs"],  # in the passage: the lamp's niche, the house's door, the prayer wheel at the inner door
	["samkha_ward", -112.0, -70.0, 2650.6, 236.0, 12.0, "abs"],  # the ward: the tower's north face, the court hall's windows, the steps from the passage
	["samkha_roof", -124.0, -93.0, 2669.4, 324.0, 6.0, "abs"],  # on the roof: the tiled pavilion, its glass pane, the lha tho, the black banner
	["samkha_east", -96.0, -84.0, 2652.0, 262.0, 14.0, "abs"],  # the castle's east face from the way to the Yak Gate: the yellow bay, the ward's gate
	["samkha_pavilion", -130.0, -140.0, 2656.4, 180.0, -6.0, "abs"],  # SAM-04 from the bridge's south end: the niche, the toll table, the stele
	["samkha_pavilion_road", -114.0, -141.0, 2657.6, 252.0, -4.0, "abs"],  # SAM-04 from the road's end: the stele under its roof, the open east end
	["samkha_gate_shut", -130.0, -101.0, 2650.5, 0.0, 8.0, "abs"],  # 17:45: the gate shut and barred at the dusk horns
	["samkha_sherab", -128.6, -143.1, 2656.5, 240.0, -15.0, "abs"],  # step 6: Sherab at his table in the south pavilion at 10:00
	["samkha_gatekeeper", -129.0, -90.8, 2652.1, 196.0, -12.0, "abs"],  # the gatekeeper on his bench in the passage at noon
	["samkha_ponpo", -127.5, -93.5, 2669.5, 32.0, 2.0, "abs"],  # the Pönpo on his roof at 17:24 for the horns, turned to the monastery
	["samkha_dogs", -131.0, -88.6, 2670.4, 180.0, -24.0, "abs"],  # the mastiffs at the roof's edge barking at a crosser on the bridge, 15:16
	["samkha_deck_people", -130.0, -95.6, 2652.3, 180.0, -7.0, "abs"],  # from the passage's mouth: an old man coming over the deck, 15:16
	["samkha_gate_dusk", -130.0, -101.0, 2650.5, 0.0, 8.0, "abs"],  # 17:20: the gatekeeper at the gate before the bar
	["samkha_mules", -130.0, -119.0, 2649.4, 87.0, -11.0, "abs"],  # V-10 at 15:17: CV-02's mules and ponies on the lower bridge below
	["samkha_mules_close", -49.0, -99.5, 2627.6, 198.0, -8.0, "abs"],  # and from the north ramp's foot, coming over it
	["samkha_court", -125.4, -90.6, 2655.4, 326.0, -8.0, "abs"],  # step 7: the court hall at 09:30 from the stair's head, the dais under the windows
	["samkha_court_dais", -130.4, -90.2, 2655.2, 0.0, -2.0, "abs"],  # the Pönpo on his cushions from behind the petitioners' felts
	["samkha_stair_hall", -127.2, -86.4, 2652.6, 150.0, 18.0, "abs"],  # in the stair hall at the house's door: the stair up to the hall
	["samkha_court_scribe", -128.2, -84.0, 2655.3, 250.0, -18.0, "abs"],  # the scribe at his low table by a pillar
	["rivers_yalong", -150.0, -40.0, 2665.0, 262.0, -6.0, "abs"],  # M2 sprint 5, step 2: the Yalong from above Samkha's ula yard, the fan below
	["rivers_fan", -180.0, -100.0, 2612.0, 250.0, -10.0, "abs"],  # the slot's water out over the fan towards the Yalong
	["rivers_golden", 372.0, -178.0, 2714.0, 300.0, -30.0, "abs"],  # the Golden Slot from over its north rim, down towards the confluence
	["confluence_terrace", 199.0, -91.2, 2665.65, 113.0, -22.0, "abs"],  # M2 sprint 5, steps 3-4: V-02 on the Conch terrace's lip near its corner, the pool below and up the Serchu
	["confluence_first_sun", 199.0, -91.2, 2665.65, 113.0, -22.0, "abs"],  # the same at the first sun (07:51)
	["confluence_pool", 203.0, -84.0, 2669.0, 150.0, -38.0, "abs"],  # down on the pool from over the terrace's east end: the Dungchu in from the left, the Serchu ahead, the slot away right
	["confluence_above", 172.0, -50.0, 2684.0, 140.0, -22.0, "abs"],  # from above Pema Ö's place: the gorge's milky water and the Golden Slot's amber meeting, the slot's head
	["conch_fall", 150.0, -97.6, 2655.0, 88.0, -6.0, "abs"],  # the Conch Fall SAM-13 from over the slot 20 m below it
	["pema_o_front", 186.9, -81.0, 2665.7, 320.0, 14.0, "abs"],  # M2 sprint 5, step 4: Pema Ö Lhakhang from the Conch terrace, up its stair between the chortens
	["pema_o_quarter", 190.0, -62.0, 2674.2, 286.0, 2.0, "abs"],  # from the slope east of it: its east side, the kora's lean-to, the forecourt
	["pema_o_hall", 166.6, -56.9, 2671.6, 320.0, 6.0, "abs"],  # in its hall: Guru Rinpoche over the altar, the monks' rows
	["pema_o_door", 163.0, -52.6, 2671.4, 140.0, -10.0, "abs"],  # I-11: the confluence through its door from the hall
	["pema_o_kora", 159.4, -62.3, 2671.6, 320.0, -5.0, "abs"],  # along its kora corridor's west side, the wheels on the right
	["pema_o_above", 205.0, -95.0, 2700.0, 315.0, -30.0, "abs"],  # the temple, its stair, the terrace and the pool from over the slot
	["pema_lama_sang", 196.0, -86.5, 2665.7, 128.0, -8.0, "abs"],  # M2 sprint 5, step 5: Lama Orgyen Dorje laying juniper on the terrace's burner, 06:46
	["pema_lama_lip", 192.0, -88.0, 2665.9, 115.0, -10.0, "abs"],  # the lama at the lip at the first sun, the pool and the Serchu beyond, 07:47
	["pema_monks_bowls", 166.6, -56.9, 2671.6, 320.0, 2.0, "abs"],  # the two monks at the altar's bowls, 06:50
	["pema_monks_service", 166.6, -56.9, 2671.6, 320.0, -6.0, "abs"],  # the service: the monks on their rows, the lama on his seat, 08:10
	["pema_kora_woman", 157.9, -60.8, 2671.6, 325.0, -6.0, "abs"],  # the old woman on the kora ahead along its west side, 06:34
	["pema_dipper", 205.4, -95.2, 2658.3, 150.0, -14.0, "abs"],  # the dipper on its stone in the slot's head, 07:00
	["v02_0747", 199.0, -91.2, 2665.65, 113.0, -22.0, "abs"],  # M2 sprint 5, step 6: V-02 at the terrain's first sun (07:47)
	["v02_0800", 199.0, -91.2, 2665.65, 113.0, -22.0, "abs"],  # and at 08:00
	["v02_0815", 199.0, -91.2, 2665.65, 113.0, -22.0, "abs"],  # and at 08:15
	["v02_mist", 199.0, -91.2, 2665.65, 113.0, -22.0, "abs"],  # V-02 before the first sun: the mist on the pool, 07:30
	["v02_lift", 199.0, -91.2, 2665.65, 113.0, -22.0, "abs"],  # the mist lifting in the first light, 07:52
	["v02_conch", 205.0, -92.0, 2665.7, 123.0, -40.0, "abs"],  # down from the lip at the conch's glint in the eddy, 07:55
	["ngakpa_above", 212.0, -100.0, 2706.0, 328.0, -16.0, "abs"],  # M2 sprint 6, step 1: the ngakpa quarter round Pema Ö from over the pool
	["ngakpa_from_lane", 120.0, -62.0, 2672.0, 60.0, 4.0, "abs"],  # from Nétsang Lam below it: the quarter on its slope over the temple
	["ngakpa_lane", 150.6, -16.6, 2685.1, 10.0, 14.0, "abs"],  # up one of its side lanes (LN-043) between two groups
	["ngakpa_to_service", 186.9, -81.0, 2665.7, 320.0, 10.0, "abs"],
	["spring_queue", -106.2, 230.3, 2776.65, 337.0, -6.0, "abs"],  # M2 sprint 6, step 3: the Lukhang spring's queue in the blue before dawn, 05:44
	["spring_milk", -106.2, 230.3, 2776.65, 337.0, -6.0, "abs"],  # the old woman's milk on the naga's rock, 06:00
	["spring_afternoon", -106.2, 230.3, 2776.65, 337.0, -6.0, "abs"],  # the afternoon's trips, the talk behind the queue, 15:44
	["spring_shrine", -108.96, 235.23, 2776.5, 345.5, 2.0, "abs"],  # the klu khang's niche, its offerings, the spouts
	["spring_above", -92.0, 240.0, 2785.0, 251.6, -25.0, "abs"],  # the yard cut into the slope, from the slope east of it
	["spring_path", -84.0, 231.0, 2769.1, 275.0, 10.0, "abs"],  # up the path to it from upper Shöl's lanes
	["lookout_lane", 104.0, 204.0, 2780.4, 103.0, 2.0, "abs"],  # M2 sprint 6, step 4: the garden lane between its walls, 2.5 m high
	["lookout_ramp", 16.0, 215.6, 2772.0, 87.0, 6.0, "abs"],  # its foot at H-SHL-095's yard, up the shoulder between the walls
	["lookout_arrive", 252.5, 238.5, 2783.0, 34.0, 4.0, "abs"],  # the lane's end, the terrace opening on the gorge's rim
	["lookout_terrace", 258.8, 246.7, 2783.1, 34.0, 9.0, "abs"],  # V-13a's place at the parapet, facing the notch (034)
	["lookout_dusk", 257.7, 242.5, 2783.2, 34.0, 7.0, "abs"],  # the old woman's juniper on the burner, 17:06
	["gardens_above", 110.0, 236.0, 2816.0, 180.0, -32.0, "abs"],  # the lane and its walled orchards from the slope above
	["v13a_wide", 258.8, 246.7, 2783.1, 32.5, 8.0, "abs"],  # M2 sprint 6, step 5: V-13a at the terrace's tip, the notch at the normal lens, 17:08
	["v13a_1700", 258.8, 246.7, 2783.1, 32.5, 11.0, "abs", 14.0],  # Dungri Karpo in the notch in the viewpoint's frame (14 degrees): white at 17:00
	["v13a_1708", 258.8, 246.7, 2783.1, 32.5, 11.0, "abs", 14.0],  # gold, 17:08
	["v13a_1713", 258.8, 246.7, 2783.1, 32.5, 11.0, "abs", 14.0],  # pink, 17:13
	["v13a_1717", 258.8, 246.7, 2783.1, 32.5, 11.0, "abs", 14.0],  # the pink leaving the summit, 17:17
	["v13a_close", 258.8, 246.7, 2783.1, 32.5, 11.4, "abs", 9.0],  # the summit in the notch, drawn close (a 9-degree lens), 17:12
	["v05_peak", 540.0, 150.0, 2974.6, 31.2, 9.0, "abs"],  # V-05: the peak over the gorge from the Tsokchen roof, 17:08
	["tsongra_peak", 0.0, 0.0, 1.6, 32.9, 12.0],  # and hidden from Tsongra by the gorge's west rim (chapter 02, 2.7), 17:08  # M2 sprint 6, step 2: a man of the quarter climbing Pema Ö's stair to the 08:00 service, 07:46 (his way down past the kora to the terrace)
	["west_edge_dawn", -240.0, 52.0, 2652.0, 262.0, -16.0, "abs"],  # the west edge at 06:45: Norbu off down to the Landing
	["west_mani_dusk", -324.0, 79.6, 2634.0, 352.0, 14.0, "abs"],  # the poor family's grandmother round the western mani wall's first section at dusk, 18:09
	["west_mani_foot", -319.0, 48.0, 2625.7, 352.0, 18.0, "abs"],  # M2 sprint 6, step 6: the western mani wall SHL-10 up the lingkor's west side from its foot
	["west_mani_side", -336.5, 100.1, 2645.8, 60.0, 8.0, "abs"],  # its four walls stepping up the slope, from the west
	["conch_fall_below", 156.0, -97.6, 2647.6, 88.0, 10.0, "abs"],  # up the slot at the fall from below its pool of foam
	["conch_fall_sun", 156.0, -97.6, 2647.6, 88.0, 10.0, "abs"],  # the same at the first sun, its spray against the light
	["lower_row", -34.0, 67.0, 1.6, 300.0, 5.0],  # IMP-019: lower Shöl's lane before H-SHL-009, 015 and 023, three households' own stairs
	["crowns_row", -40.0, 56.0, 2696.5, 355.0, -2.0, "abs"],  # ISS-109: level with the crowns of H-SHL-009, 015 and 023
	["crowns_031", 48.4, 0.0, 2681.5, 0.0, -3.0, "abs"],  # and of H-SHL-031 and its neighbours
	["upper_row", -92.0, 162.0, 1.6, 78.0, 2.0],  # IMP-019: along the Rooftop Way's row of log houses (H-SHL-110 to 068), from its lane
	["upper_over", -10.0, 110.0, 2750.0, 305.0, -14.0, "abs"],  # and over the upper town's rows from the south-east
	# IMP-023, lanes and terraces (7 Oct 2026): up three side lanes from their feet at a third-person camera's height, down
	# one from its head, and along two rows' front yards
	["lane_028_up", -69.3, 173.0, 2.2, 10.0, 14.0],  # LN-028, between H-SHL-074 and 064, a 7.3 m flight
	["lane_031_up", -72.1, 187.44, 2.2, 10.0, 14.0],  # LN-031, between H-SHL-076 and 066
	["lane_031_down", -69.5, 202.2, 2.2, 190.0, -18.0],  # and down it from its head
	["lane_011_up", -37.63, 67.74, 2.2, 10.0, 14.0],  # LN-011 in lower Shöl, between H-SHL-015 and 009
	["yard_row9", -73.6, 173.1, 2.6, 283.0, -8.0],  # along H-SHL-074's yard and row 9's beyond it
	["yard_row8", -74.1, 158.6, 2.6, 282.0, -8.0],  # along H-SHL-077's yard, the Rooftop Way's row
	["flight_yard_007", -54.65, 28.1, 2.2, 100.0, 8.0],  # YL-006: up from LN-003 into H-SHL-007's yard, the house to enter
	["flight_yards_022", -64.59, 43.07, 2.2, 99.0, 6.0],  # YL-001: from H-SHL-022's yard up into 013's, through the wall between
	["flight_mouth_015", -63.31, 117.2, 2.2, 10.0, 14.0],  # ML-002: from the slope up through the yards' wall into LN-015
	["flight_mouth_006", 28.85, 20.9, 2.0, 10.0, 12.0],  # ML-001: from the slope up into LN-006, walled since ISS-116
	["flight_head_022", -73.2, 38.0, 2664.6, 28.0, 10.0, "abs"],  # YL-011 (ISS-115): up LN-002 to its head, the flight on into H-SHL-022's yard
	["flight_head_022_down", -63.6, 43.2, 2672.3, 268.0, -16.0, "abs"],  # and down it from the yard to the lane's head
	["flight_head_022_up", -74.6, 44.3, 2668.8, 96.0, 16.0, "abs"],  # from LN-002's top landing, up it into the yard
	# IMP-023 (1): washing hung out to dry (world/laundry.gd), along three households' lines
	["laundry_007", -49.7, 25.9, 1.75, 75.0, -2.0],  # H-SHL-007's three robes, a son in the monastery
	["laundry_082", -93.0, 176.2, 1.75, 80.0, -2.0],  # H-SHL-082's, robes and a monk's shirt
	# IMP-021 (3): the lamps at dusk (world/lamps.gd), at their hours (STATION_HOUR)
	["lamps_lhakhang", -2.5, 95.0, 1.7, 90.0, 3.0],  # the Mani Lhakhang's door from its forecourt, its altar lit
	["lamps_yard", -79.0, -60.0, 2651.6, 36.0, -9.0, "abs"],  # the fire in Dechen-tsang's front yard
	["lamps_v28", -95.0, 205.0, 1.6, 140.0, -12.0, "on top"],  # the embers in the roofs' burners from V-28's
	["lamps_tunnel", -3.4, 55.9, 2687.9, 355.2, 14.0, "abs"],  # in the tunnel under three houses, up the stair to its niche's lamp
	["lamps_sang", -75.6, -21.4, 2661.75, 285.0, 2.0, "abs"],  # Dechen-tsang's burner in the blue hour, its ember (dechen_roof_sang later)
	# IMP-023 (3), Greg's 1773: the plank-and-rope bridge over the Sky Stair (tools/town/bridges.py), from the stair below it
	["bridge_from_stair", -12.4, 166.0, 1.7, 356.0, 16.0],  # up the stair at the bridge across it
	["bridge_side", -6.0, 150.0, 6.0, 330.0, 10.0],  # from over the stair's east side, the bridge between its two houses
	["bridge_crossing", -6.0, 150.0, 6.0, 330.0, 10.0],  # as bridge_side at 14:31: a woman stopped half way across (IMP-027)
	["bridge_crossing_up", -12.4, 166.0, 1.7, 356.0, 16.0],  # up the stair at 15:26: an old man half way across, over the pilgrims
	["bridge_crossing_near", -25.94, 183.52, 2753.0, 97.0, -6.0, "abs"],  # from H-SHL-061's roof behind the west end, at 14:31
	# IMP-023 (2): what households keep by their walls (world/corners.gd)
	["corners_002", -20.0, 21.2, 2.0, 330.0, -14.0],  # H-SHL-002's basket, sacks and churn, from its yard's east end
	["corners_016", 36.0, 25.6, 1.6, 15.0, -12.0],  # H-SHL-016's firewood, and dung cakes drying on its wall
	["corners_040", 57.0, 34.6, 2.0, 15.0, -14.0],  # H-SHL-040's firewood, dung cakes and pots
	["v28_dusk", -95.0, 205.0, 1.6, 168.0, -9.0, "on top"],
	["v28_moon", -95.0, 205.0, 1.6, 172.0, 13.0, "on top"],
	["mist_v28", -95.0, 205.0, 1.6, 168.0, -9.0, "on top"],  # IMP-021: the dawn's river mist below, from V-28 (06:45)
	["mist_v14", -20.0, 255.0, 1.6, 170.0, -8.0, "on top"],  # and from the top of the Sky Stair as it lifts (07:10)
	["rays_v28", -95.0, 205.0, 1.6, 240.0, 1.0, "on top"],  # the sun low over the western ridge, its rays (16:05)
	["haze_v28", -95.0, 205.0, 1.6, 168.0, -6.0, "on top"],  # the evening's haze in the valley's bottom (18:00)
	["v28_night", -95.0, 205.0, 1.6, 168.0, -9.0, "on top"],  # as v28_dusk, at 19:00: night since 18:35 (K11b)
	["v28_late", -95.0, 205.0, 1.6, 168.0, -9.0, "on top"],  # and at 21:00: each household's lamps out at its own bedtime (ISS-039)
	# sprint 6, step 3: the named eight at their places (--people; NAMED_SHOTS: who, at what hour, and the camera from how
	# far before them, how high and how far round to their right)
	["named_talkers", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["named_pitch", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["named_stalls", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["named_gate", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["named_door", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["named_spring", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	# sprint 6, step 4: the twelve generic at their places, and Tsongra at 16:00 and 16:10 with all twenty (STATION_HOUR)
	["generic_knucklebones", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["novices_stair", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],  # IMP-024: the novices down the Sky Stair, at the wheel, at knucklebones
	["novices_wheel", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["novices_knucklebones", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["generic_elders", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["generic_stalls", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["generic_porter", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["generic_barkor", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	["generic_clerk", 0.0, 0.0, 0.0, 0.0, 0.0, "named"],
	# sprint 6, step 5: Samkha's north ramp, the Yak Gate at its head, the bridge's deck at its foot
	["ramp_from_gate", -55.0, -80.5, 2654.0, 178.0, -32.0, "abs"],  # from the gate's roof, down the ramp's legs
	["ramp_above", -52.0, -55.0, 2685.0, 185.0, -30.0, "abs"],  # the whole cut from above the gate
	["ramp_from_bridge", -55.0, -114.0, 2627.0, 358.0, 22.0, "abs"],  # up from the deck: the legs, the gate over them
	["gate_street", -55.0, -70.0, 1.6, 182.0, -4.0],  # the Yak Gate from Nétsang Lam's side
	# sprint 7, step 1: Dechen-tsang's rooms (the house at -75, -40; the guest yard a metre up, at 2,651 m, the rooms'
	# floors 15 cm over it; STATION_HOUR 15:00, the sun in the west)
	["dechen_yard2_w", -72.0, -29.5, 2652.6, 248.0, -3.0, "abs"],  # the guest yard: the Tibetan room's door and window in the west range
	["dechen_yard2_e", -79.0, -31.0, 2652.6, 100.0, -3.0, "abs"],  # and across it the Chinese room's and the guest room's in the east
	["dechen_tibetan_in", -85.9, -35.7, 2652.75, 295.0, -14.0, "abs"],  # in the Tibetan room from its door: the benches, the tables, the brazier
	["dechen_tibetan_door", -89.0, -31.3, 2652.6, 125.0, -6.0, "abs"],  # from its head, back towards the door and the window
	["dechen_yard2_w_shut", -72.0, -29.5, 2652.6, 248.0, -3.0, "abs"],  # the guest yard's rooms' doors shut (ISS-084): the Tibetan room's
	["dechen_yard2_e_shut", -79.0, -31.0, 2652.6, 100.0, -3.0, "abs"],  # the Chinese room's and the guest room's
	["dechen_tibetan_door_shut", -89.0, -31.3, 2652.6, 125.0, -6.0, "abs"],  # and from inside the Tibetan room, its door shut
	["dechen_chinese_in", -64.3, -34.3, 2652.75, 80.0, -10.0, "abs"],  # in the Chinese room from its door: the square table, the armchairs
	["dechen_chinese_desk", -60.9, -35.6, 2652.7, 335.0, -12.0, "abs"],  # Yang's writing table under the window
	["dechen_guest_in", -64.3, -27.3, 2652.75, 75.0, -14.0, "abs"],  # the guest room: the bed, the chest, the saddlebags
	["dechen_kitchen_in", -81.0, -22.1, 2652.75, 300.0, -12.0, "abs"],  # the kitchen from its door's corner: the stove, the kettles
	["dechen_kitchen_door", -83.6, -26.2, 2652.75, 2.0, -8.0, "abs"],  # the kitchen's door from the yard, open (ISS-105)
	["dechen_kitchen_shut", -83.6, -26.2, 2652.75, 2.0, -8.0, "abs"],  # and shut
	["dechen_yard1", -75.0, -50.0, 2651.6, 0.0, -2.0, "abs"],  # the business yard from the gate: the passage up to the guest yard
	# M2 sprint 8, step 1: Yard 3, the rear garden two metres up (the house's frame + (-75, -40), its level 2,652 m): the
	# chapel's block at its back up its stone stair, Dolkar's range on its south side with its gallery up a timber stair
	["dechen_garden_n", -57.5, -30.5, 2653.6, 28.0, 7.0, "abs"],  # from the garden's south-west: the chapel, its stair, the apple
	["dechen_garden_s", -56.5, -23.2, 2653.6, 158.0, 6.0, "abs"],  # from the chapel stair's foot: Dolkar's range, its gallery and stair, the walnut
	["dechen_garden_above", -63.0, -19.0, 2662.0, 128.0, -24.0, "abs"],  # the garden from over the master range's east end
	["dechen_chapel_in", -52.6, -20.5, 2656.6, 92.0, -8.0, "abs"],  # in the chapel from its door: the east wall, where the altar will stand
	["dechen_chapel_door", -47.6, -21.0, 2656.6, 280.0, -6.0, "abs"],  # from its east end back to the door and the window
	["dechen_gallery", -52.4, -31.05, 2656.54, 92.0, -3.0, "abs"],  # on Dolkar's gallery from its west end: her door, the lattice
	["dechen_dolkar_in", -50.9, -32.6, 2656.54, 150.0, -10.0, "abs"],  # in her reception room from its door
	["dechen_clocks", -49.75, -34.7, 2656.44, 180.0, -4.0, "abs"],  # M2 sprint 8, step 2: the five French clocks on their shelf
	["dechen_dolkar_dusk", -50.9, -32.6, 2656.54, 150.0, -10.0, "abs"],  # her room at 17:45, the clock ticking, her lamp lit
	["dechen_garden_night", -57.5, -30.5, 2653.6, 28.0, 7.0, "abs"],  # the garden at 20:30: the chapel's lamps and her room's coals within
	# M2 sprint 8, step 3: the house's people (--people, each at its hour)
	["dechen_lama_reading", -52.6, -22.6, 2656.6, 42.0, -12.0, "abs"],  # 06:40, the household lama at his reading in the chapel
	["dechen_sewers", -69.0, -50.5, 2651.6, 75.0, -10.0, "abs"],  # 09:00, the tea-sewers under Yard 1's east gallery
	["dechen_steward_gate", -72.0, -71.0, 1.6, 340.0, -2.0],  # 10:02, the steward and two servants out of the gate with the tea money
	["dechen_dice", -82.0, -61.5, 2651.6, 285.0, -10.0, "abs"],  # 10:20, the pieman and the dice in Yard 1's corner by the gate
	["dechen_dolkar_clock", -50.9, -32.6, 2656.54, 158.0, -8.0, "abs"],  # 17:28, Dolkar winding the clock
	# M2 sprint 8, step 4: the house at night (--people, each at its hour)
	["dechen_bard", -79.2, -33.7, 2653.65, 48.0, -22.0, "abs"],  # 21:15, the bard by the fire in the guest yard, his listeners round it
	["dechen_gate_barred", -72.0, -71.0, 1.6, 340.0, -2.0],  # 22:30, the gate shut and barred, from Netsang Lam
	["dechen_mastiffs", -75.0, -50.0, 2651.6, 180.0, -8.0, "abs"],  # 22:30, the two mastiffs loose in Yard 1
	# M2 sprint 9, step 1: the Caravan Ramp and the Caravan Ground (tools/town/caravan_ground.py, world/camp.gd)
	["camp_ramp_head", -122.0, -151.0, 2656.8, 190.0, -12.0, "abs"],  # the ramp's head past the south pavilion's front, its first leg going down
	["camp_landing", -144.7, -299.0, 2638.1, 352.0, 3.0, "abs"],  # on the first switchback's landing: its two legs parting, the strip of slope between them behind their walls
	["camp_ramp_above", -110.0, -230.0, 2674.0, 262.0, -24.0, "abs"],  # over the ridge foot: the zigzags down its face to the camp
	["camp_from_field", -285.0, -165.0, 2579.5, 128.0, 8.0, "abs"],  # from by the fodder yard across the ramp's legs on the face, lit
	["camp_overview", -230.0, -215.0, 2595.3, 272.0, -13.0, "abs"],  # from the ramp's fifth leg over the Caravan Ground at 16:00
	["camp_windbreaks", -305.0, -214.0, 2569.2, 238.0, -8.0, "abs"],  # CV-02's tea stacked into windbreaks, its hay, at 16:00
	["camp_fodder", -279.0, -176.0, 2581.4, 291.0, -13.0, "abs"],  # the fodder yard GAR-13 from the ramp's foot: the ricks, the straw, the sellers' lean-to by its gate
	["camp_dung", -296.0, -252.0, 2567.1, 200.0, -5.0, "abs"],  # the dung-drying walls GAR-07 on the slope under the graveyard
	["camp_wool", -372.0, -238.0, 2568.3, 228.0, -7.0, "abs"],  # CV-01's wool bales stacked by the black tents' place, its hay, at 12:00
	# M2 sprint 9, step 2: CV-02's whole herd (world/herd.gd; where it is when: tools/town/herd_probe.gd)
	["herd_gallery", 388.0, -168.0, 2716.0, 214.0, -14.0, "abs"],  # 13:25, the herd in file on the cliff gallery, from across the slot
	["herd_row", 150.0, -170.0, 2694.0, 280.0, -8.0, "abs"],  # 13:55, abreast past the eight chortens to the toll
	["herd_pavilion", -105.0, -128.0, 2660.0, 222.0, -14.0, "abs"],  # 14:35, turning at the south pavilion down the Caravan Ramp's head
	["herd_switchback", -164.0, -196.5, 2629.3, 195.0, -12.0, "abs"],  # 15:12, round the second switchback, two abreast
	["herd_ramp_above", -110.0, -230.0, 2674.0, 262.0, -24.0, "abs"],  # 15:15, spread down the zigzags of the ridge foot
	["herd_from_hejie", -280.0, -150.0, 2580.2, 128.0, 8.0, "abs"],  # 15:20, a dark ribbon down the ridge foot, from the fan channel's bank below Hejie
	["herd_ramp_foot", -270.0, -200.0, 2581.8, 20.0, 4.0, "abs"],  # 16:05, off the ramp's last leg onto the Caravan Ground
	["herd_camp", -322.0, -256.0, 2569.6, 35.0, -6.0, "abs"],  # 16:40, halted in a block by the tea-case windbreaks, the hay brought
	# M2 sprint 9, step 3: the camp at dusk (world/herd.gd after the halt, world/camp_animals.gd, world/camp.gd's fires)
	["camp_unloading", -322.0, -256.0, 2569.7, 35.0, -6.0, "abs"],  # 16:25, CV-02 unloaded where it halted, the stacks rising
	["camp_hay", -296.0, -262.0, 2569.8, 305.0, -10.0, "abs"],  # 17:05, at the hay and lying down in twos and threes, the fires lit
	["camp_tents", -398.0, -276.0, 2558.6, 292.0, -4.0, "abs"],  # 17:20, the two crews' black tents by GAR-03, CV-01's yak lying round
	["camp_picket", -352.0, -224.0, 2569.6, 322.0, -6.0, "abs"],  # 17:30, the mules and ponies on the picket line, a mastiff at its end
	["camp_dusk", -250.0, -215.0, 2588.9, 268.0, -9.0, "abs"],  # 17:40, the Caravan Ground at dusk from the ramp's fifth leg
	["camp_fire", -336.5, -226.5, 2568.0, 42.0, -8.0, "abs"],  # 18:30, a crew's dung fire by the windbreak, its drovers
	["camp_night", -245.0, -235.0, 2591.0, 278.0, -7.0, "abs"],  # 21:00, the camp's six fires in the dark, some 130 yak lying
	["camp_cv01", -364.0, -233.0, 2570.7, 238.0, -7.0, "abs"],  # 12:30, CV-01's yak at their hay by their wool and tents
	# M2 sprint 9, step 4: Hejie at a distance (STATION_HOUR)
	["hejie_v15", -457.0, -95.0, 2561.8, 80.0, 4.0, "abs"],  # V-15: up River Street from the Water Gate, the lanterns lit
	["hejie_street", -324.0, -88.6, 2578.5, 104.0, 5.0, "abs"],  # up River Street past the inn to the teahouse's bend, its shop-houses fronting it
	["hejie_east_gate", -200.0, -86.0, 2605.4, 275.0, 4.0, "abs"],  # the East Gate from outside, its arch and pavilion
	["hejie_temple", -297.5, -67.5, 2584.4, 0.0, 6.0, "abs"],  # the Guandi temple's courtyard: the burner, the flagpoles, the hall on its terrace
	["hejie_above", -310.0, 45.0, 2620.2, 185.0, -14.0, "abs"],  # Hejie's grey roofs from Shöl's west edge above
	["hejie_dusk", -310.0, 45.0, 2620.2, 185.0, -14.0, "abs"],  # Hejie at dusk, its windows lit
	["hejie_v03", -745.0, -118.0, 2646.0, 84.0, -8.0, "abs"],  # V-03: Hejie on its fan from Pharkha's bluff across the Yalong (V-01 cannot see it on the real ground)
	["hejie_v04", 330.0, -5.0, 2745.6, 264.0, -8.0, "abs"],  # V-04: Hejie at 264 from the Lhabab Chorten's terrace
	["hejie_samkha", -130.0, -119.0, 2649.4, 281.0, -12.0, "abs"],  # from the chain bridge at Samkha (V-10), Hejie's whole length below
	["hejie_landing", -494.0, -122.0, 2539.9, 62.0, 9.0, "abs"],  # from the Landing's beach: the west wall, the Water Gate, the town climbing behind
	# M2 sprint 11, step 1: the Castle Ramp SAM-10 (tools/town/castle_ramp.py)
	["castle_ramp_gate", -211.5, -80.6, 2599.5, 130.0, 12.0, "abs"],  # from Hejie's East Gate up the ramp's last leg to its second landing
	["castle_ramp_head", -109.0, -64.5, 2650.4, 300.0, -10.0, "abs"],  # from the ward's corner down the first leg, Hejie below
	["castle_ramp_landing1", -207.0, -4.0, 2625.8, 125.0, 9.0, "abs"],  # at the first switchback, back up the first leg to the castle
	["castle_ramp_leg2", -200.0, -40.0, 2618.0, 168.0, -6.0, "abs"],  # down the second leg to the bank, the East Gate's pavilion to the right
	["castle_ramp_above", -150.0, 30.0, 2668.0, 228.0, -22.0, "abs"],  # the Z from above Norbu-tsang: the castle's flank, the ramp, Hejie
	# M2 sprint 11, step 2: Samkha's houses (tools/town/builder.py `samkha`)
	["castle_lane", -111.9, -44.2, 2647.6, 300.0, -6.0, "abs"],  # down Castle Lane from its head, the retainers' houses either side
	["castle_lane_up", -150.8, -21.5, 2642.3, 125.0, 7.0, "abs"],  # up Castle Lane's steps towards the castle
	["samkha_houses_above", -122.0, 6.0, 2676.0, 200.0, -30.0, "abs"],  # the retainers' terraces, the ramp and the castle from above
	["samkha_poor", -135.0, -51.5, 2646.0, 180.0, 9.0, "abs"],  # the poor houses under the ward's north wall
	# M2 sprint 11, step 3: the ula yard SAM-09 and the stables SAM-08 (kit/samkha.py ula_yard, stables; world/ula_yard.gd)
	["ula_yard", -166.3, 2.6, 2637.6, 252.0, -7.0, "abs"],  # from its north-east corner at the afternoon's count: the animals at the rings, the owners
	["ula_yard_morning", -166.3, 2.6, 2637.6, 252.0, -7.0, "abs"],  # the morning's count, the overnight animals
	["ula_yard_above", -165.9, 21.9, 2651.6, 220.0, -30.0, "abs"],  # over the stables' roof: the yard, the ramp's switchback below, Hejie
	["stables_front", -184.4, 6.0, 2637.3, 40.0, 6.0, "abs"],  # the stables' front from the yard, the Pönpo's mule at its door
	["ula_gate_out", -165.4, -7.2, 2638.9, 310.0, -3.0, "abs"],  # into the yard at its gate from the saddle
	# M2 sprint 11, step 4: the Leat Fall SAM-11, the 1861 breach SAM-16, the latrine's midden SAM-12
	["leat_fall", -55.0, -110.6, 2626.0, 276.0, 9.0, "abs"],  # up the slot from the lower bridge's deck: the Leat Fall on its north face
	["leat_fall_lip", -79.0, -105.5, 2645.0, 300.0, 12.0, "abs"],  # across the face from over the slot: the culvert's lip and the water going down
	["breach_1861", -79.0, -71.0, 2651.0, 238.0, -6.0, "abs"],  # the ruined outwork from the road to the Yak Gate, the castle behind
	["breach_close", -84.5, -79.5, 2649.8, 268.0, -4.0, "abs"],  # into its broken east end, the patch of dry stone, the rubble
	["latrine_midden", -128.5, -121.0, 2650.0, 340.0, 6.0, "abs"],  # from the chain bridge: the latrine bay, its stain, the midden's ledge
	# M2 sprint 11, step 5: Samkha's people (with --people, each at its hour; the great court's on 9 November, STATION_DAY)
	["samkha_ward_hearing", -123.0, -71.0, 2650.7, 250.0, -5.0, "abs"],  # the ward at 08:12: the morning's parties by the steps
	["samkha_great_ward", -123.0, -71.0, 2650.7, 250.0, -5.0, "abs"],  # the same on a great court's day: the great cases' parties
	["samkha_great_court", -135.8, -90.9, 2655.4, 35.0, -10.0, "abs"],  # the hall from its south-west corner: the felts, the dais, the east wall's waiting
	["samkha_great_headmen", -126.8, -87.4, 2655.4, 280.0, -12.0, "abs"],  # the hamlets' headmen by the west wall, the Shöl headman among them
	["toll_count", -127.5, -144.2, 2656.6, 257.0, -8.0, "abs"],  # a tea porter's load counted at Sherab's table, 09:47
	["toll_argue", -127.5, -144.2, 2656.6, 257.0, -8.0, "abs"],  # Ngödrup's men arguing the Litang caravan's count, 10:12
	["samkha_lane_people", -111.9, -44.2, 2647.6, 300.0, -6.0, "abs"],  # Castle Lane at 11:00 from its head, its own about it
	# M2 sprint 12, step 1: R-01's last kilometre from the Serchu Zampa down the south bank (tools/terrain/serchu_road.py)
	["serchu_road_zampa", 1238.5, -529.3, 2812.7, 271.0, -4.0, "abs"],  # from the Zampa's south end down the road, the river on the right
	# M2 sprint 12, step 2: the Serchu Zampa, its gateway chorten and the porters' rest
	["zampa_north", 1291.5, -516.2, 2819.4, 284.0, -4.0, "abs"],  # down the north bank's road to the gateway chorten and the bridge
	["zampa_deck", 1248.0, -524.5, 2813.6, 20.6, 0.0, "abs"],  # on the deck, north through the chorten's passage
	["zampa_side", 1215.0, -529.1, 2810.3, 70.0, -3.0, "abs"],  # from the south road downstream: its cantilevers over the Serchu
	["zampa_rest", 1228.0, -527.5, 2811.5, 144.0, -8.0, "abs"],  # the porters' rest beside the road at the Zampa's south end
	# M2 sprint 12, step 3: along the road
	["serchu_mani", 751.0, -348.5, 2752.7, 287.0, -4.0, "abs"],  # down the road along the mani wall SER-15, the road either side
	["serchu_cairn", 992.2, -461.0, 2783.6, 133.0, -3.0, "abs"],  # the durtro path's cairn by the road, the path up the slope
	["serchu_washings", 846.1, -397.2, 2755.5, 18.0, -22.0, "abs"],  # from the slope below the road down to the gold washings on the bank
	["serchu_washings_close", 844.9, -390.0, 2749.2, 37.0, -10.0, "abs"],  # the huts and the troughs at the water's edge
	# M2 sprint 12, step 4: the Shade Wood SER-16
	["forest_road", 851.0, -409.5, 2766.0, 195.0, 28.0, "abs"],  # from the road's river edge up over its cut wall into the wood
	["forest_from_castle", -130.0, -89.0, 2668.5, 160.0, -4.0, "abs"],  # from Samkha Khar's roof over the slot to the wood on the south rim
	["forest_above", 700.0, -560.0, 2905.0, 335.0, -18.0, "abs"],  # from high on the ridge: the wood down the bank to the road and the river
	# M2 sprint 12, step 5: the north bank at the mills (data/serchu_mills.json)
	["mills_from_road", 508.9, -262.0, 2723.7, 13.9, -12.0, "abs"],  # from R-01 across the river: the footbridge, the mills, the leat, the flank
	["mills_row", 567.1, -216.2, 2712.9, 318.9, -7.0, "abs"],  # along the leat walk past the upper mill, the row going down the bank
	["mill_arch", 517.9, -225.2, 2706.0, 350.3, -8.6, "abs"],  # before SER-07's arch: its tail race, its wheel turning in the dark
	["mill_inside", 540.4, -209.0, 2710.9, 116.6, -12.6, "abs"],  # SER-08's door: the stones, the hopper, the sacks
	["wheel_house", 415.4, -200.7, 2697.5, 43.1, 7.0, "abs"],  # the lower water prayer wheel SER-09.1 from below, the leat out of it to its race
	["footbridge", 522.0, -227.1, 2706.2, 147.5, -7.2, "abs"],  # the footbridge SER-11 from the north bank, the path zigzagging up the south bank
	["footbridge_side", 515.2, -234.5, 2702.9, 105.9, 7.1, "abs"],  # its logs on their cribs over the Serchu, from downstream on the north bank
	["yak_road_above", 530.0, -140.0, 2757.3, 183.4, -28.0, "abs"],  # from high on the flank: the Yak Road's legs, the mills, the leat, the river, the road
	["barley_terraces", 478.5, -152.1, 2734.6, 205.0, -20.0, "abs"],  # from the Yak Road's third leg down the flank: the barley terraces in stubble, hay on the benches, the mills below
	["leat_intake", 588.8, -250.8, 2714.8, 139.1, -5.2, "abs"],  # the weir and the leat's head by the river
	# M2 sprint 12, step 6: the road's people and CV-02 over the Zampa (world/serchu_people.gd, world/caravan.gd, world/herd.gd)
	["caravan_zampa", 1222.0, -538.0, 2813.2, 56.3, -0.4, "abs"],  # 11:00: CV-02's ten over the Serchu Zampa from its gateway chorten, the herd behind on the north bank's road
	["herd_zampa", 1279.5, -498.8, 2822.6, 234.2, -10.0, "abs"],  # 11:12: the herd in file through the gateway chorten and over the deck
	["caravan_mani", 713.4, -291.4, 2754.4, 202.0, -11.5, "abs"],  # 12:18: the caravan coming down the road past the mani wall by its south side, from across the river
	["road_pilgrim", 713.4, -291.4, 2754.4, 202.0, -11.5, "abs"],  # 08:55: a pilgrim coming down past the mani wall, a carrier going up by its north side, from across the river
	["road_rest", 1228.0, -527.5, 2811.5, 144.0, -8.0, "abs"],  # 08:43: a carrier propping his tea on the porters' rest's ledge by the Zampa
	["washers_fires", 868.0, -389.5, 2749.6, 293.7, -6.0, "abs"],  # 19:00: the gold washers round their huts' fires
	["washers_work", 846.1, -397.2, 2755.5, 18.0, -22.0, "abs"],  # 10:30: the washers at the troughs and crouched at the water's edge with their pans
	["woodcutters", 731.9, -371.6, 2768.5, 134.0, 8.9, "abs"],  # 11:00: a woodcutter at his larch above the road
	["miller_door", 509.5, -220.3, 2705.9, 56.3, 14.6, "abs"],  # 10:40: SER-07's miller at his door
	["zampa_opening", 1300.0, -521.0, 2820.4, 271.1, -7.3, "abs"],  # 14:25: a new game's first sight: the Zampa's gateway chorten and the bridge, the road down the south bank
	["mon_v01", 156.6, -172.1, 1.6, 52.0, 27.0],  # M2's acceptance 1: ten metres out of the Gate Chorten's west mouth (V-01's eye is in it), turned right and up to the monastery's face at 052, 27 degrees up
	["mon_from_lookout", 258.0, 245.0, 2783.1, 105.0, 20.0, "abs"],  # M2 sprint 13: from the Gorge Rim Lookout across the gorge, the monks' houses stacked up the west face
	["mon_v09", 330.0, 185.0, 2723.7, 105.0, 32.0, "abs"],  # V-09: from the upper cantilever bridge's place up the face, 170 m above (chapter 02)
	["mon_from_tsongra", 2.0, -13.0, 1.6, 76.0, 14.0],  # from Tsongra to the spur: the monastery over the town
	["mon_from_road", 508.9, -262.0, 2723.7, 8.0, 28.0, "abs"],  # from R-01 by the mills: the south flank's rows above the north bank
	["mon_south_flank", 575.0, -150.0, 2905.0, 355.0, -6.0, "abs"],  # out over the slope below the south flank: the M2 and their yards on their podia
	["mon_wall_south", 600.0, -125.0, 2896.0, 352.0, -4.0, "abs"],  # step 4: out over the slope at the wall MON-21's height, its south run with the khamtsen's ranges over it
	["mon_east_gate", 735.0, 74.0, 1.6, 272.0, 4.0],  # the East Gate's range from the Yak Road's side, the wall meeting its ends
	["mon_upper_gate", 660.0, 292.0, 1.6, 180.0, 0.0],  # the Upper Gate's door in the wall's north run, from the ritro's way
	["mon_face_close", 400.0, 190.0, 2916.0, 97.0, 2.0, "abs"],  # the west face close, from out over the gorge at the houses' height
	["mon_courtyard", 535.0, 95.0, 1.6, 0.0, 8.0],  # in the courtyard MON-02 before the Tsokchen (AT=gonpa)
	["steps_foot", 237.0, -71.0, 1.6, 52.0, 16.0],  # M3 sprint 1: the 1,080 steps from their foot by the Conch Bridge
	["steps_landing6", 333.9, -17.2, 1.6, 12.0, 24.0],  # from landing 6, the Lhabab Chorten's platform, up the zigzag across the face
	["steps_face", 280.0, 12.0, 2805.0, 96.0, 2.0, "abs"],  # the zigzag across the face from out over the gorge
	["steps_top", 457.5, 54.5, 1.6, 252.0, -24.0],  # from the South Gate's forecourt down the last flights
	["conch_bridge_w", 186.0, -64.0, 2675.5, 78.0, -6.0, "abs"],  # step 2: the way from Pema Ö along the bank onto the Conch Bridge
	["conch_bridge_side", 222.0, -88.0, 2672.0, 4.0, 2.0, "abs"],  # the Conch Bridge from downstream, the tsenkhang on the prow
	["steps_lhabab", 339.5, -10.5, 1.6, 222.0, 10.0],  # step 3: the Lhabab Chorten on its terrace beside landing 6's platform
	["steps_landing12", 362.39, 17.73, 2794.11, 64.0, 2.0, "abs"],  # landing 12: its terrace with the byang chub chorten and the rest house
	["steps_niche", 342.2, 15.3, 1.6, 281.0, -6.0],  # a niche of prayer wheels at landing 8
	["parkhang_front", 279.0, -88.0, 2688.0, 340.0, 9.0, "abs"],  # step 4: the Parkhang from below its entrance, on its podium
	["parkhang_court", 286.0, -32.0, 2712.0, 200.0, -30.0, "abs"],  # into its court from above, by the steps' first bend
	["steps_pilgrims", 333.4, -16.0, 1.6, 12.0, 8.0],  # step 5: from landing 6 up flight 7 at 08:30, a pilgrim climbing, a novice coming down
	["steps_climb_close", 335.44, -8.26, 2746.5, 190.0, -22.0, "abs"],  # a pilgrim climbing towards the camera on flight 7 (08:30)
	["steps_double_ninth", 335.2, -9.6, 2746.1, 184.0, -16.0, "abs"],  # the Double Ninth party in its ring on landing 6's platform (14:45)
	["steps_party_close", 333.0, -14.5, 1.6, 165.0, -12.0],  # the party close: the ring on its rugs, the jars, the man pouring (14:45)
	["steps_top_confluence", 462.5, 61.4, 2891.1, 236.0, -22.0, "abs"],  # step 6: from over the South Gate's front down the steps to the confluence
	["steps_from_tsongra", 2.0, -13.0, 1.6, 87.0, 15.0],  # the steps' zigzag on the spur from Tsongra
	["steps_from_lookout", 258.0, 245.0, 2785.0, 148.0, -4.0, "abs"],  # across the gorge from over the Gorge Rim Lookout's parapet to the face's legs
	["steps_from_v01", 156.6, -172.1, 1.6, 47.0, 13.0],  # ten metres out of the Gate Chorten's west mouth (V-01), turned to the stair up the nose
	["gorge_from_lookout", 257.5, 243.5, 2783.1, 125.0, -22.0, "abs"],  # M3 sprint 2: from the Lookout's terrace by its gap down the Gorge Stair's west leg
	["gorge_v09", 328.0, 202.8, 2717.7, 108.0, 30.0, "abs"],  # V-09: on the upper bridge's deck, looking up the face at the stair's zigzag (chapter 08); V-09's own frame (data/viewpoints.json), its camera out of the flag strings (until 11 Oct 2026 at 335.1, 199.3, in one: ISS-203)
	["gorge_bridge_side", 318.0, 185.0, 2716.0, 50.0, 4.0, "abs"],  # the upper bridge from the west bank downstream
	["gorge_face", 305.0, 215.0, 2733.0, 100.0, 18.0, "abs"],  # the east leg's zigzag up the face from the west leg across the gorge
	["gorge_gate", 444.0, 160.5, 2889.8, 255.0, -40.0, "abs"],  # down the zigzag from the West Gate
	["gorge_above", 300.0, 262.0, 2830.0, 150.0, -25.0, "abs"],  # the gorge from above Tödé's rim: both legs and the bridge
	["gorge_gallery", 408.3, 172.0, 2829.5, 82.0, 4.0, "abs"],  # step 3: a gallery on its socketed beams (flight 16) from out over the gorge
	["gorge_rest", 402.4, 171.4, 2804.8, 187.0, -4.0, "abs"],  # the rest gallery RNG-09 from its switchback's landing
	["gorge_under", 442.9, 182.9, 2875.7, 178.0, 14.0, "abs"],  # up the last flights into the passage under the monks' houses across them
	["gorge_houses", 424.0, 171.0, 2884.0, 85.0, 6.0, "abs"],  # the two houses across the stair's top from over the gorge
	["gorge_wheel", 329.0, 202.7, 2718.4, 201.1, -14.0, "abs"],  # step 4: the water wheel RNG-04 down the river from the upper bridge's deck
	["gorge_naga", 346.0, 227.7, 2722.5, 116.4, -6.0, "abs"],  # the naga shrine RNG-05 under its overhang, from across the river
	["tsokchen_court", 522.0, 98.0, 2929.7, 20.0, 16.0, "abs"],  # M3 sprint 3, step 1: the Tsokchen whole from its courtyard's south-west corner
	["tsokchen_porch", 540.0, 124.0, 2931.4, 0.0, 8.0, "abs"],  # up its twenty steps to the portico, the curtains rolled up, the great door
	["tsokchen_side", 575.0, 140.0, 2940.0, 262.0, 14.0, "abs"],  # from the east: its side windows, the lantern over the nave, the rear block's gilded roof
	["tsokchen_above", 505.0, 70.0, 2962.0, 40.0, -16.0, "abs"],  # from over the south flank: the hall, its courtyard and galleries, the darchen
	["court_galleries", 535.0, 104.0, 2929.6, 200.0, 4.0, "abs"],
	["tsokchen_roof", 548.5, 145.3, 2947.5, 330.0, 16.0, "abs"],
	["chora_in", 621.5, 64.5, 2945.7, 22.0, 6.0, "abs"],  # step 2: the Chöra from its south-west corner: its white stone, the poplars, the teacher's canopy
	["chora_gate", 610.4, 75.0, 2945.6, 90.0, 3.0, "abs"],  # from the Tsenyi Dratsang's side door along the flagged walk and in at the court's west gate
	["tsenyi_side", 614.5, 71.5, 2945.6, 302.0, 5.0, "abs"],  # back from by the court's gate: the college's east wall and the side door that opens on the court
	["tsenyi_front", 600.0, 49.0, 2941.6, 0.0, 10.0, "abs"],  # the Tsenyi Dratsang from below its steps: the forecourt, the portico
	["gyupa_front", 512.0, 150.0, 2958.0, 356.0, -6.0, "abs"],  # the Gyüpa Dratsang from the air over the slope below it (a camera, not a stance): its forecourt on its fill, closed, its black banners
	["colleges_above", 585.0, 40.0, 2975.0, 40.0, -25.0, "abs"],  # the Tsenyi and the Chöra from over the south flank  # on its main roof by the lantern: the rear block, its ladder and the gilded pavilion
	["mon04_front", 580.0, 128.0, 2939.1, 10.0, 14.0, "abs"],  # step 3: the Jampa Lhakhang from the slope below: its two O4 on the Maitreya's face, the gilded roof
	["mon15_front", 576.0, 186.0, 2962.1, 309.0, 8.0, "abs"],  # the reliquary chapel: two tall red storeys, its few high windows, gilt banners
	["mon05_front", 506.0, 127.0, 2926.5, 342.0, 9.0, "abs"],  # the Gönkhang, closed: its porch, the two small windows, the black banners
	["mon05_porch", 500.0, 140.6, 2931.6, 0.0, 3.0, "abs"],  # into its porch: the black leaves under the black curtain, the painting on black ground
	["chapels_above", 540.0, 108.0, 2990.0, 20.0, -28.0, "abs"],  # the red chapels and the Gönkhang round the Tsokchen, from over the courtyard
	["labrang_front", 601.5, 191.4, 2978.5, 38.0, 6.0, "abs"],  # step 4: the Labrang turned to 218 degrees, up its 11 steps from the slope: ochre, four storeys, the gilded roof
	["labrang_bay", 635.4, 234.7, 2992.2, 218.0, 6.0, "abs"],  # its back from up the slope: the tulku's yellow bay on the top floor, looking up the gorge at 038
	["abbot_house", 572.0, 215.0, 2968.5, 8.0, 6.0, "abs"],  # the abbot's residence, plainer: three white storeys, its porch on two posts
	["estate_office", 648.0, 160.0, 2979.0, 30.0, -2.0, "abs"],  # the estate office's counting-room window and its sill, the granary range beyond
	["granary_ramp", 692.0, 170.0, 2980.1, 320.0, 6.0, "abs"],  # the granary's ramp up to its loading door at the first floor
	["jakhang_flume", 582.0, 60.0, 2938.2, 304.0, 4.0, "abs"],  # 07:00: the Jakhang's smoke pouring from its lantern, its flume on trestles into its east wall
	["dronkhang_yard", 471.0, 40.0, 2924.0, 20.0, -28.0, "abs"],  # the guest house's stable yard before it, its gate, the lean-to
	["kangyur_porch", 524.0, 181.0, 2955.0, 348.0, 4.0, "abs"],  # the Kangyur Lhakhang's stone-flagged porch, its few windows
	["novices_yard", 500.0, 25.0, 2921.0, 0.0, -18.0, "abs"],  # the novices' yard from above: its benches, trough and shelter
	["geese_pen", 606.0, 47.0, 2943.5, 25.0, -15.0, "abs"],  # the geese pen by the Tsenyi Dratsang's steps
	["kennel", 652.0, 86.0, 2948.4, 102.0, -8.0, "abs"],  # the dogs' kennel inside the wall by the East Gate's range
	["monks_pair", 519.0, -6.0, 2918.0, 2.0, -10.0, "abs"],  # 07:00: a shut M2 (H-MON-072, left) and a lived-in one (H-MON-073): the smoke, the things in its yard
	["monk_shut_door", 515.67, 14.32, 2914.6, 344.0, -8.0, "abs"],  # H-MON-072's door barred and padlocked, its owner away
	["face_top", 462.0, 140.0, 3010.0, 90.0, -88.0, "abs"],  # step 5: the west face from straight above: its houses, podia and cut walls
	["face_stack", 444.0, 110.0, 2914.0, 60.0, 6.0, "abs"],  # four houses stacked up the fall line, each roof the next one's yard, their galleries over the gorge
	["gonkor_gallery", 681.0, -43.6, 2885.4, 288.0, -2.0, "abs"],  # step 6: the Gönkor's south stretch going clockwise (west) into a wheel gallery, the wheels on the right
	["gonkor_south", 600.0, -78.0, 2880.0, 0.0, 4.0, "abs"],  # the galleries along the south wall from below
	["gonkor_dip", 561.0, -50.0, 2882.0, 350.0, -32.0, "abs"],  # the stretch between galleries e and f over the dip, from above
	["mon23_front", 703.0, 152.0, 2980.0, 125.0, -12.0, "abs"],  # the great wheel house MON-23 out on the Gönkor's east side, its door onto the way (M3 sprint 7, step 1: it stood inside the wall at 690, 140)
	["mon23_in", 717.0, 141.6, 2976.8, 110.0, -12.0, "abs"],  # inside it: the 3.5 m wheel, its bars, the bell
	# M3 sprint 7, step 1: the Gönkor whole (tools/town/gonkor.py, data/gonkor.json)
	["gonkor_face_gallery", 430.4, 115.0, 2883.9, 8.0, 3.0, "abs"],  # along the face's way north onto its timber gallery under the stacked monks' houses
	["gonkor_gallery_out", 414.0, 142.0, 2887.0, 80.0, 3.0, "abs"],  # the gallery on the gorge face from out over the gorge, the houses over it
	["gonkor_l23", 434.5, 163.0, 2884.5, 60.0, -3.0, "abs"],  # the gallery's north end and its steps up onto the Gorge Stair's landing 23, the stair's last flight on up to the West Gate
	["gonkor_steps", 413.1, 28.0, 2862.3, 8.0, 6.0, "abs"],  # from the south along the face to the gap in the 1,080 steps' landing 20, their last flights rising beyond
	["gonkor_sw", 414.6, -4.0, 2867.6, 158.0, -3.0, "abs"],  # the face's way round the spur's south-west corner towards the south stretch's west end
	["gonkor_east", 707.0, 21.0, 2934.1, 0.0, 12.0, "abs"],  # up the east side outside the wall, its flights and landings
	["gonkor_tsatsa", 707.0, 44.0, 2944.8, 80.0, 3.0, "abs"],  # the tsa-tsa house MON-24 beside the way, its window stacked with clay tsa-tsas
	["gonkor_east_above", 748.0, 130.0, 3015.0, 268.0, -22.0, "abs"],  # the east side from above: the way outside the wall, the great wheel house on it
	["gonkor_north", 712.0, 280.0, 3052.0, 262.0, -16.0, "abs"],  # behind the Labrang: down the north side's flights along the wall
	["gonkor_corner", 452.0, 292.0, 2885.0, 140.0, -14.0, "abs"],  # round the wall's west end on the gorge's rim, down to the West Gate
	["tode_above", 180.0, 230.0, 3010.0, 316.0, -20.0, "abs"],  # M3 sprint 4, step 1: Tödé from over the gorge's rim, its houses dispersed in their fields
	["tode_path", -35.0, 330.0, 2.5, 318.0, 2.0],  # on the field paths' zigzags up the 45-degree slope above the Tödé chorten, a tower-house above
	["tode_from_gonpa", 445.0, 150.0, 2937.0, 302.0, -4.0, "abs"],  # across the gorge from the monastery's west face
	["tode_west", -360.0, 380.0, 2990.0, 50.0, -10.0, "abs"],  # the west: the rammed-earth houses, the Bön households round their chapel's place
	["tode_c1", 80.3, 489.6, 5.0, 297.0, 6.0],  # the tulku's family house H-TOD-001 (TOD-04), a C1
	["tode_c2", 84.5, 373.9, 5.0, 106.0, 6.0],  # a C2 tower-house, H-TOD-005
	["tode_bon", -278.7, 516.1, 10.0, 47.5, -6.0],  # two of the Bön households' houses, H-TOD-045 and 047
	["tode_a", 23.2, 408.0, 8.0, 20.5, -4.0],  # a log-storey house, H-TOD-020
	["tode_ruin", -216.3, 497.3, 4.0, 356.0, 6.0],  # the empty tower-house TOD-26
	["tower_whole", -160.9, 394.8, 2886.2, 331.5, 18.0, "abs"],  # the Tödé tower from 40 m down the fall line before its door (M3 sprint 4, step 3)
	["tower_log", -177.1, 421.3, 2886.8, 331.5, 30.0, "abs"],  # up its notched log to the door 6 m up (M3 sprint 4, step 3)
	["tower_inside", -180.1, 428.3, 2892.7, 61.5, 32.0, "abs"],  # inside its first floor, the log up through the hatch (M3 sprint 4, step 3)
	["tower_top", -180.3, 430.5, 2918.8, 111.2, 0.0, "abs"],  # on its top, the monastery at eye level across the gorge (M3 sprint 4, step 3)
	["tower_and_gonpa", -240.0, 445.0, 1.7, 104.0, 8.0],  # the tower before Dungkar Gönpa across the gorge, from the west (M3 sprint 4, step 3)
	["tower_from_terrace", -21.5, 355.0, 2874.2, 296.0, 3.0, "abs"],  # the tower over Tödé from the Tödé Stair's terrace (M3 sprint 4, step 3)
	["leat_contour", 193.0, 561.7, 2979.3, 306.8, -6.0, "abs"],  # along the contour stretch and its walk, westward (M3 sprint 4, step 4)
	["leat_mill_upper", 96.8, 586.5, 2964.8, 297.1, 5.0, "abs"],  # the upper mill, its chute from the leat behind it (M3 sprint 4, step 4)
	["leat_mill_lower", 24.9, 394.2, 2896.6, 319.5, 5.0, "abs"],  # the lower mill and its tail race (M3 sprint 4, step 4)
	["leat_wheel", 72.7, 533.9, 2938.4, 336.2, 6.0, "abs"],  # the first water prayer wheel house over its channel (M3 sprint 4, step 4)
	["leat_wheel_last", 1.1, 313.4, 2867.8, 350.1, 6.0, "abs"],  # the last wheel house at the band's top, the race on towards Shöl (M3 sprint 4, step 4)
	["leat_steps", 42.0, 448.1, 2918.5, 177.0, -22.0, "abs"],  # down its stepped channel through the terraces (M3 sprint 4, step 4)
	["leat_culvert", 41.2, 434.8, 1.6, 9.3, 6.0],  # where it passes under a field path in a culvert (M3 sprint 4, step 4)
	["tode_floor", -71.2, 304.8, 2830.5, 340.0, -16.0, "abs"],  # the threshing floor TOD-12, 14 m, its kerb, straw and flails (M3 sprint 4, step 5)
	["tode_floor_high", -124.4, 547.8, 2942.8, 20.0, -15.0, "abs"],  # the highest threshing floor TOD-14 under the leat's line (M3 sprint 4, step 5)
	["tode_byre", -276.6, 513.8, 2945.2, 62.2, -30.0, "abs"],  # a byre with its hay in a rammed-earth yard (H-TOD-045) (M3 sprint 4, step 5)
	["tode_rack", 71.2, 489.9, 2925.4, 317.0, 4.0, "abs"],  # a maize rack at a house's yard (H-TOD-001) (M3 sprint 4, step 5)
	["tode_walnuts", -81.0, 437.1, 2896.8, 330.0, -4.0, "abs"],  # the walnut grove TOD-20, late October (M3 sprint 4, step 5)
	["tode_stall", -15.8, 263.1, 2786.2, 39.8, 2.0, "abs"],  # the window stall TOD-25 from the forecourt at the Sky Stair's head (M3 sprint 4, step 5)
	["tode_mani", -348.2, 399.3, 2847.7, 5.9, 14.0, "abs"],  # the mani wall TOD-23 up through Tödé's west edge (M3 sprint 4, step 5)
	["tsokchen_curtain", 540.0, 140.0, 2933.7, 180.0, 2.0, "abs"],  # back down the aisle to the great door, its curtain hanging (M3 sprint 6, step 1)
	["tsokchen_curtain_parted", 540.0, 140.0, 2933.7, 180.0, 2.0, "abs"],  # the same, the curtain half parted: the courtyard's glare in
	["tsokchen_curtain_w_parted", 538.8, 137.3, 2933.6, 153.0, -11.0, "abs"],  # from inside by the aisle's west side, the curtain parted at its east
	["tsokchen_porch_parted", 540.0, 127.0, 2932.6, 0.0, 6.0, "abs"],  # from the porch, the curtain pushed in by someone entering
	["assembly_boots", 547.5, 131.0, 2933.6, 288.0, -24.0, "abs"],  # the boot row on the porch at the dawn assembly (M3 sprint 6, step 2)
	["v26_door", 540.0, 135.3, 2933.6, 0.0, 2.0, "abs"],  # V-26: the full-moon assembly from the lay visitors' place inside the door (5 Nov, 10:15)
	["v26_rows", 551.2, 141.0, 2933.8, 300.0, -6.0, "abs"],  # across the rows from the east aisle: the kettles, the disciplinarian
	["v26_shafts", 540.0, 138.0, 2933.2, 0.0, 22.0, "abs"],  # up the aisle into the incense: the lantern's shafts
	["tsokchen_shut", 540.0, 127.0, 2932.6, 0.0, 6.0, "abs"],  # 20:00: the great door shut, from the porch
	["tsokchen_sweepers", 540.0, 135.4, 2933.7, 0.0, 4.0, "abs"],  # 08:00: the sweepers along the aisles, the sacristan at the lamp banks
	["tsokchen_pilgrim", 540.0, 140.0, 2933.7, 180.0, 0.0, "abs"],  # 12:00: a lay visitor prostrating inside the door
	["labrang_audience", 621.0, 211.9, 2993.1, 150.0, -5.0, "abs"],  # the Labrang's reception at 10:30: the tulku on his throne, his tutor, a petitioner before them (M3 sprint 6, step 3)
	["gonkhang_vest_parted", 500.0, 145.9, 2931.6, 0.0, 2.0, "abs"],  # the Gönkhang's black vestibule, its second curtain parted on the room
	["tsokchen_nave_in", 540.0, 135.4, 2933.7, 0.0, 4.0, "abs"],  # the Tsokchen's nave from inside its great door: the pillars in their rugs, the rows, the aisle to the thrones (M3 sprint 5, step 2)
	["tsokchen_aisle", 540.0, 148.0, 2933.7, 0.0, 2.0, "abs"],  # up the aisle to the three thrones and the inner chapel's door between the great banners
	["tsokchen_gallery_in", 531.0, 138.0, 2940.9, 54.0, -24.0, "abs"],  # from the gallery over the rows and into the well
	["tsokchen_chapel_in", 540.0, 157.7, 2933.6, 0.0, 9.0, "abs"],  # the inner chapel: Tsongkhapa and his two disciples over the lamps
	["tsokchen_nangkor", 528.45, 157.0, 2933.6, 0.0, 0.0, "abs"],  # the Nangkor's west arm, behind the inner chapel
	["tsokchen_well_up", 542.5, 142.5, 2933.6, 0.0, 70.0, "abs"],
	["s7_noon", 540.0, 136.2, 2933.7, 0.0, 8.0, "abs"],  # spike S7: the nave from the aisle inside the door at noon, the well's light and the shaft on the aisle (M3 sprint 5, step 3)
	["s7_dawn", 540.0, 136.2, 2933.7, 0.0, 6.0, "abs"],  # and at the dawn assembly's 05:30: the lamps alone
	["assembly_dawn", 540.0, 136.2, 2933.7, 0.0, 4.0, "abs"],  # the dawn assembly from the door: the rows full, the lamps (M3 sprint 5, step 5)
	["assembly_rows", 536.0, 146.0, 2934.2, 120.0, -12.0, "abs"],  # among the rows, looking across the aisle at the monks facing it
	["assembly_thrones", 540.0, 147.5, 2933.7, 0.0, 6.0, "abs"],  # up the aisle to the thrones, the abbot's and the chant leader's facing across it
	["assembly_tea", 540.0, 136.2, 2933.7, 0.0, 4.0, "abs"],  # the general tea at 11:00, fewer
	["tsokchen_shaft", 541.5, 141.0, 2933.7, 350.0, 16.0, "abs"],
	["jampa_door", 585.0, 154.6, 2946.65, 0.0, 14.0, "abs"],  # the Jampa Lhakhang inside its door: the lamps' altar, the feet on the footstool, the knees (M3 sprint 5, step 6)
	["jampa_up", 587.6, 157.6, 2946.65, 335.0, 52.0, "abs"],  # up from beside the footstool past the knees and the hands to the face far above
	["v30_face", 585.0, 159.1, 2951.1, 0.0, 2.0, "abs"],  # V-30: the face from the south gallery's rail, eye to eye, the noon patch on it
	["jampa_gallery_w", 579.6, 162.0, 2951.1, 90.0, -4.0, "abs"],  # from the west gallery: the lap, the hands and the lotus stems
	["jampa_ladder", 582.6, 155.0, 2946.65, 300.0, 22.0, "abs"],  # the stair-ladder in the dark south-west corner, the hatch over it
	["gonkhang_vest", 500.0, 145.9, 2931.6, 0.0, 2.0, "abs"],  # the Gönkhang's black vestibule and its second curtain (step 7)
	["gonkhang_room", 500.0, 148.6, 2931.6, 0.0, 6.0, "abs"],  # past the curtain: the pillars, the yak from the beam, the veiled protectors and their two lamps
	["gonkhang_yak", 503.2, 148.4, 2931.6, 312.0, 26.0, "abs"],  # the stuffed wild yak slung from the beam, its horns catching the lamp
	["gonkhang_conch", 497.2, 151.0, 2931.6, 318.0, -6.0, "abs"],  # the conch's cabinet, the lamp before it
	["kangyur_in", 520.0, 196.4, 2954.15, 0.0, 3.0, "abs"],  # the library: the Kangyur's wall and the Shakyamuni between its two grids (step 8)
	["kangyur_east", 517.4, 199.0, 2954.15, 82.0, 0.0, "abs"],  # its east wall, the Tengyur, the reading table and its chest
	["jakhang_in", 556.5, 70.6, 2929.85, 15.0, 8.0, "abs"],  # the Jakhang: the stove and its three cauldrons, the great one covered, the lantern's day (step 8)
	["jakhang_beakers", 562.0, 72.5, 2929.85, 80.0, 6.0, "abs"],  # the hundred copper beakers on the east wall
	["monk_store_in", 445.51, 29.02, 2893.2, 171.3, 20.0, "abs"],  # H-MON-012's store: the notched log up to the trapdoor (step 9)
	["monk_cell_in", 446.02, 28.28, 2895.6, 253.4, -14.0, "abs"],  # its cell: the stove, the churn, the window over the gorge
	["labrang_reception", 621.43, 212.61, 2993.1, 159.9, -4.0, "abs"],  # the Labrang's reception from its door: the throne at its east end, the carpets, the windows (step 9)
	["labrang_throne", 619.53, 209.53, 2993.0, 106.5, -6.0, "abs"],  # the throne, its tiger skin and its table, the tutor's seat  # the noon shaft from the lantern's south windows down the well onto the aisle, its dust (M3 sprint 5, step 4)  # up the well past the tall pillars to the lantern's lattice
	["parkhang_back", 268.36, -41.42, 2685.30, 189.1, 2.0, "abs"],  # the Parkhang's back from the 1,080 steps' first landing: its back door into the stair hall under the printing room's windows (M3 sprint 5, step 8)
	["parkhang_gate_in", 271.92, -67.26, 2685.70, 340.0, 4.0, "abs"],  # out of its gate's passage into the court: the arcade on its twelve pillars, the new flags drying between them, the stair hall's door
	["parkhang_arcade", 275.21, -62.87, 2685.70, 301.5, 6.0, "abs"],  # the arcade from the court's south-east: its flags, its ink stains, the stair hall's door
	["parkhang_stair", 267.49, -53.34, 2685.65, 184.2, 30.0, "abs"],  # the stair hall from its back door: the stair-ladder up to the hatch, the court's light through the arcade door
	["parkhang_printing_in", 255.71, -59.86, 2689.70, 56.0, -9.0, "abs"],  # the printing room from its west end: the six pairs' boards under the north windows, the damp sheets, the cutting table
	["parkhang_press", 268.10, -55.14, 2689.45, 8.8, -27.0, "abs"],  # a pair's place close: the bench, the board, the block inked in cinnabar, the roller, the stacks
	["parkhang_chapel_in", 278.90, -55.89, 2689.70, 160.0, -6.0, "abs"],  # the chapel from its door: Manjushri and the two lesser images on the altar, the bowls, its one lamp, the thangkas
	["parkhang_canyon", 278.53, -51.23, 2693.10, 250.0, -2.0, "abs"],  # the block canyon from the hatch: the middle aisle down its 22 m of racks to the one window at the far end
	["parkhang_canyon_far", 255.46, -59.63, 2693.10, 67.1, -3.0, "abs"],  # the canyon from the window's end, back down the middle aisle
	["parkhang_blocks_close", 259.46, -57.91, 2692.95, 133.4, -12.0, "abs"],  # the blocks close in the far window's light: on edge in their bays, their handles to the aisle, a set to a shelf
	["tode_bon_niche", -257.7, 515.5, 2939.4, 321.6, -8.3, "abs"],  # the wheel niche by H-TOD-045's gate, its swastika over the three wheels that turn the other way (M3 sprint 4, step 6)
	["tode_chapel", -258.6, 549.5, 2952.8, 39.2, -1.7, "abs"],  # the Bön chapel TOD-02 on its terrace, its circuit R-24 paved round it (M3 sprint 4, step 6)
	["tode_bon_circuit", -258.9, 553.9, 2952.1, 72.6, -6.6, "abs"],  # the Bön circuit at dawn: Yungdrung Gyaltsen and his neighbour round the chapel anticlockwise past its wheels (M3 sprint 4, step 6)
	["tode_threshing", 97.5, 415.6, 2879.3, 177.5, -15.4, "abs"],  # six threshing in a line at TOD-13 with their flails, Chödrön among them (M3 sprint 4, step 6)
	["tode_threshing_b", -196.8, 323.0, 2850.5, 284.8, -7.3, "abs"],  # the line at TOD-11, neighbours striking alternately (M3 sprint 4, step 6)
	["tode_winnowing", 97.5, 415.6, 2879.3, 177.5, -15.4, "abs"],  # TOD-13 at 14:30: the men threshing, the women winnowing (M3 sprint 4, step 6)
	["tode_gyaltsen_roof", -254.9, 537.5, 2946.7, 217.8, -21.4, "abs"],  # Yungdrung Gyaltsen threshing on his own roof with a woman of his house (H-TOD-045) (M3 sprint 4, step 6)
	["tode_roof", -167.1, 414.7, 2883.3, 158.0, -21.4, "abs"],  # two women threshing face to face on a rammed-earth roof (H-TOD-053) (M3 sprint 4, step 6)
	["tode_miller", 86.3, 580.6, 2965.5, 24.9, -0.8, "abs"],  # the miller in the upper mill TOD-05's doorway (M3 sprint 4, step 6)
	["tode_carrier", 1.9, 326.3, 2876.9, 15.0, -13.7, "abs"],  # a water carrier filling her barrel at the leat where her way crosses it, in the afternoon (H-TOD-003) (M3 sprint 4, step 6)
	["tode_stair_people", -45.9, 319.5, 2846.2, 20.4, 0.0, "abs"],  # a porter going down the Tödé Stair to Shöl (H-TOD-041) (M3 sprint 4, step 6)
	["tode_stair_foot", -19.0, 255.0, 2784.4, 330.0, 22.0, "abs"],  # M3 sprint 4, step 2: the Tödé Stair from the Sky Stair's head, the chorten beside its first flight
	["tode_stair_side", -20.0, 150.0, 2900.0, 355.0, -27.0, "abs"],  # its zigzag up the band over the chorten, from the east
	["tode_stair_top", -30.0, 352.0, 2871.0, 160.0, -28.0, "abs"],
	["tode_terrace", -22.0, 361.0, 2874.2, 174.0, -14.0, "abs"],  # from the terrace's far end back along it to the stair's top and Shöl below (step 2)  # from its top down the band to the forecourt and Shöl's roofs
	["tsokchen_v05", 549.5, 161.4, 2955.1, 240.0, -10.0, "abs"],  # V-05 from the rear block's roof (MON-40, 2,952 m): over the town at 240 degrees  # the courtyard's south range from the darchen, its colonnade and gallery, the passage
	["monk_way_up", 447.0, -46.0, 2876.2, 345.0, 16.0, "abs"],  # ISS-214 (M3 sprint 6, step 6): from the Gönkor's west end up the face, H-MON-012's way zigzagging up to its door
	["monk_door_step", 440.4, 26.3, 2893.8, 28.0, -8.0, "abs"],  # along the step before H-MON-012's door from its end, the house's front on the right
	["parkhang_walk", 262.1, -45.6, 2685.4, 146.0, -4.0, "abs"],  # ISS-215: from the 1,080 steps' landing 1 through the gap in its wall along the flagged walk to the Parkhang's back door
	["parkhang_forecourt", 275.3, -76.6, 2685.4, 340.0, 6.0, "abs"],  # the forecourt cut before the Parkhang's south gate
	["v05a_horns", 532.7, 165.6, 2955.2, 225.0, -10.0, "abs"],  # V-05a (M3 sprint 6, step 5): behind the two horn players at 05:31, the dung chen blown over the parapet, the town dark below
	["v05a_players", 532.4, 157.6, 2955.0, 330.0, -4.0, "abs"],  # the players side on at 05:31: their yellow hats, both hands on the horns, the bells over the parapet
	["v05a_novice", 550.5, 161.0, 2955.3, 252.0, -8.0, "abs"],  # 05:27: the novice by the ladder-stair's head, the players beyond waiting with their horns
	["v05a_sun", 550.5, 160.0, 2955.2, 282.0, 20.0, "abs"],  # V-05a (M3 sprint 3, step 7): on the rear block's roof at 07:24, the gilded roof over the inner chapel in its first sun (07:22 on the terrain: chapter 02, 2.8)
	["v05a_town", 528.0, 159.0, 2955.3, 250.0, -22.0, "abs"],  # V-05a: from the rear block's south-west corner at 07:24, over the town still in the ridges' shadow (Tsongra's first sun 07:39)
	["v05b_dusk", 547.0, 159.8, 2955.2, 39.0, 12.0, "abs"],  # V-05b: turned to 039 at 17:15, the Labrang's roof 27 degrees up to the right (Dungri Karpo hidden by the spur: ISS-153)
	["gonpa_gate_in", 461.0, 59.5, 2884.2, 35.0, 8.0, "abs"],  # from the 1,080 steps' forecourt through the South Gate's passage
	["gonpa_way_up", 468.0, 69.5, 2884.2, 20.0, 20.0, "abs"],  # inside the gate, up the way's first flights between their walls
	["gonpa_way_down", 517.0, 86.0, 2929.6, 240.0, -24.0, "abs"],  # from the bench's edge down the way to the South Gate and the 1,080 steps
	["gorge_novices", 401.35, 167.13, 2804.8, 30.0, 14.0, "abs"],  # step 6 (with --people): the two novices racing down past the rest gallery (V-17's people)
	["gorge_novices_rail", 318.0, 185.0, 2716.0, 50.0, 4.0, "abs"],  # the two at the raw bridge's downstream rail over the water
	["gorge_bench", 401.73, 168.6, 2804.6, 187.1, -10.0, "abs"],  # the old monk on the rest gallery's bench turning its wheel
	["gorge_water_fill", 321.6, 198.5, 2713.9, 163.7, -18.0, "abs"],  # a Tödé woman filling her barrel at the wheel's channel's head
	["gorge_tulku_bridge", 318.0, 185.0, 2716.0, 50.0, 4.0, "abs"],  # 5 November: the tulku and his attendants over the raw bridge
	["gorge_tulku_meet", 259.8, 247.0, 2783.1, 210.0, -10.0, "abs"],  # his mother greeting him on the Lookout's terrace
	["gorge_tulku_sit", 259.55, 246.57, 2783.0, 226.0, -14.0, "abs"],  # mother and son sitting together looking out, from the terrace's front
	["gorge_tulku_down", 277.8, 250.8, 2768.7, 237.0, 22.0, "abs"],  # up the west leg at the three going back down from the terrace
	["serchu_road_mid", 851.3, -412.5, 2765.9, 284.0, -3.0, "abs"],  # half way down, its cut and its walls along the bank
	["serchu_road_back", 653.4, -327.8, 2741.0, 98.0, 2.0, "abs"],  # looking back up it towards the Zampa
	["serchu_road_across", 846.0, -352.0, 2745.1, 195.0, 9.0, "abs"],  # from the north bank across the river: the road along the slope
	["serchu_road_above", 820.0, -505.0, 2858.0, 325.0, -21.0, "abs"],  # from high on the slope above: the road along the bank, the river
	["serchu_road_ser20", 451.5, -252.7, 2716.1, 277.0, -2.0, "abs"],  # coming to SER-20 and the cliff gallery's east end
	# sprint 7, step 3: who is inside this afternoon (--people; STATION_HOUR)
	["dechen_tibetan_people", -85.9, -35.7, 2652.75, 295.0, -14.0, "abs"],  # Dolkar with the Litang agent, Ngodrup at the head
	["dechen_chinese_people", -64.3, -34.3, 2652.75, 80.0, -10.0, "abs"],  # Dolkar with Yang Shouren and the Han clerk
	["dechen_desk_people", -60.9, -35.6, 2652.7, 335.0, -12.0, "abs"],  # Yang at his ledger, the clerk on the bench
	["dechen_kitchen_people", -81.0, -22.1, 2652.75, 300.0, -12.0, "abs"],  # the cook at the stove, a woman at the kettles
	# sprint 7, step 6: the roof's sang at 17:12, the household at the burner, the town's threads beyond (--people)
	["dechen_roof_sang", -75.6, -21.4, 2661.75, 285.0, 2.0, "abs"],
	# sprint 7, step 7: the codex's page open over Tsongra, eight of the slice's thirteen found (_next_shot)
	["codex_page", 3.0, 2.0, 1.7, 30.0, 0.0],
	["ledger_page", 3.0, 2.0, 1.7, 30.0, 0.0],  # M2 sprint 1, step 4: the player's ledger open on day 1, the letter given
	# the caravan CV-02 (world/caravan.gd, with --people; STATION_HOUR)
	["caravan_ramp", -29.0, -84.0, 2657.0, 235.0, -30.0, "abs"],  # 15:12, over the ramp's east end: the file climbing the legs
	["caravan_gate", -53.5, -70.5, 2652.4, 186.0, -4.0, "abs"],  # 15:25, the yak coming through the Yak Gate with their loads (ISS-107: at 15:22 the gate was still empty)
	["caravan_passage", -69.5, -56.0, 2651.7, 92.0, -3.0, "abs"],  # 15:36, in Yard 1: a yak into the passage, one at a time
	["dechen_passage_up", -75.0, -48.5, 2651.6, 0.0, 3.0, "abs"],  # Yard 1: the way up to the guest yard through the north range (ISS-177)
	["dechen_passage_yak", -69.5, -54.7, 2651.6, 90.0, 0.0, "abs"],  # Yard 1: the animal passage under the east range to Yard 0 (ISS-177)
	["caravan_yard0", -54.2, -61.5, 2652.6, 32.0, -12.0, "abs"],  # 16:05, Yard 0: the loads coming off onto the platform
	["caravan_home", -55.0, -114.0, 2627.0, 358.0, 18.0, "abs"],  # 16:58, from the deck: the yak going down the ramp home
	["tsongra_1600", 2.0, -13.0, 1.6, 356.0, 3.0],
	# M2 sprint 10, step 2: the day's drawn at the market at 11:00 (STATION_HOUR)
	["market_tsongra", 2.0, -13.0, 1.6, 356.0, 3.0],  # Tsongra from its lower level at 11:00, the hamlets come in to market
	["market_stalls", -3.0, -12.0, 1.6, 288.0, -2.0],  # along the lower level to the fuel stalls
	["market_wide", -30.0, 30.0, 14.0, 140.0, -22.0],  # down onto the square from the slope above it
	["hejie_market", -457.0, -95.0, 2561.8, 80.0, 4.0, "abs"],  # step 3: up River Street from the Water Gate on Hejie's market day, 11:00
	["hejie_market_up", -324.0, -88.6, 2578.5, 104.0, 5.0, "abs"],  # and at the teahouse's bend
	["crowd_dawn", -92.0, 104.0, 2712.0, 108.0, -14.0, "abs"],  # M2 sprint 10: the old with their lamps round the barkor before dawn, 04:50
	["crowd_kora", -92.0, 104.0, 2712.0, 108.0, -14.0, "abs"],  # the kora at its busiest, 17:42
	["crowd_evening", 2.0, -13.0, 1.6, 356.0, 3.0],  # Tsongra after supper, 19:15
	["crowd_morning", 3.0, 2.5, 1.6, 62.0, -3.0],  # Tsongra at 06:20, the women for water at the basin
	["market_west", -8.0, 3.5, 1.6, 296.0, -5.0],  # the upper market's west stalls, the butter and the cheese
	["market_east", 7.0, 5.0, 1.6, 78.0, -4.0],  # its east row, salt, tea, cloth, beads and boots
	["tsongra_1610", 2.0, -13.0, 1.6, 356.0, 3.0],
]
## The guide's stations (world/guide.gd; sprint 8, step 8): [her climb's number, metres past its start] where a still
## holds her.
const GUIDE_AT := {"guide_ladder": [0, 2.6]}
## Named starts for play (--at=, tools/play.sh's AT): [town x, y, bearing, pitch] (sprint 6, step 6: Greg's walk).
const START_AT := {"yak_gate": [-55.0, -80.0, 180.0, -18.0], "tsongra": [3.0, 2.0, 30.0, 0.0],
		"dechen": [-75.0, -67.5, 0.0, -2.0],  # on Netsang Lam before Dechen-tsang's gate (sprint 7)
		"house": [-42.2, 26.7, 280.6, 4.0],  # at the foot of H-SHL-007's outside stair, its kitchen's door at the top (sprint 8, step 7)
		"bridge": [3.67, 172.2, 7.5, 24.0],  # in H-SHL-080's yard before the ladder up its wall to the bridge over the Sky Stair (IMP-023 (3); bridges.json)
		"poor": [-276.0, 45.7, 357.0, 0.0],  # before H-SHL-142's door on the west edge, the poor family's one room (ISS-105; chapter 04, 4.2)
		"chang": [68.5, 20.5, 5.0, 4.0],  # on the lane before the chang house SHL-24, its stair up to the drinking room (M2 sprint 2)
		"serchu": [438.0, -253.0, 300.0, 0.0],  # by the road chorten SER-20 at the cliff gallery's east end (M2 sprint 3: the arrival)
		"samkha": [-130.0, -148.0, 0.0, 6.0],  # in the south pavilion SAM-04, the chain bridge ahead to Samkha Khar's gate (M2 sprint 4)
		"castle": [-123.0, -71.5, 205.0, 14.0],  # in Samkha Khar's ward by the steps from the gate passage (M2 sprint 4)
		"pema": [186.9, -81.0, 320.0, 10.0],  # on the Conch terrace at the foot of Pema Ö's stair, the temple above (M2 sprint 5)
		"spring": [-84.0, 231.0, 275.0, 8.0],  # at the foot of the path up to the Lukhang spring, the yard ahead (M2 sprint 6, step 3)
		"lookout": [14.0, 215.5, 87.0, 4.0],  # at the garden lane's foot by H-SHL-095's yard, the lane ahead (M2 sprint 6, step 4)
		"headman": [-88.0, 22.7, 270.0, 4.0],  # outside the headman's yard gate, its yard and house ahead (M2 sprint 7)
		"ramp": [-122.0, -151.0, 188.0, -10.0],  # at the Caravan Ramp's head past the south pavilion's front, its first leg ahead (M2 sprint 9)
		"camp": [-277.0, -176.5, 235.0, -3.0],  # at the ramp's foot by the fodder yard, the Caravan Ground ahead (M2 sprint 9)
		"hejie": [-456.0, -95.0, 80.0, 3.0],  # inside Hejie's Water Gate, River Street climbing ahead (M2 sprint 9, step 4)
		"castle_ramp": [-210.0, -81.0, 120.0, 8.0],  # outside Hejie's East Gate at the Castle Ramp's foot, its last leg ahead (M2 sprint 11)
		"zampa": [1300.0, -521.0, 285.0, -3.0],  # on R-01 on the Serchu's north bank, the Zampa's gateway chorten ahead (M2 sprint 12)
		"mills": [505.9, -261.5, 45.4, -12.0],  # on R-01 at the head of the path down to the mills' footbridge, the mills across the river (step 5)
		"gonpa": [535.0, 95.0, 0.0, 6.0],  # in Dungkar Gönpa's courtyard MON-02 before the Tsokchen (M2 sprint 13)
		"steps": [234.0, -66.0, 56.4, 12.0],  # at the foot of the 1,080 steps, the Conch Bridge behind (M3 sprint 1)
		"gorge": [256.0, 241.0, 124.0, -14.0],  # on the Gorge Rim Lookout's terrace by its gap, the Gorge Stair below (M3 sprint 2)
		"chora": [610.6, 75.0, 90.0, 2.0],  # on the flagged walk from the Tsenyi Dratsang's side door, the Chöra's gate ahead (M3 sprint 3, step 2)
		"tode": [-22.0, 257.0, 340.0, 10.0],  # on the forecourt by the Tödé chorten at the Sky Stair's head, the Tödé Stair ahead (M3 sprint 4)
		"leat": [259.8, 559.2, 184.2, 2.0],  # on the leat walk where Tödé's leat comes into the quarter on the contour, westward (M3 sprint 4, step 4)
		"tower": [-174.8, 420.3, 331.5, 12.0],  # before the Tödé tower's door on its pad, the notched log ahead (M3 sprint 4, step 3)
		"chapel": [-255.8, 558.0, 112.0, 5.0],  # on the Bön chapel's circuit at its front's west end, facing along it anticlockwise, the door and wheels on the left (M3 sprint 4, step 6)
		"tsokchen": [540.0, 135.8, 0.0, 3.0, 2932.05],  # inside the Tsokchen's great door on its floor (a fifth value: the feet's height above sea level, under a roof), the aisle ahead between the rows (M3 sprint 5, step 1)
		"jampa": [585.0, 155.2, 0.0, 14.0, 2945.05],  # inside the Jampa Lhakhang's door, the altar and the feet ahead, the knees far above (M3 sprint 5, step 6)
		"gonkhang": [500.0, 145.5, 0.0, 2.0, 2930.05],  # in the Gönkhang's black vestibule, its second curtain ahead (step 7)
		"library": [520.0, 196.6, 0.0, 3.0, 2952.55],  # inside the library's door, the canon's wall and the image ahead (step 8)
		"kitchen": [556.5, 70.7, 15.0, 6.0, 2928.25],  # inside the Jakhang's door, the stove and its cauldrons ahead (step 8)
		"monk": [445.51, 29.02, 125.0, 12.0, 2891.65],  # in H-MON-012's store, the notched log up through the trapdoor to the cell ahead (step 9; turned to it since the log moved, step 10; its door reached by its way since M3 sprint 6, step 6: AT=monk_way)
		"monk_way": [445.0, -41.6, 300.0, 8.0],  # at the Gönkor's west end, H-MON-012's way up the face ahead (M3 sprint 6, step 6; ISS-214)
		"labrang": [616.31, 210.27, 38.0, 10.0, 2982.55],  # inside the Labrang's door, its entrance hall to the stair ahead (step 9)
		"parkhang": [266.24, -51.66, 160.0, 4.0]}  # on the Parkhang's apron before its back door into the stair hall (step 8; since M3 sprint 6, step 6 reached from the 1,080 steps' landing 1 by a flagged walk)
## The named eight's stills (sprint 6, step 3): [who, hour, metres before them, eye height, degrees round to their left].
const NAMED_SHOTS := {
	"named_talkers": ["sonam_wangyal", 16.7, 3.2, 1.2, 15.0],  # Sönam on the talkers' steps, where the old men trade news
	"named_pitch": ["pasang_carver", 14.92, 3.0, 1.7, -55.0],  # Pasang carving, Nyima crouched by his stone to paint it
	"named_stalls": ["kalsang_drolma", 9.25, 4.0, 1.6, 20.0],  # Kalsang at her family's stall, Nyima at the next, Tsomo by them
	"named_gate": ["achak_dolkar", 16.7, 3.0, 1.6, 10.0],  # the host of Dechen-tsang in her gateway, waiting for the caravan
	"named_door": ["kalsang_drolma", 14.0, 3.0, 1.6, 10.0],  # Kalsang spinning at her doorway
	"named_spring": ["kalsang_drolma", 15.6, 3.5, 1.6, 15.0],  # Kalsang in the queue at the Lukhang spring
	"generic_knucklebones": ["boy", 12.0, 3.2, 1.4, 25.0],  # Nyima's band at knucklebones on the talkers' steps
	"novices_stair": ["novice_b", 13.92, 3.6, 1.5, 15.0],  # the elder novice coming down the Sky Stair (IMP-024)
	"novices_wheel": ["novice", 14.35, 2.8, 1.4, 35.0],  # the younger round the great wheel
	"novices_knucklebones": ["novice", 15.3, 3.0, 1.3, 40.0],  # both with the boy at knucklebones on Tsongra
	"generic_elders": ["elder_man", 16.7, 3.4, 1.2, -25.0],  # an old man beside Sönam on the steps
	"generic_stalls": ["stall_woman", 10.0, 4.5, 1.6, 30.0],  # Nyima's mother at her stall, the east stall's keeper by her
	"generic_porter": ["porter", 8.75, 3.2, 1.6, 35.0],  # a porter delivering tea at the west stall
	"generic_barkor": ["elder_woman", 15.3, 3.5, 1.7, 40.0],  # an old woman round the mani wall with her hand wheel
	"generic_clerk": ["han_man", 12.17, 3.2, 1.6, 30.0],  # a Han clerk from Hejie at the east stall
}
## Stations with an hour of the default day (sprint 4, step 6): V-28's dusk, from the top of the Rooftop Way over
## Shöl's roofs (chapter 08: 150-175 degrees): the threads of the sang rising at 17:07, the half moon over them at
## 17:40 (44.5 degrees up at 172, computed; looked at pitched up to hold both). The day's light runs for these.
## a station on another day than the default (the game day from 21 October 1903): the great court's on 9 November, the
## 20th of the Tibetan month (M2 sprint 11, step 5)
const STATION_DAY := {"v26_door": 15, "v26_rows": 15, "v26_shafts": 15, "samkha_great_ward": 19, "samkha_great_court": 19, "samkha_great_headmen": 19, "gorge_tulku_bridge": 15, "gorge_tulku_meet": 15, "gorge_tulku_sit": 15, "gorge_tulku_down": 15}
const STATION_HOUR := {"headman_yard_morning": 9.0, "headman_stable_groom": 15.0, "headman_kitchen_polish": 15.0, "headman_reception_trader": 15.5, "headman_shrine_reader": 13.6, "headman_roofroom_pema": 15.5, "headman_roof_juniper": 17.3, "headman_supper": 18.5, "headman_dog_yard": 15.0,
		"lamps_lhakhang": 17.85, "lamps_yard": 18.67, "lamps_v28": 17.5, "lamps_tunnel": 19.0, "lamps_sang": 17.6, "mist_v28": 6.75, "mist_v14": 7.17, "rays_v28": 16.08, "haze_v28": 18.0, "guide_wait": 16.75, "guide_ladder": 16.8, "house_007_in": 15.0, "house_007_door": 15.0, "house_007_shut": 15.0, "house_054_in": 15.0, "house_054_door": 15.0, "house_054_shut": 15.0, "house_004_in": 15.0, "house_004_door": 15.0, "house_004_shut": 15.0, "house_007_back": 15.0, "house_007_back_shut": 15.0, "house_007_dusk": 18.0, "hearths_close": 7.67, "hearths_noon": 12.25, "hearths_dusk": 17.42, "v28_dusk": 17.12, "v28_moon": 17.67, "v28_night": 19.0, "v28_late": 21.0, "west_edge": 15.0, "west_edge_above": 15.0, "house_142": 15.0, "house_142_door": 15.0, "house_142_in": 15.0, "house_142_back": 15.0, "house_142_back_shut": 15.0, "house_142_back_w": 15.0, "house_142_up": 12.0, "house_142_dusk": 18.0, "chang_out": 16.5, "chang_in": 16.75, "chang_back": 17.25, "chang_dusk": 19.67, "chang_window": 19.67, "arrival_v19": 14.75, "arrival_gallery_side": 14.75, "arrival_cutting": 14.8, "arrival_v01": 14.87, "arrival_v01_turn": 14.87, "arrival_row": 14.9, "arrival_ramp": 15.0, "arrival_from_town": 15.0, "arrival_chorten_east": 14.85, "arrival_mandala": 14.86, "arrival_ser20": 14.7, "arrival_eight": 14.9, "arrival_eight_side": 14.9, "arrival_caravan_gallery": 13.2, "arrival_caravan_row": 13.7, "arrival_caravan_ramp": 14.5, "samkha_v10_up": 15.3, "samkha_v10_down": 15.3, "samkha_bridge_side": 15.3, "samkha_bridge_north": 15.3, "samkha_lower_bridge": 15.3, "samkha_caravan_lower": 14.96, "samkha_castle_v10": 15.3, "samkha_castle_south": 15.3, "samkha_mouth": 15.3, "samkha_passage": 15.3, "samkha_ward": 15.3, "samkha_roof": 15.3, "samkha_east": 15.3, "samkha_pavilion": 15.3, "samkha_pavilion_road": 15.3, "samkha_gate_shut": 17.75, "samkha_sherab": 10.0, "samkha_gatekeeper": 12.0, "samkha_ponpo": 17.4, "samkha_dogs": 15.27, "samkha_deck_people": 15.27, "samkha_gate_dusk": 17.33, "samkha_mules": 15.28, "samkha_mules_close": 15.27, "samkha_court": 9.5, "samkha_court_dais": 9.5, "samkha_stair_hall": 9.5, "samkha_court_scribe": 9.5, "rivers_yalong": 14.5, "rivers_fan": 14.5, "rivers_golden": 14.5, "confluence_terrace": 14.5, "confluence_first_sun": 7.85, "confluence_above": 14.5, "confluence_pool": 14.5, "conch_fall": 14.5, "conch_fall_below": 14.5, "conch_fall_sun": 7.85, "pema_o_front": 15.0, "pema_lama_sang": 6.82, "pema_lama_lip": 7.78, "pema_monks_bowls": 6.83, "pema_monks_service": 8.17, "pema_kora_woman": 6.577, "pema_dipper": 7.0, "v02_0747": 7.783, "v02_0800": 8.0, "v02_0815": 8.25, "v02_mist": 7.5, "ngakpa_above": 15.0, "ngakpa_from_lane": 15.0, "ngakpa_lane": 15.0, "ngakpa_to_service": 7.77, "spring_queue": 5.733, "spring_milk": 6.0, "spring_afternoon": 15.733, "spring_shrine": 15.0, "spring_above": 15.733, "spring_path": 15.6, "lookout_lane": 15.0, "lookout_ramp": 15.0, "lookout_arrive": 16.0, "lookout_terrace": 16.0, "lookout_dusk": 17.1, "gardens_above": 15.0, "v13a_wide": 17.133, "v13a_1700": 17.0, "v13a_1708": 17.133, "v13a_1713": 17.217, "v13a_1717": 17.283, "v13a_close": 17.2, "v05_peak": 17.133, "tsongra_peak": 17.133, "west_edge_dawn": 6.75, "west_mani_dusk": 18.15, "west_mani_foot": 15.5, "west_mani_side": 15.5, "v02_lift": 7.867, "v02_conch": 7.917, "pema_o_quarter": 15.0, "pema_o_hall": 15.0, "pema_o_door": 15.0, "pema_o_kora": 15.0, "pema_o_above": 15.0, "bridge_crossing": 14.52, "bridge_crossing_near": 14.52, "bridge_crossing_up": 15.43, "tsongra_1600": 16.0, "tsongra_1610": 16.17,
		"stair_greg": 8.98, "stair_over_6": 8.98, "stair_over_24": 8.98, "stair_over_55": 14.0, "stair_over_95": 14.0, "stair_close_down": 14.0,
		"caravan_ramp": 15.2, "caravan_gate": 15.42, "caravan_passage": 15.6, "caravan_yard0": 16.08, "caravan_home": 16.97,
		"dechen_garden_n": 15.0, "dechen_garden_s": 15.0, "dechen_garden_above": 15.0, "dechen_chapel_in": 15.0, "dechen_chapel_door": 15.0, "dechen_gallery": 15.0, "dechen_dolkar_in": 15.0, "dechen_clocks": 15.0, "dechen_dolkar_dusk": 17.75, "dechen_garden_night": 20.5, "dechen_lama_reading": 6.67, "dechen_sewers": 9.0, "dechen_steward_gate": 10.05, "dechen_dice": 10.5, "dechen_dolkar_clock": 17.47, "dechen_bard": 21.25, "dechen_gate_barred": 22.5, "dechen_mastiffs": 22.5, "camp_ramp_head": 15.0, "camp_landing": 15.0, "camp_ramp_above": 15.0, "camp_from_field": 15.0, "camp_overview": 15.83, "camp_windbreaks": 15.83, "camp_fodder": 15.0, "camp_dung": 15.0, "camp_wool": 12.0, "herd_gallery": 13.42, "herd_row": 13.92, "herd_pavilion": 14.58, "herd_switchback": 15.2, "herd_ramp_above": 15.25, "herd_from_hejie": 15.33, "herd_ramp_foot": 16.08, "herd_camp": 16.67, "camp_unloading": 16.42, "camp_hay": 17.08, "camp_tents": 17.33, "camp_picket": 17.5, "camp_dusk": 17.67, "camp_fire": 18.5, "camp_night": 21.0, "camp_cv01": 12.5, "hejie_v15": 16.5, "hejie_street": 15.0, "hejie_east_gate": 15.0, "hejie_temple": 15.5, "hejie_above": 15.5, "hejie_dusk": 18.33, "hejie_v03": 15.0, "hejie_v04": 16.17, "hejie_samkha": 15.5, "hejie_landing": 15.0, "castle_ramp_gate": 15.5, "castle_ramp_head": 15.5, "castle_ramp_landing1": 15.5, "castle_ramp_leg2": 15.5, "castle_ramp_above": 15.5, "castle_lane": 15.5, "castle_lane_up": 15.5, "samkha_houses_above": 15.5, "samkha_poor": 15.5, "ula_yard": 15.75, "ula_yard_morning": 7.75, "ula_yard_above": 15.75, "stables_front": 10.0, "ula_gate_out": 15.75, "leat_fall": 15.5, "leat_fall_lip": 15.5, "breach_1861": 15.5, "breach_close": 15.5, "latrine_midden": 15.5, "samkha_ward_hearing": 8.2, "samkha_great_ward": 8.17, "samkha_great_court": 9.67, "samkha_great_headmen": 9.67, "toll_count": 9.79, "toll_argue": 10.2, "samkha_lane_people": 11.0, "serchu_road_zampa": 14.0, "zampa_north": 14.0, "zampa_deck": 14.0, "zampa_side": 14.0, "zampa_rest": 14.0, "serchu_mani": 14.0, "serchu_cairn": 14.0, "serchu_washings": 14.0, "serchu_washings_close": 14.0, "forest_road": 14.0, "forest_from_castle": 14.0, "forest_above": 14.0, "serchu_road_mid": 14.0, "caravan_zampa": 11.00, "herd_zampa": 11.20, "caravan_mani": 12.30, "road_pilgrim": 8.92, "road_rest": 8.72, "washers_fires": 19.00, "washers_work": 10.50, "woodcutters": 11.00, "miller_door": 10.67, "zampa_opening": 14.42, "mills_from_road": 14.0, "mills_row": 14.0, "mill_arch": 14.0, "mill_inside": 14.0, "wheel_house": 14.0, "footbridge": 14.0, "footbridge_side": 14.0, "yak_road_above": 14.0, "barley_terraces": 14.0, "leat_intake": 14.0, "serchu_road_back": 14.0, "serchu_road_across": 14.0, "serchu_road_above": 14.0, "serchu_road_ser20": 14.0, "market_tsongra": 11.0, "market_stalls": 11.0, "market_wide": 11.0, "hejie_market": 11.0, "hejie_market_up": 11.0, "crowd_dawn": 4.83, "crowd_kora": 17.7, "crowd_evening": 19.25, "crowd_morning": 6.33, "market_west": 10.5, "market_east": 10.5,
		"dechen_yard2_w": 15.0, "dechen_yard2_w_shut": 15.0, "dechen_yard2_e_shut": 15.0, "dechen_tibetan_door_shut": 15.0, "dechen_yard2_e": 15.0, "dechen_tibetan_in": 15.0, "dechen_tibetan_door": 15.0, "dechen_chinese_in": 15.0,
		"dechen_chinese_desk": 15.0, "dechen_guest_in": 15.0, "dechen_kitchen_in": 15.0, "dechen_kitchen_door": 15.0, "dechen_kitchen_shut": 15.0, "dechen_yard1": 15.0,
		"dechen_tibetan_people": 13.95, "dechen_chinese_people": 14.3, "dechen_desk_people": 14.0, "dechen_kitchen_people": 14.0,
		"dechen_roof_sang": 17.2, "mon_v01": 15.0, "mon_from_lookout": 16.0, "mon_v09": 11.5, "mon_from_tsongra": 15.0, "mon_from_road": 12.0, "mon_south_flank": 12.0, "mon_wall_south": 12.0, "mon_east_gate": 9.0, "mon_upper_gate": 15.0, "mon_face_close": 16.0, "mon_courtyard": 15.0, "steps_foot": 15.0, "steps_landing6": 15.0, "steps_face": 15.5, "steps_top": 15.0, "conch_bridge_w": 15.0, "conch_bridge_side": 11.5, "steps_lhabab": 15.0, "steps_landing12": 15.0, "steps_niche": 15.0, "parkhang_front": 11.0, "parkhang_court": 11.0, "steps_pilgrims": 8.5, "steps_climb_close": 8.5, "steps_double_ninth": 14.75, "steps_party_close": 14.75, "steps_top_confluence": 15.0, "steps_from_tsongra": 15.5, "steps_from_lookout": 16.0, "steps_from_v01": 15.0, "gorge_from_lookout": 15.0, "gorge_v09": 11.5, "gorge_bridge_side": 11.5, "gorge_face": 15.0, "gorge_gate": 15.0, "gorge_above": 15.0, "gorge_gallery": 15.0, "gorge_rest": 15.0, "gorge_under": 15.0, "gorge_houses": 15.0, "gorge_wheel": 11.5, "gorge_naga": 11.5, "gorge_novices": 14.684, "gorge_novices_rail": 15.0, "gorge_bench": 15.0, "gorge_water_fill": 7.443, "gorge_tulku_bridge": 14.025, "gorge_tulku_meet": 14.55, "gorge_tulku_sit": 15.0, "gorge_tulku_down": 15.308, "tsokchen_court": 15.0, "tsokchen_porch": 15.0, "tsokchen_side": 15.0, "tsokchen_above": 15.0, "court_galleries": 15.0, "tsokchen_roof": 15.0, "tsokchen_v05": 15.0, "v05a_horns": 5.52, "v05a_players": 5.52, "v05a_novice": 5.45, "v05a_sun": 7.4, "v05a_town": 7.4, "v05b_dusk": 17.25, "chora_in": 15.5, "chora_gate": 15.5, "tsenyi_side": 15.5, "tsenyi_front": 15.0, "gyupa_front": 15.0, "colleges_above": 15.0, "mon04_front": 15.0, "mon15_front": 15.0, "mon05_front": 15.0, "mon05_porch": 15.0, "chapels_above": 15.0, "labrang_front": 15.0, "labrang_bay": 16.0, "abbot_house": 15.0, "estate_office": 15.0, "granary_ramp": 15.0, "jakhang_flume": 7.0, "dronkhang_yard": 15.0, "kangyur_porch": 15.0, "novices_yard": 15.0, "geese_pen": 15.0, "kennel": 15.0, "monks_pair": 7.0, "monk_shut_door": 15.0, "face_top": 12.0, "face_stack": 15.0, "gonkor_gallery": 15.0, "gonkor_south": 12.0, "gonkor_dip": 12.0, "mon23_front": 11.0, "mon23_in": 11.0, "gonkor_face_gallery": 15.0, "gonkor_gallery_out": 15.0, "gonkor_l23": 15.0, "gonkor_steps": 15.0, "gonkor_sw": 15.0, "gonkor_east": 10.5, "gonkor_tsatsa": 10.5, "gonkor_east_above": 10.5, "gonkor_north": 12.0, "gonkor_corner": 15.0, "tode_above": 15.0, "tode_path": 15.0, "tode_from_gonpa": 15.0, "tode_west": 15.0, "tode_c1": 15.0, "tode_c2": 15.0, "tode_bon": 15.0, "tode_a": 15.0, "tode_ruin": 15.0, "tode_stair_foot": 15.0, "tode_stair_side": 15.0, "tode_stair_top": 15.0, "tower_whole": 15.5, "tower_log": 15.5, "tower_inside": 15.5, "tower_top": 15.5, "tower_and_gonpa": 15.5, "tower_from_terrace": 15.5, "leat_contour": 15.5, "leat_mill_upper": 15.5, "leat_mill_lower": 15.5, "leat_wheel": 15.5, "leat_wheel_last": 15.5, "leat_steps": 15.5, "leat_culvert": 15.5, "tode_floor": 15.5, "tode_floor_high": 15.5, "tode_byre": 15.5, "tode_rack": 15.5, "tode_walnuts": 15.5, "tode_stall": 15.5, "tode_mani": 15.5, "tode_chapel": 15.5, "tode_bon_niche": 15.5, "tsokchen_curtain": 10.5, "tsokchen_curtain_parted": 10.5, "tsokchen_curtain_w_parted": 10.5, "tsokchen_porch_parted": 10.5, "assembly_boots": 5.75, "v26_door": 10.25, "v26_rows": 10.12, "v26_shafts": 10.25, "tsokchen_shut": 20.0, "tsokchen_sweepers": 8.0, "tsokchen_pilgrim": 12.012, "labrang_audience": 11.05, "gonkhang_vest_parted": 15.0, "tsokchen_nave_in": 10.5, "tsokchen_aisle": 10.5, "tsokchen_gallery_in": 10.5, "tsokchen_chapel_in": 10.5, "tsokchen_nangkor": 10.5, "tsokchen_well_up": 12.0, "s7_noon": 12.0, "s7_dawn": 5.5, "assembly_dawn": 5.75, "assembly_rows": 5.75, "assembly_thrones": 5.75, "assembly_tea": 11.2, "tsokchen_shaft": 12.0, "jampa_door": 11.5, "jampa_up": 11.75, "v30_face": 11.75, "jampa_gallery_w": 11.5, "jampa_ladder": 11.5, "gonkhang_vest": 15.0, "gonkhang_room": 15.0, "gonkhang_yak": 15.0, "gonkhang_conch": 15.0, "kangyur_in": 11.0, "kangyur_east": 11.0, "jakhang_in": 7.0, "jakhang_beakers": 7.0, "monk_store_in": 7.0, "monk_cell_in": 7.0, "labrang_reception": 14.5, "labrang_throne": 14.5, "parkhang_back": 11.0, "parkhang_gate_in": 11.0, "parkhang_arcade": 11.0, "parkhang_stair": 11.0, "parkhang_printing_in": 11.0, "parkhang_press": 11.0, "parkhang_chapel_in": 11.0, "parkhang_canyon": 15.5, "parkhang_canyon_far": 15.5, "parkhang_blocks_close": 15.5, "tode_bon_circuit": 6.2195, "tode_threshing": 10.0, "tode_threshing_b": 10.5, "tode_winnowing": 14.5, "tode_gyaltsen_roof": 10.2, "tode_roof": 10.0, "tode_miller": 11.0, "tode_carrier": 16.8426, "tode_stair_people": 8.1283, "tode_terrace": 15.0, "gonpa_gate_in": 15.0, "gonpa_way_up": 15.0, "gonpa_way_down": 15.5}
var people_hour := -1.0  ## --people-hour=: the townspeople's stills at this hour of the default day (the busiest otherwise)
const PEOPLE_AT := {"people_tsongra": [0.0, 2.0, 16.0], "people_mani": [-50.0, 95.0, 38.0], "people_stair": [-6.0, 95.0, 22.0],
		"people_wheel": [10.0, 95.0, 2.6]}

var cam: Camera3D
var terrain: Terrain3D
var ring: MeshInstance3D
var look: Node3D
var mode := ""
var sound_job: Array = []  ## --sound=<station>:<hour>:<seconds>: a sound run (sprint 8, step 1)
var day: DayCycle
var run_dir := ""
var commit := "none"
var meta := false  ## M1's reference stills (sprint 8, step 8): 5 s with no pipeline compiled before the shot (PC-29), and a sidecar (PC-30)
var uncapped := false
var mem := {}
var load_ms := 0
var jobs: Array = []
var current := {}
var only := ""  ## --only=<station>: shots of one station
var s7 := 0  ## --s7=1..5: spike S7's interior lighting stack in the Tsokchen (world/interior_stack.gd; M3 sprint 5, step 3)
var off := []  ## --off=shadows,ring,volfog,ssao,ssil,glow,ink,households: switch parts of the look off, to find what makes an artefact or costs time (households: the town before IMP-019)
## The route S3 chose (docs/DECISIONS.md, 25 Sep 2026): a clipmap of 32 (Terrain3D's default is 48) and no shadow
## casting by the terrain, whose big shadows come from the horizon map (chapter 09, 10.2). Together they bring the
## terrain under 3 ms at every station. --mesh-size=N and --t3d-shadows measure the alternatives.
var mesh_size := 32
var t3d_shadows := false
var variant := ""  ## the perf variant's name in the summaries: the --off and --mesh-size choices
var town := false  ## --town: place the town the kit can build so far (world/town.gd)
var mist_sea := false  ## --mist=sea: the mist sea's dawn (chapter 08, V-22) instead of the river mist (world/day.gd)
var snow := ""  ## --snow=dust|v31|town|falling: the weather's snow (world/day.gd SNOW; IMP-021)
var people := false  ## --people: TownSim's walkers on the street graph, drawn by the crowd (sprint 4, step 4)
var crowd: Node3D
var named: Node3D  ## the named eight (characters/named.gd), with the people
var caravan: Node3D  ## the caravan CV-02's ten yak (world/caravan.gd), with the people
var herd: Node3D  ## CV-02's other 62 yak, its drovers and mastiffs, down the Caravan Ramp to the camp (world/herd.gd; M2 sprint 9)
var climb_runs := 1  ## --climb: how many times up and down
var route_name := ""  ## --route=: a walk through a building (ROUTES)
var route_hour := -1.0  ## --hour=: the clock for a route, frozen (in play, the hour the day starts at)
var play_at := ""  ## --at=: in play, where the player starts (START_AT), not key 1's view
var play_load := ""  ## --load=: in play, a save to start from (autoload/save.gd; "latest" the newest)
var play_date := ""  ## --date=MM-DD: in play, the day the clock starts on (October to December 1903, January on 1904)
var play_new := false  ## --new: in play, a new game: the story from its start (M2 sprint 1, step 5)
var _last_still_sig := PackedByteArray()  ## the last still in small, to tell a stale one (ISS-122)
var route_from := 0  ## --from=: start a route at its point N (a window's stills of its later part)
var route_stills_from := 0  ## --still0=: the number its stills count on from
var climb_stills := false
var town_count := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a in ["--shots", "--perf", "--walk", "--play", "--ridge", "--climb", "--ladder"]:
			mode = a.substr(2)
		elif a.begins_with("--people-hour="):
			people_hour = float(a.substr(14))
		elif a.begins_with("--route="):
			mode = "route"
			route_name = a.substr(8)
		elif a == "--mist=sea":
			mist_sea = true
		elif a.begins_with("--snow="):
			snow = a.get_slice("=", 1)
		elif a.begins_with("--s7="):
			s7 = int(a.get_slice("=", 1))
		elif a.begins_with("--hour="):
			route_hour = float(a.substr(7))
		elif a.begins_with("--at="):
			play_at = a.substr(5)
		elif a.begins_with("--load="):
			play_load = a.substr(7)
		elif a.begins_with("--date="):
			play_date = a.substr(7)
		elif a == "--new":
			play_new = true
		elif a.begins_with("--from="):
			route_from = int(a.substr(7))
		elif a.begins_with("--still0="):
			route_stills_from = int(a.substr(9))
		elif a.begins_with("--runs="):
			climb_runs = int(a.substr(7))
		elif a == "--stills":
			climb_stills = true
		elif a.begins_with("--run="):
			run_dir = ProjectSettings.globalize_path("res://" + a.substr(6))
		elif a.begins_with("--commit="):
			commit = a.substr(9)
		elif a == "--meta":
			meta = true
		elif a == "--uncapped":
			uncapped = true
		elif a.begins_with("--only="):
			only = a.substr(7)
		elif a.begins_with("--off="):
			off = Array(a.substr(6).split(","))
		elif a == "--town":
			town = true
		elif a == "--people":
			people = true
		elif a == "--walkers":
			mode = "walkers"
			people = true  # (lost in sprint 7, step 7's edit and restored the same day: the spike ran with no people)
		elif a.begins_with("--sound="):
			mode = "sound"
			sound_job = Array(a.substr(8).split(":"))
		elif a == "--codex":
			mode = "codex"
			people = true
		elif a == "--pt-slice":
			mode = "pt-slice"
			people = true
		elif a == "--follow":
			mode = "follow"
			people = true
		elif a == "--save-trip":  # M2 sprint 10, step 5: saved at dusk, the evening on, loaded: everyone drawn where they were
			mode = "save-trip"
			people = true
		elif a.begins_with("--mesh-size="):
			mesh_size = int(a.substr(12))
		elif a == "--t3d-shadows":
			t3d_shadows = true
	if not off.is_empty():
		variant += "_off-" + "-".join(PackedStringArray(off))
	if mesh_size != 32:
		variant += "_mesh%d" % mesh_size
	if t3d_shadows:
		variant += "_t3d-shadows"
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = CANVAS
	get_viewport().scaling_3d_scale = 1.0
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	WorldClock.freeze(20.0)
	if uncapped:
		Quality.uncapped = true  # kept off through tier changes (on battery the policy changes tier)
		Engine.max_fps = 0
	look = Vignette.new()
	look.look_only = true
	add_child(look)
	await look.build()
	for c in look.get_children():
		if c is WorldEnvironment:
			var env: Environment = c.environment
			env.fog_density = 0.00006  # the draft's 0.00028 suits 100 m; a 15 km valley needs about a quarter
			env.volumetric_fog_enabled = env.volumetric_fog_enabled and not "volfog" in off
			env.ssao_enabled = env.ssao_enabled and not "ssao" in off
			env.ssil_enabled = env.ssil_enabled and not "ssil" in off
			env.glow_enabled = env.glow_enabled and not "glow" in off
		elif c is DirectionalLight3D:
			c.shadow_enabled = c.shadow_enabled and not "shadows" in off
	cam = Camera3D.new()
	cam.fov = 68.0
	cam.near = 0.05
	cam.far = 20000.0
	add_child(cam)
	cam.current = true
	for i in 3:
		await get_tree().process_frame
	mem["before"] = _mem()
	var t0 := Time.get_ticks_msec()
	_terrain()
	_ring()
	_rivers()
	if town:
		var t1 := Time.get_ticks_msec()
		Households.plain = "households" in off  # the town before IMP-019 (world/households.gd)
		var n: Dictionary = Town.place(self)
		town_count = n["placed"]
		print("s3: town: %d buildings from %d kit files and %d cells of retaining walls in %d ms; %d records wait for their kit steps; %d roof burners" % [n["placed"], n["files"], n["walls"], Time.get_ticks_msec() - t1, n["waiting"], n["burners"]])
		if s7 > 0 and InteriorStack.new().setup(get_node_or_null("Town/MON-01") as Node3D, s7):
			print("s3: spike S7: the Tsokchen under stack %d" % s7)
	if people and town:
		_start_people()
	for i in 3:
		await get_tree().process_frame
	load_ms = Time.get_ticks_msec() - t0
	mem["after"] = _mem()
	Telemetry.event("s3_load", {"load_ms": load_ms, "regions": terrain.data.get_region_count(), "mem_before": mem["before"], "mem_after": mem["after"]})
	print("s3: loaded %d regions and the ring in %d ms; static memory +%.0f MB, video +%.0f MB (textures +%.0f MB)" % [
		terrain.data.get_region_count(), load_ms, mem["after"]["static_mb"] - mem["before"]["static_mb"],
		mem["after"]["video_mb"] - mem["before"]["video_mb"], mem["after"]["texture_mb"] - mem["before"]["texture_mb"]])
	match mode:
		"shots":
			_start_shots()
		"perf":
			Quality.start_thermal()
			_start_perf()
		"walk":
			_start_walk()
		"play":
			_start_play()
		"ridge":
			_start_ridge()
		"climb":
			_start_climb()
		"ladder":
			_start_ladders()
		"route":
			_start_route()
		"walkers":
			_start_walkers()
		"codex":
			_start_codex()
		"sound":
			_start_sound()
		"follow":
			_start_follow()
		"save-trip":
			_start_trip()
		"pt-slice":
			_start_pt_slice()
		_:
			print("s3: no mode given; use --shots, --perf or --walk")
			get_tree().quit()


func _mem() -> Dictionary:
	return {"static_mb": OS.get_static_memory_usage() / 1048576.0,
		"video_mb": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0,
		"texture_mb": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0}


func _terrain() -> void:
	terrain = Terrain3D.new()
	terrain.name = "Terrain3D"
	var mat := Terrain3DMaterial.new()
	mat.world_background = Terrain3DMaterial.NONE
	mat.shader_override = TERRAIN_SHADER
	mat.shader_override_enabled = true
	terrain.material = mat
	terrain.collision_mode = Terrain3DCollision.DYNAMIC_GAME
	terrain.mesh_size = mesh_size
	if not t3d_shadows:
		terrain.cast_shadows = RenderingServer.SHADOW_CASTING_SETTING_OFF
	terrain.data_directory = DATA
	terrain.set_camera(cam)
	add_child(terrain)
	# With no textures in its asset list Terrain3D turns on its checkerboard debug view at start-up, which replaces
	# any shader; this terrain has no textures by design (its colour is procedural), so the view goes off again.
	terrain.material.show_checkered = false
	mat.set_shader_param("noise_tex", look.noise_tex)


## The rivers' water (M2 sprint 5, step 2; world/rivers.gd from data/rivers.json; --off=rivers leaves it out).
func _rivers() -> void:
	if "rivers" in off or not FileAccess.file_exists("res://data/rivers.json"):
		return
	var rv := Rivers.new()
	rv.name = "Rivers"
	add_child(rv)
	print("s3: rivers: %s" % rv.build(look.noise_tex))
	var lf := LeatFall.new()  # the Leat Fall down the slot's face (world/leat_fall.gd; M2 sprint 11, step 4)
	lf.name = "LeatFall"
	add_child(lf)
	print("s3: %s" % lf.build(look.noise_tex))
	var lt := Leat.new()  # the Serchu leat's water, its chutes and race (world/leat.gd; M2 sprint 12, step 5)
	lt.name = "Leat"
	add_child(lt)
	print("s3: %s" % lt.build(look.noise_tex))


func _ring() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RING + ".json"))
	var n: int = meta["n"]
	var step: float = meta["step"]
	var x0: float = meta["x0"]
	var z0: float = meta["z0"]
	var hole: Dictionary = meta["hole"]
	var hs := FileAccess.get_file_as_bytes(RING + ".r32").to_float32_array()
	var verts := PackedVector3Array()
	verts.resize(n * n)
	for j in n:
		var z := z0 + j * step
		for i in n:
			var x := x0 + i * step
			var y := hs[j * n + i]
			# Under Terrain3D the ring sinks 3 m, so the valley covers it; one step of overlap fills the valley's ragged edge.
			if x >= hole["x0"] and x <= hole["x1"] and z >= hole["z0"] and z <= hole["z1"]:
				y -= 3.0
			verts[j * n + i] = Vector3(x, y, z)
	var normals := PackedVector3Array()
	normals.resize(n * n)
	for j in n:
		for i in n:
			var l := hs[j * n + maxi(i - 1, 0)]
			var r := hs[j * n + mini(i + 1, n - 1)]
			var u := hs[maxi(j - 1, 0) * n + i]
			var d := hs[mini(j + 1, n - 1) * n + i]
			normals[j * n + i] = Vector3(l - r, 2.0 * step, u - d).normalized()
	var idx := PackedInt32Array()
	var hx0: float = hole["x0"] + step
	var hx1: float = hole["x1"] - step
	var hz0: float = hole["z0"] + step
	var hz1: float = hole["z1"] - step
	for j in n - 1:
		var qz0 := z0 + j * step
		for i in n - 1:
			var qx0 := x0 + i * step
			if qx0 >= hx0 and qx0 + step <= hx1 and qz0 >= hz0 and qz0 + step <= hz1:
				continue
			var a := j * n + i
			idx.append_array([a, a + 1, a + n, a + 1, a + n + 1, a + n])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m := ShaderMaterial.new()
	m.shader = FAR_SHADER
	m.set_shader_parameter("noise_tex", look.noise_tex)
	ring = MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = mesh
	ring.material_override = m
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # chapter 09, 13.4: the ring casts none
	add_child(ring)
	ring.visible = not "ring" in off


func _ground(x: float, y_north: float) -> float:
	return terrain.data.get_height(Vector3(x, 0.0, -y_north))


func _place(st: Array) -> void:
	cam.global_position = Vector3(st[1], _ground(st[1], st[2]) + st[3], -st[2])
	if st.size() > 6 and st[6] == "abs":  # the height above sea level itself: over a narrow ledge's drop, level with the house
		cam.global_position.y = Town.to_godot(st[1], st[2], st[3]).y
	# A camera looks along -Z, which is north; turning by -b faces the bearing b (clockwise from north). (Set here for
	# every station: from sprint 3, step 5 until sprint 4, step 2 only the stations "on top" were turned, and the others
	# all shot north and level.)
	cam.rotation = Vector3(deg_to_rad(st[5]), -deg_to_rad(st[4]), 0.0)
	cam.fov = float(st[7]) if st.size() > 7 and (st[7] is float or st[7] is int) else 68.0  # a station's own lens (V-13a's close)
	# A station "on top" stands on whatever stands there (a roof: V-28 is taken from the Rooftop Way's top), once the
	# town's collision is in the physics world: _shot_tick calls _stand_on_top a few frames in.


func _stand_on_top(st: Array) -> void:
	var q := PhysicsRayQueryParameters3D.create(Vector3(st[1], 3000.0, -st[2]), Vector3(st[1], -3000.0, -st[2]))
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if OS.get_environment("STATION_DEBUG") != "":
		print("s3: %s: ground %.2f, hit %s on %s" % [st[0], _ground(st[1], st[2]), str(hit.get("position", "nothing")), str(hit.get("collider", ""))])
	if not hit.is_empty():
		cam.global_position.y = (hit["position"] as Vector3).y + st[3]


# ------------------------------------------------------------------ shots
func _start_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if town and not "ink" in off:  # M1's ink and air on the valley's stills as in play (world/ink.gd; the stills had none
		Ink.attach(cam)  # until 28 Sep 2026: the player's camera carries it, the stills' did not; --off=ink leaves it out)
	for st in STATIONS:
		if only == "" or st[0] in only.split(","):
			jobs.append(st)
	for o in only.split(","):  # door_<house>: before a town house's door, as it is dressed (IMP-019; world/door_dressing.gd)
		if o.begins_with("door_H-"):  # roof_<house>: over its roof (a shut or left house's grass)
			jobs.append([o, 0.0, 0.0, 0.0, 0.0, 0.0, "door"])
		elif o.begins_with("roof_H-"):
			jobs.append([o, 0.0, 0.0, 0.0, 0.0, 0.0, "roof"])
	_next_shot()


## The game minute at an hour of the default day (Wednesday 28 October 1903; WorldClock.DEFAULT_MINUTE is its 14:00).
static func _minute_at(hour: float) -> float:
	return WorldClock.DEFAULT_MINUTE + (hour - 14.0) * 60.0


## The day's light and the horizon map, as the town has them (art steps A7, A8), with the valley's thinner fog.
func _day() -> void:
	Horizon.load_globals()
	day = DayCycle.new()
	day.fog_scale = 0.25  # as the look's 0.00006 against the draft's 0.00028: a 15 km valley needs about a quarter
	day.mist = town  # the valley's mist and the low sun's rays (IMP-021), where the town stands on the valley
	day.mist_sea = mist_sea
	day.snow = snow
	for c in look.get_children():
		if c is DirectionalLight3D:
			day.sun = c
		elif c is WorldEnvironment:
			day.env = (c as WorldEnvironment).environment
	add_child(day)


func _start_ridge() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_day()
	for t in RIDGE_TIMES:
		if only == "" or "%02d%02d" % [t[0], t[1]] == only:
			jobs.append(t)
	_next_ridge()


func _next_ridge() -> void:
	if jobs.is_empty():
		print("s3: ridge shots done in %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()
		return
	var t: Array = jobs.pop_front()
	var minute: float = 7 * 1440.0 + t[0] * 60 + t[1]
	WorldClock.freeze(20.0, minute)
	day.update(minute)
	_place(RIDGE_STATION)
	current = {"name": "ridge_%02d%02d" % [t[0], t[1]], "wait": 45, "last": -1, "quiet": 0, "drawn": Engine.get_frames_drawn()}
	print("s3: ridge %s, sun %.1f deg at %.0f deg" % [Calendar.clock(minute), day.last["sun_alt"], Calendar.sun_alt_az(minute).y])


func _next_shot() -> void:
	if jobs.is_empty():
		print("s3: shots done in %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()
		return
	var st: Array = jobs.pop_front()
	_place(st)
	var rooms := get_tree().get_first_node_in_group("interiors")
	if rooms != null:
		rooms.set("instant", true)  # a still takes the eye as adjusted, not half way (world/interiors.gd)
	Codex.toggle_page(false)
	Story.toggle_page(false)
	var subs: Node = Codex.call("_subs")
	subs.set("quiet_notices", true)  # no codex notice over a still: a site found at the station before, or at this one
	if st[0] == "ledger_page":  # the ledger on day 1 at dusk: the letter given in the open, the roofs to come
		new_game()
		Story.done("m1_letter")
		Story.write("m1_given", "note", "Gave Achak Dolkar the house's letter in the open. Others saw it handed over.", "achak_dolkar")
		Story.write("m1_roofs", "note", "The child of the house will show me the way up onto the roofs at dusk.", "", "Dechen-tsang's guest yard")
		Story.learn("PB-T01", "what the hostess says to a guest arriving")
		Story.owe("achak_dolkar", -2.0)
		Story.toggle_page(true)
	if st[0] == "codex_page":  # eight found, the page open
		Codex.reset()
		for id in ["CX-047", "CX-049", "CX-050", "CX-052", "CX-053", "CX-057", "CX-064", "CX-071"]:
			Codex.find(id)
		Codex.toggle_page(true)
	if STATION_HOUR.has(st[0]) or day != null or snow != "":  # the day's light at the station's hour, or back at 14:00 after one (and the weather's snow with it)
		if day == null:
			_day()
		var minute := _minute_at(float(STATION_HOUR.get(st[0], 14.0)))
		if STATION_DAY.has(st[0]):
			minute = float(STATION_DAY[st[0]]) * 1440.0 + float(STATION_HOUR.get(st[0], 14.0)) * 60.0
		WorldClock.freeze(20.0, minute)
		day.update(minute)
		print("s3: %s at %s: sun %.1f deg; the moon %.1f deg up at %.0f deg" % [st[0], Calendar.clock(minute), day.last["sun_alt"],
				Calendar.moon_alt_az(minute).x, Calendar.moon_alt_az(minute).y])
	var doors := get_node_or_null("Town/Doors")
	if doors != null:  # the room doors (world/doors.gd; ISS-105): shut for a station "_shut", else standing open
		for i in (doors.get("doors") as Array).size():
			doors.call("set_open", i, not String(st[0]).ends_with("_shut"))
		doors.call("_process", 1.0)
	var curtains := get_node_or_null("Town/Curtains")
	if curtains != null:  # the halls' curtains (world/curtains.gd; M3 sprint 6): held half parted for a station "_parted", else hanging
		var eye := get_viewport().get_camera_3d()
		curtains.call("hold", eye.global_position - eye.global_basis.z * 4.0, String(st[0]).ends_with("_parted"), eye.global_position)
	if String(st[0]).begins_with("guide_") and GUIDE_AT.has(st[0]):  # the child of the house held at a point of her way
		var g := get_tree().get_first_node_in_group("guide")
		if g != null:
			g.call("show_at", float(g.call("climb_at", int(GUIDE_AT[st[0]][0]))) + float(GUIDE_AT[st[0]][1]))
	if crowd != null and PEOPLE_AT.has(st[0]):  # the townspeople at the afternoon's minute most of them are in the view,
		var f: Array = PEOPLE_AT[st[0]]  # the clock and the light set to it (their days are the clock's: sprint 6, step 1)
		var base := WorldClock.minute - fposmod(WorldClock.minute, 1440.0)
		var m := base + (people_hour * 60.0 if people_hour >= 0.0 else TownSim.busiest_time(Town.to_godot(f[0], f[1], 2700.0), f[2], 13.5 * 60.0, 16.5 * 60.0, 0.5))
		WorldClock.freeze(20.0, m)
		if day == null:
			_day()
		day.update(m)
		TownSim.step(0.0, cam.global_position)
		print("s3: %s: the townspeople at %s" % [st[0], Calendar.clock(m)])
	if st.size() > 6 and st[6] == "door":
		_door_shot(String(st[0]).substr(5))
	if st.size() > 6 and st[6] == "roof":
		var h := get_node_or_null("Town/" + String(st[0]).substr(5)) as Node3D
		if h != null:  # 10 m out in front and 9 m over the roof, looking down at it
			var top := h.global_position + Vector3(0.0, 8.0, 0.0)
			cam.global_position = top + h.global_basis * Vector3(4.0, 9.0, 10.0)
			cam.look_at(top, Vector3.UP)
	if st.size() > 6 and st[6] == "named":
		if named == null:
			print("s3: %s: no named eight (run with --town --people)" % st[0])
			_next_shot()
			return
		_named_shot(st[0])
	current = {"name": st[0], "wait": 45, "last": -1, "quiet": 0, "station": st, "drawn": Engine.get_frames_drawn()}


## A still before a town house's door (IMP-019): 4.2 m out from its first DOOR socket and a little to its left, at eye
## height, looking at the door's middle.
func _door_shot(house: String) -> void:
	var h := get_node_or_null("Town/" + house) as Node3D
	var socks: Array = [] if h == null else h.find_children("SOCK_DOOR_*", "Node3D", true, false)
	if socks.is_empty():
		print("s3: door_%s: no such house or no door" % house)
		return
	socks.sort_custom(func(a, b): return String(a.name) < String(b.name))
	var t := (socks[0] as Node3D).global_transform
	var back := 4.2 if t.origin.y - h.global_position.y < 0.6 else 6.5  # a door up its stair: further out, to see the stair
	cam.global_position = t * Vector3(-0.8, 1.6, back)
	cam.global_position.y = maxf(cam.global_position.y, h.global_position.y + 1.6)
	cam.look_at(t * Vector3(0.0, 0.6 if back > 5.0 else 1.5, 0.0), Vector3.UP)


## A still of one of the named eight at its hour (NAMED_SHOTS): the clock and the light set to it, the camera before the
## figure and a little round to its right, looking at its chest.
func _named_shot(name: String) -> void:
	var ns: Array = NAMED_SHOTS[name]
	var m := _minute_at(float(ns[1]))
	WorldClock.freeze(20.0, m)
	if day == null:
		_day()
	day.update(m)
	TownSim.step(0.0, cam.global_position)
	var i := Array(TownSim.key).find(String(ns[0]))
	if i < 0:
		print("s3: %s: no %s among the walkers" % [name, ns[0]])
		return
	var p: Vector3 = TownSim.pos[i]
	var a: float = TownSim.yaw[i] + deg_to_rad(float(ns[4]))
	var chest := p + Vector3(0.0, 1.05 if TownSim.state[i] != 3 and TownSim.state[i] != 5 else 0.7, 0.0)
	cam.global_position = p + Vector3(sin(a), 0.0, cos(a)) * float(ns[2]) + Vector3(0.0, float(ns[3]), 0.0)
	cam.look_at(chest)
	print("s3: %s: %s at %s, state %d, at town (%.1f, %.1f, %.1f)" % [name, ns[0], Calendar.clock(m), TownSim.state[i], p.x, -p.z, p.y])


# ------------------------------------------------------------------ perf
func _start_perf() -> void:
	for st in STATIONS:
		if only != "":  # --only=: those stations' turns with everything drawn (M2 sprint 13, step 5: spike S2 with the spur full)
			if st[0] in only.split(","):
				jobs.append([st, "all"])
		elif st[0] in ["tsongra_ne", "pharkha_e", "high_sw"]:
			for cond in ["all", "ring_only", "sky_only"]:
				jobs.append([st, cond])
	_next_pass()


func _next_pass() -> void:
	if jobs.is_empty():
		Quality.stop_thermal()
		print("s3: perf done")
		get_tree().quit()
		return
	var job: Array = jobs.pop_front()
	var st: Array = job[0]
	terrain.visible = job[1] == "all"
	ring.visible = job[1] != "sky_only"
	_place(st)
	current = {"station": st[0], "cond": job[1], "yaw0": cam.rotation.y, "frame": -1, "until": Time.get_ticks_msec() + SETTLE_MS, "rows": []}
	current["name"] = "s3_%s_%s%s_%s" % [st[0], job[1], variant, "uncapped" if uncapped else "capped"]


func _summary() -> Dictionary:
	var intervals := PackedFloat32Array()
	var csv := FileAccess.open(run_dir.path_join(current["name"] + ".csv"), FileAccess.READ)
	csv.get_line()
	while not csv.eof_reached():
		var cols := csv.get_line().split(",")
		if cols.size() > 1:
			intervals.append(float(cols[1]))
	intervals.sort()
	var rows: Array = current["rows"]
	var n := intervals.size()
	var dc := 0.0
	var prim_max := 0.0
	var vid := 0.0
	var stat := 0.0
	var seen := {}
	for r in rows:
		dc += r["draw_calls"]
		prim_max = maxf(prim_max, r["primitives"])
		vid = maxf(vid, r["mem_video_mb"])
		stat = maxf(stat, r["mem_static_mb"])
		seen["%d/%d" % [r["primitives"], r["draw_calls"]]] = true
	var valid: bool = seen.size() > 1 or current["cond"] != "all"  # a lone mesh or bare sky draws the same counts every frame
	var line := {"date": Time.get_datetime_string_from_system(), "commit": commit, "route": "s3@%s:%s%s" % [current["station"], current["cond"], variant],
		"view": 0, "mode": "uncapped" if uncapped else "capped", "frames": n, "p50_ms": intervals[n / 2],
		"p95_ms": intervals[mini(n - 1, int(n * 0.95))], "p99_ms": intervals[mini(n - 1, int(n * 0.99))], "worst_ms": intervals[n - 1],
		"engine_process_ms": 0.0, "engine_physics_ms": 0.0, "render_cpu_ms": 0.0, "draw_calls": dc / maxf(rows.size(), 1.0),
		"primitives_max": prim_max, "objects": 0.0, "mem_static_mb_max": stat, "mem_video_mb_max": vid,
		"mpx_3d": CANVAS.x * CANVAS.y / 1000000.0, "tier": String(current.get("tier", "1080p")), "thermal": Telemetry.thermal, "valid": "yes" if valid else "NO (not redrawn)"}
	var path := ProjectSettings.globalize_path(HISTORY)
	var fresh := not FileAccess.file_exists(path)
	var h := FileAccess.open(path, FileAccess.READ_WRITE if not fresh else FileAccess.WRITE)
	if fresh:
		h.store_line(",".join(HISTORY_COLUMNS))
	h.seek_end()
	var out := PackedStringArray()
	for c in HISTORY_COLUMNS:
		var v = line[c]
		out.append(("%.2f" % v) if typeof(v) == TYPE_FLOAT else str(v))
	h.store_line(",".join(out))
	h.close()
	print("s3: %s%s: p50 %.2f ms, p95 %.2f, worst %.2f; draw calls mean %.0f; primitives max %.2f M; video %.0f MB; static %.0f MB" % [
		"" if valid else "INVALID ", current["name"], line["p50_ms"], line["p95_ms"], line["worst_ms"], line["draw_calls"],
		prim_max / 1000000.0, vid, stat])
	var sum := 0.0
	for v in intervals:
		sum += v
	line["mean_ms"] = sum / maxf(n, 1.0)
	return line


# ------------------------------------------------------------------ walk
func _start_walk() -> void:
	var p := CharacterBody3D.new()
	p.set_script(PlayerScript)
	p.name = "Player"
	add_child(p)
	var start := Vector3(0.0, _ground(0.0, 0.0) + 1.0, 0.0)
	p.global_position = start
	p.yaw = 0.0
	p.rotation.y = 0.0
	p.cam.current = true
	terrain.set_camera(p.cam)
	p.scripted = true
	current = {"player": p, "start": start, "frames": 0, "lowest_clear": 999.0, "max_up": 0.0, "dist": 0.0, "last": start, "turns": 0}


# ------------------------------------------------------------------ play
func _start_play() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, false)
	var p := CharacterBody3D.new()
	p.set_script(PlayerScript)
	p.ink_air = true  # M1's ink pass (art step A5)
	p.third_person = true  # M1's player, seen from behind
	# Keys 1-5: the five stations (Blender axes: x, -z, y; the feet on the ground); 6: the foot of the talkers' steps, the
	# Sky Stair ahead (sprint 3, step 3); 7 and 8 the Rooftop Way's ends, 9 and 0 the Mani Lhakhang and the Mani Lane
	# (below). The other slice stations stand over the stair's ramps, not on the ground.
	for st in STATIONS.slice(0, 5) + STATIONS.filter(func(x): return x[0] == "slice_stair_foot"):
		var feet := Vector3(st[1], _ground(st[1], st[2]) + st[3] - 1.6, -st[2])
		var b := deg_to_rad(st[4])
		var look := feet + Vector3(sin(b), 1.6 + tan(deg_to_rad(st[5])), -cos(b)) * 100.0
		p.views.append([Vector3(feet.x, -feet.z, feet.y), Vector3(look.x, -look.z, look.y)])
	# 7: the Rooftop Way's start, Dechen-tsang's guest yard, facing its first stair-ladder; 8: its last roof, V-28's,
	# looking out over the town at 165 degrees as chapter 02's V-28 does (sprint 4, step 1)
	var rp: Array = _rooftop_points()[0]
	if rp.size() > 2:
		var a: Vector3 = rp[0]
		var d := (rp[1] as Vector3) - a
		d.y = 0.0
		var la := a + d.normalized() * 100.0 + Vector3(0.0, 1.6, 0.0)
		p.views.append([Vector3(a.x, -a.z, a.y), Vector3(la.x, -la.z, la.y)])
		var e: Vector3 = rp[rp.size() - 1]
		var b8 := deg_to_rad(165.0)
		var le := e + Vector3(sin(b8), 1.6 - 0.14, -cos(b8)) * 100.0
		p.views.append([Vector3(e.x, -e.z, e.y), Vector3(le.x, -le.z, le.y)])
	# 9: the Mani Lhakhang's forecourt, in from the gap in the Sky Stair's east cheek, facing its door; 0: the Mani Lane's
	# west end, on the wall's north side, the wall on the right going east (sprint 4, step 3)
	var wp: Array = _wheel_points()[0]
	var f9: Vector3 = wp[2]
	var d9 := (wp[4] as Vector3) - f9
	d9.y = 0.0
	var l9 := f9 + d9.normalized() * 100.0 + Vector3(0.0, 1.6, 0.0)
	p.views.append([Vector3(f9.x, -f9.z, f9.y), Vector3(l9.x, -l9.z, l9.y)])
	var f0 := Vector3(-84.0, _ground(-84.0, 97.2), -97.2)
	var l0 := f0 + Vector3(100.0, 1.6 + 3.0, 0.0)
	p.views.append([Vector3(f0.x, -f0.z, f0.y), Vector3(l0.x, -l0.z, l0.y)])
	p.name = "Player"
	add_child(p)
	p.teleport(0)
	if START_AT.has(play_at):  # --at= (tools/play.sh's AT): a named start, as a last view (Blender axes: x, -z, y)
		var sa: Array = START_AT[play_at]
		var feet := Vector3(sa[0], _ground(sa[0], sa[1]) if sa.size() < 5 else Town.to_godot(sa[0], sa[1], sa[4]).y, -sa[1])
		var look := feet + Vector3(sin(deg_to_rad(sa[2])), 1.6 + tan(deg_to_rad(sa[3])), -cos(deg_to_rad(sa[2]))) * 100.0
		p.views.append([Vector3(feet.x, -feet.z, feet.y), Vector3(look.x, -look.z, look.y)])
		p.teleport(p.views.size() - 1)
	p.flying = false
	if named != null:  # Nyima follows the new player, heads glance at it (chapter 05, 9.6)
		named.player = p
	p.cam.current = true
	terrain.set_camera(p.cam)
	# The day runs from 14:00 at 6:1 (hold T for 60:1, [ and ] an hour), with the ridge shadows (art steps A7, A8); from
	# another hour with --hour= (tools/play.sh's HOUR: the caravan at 15.2, Tsongra at 16; sprint 6, step 6).
	if route_hour >= 0.0:
		WorldClock.minute = _minute_at(route_hour)
	if play_date != "":  # (tools/play.sh's DATE: the full moon's, 11-05, for the tulku's afternoon home; M3 sprint 2, step 6)
		var mo := int(play_date.get_slice("-", 0))
		var h := route_hour if route_hour >= 0.0 else 14.0
		WorldClock.minute = Calendar.minute_of(1903 if mo >= 10 else 1904, mo, int(play_date.get_slice("-", 1)), int(h), int(round(fposmod(h, 1.0) * 60.0)))
	WorldClock.frozen = false
	_day()
	var hud := Hud.new()
	hud.show_clock = true
	hud.third_person = true
	hud.player = p  # (the walk shown by the clock, the sling's aiming dot)
	add_child(hud)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tier="):  # tools/play.sh's sharp and native
			Quality.tier = arg.substr(7)
			Quality.base_tier = Quality.tier
	Quality.track(get_viewport())
	if play_new:  # --new (tools/play.sh's NEW=1): the story from its start, the house's letter in the chuba
		new_game()
	if play_load != "":  # --load= (tools/play.sh's LOAD): the save's clock, the player and the doors as they were
		var slot := Save.latest() if play_load == "latest" else play_load
		print("s3: play: loaded %s: %s" % [slot, Save.load_game(slot)])
	print("s3: play: W S forward and back, A D turn, drag with the left button to look round, the right to steer, Shift held sprint, Option walk (or a PS4 controller), F to fly (E/Q), 1-5 the stations, 6 the Sky Stair's foot, 7-8 the Rooftop Way's ends, 9 the Mani Lhakhang, 0 the Mani Lane; F5 saves, F9 loads the last save")


## A new game (chapter 14, 4.1, mission 1): nothing known, nothing found, the house's sealed letter in the chuba and
## the errand written in the ledger; started with the caravan (tools/play.sh: NEW=1 HOUR=15.2 AT=yak_gate).
func new_game() -> void:
	Story.reset()
	Codex.reset()
	Story.set_flag("story")
	Story.set_flag("has_letter")
	Story.write("m1_letter", "mission", "Bring the house's sealed letter to Achak Dolkar of Dechen-tsang, who keeps the caravan's credit in Dungkardo. She meets the caravan; her house is on Netsang Lam.", "achak_dolkar", "Dechen-tsang")
	Story.write("m2_talk", "mission", "Before the house's news is known, learn what Dungkardo is saying. People talk where they drink: the chang house above Tsongra fills in the evening.", "", "the chang house")
	print("s3: play: a new game: the letter in the chuba")


# ------------------------------------------------------------------ frames
func _process(dt: float) -> void:
	if crowd != null:  # the townspeople: frozen for stills, their own clock otherwise
		var eye := get_viewport().get_camera_3d().global_position
		TownSim.step(0.0 if mode in ["shots", "ridge"] else dt, eye)
		crowd.update(eye)
		if caravan != null:  # before the named: it places the drovers
			caravan.update(eye)
		if herd != null:
			herd.update(eye)
		if named != null:
			named.update(dt, eye)
	if current.is_empty():
		return
	match mode:
		"walkers":
			_walkers_tick(dt)
		"follow":
			_follow_tick(dt)
		"save-trip":
			_trip_tick(dt)
		"pt-slice":
			_pt_tick()
		"shots", "ridge":
			_shot_tick()
		"perf":
			_perf_tick()
		"walk":
			_walk_tick(dt)
		"climb":
			_climb_tick(dt)
		"ladder":
			_ladder_tick(dt)
		"route":
			_route_tick(dt)
		"codex":
			_codex_tick(dt)


func _shot_tick() -> void:
	current["wait"] -= 1
	var st: Array = current.get("station", [])
	if current["wait"] == 38 and st.size() > 6 and st[6] == "on top":
		_stand_on_top(st)
	var pipes := int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW)) + int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION))
	current["quiet"] = current["quiet"] + 1 if pipes == current["last"] else 0
	current["last"] = pipes
	if current["wait"] > 0 or current["quiet"] < (150 if meta else 10):  # PC-29: 5 s at 30 fps with none compiled
		return
	# frames drawn, not ticks: a window hidden or covered stops drawing while the ticks go on, and its still would be the
	# last frame it drew (ISS-122)
	if Engine.get_frames_drawn() - int(current.get("drawn", 0)) < 30:
		return
	var suffix := "" if off.is_empty() else "_off-" + "-".join(PackedStringArray(off))
	if mist_sea:
		suffix += "_sea"  # the mist sea's dawn, beside the river mist's (IMP-021)
	if snow != "":
		suffix += "_snow-" + snow  # beside the season's own (IMP-021, item 4)
	if s7 > 0:
		suffix += "_s7-%d" % s7  # spike S7's stacks side by side (M3 sprint 5, step 3)
	var path := ProjectSettings.globalize_path(OUT).path_join("s3_%s%s.png" % [current["name"], suffix])
	var img := get_viewport().get_texture().get_image()
	var sig := _still_sig(img)
	if sig == _last_still_sig and int(current.get("retakes", 0)) < 3:  # the same frame as the last still: stale (ISS-122)
		current["retakes"] = int(current.get("retakes", 0)) + 1
		current["wait"] = 45
		current["drawn"] = Engine.get_frames_drawn()
		print("s3: %s: the same frame as the last still (the window not drawing?): retaking (%d)" % [current["name"], current["retakes"]])
		return
	_last_still_sig = sig
	img.save_png(path)
	var dc := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	print("s3: shot %s (draw calls %d, primitives %.2f M)" % [path, dc, prims / 1000000.0])
	if meta:  # PC-30: the still's viewpoint, game time, weather, commit; and PC-28's settings, PC-29's quiet frames
		if commit == "none":
			var out: Array = []
			OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"), "rev-parse", "--short", "HEAD"], out)
			commit = String(out[0]).strip_edges() if not out.is_empty() else "none"
		var m := {"station": current["name"], "clock": Calendar.clock(WorldClock.minute), "minute": WorldClock.minute, "weather": "clear",
				"tier": String(Quality.get("tier")), "size": [img.get_width(), img.get_height()], "commit": commit,
				"quiet_frames": int(current["quiet"]), "draw_calls": dc, "primitives": prims, "people": people}
		var f := FileAccess.open(path.get_basename() + ".json", FileAccess.WRITE)
		f.store_string(JSON.stringify(m, " "))
		f.close()
	if town:  # the kit step's end-of-step counts (chapter 03, 14.9), one line per view
		var csv := ProjectSettings.globalize_path("res://perf/kit_counts.csv")
		var fresh := not FileAccess.file_exists(csv)
		var f := FileAccess.open(csv, FileAccess.READ_WRITE if not fresh else FileAccess.WRITE)
		if fresh:
			f.store_line("date,commit,step,view,buildings,draw_calls,primitives")
		f.seek_end()
		f.store_line("%s,%s,K5,%s,%d,%d,%d" % [Time.get_datetime_string_from_system(), commit, current["name"], town_count, dc, prims])
		f.close()
	current = {}
	if mode == "ridge":
		_next_ridge()
	else:
		_next_shot()


func _perf_tick() -> void:
	if current["frame"] < 0:
		if Time.get_ticks_msec() < current["until"]:
			return
		current["frame"] = 0
		Telemetry.tag = current["name"]
		Telemetry.start_csv(run_dir.path_join(current["name"] + ".csv"))
		return
	current["frame"] += 1
	cam.rotation.y = current["yaw0"] + TAU * float(current["frame"]) / FRAMES
	current["rows"].append(Telemetry.sample(0.0))
	if current["frame"] >= FRAMES:
		Telemetry.stop_csv()
		_summary()
		current = {}
		_next_pass()


func _walk_tick(dt: float) -> void:
	var p: CharacterBody3D = current["player"]
	current["frames"] += 1
	current["t"] = current.get("t", 0.0) + dt
	var pos := p.global_position
	var ground := _ground(pos.x, -pos.z)
	current["lowest_clear"] = minf(current["lowest_clear"], pos.y - ground)
	current["max_up"] = maxf(current["max_up"], pos.y - current["start"].y)
	current["dist"] += Vector2(pos.x - current["last"].x, pos.z - current["last"].z).length()
	current["last"] = pos
	# Run towards the real hillside 600 m west of Tsongra, which rises about 400 m (docs/terrain/base-report.md);
	# steering by the steepest ascent stalled on a 4 m knoll. Twice a second the body turns towards the target.
	if current["frames"] % 15 == 1:
		var n := terrain.data.get_normal(pos)
		var to := Vector2(WALK_TARGET.x - pos.x, WALK_TARGET.z - pos.z).normalized()
		p.yaw = atan2(-to.x, -to.y)
		p.rotation.y = p.yaw
		p.scripted_move = Vector3(0.0, 1.0, -1.0)
		if current["frames"] % 150 == 1:
			print("s3: walk t %.1f s at (%.0f, %.1f, %.0f), ground %.1f, normal %s, yaw %.0f°, velocity %s" % [
				current["t"], pos.x, pos.y, pos.z, ground, str(n), rad_to_deg(p.yaw), str(p.velocity)])
	if current["t"] >= 25.0:
		var ok: bool = current["dist"] > 60.0 and current["max_up"] > 5.0 and current["lowest_clear"] > -0.5
		print("s3: walk %s: moved %.1f m along the ground, climbed %.1f m, lowest clearance %.2f m above the terrain (fail below -0.5)" % [
			"PASS" if ok else "FAIL", current["dist"], current["max_up"], current["lowest_clear"]])
		get_tree().quit()


# ------------------------------------------------------------------ climb (spike S15)
const CLIMB_STILLS := [[2.0, "gateway"], [8.5, "in_gateway"], [21.0, "feet"], [30.5, "tunnel"], [44.5, "tunnel_window"]]


func _start_climb() -> void:
	var st: Node3D = get_node_or_null("Town/SHL-15")
	if st == null:
		print("s3: climb FAIL: no Sky Stair (run with --town)")
		get_tree().quit()
		return
	var p := CharacterBody3D.new()
	p.set_script(PlayerScript)
	p.ink_air = true
	p.third_person = true
	p.scripted = true
	add_child(p)
	var frame := st.global_transform
	p.global_position = frame * Vector3(0.0, -2.0, 8.0)  # 1.6 m before the talkers' first step, over Tsongra's lower level
	p.cam.current = true
	terrain.set_camera(p.cam)
	WorldClock.freeze(11.0)
	_day()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/player/out"))
	current = {"player": p, "stair": st, "frame": frame, "run": 0, "up": true, "t": 0.0, "results": [], "stills": CLIMB_STILLS.duplicate()}
	_climb_reset()
	var feet: Node = p.body.find_child("Feet", true, false) if p.body != null else null
	if feet != null:  # the feet as drawn: read in the skeleton's own update, since the next frame starts from the clip's pose
		(feet.get_skeleton() as Skeleton3D).skeleton_updated.connect(_climb_feet.bind(p, feet))


func _climb_reset() -> void:
	for k in ["t_run", "t_flight", "s_flight", "stalls", "stray", "under", "over"]:
		current[k] = 0.0
	for k in ["s_last", "gap_n", "gap_sum", "gap_max", "top_drop"]:
		current.erase(k)
	current["under"] = 0.0
	current["over"] = 0.0
	current["hist"] = []


func _climb_tick(dt: float) -> void:
	var p: CharacterBody3D = current["player"]
	var st: Node3D = current["stair"]
	var frame: Transform3D = current["frame"]
	var q: Vector3 = frame.affine_inverse() * p.global_position
	var s_along := -q.z
	var up: bool = current["up"]
	current["t"] += dt
	current["t_run"] += dt
	# Steer to a point 2.5 m ahead on this run's line; every second run hurries.
	var lane: float = -0.4 + 0.8 * float(current["run"]) / maxf(climb_runs - 1, 1) if climb_runs > 1 else 0.0
	var hurry: bool = current["run"] % 2 == 1
	var gait := _climb_gait(hurry)
	var aim := frame * Vector3(lane, q.y, -(s_along + (2.5 if up else -2.5)))
	var d := aim - p.global_position
	p.yaw = atan2(-d.x, -d.z)
	p.scripted_move = Vector3(0.0, {"walk": 0.0, "jog": 1.0, "sprint": 2.0}[gait], -1.0)
	# The pace on the flights: time and distance while a ramp is underfoot.
	var on_flight := not (p.stair as Dictionary).is_empty()
	if OS.get_environment("CLIMB_DEBUG") != "" and on_flight != bool(current.get("on_flight", false)) and current["run"] == 0 and up:
		print("s3: climb debug %.2f m: %s (%.2f over the line, t %.1f s)" % [s_along, "flight" if on_flight else "off", q.y - Town.stair_line(st, q), current["t_run"]])
	current["on_flight"] = on_flight
	if on_flight:  # the ground covered along the stair, not the velocity (the slide can lose some of that)
		current["t_flight"] += dt
		current["s_flight"] += absf(s_along - float(current.get("s_last", s_along)))
	current["s_last"] = s_along
	var line := Town.stair_line(st, q)
	if line > -INF and s_along > 0.5 and s_along < 240.0:
		current["under"] = minf(current["under"], q.y - line)
		if q.y - line > current["over"]:
			current["over_at"] = s_along  # where the feet stood highest over the line (the result says so)
		current["over"] = maxf(current["over"], q.y - line)
		current["stray"] = maxf(current["stray"], absf(q.x - lane))
	var hist: Array = current["hist"]
	hist.append(s_along)
	if hist.size() > 90:  # 3 s at 30 frames a second
		if absf(s_along - float(hist[0])) < 0.3:
			current["stalls"] += 1
			print("s3: climb stall at %.1f m along the stair (%.2f over its line, %.2f to the side)" % [s_along, q.y - line, q.x])
			hist.clear()
		else:
			hist.pop_front()
	if climb_stills:
		_climb_still(p, frame, s_along)
		return
	if up and s_along > 241.5:  # on the forecourt past the top: level with the last tread, no pit (sprint 3, step 5)
		current["top_drop"] = maxf(current.get("top_drop", 0.0), 117.8 - q.y)
	var done: bool = s_along >= 245.0 if up else s_along <= -6.5
	if done or current["t_run"] > 1500.0:
		var steps: float = current["s_flight"] / 0.3
		var per_step: float = current["t_flight"] / maxf(steps, 1.0)
		var want := 1.0 / float(PlayerScript.STAIR[gait][0 if up else 1])  # the player's pace (Greg's, 26 Sep 2026; the jog's since 14 Oct 2026, IMP-043)
		var r := {"run": current["run"] + 1, "way": "up" if up else "down", "lane_m": lane, "hurried": hurry, "gait": gait,
				"foot_gap_mean_m": current.get("gap_sum", 0.0) / maxf(current.get("gap_n", 0), 1), "foot_gap_max_m": current.get("gap_max", 0.0), "time_s": current["t_run"], "steps": steps, "s_per_step": per_step,
				"pace_ok": absf(per_step - want) <= want * 0.1, "stalls": current["stalls"], "under_m": current["under"], "over_m": current["over"],
				"stray_m": current["stray"], "arrived": done, "top_drop_m": current.get("top_drop", 0.0), "over_at_m": current.get("over_at", 0.0)}
		current["results"].append(r)
		print("s3: climb %d %s%s on the line %+.2f m: %.0f s, %.0f steps on the flights at %.3f s a step (the player's pace: %.2f), %d stalls, the feet %.2f to %.2f m about the ramps' line, %.2f m off its line, the planted sole %.3f m from its tread on average (%.3f at most), the feet highest over the line at %.1f m%s" % [
			r["run"], r["way"], (" at the " + gait) if gait != "walk" else "", lane, r["time_s"], steps, per_step, want, r["stalls"], r["under_m"], r["over_m"], r["stray_m"], r["foot_gap_mean_m"], r["foot_gap_max_m"], r["over_at_m"], "" if done else " (TIMED OUT)"])
		if not up:
			current["run"] += 1
		current["up"] = not up
		_climb_reset()
		if current["run"] >= climb_runs or not done:
			var ok := true
			for x in current["results"]:
				ok = ok and x["arrived"] and x["pace_ok"] and x["stalls"] == 0 and x["under_m"] > -0.1 and x["over_m"] < 0.35 and x["top_drop_m"] < 0.5
			print("s3: climb %s over %d climbs (S15 on the Sky Stair: no stalls, no falling through, the pace within 10%%)" % ["PASS" if ok else "FAIL", current["results"].size()])
			var f := FileAccess.open(ProjectSettings.globalize_path("res://tests/player/out/s15.json"), FileAccess.WRITE)
			f.store_string(JSON.stringify({"when": Time.get_datetime_string_from_system(), "commit": commit, "pass": ok, "climbs": current["results"]}, " "))
			f.close()
			get_tree().quit()


## A climb's gait: the walk, every second run the jog; CLIMB_GAIT=jog or =sprint every run at that gait (IMP-043: the
## sprint's stills up the stair, two treads a stride; it runs out of breath after about 15 s and jogs on).
func _climb_gait(hurry: bool) -> String:
	var g := OS.get_environment("CLIMB_GAIT")
	return g if g in ["jog", "sprint"] else ("jog" if hurry else "walk")


## --stills: the third-person view at each of CLIMB_STILLS on the way up; "feet" from beside the walker, level with its
## knees (s3's own camera for three frames). After the last, quit.
func _climb_still(p: CharacterBody3D, frame: Transform3D, s_along: float) -> void:
	var todo: Array = current["stills"]
	if current.has("side"):
		current["side"] -= 1
		if current["side"] == 0:
			_save_still(current["side_name"])
			current.erase("side")
			p.cam.current = true
			if todo.is_empty():
				get_tree().quit()
		return
	if todo.is_empty() or s_along < float(todo[0][0]):
		return
	var still: Array = todo.pop_front()
	if still[1] == "feet":
		var right := frame.basis.x
		var up_dir := frame.basis.z * -1.0
		var at := p.global_position + Vector3(0.0, 0.5, 0.0)
		cam.global_position = at + right * 2.4 + up_dir * 0.3 + Vector3(0.0, 0.35, 0.0)
		cam.look_at(at, Vector3.UP)
		cam.current = true
		current["side"] = 3
		current["side_name"] = still[1]
		return
	_save_still(still[1])
	if todo.is_empty():
		get_tree().quit()


func _save_still(name: String) -> void:
	if OS.get_environment("CLIMB_GAIT") != "" and current.has("stair"):  # the climb's stills at another gait beside the walk's
		name = OS.get_environment("CLIMB_GAIT") + "_" + name
	var path := ProjectSettings.globalize_path("res://tests/player/out/%s.png" % (name if name.begins_with("rooftop") else "s15_" + name))
	if DisplayServer.get_name() != "headless":
		var img := get_viewport().get_texture().get_image()
		var sig := _still_sig(img)
		if sig == _last_still_sig:  # a route's moment cannot be waited for: said, to be shot again (ISS-122)
			print("s3: climb still %s: STALE, the same frame as the last still (the window not drawing?)" % path)
		_last_still_sig = sig
		img.save_png(path)
		print("s3: climb still %s" % path)


## A still in small (64 x 36, nearest): two the same are one frame drawn twice, a window that stopped drawing (ISS-122).
func _still_sig(img: Image) -> PackedByteArray:
	var small := img.duplicate() as Image
	small.resize(64, 36, Image.INTERPOLATE_NEAREST)
	return small.get_data()


## The planted foot, as the skeleton draws it this frame: the lower sole's height over the tread under it.
func _climb_feet(p: CharacterBody3D, feet: Node) -> void:
	if current.is_empty() or (p.stair as Dictionary).is_empty():
		return
	var sk: Skeleton3D = feet.get_skeleton()
	var g := INF
	for b in [["foot_l", "ball_l"], ["foot_r", "ball_r"]]:  # a foot rests on the higher tread under its heel and ball
		var ankle: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone(b[0])).origin
		var ball: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone(b[1])).origin
		g = minf(g, ankle.y - feet._ankle_h - maxf(p.tread_at(ankle), p.tread_at(ball)))
	current["gap_n"] = current.get("gap_n", 0) + 1
	current["gap_sum"] = current.get("gap_sum", 0.0) + absf(g)
	current["gap_max"] = maxf(current.get("gap_max", 0.0), absf(g))


# ------------------------------------------------------------------ ladders (spike S15, part 2)
func _start_ladders() -> void:
	var logs := get_tree().get_nodes_in_group("ladders")
	if OS.get_environment("LADDERS_ONLY") != "":  # (only those whose names hold it: LADDERS_ONLY=TOD-01, the Tödé tower's)
		logs = logs.filter(func(l: Node) -> bool: return String(l.name).contains(OS.get_environment("LADDERS_ONLY")))
	if logs.is_empty():
		print("s3: ladder FAIL: no notched logs (run with --town after tools/town/ladders.py)")
		get_tree().quit()
		return
	var p := CharacterBody3D.new()
	p.set_script(PlayerScript)
	p.ink_air = true
	p.third_person = true
	p.scripted = true
	add_child(p)
	p.cam.current = true
	terrain.set_camera(p.cam)
	WorldClock.freeze(11.0)
	logs = logs.filter(func(x): return not String(x.name).begins_with("WAY_"))  # the Rooftop Way's: its route climbs them
	logs.sort_custom(func(a, b): return (a as Node3D).global_position.length() < (b as Node3D).global_position.length())
	if only != "":  # --only=LADDER_H-SHL-017: one log
		logs = logs.filter(func(x): return String(x.name) == only)
	current = {"player": p, "logs": logs, "i": -1, "results": []}
	_next_ladder()


func _next_ladder() -> void:
	current["i"] += 1
	var logs: Array = current["logs"]
	if current["i"] >= logs.size():
		var ok := true
		for r in current["results"]:
			ok = ok and r["up"] and r["down"] and r["pace_ok"]
		print("s3: ladder %s over %d notched logs (S15: up onto the roof and down again, the climb within 10%% of %.2f m/s)" % ["PASS" if ok else "FAIL", logs.size(), PlayerScript.CLIMB])
		var f := FileAccess.open(ProjectSettings.globalize_path("res://tests/player/out/s15_ladders.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify({"when": Time.get_datetime_string_from_system(), "commit": commit, "pass": ok, "ladders": current["results"]}, " "))
		f.close()
		get_tree().quit()
		return
	var l: Node3D = logs[current["i"]]
	var p: CharacterBody3D = current["player"]
	var way: Vector3 = l.get_meta("way")
	var foot: Vector3 = (l.find_child("SOCK_LADDER_1", true, false) as Node3D).global_position
	# Start on ground level with the foot: behind the log, or along its wall (a log in the trench behind a house, whose
	# retaining wall rises 2 m behind it, is reached along the trench).
	var side := Vector3(way.z, 0.0, -way.x)
	var start := foot - way * 2.2
	# behind it first, as far back as 2.2 m with a clear walk to its foot (a start on a yard's wall top, or behind a
	# roof's pier, had left the walker there: IMP-026's ladders stand in shallow yards and on roofs), then along its wall
	var cands := [foot - way * 2.2, foot - way * 1.8, foot - way * 1.4, foot + side * 2.0, foot - side * 2.0, foot - way * 1.2]
	if String(l.name).begins_with("ROOF_") or String(l.name).begins_with("BRIDGE_"):
		cands.push_front(foot - way * 1.4)  # planned with a level run-up of 1.6 m behind (roof_ways.py, bridges.py)
	var look := 3.0  # how far above a candidate the ground is looked for
	if l.has_meta("indoors"):  # a log in a room (the headman's: up through the kitchen's trapdoor and the hatch): just behind
		cands = [foot - way * 0.75, foot - way * 0.6]  # its foot, under the ceiling
		look = 1.6
	for c in cands:
		var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, look, 0), c + Vector3(0, -5.0, 0))
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		var g := maxf(terrain.data.get_height(c), (hit["position"] as Vector3).y if not hit.is_empty() else -INF)
		var behind: bool = (c - foot).dot(way) < -1.0
		var clear := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(c.x, g + 0.5, c.z), foot + Vector3(0, 0.5, 0) - way * 0.3)).is_empty()
		for o in [side * 0.35, -side * 0.35, -way * 0.35]:  # a walker's width round it, clear of a wall's top
			var q2 := PhysicsRayQueryParameters3D.create(c + o + Vector3(0, look, 0), c + o + Vector3(0, -5.0, 0))
			var h2 := get_world_3d().direct_space_state.intersect_ray(q2)
			if not h2.is_empty() and (h2["position"] as Vector3).y > g + 0.3:
				clear = false
		if absf(g - foot.y) < 0.6 and (clear or not behind):
			start = Vector3(c.x, g, c.z)
			break
	p.global_position = start + Vector3(0.0, 0.6, 0.0)
	if OS.get_environment("LADDER_DEBUG") != "":
		print("s3: ladder debug %s: foot %s way %s start %s (terrain there %.2f)" % [l.name, str(foot), str(way), str(start), terrain.data.get_height(start)])
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()
	p.frozen = true  # held until the terrain's collision has been built round the new place (it follows the camera)
	current["log"] = l
	current["way"] = way
	current["phase"] = "settle"
	current["t"] = 0.0
	current["r"] = {"log": String(l.name), "up": false, "down": false, "pace_ok": false}


func _ladder_tick(dt: float) -> void:
	var p: CharacterBody3D = current["player"]
	var l: Node3D = current["log"]
	var way: Vector3 = current["way"]
	var r: Dictionary = current["r"]
	var parapet: Vector3 = l.get_meta("parapet")
	current["t"] += dt
	var t: float = current["t"]
	var face := func(d: Vector3) -> void:
		p.yaw = atan2(-d.x, -d.z)
	if current.has("side_frames"):  # the side view of the climb, three frames after the camera moved
		current["side_frames"] -= 1
		if current["side_frames"] == 0:
			_save_still("ladder_side")
			current.erase("side_frames")
			p.cam.current = true
	if climb_stills and current["phase"] == "approach" and t > 0.6 and not current.has("still_foot"):
		current["still_foot"] = true
		_ladder_still("ladder_foot", p)
	match current["phase"]:
		"settle":  # held a moment for the terrain's collision, then let fall onto the ground
			p.scripted_move = Vector3.ZERO
			if t > 0.5 and p.frozen:
				p.frozen = false
				print("s3: ladder %s: set down at %s, the terrain %.2f under it" % [r["log"], str(p.global_position), p.global_position.y - terrain.data.get_height(p.global_position)])
			if t > 1.3:
				current["phase"] = "approach"
				current["t"] = 0.0
		"approach":  # to just before the log, then into its foot
			var foot: Vector3 = (l.find_child("SOCK_LADDER_1", true, false) as Node3D).global_position
			if OS.get_environment("LADDER_DEBUG") != "" and int(t * 30) % 15 == 0:
				print("s3: ladder debug %s t %.1f at %s, on floor %s" % [l.name, t, str(p.global_position), str(p.is_on_floor())])
			var before := foot - way * 0.6
			var to := Vector3(before.x - p.global_position.x, 0.0, before.z - p.global_position.z)
			face.call(way if to.length() < 0.3 or current.get("facing_log", false) else to)
			if to.length() < 0.3:
				current["facing_log"] = true
			p.scripted_move = Vector3(0.0, 0.0, -1.0)
			if p.ladder != null:
				current.erase("facing_log")
				current["phase"] = "up"
				current["t"] = 0.0
		"up":  # W until over the parapet
			p.scripted_move = Vector3(0.0, 0.0, -1.0)
			if climb_stills and p.ladder != null and not current.has("still_mid") and p.ladder_h > float(p._lad["end"]) * 0.55:
				current["still_mid"] = true
				_ladder_still("ladder_climb", p)
				var side := Vector3(way.z, 0.0, -way.x)
				cam.global_position = p.global_position + side * 2.6 - way * 1.2 + Vector3(0.0, 1.0, 0.0)
				cam.look_at(p.global_position + Vector3(0.0, 0.9, 0.0), Vector3.UP)
				cam.current = true
				current["side_frames"] = 3
			if p.ladder == null:
				r["time_up_s"] = t
				r["rise_m"] = parapet.y - 0.45 - float(r.get("foot_y", 0.0))
				r["up"] = p.global_position.y > parapet.y - 0.8
				current["phase"] = "in"
				current["t"] = 0.0
				if climb_stills:
					_ladder_still("ladder_roof", p)
			else:
				r["foot_y"] = (l.find_child("SOCK_LADDER_1", true, false) as Node3D).global_position.y
				r["end_m"] = float(p._lad["end"])
		"in":  # a metre onto the roof, then back to the edge
			face.call(way if t < 0.8 else -way)
			p.scripted_move = Vector3(0.0, 0.0, -1.0)
			if OS.get_environment("LADDER_DEBUG") != "" and int(t * 30) % 10 == 0:
				var e2: Vector3 = parapet + way * 1.0
				print("s3: ladder debug in t %.1f at %s, parapet %s, edge %s, to_edge %s, on floor %s" % [t, str(p.global_position), str(parapet), str(e2), str(e2 - p.global_position), str(p.is_on_floor())])
			if t > 0.8 and p.ladder != null:
				current["phase"] = "down"
				current["t"] = 0.0
		"down":  # S until off at the foot
			p.scripted_move = Vector3(0.0, 0.0, 1.0)
			if p.ladder == null:
				r["time_down_s"] = t
				r["down"] = absf(p.global_position.y - float(r.get("foot_y", 0.0))) < 0.6
				var want: float = 0.3 + float(r.get("end_m", 0.0)) / PlayerScript.CLIMB + 0.667
				r["pace_ok"] = absf(float(r.get("time_up_s", 0.0)) - want) <= want * 0.1
				print("s3: ladder %s: %s up %.1f m in %.1f s (%.1f s wanted), %s down in %.1f s" % [
					r["log"], "ONTO THE ROOF" if r["up"] else "NOT UP", float(r.get("end_m", 0.0)), float(r.get("time_up_s", 0.0)), want, "back" if r["down"] else "NOT DOWN", t])
				current["results"].append(r)
				_next_ladder()
				return
	if t > 30.0:
		print("s3: ladder %s: stuck in %s at %s" % [r["log"], current["phase"], str(p.global_position)])
		current["results"].append(r)
		_next_ladder()


func _ladder_still(name: String, p: CharacterBody3D) -> void:
	_save_still(name)


# ------------------------------------------------------------------ the townspeople (sprint 4, step 4)
## TownSim's first walkers on the street graph (tools/town/graph.py), drawn in the crowd's tiers (characters/crowd.gd).
func _start_people() -> void:
	if not FileAccess.file_exists(STREETS):
		print("s3: no street graph (tools/town/graph.py); no people")
		return
	var kinds: Array[String] = []  # the crowd's figures: the street graph's (the day's drawn wear several a kind: M2 sprint 10, step 2)
	kinds.assign(PEOPLE_KINDS)
	var graph_kinds = (JSON.parse_string(FileAccess.get_file_as_string(STREETS)) as Dictionary).get("kinds", [])
	if graph_kinds is Array and not (graph_kinds as Array).is_empty():
		kinds.clear()
		for k in graph_kinds:
			if FileAccess.file_exists("res://assets/generated/people/%s_vat.json" % k):
				kinds.append(String(k))
	TownSim.setup_walkers(STREETS, kinds)  # on their days at the clock (sprint 6, step 1)
	crowd = Crowd.new()
	crowd.name = "Crowd"
	add_child(crowd)
	var lo := Town.to_godot(-345.0, -125.0, 2550.0)  # the walkers' ground (tools/town/graph.py GROUND_BOX) and a margin
	var hi := Town.to_godot(280.0, 275.0, 2900.0)
	crowd.setup(TownSim, kinds, AABB(Vector3(lo.x, lo.y, hi.z), Vector3(hi.x - lo.x, hi.y - lo.y, lo.z - hi.z)))
	crowd.set_shadows(true, true)
	named = Named.new()  # the named eight among them (sprint 6, step 3)
	named.name = "Named"
	add_child(named)
	named.setup(TownSim, crowd)
	caravan = Caravan.new()  # the caravan CV-02 up the north ramp to Dechen-tsang (sprint 6, step 5)
	caravan.name = "Caravan"
	add_child(caravan)
	if not caravan.setup(TownSim, named, JSON.parse_string(FileAccess.get_file_as_string(STREETS))):
		caravan.queue_free()
		caravan = null
	var on_ground := func(x: float, z: float) -> float: return terrain.data.get_height(Vector3(x, 0.0, z))
	var beasts := CampAnimals.new()  # the camp's other beasts: CV-01's 60 yak, the picket line, the corral (M2 sprint 9, step 3)
	beasts.name = "CampAnimals"
	add_child(beasts)
	print("camp animals: %s" % str(beasts.build(on_ground)))
	if caravan != null:  # the rest of CV-02 behind the ten, down the Caravan Ramp to the camp (M2 sprint 9, step 2)
		herd = Herd.new()
		herd.name = "Herd"
		add_child(herd)
		if herd.setup(caravan, on_ground):
			var camp := get_node_or_null("Town/Camp")
			if camp != null:
				camp.set("cv02_halt", herd.get("halt_minute"))
			print("herd: CV-02's %d yak behind the ten from %02d:%02d, the lead halted at the camp at %02d:%02d, the last at %02d:%02d" % [
					Herd.N, int(caravan.get("start")) / 60, int(caravan.get("start")) % 60, int(herd.get("halt_minute")) / 60 % 24,
					int(herd.get("halt_minute")) % 60, int(herd.get("done_minute")) / 60 % 24, int(herd.get("done_minute")) % 60])
		else:
			herd.queue_free()
			herd = null
	TownSim.step(0.0, cam.global_position)


## The index in `pts` ([[x, y, z]...], the town grid) nearest (x, y).
static func _nearest_k(pts: Array, x: float, y: float) -> int:
	var best := 0
	for k in pts.size():
		if Vector2(float(pts[k][0]) - x, float(pts[k][1]) - y).length() < Vector2(float(pts[best][0]) - x, float(pts[best][1]) - y).length():
			best = k
	return best


## Spike S5 for twenty (M1 sprint 4, step 4): the walkers on their days for half an hour of real time, the clock at 6:1 from
## 14:00 to 17:00 (sprint 6, step 1; headless at a fixed 30 frames a second it runs faster), the eye at Tsongra. Each second, every walker out of doors is held against
## the game's ground (a ray down from a metre over it: the kit's hulls, the flights' ramps, the terrain near the eye; the
## terrain's heights elsewhere) and, in the Mani
## Lane, against the wall's way (east on its north side, west on its south); the great wheel's turns are counted. Pass:
## TownSim and the crowd under chapter 11's 2.5 ms together, feet within 0.35 m of the ground at the 95th percentile and
## 0.8 m at the 99.9th (the worst is reported: a step between two levels, which the terrain's 1 m grid smears into a
## facet, leaves a walker level with the upper one up to a metre over the dip), no one the wrong way round the wall, and
## the wheel turned by those who went to it.
func _start_walkers() -> void:
	if crowd == null:
		print("s3: walkers FAIL: no street graph or no town (run with --town)")
		get_tree().quit()
		return
	WorldClock.freeze(11.0)
	_day()
	var st: Array = STATIONS.filter(func(x): return x[0] == "slice_tsongra_n")[0]
	_place(st)
	var wall := get_node_or_null("Town/SHL-09")
	var wheel := get_node_or_null("Town/SHL-08_wheel")
	current = {"t": 0.0, "frames": 0, "sim_us": 0, "crowd_us": 0, "worst_us": 0, "next": 1.0, "errs": [],
			"wrong": 0.0, "wall": wall, "wheel": wheel, "turns0": float(wheel.get("turns")) if wheel else 0.0, "wheel_visits": 0,
			"seen": {}}


func _walkers_tick(dt: float) -> void:
	current["t"] += dt
	WorldClock.minute += dt * WorldClock.RATE_PLAY  # their days run on the clock: three hours from 14:00 in the spike's 1,800 s
	current["frames"] += 1
	current["sim_us"] += TownSim.last_us
	current["crowd_us"] += crowd.last_us
	current["named_us"] = int(current.get("named_us", 0)) + (named.last_us if named != null else 0)
	current["worst_us"] = maxi(current["worst_us"], TownSim.last_us + crowd.last_us)
	if OS.get_environment("WALKERS_SPIKES") != "" and TownSim.last_us + crowd.last_us > 20000:  # a frame over 20 ms: whose
		print("s3: walkers: a frame of %.1f ms at %.0f s, %s (TownSim %.1f ms, the crowd %.1f ms)" % [(TownSim.last_us + crowd.last_us) / 1000.0, current["t"],
				Calendar.clock(WorldClock.minute) if Calendar.has_method("clock") else str(WorldClock.minute), TownSim.last_us / 1000.0, crowd.last_us / 1000.0])
	var wall: Node3D = current["wall"]
	var wheel: Node3D = current["wheel"]
	for i in TownSim.count:
		if TownSim.state[i] != 0:
			continue
		if wall != null:  # the mani wall kept on the right (world/mani_wall.gd's test, for a walker)
			var a: Vector3 = wall.get("a")
			var b: Vector3 = wall.get("b")
			var u := Vector2(b.x - a.x, -(b.z - a.z))
			var length := u.length()
			u /= length
			var ap := Vector2(TownSim.pos[i].x - a.x, -(TownSim.pos[i].z - a.z))
			var along := ap.dot(u)
			var side := u.x * ap.y - u.y * ap.x
			var going := Vector2(TownSim.vel[i].x, -TownSim.vel[i].z).dot(u)
			if along > 0.0 and along < length and absf(side) < 4.0 and absf(going) > 0.2 and signf(going) != signf(side):
				current["wrong"] += dt
				if OS.get_environment("WALKERS_DEBUG") != "":
					print("s3: walkers: %s (%s) the wrong way round the mani wall at town (%.1f, %.1f) at %s, %.2f m off its line" % [TownSim.key[i], TownSim.who[i], TownSim.pos[i].x, -TownSim.pos[i].z, Calendar.clock(WorldClock.minute), side])
		if wheel != null and Vector2(TownSim.pos[i].x - wheel.global_position.x, TownSim.pos[i].z - wheel.global_position.z).length() < 2.4:
			current["seen"][i] = true
	if current["t"] >= current["next"]:
		current["next"] += 1.0
		var space := get_world_3d().direct_space_state
		for i in TownSim.count:
			if TownSim.state[i] == 2:
				continue
			var p: Vector3 = TownSim.pos[i]
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0.0, 1.0, 0.0), p - Vector3(0.0, 2.0, 0.0)))
			# the kit's hulls and the flights' ramps where the ray finds them; else the terrain's own heights (its collision
			# is built only round the camera, DYNAMIC_GAME)
			var h: float = (hit["position"] as Vector3).y if not hit.is_empty() else terrain.data.get_height(p)
			var e := 3.0 if is_nan(h) else absf(p.y - h)
			(current["errs"] as Array).append(e)  # a plain Array: a packed one read from the Dictionary is a copy
			if e > 0.8 and OS.get_environment("WALKERS_DEBUG") != "":
				print("s3: walkers: walker %d %.2f m off the ground at town (%.1f, %.1f), state %d" % [i, e, p.x, -p.z, TownSim.state[i]])
	if current["t"] < 1800.0:
		return
	var errs := PackedFloat32Array(current["errs"])
	errs.sort()
	var p95 := errs[int(errs.size() * 0.95)]
	var p999 := errs[int(errs.size() * 0.999)]
	var worst := errs[errs.size() - 1]
	var n: int = current["frames"]
	var ms: float = (current["sim_us"] + current["crowd_us"]) / float(n) / 1000.0
	var turned := float(wheel.get("turns")) - float(current["turns0"]) if wheel else 0.0
	var visits: int = (current["seen"] as Dictionary).size()
	var ok: bool = ms < 2.5 and p95 < 0.35 and p999 < 0.8 and float(current["wrong"]) == 0.0 and (visits == 0 or turned > 0.5)
	print("s3: walkers: the named eight's figures %.3f ms a frame (sprint 6, step 3; outside the budget: the engine animates them)" % [int(current.get("named_us", 0)) / float(n) / 1000.0])
	print("s3: walkers %s: %d walkers for %.0f s of their time; TownSim %.3f ms and the crowd %.3f ms a frame (worst %.2f ms); feet off the ground %.2f m at the 95th percentile, %.2f m at the 99.9th, %.2f m at worst, over %d samples; %.1f s the wrong way round the mani wall; %d went round the great wheel, which turned %.1f times" % [
			"PASS" if ok else "FAIL", TownSim.count, current["t"], current["sim_us"] / float(n) / 1000.0, current["crowd_us"] / float(n) / 1000.0,
			current["worst_us"] / 1000.0, p95, p999, worst, errs.size(), current["wrong"], visits, turned])
	get_tree().quit()


# ------------------------------------------------------------------ Nyima follows the player (sprint 6, step 3)
## --follow: chapter 05, 9.6's children who follow, as a new player meets Nyima on Tsongra's upper level at 16:05 (his
## day has him there from 16:00, 4.2): the player (third person, scripted) walks 25 m east past him; a fixed camera on
## the upper level's south edge watches, and three stills are taken as they cross it (tests/terrain/out/s3_follow_*.png);
## then the player stands, and the log says whether he fell in, how far behind he kept, and whether he walked back to
## his place. The day is held at 16:05 (the clock runs at no rate), the animation clock runs.
const FOLLOW_FROM := Vector2(-8.0, 6.5)
const FOLLOW_CAM := [4.0, 0.3, 1.7, 355.0, -6.0]  # town x, y, height, bearing, pitch
const FOLLOW_STILLS := [1.5, 5.0, 9.0]  # the player's town x at each still


## M2's acceptance 4 in a window (chapter 12, 4.3; M2 sprint 10, step 5): at 17:30 with the full crowd, everyone's drawn
## place a quarter of an hour on noted; then saved at 17:30, the evening played on to 22:30, loaded, and a quarter of an
## hour on: every walker (TownSim) and every named figure as drawn (characters/named.gd) within a metre of where it was.
## Stills of Tsongra before and after: s3_trip_before.png, s3_trip_after.png.
func _start_trip() -> void:
	if named == null:
		print("s3: save trip FAIL: no named (run with --town --people)")
		get_tree().quit()
		return
	var m := _minute_at(17.5)
	WorldClock.freeze(20.0, m)
	_day()
	day.update(m)
	WorldClock.frozen = false
	WorldClock.rate = 0.0  # the clock set by hand, phase by phase
	cam.current = true
	cam.global_position = Vector3(2.0, _ground(2.0, -13.0) + 1.6, 13.0)
	cam.rotation = Vector3(deg_to_rad(3.0), -deg_to_rad(356.0), 0.0)
	current = {"t": 0.0, "phase": 0, "at": 0.0, "m": m}
	WorldClock.minute = m + 15.0


func _trip_places() -> Array:
	var out := []
	for i in TownSim.count:
		out.append(TownSim.pos[i])
	for i in named.people:  # a figure not shown (indoors, or not yet drawn) is no place: null
		var r := named.people[i]["root"] as Node3D
		out.append(r.global_position if r.is_visible_in_tree() else null)
	return out


func _trip_tick(dt: float) -> void:
	current["t"] += dt
	var t: float = current["t"]
	var m: float = current["m"]
	if t - float(current["at"]) < 2.0:  # each phase settled two seconds (the named sit, rise, turn)
		return
	current["at"] = t
	match int(current["phase"]):
		0:  # the uninterrupted day at 17:45
			current["ref"] = _trip_places()
			_save_still("trip_before")
			WorldClock.minute = m
		1:
			print("s3: save trip: saved at %s: %s" % [Calendar.clock(WorldClock.minute), Save.save_game("trip")])
			WorldClock.minute = m + 300.0
		2:
			print("s3: save trip: the evening played on to %s" % Calendar.clock(WorldClock.minute))
			print("s3: save trip: loaded: %s, the clock %s" % [Save.load_game("trip"), Calendar.clock(WorldClock.minute)])
			WorldClock.minute += 15.0
		3:
			var ref: Array = current["ref"]
			var now := _trip_places()
			var worst := 0.0
			var off := 0
			var named_keys: Array = named.people.keys()
			for k in mini(ref.size(), now.size()):
				if ref[k] == null or now[k] == null:
					continue
				var dd := (now[k] as Vector3).distance_to(ref[k])
				worst = maxf(worst, dd)
				off += int(dd > 1.0)
				if dd > 1.0:  # who, for the record
					var w: int = k if k < TownSim.count else int(named_keys[k - TownSim.count])
					print("s3: save trip: %s %s (%s) %.2f m off: from (%.1f, %.1f) to (%.1f, %.1f)" % ["walker" if k < TownSim.count else "named figure",
							TownSim.who[w], TownSim.key[w], dd, (ref[k] as Vector3).x, -(ref[k] as Vector3).z, (now[k] as Vector3).x, -(now[k] as Vector3).z])
			_save_still("trip_after")
			var ok := ref.size() == now.size() and off == 0 and TownSim.count > 200
			print("s3: save trip %s: %d walkers and %d named figures, saved at 17:30, loaded after the evening: %d more than a metre from where the day says, the worst %.2f m" % [
					"PASS" if ok else "FAIL", TownSim.count, named.people.size(), off, worst])
			get_tree().quit()
			return
	current["phase"] = int(current["phase"]) + 1


func _start_follow() -> void:
	if named == null:
		print("s3: follow FAIL: no named eight (run with --town --people)")
		get_tree().quit()
		return
	var m := _minute_at(16.08)
	WorldClock.freeze(20.0, m)
	_day()
	day.update(m)
	WorldClock.frozen = false
	WorldClock.rate = 0.0
	TownSim.step(0.0, cam.global_position)
	var p := CharacterBody3D.new()
	p.set_script(PlayerScript)
	p.name = "Player"
	p.ink_air = true
	p.third_person = true
	add_child(p)
	p.global_position = Vector3(FOLLOW_FROM.x, _ground(FOLLOW_FROM.x, FOLLOW_FROM.y) + 0.05, -FOLLOW_FROM.y)
	p.yaw = -PI / 2.0  # facing east (the player looks along -Z turned by its yaw)
	p.facing = p.yaw
	p.scripted = true
	p.reset_physics_interpolation()
	terrain.set_camera(p.cam)
	cam.current = true
	cam.global_position = Vector3(FOLLOW_CAM[0], _ground(FOLLOW_CAM[0], FOLLOW_CAM[1]) + FOLLOW_CAM[2], -FOLLOW_CAM[1])
	cam.rotation = Vector3(deg_to_rad(FOLLOW_CAM[4]), -deg_to_rad(FOLLOW_CAM[3]), 0.0)
	named.player = p
	current = {"player": p, "t": 0.0, "shot": 0, "gaps": [], "fell_in": -1.0, "start": TownSim.pos[named.nyima]}


func _follow_tick(dt: float) -> void:
	current["t"] += dt
	var p: CharacterBody3D = current["player"]
	var t: float = current["t"]
	p.scripted_move = Vector3(0.0, 0.0, -1.0) if t > 1.5 and -p.global_position.z < 1e9 and p.global_position.x < FOLLOW_FROM.x + 25.0 else Vector3.ZERO
	if named.follows > 0 and float(current["fell_in"]) < 0.0:
		current["fell_in"] = t
	if not named.follow.is_empty() and String(named.follow["mode"]) == "trail":
		(current["gaps"] as Array).append(p.global_position.distance_to(named.follow["pos"]))
	var k: int = current["shot"]
	if k < FOLLOW_STILLS.size() and p.global_position.x >= float(FOLLOW_STILLS[k]):
		var path := ProjectSettings.globalize_path(OUT).path_join("s3_follow_%d.png" % (k + 1))
		if DisplayServer.get_name() != "headless":
			get_viewport().get_texture().get_image().save_png(path)
		print("s3: follow still %s: the player at town x %.1f, Nyima %s" % [path, p.global_position.x, "following" if not named.follow.is_empty() else "at his place"])
		current["shot"] = k + 1
	if t < 75.0:
		return
	var gaps := PackedFloat32Array(current["gaps"])
	gaps.sort()
	var back: bool = named.follow.is_empty() and (named.people[named.nyima]["root"] as Node3D).position.distance_to(current["start"]) < 0.1
	var ok: bool = named.follows == 1 and gaps.size() > 30 and gaps[gaps.size() / 2] > 2.0 and gaps[gaps.size() / 2] < 5.0 and back
	print("s3: follow %s: Nyima fell in %.1f s after the player set off, kept %.1f m behind (median; %.1f to %.1f), scattered %d times, and was %s after %.0f s" % [
			"PASS" if ok else "FAIL", float(current["fell_in"]) - 1.5, gaps[gaps.size() / 2] if gaps.size() > 0 else -1.0,
			gaps[0] if gaps.size() > 0 else -1.0, gaps[gaps.size() - 1] if gaps.size() > 0 else -1.0, named.scatters,
			"back at his place" if back else "not back", t])
	WorldClock.rate = WorldClock.RATE_PLAY
	get_tree().quit()


# ------------------------------------------------------------------ the performance route PT-slice (sprint 4, step 7)
## PT-slice (plan chapter 12, 4.2; chapter 11, 19.7): the slice as a player would take it, the Yak Gate to Tsongra and
## up the Sky Stair to the Mani Lhakhang's forecourt (the street graph's routes), then the Rooftop Way from Dechen-tsang's
## guest yard to V-28's roof (tools/town/rooftop.py) and a turn there, at 17:05 with the sang's smoke and the
## townspeople walking. The eye 1.6 m over the way, looking 4 m ahead, moves at a fixed 1.4 m/s of a 30 fps frame
## (so an uncapped pass has the same frames), and every frame is logged (Telemetry), but for a second after the cut
## between the stair and the Way. The pass: 30 fps held and a 1% low of 25 (the 99th percentile frame 40 ms or under),
## the summary in perf/history.csv. tools/perf/pt_slice.sh runs it capped and uncapped.
const PT_STEP := 1.4 / 30.0  ## metres a frame
const PT_TURN := 240  ## frames of the turn on V-28's roof


func _pt_path() -> Array:
	var segs: Array = []
	var routes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STREETS))["routes"]
	for name in ["yak_gate>tsongra", "tsongra>lhakhang"]:
		var p: Array = routes.get(name, {}).get("p", [])
		var pts := PackedVector3Array()
		for k in range(0, p.size(), 3):
			pts.append(Town.to_godot(p[k], p[k + 1], p[k + 2]))
		if segs.is_empty() or pts.is_empty():
			segs.append(pts)
		else:
			(segs[0] as PackedVector3Array).append_array(pts)  # the two walk on from each other at Tsongra
	segs.append(PackedVector3Array(_rooftop_points()[0]))
	var out: Array = []  # [points every PT_STEP along each segment]
	for pts in segs:
		var dense := PackedVector3Array()
		for k in (pts as PackedVector3Array).size() - 1:
			var a: Vector3 = pts[k]
			var b: Vector3 = pts[k + 1]
			var n := maxi(1, int(ceil(a.distance_to(b) / PT_STEP)))
			for j in n:
				dense.append(a.lerp(b, float(j) / n))
		if not dense.is_empty():
			out.append(dense)
	return out


func _start_pt_slice() -> void:
	if crowd == null or run_dir == "":
		print("s3: pt-slice FAIL: needs --town, the street graph and --run=")
		get_tree().quit()
		return
	WorldClock.freeze(20.0, _minute_at(17.0 + 5.0 / 60.0))
	_day()
	WorldClock.frozen = true
	var path := _pt_path()
	var total := 0
	for seg in path:
		total += (seg as PackedVector3Array).size()
	print("s3: pt-slice: %d segments, %d frames of walking (%.0f m) and %d of the turn" % [path.size(), total, total * PT_STEP, PT_TURN])
	current = {"station": "pt-slice", "cond": "all", "path": path, "seg": 0, "i": 0, "hold": 60, "turn": -1, "rows": [],
			"name": "s3_pt-slice%s_%s" % [variant, "uncapped" if uncapped else "capped"], "yaw": 0.0, "pitch": 0.0, "tier": "QT-BAL"}
	# measured on QT-BAL whatever the power source (on battery the policy would take QT-BATT: no volumetric fog, no SSAO,
	# smaller shadows; the first runs, 26 Sep 2026, were so); heat may still drop the tier, and is logged
	Quality.forced = {"battery": "0", "lowpower": "0"}
	Quality.set_tier("QT-BAL")
	Quality.start_thermal()


func _pt_tick() -> void:
	var path: Array = current["path"]
	current["tier"] = Quality.tier
	if current["turn"] >= 0:  # on V-28's roof: a full turn, the town and the valley all round
		current["turn"] += 1
		cam.rotation = Vector3(deg_to_rad(-8.0), float(current["yaw"]) + TAU * current["turn"] / PT_TURN, 0.0)
		current["rows"].append(Telemetry.sample(0.0))
		if current["turn"] >= PT_TURN:
			Telemetry.stop_csv()
			var line := _summary()
			var fps: float = 1000.0 / maxf(float(line["mean_ms"]), 0.001)
			var ok: bool = float(line["p99_ms"]) <= 40.0 and (uncapped or fps >= 29.0)
			print("s3: pt-slice %s (%s, %s at the end, thermal %s): %d frames, %.1f fps on average, the 99th percentile %.1f ms (40 for a 1%% low of 25 fps), the worst %.1f ms" % [
					"PASS" if ok else "FAIL", "uncapped" if uncapped else "capped at 30", Quality.tier, Telemetry.thermal, line["frames"], fps, line["p99_ms"], line["worst_ms"]])
			Quality.stop_thermal()
			get_tree().quit()
		return
	var seg: PackedVector3Array = path[current["seg"]]
	var i: int = current["i"]
	var p := seg[i]
	var ahead := seg[mini(i + int(4.0 / PT_STEP), seg.size() - 1)]
	var d := ahead - p
	if Vector2(d.x, d.z).length() > 0.3:
		current["yaw"] = lerp_angle(float(current["yaw"]), atan2(-d.x, -d.z), 0.08)
		current["pitch"] = lerpf(float(current["pitch"]), clampf(atan2(d.y, Vector2(d.x, d.z).length()), deg_to_rad(-30.0), deg_to_rad(25.0)) - deg_to_rad(4.0), 0.08)
	cam.global_position = p + Vector3(0.0, 1.6, 0.0)
	cam.rotation = Vector3(float(current["pitch"]), float(current["yaw"]), 0.0)
	if current["hold"] > 0:  # a new place: a second for the terrain and the town round it, not logged
		current["hold"] -= 1
		if current["hold"] == 0 and not current.has("logging"):
			current["logging"] = true
			Telemetry.tag = current["name"]
			Telemetry.start_csv(run_dir.path_join(current["name"] + ".csv"))
		return
	if current.has("logging"):
		current["rows"].append(Telemetry.sample(0.0))
	current["i"] = i + 1
	if current["i"] >= seg.size():
		current["seg"] += 1
		current["i"] = 0
		if current["seg"] >= path.size():
			current["turn"] = 0
		else:
			current["hold"] = 30  # the cut to the Rooftop Way: the eye jumps across the town


# ------------------------------------------------------------------ routes through buildings (kit step K7)
## [building id, [waypoints in its Blender frame (x, y, z over its pad)]]: dechen, Dechen-tsang's gate to its garden.
const ROUTES := {"tsongra": ["SHL-01_steps", [Vector3(0.0, -7.0, 0.0), Vector3(0.0, -0.8, 0.0), Vector3(0.0, 5.2, 2.0), Vector3(-6.0, 9.0, 2.0)]],
		"dechen": ["SHL-04", [Vector3(0.0, -28.0, 0.0), Vector3(0.0, -21.5, 0.0), Vector3(0.0, -6.0, 0.0), Vector3(0.0, 0.5, 0.0),
		Vector3(0.0, 5.5, 1.0), Vector3(5.0, 13.5, 1.0), Vector3(11.8, 16.2, 1.0), Vector3(17.5, 16.2, 2.0), Vector3(20.0, 10.0, 2.0)]],
		# sprint 7, step 2: over the gate's threshold and into each room and out, over each sill both ways (nine steps over)
		"rooms": ["SHL-04", [Vector3(0.0, -28.0, 0.0), Vector3(0.0, -21.5, 0.0), Vector3(0.0, -6.0, 0.0), Vector3(0.0, 0.5, 0.0),
		Vector3(0.0, 5.5, 1.0), Vector3(-7.6, 5.01, 1.0), Vector3(-12.0, 5.01, 1.15), Vector3(-13.1, 5.31, 1.15), Vector3(-7.6, 5.01, 1.0),
		Vector3(7.6, 5.32, 1.0), Vector3(12.0, 5.32, 1.15), Vector3(7.6, 5.32, 1.0),
		Vector3(7.6, 13.38, 1.0), Vector3(11.8, 13.68, 1.15), Vector3(7.6, 13.38, 1.0),
		Vector3(-9.0, 15.4, 1.0), Vector3(-9.0, 18.7, 1.15), Vector3(-9.0, 15.4, 1.0), Vector3(0.0, 10.0, 1.0)]],
		# M2 sprint 8, step 1: Yard 3: from the gate up through the guest yard into the garden, up the chapel's stone stair
		# and over its sill into the chapel and out, then up Dolkar's timber stair, along her gallery and over her sill into
		# her reception room and out, and down into the garden again (kit/trading.py _chapel, _dolkar)
		"yard3": ["SHL-04", [Vector3(0.0, -28.0, 0.0), Vector3(0.0, -21.5, 0.0), Vector3(0.0, -6.0, 0.0), Vector3(0.0, 0.5, 0.0),
		Vector3(0.0, 5.5, 1.0), Vector3(5.0, 13.5, 1.0), Vector3(11.8, 16.2, 1.0), Vector3(15.6, 16.2, 2.0), Vector3(19.0, 14.6, 2.0),
		Vector3(20.85, 14.6, 2.0), Vector3(20.85, 19.5, 5.0), Vector3(22.6, 19.5, 5.0), Vector3(24.8, 19.5, 5.0), Vector3(22.6, 19.5, 5.0),
		Vector3(20.85, 19.5, 5.0), Vector3(20.85, 14.6, 2.0), Vector3(18.4, 11.5, 2.0), Vector3(18.3, 8.95, 2.0), Vector3(22.8, 8.95, 4.94),
		Vector3(24.1, 8.95, 4.94), Vector3(24.1, 7.2, 4.94), Vector3(25.6, 5.2, 4.94), Vector3(24.1, 7.2, 4.94), Vector3(24.1, 8.95, 4.94),
		Vector3(22.8, 8.95, 4.94), Vector3(18.3, 8.95, 2.0), Vector3(20.0, 12.5, 2.0)]],
		# IMP-023 (1): along H-SHL-007's yard through the washing on its line (world/laundry.gd), which parts round the walker
		"laundry": ["H-SHL-007", [Vector3(-7.0, -5.3, 0.0), Vector3(-3.5, -5.6, 0.0), Vector3(-1.0, -5.6, 0.0), Vector3(1.5, -5.6, 0.0), Vector3(5.0, -5.4, 0.0)]],
		# IMP-025: into the guest room to its chest, where the route opens it and tries the clothes on (_wardrobe_tick)
		"wardrobe": ["SHL-04", [Vector3(0.0, -28.0, 0.0), Vector3(0.0, -21.5, 0.0), Vector3(0.0, -6.0, 0.0), Vector3(0.0, 0.5, 0.0),
		Vector3(0.0, 5.5, 1.0), Vector3(7.6, 13.38, 1.0), Vector3(11.8, 13.68, 1.15), Vector3(12.6, 13.68, 1.15)]],
		# IMP-022: along the guest yard's west gallery, south to north, where the camera's framing hint swings it side on
		# (data/camera_hints.json; H turns it off in play)
		"gallery": ["SHL-04", [Vector3(0.0, -28.0, 0.0), Vector3(0.0, -21.5, 0.0), Vector3(0.0, -6.0, 0.0), Vector3(0.0, 0.5, 0.0),
		Vector3(0.0, 5.5, 1.0), Vector3(-7.6, 4.0, 1.0), Vector3(-9.35, 4.0, 1.0), Vector3(-9.35, 8.0, 1.0), Vector3(-9.35, 12.0, 1.0),
		Vector3(-9.35, 16.0, 1.0), Vector3(-6.0, 16.0, 1.0), Vector3(0.0, 12.0, 1.0)]],
		# sprint 7, step 4: into the Tibetan room, round the brazier and the guest's low table to the guest bench (its
		# SEAT 4); there the route sits and takes tea (_tea_tick)
		"tea": ["SHL-04", [Vector3(0.0, -28.0, 0.0), Vector3(0.0, -21.5, 0.0), Vector3(0.0, -6.0, 0.0), Vector3(0.0, 0.5, 0.0),
		Vector3(0.0, 5.5, 1.0), Vector3(-7.6, 5.01, 1.0), Vector3(-12.0, 5.01, 1.15), Vector3(-11.2, 6.41, 1.15),
		Vector3(-11.2, 7.91, 1.15), Vector3(-12.8, 7.71, 1.15), Vector3(-12.75, 8.39, 1.15)]],
		# sprint 8, step 7: a town house to enter, H-SHL-007: along the lane, up its outside stair, over the sill into its
		# kitchen, round it past the pillars, and out and down again (its frame: kit/houses.py town_house(interior=True))
		"house": ["H-SHL-007", [Vector3(3.2, -4.74, 0.0), Vector3(1.9, -4.74, 0.0), Vector3(-0.9, -4.74, 2.3),
		Vector3(-1.17, -4.6, 2.3), Vector3(-1.17, -3.0, 2.45), Vector3(-0.5, 1.5, 2.45), Vector3(1.5, 1.0, 2.45),
		Vector3(-1.17, -3.0, 2.45), Vector3(-1.17, -4.6, 2.3), Vector3(-0.9, -4.74, 2.3), Vector3(1.9, -4.74, 0.0), Vector3(3.2, -4.74, 0.0)]],
		# ISS-105: tea in a house to enter: in at H-SHL-007's door as above, round the near low table to the end of the bench
		# (its SEAT 3), where the route sits and the grandmother pours from her seat beside it (_tea_tick)
		"house_tea": ["H-SHL-007", [Vector3(3.2, -4.74, 0.0), Vector3(1.9, -4.74, 0.0), Vector3(-0.9, -4.74, 2.3),
		Vector3(-1.17, -4.6, 2.3), Vector3(-1.17, -3.0, 2.45), Vector3(-2.07, 1.79, 2.45), Vector3(-2.79, 1.71, 2.45)]],
		# and in the other two: up H-SHL-054's stair (it falls west) to the middle of its bench, the mother beside it; up
		# H-SHL-004's to the middle of its, the man of the house beside it
		"house_tea_054": ["H-SHL-054", [Vector3(-3.46, -4.34, 0.0), Vector3(-2.16, -4.34, 0.0), Vector3(0.36, -4.34, 2.3),
		Vector3(0.63, -4.2, 2.3), Vector3(0.63, -2.61, 2.45), Vector3(3.0, -0.1, 2.45)]],
		"house_tea_004": ["H-SHL-004", [Vector3(3.93, -4.42, 0.0), Vector3(2.63, -4.42, 0.0), Vector3(-0.45, -4.42, 2.3),
		Vector3(-0.72, -4.28, 2.3), Vector3(-0.72, -2.69, 2.45), Vector3(3.0, -0.1, 2.45)]],
		# ISS-105: the poor family's one room on the west edge, H-SHL-142 (chapter 04, 4.2): up its yard to the door, in
		# under the low lintel, past the log to the hearth's far side, never over its stones, and out again (its frame:
		# kit/houses.py poor_house(interior=True), v2; the room's floor 6 cm over the house's foot)
		"house_142": ["H-SHL-142", [Vector3(-0.8, -5.2, 0.0), Vector3(-0.8, -3.0, 0.0), Vector3(-0.8, -1.95, 0.0),
		Vector3(-0.81, -1.06, 0.06), Vector3(-0.06, -0.16, 0.06), Vector3(0.89, -0.26, 0.06), Vector3(-0.81, -1.06, 0.06),
		Vector3(-0.8, -1.95, 0.0), Vector3(-0.8, -3.0, 0.0), Vector3(-0.8, -5.2, 0.0)]],
		# M2 sprint 1, step 5: mission 1, the letter (chapter 14, 4.1): along Netsang Lam to Dechen-tsang's gateway at
		# 16:30, where Achak Dolkar meets the caravan, and the letter handed over there (_letter_tick); or at 17:42 through
		# the gate, the yard and the passage into the Tibetan room, where she counts the day alone, the door shut first
		"letter_open": ["SHL-04", [Vector3(0.0, -30.0, 0.0), Vector3(0.0, -25.6, 0.0)]],
		# M2 sprint 2: the chang house SHL-24 (the B2 to enter's v2, as H-SHL-054): up its stair, in, round the pillars to
		# the guest's place by the back bench's end; there the chang poured (_tea_tick), or mission 2 (_chang_tick)
		"chang_tea": ["SHL-24", [Vector3(-3.46, -4.34, 0.0), Vector3(-2.16, -4.34, 0.0), Vector3(0.36, -4.34, 2.3),
		Vector3(0.63, -4.2, 2.3), Vector3(0.63, -2.61, 2.45), Vector3(-1.5, 0.5, 2.45), Vector3(-2.4, 1.5, 2.45)]],
		"chang_talk": ["SHL-24", [Vector3(-3.46, -4.34, 0.0), Vector3(-2.16, -4.34, 0.0), Vector3(0.36, -4.34, 2.3),
		Vector3(0.63, -4.2, 2.3), Vector3(0.63, -2.61, 2.45), Vector3(-1.5, 0.5, 2.45)]],
		"letter_private": ["SHL-04", [Vector3(0.0, -28.0, 0.0), Vector3(0.0, -21.5, 0.0), Vector3(0.0, -6.0, 0.0), Vector3(0.0, 0.5, 0.0),
		Vector3(0.0, 5.5, 1.0), Vector3(-7.6, 5.01, 1.0), Vector3(-12.0, 5.01, 1.15), Vector3(-11.2, 6.41, 1.15), Vector3(-11.2, 7.91, 1.15)]],
		# and its tea: in at the door, round the log's door end to the guest's sheepskin behind it, where the route sits
		# cross-legged facing the fire (ISS-088) and the grandmother pours from the copper ladle at the log's end (_tea_tick)
		"house_tea_142": ["H-SHL-142", [Vector3(-0.8, -5.2, 0.0), Vector3(-0.8, -3.0, 0.0), Vector3(-0.8, -1.95, 0.0),
		Vector3(-0.51, -1.06, 0.06), Vector3(1.69, -0.56, 0.06), Vector3(1.52, 0.45, 0.06)]],
		# sprint 7, step 5: the offers carried between the counting rooms, three times there and back: E by the agent (in
		# the Tibetan room) and by Yang (at his ledger), at the points marked in ROUTE_MARKS
		"message": ["SHL-04", [Vector3(0.0, -28.0, 0.0), Vector3(0.0, -21.5, 0.0), Vector3(0.0, -6.0, 0.0), Vector3(0.0, 0.5, 0.0),
		Vector3(0.0, 5.5, 1.0), Vector3(-7.6, 5.01, 1.0), Vector3(-12.0, 5.01, 1.15), Vector3(-13.0, 6.31, 1.15), Vector3(-12.0, 5.01, 1.15), Vector3(-7.6, 5.01, 1.0), Vector3(7.6, 5.32, 1.0), Vector3(12.0, 5.32, 1.15), Vector3(12.1, 8.52, 1.15), Vector3(12.0, 5.32, 1.15), Vector3(7.6, 5.32, 1.0), Vector3(-7.6, 5.01, 1.0), Vector3(-12.0, 5.01, 1.15), Vector3(-13.0, 6.31, 1.15), Vector3(-12.0, 5.01, 1.15), Vector3(-7.6, 5.01, 1.0), Vector3(7.6, 5.32, 1.0), Vector3(12.0, 5.32, 1.15), Vector3(12.1, 8.52, 1.15), Vector3(12.0, 5.32, 1.15), Vector3(7.6, 5.32, 1.0), Vector3(-7.6, 5.01, 1.0), Vector3(-12.0, 5.01, 1.15), Vector3(-13.0, 6.31, 1.15), Vector3(-12.0, 5.01, 1.15), Vector3(-7.6, 5.01, 1.0), Vector3(7.6, 5.32, 1.0), Vector3(12.0, 5.32, 1.15), Vector3(12.1, 8.52, 1.15), Vector3(12.0, 5.32, 1.15), Vector3(7.6, 5.32, 1.0)]]}


## The stills of a route's walk (STILLS=1): at a point reached, its name.
const ROUTE_MARKS := {"rooms": {2: "gate", 6: "tibetan", 7: "tibetan_back", 10: "chinese", 13: "guest", 16: "kitchen"},
		"house_142": {2: "door", 4: "in", 5: "log", 6: "hearth", 9: "out"},
		"gallery": {7: "gallery_in", 8: "gallery_mid", 9: "gallery_end", 11: "yard"},
		"laundry": {1: "in", 2: "through", 3: "out"},
		"message": {7: "E:agent_1", 12: "E:yang_1", 17: "E:agent_2", 22: "E:yang_2", 27: "E:agent_3", 32: "E:yang_3"}}


## The tea route's end (sprint 7, step 4; chapter 07, 7.2): the player sits on the Tibetan room's guest bench, its back
## to it; the house's woman pours before anything is said; E (the libation), E (a sip) and its refill, R (enough), each
## with a still (STILLS=1: tests/player/out/s15_tea_*.png). PASS if the bowl was filled, the libation came first, the sip
## was refilled to the brim, and nothing was poured after enough.
func _tea_tick(p: CharacterBody3D, dt: float) -> void:
	var t: float = current["tea_t"]
	current["tea_t"] = t + dt
	var tea := _nearest_tea(p.global_position)
	p.scripted_move = Vector3.ZERO
	if t == 0.0:
		var face := PI  # its back to the bench (north): facing south, over the room
		var seat := _nearest_seat(tea.global_position if tea != null and route_name == "chang_tea" else p.global_position)  # (the chang house: the seat by the guest's bowl)
		if seat != null and route_name == "tea" and absf(wrapf(seat.global_rotation.y - PI, -PI, PI)) > 0.8:
			seat = null  # the Tibetan room's guest bench faces south, over the room
		if seat != null:  # elsewhere its back to the nearest seat's bench: a SEAT faces along its -Z (the kit's out, -y)
			face = seat.global_rotation.y
			var sp := seat.global_position
			if sp.y - p.global_position.y > 0.2 and Vector2(sp.x - p.global_position.x, sp.z - p.global_position.z).length() < (1.6 if route_name == "chang_tea" else 1.2):
				# a bench: stepped up to just before its front edge, as a guest does to sit (the walk ends a pace off; in the
				# chang house beside the guest's table, squeezing in behind it)
				p.global_position = Vector3(sp.x, p.global_position.y, sp.z) + Vector3(-sin(face), 0.0, -cos(face)) * 0.2
		p.facing = face
		p.yaw = face
		p.sit()
		print("s3: route %s: sat by %s, %s at %.2f m, the bowl %.2f m off" % [route_name, seat.name if seat != null else "no seat",
				String(p.get("rest_kind")), float(p.get("seat_height")), p.global_position.distance_to(tea.global_position) if tea != null else -1.0])
		p.view_first = true  # the guest's own view (V): the bowl before him and the woman who pours
		if String(p.get("rest_kind")) == "cross" and float(p.get("seat_height")) < 0.1:  # on the floor (a poor house): down
			p.pitch = -0.38  # to the bowl on the log before the guest, the ladle over it
		if OS.get_environment("TEA_VIEW") == "third":  # the guest and the host seen from behind, for checking the scene
			p.view_first = false
			p.pitch = -0.2
		p._show_body()
		return
	if tea == null:
		print("s3: route tea FAIL: no tea in the Tibetan room (world/tea.gd; the room streamed in?)")
		get_tree().quit()
		return
	var host: int = tea.get("server")
	if host >= 0 and int(p.get("rest")) != 0:  # the view from the bench to the bowl and her
		var to: Vector3 = tea.global_position * 0.6 + (tea.call("host_point") as Vector3) * 0.4 - p.global_position
		p.yaw = atan2(-to.x, -to.z)
		p.pitch = -0.24
	for m in [[4.0, "tea_01_poured"], [5.2, "tea_02_libation"], [8.9, "tea_05_pouring"], [10.0, "tea_03_refilled"], [12.0, "tea_04_enough"]]:
		if t < float(m[0]) and t + dt >= float(m[0]) and climb_stills:
			_save_still(route_name + String(m[1]).substr(3))  # tea_01_poured, house_tea_01_poured
	if t < 4.3 and t + dt >= 4.3:
		tea.call("sip")  # the libation first
	elif t < 7.0 and t + dt >= 7.0:
		current["full"] = float(tea.get("level"))
		tea.call("sip")
		current["sipped"] = float(tea.get("level"))
	elif t < 11.2 and t + dt >= 11.2:
		current["refilled"] = float(tea.get("level"))
		tea.call("no_more")
	elif route_name == "tsokchen_tea" and t < 13.0 and t + dt >= 13.0:  # (the hall: a last sip after enough, a little left,
		tea.call("sip")  # then up: world/hall_tea.gd's lesson)
		current["held"] = [bool(tea.get("libation")), int(tea.get("refills")), bool(tea.get("enough"))]
	elif route_name == "tsokchen_tea" and t < 14.0 and t + dt >= 14.0:
		p.stand()
	elif t >= 16.0:
		var held: Array = current.get("held", [bool(tea.get("libation")), int(tea.get("refills")), bool(tea.get("enough"))])
		var ok: bool = float(current.get("full", 0.0)) > 0.99 and bool(held[0]) and float(current.get("sipped", 1.0)) < 0.7 \
				and float(current.get("refilled", 0.0)) > 0.99 and int(held[1]) == 1 and bool(held[2])
		if route_name == "tsokchen_tea":
			print("s3: route tsokchen_tea: standing up, %s" % String(tea.get("lesson")))
			ok = ok and String(tea.get("lesson")) == "left_a_little"
		print("s3: route %s: the bowl %.2f full after the pour, %.2f after the sip, %.2f after its refill; %d refills, the libation %s, enough %s %s" % [route_name,
				float(current.get("full", 0.0)), float(current.get("sipped", 1.0)), float(current.get("refilled", 0.0)), int(held[1]),
				str(held[0]), str(held[2]), "PASS" if ok else "FAIL"])
		get_tree().quit()


## The headman's house's moments (M2 sprint 7, step 5; world/headman_house.gd): in its yard by the barking mastiff, the
## call to the house (E): the dog quiet and held, by the groom if he is about the stable (headman_dog); before the
## headman's bench at the head of the reception room, C: refused, the player still standing (headman_seat). Stills
## (STILLS=1): tests/player/out/s15_headman_dog_*.png, s15_headman_seat.png.
func _headman_tick(p: CharacterBody3D, dt: float) -> void:
	var t: float = current["headman_t"]
	current["headman_t"] = t + dt
	p.scripted_move = Vector3.ZERO
	var hm := get_tree().root.find_child("HeadmanHouse", true, false)
	if hm == null:
		print("s3: route %s FAIL: no world/headman_house.gd (run with --town)" % route_name)
		get_tree().quit()
		return
	if route_name == "headman_seat":
		if t == 0.0:
			p.facing = deg_to_rad(90.0)  # its back to the headman's bench on the east wall
			p.yaw = p.facing
			p.sit()
		elif t >= 1.5:
			if climb_stills:
				_save_still("headman_seat")
			var ok := int(p.get("rest")) == 0
			print("s3: route headman_seat: %s %s" % ["still standing: the headman's seat refused" if ok else "SAT on the headman's bench", "PASS" if ok else "FAIL"])
			get_tree().quit()
		return
	var dog: Node3D = hm.get("dog")
	if dog != null:  # turned to the dog
		var to := dog.global_position - p.global_position
		p.yaw = atan2(-to.x, -to.z)
		p.pitch = -0.2
	if t < 2.0 and t + dt >= 2.0:
		current["barked"] = bool(hm.get("barking"))
		if climb_stills:
			_save_still("headman_dog_01_barking")
		current["called"] = bool(hm.call("call_to_house", p.global_position))
	if t < 5.0 and t + dt >= 5.0 and climb_stills:
		_save_still("headman_dog_02_held")
	if t >= 6.0:
		var held := float(hm.get("held_until")) > fposmod(WorldClock.minute, 1440.0)
		var holder := int(hm.get("holder"))
		var ok: bool = bool(current.get("barked", false)) and bool(current.get("called", false)) and held and not bool(hm.get("barking"))
		print("s3: route headman_dog: barking at the gate %s, called %s, held %s by %s, quiet %s %s" % [str(current.get("barked", false)),
				str(current.get("called", false)), str(held), String(TownSim.key[holder]) if holder >= 0 else "a word from inside",
				str(not bool(hm.get("barking"))), "PASS" if ok else "FAIL"])
		get_tree().quit()


## Mission 1's end (M2 sprint 1, step 5; chapter 14, 4.1): by Achak Dolkar, the letter given. In the open (route
## letter_open, at her gateway at 16:30): she knows its news, those standing near saw it, and Yang Shouren has heard of it
## an hour later. Behind a shut door (letter_private, the Tibetan room at dusk): the door shut first, she alone knows,
## and no one has heard of it an hour later. Stills (STILLS=1): the greeting and its replies, the letter given, after.
func _letter_tick(p: CharacterBody3D, dt: float) -> void:
	var t: float = current["letter_t"]
	current["letter_t"] = t + dt
	p.scripted_move = Vector3.ZERO
	var conv := get_tree().get_first_node_in_group("conversation")
	var dk := -1
	for i in TownSim.count:
		if String(TownSim.key[i]) == "achak_dolkar":
			dk = i
	if conv == null or dk < 0:
		print("s3: route %s FAIL: no conversation runner or no Achak Dolkar (run with --town --people)" % route_name)
		get_tree().quit()
		return
	var her: Vector3 = TownSim.pos[dk]
	if OS.get_environment("LETTER_DEBUG") != "" and (t == 0.0 or (t < 1.6 and t + dt >= 1.6)):
		var rooms_ := get_tree().get_first_node_in_group("interiors")
		var doors_ := get_tree().get_first_node_in_group("doors")
		var room_: Node = rooms_.call("room_at", p.global_position + Vector3(0.0, 1.0, 0.0))
		var at_: Vector3 = (room_.get_parent() as Node3D).global_position if room_ != null else Vector3.INF
		var mids := []
		for k in (doors_.get("doors") as Array).size():
			var m: Vector3 = doors_.get("doors")[k]["mid"]
			if m.distance_to(p.global_position) < 10.0:
				mids.append("%d %s %.2f open %s" % [k, doors_.call("door_id", k), m.distance_to(at_) if at_ != Vector3.INF else -1.0, str(doors_.get("doors")[k]["open"])])
		print("s3: letter debug t %.1f: player %s, room %s at %s, room_door %d, doors near %s" % [t, str(p.global_position), String(room_.get("room_id")) if room_ != null else "none", str(at_), int(conv.call("room_door")), str(mids)])
	if t == 0.0:
		if route_name == "letter_private":  # the door shut behind, and in to her
			var doors := get_tree().get_first_node_in_group("doors")
			doors.call("set_open", int(conv.call("room_door")), false)  # the room's own door
			var front := Vector3(sin(float(TownSim.yaw[dk])), 0.0, cos(float(TownSim.yaw[dk])))  # the way she faces on her bench
			p.global_position = Vector3(her.x, p.global_position.y, her.z) + front * 1.7
		var to := her - p.global_position
		p.facing = atan2(-to.x, -to.z)
		p.yaw = p.facing
		p.pitch = -0.1
		if route_name == "letter_private":  # the player's own eyes, down to her on her bench (in third person the
			p.view_first = true  # player's back and the pillar hid her)
			p.pitch = -0.2
			p._show_body()
		return
	if t < 1.5:  # the door swings shut
		return
	if not current.has("letter_started"):
		current["letter_started"] = true
		var c: Dictionary = conv.call("candidate", p)
		if c.is_empty():
			print("s3: route %s FAIL: Achak Dolkar cannot be talked to here (%.1f m off)" % [route_name, p.global_position.distance_to(her)])
			get_tree().quit()
			return
		conv.call("start", c["talk"], c["walker"])
		current["offered"] = (get_tree().get_first_node_in_group("replies").get("shown") as Array).duplicate()
		return
	if t < 3.0:
		if t + dt >= 2.0 and t < 2.0 and climb_stills:
			_save_still(route_name + "_01_greeting")
		return
	if not current.has("letter_chosen"):
		current["letter_chosen"] = true
		conv.call("choose", 0)  # in the open: hand it over; behind the door: give it with the door shut
		return
	if t < 5.0:
		if t + dt >= 4.0 and t < 4.0 and climb_stills:
			_save_still(route_name + "_02_given")
		return
	if not current.has("letter_done"):
		current["letter_done"] = true
		for k in 4:
			if not (conv.get("current") as Dictionary).is_empty():
				conv.call("go_on")
		if climb_stills:
			_save_still(route_name + "_03_after")
		var seen: Array = []
		for w in TownSim.count:
			if Story.knows(String(TownSim.key[w]), "letter_seen"):
				seen.append(String(TownSim.key[w]))
		current["seen"] = seen
		WorldClock.minute += 61.0  # an hour on: what passes on through the house
		Story._process(0.0)
		return
	var open := route_name == "letter_open"
	var given := Story.flag("letter_given") and Story.knows("achak_dolkar", "letter_news")
	var yang := Story.knows("yang_shouren", "letter_seen")
	var ok := given and not Story.flag("has_letter") and (yang if open else (Story.flag("letter_private") and not yang and (current["seen"] as Array).is_empty()))
	print("s3: route %s: the replies offered %s; given %s, private %s; saw it: %s; Yang Shouren has heard an hour later: %s; the ledger: %s %s" % [route_name,
			str(current.get("offered", [])), str(given), str(Story.flag("letter_private")), str(current["seen"]), str(yang),
			str(Story.ledger.map(func(e: Dictionary) -> String: return "%s%s" % [e["id"], " (done)" if bool(e["done"]) else ""])), "PASS" if ok else "FAIL"])
	get_tree().quit()


## Mission 2's walk (M2 sprint 2, step 4; chapter 14, 4.1): in the chang house at 16:33, the order heard from Jiang
## Deshun as the room asks him (data/talks/m2_order.json, played by world/talks.gd while the player is there), then Ama
## Yudrön asked who can bear it (data/conversations/m2_yudron.json): the number she gives, and who owes Dechen-tsang. PASS
## if the order was heard, the debts told, the mission done and the ledger holds both. Stills (STILLS=1): the order
## heard, her answer.
func _chang_tick(p: CharacterBody3D, dt: float) -> void:
	var t: float = current["chang_t"]
	current["chang_t"] = t + dt
	p.scripted_move = Vector3.ZERO
	var tk := get_tree().get_first_node_in_group("talks")
	if t < 40.0 and not Story.flag("heard_ula_order"):
		if climb_stills and t < 7.0 and t + dt >= 7.0:
			_save_still(route_name + "_01_order")
		if t + dt >= 39.9:
			print("s3: route chang_talk FAIL: the order not heard (talks %s, room %s)" % [str(tk.get("said") if tk != null else []), String(tk.call("player_room")) if tk != null else "?"])
			get_tree().quit()
		return
	var conv := get_tree().get_first_node_in_group("conversation")
	if not current.has("asked"):
		current["asked"] = true
		var yd := -1
		for i in TownSim.count:
			if String(TownSim.key[i]) == "ama_yudron":
				yd = i
		var her: Vector3 = TownSim.pos[yd]
		var away := p.global_position - her
		away.y = 0.0
		p.global_position = Vector3(her.x, p.global_position.y, her.z) + away.normalized() * 1.3
		var to := her - p.global_position
		p.facing = atan2(-to.x, -to.z)
		p.yaw = p.facing
		p.pitch = -0.08
		return
	if not current.has("talking"):
		var c: Dictionary = conv.call("candidate", p)
		if c.is_empty() or String((c["talk"] as Dictionary).get("id", "")) != "m2_yudron":
			print("s3: route chang_talk FAIL: Ama Yudrön has nothing to say (%s)" % str(c.get("talk", {}).get("id", "none")))
			get_tree().quit()
			return
		current["talking"] = true
		conv.call("start", c["talk"], c["walker"])
		current["talk_t"] = t
		return
	var since := t - float(current["talk_t"])
	if since < 2.5:
		if climb_stills and since + dt >= 2.0 and since < 2.0:
			_save_still(route_name + "_02_sixty")
		return
	if not current.has("chosen"):
		current["chosen"] = true
		conv.call("choose", 0)  # ask her who in Shöl can bear it
		return
	if since < 5.5:
		if climb_stills and since + dt >= 4.5 and since < 4.5:
			_save_still(route_name + "_03_debts")
		return
	for k in 3:
		if not (conv.get("current") as Dictionary).is_empty():
			conv.call("go_on")
	var ok := Story.flag("heard_ula_order") and Story.flag("heard_debts") and bool(Story.entry("m2_talk").get("done", false)) \
			and not Story.entry("m2_order").is_empty() and not Story.entry("m2_debts").is_empty()
	print("s3: route chang_talk: the order heard %s, the debts told %s, mission 2 %s; the ledger: %s %s" % [str(Story.flag("heard_ula_order")),
			str(Story.flag("heard_debts")), "done" if bool(Story.entry("m2_talk").get("done", false)) else "NOT done",
			str(Story.ledger.map(func(e: Dictionary) -> String: return String(e["id"]))), "PASS" if ok else "FAIL"])
	get_tree().quit()


## The Tea (world/tea.gd) nearest `at`: Dechen-tsang's Tibetan room's or a house kitchen's, whichever is streamed in.
func _nearest_tea(at: Vector3) -> Node3D:
	var best: Node3D = null
	for t in get_tree().get_nodes_in_group("tea"):
		if best == null or (t as Node3D).global_position.distance_to(at) < best.global_position.distance_to(at):
			best = t as Node3D
	return best


## The SEAT socket nearest `at` among the streamed-in rooms' (the kit's benches: facing along their -Z).
func _nearest_seat(at: Vector3) -> Node3D:
	var best: Node3D = null
	for room in get_tree().get_nodes_in_group("tea"):
		for s in (room as Node).get_parent().find_children("SOCK_SEAT_*", "Node3D", true, false):
			if best == null or (s as Node3D).global_position.distance_to(at) < best.global_position.distance_to(at):
				best = s as Node3D
	return best


## The wardrobe route's end (IMP-025; world/wardrobe.gd): by the chest in the guest room the route opens it, puts on the
## man's other two outfits, shows the woman and puts on hers, each with a still (STILLS=1:
## tests/player/out/s15_wardrobe_*.png), and closes it. PASS if each was worn and the chest closed.
## A few of tools/town/roof_ways.py's pieces to look at (IMP-026): the first two planks, a stair-ladder, a log and a
## ladder up a wall, each with where the walker stands to see it: [{"piece", "eye" (town grid, on the ground or the
## yard), "at" (its middle)}], from the piece's ground end 3 m back along its axis.
func _roofway_samples() -> Array:
	var path := "res://assets/generated/terrain/roof_ways.json"
	if not FileAccess.file_exists(path):
		return []
	var pcs: Array = JSON.parse_string(FileAccess.get_file_as_string(path))["pieces"]
	var out := []
	for want in ["plank", "plank", "stair", "log", "wall"]:
		for pc in pcs:
			if String(pc["kind"]) != want or out.any(func(o: Dictionary) -> bool: return o["piece"] == pc):
				continue
			var lo: Array
			var hi: Array
			if want == "plank":
				lo = pc["to"] if float(pc["to"][2]) <= float(pc["from"][2]) else pc["from"]
				hi = pc["from"] if lo == pc["to"] else pc["to"]
			else:
				lo = pc["foot"]
				hi = pc["top"]
			var ax := Vector2(float(hi[0]) - float(lo[0]), float(hi[1]) - float(lo[1])).normalized()
			var side := Vector2(-ax.y, ax.x)
			var eye := Vector2(float(lo[0]), float(lo[1])) - ax * 3.0 + side * 1.2
			out.append({"piece": pc, "eye": [eye.x, eye.y, float(lo[2])], "at": [(float(lo[0]) + float(hi[0])) / 2.0, (float(lo[1]) + float(hi[1])) / 2.0, (float(lo[2]) + float(hi[2])) / 2.0]})
			break
	return out


func _roofways_tick(p: CharacterBody3D, dt: float) -> void:
	var rw := _roofway_samples()
	var t: float = current["rw_t"]
	current["rw_t"] = t + dt
	p.scripted_move = Vector3.ZERO
	var i: int = current["rw_i"]
	if i >= rw.size():
		print("s3: route roofways: %d stills" % rw.size())
		get_tree().quit()
		return
	var s0: Dictionary = rw[i]
	var e: Array = s0["eye"]
	var a: Array = s0["at"]
	if t == 0.0:
		p.global_position = Town.to_godot(float(e[0]), float(e[1]), float(e[2]) + 1.0)
		p.velocity = Vector3.ZERO
		var to := Town.to_godot(float(a[0]), float(a[1]), float(a[2])) - Town.to_godot(float(e[0]), float(e[1]), float(e[2]) + 1.6)
		p.yaw = atan2(-to.x, -to.z)
		p.facing = p.yaw
		p.pitch = clampf(atan2(to.y, Vector2(to.x, to.z).length()), -0.6, 0.8)
		p.reset_physics_interpolation()
		return
	if t < 2.5 and t + dt >= 2.5 and climb_stills:
		_save_still("roofway_%02d_%s_%s" % [i + 1, String(s0["piece"]["kind"]), String(s0["piece"]["deck"]).to_lower().replace(".", "_")])
	if t >= 3.0:
		current["rw_i"] = i + 1
		current["rw_t"] = 0.0


## The viewpoints' stills (IMP-021 (5), IMP-024): each of data/viewpoints.json's views at its hour: the walker set at its
## seat, sat (C), and after the wait and the drift (world/viewpoints.gd: 2.5 s and 4 s) a still, `viewpoint_<id>`; then
## stood up and on to the next. PASS if the camera reached every frame (the player's view_k over 0.95).
func _views_tick(p: CharacterBody3D, dt: float) -> void:
	var vj = JSON.parse_string(FileAccess.get_file_as_string("res://data/viewpoints.json"))
	var views: Array = vj["views"]
	var t: float = current["views_t"]
	current["views_t"] = t + dt
	p.scripted_move = Vector3.ZERO
	var i: int = current["view_i"]
	if i >= views.size():
		var reached: int = int(current.get("views_reached", 0))
		print("s3: route viewpoints: %d of %d frames reached %s" % [reached, views.size(), "PASS" if reached == views.size() else "FAIL"])
		get_tree().quit()
		return
	var v: Dictionary = views[i]
	var s0: Array = v["seat"]
	if t == 0.0:
		WorldClock.freeze(11.0, _minute_at(float(v.get("hour", 14.0))))
		p.stand()
		p.rest = 0
		p.global_position = Town.to_godot(float(s0[0]), float(s0[1]), float(s0[2]) + 1.0)  # dropped onto the floor there
		p.velocity = Vector3.ZERO
		var b := deg_to_rad(float(v["bearing"]))
		p.facing = -b
		p.yaw = -b
		p.reset_physics_interpolation()
		return
	if t < 1.5 and t + dt >= 1.5:
		p.sit()
		if p.rest == 0:
			print("s3: route viewpoints: %s: could not sit (on the floor %s, on a stair %s, at %s)" % [v["id"], p.is_on_floor(), not (p.stair as Dictionary).is_empty(), str(p.global_position)])
	if t < 10.0 and t + dt >= 10.0:
		var vk: float = p.view_k
		var g := Town.to_godot(float(s0[0]), float(s0[1]), float(s0[2]))
		print("s3: route viewpoints: %s (%s) at %s: the frame reached %.2f (sat %s, %.1f m from the seat, %.1f m over its floor)" % [v["id"], v["name"], _hhmm(WorldClock.minute), vk,
				p.rest == 2, Vector2(p.global_position.x - g.x, p.global_position.z - g.z).length(), p.global_position.y - g.y])
		if vk > 0.95:
			current["views_reached"] = int(current.get("views_reached", 0)) + 1
		if climb_stills:
			_save_still("viewpoint_%s" % String(v["id"]).to_lower().replace("-", ""))
	if t >= 10.5:
		p.stand()
		current["view_i"] = i + 1
		current["views_t"] = 0.0


func _wardrobe_tick(p: CharacterBody3D, dt: float) -> void:
	var t: float = current["ward_t"]
	current["ward_t"] = t + dt
	p.scripted_move = Vector3.ZERO
	var wd := get_tree().root.find_child("Wardrobe", true, false)
	if wd == null:
		print("s3: route wardrobe FAIL: no wardrobe (world/wardrobe.gd)")
		get_tree().quit()
		return
	if t == 0.0:  # a step from the chest, on the room's side of it
		var chest: Vector3 = wd.get("chest")
		var from := Vector3(p.global_position.x - chest.x, 0.0, p.global_position.z - chest.z).normalized()
		p.global_position = Vector3(chest.x, p.global_position.y, chest.z) + from * 1.0
		p.facing = atan2(-from.x, -from.z) + PI
		current["opened"] = bool(wd.call("open_chest"))
		return
	var marks := [[1.8, "wardrobe_01_road"], [4.6, "wardrobe_02_town"], [7.4, "wardrobe_03_best"], [10.2, "wardrobe_04_woman_road"],
			[13.0, "wardrobe_05_woman_town"], [15.8, "wardrobe_06_woman_best"]]
	for m in marks:
		if t < float(m[0]) and t + dt >= float(m[0]) and climb_stills:
			_save_still(m[1])
	if (t < 2.0 and t + dt >= 2.0) or (t < 4.8 and t + dt >= 4.8) or (t < 10.4 and t + dt >= 10.4) or (t < 13.2 and t + dt >= 13.2):
		wd.call("step", 1)
	elif t < 8.0 and t + dt >= 8.0:  # the other of the two (B)
		p.woman = true
		p._show_body()
		wd.call("shown")
	elif t >= 17.0:
		var worn: Dictionary = p.outfit
		wd.call("close_chest")
		var ok: bool = bool(current.get("opened", false)) and int(worn["man"]) == 2 and int(worn["woman"]) == 2 and not bool(wd.get("open")) and not p.dressing
		print("s3: route wardrobe: the chest %s, the man in %s, the woman in %s, closed %s %s" % ["opened" if current.get("opened", false) else "NOT opened",
				String(p.OUTFITS["man"][int(worn["man"])][0]), String(p.OUTFITS["woman"][int(worn["woman"])][0]), str(not bool(wd.get("open"))), "PASS" if ok else "FAIL"])
		get_tree().quit()


## The codex's sites in the slice (sprint 7, step 7; world/codex_sites.gd): each look or enter site found in the built
## town, the camera set 3 m before it (a look) or a player stood on it (an enter) for two seconds at an hour it can be
## found; PASS if every one was found. Run: tools/town/codex.sh (headless, with the town and its people).
func _start_codex() -> void:
	var sites := get_tree().root.find_child("CodexSites", true, false)
	if sites == null:
		print("s3: codex FAIL: no CodexSites (run with --town)")
		get_tree().quit()
		return
	Codex.reset()
	WorldClock.freeze(11.0, _minute_at(14.5))  # Dolkar in the Chinese room, the stalls kept, the town about
	jobs = []
	for s in sites.SITES:
		if String(s[1]) in ["look", "enter"]:
			jobs.append(s)
	var gs := GDScript.new()
	gs.source_code = "extends Node3D\nvar rest := 0\n"
	gs.reload()
	var stand := Node3D.new()  # a stand-in for the player, for the enter sites
	stand.set_script(gs)
	stand.add_to_group("player")
	add_child(stand)
	current = {"sites": sites, "stand": stand, "t": -1.0, "ok": 0, "missing": []}


func _codex_tick(dt: float) -> void:
	var sites: Node = current["sites"]
	if current["t"] < 0.0:
		if jobs.is_empty():
			var n: int = current["ok"]
			var total: int = n + (current["missing"] as Array).size()
			print("s3: codex %s: %d of %d sites found%s" % ["PASS" if n == total else "FAIL", n, total,
					"" if n == total else " (not: %s)" % ", ".join(PackedStringArray(current["missing"]))])
			get_tree().quit()
			return
		var s: Array = jobs.pop_front()
		current["site"] = s
		current["t"] = 0.0
		if String(s[0]) == "CX-058":
			Codex.found["CX-057"] = WorldClock.minute - 1.0  # the pitch's second nod follows the first
		var at: Variant = sites.call("where", String(s[2]))
		if at == null:
			print("s3: codex %s: its site %s is not in the town" % [s[0], s[2]])
			(current["missing"] as Array).append(String(s[0]))
			current["t"] = -1.0
			return
		var p: Vector3 = at
		if String(s[1]) == "look":
			var back := Vector3(3.0, 0.4, 0.0) if String(s[0]) != "CX-049" else Vector3(10.0, -2.0, 0.0)
			cam.global_position = p + back
			cam.look_at(p)
		else:
			(current["stand"] as Node3D).global_position = p
			cam.global_position = p + Vector3(0.0, 1.6, 3.0)
		cam.current = true
		return
	current["t"] += dt
	if current["t"] > 2.2:
		var id: String = current["site"][0]
		if Codex.found.has(id):
			current["ok"] += 1
			print("s3: codex %s found (%s)" % [id, String(Codex.entries[id]["nod"])])
		else:
			(current["missing"] as Array).append(id)
			print("s3: codex %s NOT found at %s" % [id, str(sites.call("where", String(current["site"][2])))])
		current["t"] = -1.0


## The Rooftop Way's walk: every leg's points in order (town grid to Godot), and where a piece is crossed its kind at
## the point before it, for the stills.
func _rooftop_points() -> Array:
	var path := "res://assets/generated/terrain/rooftop.json"
	if not FileAccess.file_exists(path):
		return [[], {}]
	var pts := []
	var marks := {}
	var tight := {}  # points to reach within 0.15 m: a plank's ends, square to its axis
	var legs: Array = JSON.parse_string(FileAccess.get_file_as_string(path))["legs"]
	for k in legs.size():
		var leg: Dictionary = legs[k]
		if leg.has("points"):
			for q in leg["points"]:
				pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
			continue
		if pts.is_empty():
			continue
		# a step or a ladder is met square: the leg's last point moves onto its axis before it, the way the walk goes
		var pc = leg["piece"]
		var nxt: Array = legs[k + 1]["points"][0] if k + 1 < legs.size() and legs[k + 1].has("points") else []
		if pc != null and not nxt.is_empty():
			var last: Vector3 = pts[pts.size() - 1]
			var up: bool = float(nxt[2]) > _town_z(last) + 0.2
			var b := deg_to_rad(float(pc.get("bearing", 0.0)))
			var ax := Vector2(sin(b), cos(b))  # the piece's way: a ladder's from its foot to its wall, steps' up their flight
			var a := Vector2.INF
			match String(pc["kind"]):
				"log", "stair":
					var f: Array = pc["foot"]
					var t: Array = pc["top"]
					var ap: Array = pc.get("approach", [])  # the planner's: a walkable spot on its axis behind the foot
					a = (Vector2(ap[0], ap[1]) if not ap.is_empty() else Vector2(f[0], f[1]) - ax * 0.8) if up else Vector2(t[0], t[1]) + ax * 1.0
				"steps":
					var q: Array = pc["pos"]
					var n := int(round(float(pc["rise"]) / 0.2))
					a = Vector2(q[0], q[1]) - ax * 0.5 if up else Vector2(q[0], q[1]) + ax * (maxf(n, 2) * 0.3 + 1.2)
				"lane":  # up (or down) a side lane's flight: its foot and head are on its axis; reach them close
					tight[pts.size() - 1] = true
				"plank":  # onto its axis, a metre before its end on this side
					var pf: Array = pc["from"]
					var pt: Array = pc["to"]
					var e0 := Vector2(pf[0], pf[1])
					var e1 := Vector2(pt[0], pt[1])
					var here := Vector2(last.x, -last.z)
					if here.distance_to(e1) < here.distance_to(e0):
						var sw := e0
						e0 = e1
						e1 = sw
					a = e0 - (e1 - e0).normalized() * 1.0
					var ex := e1 + (e1 - e0).normalized() * 1.0
					pts[pts.size() - 1] = Town.to_godot(a.x, a.y, _town_z(last))
					tight[pts.size() - 1] = true
					pts.append(Town.to_godot(ex.x, ex.y, float(nxt[2])))
					tight[pts.size() - 1] = true
					marks[pts.size() - 2] = String(leg["by"])
					continue
			if a != Vector2.INF:
				pts[pts.size() - 1] = Town.to_godot(a.x, a.y, _town_z(last))
		marks[pts.size() - 1] = String(leg["by"])
	return [pts, marks, tight]


## A house's socket in the town grid (x, y, z), or Vector3.INF where the house or the socket is missing.
func _sock_town(house: String, sock: String) -> Vector3:
	var h := get_node_or_null("Town/" + house) as Node3D
	var s_ := h.find_child(sock, true, false) as Node3D if h != null else null
	if s_ == null:
		return Vector3.INF
	var g := s_.global_position
	return Vector3(g.x, -g.z, _town_z(g))


## The bridge's walk (IMP-023 (3)), in the town grid from bridges.json: up the ladder on its east house's wall from its
## yard, along the roof onto the bridge, across it to the west roof, and over that roof's plank down to the lane behind
## it (each end of the plank reached on its axis), or back and down the ladder where there is none.
## [points, marks (the stills' names), tight].
func _bridge_points() -> Array:
	var path := "res://assets/generated/terrain/bridges.json"
	if not FileAccess.file_exists(path):
		return [[], {}, {}]
	var bj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	if (bj["bridges"] as Array).is_empty():
		return [[], {}, {}]
	var br: Dictionary = bj["bridges"][0]
	var lad := {}
	var plank := {}
	for pc in bj["pieces"]:
		if String(pc["kind"]) in ["wall", "log", "stair"] and lad.is_empty():
			lad = pc
		elif String(pc["kind"]) == "plank":
			plank = pc
	if lad.is_empty():
		return [[], {}, {}]
	var near_a := String(lad["deck"]) == String(br["ends"][0])
	var dv := Vector2(float(br["dir"][0]), float(br["dir"][1]))
	var A := Vector2(float(br["a"][0]), float(br["a"][1]))
	var B := Vector2(float(br["b"][0]), float(br["b"][1]))
	var za := float(br["a"][2]) - float(br["drops"][0])  # the roofs' decks
	var zb := float(br["b"][2]) - float(br["drops"][1])
	var start := A - dv * 1.0 if near_a else B + dv * 1.2  # on the ladder's roof, before the bridge
	var start_z := za if near_a else zb
	var other := B + dv * 1.2 if near_a else A - dv * 1.0
	var other_z := zb if near_a else za
	var pts := []
	var marks := {}
	var tight := {}
	var b := deg_to_rad(float(lad["bearing"]))
	var ax := Vector2(sin(b), cos(b))  # from its foot to its wall
	var f := Vector2(float(lad["foot"][0]), float(lad["foot"][1]))
	var t := Vector2(float(lad["top"][0]), float(lad["top"][1]))
	pts.append(Town.to_godot(f.x - ax.x * 1.4, f.y - ax.y * 1.4, float(lad["foot"][2])))  # in the yard
	pts.append(Town.to_godot(f.x - ax.x * 0.8, f.y - ax.y * 0.8, float(lad["foot"][2])))
	tight[pts.size() - 1] = true
	pts.append(Town.to_godot(t.x + ax.x * 1.0, t.y + ax.y * 1.0, start_z))  # up onto the roof
	pts.append(Town.to_godot(start.x, start.y, start_z))
	tight[pts.size() - 1] = true
	marks[pts.size() - 1] = "roof"
	var L := A.distance_to(B)
	for fr in [0.3, 0.62]:  # across
		var q: Vector2 = (A + dv * L * float(fr)) if near_a else (B - dv * L * float(fr))
		pts.append(Town.to_godot(q.x, q.y, float(br["a"][2]) - float(br["sag"]) * 0.9))
		marks[pts.size() - 1] = "bridge_%d" % int(float(fr) * 100)
	pts.append(Town.to_godot(other.x, other.y, other_z))
	tight[pts.size() - 1] = true
	marks[pts.size() - 1] = "far_roof"
	if not plank.is_empty():  # over the far roof's plank down to its lane
		var e0 := Vector2(float(plank["from"][0]), float(plank["from"][1]))  # its parapet end
		var e1 := Vector2(float(plank["to"][0]), float(plank["to"][1]))  # its lane end
		var u := (e1 - e0).normalized()
		pts.append(Town.to_godot(e0.x - u.x * 1.0, e0.y - u.y * 1.0, other_z))
		tight[pts.size() - 1] = true
		pts.append(Town.to_godot(e1.x + u.x * 1.0, e1.y + u.y * 1.0, float(plank["to"][2])))
		tight[pts.size() - 1] = true
		marks[pts.size() - 1] = "lane"
	else:
		pts.append(Town.to_godot(start.x, start.y, start_z))  # back
		pts.append(Town.to_godot(t.x + ax.x * 1.0, t.y + ax.y * 1.0, start_z))
		tight[pts.size() - 1] = true
		pts.append(Town.to_godot(f.x - ax.x * 0.8, f.y - ax.y * 0.8, float(lad["foot"][2])))  # down into the yard
		pts.append(Town.to_godot(f.x - ax.x * 1.4, f.y - ax.y * 1.4, float(lad["foot"][2])))
		marks[pts.size() - 1] = "yard"
	return [pts, marks, tight]


## The great wheel's walk (sprint 4, step 3), in the town grid: up the Sky Stair's flight to the gap in its east cheek
## (the kit's sky_stair, local y 81-83, level with the Mani Lhakhang's forecourt at 2,705 m), across the forecourt, in
## at the west door, round the wheel at 2.2 m from its axis (its bars reach 2.0 m), sixteen points a turn, three turns
## clockwise and one back. Returns [points, marks for the stills, the index where the walk the other way begins].
func _wheel_points() -> Array:
	var foot := Vector2(0.0, 15.0)  # the stair's line (the gazetteer's SHL-15, world/town.gd)
	var up := (Vector2(-20.0, 255.0) - foot).normalized()
	var east := Vector2(up.y, -up.x)
	var at := func(s: float, off: float, z: float) -> Vector3:
		var q: Vector2 = foot + up * s + east * off
		return Town.to_godot(q.x, q.y, z)
	var pts := [at.call(77.5, 0.0, 2702.3), at.call(82.0, 0.0, 2705.0), at.call(82.0, 3.2, 2705.0),
			Town.to_godot(1.5, 95.0, 2705.0), Town.to_godot(4.0, 95.0, 2705.0), Town.to_godot(6.6, 95.0, 2705.0)]
	var marks := {2: "forecourt", 4: "door"}
	for k in 49:  # clockwise seen from above: from the west, by the north, east and south
		var a := deg_to_rad(180.0 - k * 22.5)
		pts.append(Town.to_godot(10.0 + 2.2 * cos(a), 95.0 + 2.2 * sin(a), 2705.0))
	marks[6 + 22] = "wheel"  # a turn and three eighths on, the walker at the wheel's north-east
	var ccw_from := pts.size() - 1
	for k in range(1, 17):
		var a := deg_to_rad(180.0 - 48 * 22.5 + k * 22.5)
		pts.append(Town.to_godot(10.0 + 2.2 * cos(a), 95.0 + 2.2 * sin(a), 2705.0))
	return [pts, marks, ccw_from]


## A Godot point's height in the town grid (the inverse of Town.to_godot's, near the town).
func _town_z(p: Vector3) -> float:
	return p.y + Town.DATUM + (p.x * p.x + p.z * p.z) * (1.0 - Town.K_REFR) / (2.0 * Town.R_EARTH)


func _start_route() -> void:
	if "--time" in OS.get_cmdline_user_args():  # a timed walk measured on QT-BAL whatever the power source, as the PT-slice
		Quality.set_tier("QT-BAL")  # is (on battery the policy would take QT-BATT; M2 sprint 10)
	var pts := []
	if route_name == "wheel":
		var wp := _wheel_points()
		pts = wp[0]
		current["marks"] = wp[1]
		current["ccw_from"] = wp[2]
		if get_node_or_null("Town/SHL-08_wheel") == null:
			print("s3: route FAIL: no great wheel in the Mani Lhakhang (run with --town)")
			get_tree().quit()
			return
	elif route_name == "sang":  # sprint 7, step 6: up the Rooftop Way's first pieces to Dechen-tsang's master range roof,
		# to its burner's north side, and juniper laid on it (E) with the household at 17:12
		var rp := _rooftop_points()
		var legs: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/terrain/rooftop.json"))["legs"]
		var n := 0
		for leg in legs:
			if leg.has("points"):
				if String(leg["on"]) == "SHL-04.5":
					n += 1
					break
				n += (leg["points"] as Array).size()
		pts = (rp[0] as Array).slice(0, n)
		current["tight"] = rp[2]
		pts.append(Town.to_godot(-80.2, -18.3, 2660.0))
		current["marks"] = {pts.size() - 1: "E:burner"}
		pts.append(Town.to_godot(-79.4, -18.3, 2660.0))  # a step aside after: the route ends past the E, not on it
	elif route_name == "yard_022":  # ISS-115: from LN-002's top landing up YL-011 into H-SHL-022's yard and to its door
		var vj: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/town_lanes.json"))["lanes"]
		var yl: Dictionary = {}
		for ln in vj:
			if "lane LN-002" in str(ln.get("between")) and "H-SHL-022" in str(ln.get("between")):
				yl = ln
		if yl.is_empty():
			print("s3: route FAIL: no flight from LN-002's head into H-SHL-022's yard (tools/terrain/pads.py)")
			get_tree().quit()
			return
		var f0 := Vector2(float(yl["from"][0]), float(yl["from"][1]))
		var u := Vector2(float(yl["dir"][0]), float(yl["dir"][1]))
		var top := f0 + u * float(yl["length"])
		for ln in vj:  # up LN-002's last flight on its axis to its top landing
			if String(ln["id"]) == "LN-002":
				var a0 := Vector2(float(ln["from"][0]), float(ln["from"][1]))
				var ud := Vector2(float(ln["dir"][0]), float(ln["dir"][1]))
				var L := float(ln["length"])
				pts.append(Town.to_godot(a0.x + ud.x * (L - 4.5), a0.y + ud.y * (L - 4.5), float(ln["z_b"]) - 2.6))
				pts.append(Town.to_godot(a0.x + ud.x * (L - 0.3), a0.y + ud.y * (L - 0.3), float(ln["z_b"])))
		pts.append(Town.to_godot(f0.x + u.x * 0.2, f0.y + u.y * 0.2, float(yl["z_a"])))  # into the flight's foot
		current["tight"] = {pts.size() - 1: true}
		pts.append(Town.to_godot(top.x + u.x * 1.0, top.y + u.y * 1.0, float(yl["z_b"])))  # up it, onto the yard
		var door := _sock_town("H-SHL-022", "SOCK_DOOR_1")
		if door != Vector3.INF:
			pts.append(Town.to_godot(door.x, door.y - 1.6, float(yl["z_b"])))  # before the door
		current["marks"] = {}
	elif route_name == "serchu":  # M2 sprint 3: the arrival by R-01 (data/arrival.json), from SER-20 along the cliff
		# gallery, through the cutting in the nose and the Gate Chorten to V-01, then down past the eight chortens' row
		var road: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/arrival.json"))["road_west"]
		for q in road.slice(0, 8):
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		current["marks"] = {2: "gallery_west", 4: "v01"}
	elif route_name == "samkha":  # M2 sprint 4: from the south pavilion over the chain bridge (data/samkha.json), through
		# the gate passage in Samkha Khar's ground storey (step 4) and down its steps into the ward, out at the ward's gate
		var sk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/samkha.json"))
		var br: Dictionary = sk["bridge"]
		var bx := float(br["x"])
		pts.append(Town.to_godot(bx, float(br["south"][0]) - 2.5, float(br["south"][1]) + 0.04))
		var deck: Array = (br["deck"] as Array).duplicate()
		deck.reverse()  # south to north
		for q in deck:
			pts.append(Town.to_godot(bx, float(q[0]), float(q[1])))
		var pa: Dictionary = sk["passage"]
		var st: Dictionary = sk["stair"]
		for y in [-92.0, -88.0, -84.0, float(pa["to"][1]) - 0.4]:
			pts.append(Town.to_godot(bx, y, float(pa["z_from"])))
		pts.append(Town.to_godot(bx, float(st["to"][1]) + 0.6, float(st["z_to"])))
		var wg: Array = sk["ward_gate"]
		pts.append(Town.to_godot(-116.0, float(wg[1]), float(sk["ward"]["z"])))
		pts.append(Town.to_godot(float(wg[0]) + 4.0, float(wg[1]), float(sk["ward"]["z"]) - 0.6))
		current["marks"] = {13: "midspan", 27: "passage", 31: "ward", 32: "ward_gate"}
		# and back (step 8): east to the Yak Gate, down Samkha's north ramp, over the lower bridge and up the south ramp
		# to the south pavilion: the caravan's way backwards (tools/town/graph.py's `caravan`)
		var streets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STREETS))
		var cv: Dictionary = streets["caravan"]
		var up: Array = (streets["routes"][String(cv["up"])] as Dictionary)["p"]
		var ramp: Array = []
		var through := false
		for k in range(0, up.size(), 3):  # through the Yak Gate's arch on its middle (the caravan's line grazes its pier)
			var q := [float(up[k]), float(up[k + 1]), float(up[k + 2])]
			if Vector2(q[0] + 55.0, q[1] + 78.0).length() < 4.0:
				if not through:
					through = true
					ramp.append([-55.0, -81.0, q[2]])
					ramp.append([-55.0, -75.2, q[2]])
				continue
			ramp.append(q)
		var in_gate := 0  # the ramp's point on the town's side of the Yak Gate, where the way from the ward meets it
		for k in ramp.size():
			if Vector2(ramp[k][0] + 60.4, ramp[k][1] + 71.2).length() < Vector2(ramp[in_gate][0] + 60.4, ramp[in_gate][1] + 71.2).length():
				in_gate = k
		pts.append(Town.to_godot(-82.0, -74.6, 2649.5))
		for k in range(in_gate, -1, -1):
			pts.append(Town.to_godot(ramp[k][0], ramp[k][1], ramp[k][2]))
		current["marks"][pts.size() - 1 - (in_gate - _nearest_k(ramp, -56.6, -78.2))] = "yak_gate"
		var dk: Array = (cv["deck"] as Array).duplicate()
		dk.reverse()
		for q in dk:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		current["marks"][pts.size() - 2] = "lower_bridge"
		pts.append(Town.to_godot(-55.0, -120.6, 2624.1))  # off the deck's end clear of its rails before turning up the ramp
		var road: Array = cv["road"]
		for k in range(road.size() - 1, int(cv["road_ramp"]) - 1, -1):
			if Town.to_godot(float(road[k][0]), float(road[k][1]), float(road[k][2])).distance_to(pts[pts.size() - 1]) > 0.3:
				pts.append(Town.to_godot(float(road[k][0]), float(road[k][1]), float(road[k][2])))
		pts.append(Town.to_godot(-127.5, -144.8, float(br["south"][1]) + 0.04))
		current["marks"][pts.size() - 1] = "pavilion"
	elif route_name == "serchu_road":  # M2 sprint 12, steps 1-2: R-01's last kilometre (tools/terrain/serchu_road.py), down
		# the north bank's stretch to the Serchu Zampa, through its gateway chorten and over its deck, down the south bank,
		# past the road chorten SER-20 on its south side to the cliff gallery's east end, and on along the gallery to its
		# west end (data/arrival.json)
		var sr: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/serchu_road.json"))
		var north: Array = (sr.get("north_path", []) as Array).duplicate()
		north.reverse()  # (it runs from the bridge outwards)
		for q in north:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		var n0 := pts.size()
		var path: Array = sr["path"]
		for q in path:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		var road: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/arrival.json"))["road_west"]
		for q in road.slice(2, 3):  # (its line goes on from the gallery's east end, the road's last point)
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		current["marks"] = {maxi(n0 - 2, 0): "chorten", n0: "zampa", n0 + int(path.size() / 2.0): "half", n0 + path.size() - 2: "ser20", pts.size() - 1: "gallery"}
	elif route_name == "mills":  # M2 sprint 12, step 5: the north bank at the mills (tools/town/serchu_mills.py): from R-01
		# down the path's legs on the south bank to the footbridge SER-11, up its steps and over its logs, down onto the north
		# bank, along the Yak Road's first leg under the mills, over the leat's slabs by the upper wheel house, round the
		# switchback and up the second leg's first stretch
		var sm: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/serchu_mills.json"))
		var sp: Array = (sm["south_path"] as Array).duplicate()
		sp.reverse()  # (it runs from the bridge up to the road)
		for q in sp:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		var br: Dictionary = sm["bridge"]
		var th := deg_to_rad(float(br["facing"]))
		var ax := sin(th)
		var ay := cos(th)
		var deck := float(br["deck"])
		var reach := float(br["span"]) / 2.0 + 0.6  # the cribs' outer edges at the deck's level (export_serchu.py CRIB)
		var b0 := pts.size()
		pts.append(Town.to_godot(float(br["at"][0]) - ax * reach, float(br["at"][1]) - ay * reach, deck))
		pts.append(Town.to_godot(float(br["at"][0]) + ax * reach, float(br["at"][1]) + ay * reach, deck))
		var legs: Array = sm["yak_road"]
		var f0 := pts.size()
		for q in legs[0]:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		var c0 := pts.size() - 1
		var l2: Array = legs[1]
		for k in mini(l2.size(), 40):
			pts.append(Town.to_godot(float(l2[k][0]), float(l2[k][1]), float(l2[k][2])))
		current["marks"] = {0: "road", b0: "bridge_s", b0 + 1: "bridge_n", f0: "north_foot", c0: "over_leat", pts.size() - 1: "leg2"}
	elif route_name == "steps":  # M3 sprint 1, step 1: the 1,080 steps (tools/town/dungrong.py): from the Conch Bridge's
		# east end up every flight and landing (data/dungrong.json `walk`: every four metres, round each switchback's landing)
		# to the South Gate's forecourt
		var dg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dungrong.json"))
		var walk: Array = dg["walk"]  # (every 4 m, round each switchback's landing, into the forecourt)
		var land6: Array = []
		for lg in dg["landings"]:
			if String(lg["kind"]) == "platform":
				land6 = lg["at"]
		var best6 := INF
		var k6 := -1
		for q in walk:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
			if not land6.is_empty():
				var dd := Vector2(float(q[0]) - float(land6[0]), float(q[1]) - float(land6[1])).length()
				if dd < best6:
					best6 = dd
					k6 = pts.size() - 1
		current["marks"] = {0: "foot", pts.size() - 2: "top", pts.size() - 1: "forecourt"}
		if k6 >= 0:
			current["marks"][k6] = "landing6"
	elif route_name == "gorge":  # M3 sprint 2, step 1: the Gorge Stair R-07 (tools/town/gorge_stair.py): from the Gorge Rim
		# Lookout's terrace out at its gap, down the west leg's flights and landings, over the upper bridge and up the east
		# leg's to the West Gate (data/gorge_stair.json `walk`)
		var gs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gorge_stair.json"))
		var mid: Array = gs["bridge"]["mid"]
		var kb := -1
		var best := INF
		for q in gs["walk"]:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
			var dd := Vector2(float(q[0]) - float(mid[0]), float(q[1]) - float(mid[1])).length()
			if dd < best:
				best = dd
				kb = pts.size() - 1
		current["marks"] = {0: "lookout", kb: "bridge", pts.size() - 1: "gate"}
	elif route_name == "gonpa":  # M3 sprint 3, step 1: Dungkar Gönpa's way up (tools/town/gonpa_ways.py): from the 1,080 steps'
		# forecourt through the South Gate's passage, up its flights to the bench and along it, through the courtyard's south
		# passage past the darchen, up the Tsokchen's twenty steps onto its porch to the great door
		var gw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gonpa_ways.json"))
		for q in gw["walk"]:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		var in_court := pts.size() - 1
		var c: Array = gw["court"]["at"]
		var cz := float(gw["court"]["z"])
		for q in [[float(c[0]) + 4.5, float(c[1]) - 4.0, cz], [float(c[0]) + 5.0, float(c[1]) + 6.0, cz], [540.0, 120.6, cz], [540.0, 128.6, cz + 4.0], [540.0, 131.2, cz + 4.0]]:  # (east of the darchen's base)
			pts.append(Town.to_godot(q[0], q[1], q[2]))
		current["marks"] = {1: "gate", in_court: "court", pts.size() - 1: "porch"}
	elif route_name == "tsokchen_roof":  # M3 sprint 3, step 1: onto the Tsokchen's roof (V-05, its terrace MON-40): from the
		# courtyard up its twenty steps, east along the platform's front past the wing, up the stair along the east wall, over
		# its slab and down onto the roof beside the lantern (../tibet-blender kit/monastery.py tsokchen: the hall at its pad)
		var pd: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/monastery.json")) as Dictionary)["pads"]["MON-01"]
		var hc := Vector2(float(pd["at"][0]), float(pd["at"][1]))
		var hz := float(pd["level"])
		for q in [[0.0, -31.0, -4.0], [0.0, -29.0, -4.0], [0.0, -22.2, 0.0], [14.3, -22.2, 0.0], [14.3, -16.3, 0.0], [14.3, 3.6, 14.4],
				[12.7, 3.0, 14.4], [11.0, 3.0, 13.9], [8.5, -4.7, 13.9]]:  # (the apron before the wings 2 m deep: kit/monastery.py APRON)
			pts.append(Town.to_godot(hc.x + float(q[0]), hc.y + float(q[1]), hz + float(q[2])))  # (the hall faces 180: kit x, y the town's)
		current["marks"] = {2: "platform", 5: "stair_top", pts.size() - 1: "roof"}
	elif route_name == "chora":  # M3 sprint 3, step 2: into the Chöra (../tibet-blender kit/monastery.py chora): up through the
		# gap between the Tsenyi Dratsang and the court from the south, onto the walk from the college's side door, in at
		# the court's west gate, across its white stone between the poplars to the teacher's platform
		var pds: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/monastery.json")) as Dictionary)["pads"]
		var cz := float(pds["MON-07"]["level"])
		var cc: Array = pds["MON-07"]["at"]
		for q in [[614.5, 52.0, cz - 1.7], [614.0, 60.0, cz - 0.75], [612.0, 72.5, cz], [613.0, 75.0, cz], [617.0, 75.0, cz], [622.0, 75.0, cz],
				[float(cc[0]), float(cc[1]) + 4.5, cz]]:  # (round the geese pen MON-34's east side at the gap's mouth: chapter 02's place)
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		current["marks"] = {3: "walk", 5: "court", pts.size() - 1: "platform"}
	elif route_name == "tode":  # M3 sprint 4, step 1: from the Tödé chorten's forecourt at the Sky Stair's head up Tödé's
		# field paths to the side of the tulku's family house H-TOD-001 (TOD-04), where its pad meets the ground at its level
		# (tools/town/tode.py `ways`: the whole way from the house to the chorten, walked the other way)
		var tj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tode.json"))
		var way: Array = (tj.get("ways", {}) as Dictionary).get(String(OS.get_environment("TODE_HOUSE")) if OS.get_environment("TODE_HOUSE") != "" else "H-TOD-001", [])
		# up the Tödé Stair from the forecourt by the chorten (tools/town/tode_stair.py `walk`; M3 sprint 4, step 2), then the
		# house's way from the stair's top (TODE_SKIP_STAIR=1: the way alone)
		var stair_walk: Array = []
		if FileAccess.file_exists("res://data/tode_stair.json") and OS.get_environment("TODE_SKIP_STAIR") == "":
			stair_walk = (JSON.parse_string(FileAccess.get_file_as_string("res://data/tode_stair.json")) as Dictionary).get("walk", [])
		for q in stair_walk:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		var stair_top := pts.size() - 1
		for k in range(way.size() - 1, -1, -1):
			var q: Array = way[k]
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		current["marks"] = {0: "the forecourt" if not stair_walk.is_empty() else "the stair's top", pts.size() - 1: "house"}
		if stair_top > 0:
			current["marks"][stair_top] = "the stair's top"
	elif route_name == "tsokchen_in":  # M3 sprint 5, step 1: into the Tsokchen's carved hall (tibet-blender kit/monastery.py
		# tsokchen(interior=True); chapter 04, 3.1) and round it clockwise, the hall on the right: in at the great door, west
		# along the front aisle past the tea table, up the west side between the stair and the pillars, round the Nangkor
		# behind the inner chapel, down the east side and back along the front aisle to the stair's foot, up it onto the
		# gallery and along the well's west balustrade; in the hall's frame from its sockets (ROOM_1 the great door's inner
		# face, +y up the hall, +x east)
		var r1 := _sock_town("MON-01", "SOCK_ROOM_1")
		var dr := _sock_town("MON-01", "SOCK_DOOR_1")
		if r1 != Vector3.INF and dr != Vector3.INF:
			var u := Vector2(r1.x - dr.x, r1.y - dr.y).normalized()
			var xv := Vector2(u.y, -u.x)  # the hall's +x (east, its facing 180)
			var at := func(lx: float, ly: float, lz: float = 0.0) -> Vector3:
				var q := Vector2(r1.x, r1.y) + xv * lx + u * ly
				return Town.to_godot(q.x, q.y, r1.z + lz)
			pts.append(Town.to_godot(dr.x - u.x * 2.0, dr.y - u.y * 2.0, dr.z))
			for q in [[0.0, -0.6], [0.0, 1.3], [-6.0, 1.45], [-10.45, 1.45], [-10.45, 11.0], [-11.75, 12.0], [-11.75, 20.3],
					[-11.45, 22.6], [-11.45, 29.7], [0.0, 29.7], [11.45, 29.7], [11.45, 22.6], [11.75, 20.3], [11.75, 10.0],
					[11.75, 1.45], [6.0, 1.45], [0.0, 1.45], [-6.0, 1.45], [-10.45, 1.45], [-11.65, 1.2]]:  # (the front aisle
				# clear of the tea table by the door, its hull to 0.75 m in)
				pts.append(at.call(float(q[0]), float(q[1])))
			var foot := pts.size() - 1
			pts.append(at.call(-11.65, 1.75, 0.2))  # up the stair (its first step 1.5 m in from the front wall)
			pts.append(at.call(-11.65, 10.95, 7.2))
			pts.append(at.call(-11.6, 11.6, 7.2))  # onto the gallery past the stair's head
			pts.append(at.call(-5.0, 11.6, 7.2))
			pts.append(at.call(-4.8, 4.0, 7.2))  # along the well's west balustrade
			current["marks"] = {2: "inside", 6: "west_side", 8: "nangkor", 10: "nangkor_back", foot: "stair_foot", pts.size() - 1: "gallery"}
	elif route_name == "tsokchen_tea":  # M3 sprint 6, step 4: at the general tea (11:00-11:40), in at the great door, west
		# along the front aisle and up into the guest's place at the west rows' door end by the aisle (the nave's SEAT 1,
		# world/hall_tea.gd), in tsokchen_in's frame (ROOM 1, +y up the hall, +x east); there the route sits and takes tea
		var r1 := _sock_town("MON-01", "SOCK_ROOM_1")
		var dr := _sock_town("MON-01", "SOCK_DOOR_1")
		if r1 != Vector3.INF and dr != Vector3.INF:
			var u := Vector2(r1.x - dr.x, r1.y - dr.y).normalized()
			var xv := Vector2(u.y, -u.x)
			pts.append(Town.to_godot(dr.x - u.x * 2.0, dr.y - u.y * 2.0, dr.z))
			for q in [[0.0, -0.6], [0.0, 1.3], [-1.8, 1.45], [-1.8, 2.43]]:
				var g := Vector2(r1.x, r1.y) + xv * float(q[0]) + u * float(q[1])
				pts.append(Town.to_godot(g.x, g.y, r1.z))
	elif route_name == "jampa":  # M3 sprint 5, step 6: into the Jampa Lhakhang (chapter 04, 3.2; tibet-blender kit/monastery.py
		# lhakhang 'maitreya', interior): in at its door, round the throne clockwise by its ambulatory (west, behind it, east),
		# to the stair-ladder in the dark south-west corner, up it through the hatch onto the gallery, south along the west
		# gallery and east along the south one to the rail before the face (V-30); the hall's frame the town's (it faces 180)
		var pd: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/monastery.json")) as Dictionary)["pads"]["MON-04"]
		var jc := Vector2(float(pd["at"][0]), float(pd["at"][1]))
		var jz := float(pd["level"]) + 0.05
		for q in [[0.0, -9.2, -0.05], [0.0, -7.6, -0.05], [0.0, -5.4, 0.0], [-3.3, -3.6, 0.0], [-3.4, 5.6, 0.0], [3.4, 5.6, 0.0], [3.4, -3.6, 0.0],
				[0.0, -4.4, 0.0], [-5.2, -3.4, 0.0], [-6.45, -1.0, 0.0]]:
			pts.append(Town.to_godot(jc.x + float(q[0]), jc.y + float(q[1]), jz + float(q[2])))
		var foot := pts.size() - 1
		var lf := _sock_town("MON-04", "SOCK_LADFOOT_1")
		var lt := _sock_town("MON-04", "SOCK_LADTOP_1")
		var tight := {}
		if lf != Vector3.INF and lt != Vector3.INF:
			pts[foot] = Town.to_godot(lf.x, lf.y - 0.1, lf.z)
			pts.append(Town.to_godot(lt.x, lt.y + 0.45, lt.z))  # off its top onto the gallery
			tight[pts.size() - 1] = true
		for q in [[-5.0, 2.0, 4.5], [-5.0, -1.6, 4.5], [0.0, -1.0, 4.5]]:
			pts.append(Town.to_godot(jc.x + float(q[0]), jc.y + float(q[1]), float(pd["level"]) + float(q[2])))
		current["marks"] = {2: "inside", 5: "behind", foot: "ladder", pts.size() - 1: "face"}
		current["tight"] = tight
	elif route_name == "monk_house":  # M3 sprint 5, step 9: in H-MON-012 on the west face (chapter 04, 3.7): since M3 sprint 6,
		# step 6 (ISS-214) from the Gönkor's west end up its way on the face (data/monastery.json `ways`, tools/town/monastery.py)
		# onto the step before its door and in; to the notched log's foot in its store, up it through the trapdoor into the
		# cell, to its window
		var dr := _sock_town("H-MON-012", "SOCK_DOOR_1")
		var lf := _sock_town("H-MON-012", "SOCK_LOGFOOT_1")
		var lt := _sock_town("H-MON-012", "SOCK_LOGTOP_1")
		var rm := _sock_town("H-MON-012", "SOCK_ROOM_2")
		var mj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/monastery.json"))
		var way: Array = (mj.get("ways", {}) as Dictionary).get("H-MON-012", [])
		if dr != Vector3.INF and lf != Vector3.INF and lt != Vector3.INF and rm != Vector3.INF:
			var u := Vector2(lf.x - dr.x, lf.y - dr.y).normalized()  # (in from the door towards the log's foot, clear of the wall)
			for k in range(way.size() - 1, -1, -1):  # up from the Gönkor's west end to the end of the step before the door
				pts.append(Town.to_godot(float(way[k][0]), float(way[k][1]), float(way[k][2])))
			pts.append(Town.to_godot(dr.x - u.x * 0.9, dr.y - u.y * 0.9, dr.z))  # along the step to before the door
			var n0 := pts.size()
			pts.append(Town.to_godot(dr.x + u.x * 1.7, dr.y + u.y * 1.7, dr.z + 0.05))
			var uk := Vector2(lt.x - lf.x, lt.y - lf.y).normalized()
			pts.append(Town.to_godot(lf.x - uk.x * 0.3, lf.y - uk.y * 0.3, lf.z))
			pts.append(Town.to_godot(lf.x - uk.x * 0.1, lf.y - uk.y * 0.1, lf.z))
			var b := Vector2(lt.x, lt.y) + uk * 0.4
			pts.append(Town.to_godot(b.x, b.y, lt.z))
			current["tight"] = {pts.size() - 1: true}
			var hn := get_node_or_null("Town/H-MON-012") as Node3D
			if hn != null:  # on across the cell round the hatch's open side to its window (the kit's frame: x, z, -y), clear of the
				# log's top, where walking back towards it mounts it (player.gd _try_ladder, within 0.9 m of the step off)
				pts.append(hn.to_global(Vector3(1.2, 2.45, 0.8)))
				pts.append(hn.to_global(Vector3(0.0, 2.45, 1.4)))
			current["marks"] = {0: "gonkor_end", n0 - 1: "door_step", n0: "store", n0 + 3: "cell", pts.size() - 1: "window"}  # (the walker crosses the cell
			# since its details' hull, which had filled the cell's back half, was taken out: 12 Oct 2026)
	elif route_name == "labrang":  # M3 sprint 5, step 9: up the Labrang to the tulku's reception (chapter 04, 3.8; tibet-blender
		# kit/monastery.py labrang, interior): up its front steps, in at the door, through the entrance hall to the stairwell's
		# west end, up the three flights round the spine wall (east, west, east), off the top landing through the door into the
		# reception and across it towards the throne; in its frame (it faces 218 degrees)
		var pd: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/monastery.json")) as Dictionary)["pads"]["MON-09"]
		var lc := Vector2(float(pd["at"][0]), float(pd["at"][1]))
		var lz := float(pd["level"])
		var f := deg_to_rad(float(pd["facing"]))
		var ex := Vector2(-cos(f), sin(f))
		var ey := Vector2(-sin(f), -cos(f))
		for q in [[0.0, -9.6, 0.0], [0.0, -8.6, 0.0], [0.0, -6.0, 0.05], [-2.5, -1.0, 0.05], [-2.6, 1.0, 0.05], [2.6, 1.0, 3.0], [2.8, 2.4, 3.0], [1.4, 2.3, 3.4],
				[-2.7, 2.3, 6.0], [-2.8, 0.9, 6.0], [-1.4, 0.95, 6.4], [2.6, 1.0, 9.0], [2.6, 0.4, 9.0], [2.6, -1.4, 9.0], [4.6, -3.3, 9.0]]:
			var v: Vector2 = lc + ex * float(q[0]) + ey * float(q[1])
			pts.append(Town.to_godot(v.x, v.y, lz + float(q[2])))
		current["marks"] = {2: "hall", 5: "first_floor", 8: "second_floor", 11: "landing", 13: "reception"}
	elif route_name == "parkhang":  # M3 sprint 5, step 8: through the Parkhang (chapter 04, 3.6; tibet-blender kit/dungrong.py
		# parkhang, interior): up the hollow beside the 1,080 steps' first flight to its back door, through the stair hall and
		# out under the arcade into the court, out at the south gate onto its apron and back in, up the stair-ladder from the
		# hall to the printing room, along it into the chapel and out, up the second from its east end to the block store and
		# down the canyon's middle aisle to the window at its far end; in its own frame (it faces 160 degrees)
		var pk := get_node_or_null("Town/RNG-10") as Node3D
		if pk != null:
			var kp := func(x: float, y: float, z: float) -> Vector3: return pk.to_global(Vector3(x, z, -y))
			var tight := {}
			var marks := {}
			# (since M3 sprint 6, step 6, ISS-215: up the 1,080 steps' first flight from the Conch Bridge onto landing 1, off it
			# through the gap in its wall along the flagged walk to the back door; out at the south gate onto its forecourt)
			var dj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dungrong.json"))
			var lj := {}
			for ln in dj["lanes"]:
				lj[String(ln["id"])] = ln
			for lid in ["R04.F01", "R04.P01"]:
				if not lj.has(lid):
					continue
				var ln: Dictionary = lj[lid]
				var o := Vector2(float(ln["from"][0]), float(ln["from"][1]))
				var dv := Vector2(float(ln["dir"][0]), float(ln["dir"][1]))
				if lid == "R04.F01":  # its foot a pace up from the bridge's end, its top onto the landing
					pts.append(Town.to_godot(o.x + dv.x * 1.0, o.y + dv.y * 1.0, float(ln["z_a"]) + 0.2))
					pts.append(Town.to_godot(o.x + dv.x * (float(ln["length"]) + 1.2), o.y + dv.y * (float(ln["length"]) + 1.2), float(ln["z_b"])))
				else:  # the walk from the landing's middle line to its far end at the apron
					pts.append(Town.to_godot(o.x - dv.x * 1.2, o.y - dv.y * 1.2, float(ln["z_a"])))
					pts.append(Town.to_godot(o.x + dv.x * float(ln["length"]), o.y + dv.y * float(ln["length"]), float(ln["z_a"])))
			marks[0] = "steps_foot"
			var nb := pts.size()
			for q in [[0.0, 10.4, 0.05], [0.0, 9.3, 0.05],
					[0.6, 8.2, 0.05], [0.4, 5.6, 0.05], [0.0, 4.4, 0.05], [0.0, 2.9, 0.06], [0.0, -2.0, 0.06], [0.0, -6.5, 0.06], [0.0, -10.8, 0.06], [0.0, -14.0, 0.06],
					[0.0, -10.8, 0.06], [0.0, -6.5, 0.06], [0.0, -2.0, 0.06], [0.0, 2.9, 0.06], [0.0, 4.4, 0.05], [0.0, 5.15, 0.05], [-0.85, 5.05, 0.05]]:
				pts.append(kp.call(float(q[0]), float(q[1]), float(q[2])))
			marks[nb - 2] = "landing_1"
			marks[nb + 1] = "back_door"
			marks[nb + 5] = "court"
			marks[nb + 9] = "forecourt"
			for k in [1, 2]:
				var lf := pk.find_child("SOCK_LADFOOT_%d" % k, true, false) as Node3D
				var lt := pk.find_child("SOCK_LADTOP_%d" % k, true, false) as Node3D
				if lf == null or lt == null:
					break
				var d := Vector3(lt.global_position.x - lf.global_position.x, 0.0, lt.global_position.z - lf.global_position.z).normalized()
				pts.append(lf.global_position - d * 0.1)
				if k == 1:
					marks[pts.size() - 1] = "ladder"
				pts.append(lt.global_position + d * 0.45)  # off its top onto the floor
				tight[pts.size() - 1] = true
				if k == 1:
					marks[pts.size() - 1] = "printing"
					for q in [[0.9, 7.55, 4.0], [1.3, 6.5, 4.0], [9.6, 6.5, 4.0], [10.45, 5.6, 4.0], [10.45, 4.3, 4.0], [10.45, 2.0, 4.0], [10.45, 4.3, 4.0],
							[10.45, 5.7, 4.0], [11.2, 6.6, 4.0], [12.75, 6.6, 4.0], [12.75, 7.2, 4.0]]:
						pts.append(kp.call(float(q[0]), float(q[1]), float(q[2])))
					marks[pts.size() - 6] = "chapel"
				else:
					marks[pts.size() - 1] = "canyon"
					for q in [[9.0, 7.2, 7.4], [0.0, 7.2, 7.4], [-12.0, 7.2, 7.4], [-12.75, 7.2, 7.4]]:
						pts.append(kp.call(float(q[0]), float(q[1]), float(q[2])))
					marks[pts.size() - 1] = "window"
			current["marks"] = marks
			current["tight"] = tight
	elif route_name in ["gonkhang", "kangyur", "jakhang", "boots"]:  # M3 sprint 5, steps 7-8: in at the door, through to the far side
		# and back (the Gönkhang through its vestibule and its second curtain; the library to its reading table; the Jakhang to
		# the great cauldron's steps); "boots" (M3 sprint 6, step 2): into the Gönkhang and out again into its forecourt, the
		# boots off at its room and on again under the sky (world/boots.gd; its lines in the log)
		var hid: String = {"gonkhang": "MON-05", "kangyur": "MON-14", "jakhang": "MON-12", "boots": "MON-05"}[route_name]
		var pd: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/monastery.json")) as Dictionary)["pads"][hid]
		var hc := Vector2(float(pd["at"][0]), float(pd["at"][1]))
		var hz := float(pd["level"]) + 0.05
		var qs: Array = {"gonkhang": [[0.0, -8.0, -0.05], [0.0, -5.6, -0.05], [0.0, -3.6, 0.0], [0.0, -1.2, 0.0], [-3.2, -1.0, 0.0], [-3.2, 1.2, 0.0], [3.2, 1.2, 0.0],
					[3.2, -1.0, 0.0], [0.0, -1.5, 0.0]],
				"kangyur": [[0.0, -9.0, -0.05], [0.0, -6.4, -0.05], [0.0, -3.4, 0.0], [1.4, -1.0, 0.0], [1.4, 1.75, 0.0], [0.0, -3.0, 0.0]],
				"jakhang": [[-3.5, -8.6, -0.05], [-3.5, -6.4, -0.05], [-3.5, -3.8, 0.0], [0.0, -3.0, 0.0], [5.6, -3.0, 0.0], [5.6, 0.6, 0.0], [-3.5, -3.4, 0.0]],
				"boots": [[0.0, -8.0, -0.05], [0.0, -5.6, -0.05], [0.0, -3.6, 0.0], [0.0, -1.2, 0.0], [0.0, -3.6, 0.0], [0.0, -5.6, -0.05], [0.0, -6.6, -0.05]]}[route_name]
		for q in qs:
			pts.append(Town.to_godot(hc.x + float(q[0]), hc.y + float(q[1]), hz + float(q[2])))
		current["marks"] = {2: "inside", pts.size() - 2: "far"}
	elif route_name == "chapel":  # M3 sprint 4, step 6: the Bön chapel TOD-02's circuit R-24 (tools/town/tode_things.py
		# `circuit`): from its path's end beside its terrace onto the paving, once round it anticlockwise past the wheels in
		# their niches by its door, and back to the path
		var tj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tode.json"))
		var way: Array = (tj.get("ways", {}) as Dictionary).get("TOD-02", [])
		var circ: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://data/tode_things.json")) as Dictionary).get("circuit", [])
		if not way.is_empty() and not circ.is_empty():
			var w0 := Vector2(float(way[0][0]), float(way[0][1]))
			var k0 := 0
			for k in circ.size():
				if Vector2(float(circ[k][0]), float(circ[k][1])).distance_to(w0) < Vector2(float(circ[k0][0]), float(circ[k0][1])).distance_to(w0):
					k0 = k
			pts.append(Town.to_godot(float(way[0][0]), float(way[0][1]), float(way[0][2])))
			for i in circ.size() + 1:
				var q: Array = circ[(k0 + i) % circ.size()]
				pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
			pts.append(Town.to_godot(float(way[0][0]), float(way[0][1]), float(way[0][2])))
			current["marks"] = {1: "on the circuit", circ.size() + 1: "round", pts.size() - 1: "the path"}
	elif route_name == "tower":  # M3 sprint 4, step 3: the Tödé tower TOD-01 (chapter 03, 12.1; ../tibet-blender kit/tode.py
		# star_tower, placed by world/town.gd at tools/town/tode.py's place): from its path's end beside its pad (data/tode.json
		# `ways` TOD-01) round to the foot of the notched log before its door, up the log onto its sill 6 m up and in, then on
		# each floor from the last log's top past the hatch it came up through to the next log's foot, up through every hatch
		# to its top, V-12 (its sockets: SOCK_LOGFOOT_k, SOCK_LOGTOP_k, k 1-8 inside and 9 outside, SOCK_TOP_1)
		var tj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tode.json"))
		var way: Array = (tj.get("ways", {}) as Dictionary).get("TOD-01", [])
		if not way.is_empty():
			pts.append(Town.to_godot(float(way[0][0]), float(way[0][1]), float(way[0][2])))
		var f9 := _sock_town("TOD-01", "SOCK_LOGFOOT_9")
		var t9 := _sock_town("TOD-01", "SOCK_LOGTOP_9")
		if f9 != Vector3.INF and t9 != Vector3.INF:
			var u := Vector2(t9.x - f9.x, t9.y - f9.y).normalized()  # the log's way in, towards the door (the kit's +y)
			var side := Vector2(u.y, -u.x)
			if not way.is_empty() and (Vector2(float(way[0][0]), float(way[0][1])) - Vector2(f9.x, f9.y)).dot(side) < 0.0:
				side = -side
			for q in [[side * 4.5 - u * 2.0, f9.z], [-u * 1.6, f9.z], [-u * 0.4, f9.z]]:  # round the pad's front corner to the foot
				var v: Vector2 = Vector2(f9.x, f9.y) + (q[0] as Vector2)
				pts.append(Town.to_godot(v.x, v.y, float(q[1])))
			for q in [[Vector2(t9.x, t9.y) + u * 0.3, t9.z], [Vector2(t9.x, t9.y) + u * 1.2, t9.z]]:  # on the sill, through the door
				pts.append(Town.to_godot((q[0] as Vector2).x, (q[0] as Vector2).y, float(q[1])))
			var marks := {pts.size() - 1: "door"}
			var tight := {}
			for k in range(1, 9):
				var f := _sock_town("TOD-01", "SOCK_LOGFOOT_%d" % k)
				var t := _sock_town("TOD-01", "SOCK_LOGTOP_%d" % k)
				var uk := Vector2(t.x - f.x, t.y - f.y).normalized()
				pts.append(Town.to_godot(f.x - uk.x * 0.1, f.y - uk.y * 0.1, f.z))  # at the log's foot (the upper rooms are some 4 m
				# across: a point further behind it stood in the wall)
				var b := Vector2(t.x, t.y) + uk * 0.4  # off its top at the hatch's far edge onto the floor above
				pts.append(Town.to_godot(b.x, b.y, t.z))
				tight[pts.size() - 1] = true
				var nxt := _sock_town("TOD-01", "SOCK_LOGFOOT_%d" % (k + 1)) if k < 8 else _sock_town("TOD-01", "SOCK_TOP_1")
				var sk := Vector2(uk.y, -uk.x)  # then sideways, towards the next log's side, clear of the hatch behind
				if (Vector2(nxt.x, nxt.y) - Vector2(t.x, t.y)).dot(sk) < 0.0:
					sk = -sk
				var m := b + sk * 1.2
				pts.append(Town.to_godot(m.x, m.y, t.z))
				marks[pts.size() - 1] = "floor_%d" % (k + 1) if k < 8 else "top"
			var top := _sock_town("TOD-01", "SOCK_TOP_1")
			pts.append(Town.to_godot(top.x, top.y, top.z))
			marks[pts.size() - 1] = "V-12"
			current["marks"] = marks
			current["tight"] = tight
	elif route_name == "leat":  # M3 sprint 4, step 4: the leat walk R-12's first stretch along Tödé's leat TOD-10 on the contour
		# (tools/town/tode_leat.py `walk`, beside the channel on its shelf), from where it comes into the quarter in the east to
		# where the leat turns down over the upper mill
		var lj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tode_leat.json"))
		for q in lj.get("walk", []):
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		current["marks"] = {0: "east", pts.size() - 1: "over the mill"}
	elif route_name == "gonkor":  # M3 sprint 3, step 6: the Gönkor's south stretch (tools/town/monastery.py `lanes`, MON-K),
		# walked clockwise: from its east end westward through the eight wheel galleries along the wall, the wheels on the
		# right hand, each lane's end a point; then (M3 sprint 7, step 1) on round the rest of the circuit (data/gonkor.json
		# `loop`, laid anticlockwise: walked backwards): along the face to the 1,080 steps' landing 20 and up their last
		# three flights to the forecourt, along the face's shelf and gallery to the Gorge Stair's landing 23 and up its last
		# flight to the West Gate, round the wall's west end and up the north side behind the Labrang, down the east side
		# to the great wheel house's door and past the tsa-tsa house to the south stretch's east end again. GONKOR_SOUTH=1
		# for the south stretch alone
		var mj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/monastery.json"))
		var wy := float((mj.get("gonkor", {}) as Dictionary).get("walk_y", -41.7))  # (the walk's middle, not its bed's)
		for ln in mj.get("lanes", []):
			if not bool(ln.get("gonkor", false)):
				continue  # (the hero monk's house's way, MON-H, leaves its west end: M3 sprint 6, step 6)
			if pts.is_empty():
				pts.append(Town.to_godot(float(ln["from"][0]), wy, float(ln["z_a"])))
			var e := float(ln["from"][0]) + float(ln["dir"][0]) * float(ln["length"])
			pts.append(Town.to_godot(e, wy, float(ln["z_b"])))
		var marks := {0: "east end", pts.size() - 1: "west end"}
		if OS.get_environment("GONKOR_SOUTH") != "1" and FileAccess.file_exists("res://data/gonkor.json"):
			var gk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gonkor.json"))
			var lp: Array = gk["loop"]
			var named := {}  # the places along it (tools/town/gonkor.py `marks`)
			for nm in gk.get("marks", {}):
				named[nm] = Vector2(float(gk["marks"][nm][0]), float(gk["marks"][nm][1]))
			for k in range(lp.size() - 1, -1, -1):
				var q: Array = lp[k]
				pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
				for nm in named:
					if Vector2(float(q[0]), float(q[1])).distance_to(named[nm]) < 1.5 and not marks.values().has(nm):
						marks[pts.size() - 1] = nm
			marks[pts.size() - 1] = "east end again"
			var from := OS.get_environment("GONKOR_FROM")  # (from a place along it by name, `marks`: GONKOR_FROM="West Gate", or a
			if from.is_valid_int():  # point's number in the whole walk: GONKOR_FROM=250)
				marks[int(from)] = "from"
				from = "from"
			if from != "":
				for k in marks:
					if String(marks[k]) == from:
						pts = pts.slice(int(k))
						var m2 := {}
						for k2 in marks:
							if int(k2) >= int(k):
								m2[int(k2) - int(k)] = marks[k2]
						marks = m2
						break
		current["marks"] = marks
	elif route_name == "gorge_water":  # M3 sprint 2, step 6: the way down to the water (tools/town/gorge_stair.py `water`):
		# from the raw bridge's middle off its west end, south round the back of its abutment, down the two flights to the
		# landing by the wheel's channel's head, and back up onto the bridge
		var gw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gorge_stair.json"))
		var bw: Dictionary = gw["bridge"]
		var on_deck := func(q: Array) -> Vector3: return Town.to_godot(float(q[0]), float(q[1]), float(bw["deck"]))
		pts.append(on_deck.call(bw["mid"]))
		pts.append(on_deck.call(bw["w_end"]))
		var wp: Array = gw["water"]["path"]
		for q in wp:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		var at_water := pts.size() - 1
		for k in range(wp.size() - 2, -1, -1):
			pts.append(Town.to_godot(float(wp[k][0]), float(wp[k][1]), float(wp[k][2])))
		pts.append(on_deck.call(bw["mid"]))
		current["marks"] = {0: "bridge", at_water: "water", pts.size() - 1: "back"}
	elif route_name == "castle_ramp":  # M2 sprint 11, step 1: the Castle Ramp SAM-10 (tools/town/castle_ramp.py): from the
		# ward by the passage's steps, out at the ward's gate and north round its corner, down the three legs and round their
		# landings through their middles, through Hejie's East Gate into the square inside it; and back up to the ward
		var sk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/samkha.json"))
		var cr: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/castle_ramp.json"))
		var wz := float(sk["ward"]["z"])
		var wg: Array = sk["ward_gate"]
		var path: Array = cr["path"]
		pts.append(Town.to_godot(-130.0, -74.5, wz))
		pts.append(Town.to_godot(-116.0, float(wg[1]), wz))
		pts.append(Town.to_godot(float(wg[0]) + 1.8, float(wg[1]), float(path[0][2])))  # out through the gate's middle
		for k in range(1, path.size()):
			pts.append(Town.to_godot(float(path[k][0]), float(path[k][1]), float(path[k][2])))
		var foot := pts.size() - 2
		pts.append(Town.to_godot(-223.0, -80.5, 2597.6))  # through the gate tower's passage (HEJ-02)
		pts.append(Town.to_godot(-231.0, -79.0, 2596.0))  # in the square inside it (HEJ-35)
		current["marks"] = {2: "ward_gate", 4: "landing1", 8: "landing2", foot: "foot", pts.size() - 1: "square"}
		var back := pts.slice(1, pts.size() - 1)
		back.reverse()
		pts.append_array(back)
		current["marks"][pts.size() - 4] = "up_landing1"  # the first leg's end, going up
	elif route_name == "castle_lane":  # M2 sprint 11, step 2: Samkha's houses (tools/town/builder.py `samkha`): from the
		# castle ward's gate north by Dechen-tsang's wall to Castle Lane's head, down its four terraces' steps between the
		# retainers' houses to its end over the ramp, back up, and along the ward's north wall to the poor houses' doors
		var cl: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://data/town_lanes.json"))["lanes"] as Array).filter(
				func(ln): return String(ln["id"]).begins_with("CL-"))
		cl.sort_custom(func(a, b): return String(a["id"]) < String(b["id"]))
		pts.append(Town.to_godot(-107.8, -73.5, 2648.4))
		pts.append(Town.to_godot(-109.8, -60.0, 2646.5))
		var down := []
		for ln in cl:  # each lane from its head (towards the castle) down to its foot
			var o := Vector2(float(ln["from"][0]), float(ln["from"][1]))
			var u := Vector2(float(ln["dir"][0]), float(ln["dir"][1]))
			var head := o + u * float(ln["length"])
			down.append(Town.to_godot(head.x, head.y, float(ln["z_b"])))
			var mid := o + u * minf(3.0, float(ln["length"]) / 2.0)
			down.append(Town.to_godot(mid.x, mid.y, float(ln["z_a"])))
		pts.append_array(down)
		current["marks"] = {2: "lane_head", 6: "lane_mid", pts.size() - 1: "lane_end"}
		var up := down.slice(0, down.size() - 1)
		up.reverse()
		pts.append_array(up)
		pts.append(Town.to_godot(-109.8, -60.0, 2646.5))
		pts.append(Town.to_godot(-120.0, -59.5, 2645.0))
		var poor: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://data/town_generic.json"))["houses"] as Array).filter(
				func(h): return String(h["quarter"]) == "samkha.rock")
		for h in poor:  # in each yard, before its door (each faces north, its front 2.5 m from its middle)
			pts.append(Town.to_godot(float(h["pos"][0]), float(h["pos"][1]) + 2.5 + 0.6, float(h["pos"][2])))
		current["marks"][pts.size() - 3] = "poor"
	elif route_name == "ula_yard":  # M2 sprint 11, step 3: from Castle Lane's foot over the saddle to the ula yard's gate
		# (kit/samkha.py ula_yard; its place data/castle_ramp.json pads SAM-09), in, round the yard by the rings and the
		# trough to the stables' door, and out again
		var cl: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://data/town_lanes.json"))["lanes"] as Array).filter(
				func(ln): return String(ln["id"]) == "CL-04")
		var yd: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/castle_ramp.json"))["pads"]["SAM-09"]
		var c := Vector2(float(yd["at"][0]), float(yd["at"][1]))
		var th := deg_to_rad(float(yd["facing"]) - 180.0)
		var ax := Vector2(cos(th), -sin(th))  # the yard's x (along its front) and y (to its back) in the town grid
		var ay := Vector2(sin(th), cos(th))
		var lz := float(yd["level"])
		var at := func(u: float, v: float, z: float) -> Vector3:
			var q: Vector2 = c + ax * u + ay * v
			return Town.to_godot(q.x, q.y, z)
		if not cl.is_empty():
			var o := Vector2(float(cl[0]["from"][0]), float(cl[0]["from"][1]))
			var u := Vector2(float(cl[0]["dir"][0]), float(cl[0]["dir"][1]))
			pts.append(Town.to_godot((o + u * 2.0).x, (o + u * 2.0).y, float(cl[0]["z_a"])))
		for q in [[21.0, 0.0, lz + 1.2], [17.0, 0.0, lz + 0.4], [13.0, 0.0, lz], [4.0, -4.0, lz], [-6.0, -5.0, lz], [-11.0, 2.0, lz],
				[-6.0, 7.0, lz], [-6.0, 8.6, lz], [3.0, 6.0, lz], [13.0, 0.0, lz], [17.0, 0.0, lz + 0.4], [21.0, 0.0, lz + 1.2]]:
			pts.append(at.call(q[0], q[1], q[2]))
		current["marks"] = {3: "gate", 7: "trough", 9: "stable_door"}
	elif route_name == "court":  # M2 sprint 4, step 7: from the gate passage by the house's door into the stair hall, up
		# the stair into the court hall, round the stair's opening to the petitioners' felt and up to the dais's foot (the
		# castle's frame: kit/samkha.py; its origin data/samkha.json's castle)
		var sk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/samkha.json"))
		var c: Array = sk["castle"]["at"]
		var zc := float(sk["castle"]["z"])
		for q in [[0.0, -3.0, 1.5], [0.6, -1.6, 1.5], [3.0, -1.6, 1.5], [4.3, 0.4, 1.5], [5.6, 0.4, 1.5], [5.6, -0.6, 1.5],
				[5.6, -2.6, 3.0], [5.6, -4.3, 4.7], [4.4, -4.2, 4.7], [3.0, -3.2, 4.7], [0.0, -1.8, 4.7], [0.0, 3.5, 4.7]]:
			pts.append(Town.to_godot(float(c[0]) + q[0], float(c[1]) + q[1], zc + q[2]))
		current["marks"] = {2: "door", 4: "stair_foot", 7: "stair_head", 10: "felt", 11: "dais"}
	elif route_name == "netsang":  # M2 sprint 5, step 7 (chapter 08, V-02's approach): from Dechen-tsang's gate down Nétsang
		# Lam (R-08) east below Tsongra and the trading houses, down the ramp into Pema Ö's forecourt, behind the left
		# chorten and down the temple's stair to the Conch terrace, to V-02's place at its lip
		for q in [[-75.0, -67.5], [-40.0, -68.0], [0.0, -62.0], [40.0, -64.0], [80.0, -66.0], [120.0, -68.0], [149.0, -69.6]]:
			pts.append(Town.to_godot(q[0], q[1], 2660.0))
		var th := deg_to_rad(180.0 - 140.0)
		for q in [[-11.0, -9.4, 0.0], [-8.0, -7.9, 0.0], [-2.0, -8.6, 0.0], [0.0, -12.3, 0.0], [0.0, -28.4, -6.0], [0.0, -31.0, -6.0]]:
			pts.append(Town.to_godot(165.0 + q[0] * cos(th) - q[1] * sin(th), -55.0 + q[0] * sin(th) + q[1] * cos(th), 2670.0 + q[2]))
		pts.append(Town.to_godot(199.0, -90.4, 2664.0))
		current["marks"] = {6: "ramp_top", 7: "forecourt", 10: "stair_head", 11: "stair_foot", 13: "v02"}
	elif route_name == "pema_o":  # M2 sprint 5, step 4: from the Conch terrace up Pema Ö's stair between the chortens, through
		# its porch into the hall to the altar's foot, out again, round its kora corridor clockwise turning the wheels, and down
		# (the temple's frame: kit/confluence.py; its middle the gazetteer's (165, -55), its floor 2,670 m, facing 140 degrees)
		var th := deg_to_rad(180.0 - 140.0)  # world/town.gd turns the kit's frame by -(facing - 180) about Godot's y
		for q in [[0.0, -31.0, -6.0], [0.0, -28.4, -6.0], [0.0, -12.3, 0.0], [0.0, -7.6, 0.0], [0.0, -4.6, 0.0], [0.0, -2.0, 0.0],
				[0.0, 3.4, 0.0], [0.0, -2.0, 0.0], [0.0, -6.2, 0.0], [-0.4, -7.9, 0.0], [-8.95, -7.9, 0.0], [-8.95, 7.95, 0.0],
				[8.95, 7.95, 0.0], [8.95, -7.9, 0.0], [0.4, -7.9, 0.0], [0.0, -12.3, 0.0], [0.0, -28.4, -6.0], [0.0, -31.0, -6.0]]:
			var x := float(q[0]) * cos(th) - float(q[1]) * sin(th)
			var y := float(q[0]) * sin(th) + float(q[1]) * cos(th)
			pts.append(Town.to_godot(165.0 + x, -55.0 + y, 2670.0 + float(q[2])))
		current["marks"] = {2: "stair_head", 4: "door", 6: "altar", 10: "kora_in", 13: "kora_out", 16: "stair_foot"}
	elif route_name == "spring":  # M2 sprint 6, step 3: up the path from upper Shöl's lanes to the Lukhang spring, in at its
		# way in, to the spouts' basin and before the naga's niche (the yard's frame: kit/spring.py, its middle (-110, 234.5)
		# at 2,775 m, facing 190 degrees)
		for q in [[-84.0, 231.0, 2767.0], [-86.0, 233.3, 2769.0], [-90.0, 235.3, 2771.7], [-98.0, 235.3, 2773.6],
				[-101.4, 234.6, 2774.4]]:
			pts.append(Town.to_godot(q[0], q[1], q[2]))
		var th := deg_to_rad(180.0 - 190.0)
		for q in [[5.0, -2.5], [2.6, 0.2], [0.78, 1.2], [0.0, 1.2]]:
			pts.append(Town.to_godot(-110.0 + q[0] * cos(th) - q[1] * sin(th), 234.5 + q[0] * sin(th) + q[1] * cos(th), 2775.0))
		current["marks"] = {2: "path", 5: "way_in", 7: "spout", 8: "naga"}
	elif route_name == "lingkor_west":  # M2 sprint 6, step 6: once round the western mani wall's first section, clockwise:
		# up the bed's west side, through the way to the next wall, down its east side (tools/terrain/pads.py STAIRS "SHL-10",
		# tools/town/mani.py WEST_SECTIONS); the bed at an even grade from 2,624 m at (-320, 62), 260 m at 352 degrees
		var u := Vector2(sin(deg_to_rad(352.0)), cos(deg_to_rad(352.0)))
		for q in [[-4.0, -2.2], [20.0, -2.2], [40.0, -2.2], [63.5, -2.2], [63.5, 2.2], [40.0, 2.2], [20.0, 2.2], [0.8, 2.2]]:
			var sl: float = q[0]
			var lat: float = q[1]
			var xy := Vector2(-320.0, 62.0) + u * sl + Vector2(u.y, -u.x) * lat
			pts.append(Town.to_godot(xy.x, xy.y, 2624.0 + 121.9 * clampf(sl, 0.0, 260.0) / 260.0))
		current["marks"] = {3: "top_west", 4: "top_east", 7: "foot_east"}
	elif route_name == "headman":  # M2 sprint 7, step 1: the headman's house SHL-19, every floor (chapter 04, 4.1): in at the
		# yard's gate, into the stable under its low lintel, up the notched log through the kitchen's trapdoor, through the
		# kitchen to the hall, into the reception room and the grain room, up the stair to the second floor's hall, into the
		# shrine room, the two bedrooms and the guest room to its bay, up the log through the hatch onto the roof and into the
		# mistress's room there; down again, out at the family's door and down the outside stair to the gate (its frame:
		# tibet-blender kit/headman.py; its middle the gazetteer's (-95, 30) at 2,655 m, facing 180, so unturned)
		for q in [[7.0, -7.3, 0.0], [4.5, -7.3, 0.0], [-3.3, -6.4, 0.0], [-3.3, -3.4, 0.06], [-2.9, -2.1, 0.06], [2.2, -2.1, 0.06],
				[2.2, 0.2, 0.06], [3.4, 0.4, 0.06], [4.6, 1.8, 0.06], [4.75, 3.4, 0.06], [3.1, 3.4, 2.45], [2.3, 2.6, 2.45],
				[1.6, 2.2, 2.45], [0.2, 2.2, 2.45], [-0.1, 1.2, 2.45], [-0.1, 0.4, 2.45], [-0.1, -1.1, 2.45], [-0.05, -1.6, 2.45],
				[1.5, -1.6, 2.45], [1.5, -2.9, 2.45], [2.9, -3.2, 2.45], [1.5, -2.9, 2.45], [1.5, -1.6, 2.45], [-0.05, -1.6, 2.45],
				[-0.3, -3.7, 2.45], [-2.4, -3.7, 2.45], [-3.4, -1.5, 2.45], [-2.4, -3.7, 2.45], [-0.95, -3.75, 2.45], [-0.95, -0.1, 5.15],
				[-0.95, 0.9, 5.15], [-2.4, 0.9, 5.15], [-2.6, 2.5, 5.15], [-2.4, 0.9, 5.15], [1.4, 0.9, 5.15], [2.4, 1.5, 5.15],
				[1.4, 0.9, 5.15], [0.0, 0.6, 5.15], [0.0, -2.0, 5.15], [1.4, -2.0, 5.15], [2.4, -1.8, 5.15], [1.4, -2.0, 5.15],
				[0.0, -2.6, 5.15], [-0.3, -3.65, 5.15], [-2.4, -3.65, 5.15], [-3.3, -2.4, 5.15], [-3.4, -3.4, 5.15], [-2.4, -3.65, 5.15],
				[-0.3, -3.65, 5.15], [0.05, -2.6, 5.15], [0.05, 2.0, 5.15], [0.05, 3.85, 5.15], [-0.55, 3.85, 5.15], [-0.55, 2.0, 8.15],
				[-0.55, 0.9, 8.15], [0.5, -2.14, 8.15], [1.7, -2.14, 8.21], [2.9, -2.0, 8.21], [1.7, -2.14, 8.21], [0.5, -2.14, 8.15],
				[-0.55, 0.4, 8.15], [-0.55, 1.3, 8.15], [-0.55, 3.9, 5.15], [0.05, 3.6, 5.15], [0.05, 0.4, 5.15], [-0.95, 0.3, 5.15],
				[-0.95, -3.75, 2.45], [-0.53, -3.6, 2.45], [-0.53, -5.35, 2.3], [-0.1, -5.53, 2.3], [3.6, -5.53, 0.0], [4.5, -7.3, 0.0],
				[7.0, -7.3, 0.0]]:
			pts.append(Town.to_godot(-95.0 + float(q[0]), 30.0 + float(q[1]), 2655.0 + float(q[2])))
		current["marks"] = {3: "stable", 10: "log_top", 12: "kitchen", 20: "reception", 26: "grain", 29: "stair_head", 32: "shrine", 35: "bed1", 40: "bed2", 46: "guest_bay", 53: "hatch", 57: "roof_room", 68: "family_door", 71: "yard"}
		current["tight"] = {2: true, 9: true, 15: true, 17: true, 22: true, 24: true, 27: true, 28: true, 30: true, 33: true, 36: true, 38: true, 41: true, 43: true, 47: true, 52: true, 55: true, 58: true, 60: true, 65: true, 67: true}  # straight at each doorway with a sill (its step over) and at each log's foot or top
	elif route_name in ["headman_tea", "headman_dog", "headman_seat"]:  # M2 sprint 7, step 5: the headman's house's moments
		# (world/headman_house.gd, world/tea.gd): in at the yard's gate past the mastiff (headman_dog: stop in the yard and call
		# to the house, _headman_tick), up the outside stair, over the family's sill and into the reception room over its own:
		# to the lower bench's guest seat for tea (headman_tea, poured by the mistress from the head of the room at 15:30), or
		# to the headman's bench at its head, where sitting is refused (headman_seat)
		var q := [[7.0, -7.3, 0.0], [4.5, -7.3, 0.0]]
		if route_name != "headman_dog":
			q += [[3.6, -5.53, 0.0], [-0.1, -5.53, 2.3], [-0.53, -5.35, 2.3], [-0.53, -3.6, 2.45], [-0.05, -1.6, 2.45], [1.3, -1.6, 2.45]]
			q += [[1.75, -1.55, 2.45]] if route_name == "headman_tea" else [[1.5, -2.9, 2.45], [4.0, -3.0, 2.45]]
		for v in q:
			pts.append(Town.to_godot(-95.0 + float(v[0]), 30.0 + float(v[1]), 2655.0 + float(v[2])))
		current["tight"] = {4: true, 6: true, 9: true} if route_name != "headman_dog" else {}  # (9: just before the bench)
		current["marks"] = {}
	elif route_name == "lookout":  # M2 sprint 6, step 4: from H-SHL-095's yard up the garden lane between its walls and along
		# the contour through upper Shöl's orchards to the Gorge Rim Lookout's terrace, to V-13a's place at its parapet
		var gl: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gardens.json"))
		for ln in gl["lanes"]:
			pts.append(Town.to_godot(float(ln["from"][0]), float(ln["from"][1]), float(ln["z_a"])))
		var last: Dictionary = gl["lanes"][gl["lanes"].size() - 1]
		pts.append(Town.to_godot(float(last["from"][0]) + float(last["dir"][0]) * float(last["length"]), float(last["from"][1]) + float(last["dir"][1]) * float(last["length"]), float(last["z_b"])))
		pts.append(Town.to_godot(258.8, 246.7, 2781.5))
		current["marks"] = {1: "ramp_top", 6: "orchards", pts.size() - 2: "lane_end", pts.size() - 1: "v13a"}
	elif route_name == "camp":  # M2 sprint 9, step 1: from R-01's end by the south pavilion down the Caravan Ramp's six
		# legs, round each of its five switchbacks' landings, onto the Caravan Ground at its foot by the fodder yard, then
		# round the corral's south side to the windbreaks of the trader's tea (data/caravan_ground.json)
		var cg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/caravan_ground.json"))
		current["marks"] = {}
		var landing := 0
		var path: Array = cg["path"]
		for k in path.size():
			var q: Array = path[k]
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
			if k >= 2 and k + 1 < path.size() and absf(float(q[2]) - float(path[k - 1][2])) < 0.01 and absf(float(q[2]) - float(path[k + 1][2])) < 0.01:
				landing += 1  # the middle of a landing's turn: its two points level with the leg's end before them
				if landing % 2 == 1:
					current["marks"][pts.size() - 1] = "landing_%d" % ((landing + 1) / 2)
		current["marks"][pts.size() - 1] = "foot"
		for q in cg["walk"]:
			pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
		current["marks"][pts.size() - 1] = "windbreaks"
	elif route_name == "stalls":  # sprint 7, step 8: along the fuel stalls' counters at nine, stopping to listen at each
		# keeper (L: marks), then back west past them: the barks (world/barks.gd) the town says on the way
		for q in [[-24.0, -12.0], [-18.0, -11.4], [-15.6, -11.4], [-12.0, -11.4], [-9.8, -11.4], [-17.0, -11.6], [-20.0, -11.6]]:
			pts.append(Town.to_godot(q[0], q[1], 2660.0))
		current["marks"] = {1: "L:kalsang", 2: "L:stall_woman", 3: "L:stall_man", 4: "L:nomad"}
	elif route_name == "roofways":  # IMP-026: stood by a few of tools/town/roof_ways.py's pieces in turn, a still of each
		# (_roofways_tick); the walk itself is a step at the first
		var rw: Array = _roofway_samples()
		if rw.is_empty():
			print("s3: route FAIL: no roof_ways.json (tools/town/roof_ways.py)")
			get_tree().quit()
			return
		var e0: Array = rw[0]["eye"]
		pts = [Town.to_godot(float(e0[0]), float(e0[1]) + 0.6, float(e0[2])), Town.to_godot(float(e0[0]), float(e0[1]), float(e0[2]))]
		current["marks"] = {}
	elif route_name == "viewpoints":  # IMP-021 (5), IMP-024: sat at each of data/viewpoints.json's seats in turn at its
		# hour, the camera drifting out to its frame (_views_tick); the walk itself is a step at the first seat
		var vj = JSON.parse_string(FileAccess.get_file_as_string("res://data/viewpoints.json"))
		var s0: Array = vj["views"][0]["seat"]
		pts = [Town.to_godot(float(s0[0]), float(s0[1]) + 0.6, float(s0[2])), Town.to_godot(float(s0[0]), float(s0[1]), float(s0[2]))]
		current["marks"] = {}
	elif route_name == "bridge":  # IMP-023 (3), Greg's 1773: up the ladder on a house's wall to its roof, across the
		# bridge over the Sky Stair, and down the far roof's plank to its lane (bridges.json)
		var bp := _bridge_points()
		pts = bp[0]
		current["marks"] = bp[1]
		current["tight"] = bp[2]
		if pts.is_empty() or get_node_or_null("Town") == null:
			print("s3: route FAIL: no bridge (tools/town/bridges.py) or no town (run with --town)")
			get_tree().quit()
			return
	elif route_name == "rooftop":
		var rp := _rooftop_points()
		pts = rp[0]
		current["marks"] = rp[1]
		current["tight"] = rp[2]
		if OS.get_environment("ROUTE_DEBUG") != "":
			for k in pts.size():
				var q: Vector3 = pts[k]
				print("s3: route point %d: town (%.2f, %.2f, %.2f)%s" % [k, q.x, -q.z, _town_z(q), (" then " + String(rp[1][k])) if rp[1].has(k) else ""])
		if pts.is_empty() or get_node_or_null("Town") == null:
			print("s3: route FAIL: no Rooftop Way (tools/town/rooftop.py) or no town (run with --town)")
			get_tree().quit()
			return
	else:
		var r: Array = ROUTES.get("message" if route_name.begins_with("message_") else route_name, [])  # (the story's two: M1's walk)
		var b: Node3D = get_node_or_null("Town/" + String(r[0])) if not r.is_empty() else null
		if b == null:
			print("s3: route FAIL: no route or building %s (run with --town)" % route_name)
			get_tree().quit()
			return
		for q in r[1]:
			pts.append(b.global_transform * Vector3(q.x, q.z, -q.y))  # Blender's (x, y, z) is Godot's (x, z, -y)
		current["marks"] = ROUTE_MARKS.get("message" if route_name.begins_with("message_") else route_name, {})
		if route_name.begins_with("message_"):  # mission 3 in a story: the letter given, Dolkar's ask in the ledger
			new_game()
			Story.set_flag("has_letter", false)
			Story.set_flag("letter_given")
			Story.done("m1_letter")
			Story.write("m3_price", "mission", "Carry the last offers between Achak Dolkar's two counting rooms. No one opens a price.", "achak_dolkar", "Dechen-tsang's counting rooms")
		if route_name == "house_tea_142":  # onto the guest's sheepskin itself, the host's place at the log's end beside it
			current["tight"] = {pts.size() - 1: true}
		if route_name == "yard3":  # straight at each stair's foot and head and at each doorway with a sill (its step over)
			current["tight"] = {9: true, 10: true, 14: true, 15: true, 17: true, 18: true, 19: true, 23: true, 24: true, 25: true}
			current["marks"] = {7: "garden", 10: "chapel_landing", 12: "chapel", 18: "gallery", 21: "dolkar", 26: "garden"}
		if route_name.begins_with("letter_") or route_name == "chang_talk":  # the story from a new game's start
			new_game()
	var p := CharacterBody3D.new()
	p.set_script(PlayerScript)
	p.ink_air = true
	p.third_person = true
	p.scripted = true
	add_child(p)
	var i0 := clampi(route_from, 0, pts.size() - 2)
	p.global_position = pts[i0] + Vector3(0.0, 0.6, 0.0)
	p.cam.current = true
	terrain.set_camera(p.cam)
	# the Rooftop Way at 16:45, as M1's acceptance 5 walks it (--hour=H for another light)
	# (until 26 Sep 2026 the hour went in as the animation's seconds and every route walked at the default 14:00)
	WorldClock.freeze(11.0, _minute_at(route_hour if route_hour >= 0.0 else {"rooftop": 16.75, "message": 14.55, "message_sleeve": 14.55, "message_aloud": 14.55, "chang_tea": 16.6, "chang_talk": 16.55, "serchu": 14.7, "samkha": 15.3, "sang": 17.2, "stalls": 9.0, "letter_open": 16.5, "letter_private": 17.7, "headman_tea": 15.5, "headman_dog": 15.0, "headman_seat": 15.5, "tsokchen_tea": 11.05}.get(route_name, 14.0)))
	_day()
	current = {"player": p, "pts": pts, "i": i0 + 1, "t": 0.0, "hist": [], "log": [], "marks": current.get("marks", {}), "floor": NAN, "falls": 0,
			"stills": route_stills_from, "tight": current.get("tight", {}), "ccw_from": current.get("ccw_from", -1)}
	if OS.get_environment("ROUTE_DEBUG") != "":
		print("s3: route debug: start %s, the terrain's height there %.2f" % [str(p.global_position), terrain.data.get_height(p.global_position)])  # (a start
		# under the terrain falls through it: the leat walk's first point had stood off its shelf, M3 sprint 4, step 4)


## A timed walk's frame (--time): its interval and the pipelines compiled since the last, from 5 s in; every frame of the
## route, its pauses too (until M2 sprint 10 a pause to listen returned before it, and was counted as one long frame).
func _time_frame() -> void:
	var now := Time.get_ticks_usec()
	var pipes := int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW)) + int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION))
	if current["t"] > 5.0 and current.has("last_us"):
		var ms := (now - int(current["last_us"])) / 1000.0
		current["worst_ms"] = maxf(float(current.get("worst_ms", 0.0)), ms)
		var ivs: PackedFloat32Array = current.get("intervals", PackedFloat32Array())  # (a packed array is copied: append to a
		ivs.append(ms)  # local, then put it back)
		current["intervals"] = ivs
		if ms > 50.0:
			current["late"] = int(current.get("late", 0)) + 1
			print("s3: route %s: a frame of %.1f ms at %.1f s (%s)" % [route_name, ms, current["t"], ", ".join(Streamer.events)])
		if pipes > int(current.get("pipes", pipes)):
			current["compiled"] = int(current.get("compiled", 0)) + pipes - int(current["pipes"])
			print("s3: route %s: %d pipelines compiled at %.1f s (%s)" % [route_name, pipes - int(current["pipes"]), current["t"], ", ".join(Streamer.events)])
	current["pipes"] = pipes
	current["last_us"] = now


func _route_tick(dt: float) -> void:
	var p: CharacterBody3D = current["player"]
	var pts: Array = current["pts"]
	var i: int = current["i"]
	current["t"] += dt
	if "--time" in OS.get_cmdline_user_args():  # in a window: each frame's interval and the pipelines compiled, after 5 s
		_time_frame()
	if current.has("tea_t"):  # sprint 7, step 4: seated on the guest bench, the tea (the walk is over: until 8 Oct 2026
		_tea_tick(p, dt)  # it went on, past its last point, an out-of-bounds error every frame of the tea)
		return
	if current.has("headman_t"):  # M2 sprint 7, step 5: the headman's dog called off, or his seat refused
		_headman_tick(p, dt)
		return
	if current.has("letter_t"):  # M2 sprint 1, step 5: the letter given
		_letter_tick(p, dt)
		return
	if current.has("chang_t"):  # M2 sprint 2, step 4: what the town is saying
		_chang_tick(p, dt)
		return
	if current.has("views_t"):  # IMP-021 (5): sat at each viewpoint in turn
		_views_tick(p, dt)
		return
	if current.has("rw_t"):  # IMP-026: by each sample of the ways onto the roofs
		_roofways_tick(p, dt)
		return
	if current.has("ward_t"):  # IMP-025: at the chest in the guest room, the clothes
		_wardrobe_tick(p, dt)
		return
	if float(current.get("wait", 0.0)) > 0.0:  # stopped by someone to press E (the message, step 5), a still after
		current["wait"] = float(current["wait"]) - dt
		p.scripted_move = Vector3.ZERO
		(current["hist"] as Array).clear()
		if current.has("listen"):  # stopped to listen (the barks, step 8): a still 1.2 s after the first line said here
			var said_n: int = (_barks().get("said") as Array).size() if _barks() != null else 0
			if said_n > int(current["heard"]) and not current.has("listen_at"):
				current["listen_at"] = float(current["wait"]) - 1.2
			if current.has("listen_at") and float(current["wait"]) <= float(current["listen_at"]):
				if climb_stills:
					current["stills"] += 1
					_save_still("%s_%02d_%s" % [route_name, current["stills"], String(current["listen"])])
				current.erase("listen_at")
				current["heard"] = 1 << 30  # one still a stop
			if float(current["wait"]) <= 0.0:
				current.erase("listen")
		if current.has("wait_e") and float(current["wait"]) < 3.6:
			var msg := get_tree().root.find_child("RoofSang" if String(current["wait_e"]) == "burner" else "Message", true, false)
			var took: bool = msg != null and bool(msg.call("lay" if String(current["wait_e"]) == "burner" else "interact"))
			if took and msg != null and bool(msg.get("choosing")):  # mission 3's choice at Yang's first answer: a second on
				current["to_choose"] = msg  # screen (its still), then chosen
			print("s3: route %s: E by %s %s" % [route_name, String(current["wait_e"]), "taken" if took else "NOT TAKEN"])
			current["taken"] = int(current.get("taken", 0)) + (1 if took else 0)
			current.erase("wait_e")
		if current.has("to_choose") and float(current["wait"]) < 2.6:
			if climb_stills:
				_save_still(route_name + "_choice")
			(current["to_choose"] as Node).call("choose", route_name == "message_aloud")
			print("s3: route %s: the agent's price %s" % [route_name, "spoken aloud" if route_name == "message_aloud" else "pressed into the sleeve"])
			current.erase("to_choose")
		if float(current["wait"]) <= 2.0 and current.has("wait_still"):  # 1.6 s after E: the line said, not yet fading
			if climb_stills:
				_save_still(String(current["wait_still"]))
			current.erase("wait_still")
			p.view_first = false  # on over the shoulder
			p.pitch = 0.0
			p._show_body()
		return
	if current.has("ending"):  # on the last roof: turned to V-28's view (chapter 02: 150-175 degrees, down over Shöl's
		# roofs), still for four seconds while the body turns to it, then the still
		p.scripted_move = Vector3.ZERO
		p.yaw = -deg_to_rad(165.0)
		p.pitch = -deg_to_rad(14.0)
		current["ending"] += 1
		if current["ending"] >= 120:
			current["stills"] += 1
			_save_still("rooftop_%02d_end" % current["stills"])
			get_tree().quit()
		return
	var to: Vector3 = pts[i] - p.global_position
	var flat := Vector2(to.x, to.z)
	p.yaw = atan2(-to.x, -to.z)
	p.scripted_move = Vector3(0.0, 0.0, -1.0)
	if OS.get_environment("ROUTE_RUN") != "":  # debugging: run the route (and ROUTE_JUMP_T=s: jump at s, traced)
		p.scripted_move.y = 1.0
		var jt := float(OS.get_environment("ROUTE_JUMP_T")) if OS.get_environment("ROUTE_JUMP_T") != "" else -1.0
		if jt > 0.0 and current["t"] >= jt and not current.has("jumped"):
			current["jumped"] = 0
			p.set("_want_jump", true)
		if current.has("jumped") and int(current["jumped"]) < 30:
			current["jumped"] = int(current["jumped"]) + 1
			print("s3: jump trace %d pos %s vel %s airborne %s floor %s stair %s" % [current["jumped"], str(p.global_position), str(p.velocity), str(p.get("_airborne")), str(p.is_on_floor()), str(not (p.get("stair") as Dictionary).is_empty())])
	if OS.get_environment("ROUTE_TRACE") != "" and i >= int(OS.get_environment("ROUTE_TRACE")):
		print("s3: trace %d t %.2f at %s to %s vel %s yaw %.2f" % [i, current["t"], str(p.global_position), str(pts[i]), str(p.velocity), p.yaw])
	if p.ladder != null:  # on a log or a stair-ladder: up (W) or down (S) as the next point lies over or under its middle
		var mid: float = ((p._lad["foot"] as Vector3).y + (p._lad["parapet"] as Vector3).y) / 2.0
		p.scripted_move = Vector3(0.0, 0.0, -1.0 if pts[i].y > mid else 1.0)
	elif p.is_on_floor():  # never able to fall: off a ladder, the floor underfoot never drops more than 1.2 m at once
		if not is_nan(current["floor"]) and current["floor"] - p.global_position.y > 1.2:
			current["falls"] += 1
			print("s3: route %s: FELL %.1f m near %s" % [route_name, current["floor"] - p.global_position.y, str(p.global_position)])
		current["floor"] = p.global_position.y
	if p.ladder != null:
		current["floor"] = p.global_position.y
		var halfway: bool = p.ladder_h > float(p._lad["end"]) * 0.5 if pts[i].y > p.global_position.y else p.ladder_h < float(p._lad["end"]) * 0.5
		if climb_stills and route_name == "bridge" and p.ladder != current.get("still_lad") and halfway:
			current["still_lad"] = p.ladder  # each ladder halfway, up and down (1773's ladder up the wall)
			current["stills"] += 1
			_save_still("%s_%02d_climb" % [route_name, current["stills"]])
	# Chapter 04, 10: a threshold stepped over, never on: count the steps over, and any frame stood on a sill
	if not p.over.is_empty():
		if not current.get("in_over", false):
			current["overs"] = int(current.get("overs", 0)) + 1
		current["in_over"] = true
	else:
		current["in_over"] = false
		for node in get_tree().get_nodes_in_group("sills"):
			var mk := node as Node3D
			var d := mk.global_transform.affine_inverse() * p.global_position
			if absf(d.x) < float(mk.get_meta("w")) / 2.0 and absf(d.z) < float(mk.get_meta("d")) / 2.0 + 0.05 and d.y > 0.1:
				current["on_sill"] = int(current.get("on_sill", 0)) + 1
	var hist: Array = current["hist"]
	hist.append(p.global_position)
	if hist.size() > 90:
		hist.pop_front()
		if (p.global_position - (hist[0] as Vector3)).length() < 0.3:
			print("s3: route %s FAIL: stalled on the way to point %d at %s (%.2f m short, %.2f m below it)" % [route_name, i, str(p.global_position), flat.length(), to.y])
			if OS.get_environment("ROUTE_DEBUG") != "":
				var hits := []
				for c in p.get_slide_collision_count():
					var col := p.get_slide_collision(c)
					hits.append("%s n%s at %s" % [(col.get_collider() as Node).name if col.get_collider() is Node else "?", str(col.get_normal()), str(col.get_position())])
				print("s3: route debug: on floor %s, on wall %s, stair %s, ladder %s, velocity %s, hits %s" % [p.is_on_floor(), p.is_on_wall(), str(p.stair), str(p.ladder), str(p.velocity), str(hits)])
				print("s3: route debug: the last 90 positions, every 10th: %s" % str(hist.filter(func(_q): return true).slice(0, 90, 10)))
				var fwd := Vector3(to.x, 0, to.z).normalized()
				var prof := []
				for k in range(0, 16):
					var at := p.global_position + fwd * (k * 0.1)
					var qq := PhysicsRayQueryParameters3D.create(at + Vector3(0, 3.0, 0), at + Vector3(0, -2.0, 0), p.collision_mask, [p.get_rid()])
					var hh := get_world_3d().direct_space_state.intersect_ray(qq)
					prof.append("%.1f:%s" % [k * 0.1, ("%.2f %s" % [(hh["position"] as Vector3).y - p.global_position.y, (hh["collider"] as Node).name]) if not hh.is_empty() else "-"])
				print("s3: route debug: ahead ", prof)
				for dy in [0.3, 0.45, 0.55, 0.7]:
					var t := p.global_transform
					t.origin += Vector3(0, dy, 0)
					var dirv := Vector3(to.x, 0, to.z).normalized()
					print("s3: route debug: lifted %.2f: blocked %s" % [dy, p.test_move(t, dirv * 0.35)])
			get_tree().quit()
			return
	if flat.length() < (0.15 if current["tight"].has(i) else 0.45) and (p.ladder == null or absf(to.y) < 0.6):
		print("s3: route %s: point %d reached at %.1f s, %.2f m from its level" % [route_name, i, current["t"], -to.y])
		if String(current["marks"].get(i, "")).begins_with("E:"):  # stop, face them, press E, a still once said
			var nm := String(current["marks"][i]).substr(2)
			current["wait"] = 4.2
			current["wait_e"] = nm
			current["stills"] += 1
			current["wait_still"] = "%s_%02d_%s" % [route_name, current["stills"], nm]
			var whom := "yang_shouren" if nm.begins_with("yang") else ("achak_dolkar" if nm == "burner" else "ngodrup_dedpon")
			for w_ in TownSim.count:
				if String(TownSim.key[w_]) == whom:
					var to_: Vector3 = TownSim.pos[w_] + Vector3(0.0, 0.9, 0.0) - (p.global_position + Vector3(0.0, 1.6, 0.0))
					p.yaw = atan2(-to_.x, -to_.z)
					p.pitch = atan2(to_.y, Vector2(to_.x, to_.z).length())
			if nm == "burner":  # over the shoulder: the household at the burner and the smoke going up
				p.pitch = 0.05
			else:
				p.view_first = true  # the one spoken to, from the player's own eyes
				p._show_body()
		elif String(current["marks"].get(i, "")).begins_with("L:"):  # stop, turn to the counter, and listen for eight seconds
			current["wait"] = 8.0
			current["listen"] = String(current["marks"][i]).substr(2)
			current["heard"] = (_barks().get("said") as Array).size() if _barks() != null else 0
			p.yaw = 0.0  # north, to the stall
		elif climb_stills and current["marks"].has(i):
			current["stills"] += 1
			_save_still("%s_%02d_%s" % [route_name, current["stills"], current["marks"][i]])
		current["i"] = i + 1
		hist.clear()  # a point reached is progress: into a room and out again within the stall's 3 s is no stall
		var wheel := get_node_or_null("Town/SHL-08_wheel")
		if i == current["ccw_from"] and wheel != null:  # the clockwise turns done: the wheel's count before the walk the other way
			current["cw"] = [float(wheel.get("turns")), int(wheel.get("rings"))]
			hist.clear()  # turned back, the walker passes where it was a moment before, which is no stall
		if current["i"] >= pts.size():
			var ok: bool = current["falls"] == 0 and absf(to.y) < 0.6
			if route_name == "wheel" and wheel != null and current.has("cw"):
				var cw: Array = current["cw"]
				var back: float = float(wheel.get("turns")) - float(cw[0])
				var turned: bool = float(cw[0]) >= 2.5 and int(cw[1]) >= int(float(cw[0])) and back < 0.3
				print("s3: route wheel: the great wheel went round %.2f times with the walker, its bell rang %d times; walked the other way it turned %.2f more (its run-down) %s" % [
						float(cw[0]), int(cw[1]), back, "PASS" if turned else "FAIL"])
				ok = ok and turned
			if "--time" in OS.get_cmdline_user_args():  # spike S6's bar at the doors: no frame over 50 ms, no pipeline compiled
				print("s3: route %s: the worst frame %.1f ms after 5 s, %d over 50 ms, %d pipelines compiled" % [route_name,
						float(current.get("worst_ms", 0.0)), int(current.get("late", 0)), int(current.get("compiled", 0))])
				var iv: PackedFloat32Array = current.get("intervals", PackedFloat32Array())
				if iv.size() > 10:  # the frame rate held (M2's acceptance 4: 30 fps; its 1% low, as the PT-slice's)
					var sorted_iv := iv.duplicate()
					sorted_iv.sort()
					var mean := 0.0
					for x in iv:
						mean += x
					mean /= iv.size()
					var p99 := sorted_iv[mini(sorted_iv.size() - 1, int(sorted_iv.size() * 0.99))]
					print("s3: route %s: %d frames, mean %.1f ms (%.1f fps), 1%% low %.1f fps, %d over 33.3 ms" % [route_name, iv.size(), mean,
							1000.0 / mean, 1000.0 / p99, Array(iv).filter(func(x): return x > 33.34).size()])
				ok = ok and int(current.get("late", 0)) == 0 and int(current.get("compiled", 0)) == 0
			if route_name == "sang":  # juniper laid on Dechen-tsang's burner, with the household
				var rs := get_tree().root.find_child("RoofSang", true, false)
				var laid_: int = int(rs.get("laid")) if rs != null else 0
				print("s3: route sang: %d sprig(s) of juniper laid on the burner; the codex's CX-050 %s, CX-070 %s" % [laid_,
						"found" if Codex.found.has("CX-050") else "NOT found", "found" if Codex.found.has("CX-070") else "NOT found"])
				ok = ok and laid_ >= 1 and Codex.found.has("CX-050") and Codex.found.has("CX-070")
			if route_name.begins_with("message"):  # the six steps of the offers carried, the deal made
				var msg := get_tree().root.find_child("Message", true, false)
				var made: bool = msg != null and bool(msg.get("done"))
				print("s3: route message: %d of 6 steps taken, the deal %s; the codex's CX-048 %s, CX-052 %s" % [int(current.get("taken", 0)),
						"made" if made else "NOT made", "found" if Codex.found.has("CX-048") else "NOT found", "found" if Codex.found.has("CX-052") else "NOT found"])
				ok = ok and made and int(current.get("taken", 0)) == 6 and Codex.found.has("CX-048") and Codex.found.has("CX-052")
				if route_name != "message":  # in the story: the mission done, the note, and what Dolkar has heard an hour on
					WorldClock.minute += 61.0
					Story._process(0.0)
					var aloud := route_name == "message_aloud"
					var heard := Story.knows("achak_dolkar", "price_spoken" if aloud else "deal_in_the_sleeve")
					print("s3: route %s: mission 3 %s; Dolkar has heard %s; Yang knows the price was spoken: %s; the ledger: %s" % [route_name,
							"done" if bool(Story.entry("m3_price").get("done", false)) else "NOT done", "price_spoken" if aloud else "deal_in_the_sleeve" if heard else "nothing",
							str(Story.knows("yang_shouren", "price_spoken")), str(Story.entry("m3_told").get("text", ""))])
					ok = ok and bool(Story.entry("m3_price").get("done", false)) and heard and Story.knows("yang_shouren", "price_spoken") == aloud
			if route_name in ["rooms", "dechen", "yard3"]:  # the thresholds: every one stepped over, never stood on
				var want: int = {"rooms": 9, "dechen": 1, "yard3": 5}[route_name]
				print("s3: route %s: %d steps over a threshold (%d wanted), %d frames on a sill" % [route_name, int(current.get("overs", 0)), want, int(current.get("on_sill", 0))])
				ok = ok and int(current.get("overs", 0)) >= want and int(current.get("on_sill", 0)) == 0
			var bk := _barks()
			if bk != null:  # the town's lines on the way (world/barks.gd; sprint 7, step 8)
				var heard: Array = []
				for l in bk.get("said"):
					heard.append("%s by %s at %s" % [l[1], l[2], _hhmm(float(l[0]))])
				print("s3: route %s: the town said %d line(s): %s" % [route_name, heard.size(), ", ".join(heard) if not heard.is_empty() else "none"])
				if route_name == "stalls":  # a keeper's greeting, and the nomad's goodbye as the player walked away from her stall
					var ids: Array = (bk.get("said") as Array).map(func(l): return String(l[1]))
					var greeted := ids.has("PB-T28") or ids.has("PB-T18")
					print("s3: route stalls: a keeper's greeting %s, the nomad's goodbye %s" % ["said" if greeted else "NOT said", "said" if ids.has("PB-T11") else "NOT said"])
					ok = ok and greeted and ids.has("PB-T11")
			print("s3: route %s %s: %d points in %.1f s, %d falls" % [route_name, "PASS" if ok else "FAIL", pts.size() - 1, current["t"], current["falls"]])
			if climb_stills and route_name == "rooftop":
				current["ending"] = 0
			elif (route_name == "tea" or route_name.begins_with("house_tea") or route_name == "chang_tea" or route_name == "headman_tea" or route_name == "tsokchen_tea") and ok:
				current["tea_t"] = 0.0
			elif (route_name == "headman_dog" or route_name == "headman_seat") and ok:
				current["headman_t"] = 0.0
			elif route_name == "chang_talk" and ok:
				current["chang_t"] = 0.0
			elif route_name.begins_with("letter_") and ok:
				current["letter_t"] = 0.0
			elif route_name == "wardrobe" and ok:
				current["ward_t"] = 0.0
			elif route_name == "viewpoints" and ok:
				current["views_t"] = 0.0
				current["view_i"] = 0
			elif route_name == "roofways" and ok:
				current["rw_t"] = 0.0
				current["rw_i"] = 0
			else:
				get_tree().quit()


func _barks() -> Node:
	return get_tree().root.find_child("Barks", true, false)


func _hhmm(minute: float) -> String:
	var m := int(fposmod(minute, 1440.0))
	return "%d:%02d" % [m / 60, m % 60]


## A sound run (plan chapter 10, 13.11; M1 sprint 8, step 1): the camera at a station (STATIONS) at an hour of the
## default day, the clock running at play's rate, the Master bus recorded for some seconds into
## tests/audio/out/sound_<station>_<hour>.wav, for tools/audio/measure.py. In a window (a headless run mixes nothing).
func _start_sound() -> void:
	var name_: String = sound_job[0]
	var st: Array = []
	for s_ in STATIONS:
		if String(s_[0]) == name_:
			st = s_
	if st.is_empty():
		print("s3: sound FAIL: no station %s" % name_)
		get_tree().quit()
		return
	_place(st)
	var minute := _minute_at(float(sound_job[1]))
	WorldClock.minute = minute
	WorldClock.frozen = false
	WorldClock.rate = WorldClock.RATE_PLAY
	_day()
	day.update(minute)
	if TownSim.walkers_on:
		TownSim.step(0.0, cam.global_position)
	var rec := AudioEffectRecord.new()
	AudioServer.add_bus_effect(0, rec)
	rec.set_recording_active(true)
	print("s3: sound run at %s from %s for %s s" % [name_, Calendar.clock(minute), sound_job[2]])
	var t0 := Time.get_ticks_msec()  # real seconds: the mix runs on the wall clock, whatever the frames' pace
	while Time.get_ticks_msec() - t0 < int(float(sound_job[2]) * 1000.0):
		await get_tree().process_frame
	rec.set_recording_active(false)
	var out := ProjectSettings.globalize_path("res://tests/audio/out")
	DirAccess.make_dir_recursive_absolute(out)
	var path := "%s/sound_%s_%s.wav" % [out, name_, String(sound_job[1]).replace(".", "_")]
	rec.get_recording().save_to_wav(path)
	var said: Array = AudioDirector.sound.get("played")
	print("s3: sound run saved %s; the director played %s" % [path, ", ".join(said.map(func(l): return "%s (+%.1f s)" % [l[1], float(l[2])]))])
	var sd: Node = AudioDirector.sound if is_instance_valid(AudioDirector) else null
	if sd != null:  # the loops heard at the end (a stove, the juniper, the flags): voiced, or running unheard
		var loops: Dictionary = sd.get("_loops")
		var heard: Array = []
		for k in loops:
			if loops[k]["player"] != null:
				heard.append("%s (%s)" % [String(loops[k]["id"]), String(k)])
		print("s3: sound run: %d loops running, %d heard: %s" % [loops.size(), heard.size(), ", ".join(heard)])
	# the hand wheels heard at some time in the run: a wheel's whirr is made the first time it comes near (characters/hand_wheel.gd)
	print("s3: sound run: %d hand wheels heard" % get_tree().root.find_children("Whirr", "AudioStreamPlayer3D", true, false).size())
	get_tree().quit()
