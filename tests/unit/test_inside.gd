extends GutTest
## Who is inside Dechen-tsang this afternoon (M1 sprint 7, step 3; chapter 04, 4.3; chapter 05, 4.2): a seat in a room
## is walked to by its way (TownSim: from the house's gate over the threshold, across the yards, over the room's sill),
## and between two rooms of the house only back to where the ways part; on the real days (tools/town/graph.py from
## data/named_days.json and data/generic_days.json) Dolkar walks between the two counting rooms until she leaves for
## the caravan, Yang sits at his ledger in the Chinese room with the Han clerk on the bench, the Litang agent sits at
## the head of the Tibetan room, the cook is at the kitchen's stove, and the house's woman, at the kettles in the
## morning, keeps the Tibetan room's tea in the afternoon (step 4).

const PATH := "user://test_inside_streets.json"
const STREETS := "res://assets/generated/terrain/street_graph.json"
const HOUSE := "res://assets/generated/kit/types/trading_house_v1.json"
const CROWD: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]
const Town := preload("res://world/town.gd")

var keep := {}


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}
	WorldClock.frozen = true


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]


func _at(m: float) -> void:
	WorldClock.minute = 7.0 * 1440.0 + m
	TownSim.step(0.0, Vector3.ZERO)


## A made-up house: the anchor at x = 0, two rooms' seats reached by ways sharing their first two points.
func test_two_rooms_of_one_house() -> void:
	var common := [[0.0, 2.0, 2662.0], [0.0, 10.0, 2662.0]]
	var a := {"name": "a", "at": [-6.0, 12.0, 2662.0], "face": [0.0, 1.0], "pose": "stand", "via": common + [[-4.0, 12.0, 2662.0]]}
	var b := {"name": "b", "at": [6.0, 12.0, 2662.0], "face": [0.0, 1.0], "pose": "stand", "via": common + [[4.0, 12.0, 2662.0]]}
	var data := {"pace": 1.1, "up": 0.75, "down": 0.5, "rate": 0.1, "anchors": {"house": [0.0, 0.0, 2662.0]},
		"walkers": [{"kind": "achak_dolkar", "named": true, "pace": 1.0, "up": 0.8, "down": 0.5, "home": "house",
			"day": [["house", 0, 600, "inside", 0, null], ["house", 620, 640, "talk", 0, a], ["house", 650, 670, "talk", 0, b],
				["house", 700, 1440, "inside", 0, null]]}], "routes": {}}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	TownSim.setup_walkers(PATH, CROWD)
	assert_eq(TownSim.slipped, 0, "on time")
	_at(630.0)
	assert_almost_eq(TownSim.pos[0].x, -6.0, 0.05, "at the first room's seat")
	assert_eq(int(TownSim.state[0]), 4, "talking")
	# between the rooms: from (-6, 12) back to (-4, 12), to (0, 10), on to (4, 12) and (6, 12): never back at the anchor
	var nearest := INF
	for k in 100:
		_at(640.0 + 10.0 * k / 100.0)
		nearest = minf(nearest, Vector2(TownSim.pos[0].x, TownSim.pos[0].z).length())
	assert_gt(nearest, 8.0, "between two rooms it never walks out to the anchor (%.1f m from it at nearest)" % nearest)
	_at(660.0)
	assert_almost_eq(TownSim.pos[0].x, 6.0, 0.05, "at the second room's seat")


## A day's walker by key in the real street graph, or -1.
func _who(k: String) -> int:
	for i in TownSim.count:
		if String(TownSim.key[i]) == k:
			return i
	return -1


## Whether a Godot point lies in one of Dechen-tsang's rooms (the house's sidecar: its rooms' boxes in its frame).
func _room_of(p: Vector3) -> int:
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HOUSE))
	var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json"))
	var pos: Array = []
	for b in t["buildings"]:
		if b["id"] == "SHL-04":
			pos = b["pos"]
	var q := Town.to_godot(float(pos[0]), float(pos[1]), float(pos[2]))
	var u := p.x - q.x
	var v := -(p.z - q.z)
	var rooms: Array = side["rooms"]
	for k in rooms.size():
		var r: Array = rooms[k]
		if u >= float(r[0]) and u <= float(r[1]) and v >= float(r[2]) and v <= float(r[3]):
			return k
	return -1


