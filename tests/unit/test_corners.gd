extends GutTest
## The corners round the houses (world/corners.gd; IMP-023 (2), Greg's 1781): most households keep a few things by their
## walls, each its own; a shut house only its firewood and pots, a left one nothing; each thing on the ground against a
## wall before the front or a side's front half, never in the door's way.

const Corners := preload("res://world/corners.gd")
const Households := preload("res://world/households.gd")
const SHUT_OK := ["corner_firewood", "corner_pots"]

var root: Node3D


func before_each() -> void:
	var town: GDScript = load("res://world/town.gd")
	root = Node3D.new()
	add_child_autofree(root)
	for h in JSON.parse_string(FileAccess.get_file_as_string("res://data/town_generic.json"))["houses"]:
		var n := Node3D.new()
		n.name = String(h["id"])
		root.add_child(n)
		n.position = town.call("to_godot", float(h["pos"][0]), float(h["pos"][1]), float(h["pos"][2]))
		n.rotation.y = -deg_to_rad(float(h["rot_deg"]) - 180.0)


func test_each_its_own() -> void:
	var hh := Households.new()
	add_child_autofree(hh)
	hh.build(root)
	var c := Corners.new()
	add_child_autofree(c)
	var r: Dictionary = c.build(root, hh)
	assert_gt(float(r["houses"]) / float(root.get_child_count()), 0.6, "most households keep things by their walls")
	var kinds := {}
	var combos := {}
	for h in c.per_house:
		assert_false(hh.is_left(String(h)), "%s left: nothing" % h)
		for k in c.per_house[h]:
			kinds[k] = true
			if hh.is_shut(String(h)):
				assert_has(SHUT_OK, k, "%s shut: only its firewood and pots" % h)
		combos[",".join(PackedStringArray(c.per_house[h]))] = true
	assert_eq(kinds.size(), 8, "every kind somewhere")
	assert_gt(combos.size(), c.per_house.size() * 0.4, "many combinations")


func test_against_the_walls_on_the_ground() -> void:
	var c := Corners.new()
	add_child_autofree(c)
	c.build(root)
	var n := 0
	var fp := {}  # each house's footprint (a poor one-room house of the west edge is 5 m deep, a town house 8)
	for r in JSON.parse_string(FileAccess.get_file_as_string("res://data/town_generic.json"))["houses"]:
		fp[String(r["id"])] = r["footprint"]
	for f in c.placed:
		for xf in c.placed[f]:
			n += 1
			var on := false  # its house: the thing's place in its frame on the ground, by a front corner or a side
			for h in root.get_children():
				var l := (h as Node3D).to_local((xf as Transform3D).origin)
				var hd := float((fp.get(String(h.name), [9.0, 8.0]) as Array)[1]) / 2.0
				var hw := float((fp.get(String(h.name), [9.0, 8.0]) as Array)[0]) / 2.0
				if absf(l.y) < 0.01 and l.z > hd - 1.5 and l.z < hd + 1.5 and absf(l.x) < hw + 1.5:
					on = true
					break
			assert_true(on, "%s on its house's ground by its walls" % f)
	assert_eq(n, int(c.counts["things"]), "every thing drawn")
