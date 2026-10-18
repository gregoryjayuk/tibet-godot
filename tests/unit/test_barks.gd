extends GutTest
## The bark lines (M1 sprint 7, step 8; plan chapter 07, 8.4-8.6; chapter 05, 9.6): the phrasebook's 61 Tibetan and 31
## Chinese lines, and the slice's 40 and 12 on their speakers and moments, in their script with the English (no Latin
## letters in any script); every speaker a walker of the town; the scenes' lines from the same data; the greeting duty
## once a day at each place (a host's visit: you've come, come in, sit); Yang in Chinese in his room and seeing the
## player out; an overheard line only with its listener by;
## "Sorry" squeezing past on a stair; nothing over a line still up; the elder at the mani wall.

const Barks := preload("res://world/barks.gd")
const CROWD := ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]
const HOWS := ["greet", "near", "pass", "leave", "overheard", "event", "wrong_way"]
const PLACES := ["anywhere", "stalls", "tsongra", "stair", "tibetan_room", "chinese_room", "kitchen", "dechen", "dechen_gate", "tibetan_door", "roof", "mani", "house_kitchen", "chang_room", "castle_gate", "lookout", "gonkhang_door"]
const AT := Vector3(100.0, 0.0, 100.0)  ## the player, away from Tsongra's square

var keep := {}
var town: Node3D
var barks: Node
var player: CharacterBody3D
var rooms: Node  ## a stand-in for world/interiors.gd: its room_at


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}
	WorldClock.frozen = true
	WorldClock.minute = 7.0 * 1440.0 + 10.0 * 60.0
	for s in get_tree().get_nodes_in_group("subtitles"):
		s.free()
	var ps := GDScript.new()
	ps.source_code = "extends CharacterBody3D\nvar rest := 0\nvar stair := {}\n"
	ps.reload()
	player = CharacterBody3D.new()
	player.set_script(ps)
	player.add_to_group("player")
	add_child_autofree(player)
	player.global_position = AT
	var rs := GDScript.new()
	rs.source_code = "extends Node\nvar room_id := \"\"\nfunc room_at(_p: Vector3) -> Node:\n\treturn self if room_id != \"\" else null\n"
	rs.reload()
	rooms = Node.new()
	rooms.set_script(rs)
	rooms.add_to_group("interiors")
	add_child_autofree(rooms)
	town = Node3D.new()
	add_child_autofree(town)
	var stalls := Node3D.new()
	stalls.name = "SHL-29_1"  # Tsongra's stalls, as world/town.gd names the building
	town.add_child(stalls)
	stalls.global_position = AT + Vector3(0.0, 0.0, 8.0)
	barks = Barks.new()
	town.add_child(barks)
	barks.set_process(false)
	for k in barks.chance.keys():
		barks.chance[k] = 1.0


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]
	for s in get_tree().get_nodes_in_group("subtitles"):
		s.free()


## The town's walkers, set as TownSim holds them: [kind, where (Godot), what it faces (Godot; null: away from the
## player), state (0 walking, 1 standing, 2 indoors, 3 sitting)].
func _walkers(list: Array) -> void:
	TownSim.running = false
	TownSim.walkers_on = true
	TownSim.count = list.size()
	TownSim.key.resize(list.size())
	TownSim.pos.resize(list.size())
	TownSim.yaw.resize(list.size())
	TownSim.state.resize(list.size())
	for i in list.size():
		var w: Array = list[i]
		var q: Vector3 = w[1]
		var f: Vector3 = w[2] if w[2] != null else q + (q - player.global_position)
		TownSim.key[i] = String(w[0])
		TownSim.pos[i] = q
		TownSim.yaw[i] = atan2(f.x - q.x, f.z - q.z)
		TownSim.state[i] = int(w[3])


## Time passing: the lines up fade, the clock moves on.
func _later(seconds: float) -> void:
	barks.skew += seconds
	for s in get_tree().get_nodes_in_group("subtitles"):
		s.set("_left", 0.0)


func _last() -> Array:
	var s := get_tree().get_first_node_in_group("subtitles")
	var lines: Array = [] if s == null else s.get("lines")
	return [] if lines.is_empty() else lines[lines.size() - 1]


