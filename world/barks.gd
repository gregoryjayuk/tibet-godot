extends Node
## The town's lines to and around the player (plan chapter 07, 8.4-8.6; chapter 05, 9.6; chapter 11, 14.2; M1 sprint 7,
## step 8): the slice's bark lines (data/barks.json, from tools/culture/barks.py and chapter 07's phrasebook), each
## said by one of its speakers, at its place and hours, in its way, and shown in its script with the English under it
## (ui/subtitles.gd; never Wylie or pinyin). Chapter 05's greeting duty: the hosts and the stall-keepers greet the
## player, turning to them, once a day at each place (a host at the gate, at the door, in the room: the steps of a
## visit); everyone else waits to be spoken to, but may be overheard, may ask "Where are you going?"
## on the stair, or say "Sorry" squeezing past. A line said in a scene of its own (the tea, the message, the roof's
## sang) is that scene's, which takes it from here (`line`). One line at a time, a few seconds apart, never over a
## scene's. Added by world/town.gd.

const DATA := "res://data/barks.json"
const Subtitles := preload("res://ui/subtitles.gd")
const Horizon := preload("res://world/horizon.gd")
const EVERY := 0.25  ## seconds between looks round
const GAP := 5.5  ## seconds between two lines
const REACH := {"greet": 3.5, "near": 3.0, "pass": 1.6, "leave": 9.0, "overheard": 6.0, "wrong_way": 15.0}
const CHANCE := {"greet": 1.0, "near": 0.06, "pass": 0.6, "leave": 1.0, "overheard": 0.05}  ## a look round's chance
const AGAIN := {"greet": 0.0, "near": 45.0, "pass": 20.0, "leave": 30.0, "overheard": 60.0}  ## a speaker's seconds before its next (a greeting: once a day, by `_greeted`)
const ORDER := ["leave", "greet", "pass", "near", "overheard"]

var barks: Array = []
var roles := {}  ## role -> [walker keys and kinds]
var said: Array = []  ## [minute, id, speaker key] said this session, for the tests and the stills
var rng := RandomNumberGenerator.new()
var chance := CHANCE.duplicate()  ## the tests set theirs to 1
var skew := 0.0  ## seconds added to the clock: the tests' way of letting time pass
var town: Node3D
var _t := 0.0
var _clock := 0.0  ## the game's seconds since the town came (its frames' time: it stops when the game does)
var _last_line := -1.0e9  ## the clock's seconds at the last line
var _speaker_at := {}  ## walker -> the clock's seconds at its last line
var _line_at := {}  ## line id -> the clock's seconds when it was last said
var _greeted := {}  ## "walker|place" -> the game day it greeted the player there
var _named: Node  ## characters/named.gd, whose overrides turn a greeter to the player
var _room := ""  ## the room the player was in at the last look (for "leave")
var _near_stall := -1  ## the nomad whose stall the player stands at (for her "Go in peace")
static var _lines := {}  ## id -> line, for `line`


## A slice line by its phrasebook id: {"script", "english", "lang", ...}. The scenes (the tea, the message, the roof's
## sang) say theirs from here, so a line a native speaker corrects is corrected once: in chapter 07, then by
## tools/culture/barks.py.
static func line(id: String) -> Dictionary:
	if _lines.is_empty() and FileAccess.file_exists(DATA):
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		for b in d["barks"]:
			_lines[String(b["id"])] = b
	return _lines.get(id, {"script": "", "english": "", "lang": "bo"})


func _ready() -> void:
	town = get_parent() as Node3D
	rng.seed = 1903
	add_to_group("barks")
	if FileAccess.file_exists(DATA):
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		barks = d["barks"]
		roles = d["roles"]


func _process(dt: float) -> void:
	_clock += dt
	_t += dt
	if _t < EVERY:
		return
	_t = 0.0
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and TownSim.walkers_on:
		look_round(player)


