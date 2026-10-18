extends RefCounted
## The town from its data (plan chapter 02, 12; PLAN step 9, kit K5): the gazetteer's buildings (data/town.json) and
## the town builder's generic houses (data/town_generic.json, tools/town/builder.py), placed as the kit's types on the
## terrain, each on its pad and facing its way. So far the kit has the town houses B, the poor houses E and the stalls
## (kit step K5); the other buildings keep their pads, flat and empty, until their kit steps (the trading houses K7,
## the log-storey houses K8, the monastery K9 and K13, Hejie K10, the castle K11, Tödé K12). Since kit step K7, the
## trading house Dechen-tsang (SHL-04), the first with Chinese pieces; since K8, upper Shöl's log-storey houses (type A).
## Positions: the town grid (x east, y north, z metres above sea level) is Godot's (x, z - 2,662 - the earth's drop,
## -y), as the terrain is (tools/terrain/export_t3d.py). rot_deg is the facade's facing, clockwise from north; the
## kit's houses face south (+Z) as exported.

const KIT := "res://assets/generated/kit/types/%s.glb"
const TOWN := "res://data/town.json"
const GENERIC := "res://data/town_generic.json"
const HEJIE := "res://data/hejie.json"  ## Hejie's generic houses (tools/town/hejie.py; M2 sprint 9, step 4)
const MONASTERY := "res://data/monastery.json"  ## Dungkar Gönpa's monks' houses (tools/town/monastery.py; M2 sprint 13)
const TODE := "res://data/tode.json"  ## Tödé's houses (tools/town/tode.py; M3 sprint 4, step 1)
const TODE_STAIR := "res://data/tode_stair.json"  ## the Tödé Stair (tools/town/tode_stair.py; M3 sprint 4, step 2)
const DUNGRONG := "res://data/dungrong.json"  ## the 1,080 steps' flights and landings (tools/town/dungrong.py; M3 sprint 1)
const GORGE := "res://data/gorge_stair.json"  ## the Gorge Stair's flights and landings and the upper bridge (tools/town/gorge_stair.py; M3 sprint 2)
const GONPA := "res://data/gonpa_ways.json"  ## the monastery's way up from the South Gate to the Tsokchen's courtyard (tools/town/gonpa_ways.py; M3 sprint 3)
const GONKOR := "res://data/gonkor.json"  ## the Gönkor round the monastery beyond its south stretch: its flights, landings and its gallery on the gorge face (tools/town/gonkor.py; M3 sprint 7)
const CASTLE_RAMP := "res://data/castle_ramp.json"  ## the Castle Ramp's yards' places (tools/town/castle_ramp.py; M2 sprint 11)
const SERCHU_ROAD := "res://data/serchu_road.json"  ## the Serchu road's Zampa, its chorten and the porters' rest (M2 sprint 12)
const SERCHU_MILLS := "res://data/serchu_mills.json"  ## the north bank's mills, wheels, leat and footbridge (M2 sprint 12, step 5)
const SERCHU_KIT := "res://assets/generated/kit/serchu/index.json"  ## their channel, chutes, weir and footbridge (export_serchu.py)
const TODE_LEAT := "res://data/tode_leat.json"  ## Tödé's leat TOD-10, its two mills and three water prayer wheels (M3 sprint 4, step 4)
const TODE_LEAT_KIT := "res://assets/generated/kit/tode_leat/index.json"  ## its channel, chutes, races and culverts (export_serchu.py)
const TODE_THINGS := "res://data/tode_things.json"  ## Tödé's threshing floors, byres, racks, walnuts and window stall (M3 sprint 4, step 5)
const SAMKHA_RIM := "res://data/samkha_rim.json"  ## the Leat Fall's outlet and the latrine's midden (tools/town/samkha_rim.py)
const DATUM := 2662.0
## Kit step K6: the Sky Stair along the gazetteer's line (SHL-15), from its route's first height (R-05: Tsongra, 2,665 m),
## and what stands on it turned to its line and set on its treads (SHL-17, the gateway chorten it climbs through: its
## passage's line a rise under the flights' nosings, so the treads show in it and it has its 3 m of headroom). The tunnel under three
## houses (SHL-16) is built in the stair's own frame and placed as the stair is, its three town houses at its HOUSE
## sockets; the talkers' steps (SHL-40) climb from Tsongra's lower level to the stair's foot, 6.4 m before it and 3 m down.
const SKY_STAIR := {"id": "SHL-15", "file": "sky_stair_v1", "z": 2665.0}
const ON_STAIR := {"SHL-17": "gateway_chorten_v1"}
const IN_STAIR_FRAME := {"SHL-16": ["sky_tunnel_v1", Vector3.ZERO], "SHL-40": ["talkers_steps_v1", Vector3(0.0, -3.0, 6.4)]}
const TUNNEL_HOUSES := ["town_house_b2_v2", "town_house_b3_v1", "town_house_b2_v3"]
## Tsongra's two levels (sprint 3, step 6; chapter 02, SHL-01): the flight from the lower level (2,660 m) up to the upper
## (2,662 m) in the middle of the step between them (tools/terrain/pads.py's LEVELS), climbing north to the edge at y = 0.
const TSONGRA_STEPS := {"file": "tsongra_steps_v1", "pos": [0.0, -3.4, 2660.0]}
## The retaining walls (kit step K6; chapter 03, 11.4): one file per 128 m cell, built from the pads with the terrain.
const WALLS := "res://assets/generated/kit/walls/%s"
## The notched logs up to the roofs (sprint 3, step 3; tools/town/ladders.py): each leans from its foot towards its wall
## at its own angle (the kit's log is built at 67 degrees and turned by the difference), in the group "ladders" for the
## player's climb, with the parapet's top it rests on as metadata.
const LADDERS := "res://assets/generated/terrain/ladders.json"
const LOG_LEAN := 67.0
const STAIR_LEAN := 65.0  ## the kit's stair-ladder (IN-04), built at 65 degrees
const WALL_LEAN := 75.0  ## the kit's ladder up a house wall (wall_ladder_80/90/100; IMP-023 (3)), built at 75 degrees
## The plank-and-rope bridges (tools/town/bridges.py, ../tibet-blender/export_bridges.py; IMP-023 (3), Greg's 1773)
const BRIDGES := "res://assets/generated/terrain/bridges.json"
const BRIDGE_KIT := "res://assets/generated/kit/bridges/%s.glb"
## The arrival by the Serchu road (M2 sprint 3; ../tibet-blender/export_arrival.py): the cliff gallery SER-03 and its rock,
## the rock of R-01's cutting through the nose, each laid from its line's start along its bearing.
const ARRIVAL_KIT := "res://assets/generated/kit/arrival/index.json"
const GARDENS := "res://data/gardens.json"  ## upper Shöl's orchards and the lane to the Gorge Rim Lookout (tools/town/gardens.py)
const TREE_VARIANTS := {"walnut": 3, "apple": 4, "pear": 3}  ## ../tibet-blender export_types.py VARIANTS
const ARRIVAL := "res://data/arrival.json"  ## the road's lines, the eight chortens' row (tools/terrain/arrival.py)
## Samkha (M2 sprint 4; ../tibet-blender/export_samkha.py): the chain bridge SAM-03, laid from its north end, swaying
## under its walkers (world/chain_bridge.gd)
const SAMKHA_KIT := "res://assets/generated/kit/samkha/index.json"
const ChainBridge := preload("res://world/chain_bridge.gd")
const ROOF_WAYS := "res://assets/generated/terrain/roof_ways.json"  ## a way onto every roof (tools/town/roof_ways.py; IMP-026)
## The side lanes (sprint 4, step 1; tools/town/builder.py) and the flights between yards (IMP-023; tools/terrain/pads.py):
## a stone flight up each one's steep part, from `s` metres up the lane along its axis, its first riser's foot at `z`.
const LANES := "res://data/town_lanes.json"
const LANE_KIT := "res://assets/generated/kit/lanes/%s.glb"  ## each flight its own, wall to wall (../tibet-blender export_lanes.py; IMP-023)
## The Rooftop Way (R-06, sprint 4, step 1; tools/town/rooftop.py): its logs and stair-ladders (as the ladders above),
## its roof-terrace steps and its plank bridges (SHL-30), each laid from its near end towards its far one.
const ROOFTOP := "res://assets/generated/terrain/rooftop.json"
## The slice's named buildings with a kit type of their own (sprint 4, step 2; chapter 12, 4.2): the headman's house with
## its walled yard, the bowl-turner, the saddler and the tailor, Tsongra's basin and darchen; with a height where the
## gazetteer's is not the ground they stand on (the basin's 2,664 m is its trough's rim over the square's 2,662 m).
## Sprint 4, step 3: the Mani Lhakhang, facing west onto the Sky Stair (the gazetteer's rot_deg), its great wheel placed
## at its WHEEL socket (world/great_wheel.gd). [file, height or null, [x, y] or null, facing or null].
const NAMED := {"SHL-19": ["headman_house_v1", null], "SHL-21": ["workshop_turner_v1", null], "SHL-22": ["workshop_saddler_v1", null],
		"SHL-25": ["workshop_tailor_v1", null], "SHL-02": ["tsongra_basin_v1", 2662.0], "SHL-03": ["darchen_12_v1", 2662.0],
		"SHL-08": ["mani_lhakhang_v1", null],
		"TOD-01": ["tod01_tower_v1", null],  # the Tödé tower (M3 sprint 4, step 3; ../tibet-blender kit/tode.py star_tower): at
		# tools/town/tode.py's place and level, its door down the fall line (tode_named)
		"TOD-02": ["tod02_bon_chapel_v1", null],  # the Yungdrung Lhakhang, Tödé's Bön chapel (step 6; kit/tode.py bon_chapel), on
		# its terrace, its door down the fall line, its circuit R-24 round it (tools/town/tode_things.py)
		# sprint 6, step 5: the Yak Gate at the head of Samkha's north ramp (tools/town/north_ramp.py; the approach's level),
		# and the lower cantilever bridge's deck across the slot from the ramp's foot, until kit step K11 builds the bridge
		"SAM-07": ["yak_gate_v1", 2651.1], "SAM-05": ["sam05_cantilever_v1", 2624.1, [-55.0, -110.5], 180.0],  # (the kit's
		# cantilever bridge since M2 sprint 4: four tiers each side over the built slot's 15 m)
		# M2 sprint 3: the Gate Chorten over R-01, its passage along the road's turn (data/arrival.json passage_bearing 282:
		# the kit's -y to 102), and the road chorten at the gallery's east end
		"SER-01": ["ser01_gate_chorten_v1", 2692.0, null, 102.0], "SER-20": ["chorten_s_v1", 2712.0],
		# M2 sprint 4: Samkha Khar on the slot's rim, the gate passage SAM-02 through its ground storey on the chain
		# bridge's line, and the south pavilion SAM-04 at the bridge's south end (data/samkha.json "castle", "pavilion")
		"SAM-01": ["sam01_castle_v1", 2649.0, [-130.0, -87.0], 180.0], "SAM-04": ["sam04_pavilion_v1", 2655.0, [-130.0, -146.0], 180.0],
		# M2 sprint 5, step 4: Pema Ö Lhakhang facing the confluence (its chortens SHL-13 and its stair are the kit's), the
		# Conch terrace beside the pool (tools/terrain/pads.py MOVED)
		"SHL-11": ["sh11_pema_o_v1", 2670.0, null, 140.0], "SHL-12": ["sh12_conch_terrace_v1", 2664.0, [190.0, -83.5], 180.0],
		"SHL-14": ["sh14_lukhang_v1", 2775.0, [-110.0, 234.5], 190.0], "SHL-32": ["sh32_lookout_v1", 2781.5, [258.0, 245.0], 34.0],
		# M2 sprint 11, step 3: the ula yard and the castle's stables behind it, where the Castle Ramp's planner put them
		# (ramp_pads: data/castle_ramp.json)
		"SAM-08": ["sam08_stables_v1", null], "SAM-09": ["sam09_ula_yard_v1", null],
		# M2 sprint 11, step 4: the 1861 breach on its pad; the Leat Fall's outlet and the latrine's midden on the slot's
		# face where tools/town/samkha_rim.py finds them (rim_places: data/samkha_rim.json)
		"SAM-16": ["sam16_breach_v1", null], "SAM-11": ["sam11_leat_outlet_v1", null], "SAM-12": ["sam12_midden_v1", null],
		# M2 sprint 12, step 2: the Serchu Zampa and the porters' rest by it, where tools/terrain/serchu_road.py puts them
		# (serchu_places: data/serchu_road.json `places`, `pads`; the Zampa's gateway chorten SER-04C beside the loop)
		"SER-04": ["ser04_zampa_v1", null], "SER-19": ["ser19_porters_rest_v1", null],
		"RNG-01": ["rng01_conch_bridge_v1", null], "RNG-14": ["rng14_tsenkhang_v1", null],  # the Conch Bridge and the tsenkhang (tools/town/dungrong.py places them; M3 sprint 1)
		"RNG-12": ["rng12_lhabab_v1", null],  # the Lhabab Chorten on its terrace beside the steps' landing 6 (M3 sprint 1, step 3)
		"RNG-02": ["rng02_upper_bridge_v1", null],  # the upper bridge, where tools/town/gorge_stair.py finds it (M3 sprint 2)
		"RNG-10": ["rng10_parkhang_in_v1", null],  # the Parkhang where tools/town/dungrong.py stands it (M3 sprint 1, step 4), carved inside since M3 sprint 5, step 8
		# step 3: the durtro path's cairn by the road (the gold washings' huts and troughs are the planner's `things`)
		"SER-14": ["ser14_cairn_v1", null]}