func test_the_afternoon_in_dechen_tsang() -> void:
	if not FileAccess.file_exists(STREETS) or not FileAccess.file_exists(HOUSE):
		pending("no street graph or no trading house (tools/town/graph.py, the kit's export)")
		return
	TownSim.setup_walkers(STREETS, CROWD)
	var dolkar := _who("achak_dolkar")
	var yang := _who("yang_shouren")
	var agent := _who("ngodrup_dedpon")
	var clerk := _who("han_man")
	var cook := _who("cook")
	var woman := _who("kitchen_woman")
	for i in [dolkar, yang, agent, clerk, cook, woman]:
		assert_gt(i, -1, "each of them walks a day")
	if -1 in [dolkar, yang, agent, clerk, cook, woman]:
		return
	_at(14.0 * 60.0)  # the Tibetan room (0), the Chinese (1), the guest room (2), the kitchen (3)
	assert_eq(_room_of(TownSim.pos[dolkar]), 0, "14:00: Dolkar in the Tibetan room")
	assert_eq(_room_of(TownSim.pos[agent]), 0, "the Litang agent in the Tibetan room")
	assert_eq(int(TownSim.state[agent]), 6, "seated cross-legged on the bench (ISS-088)")
	assert_eq(_room_of(TownSim.pos[yang]), 1, "Yang in the Chinese room")
	assert_eq(int(TownSim.state[yang]), 3, "seated at his ledger")
	assert_eq(_room_of(TownSim.pos[clerk]), 1, "the Han clerk in the Chinese room")
	assert_eq(_room_of(TownSim.pos[cook]), 3, "the cook in the kitchen")
	assert_eq(_room_of(TownSim.pos[woman]), 0, "the house's woman in the Tibetan room, keeping its tea (step 4)")
	_at(14.3 * 60.0)
	assert_eq(_room_of(TownSim.pos[dolkar]), 1, "14:18: Dolkar across the yard in the Chinese room")
	_at(14.6 * 60.0)
	assert_eq(_room_of(TownSim.pos[dolkar]), 0, "14:36: back in the Tibetan room with the last offers")
	_at(15.2 * 60.0)
	assert_eq(_room_of(TownSim.pos[dolkar]), -1, "15:12: gone out to meet the caravan")
	assert_eq(_room_of(TownSim.pos[yang]), 1, "Yang still at his ledger")


## Sprint 7, step 6: at 17:00 Dolkar is on the master range's roof by its sang burner, having gone up out of sight (the
## house's stairs, from its door to the roof's hatch: a via point "in").
func test_up_to_the_roof_out_of_sight() -> void:
	if not FileAccess.file_exists(STREETS) or not FileAccess.file_exists(HOUSE):
		pending("no street graph or no trading house (tools/town/graph.py, the kit's export)")
		return
	TownSim.setup_walkers(STREETS, CROWD)
	var dolkar := _who("achak_dolkar")
	var woman := _who("kitchen_woman")
	if dolkar < 0 or woman < 0:
		return
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HOUSE))
	var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json"))
	var pos: Array = []
	for b in t["buildings"]:
		if b["id"] == "SHL-04":
			pos = b["pos"]
	var s: Array = side["socket_pos"]["SOCK_SANG_1"]
	var burner := Town.to_godot(float(pos[0]) + float(s[0]), float(pos[1]) + float(s[1]), float(pos[2]) + float(s[2]))
	_at(17.1 * 60.0)
	assert_lt((TownSim.pos[dolkar] as Vector3).distance_to(burner), 2.0, "17:06: Dolkar by the roof's burner")
	assert_lt((TownSim.pos[woman] as Vector3).distance_to(burner), 2.0, "and the house's woman")
	var hidden := false
	var m := 16.8 * 60.0
	while m < 17.0 * 60.0:
		_at(m)
		hidden = hidden or int(TownSim.state[dolkar]) == 2
		m += 0.1
	assert_true(hidden, "on her way up she is out of sight: indoors, on the house's stairs")
