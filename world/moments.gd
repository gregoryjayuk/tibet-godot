extends Node
## The AweDirector's moments (plan chapter 08, 2; M2 sprint 3, step 5): the records of data/moments.json. Its first,
## V-01, the Gate Chorten reveal (chapter 08, V-19 and V-01's "Sound"): on R-01 from SER-20 along the cliff gallery and
## through the cutting in the nose the town is not heard, its buses held 18 dB down (the slot's water and the wind
## stay, and the player's own steps and the caravan's bells); in the chorten's passage the dead stone room (RZ-22) with
## the district beds 12 dB down; out of it on its west side the town rises to its own level over 2 s (`sc_gate_reveal`).
## The first time the player stands at the station in one of its windows the moment is logged in the story (a flag
## "moment:V-01", saved with it). The buses move by the AudioDirector's offsets, so a viewpoint's settling adds to it.
## Added by world/town.gd with the town.

const Town := preload("res://world/town.gd")
const DATA := "res://data/moments.json"
const ARRIVAL := "res://data/arrival.json"
const SOURCE := "moment"

var moments: Array = []
var road: Array = []  ## R-01 from SER-20 to the Gate Chorten's east mouth: [Vector2] in the town grid
var state := "none"  ## the reveal's stretch the player is on: quiet, room, or none
var level := {}  ## bus -> the offset now (dB)
var logged: Array = []  ## moments logged this session (the tests')
var _room_at := Vector2.INF
var _t := 0.0


func _ready() -> void:
	add_to_group("moments")
	if FileAccess.file_exists(DATA):
		moments = (JSON.parse_string(FileAccess.get_file_as_string(DATA)) as Dictionary).get("moments", [])
	if FileAccess.file_exists(ARRIVAL):
		var a: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARRIVAL))
		var chorten: Array = a.get("gate_chorten", {}).get("at", [])
		for q in a.get("road_west", []):
			road.append(Vector2(float(q[0]), float(q[1])))
			if not chorten.is_empty() and Vector2(float(q[0]), float(q[1])).distance_to(Vector2(chorten[0], chorten[1])) < 9.0:
				break  # up to the chorten's east mouth
		if not chorten.is_empty():
			_room_at = Vector2(float(chorten[0]), float(chorten[1]))


## The town grid's (x, y, z) of a Godot point.
static func grid(p: Vector3) -> Vector3:
	return Vector3(p.x, -p.z, p.y + Town.DATUM)


## Which of the reveal's stretches the grid point `g` is on: "room" in the chorten's passage, "quiet" on the road east of
## it, "none" elsewhere.
func stretch(g: Vector3, cue: Dictionary) -> String:
	var at := Vector2(g.x, g.y)
	if _room_at != Vector2.INF and at.distance_to(_room_at) <= float(cue.get("room", {}).get("radius", 3.8)):
		return "room"
	var within := float(cue.get("quiet", {}).get("within", 20.0))
	for k in road.size() - 1:
		var a: Vector2 = road[k]
		var b: Vector2 = road[k + 1]
		var t := clampf((at - a).dot(b - a) / maxf((b - a).length_squared(), 0.001), 0.0, 1.0)
		if at.distance_to(a + (b - a) * t) <= within:
			return "quiet"
	return "none"


func _process(dt: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null or moments.is_empty():
		return
	var g := grid(p.global_position)
	for m in moments:
		var cue: Dictionary = m.get("cue", {})
		if cue.has("near"):
			_near(m, g, cue, dt)
		elif not cue.is_empty():
			_cue(g, cue, dt)
		_log(m, g)


## The reveal's mix: the offsets each bus is held at on each stretch, moved towards it at the rise's rate.
func _cue(g: Vector3, cue: Dictionary, dt: float) -> void:
	state = stretch(g, cue)
	var quiet := float(cue.get("quiet", {}).get("db", -18.0))
	var rate := absf(quiet) / maxf(float(cue.get("rise_s", 2.0)), 0.1)
	for bus in cue.get("buses", []):
		var goal := 0.0
		if state == "quiet":
			goal = quiet
		elif state == "room":
			goal = float(cue.get("room", {}).get("beds_db", -12.0)) if String(bus) == "Beds" else quiet
		var now := float(level.get(bus, 0.0))
		now = goal if state != "none" and goal < now else move_toward(now, goal, rate * dt)  # down at once, up over the rise
		level[bus] = now
		if is_instance_valid(AudioDirector):
			AudioDirector.set_offset(SOURCE, String(bus), now)


## A moment's quiet by its station (V-02's `sc_conch_dawn`): within `near.within` metres of its point in its window, the
## buses held at `near.db`, eased there and back over `rise_s`; its own source of offsets, so the moments add.
func _near(m: Dictionary, g: Vector3, cue: Dictionary, dt: float) -> void:
	var nr: Dictionary = cue["near"]
	var at: Array = nr["at"]
	var close := Vector2(g.x, g.y).distance_to(Vector2(float(at[0]), float(at[1]))) <= float(nr.get("within", 25.0))
	var goal_db := float(nr.get("db", -6.0)) if close and window_open(m, fposmod(WorldClock.minute, 1440.0)) else 0.0
	var rate := absf(float(nr.get("db", -6.0))) / maxf(float(cue.get("rise_s", 3.0)), 0.1)
	var src := "%s:%s" % [SOURCE, String(m["id"])]
	for bus in cue.get("buses", []):
		var key := "%s:%s" % [String(m["id"]), String(bus)]
		var now := move_toward(float(level.get(key, 0.0)), goal_db, rate * dt)
		level[key] = now
		if is_instance_valid(AudioDirector):
			AudioDirector.set_offset(src, String(bus), now)


## Whether the minute `minute` is in one of the moment's windows.
static func window_open(m: Dictionary, minute: float) -> bool:
	var w: Dictionary = m.get("window", {})
	if String(w.get("date", "any")) == "good_days" and not preload("res://world/assembly.gd").good_day(WorldClock.minute):
		return false  # (V-26: the Tibetan month's 8th, 15th and 30th, world/assembly.gd GOOD_DAYS)
	for pair in [[w.get("from", "00:00"), w.get("to", "24:00")], w.get("alt_window", []), w.get("first_arrival", [])]:
		if (pair as Array).size() == 2 and minute >= _minute(String(pair[0])) and minute <= _minute(String(pair[1])):
			return true
	return false


## Logs the moment the first time the player stands at one of its stations in one of its windows.
func _log(m: Dictionary, g: Vector3) -> void:
	var flag := "moment:%s" % String(m["id"])
	if Story.flag(flag):
		return
	if not window_open(m, fposmod(WorldClock.minute, 1440.0)):
		return
	for st in m.get("stations", []):
		var sp: Array = st["pos"]
		if Vector2(g.x, g.y).distance_to(Vector2(float(sp[0]), float(sp[1]))) <= float(st.get("radius", 6.0)):
			Story.set_flag(flag)
			logged.append(String(m["id"]))
			return


static func _minute(hm: String) -> float:
	var parts := hm.split(":")
	return float(parts[0]) * 60.0 + float(parts[1])