const GreatWheel := preload("res://world/great_wheel.gd")
const Dusk := preload("res://world/dusk.gd")
const Lamps := preload("res://world/lamps.gd")
const Viewpoints := preload("res://world/viewpoints.gd")
const Moments := preload("res://world/moments.gd")
const CastleGate := preload("res://world/castle_gate.gd")
const KoraWheels := preload("res://world/kora_wheels.gd")
const Parkhang := preload("res://world/parkhang.gd")
const Gonkhang := preload("res://world/gonkhang.gd")
const PemaOPeople := preload("res://world/pema_o_people.gd")
const ConfluenceDawn := preload("res://world/confluence_dawn.gd")
const Spring := preload("res://world/spring.gd")
const HeadmanHouse := preload("res://world/headman_house.gd")
const DechenNight := preload("res://world/dechen_night.gd")
const Camp := preload("res://world/camp.gd")
const Market := preload("res://world/market.gd")
const Interiors := preload("res://world/interiors.gd")
const Doors := preload("res://world/doors.gd")
const Curtains := preload("res://world/curtains.gd")
const Boots := preload("res://world/boots.gd")
const HallDay := preload("res://world/hall_day.gd")
const Horns := preload("res://world/horns.gd")
const CodexSites := preload("res://world/codex_sites.gd")
const Barks := preload("res://world/barks.gd")
const ReverbZones := preload("res://world/reverb_zones.gd")
const Flags := preload("res://world/flags.gd")
const Birds := preload("res://world/birds.gd")
const Households := preload("res://world/households.gd")
const DoorDressing := preload("res://world/door_dressing.gd")
const Laundry := preload("res://world/laundry.gd")
const Corners := preload("res://world/corners.gd")
const Forest := preload("res://world/forest.gd")
const Mills := preload("res://world/mills.gd")
const Hearths := preload("res://world/hearths.gd")
const WorkSounds := preload("res://world/work_sounds.gd")
const RoofPeople := preload("res://world/roof_people.gd")
const BridgePeople := preload("res://world/bridge_people.gd")
const SamkhaPeople := preload("res://world/samkha_people.gd")
const SerchuPeople := preload("res://world/serchu_people.gd")
const StepsPeople := preload("res://world/steps_people.gd")
const GorgePeople := preload("res://world/gorge_people.gd")
const TodePeople := preload("res://world/tode_people.gd")
const SunShafts := preload("res://world/shafts.gd")
const Assembly := preload("res://world/assembly.gd")
const UlaYard := preload("res://world/ula_yard.gd")
const Conversation := preload("res://world/conversation.gd")
const Talks := preload("res://world/talks.gd")
const Guide := preload("res://world/guide.gd")
const ManiWall := preload("res://world/mani_wall.gd")
## The barkor's mani wall (tools/town/mani.py): its segments and end pillars on the Mani Lane's bed, and Pasang's pitch
## (SHL-27) against its north face.
const MANI := "res://assets/generated/terrain/mani_walls.json"
const R_EARTH := 6371000.0
const K_REFR := 0.13


## The kit file for a record, or "" when the kit has nothing for its type yet.
static func kit_file(b: Dictionary) -> String:
	if NAMED.has(String(b.get("id", ""))):
		return String(NAMED[String(b["id"])][0])
	var mp: Dictionary = monastery_pads().get(String(b.get("id", "")), {})
	if mp.has("kit"):  # a hall of Dungkar Gönpa at its far form (tools/town/monastery.py HALL_KIT; M2 sprint 13, step 3)
		return String(mp["kit"])
	if b.has("kit"):  # a generic house of Hejie's (tools/town/hejie.py): its type and seed given
		return "%s_v%d" % [String(b["kit"]), int(b.get("seed", 1))]
	if String(b.get("district", "")) == "hejie" or String(b.get("id", "")).begins_with("HEJ-"):
		var given := String((_hejie_pads().get(String(b.get("id", "")), {}) as Dictionary).get("kit", ""))
		return given if given != "" else _hejie_file(b)  # (tools/town/hejie.py's since M2 sprint 10, step 3)
	var t := String(b.get("type", ""))
	var seed := int(b.get("seed", 1 + (hash(String(b["id"])) & 0x7fffffff) % 3))
	var variant := String(b.get("variant", ""))
	if t == "A" and variant != "":  # kit step K8: upper Shöl's log-storey houses (tools/town/builder.py)
		return "log_house_%s_v%d" % [variant.to_lower(), seed]
	if t == "B" and variant != "":
		if Interiors.ROOMS.has(String(b["id"])):  # a house to enter (sprint 8, step 7): its kitchen carved, its door open
			return "town_house_b2_in_v%d" % seed
		var name := "town_house_%s" % variant.to_lower()
		if int(b.get("storeys", 3)) == 2:
			name += "_s2"
			seed = mini(seed, 4)  # four variants with two storeys (IMP-019), six with three
		if b.has("party"):
			name += "_" + String(b["party"])
		return "%s_v%d" % [name, seed]
	match t:
		"B":
			if Interiors.ROOMS.has(String(b["id"])):  # a building of the gazetteer to enter: the chang house, its first floor carved
				return "town_house_b2_in_v%d" % seed
			return "town_house_b2_v%d" % seed
		"B, large":
			return "town_house_b3_v%d" % seed
		"B, workshop":
			return "town_house_b1_v%d" % seed
		"E", "E + forge shed":
			if Interiors.ROOMS.has(String(b["id"])):  # the poor house to enter (chapter 04, 4.2): its one room carved
				return "poor_house_e1_in_v%d" % seed
			return "poor_house_e1_v%d" % seed
		"stall", "stalls":
			return "stall_sh04_v%d" % mini(seed, 2)
		"M1", "M2":  # Dungkar Gönpa's monks' houses (kit/monastery.py; M2 sprint 13), each its variant (tools/town/monastery.py)
			return "monk_house_%s_v%d" % [t.to_lower(), seed] if String(b.get("id", "")).begins_with("H-MON-") else ""
		"trading house":  # kit step K7: Dechen-tsang; the smaller houses (SHL-05 to 07) are variants to come
			return "trading_house_v1" if String(b["id"]) == "SHL-04" else ""
	return ""


## Hejie's named buildings (M2 sprint 9, step 4; ../tibet-blender kit/hejie.py): by their chapter 02 type, the inns and
## the official lodging by their ids; a shop-house's form by its frontage and its seed.
static var _hejie_pads_cache = null
static var _ramp_pads_cache = null
static var _serchu_cache = null
static var _rim_cache = null
static var _monastery_cache = null
static var _dungrong_cache = null
static var _gorge_cache = null
static var _tode_cache = null


## Tödé's named places (tools/town/tode.py `named`; M3 sprint 4): id -> {at, level, facing}: the tower TOD-01 at its place
## and level, its door down the fall line.
static func tode_named() -> Dictionary:
	if _tode_cache == null:
		_tode_cache = {}
		if FileAccess.file_exists(TODE):
			var nm: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(TODE)) as Dictionary).get("named", {})
			for k in nm:
				if (nm[k] as Dictionary).has("facing"):
					_tode_cache[k] = nm[k]
	return _tode_cache


## The things on Samkha's rim tools/town/samkha_rim.py placed on the slot's face: id -> {at, level, facing}.
static func rim_places() -> Dictionary:
	if _rim_cache == null:
		_rim_cache = {}
		if FileAccess.file_exists(SAMKHA_RIM):
			var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMKHA_RIM))
			for pair in [["SAM-11", d.get("leat_fall", {}).get("outlet", [])], ["SAM-12", d.get("midden", [])]]:
				var q: Array = pair[1]
				if q.size() >= 4:
					_rim_cache[pair[0]] = {"at": [q[0], q[1]], "level": q[2], "facing": q[3]}
	return _rim_cache


## The Serchu road's things (tools/terrain/serchu_road.py; M2 sprint 12, step 2): id -> {at, level, facing}: the Zampa
## SER-04 over the river, its gateway chorten SER-04C on the north abutment, the porters' rest SER-19 beside the road.
static func serchu_places() -> Dictionary:
	if _serchu_cache == null:
		_serchu_cache = {}
		if FileAccess.file_exists(SERCHU_ROAD):
			var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SERCHU_ROAD))
			_serchu_cache.merge(d.get("places", {}))
			_serchu_cache.merge(d.get("pads", {}))
	return _serchu_cache

## The buildings the Castle Ramp's planner placed (data/castle_ramp.json `pads`): id -> {at, level, facing}. They stand
## there, not at the gazetteer's places, which lay on the ramp (the ula yard SAM-09 and the stables SAM-08 behind it).
static func ramp_pads() -> Dictionary:
	if _ramp_pads_cache == null:
		_ramp_pads_cache = {}
		if FileAccess.file_exists(CASTLE_RAMP):
			_ramp_pads_cache = (JSON.parse_string(FileAccess.get_file_as_string(CASTLE_RAMP)) as Dictionary).get("pads", {})
	return _ramp_pads_cache


## Dungkar Gönpa's halls' pads (data/monastery.json `pads`, tools/town/monastery.py; M2 sprint 13): id -> {at, level,
## facing}, each at the middle of its own ground rather than chapter 02's height.
static func monastery_pads() -> Dictionary:
	if _monastery_cache == null:
		_monastery_cache = {}
		if FileAccess.file_exists(MONASTERY):
			_monastery_cache = (JSON.parse_string(FileAccess.get_file_as_string(MONASTERY)) as Dictionary).get("pads", {})
	return _monastery_cache


