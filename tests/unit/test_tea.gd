extends GutTest
## Tea before talk, refilled after each sip (M1 sprint 7, step 4; plan chapter 07, 7.2): the seated guest is poured a
## bowl to the brim before anything is said, with "Please have tea"; the first E is the libation, not a sip; each sip is
## refilled to the brim after a moment with "Please have tea" again; "enough" (a palm over the bowl) stops the refills;
## standing up, the guest hears "Go slowly". No host within reach, no tea.

const Tea := preload("res://world/tea.gd")
const PATH := "user://test_tea_streets.json"
const CROWD: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]

var keep := {}
var tea: Node3D
var guest: Node3D
var subs: Node


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}
	WorldClock.frozen = true
	for s in get_tree().get_nodes_in_group("subtitles"):
		s.queue_free()
	var gs := GDScript.new()
	gs.source_code = "extends Node3D\nvar rest := 2\n"  # player/player.gd's Rest.SEATED
	gs.reload()
	guest = Node3D.new()
	guest.set_script(gs)
	guest.add_to_group("player")
	add_child_autofree(guest)
	tea = Tea.new()
	add_child_autofree(tea)


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]
	for s in get_tree().get_nodes_in_group("subtitles"):
		s.free()


## The house's woman standing at `x` metres from the bowl (the town grid's x; the bowl at its origin).
func _host(x: float) -> void:
	var z0 := 2662.0 + tea.global_position.y  # Town.to_godot's datum: the grid's height 2662 is Godot's 0
	var data := {"pace": 1.1, "up": 0.75, "down": 0.5, "rate": 0.1, "anchors": {"home": [x - 20.0, 0.0, z0], "room": [x, 0.0, z0]},
		"walkers": [{"kind": "kitchen_woman", "named": true, "pace": 1.0, "up": 0.8, "down": 0.5, "home": "home",
			"day": [["home", 0, 600, "inside", 0, null], ["room", 620, 1440, "stand", 0, null]]}],
		"routes": {"home>room": {"p": [x - 20.0, 0.0, z0, x, 0.0, z0], "k": [0], "n": [0]}}}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	TownSim.setup_walkers(PATH, CROWD)
	WorldClock.minute = 7.0 * 1440.0 + 14.0 * 60.0
	TownSim.step(0.0, Vector3.ZERO)


func _run(seconds: float) -> void:
	var n := int(seconds / 0.05)
	for k in n:
		tea._process(0.05)


func _said() -> Array:
	var s := get_tree().get_first_node_in_group("subtitles")
	return [] if s == null else (s.get("lines") as Array).map(func(l): return String(l[1]))


func test_tea_before_talk_and_refilled_after_each_sip() -> void:
	_host(0.8)
	guest.position = Vector3(0.4, 0.0, 0.6)
	_run(0.2)
	assert_eq(int(tea.state), Tea.S.POURING, "seated, the host pours before anything is said")
	assert_eq(_said().size(), 0, "nothing said before the tea")
	_run(1.0)
	assert_almost_eq(float(tea.level), 1.0, 0.01, "filled to the brim")
	assert_eq(_said(), ["Please have tea."], "and then: please have tea")
	tea.sip()
	assert_true(tea.libation, "the first E is the libation")
	assert_almost_eq(float(tea.level), 1.0, 0.01, "no tea drunk by it")
	tea.sip()
	assert_almost_eq(float(tea.level), 1.0 - Tea.SIP, 0.01, "a sip")
	_run(Tea.REFILL_AFTER + Tea.POUR_S + 0.3)
	assert_almost_eq(float(tea.level), 1.0, 0.01, "refilled to the brim after the sip")
	assert_eq(int(tea.refills), 1, "one refill")
	assert_eq(_said().filter(func(l): return l == "Please have tea.").size(), 2, "please have tea at every refill")
	tea.no_more()
	assert_true("No more, thank you." in _said(), "enough")
	tea.sip()
	_run(Tea.REFILL_AFTER + Tea.POUR_S + 0.5)
	assert_almost_eq(float(tea.level), 1.0 - Tea.SIP, 0.01, "after enough, no more refills")
	guest.set("rest", 0)
	_run(0.1)
	assert_eq(int(tea.state), Tea.S.AWAY, "standing, the visit is over")
	assert_eq(_said()[_said().size() - 1], "Go slowly.", "and the host: go slowly")


func test_no_host_no_tea() -> void:
	_host(3.0)  # the woman across the room, out of reach of the table
	guest.position = Vector3(0.4, 0.0, 0.6)
	_run(1.5)
	assert_eq(int(tea.state), Tea.S.AWAY, "nobody within reach of the bowl: no tea")