## One look round: the best line that can be said now, said. Returns its id, or "".
func look_round(player: Node3D) -> String:
	var now := _clock + skew
	if not _quiet(now):
		return ""
	var p := player.global_position
	var seated := int(player.get("rest")) != 0 if player.get("rest") != null else false
	var m := fposmod(WorldClock.minute, 1440.0)
	var room := _room_of(p)
	var left_room := _room if room != _room else ""
	_room = room
	var best: Array = []  # [order, weight, line, speaker]
	for b in barks:
		var how := String(b["how"])
		if how == "event" or how == "wrong_way" or not ORDER.has(how):
			continue
		var h: Array = b["hours"]
		if m < float(h[0]) * 60.0 or m > float(h[1]) * 60.0 or now - float(_line_at.get(b["id"], -1.0e9)) < 90.0:
			continue
		if how == "leave":
			var spk := _leaver(b, p, left_room)
			if spk >= 0:
				best = _better(best, [0, 99.0, b, spk])
			continue
		if not _at_place(String(b["where"]), p, player, room):
			continue
		for i in TownSim.count:
			if not _speaks(i, b["who"]) or int(TownSim.state[i]) == 2:
				continue
			var q: Vector3 = TownSim.pos[i]
			if q.distance_to(p) > float(REACH[how]) or now - float(_speaker_at.get(i, -1.0e9)) < float(AGAIN[how]):
				continue
			match how:
				"greet":  # once a day at each place, to one arriving (not to a guest already sat); they turn to say it
					if seated or int(_greeted.get("%d|%s" % [i, b["where"]], -1)) == int(WorldClock.minute / 1440.0):
						continue
				"pass":  # squeezing past on a flight, both on the move
					var body := player as CharacterBody3D
					if body == null or Vector2(body.velocity.x, body.velocity.z).length() < 0.5 or int(TownSim.state[i]) != 0:
						continue
				"near":
					if not _facing(i, p):
						continue
				"overheard":
					if not _listener(i, b["with"]):
						continue
			if rng.randf() > float(chance[how]):
				continue
			best = _better(best, [ORDER.find(how), float(b["weight"]) + rng.randf(), b, i])
	if best.is_empty():
		return ""
	if String(best[2]["how"]) == "greet":
		_turn(int(best[3]), player)
	return _say(best[2], best[3], now)


## Called by the mani wall (world/mani_wall.gd) when the player walks its lane the wrong way: an elder near says so.
func remark_wrong_way(at: Vector3) -> String:
	var now := _clock + skew
	if not _quiet(now):
		return ""
	for b in barks:
		if String(b["how"]) != "wrong_way" or now - float(_line_at.get(b["id"], -1.0e9)) < 90.0:
			continue
		for i in TownSim.count:
			if _speaks(i, b["who"]) and int(TownSim.state[i]) != 2 and (TownSim.pos[i] as Vector3).distance_to(at) < REACH["wrong_way"]:
				return _say(b, i, now)
	return ""


## No line up (a bark's or a scene's own), the last bark a few seconds gone, and two seconds' quiet after a scene's.
func _quiet(now: float) -> bool:
	var subs := get_tree().get_first_node_in_group("subtitles")
	if subs != null and float(subs.get("_left")) > 0.0:
		_last_line = maxf(_last_line, now - GAP + 2.0)
		return false
	return now - _last_line >= GAP


func _say(b: Dictionary, i: int, now: float) -> String:
	var subs := get_tree().get_first_node_in_group("subtitles")
	if subs == null:
		subs = Subtitles.new()
		get_tree().root.add_child(subs)
	subs.call("say_zh" if String(b["lang"]) == "zh" else "say", String(b["script"]), String(b["english"]), 3.2)
	_last_line = now
	_speaker_at[i] = now
	_line_at[b["id"]] = now
	if String(b["how"]) == "greet":
		_greeted["%d|%s" % [i, b["where"]]] = int(WorldClock.minute / 1440.0)
	said.append([WorldClock.minute, String(b["id"]), String(TownSim.key[i])])
	if OS.get_environment("BARKS_LOG") != "":  # a trace of the lines said, for the routes (tools/player/s15.sh)
		print("barks: %.1f s %s by %s" % [now, b["id"], TownSim.key[i]])
	return String(b["id"])


func _better(best: Array, c: Array) -> Array:
	if best.is_empty() or int(c[0]) < int(best[0]) or (int(c[0]) == int(best[0]) and float(c[1]) > float(best[1])):
		return c
	return best


func _speaks(i: int, who: Array) -> bool:
	var k := String(TownSim.key[i])
	for r in who:
		if (roles.get(r, []) as Array).has(k):
			return true
	return false


## A greeter turned to the player for a few seconds (characters/named.gd's overrides, as world/message.gd turns
## them); one seated only looks up.
func _turn(i: int, player: Node3D) -> void:
	if TownSim.seated(i):
		return
	if _named == null:
		_named = get_tree().get_first_node_in_group("named")
		if _named == null:
			return
	var q: Vector3 = TownSim.pos[i]
	var to := player.global_position - q
	var ov: Dictionary = _named.get("overrides")
	if ov.has(i):
		return  # a scene has them already
	ov[i] = {"pos": q, "yaw": atan2(to.x, to.z), "state": int(TownSim.state[i]), "speed": 0.0}
	await get_tree().create_timer(4.0).timeout
	if is_inside_tree() and is_instance_valid(_named):
		ov.erase(i)