## The Conch Bridge's and the tsenkhang's places (data/dungrong.json `places`, tools/town/dungrong.py; M3 sprint 1): id ->
## {at, level, facing}.
static func dungrong_places() -> Dictionary:
	if _dungrong_cache == null:
		_dungrong_cache = {}
		if FileAccess.file_exists(DUNGRONG):
			_dungrong_cache = (JSON.parse_string(FileAccess.get_file_as_string(DUNGRONG)) as Dictionary).get("places", {})
	return _dungrong_cache


## The upper bridge's place (data/gorge_stair.json `places`, tools/town/gorge_stair.py; M3 sprint 2): id -> {at, level, facing}.
static func gorge_places() -> Dictionary:
	if _gorge_cache == null:
		_gorge_cache = {}
		if FileAccess.file_exists(GORGE):
			_gorge_cache = (JSON.parse_string(FileAccess.get_file_as_string(GORGE)) as Dictionary).get("places", {})
	return _gorge_cache


## Hejie's named buildings' pads (tools/town/hejie.py): each one's level and kit type.
static func _hejie_pads() -> Dictionary:
	if _hejie_pads_cache == null:
		_hejie_pads_cache = {}
		if FileAccess.file_exists(HEJIE):
			_hejie_pads_cache = (JSON.parse_string(FileAccess.get_file_as_string(HEJIE)) as Dictionary).get("pads", {})
	return _hejie_pads_cache


static func _hejie_file(b: Dictionary) -> String:
	var id := String(b.get("id", ""))
	var t := String(b.get("type", ""))
	var seed := 1 + (hash(id) & 0x7fffffff) % 3
	if id == "HEJ-11" or id == "HEJ-12":
		return "hejie_inn_v1"
	match t:
		"gate tower":
			return "hejie_gate_v1"
		"yamen":
			return "hejie_post_v1"
		"stables and rooms":
			return "hejie_relay_v1"
		"courtyard house":
			return "hejie_lodging_v1"
		"temple":
			return "hejie_temple_v1"
		"long hall":
			return "hejie_godown_v1"
		"G", "courtyard mill", "F, large":
			return "hejie_g%d_v%d" % [1 if t == "courtyard mill" else 2, mini(seed, 2)]
		"F", "F + yard", "F + forge", "F, open front":
			var fp: Array = b.get("footprint", [6, 12])
			if float(fp[0]) <= 6.5:
				return "hejie_f1_v%d" % seed
			return ("hejie_f3_v%d" if seed == 3 else "hejie_f2_v%d") % seed
	return ""


## The stair's nosing line (the surface its ramps give the player) at a point in the stair's own frame, from the ramps'
## `stair` metadata (addons/dungkardo_import): on a flight the ramp's height there, on a landing the top of the flight
## below it; -INF before the first flight's toe.
static func stair_line(stair: Node3D, p: Vector3) -> float:
	var best := -INF
	for cs in stair.find_children("*", "CollisionShape3D", true, false):
		if not cs.has_meta("stair"):
			continue
		var m: Dictionary = cs.get_meta("stair")
		var d := (p - (m["toe"] as Vector3)).dot(m["dir"])
		if d >= 0.0:
			best = maxf(best, (m["toe"] as Vector3).y + minf(d / float(m["run"]), float(m["n"])) * float(m["rise"]))
	return best


static func to_godot(x: float, y: float, z: float) -> Vector3:
	var drop := (x * x + y * y) * (1.0 - K_REFR) / (2.0 * R_EARTH)
	return Vector3(x, z - DATUM - drop, -y)


