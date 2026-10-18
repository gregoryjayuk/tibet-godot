extends Node
## Talk that is overheard (plan chapter 05, 9.5; chapter 14, 7; M2 sprint 2, step 3): scenes in data/talks/*.json, each
## at a room (`place`, a room's id) between two minutes of the day (`from`, `to`), needing its speakers there (`needs`:
## TownSim walkers seated, standing or talking in that room), with conditions as a conversation's (`if`), played once
## (`once`, a flag). While the player is in the room, a scene whose time it is and whose speakers are all there plays
## line by line: each speaker's line on the subtitles with the speaker's name over it, a narrator's line in italics; the
## speakers' heads turn to whoever speaks (the attention does). When the last line is said its effects (`do`) reach the
## story: what the player has learned, written in the ledger. A player who walks out before the end has not heard it:
## the scene can begin again while its time lasts. Lines are the phrasebook's by id (`say`) or the story's own (`line`
## and `en`; docs/culture/conversation-lines-check.md). Added by world/town.gd.

const Barks := preload("res://world/barks.gd")
const Subtitles := preload("res://ui/subtitles.gd")
const DIR := "res://data/talks"
const PER_LINE := 4.6  ## seconds a line stays before the next
const SETTLE := 5.0  ## seconds in a room before a scene begins there, and nothing else on the subtitles: the hosts' greeting first
const NAMES := {"ama_yudron": "Ama Yudrön", "yudron_daughter": "Yudrön's daughter", "jiang_deshun": "Jiang Deshun",
		"post_soldier": "a soldier of the post", "post_soldier_b": "another soldier", "muleteer": "a muleteer",
		"muleteer_b": "another muleteer", "drakpa_bard": "Drakpa Tharchin, the bard"}

var talks: Array = []
var current := {}  ## the scene playing, {} when none
var at := 0  ## the line it is at
var said: Array = []  ## [scene id, line index] of every line said (the tests')
var _t := 0.0
var _runner: Node  ## world/conversation.gd, for its conditions and effects
var _room := ""
var _in_for := 0.0  ## seconds the player has been in `_room`


func _ready() -> void:
	add_to_group("talks")
	var dir := DirAccess.open(DIR)
	if dir == null:
		return
	var files := Array(dir.get_files()).filter(func(f: String) -> bool: return f.ends_with(".json"))
	files.sort()
	for f in files:
		var d = JSON.parse_string(FileAccess.get_file_as_string("%s/%s" % [DIR, f]))
		if d is Dictionary:
			talks.append(d)


func _runner_node() -> Node:
	if _runner == null:
		_runner = get_tree().get_first_node_in_group("conversation")
	return _runner


## The room the player is in (its id), or "".
func player_room() -> String:
	var p := get_tree().get_first_node_in_group("player")
	var rooms := get_tree().get_first_node_in_group("interiors")
	if not (p is CharacterBody3D) or rooms == null:
		return ""
	var r: Node = rooms.call("room_at", (p as Node3D).global_position + Vector3(0.0, 1.0, 0.0))
	return String(r.get("room_id")) if r != null else ""


## Whether walker `key` is in the room `room` now, there to speak (not walking, not away).
func present(key: String, room: String) -> bool:
	var rooms := get_tree().get_first_node_in_group("interiors")
	for i in TownSim.count:
		if String(TownSim.key[i]) == key:
			var st := int(TownSim.state[i])
			if st == 0 or st == 2:
				return false
			var r: Node = rooms.call("room_at", TownSim.pos[i] + Vector3(0.0, 0.8, 0.0)) if rooms != null else null
			return r != null and String(r.get("room_id")) == room
	return false


## Whether scene `t` can play now with the player in room `room`.
func ready_to_play(t: Dictionary, room: String) -> bool:
	if String(t.get("place", "")) != room:
		return false
	if t.has("once") and Story.flag(String(t["once"])):
		return false
	var m := fposmod(WorldClock.minute, 1440.0)
	if m < float(t.get("from", 0.0)) or m > float(t.get("to", 1440.0)):
		return false
	for k in t.get("needs", []):
		if not present(String(k), room):
			return false
	var r := _runner_node()
	return r == null or bool(r.call("test", t.get("if", []), -1))


func _process(dt: float) -> void:
	if not TownSim.walkers_on:
		return
	var room := player_room()
	if room != _room:
		_room = room
		_in_for = 0.0
	_in_for += dt
	if current.is_empty():
		if room == "" or _in_for < SETTLE or _subs_busy():
			return
		for t in talks:
			if ready_to_play(t, room):
				begin(t)
				break
		return
	if room != String(current.get("place", "")):  # walked out: not heard
		current = {}
		return
	_t -= dt
	if _t <= 0.0:
		next_line()


func begin(t: Dictionary) -> void:
	current = t
	at = -1
	_t = 0.0
	next_line()


func next_line() -> void:
	at += 1
	var lines: Array = current.get("lines", [])
	if at >= lines.size():
		var r := _runner_node()
		if r != null:
			r.call("apply", current.get("do", []))
		if current.has("once"):
			Story.set_flag(String(current["once"]))
		current = {}
		return
	var l: Dictionary = lines[at]
	said.append([String(current.get("id", "")), at])
	var who := String(l.get("who", ""))
	var name := String(NAMES.get(who, who.replace("_", " ")))
	if l.has("narrate"):
		_subs().call("narrate", String(l["narrate"]), PER_LINE + 0.3)
	elif l.has("say"):
		var b := Barks.line(String(l["say"]))
		_subs().call("say_zh" if String(b.get("lang", "bo")) == "zh" else "say", String(b.get("script", "")), String(b.get("english", "")), PER_LINE + 0.3, name)
	else:
		if l.has("zh"):
			_subs().call("say_zh", String(l["zh"]), String(l.get("en", "")), PER_LINE + 0.3, name)
		else:
			_subs().call("say", String(l.get("bo", "")), String(l.get("en", "")), PER_LINE + 0.3, name)
	_t = float(l.get("seconds", PER_LINE))


func _subs_busy() -> bool:
	var s := get_tree().get_first_node_in_group("subtitles")
	return s != null and float(s.get("_left")) > 0.0


func _subs() -> Node:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s == null:
		s = Subtitles.new()
		get_tree().root.add_child(s)
	return s
