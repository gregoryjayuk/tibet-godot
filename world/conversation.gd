extends Node
## The conversation runner (plan chapter 11, 14.2; chapter 14, 7; M2 sprint 1, step 2): short graphs in
## data/conversations/*.json, each with who speaks it, when it can be had (`if`), and its nodes: a line (`say`, a
## phrasebook line by its id, in its script with the English under it; or `line` and `en`, a line written for the story,
## shown in English until a native speaker have written it in its script: docs/culture/conversation-lines-check.md),
## or `narrate`, what the player does; effects (`do`); and up to four replies, each with its own conditions, effects and
## next node, or a `next` after the line (E goes on). E by a person who has a conversation at this hour starts it: the
## player stands, the speaker turns to the player (unless seated), the replies are chosen with 1-4. Conditions: flag,
## not, knows, not_knows, hour, day, shut_in and not_shut_in (a room's door shut on the two of them), alone (no one else
## of the town near), met. Effects: flag, unflag, meet,
## tell, witnesses (who of the town stands within a radius learns it), pass_on, favour, owe, write and done (the
## ledger), pay, receive. The story's state is Story's (autoload/story.gd), saved with the game.

const Barks := preload("res://world/barks.gd")
const Subtitles := preload("res://ui/subtitles.gd")
const Replies := preload("res://ui/replies.gd")
const DIR := "res://data/conversations"
const REACH := 2.2  ## metres from the player a speaker can be talked to
const AWAY := 3.5  ## metres: the conversation ends if the player is further
const DAY1 := 10080.0  ## game minutes at 00:00 on day 1, Wednesday 28 October 1903 (WorldClock: from 21 October)

var talks: Array = []  ## every conversation's graph
var current := {}  ## the running conversation, {} when none
var node := {}  ## its current node
var speaker := -1  ## the TownSim walker speaking
var said: Array = []  ## node ids shown, in order (the tests')
var _replies: Array = []  ## the replies now offered: their dictionaries
var _shown := ""  ## the prompt as last said
var _named: Node
var _wait := 0.0  ## a line with no replies goes on with E, or after this many seconds


func _ready() -> void:
	add_to_group("conversation")
	load_talks()


func load_talks() -> void:
	talks.clear()
	var dir := DirAccess.open(DIR)
	if dir == null:
		return
	var files := Array(dir.get_files()).filter(func(f: String) -> bool: return f.ends_with(".json"))
	files.sort()
	for f in files:
		var d = JSON.parse_string(FileAccess.get_file_as_string("%s/%s" % [DIR, f]))
		if d is Dictionary:
			talks.append(d)


func _player() -> Node3D:
	var p := get_tree().get_first_node_in_group("player")
	return p if p is CharacterBody3D else null  # the player's body (a test's stand-in in the group is not one)


## The day of the story: 1 on Wednesday 28 October 1903, from 00:00.
static func day_of(minute: float) -> int:
	return int(floor((minute - DAY1) / 1440.0)) + 1


func _process(dt: float) -> void:
	var p := _player()
	if p == null:
		return
	if not current.is_empty():
		if speaker >= 0 and Vector2(TownSim.pos[speaker].x - p.global_position.x, TownSim.pos[speaker].z - p.global_position.z).length() > AWAY:
			finish()
			return
		_face(p)
		if speaker >= 0:  # the camera's two-shot (player/player.gd; ISS-135): the speaker's head, seated or standing
			p.set("talk_at", TownSim.pos[speaker] + Vector3(0.0, 1.05 if TownSim.seated(speaker) else 1.5, 0.0))
		if _replies.is_empty() and _wait > 0.0:
			_wait -= dt
			if _wait <= 0.0:
				go_on()
		return
	var c := candidate(p)
	var t := "E  talk" if not c.is_empty() else ""
	if t != _shown:
		_shown = t
		_subs().call("prompt", t)