## Places every record the kit can build, under `parent`, within `bounds` (x0, y0, width, height in the town grid).
## Returns counts: {"placed": n, "files": n, "waiting": n (records the kit cannot build yet)}.
static func place(parent: Node3D, bounds := Rect2(-1350.0, -1100.0, 3650.0, 2200.0)) -> Dictionary:
	var records: Array = []
	for path in [TOWN, GENERIC, HEJIE, MONASTERY, TODE]:
		if FileAccess.file_exists(path):
			var d = JSON.parse_string(FileAccess.get_file_as_string(path))
			records.append_array(d.get("buildings", d.get("houses", [])))
			if path == MONASTERY:  # (its khamtsen are its `buildings`, its monks' houses its `houses`)
				records.append_array(d.get("houses", []))
	var root := Node3D.new()
	root.name = "Town"
	parent.add_child(root)
	var cache := {}
	var placed := 0
	var waiting := 0
	# The Sky Stair's line gives its bearing: the stair is built climbing towards its own +y (north), so it turns by it.
	var stair_rot := 0.0
	var stair: Node3D = null
	for b in records:
		if String(b.get("id", "")) == SKY_STAIR["id"] and b.has("line"):
			var a: Array = b["line"][0]
			var e: Array = b["line"][1]
			stair_rot = -atan2(float(e[0]) - float(a[0]), float(e[1]) - float(a[1]))
			if bounds.has_point(Vector2(a[0], a[1])) and ResourceLoader.exists(KIT % SKY_STAIR["file"]):
				var st: Node3D = (load(KIT % SKY_STAIR["file"]) as PackedScene).instantiate()
				st.name = "SHL-15"
				st.position = to_godot(float(a[0]), float(a[1]), SKY_STAIR["z"])
				st.rotation.y = stair_rot
				root.add_child(st)
				stair = st
				placed += 1
				for id in IN_STAIR_FRAME:
					var f0: String = IN_STAIR_FRAME[id][0]
					if not ResourceLoader.exists(KIT % f0):
						continue
					var piece: Node3D = (load(KIT % f0) as PackedScene).instantiate()
					piece.name = id
					piece.transform = Transform3D(st.transform.basis, st.transform * (IN_STAIR_FRAME[id][1] as Vector3))
					root.add_child(piece)
					placed += 1
					var k := 0
					for sock in piece.find_children("SOCK_HOUSE_*", "Node3D", true, false):
						if k < TUNNEL_HOUSES.size() and ResourceLoader.exists(KIT % TUNNEL_HOUSES[k]):
							var hs: Node3D = (load(KIT % TUNNEL_HOUSES[k]) as PackedScene).instantiate()
							hs.name = "%s_house_%d" % [id, k + 1]
							hs.transform = Transform3D(st.transform.basis, (sock as Node3D).global_position)
							root.add_child(hs)
							placed += 1
						k += 1
	# the pads tools/town/caravan_ground.py and tools/town/hejie.py set on the real ground, off chapter 02's heights (and a
	# moved one's place): the buildings stand on them (M2 sprint 9; until then the smithy stood 3 m down in its pad)
	var levels := {}
	for path in ["res://data/caravan_ground.json", HEJIE]:
		if FileAccess.file_exists(path):
			var lv: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary).get("pads", {})
			levels.merge(lv, true)
	for b in records:
		var p = b.get("pos")
		if p == null or p[2] == null or not bounds.has_point(Vector2(p[0], p[1])):
			continue
		if levels.has(String(b.get("id", ""))):
			var lp: Dictionary = levels[String(b["id"])]
			var at: Array = lp.get("at", [p[0], p[1]])
			p = [float(at[0]), float(at[1]), float(lp["level"])]
		if ON_STAIR.has(String(b["id"])) and ResourceLoader.exists(KIT % ON_STAIR[String(b["id"])]):
			var g: Node3D = (load(KIT % ON_STAIR[String(b["id"])]) as PackedScene).instantiate()
			g.name = String(b["id"])
			g.position = to_godot(p[0], p[1], p[2])
			g.rotation.y = stair_rot
			if stair != null:  # onto the stair's line, a rise under its nosings
				var q := stair.transform.affine_inverse() * g.position
				q.x = 0.0
				var y := stair_line(stair, q)
				if y > -INF:
					q.y = y - 0.19
					g.position = stair.transform * q
			root.add_child(g)
			placed += 1
			continue
		var f := kit_file(b)
		if f == "":
			waiting += 1
			continue
		if not cache.has(f):
			cache[f] = load(KIT % f) if ResourceLoader.exists(KIT % f) else null
		if cache[f] == null:
			push_warning("town: no kit file %s for %s" % [f, b["id"]])
			continue
		var n := 3 if String(b.get("type", "")) == "stalls" else 1  # the fuel stalls: three in a row
		var z0: float = p[2]
		var x0: float = p[0]
		var y0: float = p[1]
		var facing := float(b.get("rot_deg", 180.0))
		if NAMED.has(String(b["id"])):
			var nm: Array = NAMED[String(b["id"])]
			if nm[1] != null:
				z0 = float(nm[1])
			if nm.size() > 2 and nm[2] != null:
				x0 = float(nm[2][0])
				y0 = float(nm[2][1])
			if nm.size() > 3 and nm[3] != null:
				facing = float(nm[3])
		var placed_at: Dictionary = ramp_pads() if ramp_pads().has(String(b["id"])) else (serchu_places() if serchu_places().has(String(b["id"])) else (monastery_pads() if monastery_pads().has(String(b["id"])) else (dungrong_places() if dungrong_places().has(String(b["id"])) else (gorge_places() if gorge_places().has(String(b["id"])) else (tode_named() if tode_named().has(String(b["id"])) else rim_places())))))
		if placed_at.has(String(b["id"])):  # moved off the Castle Ramp's way (step 3), on the slot's face (step 4), by the Serchu road, a hall on its own ground
			var rp: Dictionary = placed_at[String(b["id"])]
			x0 = float(rp["at"][0])
			y0 = float(rp["at"][1])
			z0 = float(rp["level"])
			facing = float(rp["facing"])
		for k in n:
			var node: Node3D = (cache[f] as PackedScene).instantiate()
			node.name = "%s_%d" % [String(b["id"]), k] if n > 1 else String(b["id"])
			var rot := deg_to_rad(facing - 180.0)
			var along := Vector3(cos(rot), 0.0, -sin(rot)) * (k - (n - 1) / 2.0) * 3.0
			node.position = to_godot(x0, y0, z0) + along
			node.rotation.y = -rot
			root.add_child(node)
			_add_sills(node, f)
			_add_leaves(node, f)
			_add_curtains(node, f)
			placed += 1
	# the 1,080 steps' chortens, rest house and wheel niches (M3 sprint 1, step 3; data/dungrong.json `things`,
	# tools/town/dungrong.py), a niche's wheels turned under a passing hand (world/kora_wheels.gd)
	if FileAccess.file_exists(DUNGRONG):
		for th in (JSON.parse_string(FileAccess.get_file_as_string(DUNGRONG)) as Dictionary).get("things", []):
			var tf := String(th["kit"])
			if not ResourceLoader.exists(KIT % tf) or not bounds.has_point(Vector2(float(th["at"][0]), float(th["at"][1]))):
				continue
			var tn: Node3D = (load(KIT % tf) as PackedScene).instantiate()
			tn.name = String(th["id"]).validate_node_name()
			tn.position = to_godot(float(th["at"][0]), float(th["at"][1]), float(th["level"]))
			tn.rotation.y = -deg_to_rad(float(th["facing"]) - 180.0)
			root.add_child(tn)
			placed += 1
			if th.get("wheels", false):
				var kw := KoraWheels.new()
				kw.name = "Wheels"
				tn.add_child(kw)
				kw.setup(tn)
	# the Gorge Stair's houses built across its top and its rest gallery with its wheel (M3 sprint 2, step 3; data/gorge_stair.json
	# `things`, tools/town/gorge_stair.py)
	if FileAccess.file_exists(GORGE):
		for th in (JSON.parse_string(FileAccess.get_file_as_string(GORGE)) as Dictionary).get("things", []):
			var tf := String(th["kit"])
			if not ResourceLoader.exists(KIT % tf) or not bounds.has_point(Vector2(float(th["at"][0]), float(th["at"][1]))):
				continue
			var tn: Node3D = (load(KIT % tf) as PackedScene).instantiate()
			tn.name = String(th["id"]).validate_node_name()
			tn.position = to_godot(float(th["at"][0]), float(th["at"][1]), float(th["level"]))
			tn.rotation.y = -deg_to_rad(float(th["facing"]) - 180.0)
			root.add_child(tn)
			placed += 1
			if th.get("wheels", false):
				var kw := KoraWheels.new()
				kw.name = "Wheels"
				tn.add_child(kw)
				kw.setup(tn)
	var pk := root.get_node_or_null("RNG-10") as Node3D
	if pk != null:  # its printers heard by day from its printing room along the north range's second storey (world/parkhang.gd)
		var pn := Parkhang.new()
		pn.name = "Printers"
		pn.position = Vector3(0.0, 3.0, -7.0)  # (the kit's (0, 7, 5): the sound's own 2 m over it)
		pk.add_child(pn)
	var gk := root.get_node_or_null("MON-05") as Node3D
	if gk != null:  # the Gönkhang's drum heard at its door, through the rite and at night (world/gonkhang.gd; M3 sprint 3, step 3)
		var gn := Gonkhang.new()
		gn.name = "Drum"
		gn.position = Vector3(0.0, 1.5, 5.8)  # (in its porch before the curtain: the kit's (0, -5.8, 1.5))
		gk.add_child(gn)
	# the gold washings' huts and troughs on the Serchu's bank below the road (M2 sprint 12, step 3; data/serchu_road.json
	# `things`, tools/terrain/serchu_road.py)
	if FileAccess.file_exists(SERCHU_ROAD):
		for th in (JSON.parse_string(FileAccess.get_file_as_string(SERCHU_ROAD)) as Dictionary).get("things", []):
			var tf := String(th["kit"])
			if not ResourceLoader.exists(KIT % tf):
				continue
			var tn: Node3D = (load(KIT % tf) as PackedScene).instantiate()
			tn.name = String(th["id"])
			tn.position = to_godot(float(th["at"][0]), float(th["at"][1]), float(th["level"]))
			tn.rotation.y = -deg_to_rad(float(th["facing"]) - 180.0)
			root.add_child(tn)
			placed += 1
	# the Serchu Zampa's gateway chorten on its north abutment, the road through its passage (M2 sprint 12, step 2)
	if serchu_places().has("SER-04C") and ResourceLoader.exists(KIT % "ser04_gate_chorten_v1"):
		var sc: Dictionary = serchu_places()["SER-04C"]
		var ch: Node3D = (load(KIT % "ser04_gate_chorten_v1") as PackedScene).instantiate()
		ch.name = "SER-04C"
		ch.position = to_godot(float(sc["at"][0]), float(sc["at"][1]), float(sc["level"]))
		ch.rotation.y = -deg_to_rad(float(sc["facing"]) - 180.0)
		root.add_child(ch)
		placed += 1
	# the north bank at the Serchu's mills (M2 sprint 12, step 5; tools/town/serchu_mills.py): the four mills and the two
	# water prayer wheels' houses where it placed them, each turning part on its socket, turned and heard by
	# world/mills.gd; the leat's channel, the chutes, the race, the weir, the culvert and the footbridge SER-11
	# (../tibet-blender export_serchu.py), unturned, about their first points; hay on the barley terraces SER-17
	if FileAccess.file_exists(SERCHU_MILLS):
		var sm: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SERCHU_MILLS))
		var mills := Mills.new()
		mills.name = "Mills"
		root.add_child(mills)
		var mk := 0
		for m in sm["mills"]:
			mk += 1
			placed += mills.house(m, KIT % ("ser05_mill_v%d" % mk), KIT % "mill_runner_v1", "WHEEL", false)
		mk = 0
		for w in sm["wheels"]:
			mk += 1
			placed += mills.house(w, KIT % ("ser09_wheel_house_v%d" % mk), KIT % "ser09_wheel_drum_v1", "SHAFT", true)
		if FileAccess.file_exists(GORGE):  # and the gorge's water wheel RNG-04 by the upper bridge (M3 sprint 2, step 4)
			var gw: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(GORGE)) as Dictionary).get("wheel", {})
			if not gw.is_empty():
				placed += mills.house(gw, KIT % "ser09_wheel_house_v1", KIT % "ser09_wheel_drum_v1", "SHAFT", true)
		if FileAccess.file_exists(TODE_LEAT):  # and Tödé's leat's two mills TOD-05, 06 and three water prayer wheels TOD-07 to 09
			# (M3 sprint 4, step 4; tools/town/tode_leat.py: at tools/town/tode.py's places), the Serchu's kit types
			var tl: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TODE_LEAT))
			var tk := 0
			for m in tl.get("mills", []):
				tk += 1
				placed += mills.house(m, KIT % ("ser05_mill_v%d" % (tk + 2)), KIT % "mill_runner_v1", "WHEEL", false)
			tk = 0
			for w in tl.get("wheels", []):
				tk += 1
				placed += mills.house(w, KIT % ("ser09_wheel_house_v%d" % (2 - tk % 2)), KIT % "ser09_wheel_drum_v1", "SHAFT", true)
		for th in sm.get("things", []):
			var hf := String(th["kit"])
			if not ResourceLoader.exists(KIT % hf):
				continue
			var hn: Node3D = (load(KIT % hf) as PackedScene).instantiate()
			hn.name = String(th["id"])
			hn.position = to_godot(float(th["at"][0]), float(th["at"][1]), float(th["level"]))
			hn.rotation.y = -deg_to_rad(float(th["facing"]) - 180.0)
			root.add_child(hn)
			placed += 1
	# Tödé's fields' and yards' things (M3 sprint 4, step 5; tools/town/tode_things.py): the threshing floors TOD-11 to 14 on
	# their pads, byres in rammed-earth yards, racks at house pads' corners, the walnut grove TOD-20, the window stall TOD-25
	if FileAccess.file_exists(TODE_THINGS):
		for th in (JSON.parse_string(FileAccess.get_file_as_string(TODE_THINGS)) as Dictionary).get("things", []):
			var tf := String(th["kit"])
			if not ResourceLoader.exists(KIT % tf) or not bounds.has_point(Vector2(float(th["at"][0]), float(th["at"][1]))):
				continue
			var tn: Node3D = (load(KIT % tf) as PackedScene).instantiate()
			tn.name = String(th["id"])
			tn.position = to_godot(float(th["at"][0]), float(th["at"][1]), float(th["level"]))
			tn.rotation.y = -deg_to_rad(float(th["facing"]) - 180.0)
			root.add_child(tn)
			placed += 1
			if String(th["id"]).begins_with("TOD-03.W"):  # a Bön household's niche by its gate (step 6): its wheels anticlockwise
				var nw := KoraWheels.new()
				nw.name = "KoraWheels"
				nw.sense = -1.0
				tn.add_child(nw)
				nw.setup(tn)
	for kit_index in [SERCHU_KIT, TODE_LEAT_KIT]:  # (and Tödé's leat's: M3 sprint 4, step 4)
		if not FileAccess.file_exists(kit_index):
			continue
		for pc in (JSON.parse_string(FileAccess.get_file_as_string(kit_index)) as Dictionary)["pieces"]:
			var sa: Array = pc["from"]
			var sp := String(kit_index).get_base_dir() + "/" + String(pc["file"])
			if not ResourceLoader.exists(sp):
				continue
			var sn: Node3D = (load(sp) as PackedScene).instantiate()
			sn.name = ("SERCHU_%s" if kit_index == SERCHU_KIT else "TODE_LEAT_%s") % String(pc["file"]).get_basename()
			sn.position = to_godot(float(sa[0]), float(sa[1]), float(sa[2]))
			sn.rotation.y = -atan2(float(pc["dir"][0]), float(pc["dir"][1]))
			sn.add_to_group("serchu_mills")
			root.add_child(sn)
			placed += 1
	# the Mani Lhakhang's great wheel, at its WHEEL socket, turned by world/great_wheel.gd; its bell at the BELL socket
	var lhakhang := root.get_node_or_null("SHL-08")
	if lhakhang != null and ResourceLoader.exists(KIT % "great_wheel_45_v1"):
		var sock := lhakhang.find_child("SOCK_WHEEL_1", true, false) as Node3D
		if sock != null:
			var wheel: Node3D = (load(KIT % "great_wheel_45_v1") as PackedScene).instantiate()
			wheel.name = "SHL-08_wheel"
			wheel.set_script(GreatWheel)
			wheel.set("bell", lhakhang.find_child("SOCK_BELL_1", true, false))
			root.add_child(wheel)
			wheel.global_transform = sock.global_transform
			placed += 1
	# the barkor's mani wall: its segments and end pillars, under a node that answers the walker (world/mani_wall.gd)
	if FileAccess.file_exists(MANI):
		for wall in JSON.parse_string(FileAccess.get_file_as_string(MANI))["walls"]:
			var segs: Array = wall["segments"]
			if segs.is_empty() or not bounds.has_point(Vector2(segs[0][0], segs[0][1])):
				continue
			var wn := Node3D.new()
			wn.name = String(wall["id"])
			wn.set_script(ManiWall)
			wn.set("a", to_godot(segs[0][0], segs[0][1], segs[0][2]))
			wn.set("b", to_godot(segs[segs.size() - 1][0], segs[segs.size() - 1][1], segs[segs.size() - 1][2]))
			if wall.has("gloss"):  # the western mani wall's own (M2 sprint 6, step 6)
				wn.set("gloss", String(wall["gloss"]))
				wn.set("half", float(wall.get("half", 4.0)))
			root.add_child(wn)
			for q in segs + (wall["ends"] as Array):
				if not ResourceLoader.exists(KIT % q[4]):
					continue
				var piece: Node3D = (load(KIT % q[4]) as PackedScene).instantiate()
				piece.position = to_godot(q[0], q[1], q[2])
				piece.rotation.y = deg_to_rad(float(q[3]))
				wn.add_child(piece)
				placed += 1
			if wall.has("pitch") and ResourceLoader.exists(KIT % wall["pitch"]["at"][4]):
				var pa: Array = wall["pitch"]["at"]
				var pn: Node3D = (load(KIT % pa[4]) as PackedScene).instantiate()
				pn.name = String(wall["pitch"]["id"])
				pn.position = to_godot(pa[0], pa[1], pa[2])
				pn.rotation.y = -deg_to_rad(float(pa[3]) - 180.0)  # facing as a named building's (the kit's front at -y)
				root.add_child(pn)
				placed += 1
	var tp: Array = TSONGRA_STEPS["pos"]
	if bounds.has_point(Vector2(tp[0], tp[1])) and ResourceLoader.exists(KIT % TSONGRA_STEPS["file"]):
		var ts: Node3D = (load(KIT % TSONGRA_STEPS["file"]) as PackedScene).instantiate()
		ts.name = "SHL-01_steps"
		ts.position = to_godot(tp[0], tp[1], tp[2])
		root.add_child(ts)
		placed += 1
	var walls := 0
	if FileAccess.file_exists(WALLS % "index.json"):
		for c in JSON.parse_string(FileAccess.get_file_as_string(WALLS % "index.json"))["cells"]:
			if not bounds.intersects(Rect2(c["x0"], c["y0"], 128.0, 128.0)) or not ResourceLoader.exists(WALLS % c["file"]):
				continue
			var w: Node3D = (load(WALLS % c["file"]) as PackedScene).instantiate()
			w.position = to_godot(float(c["x0"]), float(c["y0"]), float(c["datum"]))
			root.add_child(w)
			walls += 1
	var logs := 0
	if FileAccess.file_exists(LADDERS):
		for l in JSON.parse_string(FileAccess.get_file_as_string(LADDERS))["ladders"]:
			if _ladder(root, l, "LADDER_%s" % l["house"], LOG_LEAN, bounds):
				logs += 1
	# a door's notched log (IMP-019): where a town house's later variant goes up by a log to the landing before its
	# first-floor door (the kit's sockets LOGFOOT and LOGTOP), a log of the length it needs, climbable as the roofs' are
	for h in root.get_children():
		if String(h.name).begins_with("H-") and String(h.name) != "H-MON-012":  # (the monk's house's log is inside, from its
			# store to its cell: hung below as DOORLOG_H-MON-012_1; hung here too it had stood twice, once as a door's)
			var foot := (h as Node3D).find_child("SOCK_LOGFOOT_1", true, false) as Node3D
			var top := (h as Node3D).find_child("SOCK_LOGTOP_1", true, false) as Node3D
			if foot != null and top != null and _door_log(root, String(h.name), foot.global_position, top.global_position):
				logs += 1
	# the headman's house's two logs inside (M2 sprint 7, step 1; chapter 04, 4.1): up from the stable through the
	# kitchen's trapdoor, and from the second floor's hall up through the hatch onto the roof
	var headman := root.get_node_or_null("SHL-19") as Node3D
	if headman != null:
		for k in [1, 2]:
			var foot := headman.find_child("SOCK_LOGFOOT_%d" % k, true, false) as Node3D
			var top := headman.find_child("SOCK_LOGTOP_%d" % k, true, false) as Node3D
			if foot != null and top != null and _door_log(root, "SHL-19_%d" % k, foot.global_position, top.global_position):
				logs += 1
				(root.get_node("DOORLOG_SHL-19_%d" % k) as Node3D).set_meta("indoors", true)  # under a ceiling (the ladders check)
	# the Tödé tower's logs (M3 sprint 4, step 3; ../tibet-blender kit/tode.py star_tower): eight inside from each floor up
	# through the next one's hatch (under its floors: indoors, as the headman's), the ninth outside from the ground before
	# its door up to its sill 6 m up (the kit's notched_log_70)
	var tower := root.get_node_or_null("TOD-01") as Node3D
	if tower != null:
		for k in range(1, 10):
			var foot := tower.find_child("SOCK_LOGFOOT_%d" % k, true, false) as Node3D
			var top := tower.find_child("SOCK_LOGTOP_%d" % k, true, false) as Node3D
			if foot != null and top != null and _door_log(root, "TOD-01_%d" % k, foot.global_position, top.global_position, [42] if k < 9 else [70]):
				logs += 1
				if k < 9:
					(root.get_node("DOORLOG_TOD-01_%d" % k) as Node3D).set_meta("indoors", true)
	# the Tsokchen's ladder from its main roof up the rear block's front onto its roof, V-05's terrace (M3 sprint 3, step 1:
	# the kit's LADFOOT and LADTOP sockets), a wall ladder of the length it needs, climbed as the roofs' are
	var tsok := root.get_node_or_null("MON-01") as Node3D
	if tsok != null:
		var lad_f := tsok.find_child("SOCK_LADFOOT_1", true, false) as Node3D
		var lad_t := tsok.find_child("SOCK_LADTOP_1", true, false) as Node3D
		if lad_f != null and lad_t != null and _wall_ladder(root, "MON-01", lad_f.global_position, lad_t.global_position):
			logs += 1
	# the hero monk's house's notched log from its store up through the trapdoor into its cell (M3 sprint 5, step 9), indoors
	var cell := root.get_node_or_null("H-MON-012") as Node3D
	if cell != null:
		var cf := cell.find_child("SOCK_LOGFOOT_1", true, false) as Node3D
		var ct := cell.find_child("SOCK_LOGTOP_1", true, false) as Node3D
		if cf != null and ct != null and _door_log(root, "H-MON-012_1", cf.global_position, ct.global_position):
			logs += 1
			(root.get_node("DOORLOG_H-MON-012_1") as Node3D).set_meta("indoors", true)
	# the stair-ladders indoors at their LADFOOT and LADTOP sockets: the Jampa Lhakhang's from its ground floor's dark
	# south-west corner up through the hatch to its gallery (M3 sprint 5, step 6; chapter 04, 3.2: "a two-rail stair-ladder at
	# 65 degrees, 4.5 m of climb"); the Parkhang's from its stair hall up to the printing room and from that room's east end
	# up to the block store (step 8; 3.6)
	for hid in ["MON-04", "RNG-10"]:
		var hall := root.get_node_or_null(hid) as Node3D
		if hall == null:
			continue
		for k in range(1, 4):
			var jf := hall.find_child("SOCK_LADFOOT_%d" % k, true, false) as Node3D
			var jt := hall.find_child("SOCK_LADTOP_%d" % k, true, false) as Node3D
			if jf == null or jt == null:
				break
			if _stair_ladder(root, hid if k == 1 else "%s_%d" % [hid, k], jf.global_position, jt.global_position):
				logs += 1
	var flights := 0
	for lanes_path in [LANES, DUNGRONG, GORGE, GONPA, TODE, TODE_STAIR, MONASTERY, GONKOR]:  # the town's lane stairs, the 1,080 steps' flights and landings, the Gorge Stair's
		if not FileAccess.file_exists(lanes_path):
			continue
		for ln in JSON.parse_string(FileAccess.get_file_as_string(lanes_path))["lanes"]:
			var fl = ln.get("flight")
			if fl == null or not ResourceLoader.exists(LANE_KIT % fl["file"]):
				continue
			var d: Array = ln["dir"]
			var o: Array = ln["from"]
			var p := Vector2(o[0], o[1]) + Vector2(d[0], d[1]) * float(fl["s"])
			if not bounds.has_point(p):
				continue
			var st: Node3D = (load(LANE_KIT % fl["file"]) as PackedScene).instantiate()
			st.name = "LANE_%s" % ln["id"]
			st.position = to_godot(p.x, p.y, float(fl["z"]))
			st.rotation.y = -atan2(float(d[0]), float(d[1]))
			root.add_child(st)
			flights += 1
	var way := 0
	if FileAccess.file_exists(ROOFTOP):
		var k := 0
		for pc in JSON.parse_string(FileAccess.get_file_as_string(ROOFTOP))["pieces"]:
			k += 1
			if pc.has("file") and _piece(root, pc, "WAY_%02d_%s" % [k, pc["kind"]], bounds):
				way += 1  # a side lane's flight is the lane's own (LANES)
	# the plank-and-rope bridges and the pieces that lead onto their roofs (tools/town/bridges.py; IMP-023 (3), Greg's
	# 1773): the one over the Sky Stair, a plank from the lane onto its west roof, a ladder up its east house's wall
	var bridges := 0
	if FileAccess.file_exists(BRIDGES):
		var bj = JSON.parse_string(FileAccess.get_file_as_string(BRIDGES))
		for br in bj["bridges"]:
			var a: Array = br["a"]
			if not bounds.has_point(Vector2(a[0], a[1])) or not ResourceLoader.exists(BRIDGE_KIT % br["file"]):
				continue
			var bn: Node3D = (load(BRIDGE_KIT % br["file"]) as PackedScene).instantiate()
			bn.name = "BRIDGE_%s" % br["id"]
			bn.position = to_godot(a[0], a[1], a[2])
			bn.rotation.y = -atan2(float(br["dir"][0]), float(br["dir"][1]))
			bn.add_to_group("bridges")
			bn.set_meta("sag", float(br["sag"]))  # world/flags.gd strings its flags along a hand rope
			root.add_child(bn)
			var ea := to_godot(a[0], a[1], a[2])
			var eb := to_godot(float(br["b"][0]), float(br["b"][1]), float(br["b"][2]))
			for mi in bn.find_children("*", "MeshInstance3D", true, false):  # its deck gives under the walker (IMP-027)
				(mi as MeshInstance3D).set_instance_shader_parameter("give", 0.06)
				(mi as MeshInstance3D).set_instance_shader_parameter("give_ends", Vector4(ea.x, ea.z, eb.x, eb.z))
			bridges += 1
		var k := 0
		for pc in bj["pieces"]:
			k += 1
			if _piece(root, pc, "BRIDGE_%s_%02d_%s" % [pc["bridge"], k, pc["kind"]], bounds):
				bridges += 1
	# the arrival by the Serchu road (M2 sprint 3): the cliff gallery and the cutting's rock
	var arrival := 0
	if FileAccess.file_exists(ARRIVAL_KIT):
		var aj = JSON.parse_string(FileAccess.get_file_as_string(ARRIVAL_KIT))
		for pc in aj["pieces"]:
			var a: Array = pc["from"]
			var path := ARRIVAL_KIT.get_base_dir() + "/" + String(pc["file"])
			if not bounds.has_point(Vector2(a[0], a[1])) or not ResourceLoader.exists(path):
				continue
			var an: Node3D = (load(path) as PackedScene).instantiate()
			an.name = "ARRIVAL_%s" % String(pc["file"]).get_basename()
			an.position = to_godot(a[0], a[1], a[2])
			an.rotation.y = -atan2(float(pc["dir"][0]), float(pc["dir"][1]))
			an.add_to_group("arrival")
			root.add_child(an)
			arrival += 1
	# upper Shöl's walled gardens (SHL-33; M2 sprint 6, step 4): their trees on the slope, each its own variant, turn and
	# size, a little sunk into the ground; and a door into each plot from the lane, on its wall's face (tools/town/gardens.py)
	var garden_trees := 0
	if FileAccess.file_exists(GARDENS):
		var gd = JSON.parse_string(FileAccess.get_file_as_string(GARDENS))
		for t in gd["trees"]:
			var ta: Array = t["at"]
			var tf := KIT % ("tree_%s_v%d" % [String(t["kind"]), 1 + int(t["seed"]) % int(TREE_VARIANTS[String(t["kind"])])])
			if not bounds.has_point(Vector2(ta[0], ta[1])) or not ResourceLoader.exists(tf):
				continue
			var tn: Node3D = (load(tf) as PackedScene).instantiate()
			tn.name = "TREE_%d_%s" % [garden_trees, String(t["kind"])]
			tn.position = to_godot(float(ta[0]), float(ta[1]), float(ta[2]) - 0.15)
			tn.rotation.y = fposmod(float(t["seed"]) * 0.618, 1.0) * TAU
			tn.scale = Vector3.ONE * float(t["size"])
			root.add_child(tn)
			garden_trees += 1
		for gt in gd["gates"]:
			var ga: Array = gt["at"]
			var df := KIT % ("garden_door_v%d" % (1 + int(gt["plot"]) % 3))
			if not bounds.has_point(Vector2(ga[0], ga[1])) or not ResourceLoader.exists(df):
				continue
			var dn: Node3D = (load(df) as PackedScene).instantiate()
			dn.name = "GARDEN_DOOR_%d" % int(gt["plot"])
			dn.position = to_godot(float(ga[0]), float(ga[1]), float(ga[2]))
			dn.rotation.y = -deg_to_rad(float(gt["facing"]) - 180.0)
			root.add_child(dn)
	# the lower cantilever bridge SAM-05: its flags along a rail (world/flags.gd)
	var sam05 := root.get_node_or_null("SAM-05") as Node3D
	if sam05 != null:
		sam05.add_to_group("bridges")
		sam05.set_meta("sag", 0.4)
		sam05.set_meta("hand", 1.45)
	# the cantilever bridges' corner poles strung with flags over their decks (world/flags.gd; M3 sprint 2, step 2): the
	# poles' way out from the middle, the kit's deck width / 2 + 0.3 (../tibet-blender kit/infra.py cantilever_bridge)
	for cb in [["SAM-05", 3.0], ["SER-04", 3.0], ["RNG-01", 2.0], ["RNG-02", 2.2]]:
		var cn := root.get_node_or_null(String(cb[0])) as Node3D
		if cn != null:
			cn.add_to_group("bridges")
			cn.set_meta("poles", float(cb[1]) / 2.0 + 0.3)
	# the Bön chapel TOD-02's four wheels in their niches by the door (M3 sprint 4, step 6), turned anticlockwise
	var bon := root.get_node_or_null("TOD-02") as Node3D
	if bon != null:
		var bw := KoraWheels.new()
		bw.name = "KoraWheels"
		bw.sense = -1.0
		bon.add_child(bw)
		print("town: the Bön chapel's wheels: %d" % bw.setup(bon))
	# the Tsokchen's Nangkor (M3 sprint 5, step 1): its 24 wheels on their ledge along the corridor round the inner chapel,
	# turned under a passing hand (world/kora_wheels.gd)
	var nangkor := root.get_node_or_null("MON-01") as Node3D
	if nangkor != null:
		var nkw := KoraWheels.new()
		nkw.name = "KoraWheels"
		nangkor.add_child(nkw)
		print("town: the Tsokchen's Nangkor: %d wheels" % nkw.setup(nangkor))
	# Pema Ö's kora corridor (M2 sprint 5, step 4): its 36 wheels, turned under hands (world/kora_wheels.gd)
	var pema := root.get_node_or_null("SHL-11") as Node3D
	if pema != null:
		var kw := KoraWheels.new()
		kw.name = "KoraWheels"
		pema.add_child(kw)
		print("town: Pema Ö's kora: %d wheels" % kw.setup(pema))
	# the Gönkor's prayer-wheel galleries MON-22a to h on the monastery wall's south line, each its sixteen wheels turned under a
	# passing hand (world/kora_wheels.gd), and the great wheel house MON-23's 3.5 m wheel at its WHEEL socket, walked round
	# inside and its bell struck once a turn (world/great_wheel.gd; M3 sprint 3, step 6)
	var gonkor := 0
	for gid in ["MON-22a", "MON-22b", "MON-22c", "MON-22d", "MON-22e", "MON-22f", "MON-22g", "MON-22h"]:
		var gal := root.get_node_or_null(gid) as Node3D
		if gal != null:
			var gw := KoraWheels.new()
			gw.name = "KoraWheels"
			gal.add_child(gw)
			gonkor += gw.setup(gal)
	if gonkor > 0:
		print("town: the Gönkor's galleries: %d wheels" % gonkor)
	var wheel_house := root.get_node_or_null("MON-23") as Node3D
	if wheel_house != null and ResourceLoader.exists(KIT % "great_wheel_35_v1"):
		var wsock := wheel_house.find_child("SOCK_WHEEL_1", true, false) as Node3D
		if wsock != null:
			var gw35: Node3D = (load(KIT % "great_wheel_35_v1") as PackedScene).instantiate()
			gw35.name = "MON-23_wheel"
			gw35.set_script(GreatWheel)
			gw35.set("bell", wheel_house.find_child("SOCK_BELL_1", true, false))
			root.add_child(gw35)
			gw35.global_transform = wsock.global_transform
	# Dechen-tsang at night (M2 sprint 8, step 4): its gate barred at 22:00, the mastiffs loose in Yard 1 (world/dechen_night.gd)
	var dechen_h := root.get_node_or_null("SHL-04") as Node3D
	if dechen_h != null:
		var dn := DechenNight.new()
		dn.name = "Night"
		dechen_h.add_child(dn)
		print("town: Dechen-tsang's night: %s" % ("its gate and two mastiffs" if dn.setup() else "no gate (the kit's dechen_gate_leaf)"))
	# Samkha Khar's gate (M2 sprint 4, step 4): the passage's leaves and bar, shut at the dusk horns (world/castle_gate.gd)
	var castle := root.get_node_or_null("SAM-01") as Node3D
	if castle != null:
		var gate := CastleGate.new()
		gate.name = "Gate"
		castle.add_child(gate)
		gate.setup(castle)
	# Samkha's chain bridge (M2 sprint 4): its flags strung along a hand chain (world/flags.gd), its sway
	if FileAccess.file_exists(SAMKHA_KIT):
		for pc in (JSON.parse_string(FileAccess.get_file_as_string(SAMKHA_KIT)) as Dictionary)["pieces"]:
			var a: Array = pc["from"]
			var path := SAMKHA_KIT.get_base_dir() + "/" + String(pc["file"])
			if not bounds.has_point(Vector2(a[0], a[1])) or not ResourceLoader.exists(path):
				continue
			var sn: Node3D = (load(path) as PackedScene).instantiate()
			sn.name = String(pc["id"])
			sn.position = to_godot(a[0], a[1], a[2])
			sn.rotation.y = -atan2(float(pc["dir"][0]), float(pc["dir"][1]))
			sn.add_to_group("bridges")
			sn.set_meta("sag", float(pc["sag"]))
			sn.set_meta("hand", 0.86)
			root.add_child(sn)
			var e0 := sn.position
			var e1 := to_godot(a[0] + float(pc["dir"][0]) * float(pc["length"]), a[1] + float(pc["dir"][1]) * float(pc["length"]), a[2] + float(pc["rise"]))
			var sw := ChainBridge.new()
			sw.name = "Sway"
			sn.add_child(sw)
			sw.setup(sn, e0, e1)
			arrival += 1
	# the eight chortens SER-02 on their row, from birth at its east end to nirvana at its west, their vases' niches to
	# the south, where the westbound road passes keeping them on its right; each set into the row's slope by its plinth
	if FileAccess.file_exists(ARRIVAL):
		var row: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(ARRIVAL)) as Dictionary).get("row", {})
		if not row.is_empty() and bounds.has_point(Vector2(float(row["from_x"]), float(row["y"]))):
			var x0 := float(row["from_x"])
			var x1 := float(row["to_x"])
			for k in 8:
				var f := "chorten8_f%d_v1" % (k + 1)
				if not ResourceLoader.exists(KIT % f):
					continue
				var x := x0 + (x1 - x0) * k / 7.0
				var z := float(row["z_from"]) + (float(row["z_to"]) - float(row["z_from"])) * (x0 - x) / (x0 - x1)
				var c: Node3D = (load(KIT % f) as PackedScene).instantiate()
				c.name = "SER-02_%d" % (k + 1)
				c.position = to_godot(x, float(row["y"]), z - 0.3)
				root.add_child(c)
				arrival += 1
	# a way onto every roof the town can reach (tools/town/roof_ways.py; IMP-026): logs, stair-ladders, planks from the
	# upper yards, steps, a tall ladder up a wall where a run of roofs has no other
	var roof_ways := 0
	if FileAccess.file_exists(ROOF_WAYS):
		for pc in JSON.parse_string(FileAccess.get_file_as_string(ROOF_WAYS))["pieces"]:
			if _piece(root, pc, "ROOF_%s_%s" % [String(pc["deck"]).replace(".", "_"), pc["kind"]], bounds):
				roof_ways += 1
	# the day's turns at dusk: the sang's smoke at every roof burner, the horns, the ladders drawn up (world/dusk.gd)
	var dusk := Dusk.new()
	dusk.name = "Dusk"
	root.add_child(dusk)
	# the lamps at dusk: the Mani Lhakhang's altar, the tunnel's niche, the burners' embers, the fire in Dechen-tsang's
	# yard (world/lamps.gd; IMP-021 (3))
	var lamps := Lamps.new()
	lamps.name = "Lamps"
	root.add_child(lamps)
	var lmc: Dictionary = lamps.build(root, dusk.sang_socks, dusk._base)
	# the shafts of sun through the halls' windows: the Tsokchen's lantern (world/shafts.gd from data/sun_tables.json,
	# tools/town/sun_table.py; M3 sprint 5, step 4)
	var shafts := SunShafts.new()
	shafts.name = "Shafts"
	root.add_child(shafts)
	# the Caravan Ground's things: the windbreaks of stacked loads, the hay piles, the fodder yard, the dung-drying walls,
	# each caravan's from its hour (world/camp.gd; M2 sprint 9, step 1)
	var camp := Camp.new()
	camp.name = "Camp"
	root.add_child(camp)
	var cmc: Dictionary = camp.build(bounds)
	print("town: the Caravan Ground: %d things%s" % [cmc["things"], (", %d kit files missing" % cmc["missing"]) if cmc["missing"] > 0 else ""])
	# Tsongra's market on the market day: its stalls set up for the morning (world/market.gd; M2 sprint 10, step 4)
	var market := Market.new()
	market.name = "Market"
	root.add_child(market)
	var mkc: Dictionary = market.build()
	print("town: Tsongra's market: %d stalls%s" % [mkc["stalls"], (", %d kit files missing" % mkc["missing"]) if mkc["missing"] > 0 else ""])
	# the slice's viewpoints: sat at, the camera drifts out to a composed frame and the town's sounds settle
	# (world/viewpoints.gd; IMP-021 (5), IMP-024)
	var viewpoints := Viewpoints.new()
	viewpoints.name = "Viewpoints"
	root.add_child(viewpoints)
	# the moments (world/moments.gd; chapter 08, 2; M2 sprint 3): the Gate Chorten's reveal, the town unheard on the
	# gallery and rising as the player comes out under the chorten
	var moments := Moments.new()
	moments.name = "Moments"
	root.add_child(moments)
	print("town: lamps: %d on the Mani Lhakhang's altar, %d in the tunnel, %d embers, the yard fire %s" % [lmc["altar"], lmc["tunnel"], lmc["embers"], lmc["fire"]])
	# the rooms behind Dechen-tsang's doors, streamed in as the player comes (world/interiors.gd; sprint 7)
	var interiors := Interiors.new()
	interiors.name = "Interiors"
	root.add_child(interiors)
	# the room doors that open and shut, hung at the leaves the kit marks (world/doors.gd; ISS-105): the three houses to
	# enter and Dechen-tsang's kitchen
	var doors := Doors.new()
	doors.name = "Doors"
	root.add_child(doors)
	print("town: doors: %d that open and shut" % doors.build(root))
	# the halls' yak-hair curtains, parted by whoever comes through (world/curtains.gd; M3 sprint 6, step 1)
	var curtains := Curtains.new()
	curtains.name = "Curtains"
	root.add_child(curtains)
	print("town: curtains: %d in the halls' doorways" % curtains.build(root))
	# boots off at the halls' thresholds, and the Gönkhang's keeper and its rule (world/boots.gd; M3 sprint 6, step 2)
	var boots := Boots.new()
	boots.name = "Boots"
	root.add_child(boots)
	print("town: boots: the halls' thresholds, the Gönkhang's keeper %d" % boots.build(root))
	# the Tsokchen's day and the Labrang's: the tea passes, the lay visitors, the sweepers, the shut door, the incense, the
	# tulku's reception (world/hall_day.gd; M3 sprint 6, step 3)
	var hall_day := HallDay.new()
	hall_day.name = "HallDay"
	root.add_child(hall_day)
	print("town: the halls' day: %d people" % hall_day.build(root))
	# where the slice's codex nods are found by looking, going in or being there (world/codex_sites.gd; sprint 7)
	var sites := CodexSites.new()
	sites.name = "CodexSites"
	root.add_child(sites)
	# the town's lines to and around the player, in Tibetan and Chinese with the English under them (world/barks.gd; sprint 7)
	var barks := Barks.new()
	barks.name = "Barks"
	root.add_child(barks)
	# the outdoors' reverb areas: the Sky Stair's lane, tunnel and gateway, and Tsongra (world/reverb_zones.gd; sprint 8)
	var zones := ReverbZones.new()
	zones.name = "ReverbZones"
	root.add_child(zones)
	zones.setup(root.get_node_or_null("SHL-15") as Node3D, root.get_node_or_null("SHL-17") as Node3D)
	zones.add_passage("RZ-22", root.get_node_or_null("SER-01") as Node3D, Vector3(2.4, 3.0, 7.4))  # the Gate Chorten's dead stone room
	# each household its own: its lime, its paint, its tone; lived in, shut, or left for good (world/households.gd; IMP-019)
	var households := Households.new()
	households.name = "Households"
	root.add_child(households)
	var hh: Dictionary = households.build(root)
	print("town: households: %d, %d shut, %d of them left" % [hh["houses"], hh["shut"], hh["left"]])
	# the prayer flags: poles on the roofs' piers, strings between houses, banners on the courtyard poles, each house its
	# own (world/flags.gd; sprint 8, after Greg's walk): a left house's bare poles, a shut one's flags unrenewed
	var flags := Flags.new()
	flags.name = "Flags"
	root.add_child(flags)
	var fc: Dictionary = flags.build(root, households)
	print("town: flags: %d poles on %d houses, %d strings, %d banners, %d flags, heard from %d places" % [fc["poles"], fc["houses"], fc["lines"], fc["banners"], fc["flags"], flags.rustle.size()])
	# each household's things at its door: a yak skull, a thread cross, mani stones, Losar's marks; a shut house's bar
	# (world/door_dressing.gd; IMP-019)
	var dressing := DoorDressing.new()
	dressing.name = "DoorDressing"
	root.add_child(dressing)
	var dd: Dictionary = dressing.build(root, households)
	print("town: door dressing: %d of %d doors dressed, %d barred, %d things" % [dd["dressed"], dd["doors"], dd["barred"], dd["items"]])
	# the washing hung out to dry, across a third of the yards and on a few roofs, parting round the walker (world/laundry.gd;
	# IMP-023, Greg's 1775)
	var laundry := Laundry.new()
	laundry.name = "Laundry"
	root.add_child(laundry)
	var lc: Dictionary = laundry.build(root, households)
	print("town: laundry: %d lines (%d on roofs), %d pieces, %d of them robes" % [lc["lines"], lc["roofs"], lc["pieces"], lc["robes"]])
	# what each household keeps by its walls: firewood, dung cakes, pots, sacks, a basket, a churn, juniper, a book
	# (world/corners.gd; IMP-023, Greg's 1781)
	var corners := Corners.new()
	corners.name = "Corners"
	root.add_child(corners)
	var cc: Dictionary = corners.build(root, households)
	print("town: corners: %d things by the walls of %d houses" % [cc["things"], cc["houses"]])
	# the Shade Wood SER-16 above the Serchu road and on the south rim (world/forest.gd; M2 sprint 12, step 4)
	var forest := Forest.new()
	forest.name = "Forest"
	root.add_child(forest)
	var ft := forest.build()
	print("town: the Shade Wood: %d trees in %d cells" % [ft, forest.cells])
	# the hearths' smoke at each household's hours, out of its kitchen's window (world/hearths.gd; sprint 8, step 2)
	var hearths := Hearths.new()
	hearths.name = "Hearths"
	root.add_child(hearths)
	var hn := hearths.build(root, flags, households)
	print("town: hearths: %d threads, %d cold or left" % [hn, hearths.cold.size()])
	# the town's work heard from the worker: Pasang's chisel at his pitch (world/work_sounds.gd; sprint 8, step 4)
	var work := WorkSounds.new()
	work.name = "WorkSounds"
	root.add_child(work)
	# V-28's people on the near roofs at dusk (world/roof_people.gd; sprint 8, step 6)
	var roofp := RoofPeople.new()
	roofp.name = "RoofPeople"
	root.add_child(roofp)
	var rp := roofp.build(root, func(x: float, y: float, z: float) -> Vector3: return to_godot(x, y, z), households)
	print("town: roof people: %d on the roofs near V-28 at dusk" % rp)
	# upper Shöl's people crossing the bridge over the Sky Stair now and then (world/bridge_people.gd; IMP-027)
	var brp := BridgePeople.new()
	brp.name = "BridgePeople"
	root.add_child(brp)
	print("town: bridge people: %d crossings of the bridge over the Sky Stair" % brp.build(root, func(x: float, y: float, z: float) -> Vector3: return to_godot(x, y, z)))
	# who is there at Samkha: the toll steward, the gatekeeper, the Pönpo on his roof, the castle's mastiffs, the day's
	# crossings of the chain bridge (world/samkha_people.gd; M2 sprint 4, step 6)
	var skp := SamkhaPeople.new()
	skp.name = "SamkhaPeople"
	root.add_child(skp)
	print("town: Samkha's people: %d" % skp.build(root))
	# who is on the Serchu road: the day's carriers, pilgrims, tenants and woodcutters, the gold washers at work and at
	# their fires, the millers, the woodcutters by their trees (world/serchu_people.gd; M2 sprint 12, step 6)
	var srp := SerchuPeople.new()
	srp.name = "SerchuPeople"
	root.add_child(srp)
	print("town: the Serchu road's people: %d" % srp.build(root))
	# who is on the 1,080 steps: pilgrims climbing with their rosaries, monks down and up, novices, and on the Double Ninth
	# Hejie's party at the Lhabab Chorten (world/steps_people.gd; M3 sprint 1, step 5)
	var stp := StepsPeople.new()
	stp.name = "StepsPeople"
	root.add_child(stp)
	print("town: the steps' people: %d trips" % stp.build(root))
	# who uses the Gorge Stair: Tödé's monks down and up, its water carriers to the channel's head, the old monk at the
	# rest gallery's wheel, two novices racing down, and on the full moon the tulku's afternoon home (world/gorge_people.gd;
	# M3 sprint 2, step 6)
	var gp := GorgePeople.new()
	gp.name = "GorgePeople"
	root.add_child(gp)
	print("town: the Gorge Stair's people: %d acts" % gp.build(root))
	# Tödé's people from their doors (tools/town/tode_days.py; M3 sprint 4, step 6): the Bön circuit at dawn, the threshers
	# at the floors and on the roofs with their flails, the millers, the water carriers at the leat, the traders down to
	# Shöl and back (world/tode_people.gd)
	var tdp := TodePeople.new()
	tdp.name = "TodePeople"
	root.add_child(tdp)
	print("town: Tödé's people: %d acts" % tdp.build(root))
	# the Tsokchen's assemblies: the monks seated in their rows at dawn, at the general tea and at the evening recitation
	# (world/assembly.gd; M3 sprint 5, step 5)
	var asm := Assembly.new()
	asm.name = "Assembly"
	root.add_child(asm)
	print("town: the Tsokchen's assembly: %d places" % asm.build(root))
	# the dawn and dusk horns' players on the Tsokchen's roof terrace, the call lifted and blown, the novice by the
	# ladder-stair's head (world/horns.gd; M3 sprint 6, step 5)
	var horns := Horns.new()
	horns.name = "Horns"
	root.add_child(horns)
	print("town: the horns: %d players on the Tsokchen's roof" % horns.build(root))
	# the ula yard's day: the animals owed at its rings, the headman's men's count, the scribe, the Pönpo's mule
	# (world/ula_yard.gd; M2 sprint 11, step 3)
	var uy := UlaYard.new()
	uy.name = "UlaYard"
	root.add_child(uy)
	print("town: the ula yard: %d animals and people" % uy.build(root))
	# who is there at Pema Ö at first sun: the lama to the terrace's lip, the monks at the bowls, the old woman on the
	# kora, the dipper (world/pema_o_people.gd; M2 sprint 5, step 5)
	var pop := PemaOPeople.new()
	pop.name = "PemaOPeople"
	root.add_child(pop)
	print("town: Pema Ö's people: %d" % pop.build(root))
	# V-02's dawn at the confluence: the pool's mist and the conch's glint (world/confluence_dawn.gd; M2 sprint 5, step 6)
	var cd := ConfluenceDawn.new()
	cd.name = "ConfluenceDawn"
	root.add_child(cd)
	print("town: the confluence's dawn: %s" % cd.build())
	# the Lukhang spring's water carriers: the queue at its spouts at dawn and after three, the talk behind it, the milk on
	# the naga's rock; its spouts heard (world/spring.gd; M2 sprint 6, step 3)
	var spring := Spring.new()
	spring.name = "Spring"
	root.add_child(spring)
	print("town: the Lukhang spring: %d visits a day" % spring.build(root))
	# the headman's house's moments: the mastiff at the gate, the headman's seat, the hatch at night, the locked chests
	# (world/headman_house.gd; M2 sprint 7, step 5)
	var hm := HeadmanHouse.new()
	hm.name = "HeadmanHouse"
	root.add_child(hm)
	print("town: the headman's house: %s" % ("its mastiff, its seat, its hatch" if hm.build(root) else "not placed"))
	# talking with the town's people: the story's conversations (world/conversation.gd; M2 sprint 1, step 2)
	var conv := Conversation.new()
	conv.name = "Conversation"
	root.add_child(conv)
	print("town: conversations: %d" % conv.talks.size())
	var tk := Talks.new()  # and the talk overheard in the rooms (world/talks.gd; M2 sprint 2, step 3)
	tk.name = "Talks"
	root.add_child(tk)
	# a child of the house who leads the way up the Rooftop Way from 16:40 (world/guide.gd; sprint 8, step 8; M1's walk 5)
	var guide := Guide.new()
	guide.name = "Guide"
	root.add_child(guide)
	print("town: the guide: %d pieces of the Rooftop Way" % guide.build(func(x: float, y: float, z: float) -> Vector3: return to_godot(x, y, z)))
	# the birds on the wing, each flock its own: choughs round the monastery, the ritro cliff and Shöl's roofs, ravens in
	# pairs, griffons on the midday thermals (world/birds.gd; sprint 8, step 2)
	var birds := Birds.new()
	birds.name = "Birds"
	root.add_child(birds)
	var bc: Dictionary = birds.build(func(x: float, y: float, z: float) -> Vector3: return to_godot(x, y, z))
	print("town: birds: %d choughs, %d ravens, %d griffons in %d flocks" % [bc["chough"], bc["raven"], bc["griffon"], bc["flocks"]])
	return {"placed": placed, "files": cache.size(), "waiting": waiting, "walls": walls, "ladders": logs, "lane_flights": flights, "way": way, "garden_trees": garden_trees,
			"bridges": bridges, "roof_ways": roof_ways, "arrival": arrival, "burners": dusk.burners}


