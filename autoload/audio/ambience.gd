extends Node
## The Ambience director (plan chapter 10, 13.7; M1 sprint 8, step 1), AudioDirector/Ambience: the district beds. Each
## bed of data/sound.json `beds` is layers, each a 2D player on its sound's bus with a curve of its loudness over the
## day's hours (LUFS at the listener; the player's gain is that less its files' own loudness), read four times a second. A bed's weight is its district's nearness: 1 within 25 m of one of the district's buildings
## (data/town.json), nothing 50 m out (a bed of district "*" is everywhere). The wind's layer takes its strength from
## the listener's height (low in the town, stronger above it); a market layer ("crowd") swells with the people TownSim
## has standing within 40 m. Indoors (world/interiors.gd `room_at`) the beds fall 18 dB, as through an open door.
## Levels move 6 dB a second, so crossing a threshold or a district's edge crossfades.

var Town: GDScript  ## world/town.gd, loaded at start, not preloaded: the town's scripts refer to this autoload
const OFF_DB := -80.0
const NEAR := 25.0  ## metres from a district's building at which its bed is whole
const FAR := 50.0  ## and at which it is gone
const INDOOR_DB := -18.0
const SLEW := 6.0  ## dB a second
const WIND_HEIGHTS := [30.0, 110.0]  ## metres over Tsongra where the wind goes from low to middling, and to strong

var listener_override: Node3D
var indoor := false
var layers: Array = []  ## {bed, sound, curve, crowd, wind, players: [AudioStreamPlayer], target: [dB]}
var _districts := {}  ## district -> PackedVector2Array of its buildings (Godot x, z)
var _tick := 0.0
var _first := true  ## the first aim sets the levels outright: the beds begin at their level, they fade only on a change


func _data() -> Dictionary:
	return get_parent().get("data") if get_parent() != null else {}


func _ready() -> void:
	Town = load("res://world/town.gd")
	var pts := {}  # district -> [Vector2]: plain arrays while building (a packed array in a dictionary is a copy)
	for f in ["res://data/town.json", "res://data/town_generic.json"]:  # the gazetteer's buildings and the houses
		if not FileAccess.file_exists(f):
			continue
		var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(f))
		for b in t.get("buildings", []) + t.get("houses", []):
			var d := String(b.get("district", ""))
			var p: Array = b.get("pos", [])
			if d == "" or p.size() < 2:
				continue
			var g: Vector3 = Town.to_godot(float(p[0]), float(p[1]), 0.0)
			if not pts.has(d):
				pts[d] = []
			(pts[d] as Array).append(Vector2(g.x, g.z))
	for d in pts:
		_districts[d] = PackedVector2Array(pts[d])
	var beds: Dictionary = _data().get("beds", {})
	for bed in beds:
		for L in beds[bed]["layers"]:
			var rec: Dictionary = _data()["sounds"][L["sound"]]
			var n := (rec["files"] as Array).size() if bool(L.get("wind", false)) else 1
			var players: Array = []
			for v in n:
				var p := AudioStreamPlayer.new()
				p.name = "%s_%s_%d" % [bed, L["sound"], v]
				p.bus = StringName(rec.get("bus", "Beds"))
				p.volume_db = OFF_DB
				add_child(p)
				players.append(p)
			layers.append({"bed": bed, "district": String(beds[bed]["district"]), "sound": L["sound"], "curve": L["curve"],
					"crowd": bool(L.get("crowd", false)), "wind": bool(L.get("wind", false)), "players": players, "target": []})


func listener() -> Vector3:
	if listener_override != null:
		return listener_override.global_position
	var cam := get_viewport().get_camera_3d() if get_viewport() != null else null
	return cam.global_position if cam != null else Vector3.ZERO


## A layer's level at `minute` of the day from its curve (keys "HH:MM", dB or null for off; linear in dB between keys,
## round midnight), or OFF_DB.
static func curve_db(curve: Dictionary, minute: float) -> float:
	var keys: Array = []
	for k in curve:
		var hm := String(k).split(":")
		keys.append([float(hm[0]) * 60.0 + float(hm[1]), curve[k]])
	keys.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	var m := fposmod(minute, 1440.0)
	var prev: Array = keys[keys.size() - 1]
	var prev_t := float(prev[0]) - 1440.0
	for k in keys:
		if float(k[0]) >= m:
			return _between(prev[1], k[1], m, prev_t, float(k[0]))
		prev = k
		prev_t = float(k[0])
	var first: Array = keys[0]
	return _between(keys[keys.size() - 1][1], first[1], m, prev_t, float(first[0]) + 1440.0)


