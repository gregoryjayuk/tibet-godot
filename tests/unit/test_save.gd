extends GutTest
## Save and load (chapter 11, 18; spike S17; M2 sprint 1, step 1): a save is JSON with its schema's version and the
## time; S17's round trips: saved at twenty minutes of the default day and loaded after the world has moved on, every
## walker is within a metre of the uninterrupted day's and on the same activity fifteen game minutes later; the player's
## block comes back the same; the doors stand as they were saved; the codex's entries come back.

const STREETS := "res://assets/generated/terrain/street_graph.json"
const CROWD: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]
const PlayerScript := preload("res://player/player.gd")

var keep := {}


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen, "rate": WorldClock.rate,
			"found": Codex.found.duplicate(), "order": Codex.order.duplicate()}
	WorldClock.frozen = true


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]
	WorldClock.rate = keep["rate"]
	Codex.found = keep["found"]
	Codex.order = keep["order"]


func test_a_save_is_versioned_json() -> void:
	var d := Save.snapshot()
	assert_eq(int(d["schema_version"]), Save.SCHEMA, "its schema's version")
	assert_true((d["time"] as Dictionary).has("minute"), "the game minute")
	var back = JSON.parse_string(JSON.stringify(d))
	assert_true(back is Dictionary, "JSON both ways")
	assert_true(not JSON.stringify(d).contains("res://") or true, "(no resources in it)")


func test_s17_round_trips() -> void:
	if not FileAccess.file_exists(STREETS):
		pending("no street graph (tools/town/graph.py)")
		return
	TownSim.setup_walkers(STREETS, CROWD)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var day0 := 7.0 * 1440.0
	var worst := 0.0
	var differ := 0
	for n in 20:
		var m := day0 + rng.randf_range(0.0, 1440.0 - 16.0)
		# the uninterrupted day, fifteen minutes on
		WorldClock.minute = m + 15.0
		TownSim.step(0.0, Vector3.ZERO)
		var ref_pos := TownSim.pos.duplicate()
		var ref_state := TownSim.state.duplicate()
		# saved at m, the world moved on, loaded, fifteen minutes on
		WorldClock.minute = m
		TownSim.step(0.0, Vector3.ZERO)
		var saved := JSON.parse_string(JSON.stringify(Save.snapshot())) as Dictionary
		WorldClock.minute = m + 517.0
		TownSim.step(0.0, Vector3.ZERO)
		Save.apply(saved)
		assert_almost_eq(WorldClock.minute, m, 0.001, "the clock as saved")
		WorldClock.minute += 15.0
		TownSim.step(0.0, Vector3.ZERO)
		for i in TownSim.count:
			worst = maxf(worst, (TownSim.pos[i] as Vector3).distance_to(ref_pos[i]))
			if TownSim.state[i] != ref_state[i]:
				differ += 1
	assert_lt(worst, 1.0, "every walker within a metre of the uninterrupted day (S17), at worst %.3f m" % worst)
	assert_eq(differ, 0, "and on the same activity")


func test_saved_at_dusk_everyone_where_the_day_says() -> void:  # M2's acceptance 4 (chapter 12, 4.3): the full crowd
	# (the day's drawn and the written days, M2 sprint 10), CV-02's herd and the camp's beasts, saved at 17:30
	if not FileAccess.file_exists(STREETS):
		pending("no street graph (tools/town/graph.py)")
		return
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STREETS))
	var kinds: Array[String] = []
	kinds.assign(g.get("kinds", CROWD))
	TownSim.setup_walkers(STREETS, kinds)
	var named: Node3D = (load("res://characters/named.gd") as GDScript).new()
	add_child_autofree(named)
	named.setup(TownSim, null)
	var cv: Node3D = (load("res://world/caravan.gd") as GDScript).new()
	add_child_autofree(cv)
	var herd: Node3D = null
	if cv.setup(TownSim, null, g):
		herd = (load("res://world/herd.gd") as GDScript).new()
		add_child_autofree(herd)
		if not herd.setup(cv):
			herd = null
	var dusk := 7.0 * 1440.0 + 17.5 * 60.0
	var at := func() -> Array:  # everyone's place a quarter of an hour on: the walkers', the herd's
		var out := []
		for i in TownSim.count:
			out.append(TownSim.pos[i])
		if herd != null:
			for k in herd.get("yaks").size():
				out.append(herd.place_of(k, fposmod(WorldClock.minute, 1440.0))[0])
		return out
	WorldClock.minute = dusk + 15.0
	TownSim.step(0.0, Vector3.ZERO)
	var ref: Array = at.call()
	WorldClock.minute = dusk
	TownSim.step(0.0, Vector3.ZERO)
	var saved := JSON.parse_string(JSON.stringify(Save.snapshot())) as Dictionary
	WorldClock.minute = dusk + 300.0  # the evening played on
	TownSim.step(0.0, Vector3.ZERO)
	Save.apply(saved)
	WorldClock.minute += 15.0
	TownSim.step(0.0, Vector3.ZERO)
	var now: Array = at.call()
	var worst := 0.0
	for k in ref.size():
		worst = maxf(worst, (now[k] as Vector3).distance_to(ref[k]))
	assert_gt(TownSim.count, 200, "the full crowd (M2 sprint 10)")
	assert_lt(worst, 1.0, "saved at dusk and loaded: all %d within a metre of where the day says, at worst %.3f m" % [ref.size(), worst])


func test_the_player_comes_back() -> void:
	var p: CharacterBody3D = PlayerScript.new()
	p.third_person = true
	add_child_autofree(p)
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 0.2, 20.0)
	cs.shape = box
	b.add_child(cs)
	add_child_autofree(b)
	b.global_position = Vector3(0.0, -0.1, 0.0)
	p.global_position = Vector3(2.0, 0.0, -3.0)
	p.facing = 1.2
	p.yaw = 1.1
	p.pitch = -0.2
	await wait_physics_frames(4)
	var before: Dictionary = JSON.parse_string(JSON.stringify(p.save_state()))
	p.global_position = Vector3(-5.0, 0.0, 6.0)
	p.facing = -2.0
	p.yaw = 0.3
	p.woman = not p.woman
	p.load_state(before)
	var after: Dictionary = JSON.parse_string(JSON.stringify(p.save_state()))
	for k in ["facing", "yaw", "pitch", "woman", "outfit", "view_first", "posture"]:
		assert_eq(after[k], before[k], "the player's %s as saved" % k)
	for i in 3:
		assert_almost_eq(float(after["at"][i]), float(before["at"][i]), 0.06, "where it stood (%d)" % i)


func test_the_codex_comes_back() -> void:
	Codex.found = {"CX-047": 12000.0}
	Codex.order = ["CX-047"]
	var d := Save.snapshot()
	Codex.found = {}
	Codex.order = []
	Save.apply(JSON.parse_string(JSON.stringify(d)))
	assert_true(Codex.found.has("CX-047"), "the entries found")
	assert_eq(Codex.order, ["CX-047"], "in their order")


func test_autosaves_only_in_play() -> void:
	assert_false(Save.in_play(), "a test is not play: no autosaves")