## The thresholds a kit type's doorways carry (its sidecar's `sills`: the kit's frame), as markers in the group "sills"
## for the player's step-over (player/player.gd; chapter 04, 10: stepped over, never on): each at the sill's middle on
## the ground it stands on, its -Z the way across into the building, with the sill's width, height and depth.
static func _add_sills(node: Node3D, f: String) -> void:
	var side_path := (KIT % f).get_basename() + ".json"
	if not FileAccess.file_exists(side_path):
		return
	var side = JSON.parse_string(FileAccess.get_file_as_string(side_path))
	if not (side is Dictionary) or not (side as Dictionary).has("sills"):
		return
	var k := 0
	for sl in side["sills"]:
		var m := Marker3D.new()
		k += 1
		m.name = "SILL_%d" % k
		var a := deg_to_rad(float(sl[3]))
		var way := Vector3(cos(a), 0.0, -sin(a))  # the kit's (x, y) is Godot's (x, -z)
		m.transform = Transform3D(Basis.looking_at(way, Vector3.UP), Vector3(float(sl[0]), float(sl[2]), -float(sl[1])))
		m.set_meta("w", float(sl[4]))
		m.set_meta("h", float(sl[5]))
		m.set_meta("d", float(sl[6]))
		m.add_to_group("sills")
		node.add_child(m)