func test_the_phrasebook_and_the_slice_lines() -> void:
	var pb: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/phrasebook.json"))["lines"]
	var n := {"bo": 0, "zh": 0}
	for id in pb:
		n[String(pb[id]["lang"])] += 1
	assert_eq(n, {"bo": 62, "zh": 31}, "the phrasebook: chapter 07's 62 Tibetan and 31 Chinese lines (PB-T62, the Gönkhang's keeper, M3 sprint 6)")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/barks.json"))
	var s := {"bo": 0, "zh": 0}
	var latin := RegEx.create_from_string("[A-Za-z]")
	var tibetan := RegEx.create_from_string("[\\x{0F00}-\\x{0FFF}]")
	var han := RegEx.create_from_string("[\\x{4E00}-\\x{9FFF}]")
	for b in d["barks"]:
		var id := String(b["id"])
		s[String(b["lang"])] += 1
		assert_null(latin.search(String(b["script"])), "%s: no Wylie or pinyin in the game's script" % id)
		assert_not_null((tibetan if b["lang"] == "bo" else han).search(String(b["script"])), "%s: in its own script" % id)
		assert_true(String(b["english"]).length() > 1 and String(b["english"]).right(1) in [".", "?", "!"], "%s: its English" % id)
		assert_false(bool(pb[id]["unverified"]), "%s: never a line the plan marks unverified" % id)
		assert_has(HOWS, String(b["how"]), "%s: how it is said" % id)
		assert_has(PLACES, String(b["where"]), "%s: where" % id)
		for r in b["who"] + b["with"]:
			assert_true(d["roles"].has(r), "%s: its role %s" % [id, r])
		var h: Array = b["hours"]
		assert_true(float(h[0]) >= 0.0 and float(h[0]) < float(h[1]) and float(h[1]) <= 24.0, "%s: its hours" % id)
	assert_eq(s, {"bo": 48, "zh": 12}, "the slice: 48 Tibetan and 12 Chinese (PB-T43 at the Gorge Rim Lookout, M2 sprint 6; PB-T62 at the Gönkhang's curtain, M3 sprint 6)")


func test_every_speaker_is_a_walker_of_the_town() -> void:
	var kinds: Array = CROWD.duplicate()
	for f in ["res://data/named_days.json", "res://data/generic_days.json"]:
		kinds.append_array((JSON.parse_string(FileAccess.get_file_as_string(f))["people"] as Dictionary).keys())
	kinds.append_array(["castle_gatekeeper", "sherab_steward", "ponpo_tsewang"])  # Samkha's, on their days in world/samkha_people.gd
	kinds.append("gonkhang_keeper")  # standing at the Gönkhang's curtain through his hours (world/boots.gd)
	var roles: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/barks.json"))["roles"]
	for r in roles:
		assert_gt((roles[r] as Array).size(), 0, "%s: someone" % r)
		for k in roles[r]:
			assert_has(kinds, k, "%s: %s walks the town" % [r, k])


func test_the_scenes_say_their_lines_from_the_data() -> void:
	var tea := Barks.line("PB-T07")
	assert_eq([tea["script"], tea["english"], tea["lang"]], ["ཇ་མཆོད།", "Please have tea.", "bo"], "the tea's line")
	var agreed := Barks.line("PB-C03")
	assert_eq([agreed["script"], agreed["english"], agreed["lang"]], ["要得！", "Agreed!", "zh"], "Yang's last word")
	var src := ""
	for f in ["res://world/tea.gd", "res://world/message.gd", "res://world/roof_sang.gd", "res://world/castle_gate.gd", "res://world/boots.gd"]:
		src += FileAccess.get_file_as_string(f)
	var said := src  # and the story's scenes, the talks overheard (world/talks.gd: the bard's refrain)
	for f in DirAccess.get_files_at("res://data/talks"):
		said += FileAccess.get_file_as_string("res://data/talks/" + f)
	for b in barks.barks:
		if String(b["how"]) == "event":
			assert_string_contains(said, "\"%s\"" % b["id"], "%s: said by its scene" % b["id"])
	var script := RegEx.create_from_string("[\\x{0F00}-\\x{0FFF}\\x{4E00}-\\x{9FFF}]")
	assert_null(script.search(src), "no line written into a scene: each from the data, corrected once")


func test_a_stall_keeper_greets_once_a_day() -> void:
	_walkers([["stall_woman", AT + Vector3(0.0, 0.0, 2.0), AT, 1]])
	assert_eq(barks.look_round(player), "PB-T28", "come and buy!")
	assert_eq(_last(), ["ཉོས་ཤོག", "Come and buy!", "bo"], "in its script, with the English")
	_later(6.0)
	assert_eq(barks.look_round(player), "", "not again at once")
	_later(50.0)
	assert_has(["PB-T29", "PB-T30"], barks.look_round(player), "then a word about her wares")
	_later(100.0)
	var twice: int = barks.said.filter(func(l): return l[1] == "PB-T28").size()
	for k in 3:
		barks.look_round(player)
		_later(100.0)
	assert_eq(barks.said.filter(func(l): return l[1] == "PB-T28").size(), twice, "greeted once a day")
	WorldClock.minute += 1440.0
	_later(100.0)
	assert_eq(barks.look_round(player), "PB-T28", "and the next day again")
	WorldClock.minute = 8.0 * 1440.0 + 22.0 * 60.0
	_later(100.0)
	assert_eq(barks.look_round(player), "", "the stalls are shut at ten at night")