## The conversation the player can start now and its speaker: {talk, walker} or {}.
func candidate(p: Node3D) -> Dictionary:
	if not TownSim.walkers_on or int(p.get("rest")) != 0:
		return {}
	var fwd := Vector3(-sin(float(p.get("facing"))), 0.0, -cos(float(p.get("facing"))))
	var best := {}
	var best_d := REACH
	for t in talks:
		var who := String(t.get("who", ""))
		for i in TownSim.count:
			if String(TownSim.key[i]) != who or int(TownSim.state[i]) == 2:
				continue
			var to := TownSim.pos[i] - p.global_position
			to.y = 0.0
			var d := to.length()
			if d < best_d and (d < 0.9 or fwd.dot(to / maxf(d, 0.01)) > 0.2) and test(t.get("if", []), i):
				best = {"talk": t, "walker": i}
				best_d = d
	return best


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo():
		return
	if current.is_empty():
		if e.is_action_pressed("use"):  # E, or the controller's triangle
			var p := _player()
			var c := candidate(p) if p != null else {}
			if not c.is_empty():
				start(c["talk"], int(c["walker"]))
				get_viewport().set_input_as_handled()
		return
	for k in 4:  # the number keys, or the D-pad clockwise from the top (autoload/controls.gd)
		if e.is_action_pressed("answer_%d" % (k + 1)) and not _replies.is_empty():
			choose(k)
			get_viewport().set_input_as_handled()
			return
	if e.is_action_pressed("use") and _replies.is_empty():
		go_on()
		get_viewport().set_input_as_handled()


func start(t: Dictionary, walker: int) -> void:
	current = t
	speaker = walker
	said.clear()
	var p := _player()
	if p != null:
		p.set("talking", true)
	Story.meet(String(t.get("who", "")))
	_prompt("")
	show_node(String(t.get("start", "a")))


## Shows node `id`: its line, its effects, its replies; "end" (or a node not there) ends the conversation.
func show_node(id: String) -> void:
	var nodes: Dictionary = current.get("nodes", {})
	if id == "end" or not nodes.has(id):
		finish()
		return
	node = nodes[id]
	said.append(id)
	if node.has("say"):
		var l := Barks.line(String(node["say"]))
		if String(l.get("lang", "bo")) == "zh":
			_subs().call("say_zh", String(l.get("script", "")), String(l.get("english", "")), 30.0)
		else:
			_subs().call("say", String(l.get("script", "")), String(l.get("english", "")), 30.0)
	elif node.has("en"):  # a line of the story's own: in its script once written and checked (`bo`, `zh`), else English
		if node.has("zh"):
			_subs().call("say_zh", String(node["zh"]), String(node["en"]), 30.0)
		else:
			_subs().call("say", String(node.get("bo", "")), String(node["en"]), 30.0)
	elif node.has("narrate"):
		_subs().call("narrate", String(node["narrate"]), 30.0)
	apply(node.get("do", []))
	_replies = (node.get("replies", []) as Array).filter(func(r: Dictionary) -> bool: return test(r.get("if", []), speaker))
	var texts := _replies.map(func(r: Dictionary) -> String: return String(r.get("en", "")))
	_rep().call("show_replies", texts)
	_wait = 0.0 if not _replies.is_empty() else float(node.get("wait", 0.0))
	_prompt("1-%d  answer" % _replies.size() if not _replies.is_empty() else "E  go on")


func choose(k: int) -> void:
	if k < 0 or k >= _replies.size():
		return
	var r: Dictionary = _replies[k]
	_replies = []
	_rep().call("hide_replies")
	apply(r.get("do", []))
	show_node(String(r.get("next", "end")))


func go_on() -> void:
	show_node(String(node.get("next", "end")))


func finish() -> void:
	current = {}
	node = {}
	_replies = []
	_rep().call("hide_replies")
	_prompt("")
	_shown = ""
	var p := _player()
	if p != null:
		p.set("talking", false)
		p.set("talk_at", Vector3.INF)
	if speaker >= 0 and _named != null:
		(_named.get("overrides") as Dictionary).erase(speaker)
	speaker = -1