## The speaker turned to the player (within 100 degrees of its way).
func _facing(i: int, p: Vector3) -> bool:
	var q: Vector3 = TownSim.pos[i]
	var to := Vector2(p.x - q.x, p.z - q.z).normalized()
	var y: float = TownSim.yaw[i]
	return Vector2(sin(y), cos(y)).dot(to) > -0.17


## One of the roles someone is talking to stands within 3 m of speaker i.
func _listener(i: int, with_: Array) -> bool:
	var q: Vector3 = TownSim.pos[i]
	for j in TownSim.count:
		if j != i and _speaks(j, with_) and int(TownSim.state[j]) != 2 and (TownSim.pos[j] as Vector3).distance_to(q) < 3.0:
			return true
	return false


## A "leave" line's speaker as the player goes: Yang when the player has just left his room; a nomad at her stall when
## the player, who stood at it, walks away.
func _leaver(b: Dictionary, p: Vector3, left_room: String) -> int:
	for i in TownSim.count:
		if not _speaks(i, b["who"]) or int(TownSim.state[i]) == 2:
			continue
		var d := (TownSim.pos[i] as Vector3).distance_to(p)
		if String(b["where"]) == "chinese_room":
			if left_room == "dechen_chinese" and d < REACH["leave"]:
				return i
		elif String(b["where"]) == "stalls":
			if d < 2.5:
				_near_stall = i
			elif _near_stall == i and d > 6.0:
				_near_stall = -1
				return i
	return -1


func _room_of(p: Vector3) -> String:
	var itr := get_tree().get_first_node_in_group("interiors")
	var r: Node = itr.call("room_at", p + Vector3(0.0, 1.0, 0.0)) if itr != null else null
	return String(r.get("room_id")) if r != null else ""


func _node(name: String) -> Node3D:
	return town.find_child(name, false, false) as Node3D if town != null else null


func _at_place(where: String, p: Vector3, player: Node3D, room: String) -> bool:
	match where:
		"anywhere":
			return true
		"stalls":
			var s := _node("SHL-29_1")
			return s != null and s.global_position.distance_to(p) < 16.0
		"tsongra":  # the square, away from its stalls (their keepers greet there with their own line); its level is the datum
			return Vector2(p.x, p.z).length() < 45.0 and absf(p.y) < 8.0 and not _at_place("stalls", p, player, room)
		"stair":
			return player.get("stair") is Dictionary and not (player.get("stair") as Dictionary).is_empty()
		"tibetan_room":
			return room == "dechen_tibetan"
		"chinese_room":
			return room == "dechen_chinese"
		"kitchen":
			return room == "dechen_kitchen"
		"house_kitchen":  # a house to enter's kitchen, or a poor house's one room (world/interiors.gd ROOMS)
			return room.begins_with("house_kitchen") or room.begins_with("house_room")
		"chang_room":  # the chang house's drinking room (SHL-24)
			return room.begins_with("chang_room")
		"castle_gate":  # before Samkha Khar's gate passage, outside its leaves (SAM-01's PASSAGE socket)
			var c := _node("SAM-01")
			var mouth := c.find_child("SOCK_PASSAGE_1", true, false) as Node3D if c != null else null
			return mouth != null and mouth.global_position.distance_to(p) < 4.0
		"dechen", "dechen_gate", "tibetan_door":
			var h := _node("SHL-04")
			if h == null:
				return false
			var l := h.global_transform.affine_inverse() * p  # the house's frame, Godot's axes (the kit's y is -z)
			if where == "dechen_gate":
				return Vector2(l.x, l.z - 23.5).length() < 6.0
			if where == "tibetan_door":
				return room == "" and Vector2(l.x - (-8.8), l.z - (-5.0)).length() < 2.4
			return room == "" and absf(l.x) < 30.0 and absf(l.z) < 23.0 and not _at_place("roof", p, player, room)  # up there: "please come up"
		"roof":
			var g := Horizon.ground_at(p.x, -p.z)
			return not is_nan(g) and p.y - g > 3.0
		"lookout":  # the Gorge Rim Lookout's terrace (SHL-32; M2 sprint 6, step 4)
			var lk := _node("SHL-32")
			return lk != null and lk.global_position.distance_to(p) < 6.0
	return false

