extends GutTest
## The headman's house's moments (M2 sprint 7, step 5; world/headman_house.gd): the hatch shut and its log taken in from
## 20:30 to 05:00, never with the player on the roof; the headman's bench refused and the lower bench not; the dog's
## call heard only while it barks; the story's three lines (CV-040 to 042) in data/story_lines.json. The walks:
## `tools/player/s15.sh route headman_dog`, `route headman_tea`, `route headman_seat`.

const HeadmanHouse := preload("res://world/headman_house.gd")

var _minute := 0.0


func before_each() -> void:
	_minute = WorldClock.minute


func after_each() -> void:
	WorldClock.minute = _minute


## A stand-in town: SHL-19 at the origin with its hatch and its dog's peg, and the hatch's log among the ladders.
func _town() -> Array:
	var root := Node3D.new()
	add_child_autofree(root)
	var house := Node3D.new()
	house.name = "SHL-19"
	root.add_child(house)
	for s in [["SOCK_HATCH_1", Vector3(-0.55, 8.15, -2.7)], ["SOCK_DOG_1", Vector3(5.15, 0.0, 9.2)]]:
		var n := Node3D.new()
		n.name = s[0]
		house.add_child(n)
		n.position = s[1]
	var lg := Node3D.new()
	lg.name = "DOORLOG_SHL-19_2"
	root.add_child(lg)
	lg.add_to_group("ladders")
	var hm: Node3D = HeadmanHouse.new()
	root.add_child(hm)
	assert_true(hm.build(root), "the house found")
	return [root, hm, lg]


func test_the_hatch_at_night() -> void:
	var t := _town()
	var hm: Node3D = t[1]
	var lg: Node3D = t[2]
	assert_true(HeadmanHouse.night(21.0 * 60.0) and HeadmanHouse.night(4.5 * 60.0), "night: 20:30 to 05:00")
	assert_false(HeadmanHouse.night(5.5 * 60.0) or HeadmanHouse.night(20.0 * 60.0), "not before 20:30 nor after 05:00")
	WorldClock.minute = 15.0 * 60.0
	hm._process(0.1)
	assert_false(bool(hm.get("hatch_shut")), "open by day")
	assert_true(lg.is_in_group("ladders"), "its log climbable by day")
	WorldClock.minute = 21.0 * 60.0
	hm._process(0.1)
	assert_true(bool(hm.get("hatch_shut")), "shut at 21:00")
	assert_false(lg.is_in_group("ladders"), "its log taken in")
	assert_false(lg.visible, "and out of sight")
	WorldClock.minute = 6.0 * 60.0
	hm._process(0.1)
	assert_true(lg.is_in_group("ladders") and not bool(hm.get("hatch_shut")), "open again from 05:00")


func test_the_headmans_seat() -> void:
	var t := _town()
	var hm: Node3D = t[1]
	var house: Node3D = t[0].get_node("SHL-19")
	# the headman's bench (the kit's frame x 4.44-5.15, y -3.95..-2.05, its top 0.45 over the floor at 2.45) and the lower
	# bench by the door (x 1.4-3.7, y -1.16)
	assert_false(bool(hm.call("may_sit", house.to_global(Vector3(4.6, 2.45, 3.0)))), "the headman's bench: refused")
	assert_true(bool(hm.call("may_sit", house.to_global(Vector3(1.78, 2.45, 1.4)))), "the lower bench: a guest's")


func test_the_call_only_to_a_barking_dog() -> void:
	var t := _town()
	var hm: Node3D = t[1]
	var house: Node3D = t[0].get_node("SHL-19")
	if hm.get("dog") == null:
		pending("no mastiff body: ../tibet-blender people2/stand_ins.py -- mastiff")
		return
	assert_false(bool(hm.call("call_to_house", house.to_global(Vector3(7.0, 0.0, 7.3)))), "no call to a quiet dog")


func test_the_lines() -> void:
	var ids := []
	for l in (JSON.parse_string(FileAccess.get_file_as_string("res://data/story_lines.json")) as Dictionary)["lines"]:
		ids.append(String(l["id"]))
	for id in ["CV-040", "CV-041", "CV-042"]:
		assert_has(ids, id, "%s among the story's own lines (English until a native speaker writes it)" % id)