## Whether every condition holds (`walker` the speaker, for the witnesses).
func test(conds: Array, walker: int) -> bool:
	for c in conds:
		var a: Array = c
		match String(a[0]):
			"flag":
				if not Story.flag(String(a[1])):
					return false
			"not":
				if Story.flag(String(a[1])):
					return false
			"knows":
				if not Story.knows(String(a[1]), String(a[2])):
					return false
			"not_knows":
				if Story.knows(String(a[1]), String(a[2])):
					return false
			"met":
				if not Story.met(String(a[1])):
					return false
			"hour":
				var h := fposmod(WorldClock.minute, 1440.0) / 60.0
				if h < float(a[1]) or h >= float(a[2]):
					return false
			"day":
				if day_of(WorldClock.minute) != int(a[1]):
					return false
			"shut_in":  # the player in a room whose door is shut: no one else sees
				if not _shut_in():
					return false
			"not_shut_in":
				if _shut_in():
					return false
			"alone":  # no one else of the town within the radius (or the room): what is said is between the two
				if not witnesses(float(a[1]) if a.size() > 1 else 6.0).is_empty():
					return false
			_:
				push_warning("conversation: no condition %s" % a[0])
				return false
	return true


func apply(effects: Array) -> void:
	for e in effects:
		var a: Array = e
		match String(a[0]):
			"flag":
				Story.set_flag(String(a[1]))
			"unflag":
				Story.set_flag(String(a[1]), false)
			"meet":
				Story.meet(String(a[1]))
			"tell":
				Story.tell(String(a[1]), String(a[2]))
			"witnesses":  # whoever of the town stands near and is not indoors sees it
				for w in witnesses(float(a[2]) if a.size() > 2 else 8.0):
					Story.tell(w, String(a[1]))
			"pass_on":
				Story.pass_on(String(a[1]), a[2], float(a[3]) if a.size() > 3 else 720.0)
			"favour":
				Story.favour(String(a[1]), int(a[2]))
			"owe":
				Story.owe(String(a[1]), float(a[2]))
			"write":
				Story.write(String(a[1]), String(a[2]), String(a[3]), String(a[4]) if a.size() > 4 else "", String(a[5]) if a.size() > 5 else "")
			"done":
				Story.done(String(a[1]))
			"pay":
				Story.pay(String(a[1]), float(a[2]))
			"receive":
				Story.receive(String(a[1]), float(a[2]))
			_:
				push_warning("conversation: no effect %s" % a[0])


## The named walkers within `radius` of the player, out of doors or in the same room, not the speaker.
func witnesses(radius: float) -> Array:
	var out := []
	var p := _player()
	if p == null:
		return out
	for i in TownSim.count:
		if i == speaker or int(TownSim.state[i]) == 2 or TownSim.kind[i] != TownSim.NAMED:
			continue
		if (TownSim.pos[i] as Vector3).distance_to(p.global_position) < radius:
			out.append(String(TownSim.key[i]))
	return out


func _shut_in() -> bool:
	var doors := get_tree().get_first_node_in_group("doors")
	var d := room_door()
	return d >= 0 and float(doors.call("openness_of", d)) < 0.05


## The door of the room the player is in (world/doors.gd's index), or -1: the door nearest that room's doorway (its
## scene's ROOM socket), not the nearest to the player, which can be another room's.
func room_door() -> int:
	var p := _player()
	var rooms := get_tree().get_first_node_in_group("interiors")
	var doors := get_tree().get_first_node_in_group("doors")
	if p == null or rooms == null or doors == null:
		return -1
	var room: Node = rooms.call("room_at", p.global_position + Vector3(0.0, 1.0, 0.0))
	if room == null:
		return -1
	return int(doors.call("near", (room.get_parent() as Node3D).global_position, 3.0))


## The speaker turned to the player while they talk (characters/named.gd's overrides), unless seated.
func _face(p: Node3D) -> void:
	if speaker < 0 or TownSim.seated(speaker):
		return
	if _named == null:
		_named = get_tree().get_first_node_in_group("named")
		if _named == null:
			return
	var q: Vector3 = TownSim.pos[speaker]
	var to := p.global_position - q
	(_named.get("overrides") as Dictionary)[speaker] = {"pos": q, "yaw": atan2(to.x, to.z), "state": 4, "speed": 0.0}


func _subs() -> Node:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s == null:
		s = Subtitles.new()
		get_tree().root.add_child(s)
	return s


func _rep() -> Node:
	var r := get_tree().get_first_node_in_group("replies")
	if r == null:
		r = Replies.new()
		get_tree().root.add_child(r)
	return r


func _prompt(t: String) -> void:
	_subs().call("prompt", t)
