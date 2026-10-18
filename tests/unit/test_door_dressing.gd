extends GutTest
## The door dressing (world/door_dressing.gd; IMP-019): every town house's door its own things by its name, in the
## shares set (a skull three in ten, a thread cross one in four, mani stones a third of the doors on the ground, Losar's
## marks half the lived-in houses); a shut house's door barred, and never Losar's marks on it; none on a house to
## enter's open door; each placed in its door socket's frame and drawn, one MultiMesh a kind.

const Dressing := preload("res://world/door_dressing.gd")
const Households := preload("res://world/households.gd")
const TYPES := ["town_house_b2_v1", "town_house_b1_v1", "log_house_a1_v1", "log_house_a2_v4", "town_house_b2_v5", "log_house_a3_v8"]
const N := 120

var root: Node3D
var hh: Node
var dd: Node3D
var r: Dictionary


func before_all() -> void:
	root = Node3D.new()
	add_child(root)
	for i in N:
		var h: Node3D = (load("res://assets/generated/kit/types/%s.glb" % TYPES[i % TYPES.size()]) as PackedScene).instantiate()
		h.name = "H-SHL-007" if i == 7 else "H-D%03d" % i  # one of them a house to enter (world/interiors.gd)
		root.add_child(h)
		h.position = Vector3(float(i % 12) * 25.0, 0.0, float(i / 12) * 25.0)
		h.rotation.y = float(i) * 0.9
	hh = Households.new()
	root.add_child(hh)
	hh.build(root)
	dd = Dressing.new()
	root.add_child(dd)
	r = dd.build(root, hh)


func after_all() -> void:
	root.free()


func _with(prefix: String) -> int:
	var n := 0
	for h in dd.per_house:
		n += int((dd.per_house[h] as Array).any(func(f): return String(f).begins_with(prefix)))
	return n


func test_every_door_its_own() -> void:
	assert_eq(int(r["doors"]), N, "every house's door")
	assert_between(float(_with("door_skull")) / N, 0.15, 0.45, "a skull over three doors in ten")
	assert_between(float(_with("door_threadcross")) / N, 0.1, 0.4, "a thread cross by one in four")
	assert_gt(_with("door_mani"), 0, "mani stones at some doors on the ground")
	var lived := 0
	var marked := 0
	for h in dd.per_house:
		if not hh.is_shut(String(h)):
			lived += 1
			marked += int((dd.per_house[h] as Array).any(func(f): return String(f).begins_with("door_marks")))
	assert_between(float(marked) / lived, 0.3, 0.7, "Losar's marks on half the lived-in houses")
	assert_gt(_with("door_marks_l"), 0, "a Bön household or two")


func test_shut_barred_never_marked() -> void:
	var shut := 0
	for h in dd.per_house:
		var files: Array = dd.per_house[h]
		if hh.is_shut(String(h)):
			shut += 1
			assert_true(files.has("door_bar_v1"), "%s shut: its door barred" % h)
			assert_false(files.any(func(f): return String(f).begins_with("door_marks")), "%s shut since before Losar: no marks" % h)
		else:
			assert_false(files.has("door_bar_v1"), "%s lived in: no bar" % h)
	assert_eq(int(r["barred"]), shut, "every shut house barred")
	assert_gt(shut, 5, "some shut among them")
	assert_false((dd.per_house["H-SHL-007"] as Array).any(func(f): return String(f).begins_with("door_marks")), "a house to enter's open door unmarked")


func test_drawn_at_the_doors() -> void:
	var n := 0
	for mi in dd.get_children():
		var mm := (mi as MultiMeshInstance3D).multimesh
		assert_not_null(mm.mesh, "%s has its mesh" % mi.name)
		n += mm.instance_count
	assert_eq(n, int(r["items"]), "one instance a thing")
	for h in root.get_children():
		if not String(h.name).begins_with("H-"):
			continue
		var socks: Array = h.find_children("SOCK_DOOR_*", "Node3D", true, false)
		socks.sort_custom(func(a, b): return String(a.name) < String(b.name))
		var door := (socks[0] as Node3D).global_position
		if (dd.per_house[String(h.name)] as Array).has("door_bar_v1"):
			var near := (dd.placed["door_bar_v1"] as Array).any(func(t): return (t as Transform3D).origin.distance_to(door) < 0.01)
			assert_true(near, "%s's bar at its door" % h.name)