## The door leaves a kit type's room doors carry (its sidecar's `leaves`: the kit's frame; ISS-105), as markers in the group
## "door_leaves" at their hinges, for world/doors.gd to hang the leaves on and swing: each with the leaf's way shut and
## open (degrees, the kit's from +x), its width and height and its kit type.
static func _add_leaves(node: Node3D, f: String) -> void:
	var side_path := (KIT % f).get_basename() + ".json"
	if not FileAccess.file_exists(side_path):
		return
	var side = JSON.parse_string(FileAccess.get_file_as_string(side_path))
	if not (side is Dictionary) or not (side as Dictionary).has("leaves"):
		return
	var k := 0
	for lf in side["leaves"]:
		var m := Marker3D.new()
		k += 1
		m.name = "LEAF_%d" % k
		m.position = Vector3(float(lf[0]), float(lf[2]), -float(lf[1]))  # the kit's (x, y, z) is Godot's (x, z, -y)
		m.set_meta("shut", float(lf[3]))
		m.set_meta("open", float(lf[4]))
		m.set_meta("w", float(lf[5]))
		m.set_meta("h", float(lf[6]))
		m.set_meta("type", String(lf[7]))
		m.add_to_group("door_leaves")
		node.add_child(m)


## The yak-hair curtains a kit type's doorways hang (its sidecar's `curtains`: the kit's frame; M3 sprint 6, step 1): the
## kit's own curtain type at each, from its top's middle, turned to the way in, in the group "curtains" with its width and
## height, for world/curtains.gd to part as the player and the walkers come through.
static func _add_curtains(node: Node3D, f: String) -> void:
	var side_path := (KIT % f).get_basename() + ".json"
	if not FileAccess.file_exists(side_path):
		return
	var side = JSON.parse_string(FileAccess.get_file_as_string(side_path))
	if not (side is Dictionary) or not (side as Dictionary).has("curtains"):
		return
	var k := 0
	for c in side["curtains"]:
		var path := KIT % (String(c[6]) + "_v1")
		if not ResourceLoader.exists(path):
			push_warning("town: no %s for %s's curtain: export it (../tibet-blender export_types.py)" % [String(c[6]), node.name])
			continue
		var cn: Node3D = (load(path) as PackedScene).instantiate()
		k += 1
		cn.name = "CURTAIN_%d" % k
		cn.position = Vector3(float(c[0]), float(c[2]), -float(c[1]))  # the kit's (x, y, z) is Godot's (x, z, -y)
		cn.rotation.y = deg_to_rad(float(c[3]) - 90.0)  # the type's way in (its +y) to the doorway's
		cn.set_meta("w", float(c[4]))
		cn.set_meta("h", float(c[5]))
		cn.add_to_group("curtains")
		node.add_child(cn)


