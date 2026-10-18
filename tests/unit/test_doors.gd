extends GutTest
## The room doors that open and shut (world/doors.gd; ISS-105, ISS-084): Dechen-tsang's kitchen door, its three guest-yard
## rooms', its chapel's and Dolkar's room's (M2 sprint 8) and H-SHL-007's, hung at the
## leaves the kit marks and standing open into the room, the way through clear; shut, the leaves meet across the doorway
## with their rings and straps outside, the doorway is barred and its threshold no longer stepped over; open again, the
## way is clear; E by a door shuts it and opens it again, its prompt saying which, but never on the player in its
## doorway; and one of the town coming to a shut door opens it.

const Town := preload("res://world/town.gd")
const SWING_HALF := 0.35  ## half of world/doors.gd's SWING_S


func before_each() -> void:
	Controls.pad = false  # the prompts as the keys read them (autoload/controls.gd `say`), a controller paired or not
	TownSim.running = false
	TownSim.walkers_on = false
	TownSim.count = 0


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.count = 0
	for s in get_tree().get_nodes_in_group("subtitles"):
		s.free()


func _ray(root: Node3D, from: Vector3, to: Vector3) -> Dictionary:
	return root.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))


func _town() -> Node:
	var root := Node3D.new()
	add_child_autofree(root)
	var at := {}
	for b in JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json"))["buildings"]:
		if b["id"] == "SHL-04":
			at["SHL-04"] = b["pos"]
	for b in JSON.parse_string(FileAccess.get_file_as_string("res://data/town_generic.json"))["houses"]:
		if b["id"] == "H-SHL-007":
			at["H-SHL-007"] = b["pos"]
	var box := Rect2(Vector2(at["SHL-04"][0], at["SHL-04"][1]), Vector2.ZERO).expand(Vector2(at["H-SHL-007"][0], at["H-SHL-007"][1])).grow(12.0)
	gut.p("placed: %s" % [Town.place(root, box)])
	return root.find_child("Doors", true, false)


func test_they_open_and_shut() -> void:
	var doors := _town()
	assert_not_null(doors, "the doors built")
	if doors == null:
		return
	assert_eq(doors.doors.size(), 7, "Dechen-tsang's kitchen door, its three guest-yard rooms' (ISS-084), its chapel's and Dolkar's room's (M2 sprint 8) and H-SHL-007's")
	await wait_physics_frames(2)
	for i in doors.doors.size():
		var d: Dictionary = doors.doors[i]
		var mid: Vector3 = d["mid"]
		var w: Vector3 = d["way_in"]
		assert_eq((d["leaves"] as Array).size(), 2, "door %d: two leaves" % i)
		for lf in d["leaves"]:
			var pivot: Node3D = lf[0]
			assert_eq(pivot.get_child_count(), 1, "door %d: its leaf hung" % i)
			assert_gt(pivot.global_basis.x.dot(w), 0.95, "door %d: standing open, into the room" % i)
		var from := mid + Vector3(0.0, 1.2, 0.0) - w * 1.0
		var to := mid + Vector3(0.0, 1.2, 0.0) + w * 1.0
		assert_true(_ray(doors, from, to).is_empty(), "door %d: open, the doorway clear" % i)
		var sill: Node = d["sill"]
		assert_not_null(sill, "door %d: its threshold" % i)
		assert_true(doors.set_open(i, false), "door %d: shut" % i)
		assert_false(doors.set_open(i, false), "door %d: shut already" % i)
		doors._process(1.0)
		await wait_physics_frames(3)
		var ends := []
		for lf in d["leaves"]:
			var pivot: Node3D = lf[0]
			assert_almost_eq(wrapf(pivot.global_rotation.y - float(lf[1]), -PI, PI), 0.0, 0.01, "door %d: the leaf shut" % i)
			var leaf := pivot.get_child(0) as Node3D
			assert_lt(leaf.global_basis.z.dot(w), 0.0, "door %d: its ring and straps outside" % i)
			ends.append(pivot.global_position + pivot.global_basis.x * leaf.scale.x * Town.Doors.LEAF_W)
		assert_almost_eq((ends[0] as Vector3).distance_to(ends[1]), 0.0, 0.05, "door %d: the leaves meet" % i)
		var hit := _ray(doors, from, to)
		assert_false(hit.is_empty(), "door %d: shut, the doorway barred" % i)
		if not hit.is_empty():
			assert_almost_eq(((hit["position"] as Vector3) - mid).dot(w), -0.06, 0.08, "door %d: barred at its leaves" % i)
		if sill != null:
			assert_false(sill.is_in_group("sills"), "door %d: its threshold not stepped over while shut" % i)
		assert_true(doors.set_open(i, true), "door %d: open again" % i)
		doors._process(1.0)
		await wait_physics_frames(3)
		assert_true(_ray(doors, from, to).is_empty(), "door %d: the doorway clear again" % i)
		if sill != null:
			assert_true(sill.is_in_group("sills"), "door %d: its threshold stepped over again" % i)