## Between two keys: linear in dB between two levels; an "off" key is a step at its own minute (a layer on at 8:00
## and off at 23:00 holds its level till 23:00, and one off till 5:30 comes on at 5:30).
static func _between(a, b, m: float, t0: float, t1: float) -> float:
	if a == null and b == null:
		return OFF_DB
	if b == null:
		return float(a)
	if a == null:
		return OFF_DB if m < t1 else float(b)
	return lerpf(float(a), float(b), (m - t0) / maxf(t1 - t0, 0.001))


## A district's weight at `p` (13.7).
func weight(district: String, p: Vector3) -> float:
	if district == "*":
		return 1.0
	var pts: PackedVector2Array = _districts.get(district, PackedVector2Array())
	var best := INF
	var q := Vector2(p.x, p.z)
	for b in pts:
		best = minf(best, q.distance_squared_to(b))
	return 1.0 - smoothstep(NEAR, FAR, sqrt(best))


func _process(dt: float) -> void:
	_tick -= dt
	if _tick <= 0.0:
		_tick = 0.25
		_aim()
	for L in layers:
		var ps: Array = L["players"]
		var tg: Array = L["target"]
		for i in ps.size():
			var p := ps[i] as AudioStreamPlayer
			var want: float = float(tg[i]) if i < tg.size() else OFF_DB
			p.volume_db = want if _first else move_toward(p.volume_db, want, SLEW * dt)
			if want > OFF_DB + 1.0 and not p.playing:
				p.stream = get_parent().call("stream", L["sound"], i if bool(L["wind"]) else -1)
				if p.stream != null:
					var dice: RandomNumberGenerator = get_parent().get("rng")  # the director's dice, never the global stream
					p.play(dice.randf() * maxf(p.stream.get_length() - 0.1, 0.0))  # each bed from its own point in the loop
			elif p.playing and p.volume_db <= OFF_DB + 0.5 and want <= OFF_DB + 0.5:
				p.stop()
	if _first and not layers.is_empty() and not (layers[0]["target"] as Array).is_empty():
		_first = false


## Each layer's target: its curve at the game's minute, its district's weight, the wind's strength, the crowd, indoors.
func _aim() -> void:
	var ear := listener()
	var m := fposmod(WorldClock.minute, 1440.0)
	var itr := get_tree().get_first_node_in_group("interiors")
	indoor = itr != null and itr.call("room_at", ear) != null
	var people := 0
	if TownSim.walkers_on:
		for i in TownSim.count:
			if int(TownSim.state[i]) != 2 and (TownSim.pos[i] as Vector3).distance_to(ear) < 40.0:
				people += 1
	for L in layers:
		var base := curve_db(L["curve"], m)
		var w := weight(String(L["district"]), ear)
		var lufs: Array = (_data()["sounds"][L["sound"]] as Dictionary).get("lufs", [])
		var tg: Array = []
		var ps: Array = L["players"]
		for i in ps.size():
			var db := base
			if db <= OFF_DB + 0.5 or w <= 0.001:
				tg.append(OFF_DB)
				continue
			db -= float(lufs[mini(i, lufs.size() - 1)]) if not lufs.is_empty() else -30.0  # the curve is the layer's loudness
			db += linear_to_db(w)
			if bool(L["crowd"]):  # the market's walla, by how many stand near: -12 dB with none, whole with twelve
				db += lerpf(-12.0, 0.0, clampf(people / 12.0, 0.0, 1.0))
			if bool(L["wind"]):  # one of its three strengths by the height over Tsongra (the datum); the slew crossfades
				var strength := 0 if ear.y < WIND_HEIGHTS[0] else (1 if ear.y < WIND_HEIGHTS[1] else 2)
				if i != strength:
					tg.append(OFF_DB)
					continue
			if indoor:
				db += INDOOR_DB
			tg.append(maxf(db, OFF_DB))
		L["target"] = tg