## A notched log from its foot to the edge of a door's landing (Godot points; IMP-019), the shortest of the kit's logs
## that reaches past it, leaning at its own angle, in the group "ladders" for the player's climb as the roofs' logs are;
## "from" the door, which dusk leaves standing (world/dusk.gd draws up only the ground's).
static func _door_log(root: Node3D, house: String, foot: Vector3, top: Vector3, sizes: Array = [24, 30, 36, 42]) -> bool:
	var length := foot.distance_to(top)
	var file := ""
	for l in sizes:  # (the kit's notched logs, decimetres; the Tödé tower's door's own 7.0 m)
		if float(l) / 10.0 >= length + 0.2:
			file = "notched_log_%d_v1" % l
			break
	if file == "" or not ResourceLoader.exists(KIT % file):
		return false
	var lg: Node3D = (load(KIT % file) as PackedScene).instantiate()
	lg.name = "DOORLOG_%s" % house
	var bearing := atan2(top.x - foot.x, -(top.z - foot.z))  # clockwise from north (the town grid's +y is Godot's -z)
	var lean := atan2(top.y - foot.y, Vector2(top.x - foot.x, top.z - foot.z).length())
	var yaw := Basis(Vector3.UP, -bearing)
	lg.transform = Transform3D(yaw * Basis(Vector3.RIGHT, lean - deg_to_rad(LOG_LEAN)), foot)
	lg.set_meta("parapet", top)
	lg.set_meta("way", yaw * Vector3.FORWARD)
	lg.set_meta("from", "door")
	lg.add_to_group("ladders")
	root.add_child(lg)
	return true