func test_one_of_the_town_opens_a_shut_door() -> void:
	var doors := _town()
	if doors == null or doors.doors.is_empty():
		fail_test("no doors")
		return
	doors.set_open(0, false)
	var d: Dictionary = doors.doors[0]
	var outside: Vector3 = d["mid"] - (d["way_in"] as Vector3) * 3.0
	TownSim.count = 1
	TownSim.pos.resize(1)
	TownSim.state.resize(1)
	TownSim.pos[0] = outside
	TownSim.state[0] = 0
	doors._walkers()
	assert_false(bool(d["open"]), "shut while no one comes")
	TownSim.state[0] = 2
	TownSim.pos[0] = d["mid"]
	doors._walkers()
	assert_false(bool(d["open"]), "not by one indoors (not drawn)")
	TownSim.state[0] = 0
	TownSim.pos[0] = d["mid"] - (d["way_in"] as Vector3) * 0.8
	doors._walkers()
	assert_true(bool(d["open"]), "opened by one walking up to it")


func test_e_by_a_door() -> void:
	var doors := _town()
	if doors == null or doors.doors.is_empty():
		fail_test("no doors")
		return
	var d: Dictionary = doors.doors[1]
	var walker := GDScript.new()  # the player as world/doors.gd sees it: where it stands, and whether it sits
	walker.source_code = "extends Node3D\nvar rest := 0\n"
	walker.reload()
	var p := Node3D.new()
	p.set_script(walker)
	p.add_to_group("player")
	add_child_autofree(p)
	p.global_position = d["mid"] - (d["way_in"] as Vector3) * 0.9
	doors._process(0.1)
	var subs := get_tree().get_first_node_in_group("subtitles")
	assert_not_null(subs, "a prompt shown")
	if subs != null:
		assert_eq(String((subs.get("_prompt") as Label).text), "E  shut the door", "the prompt by an open door")
	var e := InputEventKey.new()
	e.keycode = KEY_E
	e.pressed = true
	doors._unhandled_input(e)
	assert_false(bool(d["open"]), "E: shut")
	doors._process(0.1)
	if subs != null:
		assert_eq(String((subs.get("_prompt") as Label).text), "E  open the door", "the prompt by a shut door")
	doors._unhandled_input(e)
	assert_true(bool(d["open"]), "E again: open")
	p.set("rest", 1)
	doors._unhandled_input(e)
	assert_true(bool(d["open"]), "not while sitting")
	p.set("rest", 0)
	p.global_position = d["mid"] + (d["way_in"] as Vector3) * 0.3
	doors._process(0.1)
	doors._unhandled_input(e)
	assert_true(bool(d["open"]), "not on the player standing in the doorway")
	if subs != null:
		assert_eq(String((subs.get("_prompt") as Label).text), "", "nor offered there")
	p.global_position = d["mid"] - (d["way_in"] as Vector3) * 3.0
	doors._process(0.1)
	doors._unhandled_input(e)
	assert_true(bool(d["open"]), "not from 3 m away")
	if subs != null:
		assert_eq(String((subs.get("_prompt") as Label).text), "", "no prompt away from it")


func test_a_shut_door_shuts_out_the_day() -> void:
	var doors := _town()
	if doors == null or doors.doors.is_empty():
		fail_test("no doors")
		return
	var d: Dictionary = doors.doors[1]
	var inside: Vector3 = d["mid"] + (d["way_in"] as Vector3) * 0.4  # where a room's ROOM socket stands, at the doorway's inner face
	assert_almost_eq(float(doors.openness_near(inside)), 1.0, 0.001, "open: the doorway's day comes in")
	doors.set_open(1, false)
	doors._process(SWING_HALF)
	var half := float(doors.openness_near(inside))
	assert_true(half > 0.05 and half < 0.95, "half way through its swing, half the day (%.2f)" % half)
	doors._process(1.0)
	assert_almost_eq(float(doors.openness_near(inside)), 0.0, 0.001, "shut: none")
	assert_almost_eq(float(doors.openness_near(inside + Vector3(30.0, 0.0, 0.0))), 1.0, 0.001, "no door near: as before")
