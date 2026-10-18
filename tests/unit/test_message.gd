extends GutTest
## Carrying a message between Dechen-tsang's two counting rooms (M1 sprint 7, step 5; chapter 04, 4.3; CX-052): from
## 14:30, near the Litang agent, the offers are the player's to carry; each E by the one whose turn it is takes the next
## step (the agent, Yang, three times), never by the wrong one; the lines are the phrasebook's, Tibetan from the agent,
## Chinese from Yang, and the last tells the lesson: nobody opened a price first, three in a room.

const Message := preload("res://world/message.gd")
const PATH := "user://test_message_streets.json"
const CROWD: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]

var keep := {}
var msg: Node
var guest: Node3D


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}
	WorldClock.frozen = true
	for s in get_tree().get_nodes_in_group("subtitles"):
		s.queue_free()
	var gs := GDScript.new()
	gs.source_code = "extends Node3D\nvar rest := 0\n"  # standing
	gs.reload()
	guest = Node3D.new()
	guest.set_script(gs)
	guest.add_to_group("player")
	add_child_autofree(guest)
	msg = Message.new()
	add_child_autofree(msg)


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]
	for s in get_tree().get_nodes_in_group("subtitles"):
		s.free()


## The agent seated at x = 0, Yang seated at x = 20 (two rooms across a yard), from a home far off.
func _town() -> void:
	var z := 2662.0
	var seat := func(x: float) -> Dictionary: return {"name": "s", "at": [x, 0.0, z], "face": [0.0, 1.0], "pose": "chair"}
	var data := {"pace": 1.1, "up": 0.75, "down": 0.5, "rate": 0.1,
		"anchors": {"home": [0.0, -40.0, z], "tib": [0.0, 0.0, z], "chi": [20.0, 0.0, z]},
		"walkers": [
			{"kind": "ngodrup_dedpon", "named": true, "pace": 1.0, "up": 0.8, "down": 0.5, "home": "home",
				"day": [["home", 0, 600, "inside", 0, null], ["tib", 620, 1440, "sit", 0, seat.call(0.0)]]},
			{"kind": "yang_shouren", "named": true, "pace": 1.0, "up": 0.8, "down": 0.5, "home": "home",
				"day": [["home", 0, 600, "inside", 0, null], ["chi", 620, 1440, "sit", 0, seat.call(20.0)]]}],
		"routes": {"home>tib": {"p": [0.0, -40.0, z, 0.0, 0.0, z], "k": [0], "n": [0]},
			"home>chi": {"p": [0.0, -40.0, z, 20.0, 0.0, z], "k": [0], "n": [0]}}}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	TownSim.setup_walkers(PATH, CROWD)


func _at(m: float) -> void:
	WorldClock.minute = 7.0 * 1440.0 + m
	TownSim.step(0.0, Vector3.ZERO)
	msg._process(0.05)


func _said() -> Array:
	var s := get_tree().get_first_node_in_group("subtitles")
	return [] if s == null else (s.get("lines") as Array).map(func(l): return String(l[1]))


func test_the_offers_carried_three_times() -> void:
	_town()
	guest.position = Vector3(1.0, 0.0, 0.0)
	_at(14.0 * 60.0)
	assert_eq(int(msg.stage), -1, "before 14:30, no offers to carry")
	_at(14.6 * 60.0)
	assert_eq(int(msg.stage), 0, "14:36, by the agent: the offers are the guest's to carry")
	for k in 6:
		var by_agent := k % 2 == 0
		guest.position = Vector3(20.0 if by_agent else 1.0, 0.0, 0.0)  # by the wrong one first
		_at(14.6 * 60.0)
		assert_false(msg.interact(), "step %d: E by the wrong one takes nothing" % k)
		guest.position = Vector3(1.0 if by_agent else 19.0, 0.0, 0.0)
		_at(14.6 * 60.0)
		assert_true(msg.interact(), "step %d: E by the %s" % [k, "agent" if by_agent else "buyer"])
	assert_true(msg.done, "the deal made")
	var said := _said()
	assert_true("Too dear. Come down a bit." in said, "Yang's first answer, in Chinese")
	assert_true("Agreed!" in said, "and his last")
	var s := get_tree().get_first_node_in_group("subtitles")
	var langs: Array = (s.get("lines") as Array).map(func(l): return String(l[2]))
	assert_true("bo" in langs and "zh" in langs, "Tibetan from the agent, Chinese from Yang")
	await wait_seconds(3.5)  # the last narration comes after the line
	assert_true(_said().any(func(l): return String(l).contains("nobody opened a price first")), "the lesson: nobody opens a price first")
