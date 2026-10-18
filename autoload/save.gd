extends Node
## Save and load (plan chapter 11, 18; spike S17; M2 sprint 1, step 1). A save is a JSON document in `user://saves/`,
## never a Godot resource (loading one can run a script inside it): its schema's version, the game minute and the
## clock's rate, and a block from everything that keeps state the player changed, each a node in the group "saved"
## with a `save_key`, `save_state() -> Dictionary` and `load_state(Dictionary)` (the player, the doors, the codex; the
## people's memory and the ledger to come). No one's place is saved: the townspeople's days are looked up from the
## clock (TownSim), so setting the clock puts everyone back. A 320 x 180 thumbnail beside each save.
## F5 saves to "quick", F9 loads the latest save; autosaves at 05:00, 12:00 and 17:00 game time and every ten real
## minutes, in three rotating slots (auto_1 to auto_3), only in play (a scripted or frozen run never saves).

signal saved(slot: String)
signal loaded(slot: String)

const SCHEMA := 1  ## bump with a migration in _migrate() whenever a block's form changes
const DIR := "user://saves"
const AUTO_AT := [300.0, 720.0, 1020.0]  ## game minutes of the day: 05:00, 12:00, 17:00
const AUTO_EVERY := 600.0  ## real seconds between autosaves
const AUTO_SLOTS := 3

var last_slot := ""  ## the slot last written or read
var _since := 0.0
var _last_minute := -1.0
var _auto_next := 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Whether the game is being played (a player who is not scripted, the clock running): only then is it saved by itself.
func in_play() -> bool:
	var p := get_tree().get_first_node_in_group("player")
	return p is CharacterBody3D and p.get("scripted") == false and not WorldClock.frozen  # (a test's stand-in has no flag)


func _process(dt: float) -> void:
	var m := fposmod(WorldClock.minute, 1440.0)
	if not in_play():
		_last_minute = m
		_since = 0.0
		return
	_since += dt
	var crossed := false
	if _last_minute >= 0.0:
		for a in AUTO_AT:
			if (_last_minute < a and m >= a) or (_last_minute > m and (m >= a or _last_minute < a)):  # (or over midnight)
				crossed = true
	_last_minute = m
	if crossed or _since >= AUTO_EVERY:
		_since = 0.0
		save_game("auto_%d" % _auto_next)
		_auto_next = _auto_next % AUTO_SLOTS + 1


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo() or not in_play():
		return
	if e.is_action_pressed("quicksave"):  # F5
		save_game("quick")
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("quickload"):  # F9
		var s := latest()
		if s != "":
			load_game(s)
		get_viewport().set_input_as_handled()


## The world's state as a save: every block, its schema's version and the time.
func snapshot() -> Dictionary:
	var d := {"schema_version": SCHEMA, "saved_at": Time.get_datetime_string_from_system(), "game": "Dungkardo",
			"time": {"minute": WorldClock.minute, "rate": WorldClock.rate}}
	for n in get_tree().get_nodes_in_group("saved"):
		var k := String(n.get("save_key"))
		if k != "" and n.has_method("save_state"):
			d[k] = n.call("save_state")
	for a in [Codex, Story]:  # the autoloads that keep the player's state
		if a != null and a.has_method("save_state"):
			d[String(a.get("save_key"))] = a.call("save_state")
	return d


## Puts the world back as a save had it: the clock first (everyone's place follows from it), then each block.
func apply(d: Dictionary) -> void:
	d = _migrate(d)
	var t: Dictionary = d.get("time", {})
	WorldClock.minute = float(t.get("minute", WorldClock.minute))
	WorldClock.rate = float(t.get("rate", WorldClock.RATE_PLAY))
	TownSim.day_minute = fposmod(WorldClock.minute, 1440.0)
	_last_minute = fposmod(WorldClock.minute, 1440.0)  # no autosave for the minute just loaded
	_since = 0.0
	for a in [Codex, Story]:
		if a != null and a.has_method("load_state") and d.has(String(a.get("save_key"))):
			a.call("load_state", d[String(a.get("save_key"))])
	for n in get_tree().get_nodes_in_group("saved"):
		var k := String(n.get("save_key"))
		if k != "" and d.has(k) and n.has_method("load_state"):
			n.call("load_state", d[k])


func save_game(slot: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var f := FileAccess.open("%s/%s.json" % [DIR, slot], FileAccess.WRITE)
	if f == null:
		push_warning("save: cannot write %s (%d)" % [slot, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(snapshot(), " "))
	f.close()
	_thumbnail(slot)
	last_slot = slot
	_notice("Saved")
	saved.emit(slot)
	return true


func load_game(slot: String) -> bool:
	var path := "%s/%s.json" % [DIR, slot]
	if not FileAccess.file_exists(path):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (d is Dictionary):
		push_warning("save: %s is not a save" % slot)
		return false
	apply(d)
	last_slot = slot
	_notice("Loaded")
	loaded.emit(slot)
	return true


## The newest save on disk, or "".
func latest() -> String:
	var best := ""
	var best_t := -1
	var dir := DirAccess.open(DIR)
	if dir == null:
		return ""
	for f in dir.get_files():
		if f.ends_with(".json"):
			var t := FileAccess.get_modified_time("%s/%s" % [DIR, f])
			if t > best_t:
				best_t = t
				best = f.get_basename()
	return best


## A save from an older schema brought up to this one, a step a version (none yet: version 1 is the first).
func _migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("schema_version", 1))
	while v < SCHEMA:
		v += 1
		d["schema_version"] = v
	return d


func _thumbnail(slot: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var tex := get_viewport().get_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.is_empty():
		return
	img.resize(320, 180, Image.INTERPOLATE_BILINEAR)
	img.save_png("%s/%s.png" % [DIR, slot])


func _notice(t: String) -> void:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s != null and s.has_method("narrate"):
		s.call("narrate", t, 1.5)