## A building's own ladder up a wall from its foot to the parapet it rests on (Godot points): the kit's wall ladder long
## enough (8, 9 or 10 m, built at WALL_LEAN), its foot on a roof, in the group "ladders" for the player's climb.
static func _wall_ladder(root: Node3D, house: String, foot: Vector3, top: Vector3) -> bool:
	var length := foot.distance_to(top)
	var file := ""
	for l in [80, 90, 100]:
		if float(l) / 10.0 >= length:
			file = "wall_ladder_%d_v1" % l
			break
	if file == "" or not ResourceLoader.exists(KIT % file):
		return false
	var lg: Node3D = (load(KIT % file) as PackedScene).instantiate()
	lg.name = "LADDER_%s" % house
	var bearing := atan2(top.x - foot.x, -(top.z - foot.z))
	var lean := atan2(top.y - foot.y, Vector2(top.x - foot.x, top.z - foot.z).length())
	var yaw := Basis(Vector3.UP, -bearing)
	lg.transform = Transform3D(yaw * Basis(Vector3.RIGHT, lean - deg_to_rad(WALL_LEAN)), foot)
	lg.set_meta("parapet", top)
	lg.set_meta("way", yaw * Vector3.FORWARD)
	lg.set_meta("from", "roof")  # (its foot on a roof: world/dusk.gd leaves it at dusk)
	lg.add_to_group("ladders")
	root.add_child(lg)
	return true


## A stair-ladder inside a building from its foot to the floor it rises to (Godot points): the kit's stair_ladder_50, 60
## or 70 at its 65 degrees, the shortest that reaches, turned to its way, in the group "ladders", indoors (M3 sprint 5).
static func _stair_ladder(root: Node3D, house: String, foot: Vector3, top: Vector3) -> bool:
	var length := foot.distance_to(top)
	var file := ""
	for l in [40, 45, 50, 60, 70]:
		if float(l) / 10.0 >= length - 0.05:
			file = "stair_ladder_%d_v1" % l
			break
	if file == "" or not ResourceLoader.exists(KIT % file):
		return false
	var lg: Node3D = (load(KIT % file) as PackedScene).instantiate()
	lg.name = "LADDER_%s" % house
	var bearing := atan2(top.x - foot.x, -(top.z - foot.z))
	var lean := atan2(top.y - foot.y, Vector2(top.x - foot.x, top.z - foot.z).length())
	var yaw := Basis(Vector3.UP, -bearing)
	lg.transform = Transform3D(yaw * Basis(Vector3.RIGHT, lean - deg_to_rad(STAIR_LEAN)), foot)
	lg.set_meta("parapet", top)
	lg.set_meta("way", yaw * Vector3.FORWARD)
	lg.set_meta("from", "floor")
	lg.set_meta("indoors", true)
	lg.add_to_group("ladders")
	root.add_child(lg)
	return true


## A notched log or a stair-ladder from its foot to the parapet or wall top it rests on (town-grid points), leaning at
## its own angle (the kit's piece, built at `built` degrees, turned by the difference), in the group "ladders" for the
## player's climb, with the top it rests on and its way (level, from the foot towards the wall) as metadata.
## A piece of the Rooftop Way or of a bridge's way onto its roofs (rooftop.json, bridges.json): a notched log, a stair-
## ladder or a ladder up a wall (climbed, as the ladders), roof-terrace steps, or a plank laid from its near end towards
## its far one. True if placed.
static func _piece(root: Node3D, pc: Dictionary, node_name: String, bounds: Rect2) -> bool:
	if not ResourceLoader.exists(KIT % pc["file"]):
		return false
	match String(pc["kind"]):
		"log", "stair", "wall":
			return _ladder(root, pc, node_name, {"log": LOG_LEAN, "stair": STAIR_LEAN, "wall": WALL_LEAN}[String(pc["kind"])], bounds)
		"steps":
			var q: Array = pc["pos"]
			var sp: Node3D = (load(KIT % pc["file"]) as PackedScene).instantiate()
			sp.name = node_name
			sp.position = to_godot(q[0], q[1], q[2])
			sp.rotation.y = -deg_to_rad(float(pc["bearing"]))
			root.add_child(sp)
			return true
		"plank":
			var a: Array = pc["from"]
			var b: Array = pc["to"]
			var pa := to_godot(a[0], a[1], a[2])
			var pb := to_godot(b[0], b[1], b[2])
			var flat := Vector2(pb.x - pa.x, pb.z - pa.z)
			var yaw := Basis(Vector3.UP, atan2(-flat.x, -flat.y))
			var pk: Node3D = (load(KIT % pc["file"]) as PackedScene).instantiate()
			pk.name = node_name
			# the kit's plank spans its length (plank_bridge_N: N metres): centred on the gap, it rests alike on both ends
			var span := float(String(pc["file"]).get_slice("_", 2))
			var along := (pb - pa).normalized()
			pk.transform = Transform3D(yaw * Basis(Vector3.RIGHT, atan2(pb.y - pa.y, flat.length())), (pa + pb) / 2.0 - along * span / 2.0)
			root.add_child(pk)
			return true
	return false


static func _ladder(root: Node3D, l: Dictionary, node_name: String, built: float, bounds: Rect2) -> bool:
	var f: Array = l["foot"]
	var t: Array = l["top"]
	if not bounds.has_point(Vector2(f[0], f[1])) or not ResourceLoader.exists(KIT % l["file"]):
		return false
	var lg: Node3D = (load(KIT % l["file"]) as PackedScene).instantiate()
	lg.name = node_name
	var yaw := Basis(Vector3.UP, -deg_to_rad(float(l["bearing"])))
	lg.transform = Transform3D(yaw * Basis(Vector3.RIGHT, deg_to_rad(float(l["lean"]) - built)), to_godot(f[0], f[1], f[2]))
	lg.set_meta("parapet", to_godot(t[0], t[1], t[2]))
	lg.set_meta("way", yaw * Vector3.FORWARD)
	lg.set_meta("from", String(l.get("from", "")))  # its foot on the ground, or on a roof (world/dusk.gd draws up the first)
	lg.add_to_group("ladders")
	root.add_child(lg)
	return true