func test_a_host_greets_at_each_step_of_a_visit() -> void:
	var house := Node3D.new()
	house.name = "SHL-04"  # Dechen-tsang, its frame at AT: the Tibetan room's door at (-8.8, -5.0) in it
	town.add_child(house)
	house.global_position = AT
	_walkers([["achak_dolkar", AT + Vector3(-8.8, 0.0, -3.4), AT + Vector3(-8.8, 0.0, 2.0), 4]])  # inside, her back to the door
	player.global_position = AT + Vector3(-8.8, 0.0, -5.2)
	assert_eq(barks.look_round(player), "PB-T01", "you've come? as she turns to the guest at the door")
	_later(6.0)
	assert_eq(barks.look_round(player), "PB-T05", "please come in")
	_later(6.0)
	rooms.set("room_id", "dechen_tibetan")
	player.global_position = AT + Vector3(-8.8, 0.0, -1.5)
	assert_eq(barks.look_round(player), "PB-T06", "please sit, inside")
	for k in 4:
		_later(30.0)
		barks.look_round(player)
	assert_eq(barks.said.filter(func(l): return String(l[1]) in ["PB-T01", "PB-T05", "PB-T06"]).size(), 3, "each step once a day")


func test_an_indoor_walker_says_nothing() -> void:
	_walkers([["stall_woman", AT + Vector3(0.0, 0.0, 2.0), AT, 2]])
	assert_eq(barks.look_round(player), "", "indoors, not drawn: silent")


func test_yang_greets_in_chinese_and_sees_the_player_out() -> void:
	rooms.set("room_id", "dechen_chinese")
	_walkers([["yang_shouren", AT + Vector3(2.5, 0.0, 0.0), null, 3]])  # at his ledger, his back to the door
	assert_eq(barks.look_round(player), "PB-C10", "sit, have tea: he looks up from his seat")
	assert_eq(_last(), ["請坐，喝茶。", "Sit, have tea.", "zh"], "in Chinese, with the English")
	_later(10.0)
	rooms.set("room_id", "")
	player.global_position = AT + Vector3(-4.0, 0.0, 0.0)
	assert_eq(barks.look_round(player), "PB-C08", "go carefully, as the player leaves his room")


func test_an_overheard_line_needs_its_listener() -> void:
	_walkers([["han_man", AT + Vector3(0.0, 0.0, 5.0), AT + Vector3(0.0, 0.0, 9.0), 1]])
	assert_eq(barks.look_round(player), "", "the clerk alone says nothing")
	_walkers([["han_man", AT + Vector3(0.0, 0.0, 5.0), AT + Vector3(0.0, 0.0, 9.0), 4], ["stall_man", AT + Vector3(0.0, 0.0, 6.5), AT + Vector3(0.0, 0.0, 5.0), 4]])
	assert_has(["PB-C01", "PB-C06"], barks.look_round(player), "with a stall-keeper by, he haggles, overheard")
	assert_eq(String(_last()[2]), "zh", "in Chinese")


func test_sorry_squeezing_past_on_a_stair() -> void:
	player.set("stair", {"n": 12})
	player.velocity = Vector3(1.2, 0.0, 0.0)
	_walkers([["townsman", AT + Vector3(1.2, 0.0, 0.0), AT, 0]])
	assert_eq(barks.look_round(player), "PB-T17", "sorry, excuse me")
	_later(6.0)
	player.velocity = Vector3.ZERO
	assert_ne(barks.look_round(player), "PB-T17", "not while the player stands")


func test_never_over_a_line_still_up() -> void:
	_walkers([["stall_woman", AT + Vector3(0.0, 0.0, 2.0), AT, 1]])
	var subs: Node = preload("res://ui/subtitles.gd").new()
	add_child_autofree(subs)
	subs.call("say", "ཇ་མཆོད།", "Please have tea.", 3.0)
	assert_eq(barks.look_round(player), "", "a scene's line is up")
	_later(6.0)
	assert_eq(barks.look_round(player), "PB-T28", "then the greeting")


func test_the_elder_at_the_mani_wall() -> void:
	_walkers([["elder_woman", AT + Vector3(8.0, 0.0, 0.0), AT, 1]])
	assert_eq(barks.remark_wrong_way(AT), "PB-T44", "an elder near says so")
	assert_eq(_last(), ["གཡས་སྐོར་གྱིས།", "Go round to the right!", "bo"], "go round to the right")
	_later(10.0)
	assert_eq(barks.remark_wrong_way(AT), "", "and not again at once")
	_later(100.0)
	_walkers([["elder_woman", AT + Vector3(30.0, 0.0, 0.0), AT, 1]])
	assert_eq(barks.remark_wrong_way(AT), "", "no elder near, no remark")
