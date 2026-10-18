extends GutTest
## Washing hung to dry (world/laundry.gd; IMP-023 (1), Greg's 1775): about a third of the households have a line out,
## none of the shut ones; most across their yard, a metre and a half before the front and about 1.9 m up, a few on their
## roofs; robes on the lines of a household with a son in the monastery; no two lines alike; each piece drawn as cloth.

const Laundry := preload("res://world/laundry.gd")
const Households := preload("res://world/households.gd")

var root: Node3D
var town: GDScript


func before_each() -> void:
	town = load("res://world/town.gd")
	root = Node3D.new()
	add_child_autofree(root)
	for h in JSON.parse_string(FileAccess.get_file_as_string("res://data/town_generic.json"))["houses"]:
		var n := Node3D.new()
		n.name = String(h["id"])
		root.add_child(n)
		n.position = town.call("to_godot", float(h["pos"][0]), float(h["pos"][1]), float(h["pos"][2]))
		n.rotation.y = -deg_to_rad(float(h["rot_deg"]) - 180.0)


func test_a_third_of_the_households() -> void:
	var hh := Households.new()
	add_child_autofree(hh)
	hh.build(root)
	var l := Laundry.new()
	add_child_autofree(l)
	var c: Dictionary = l.build(root, hh)
	var n := root.get_child_count()
	assert_between(float(c["lines"]) / float(n), 0.2, 0.4, "about a third")
	assert_eq(int(c["roofs"]), 0, "none on the bare test houses' roofs (they have no corners)")
	assert_gt(int(c["robes"]), 3, "robes on some lines")
	for h in l.per_house:
		assert_false(hh.is_shut(String(h)), "%s shut: no washing" % h)
	var seen := {}
	for h in l.per_house:
		var key := ",".join(PackedStringArray(l.per_house[h]))
		seen[key] = int(seen.get(key, 0)) + 1
	assert_gt(seen.size(), int(c["lines"]) * 0.7, "the lines their own")


func test_in_the_yard_and_drawn() -> void:
	var l := Laundry.new()
	add_child_autofree(l)
	l.build(root)
	var pieces := 0
	var cloths := 0
	for mi in l.get_children():
		if String(mi.name).begins_with("cloth_"):
			cloths += 1
			var mm := (mi as MultiMeshInstance3D).multimesh
			pieces += mm.instance_count
			assert_not_null(mm.mesh, "%s has its cloth" % mi.name)
			assert_true(mm.use_custom_data, "its colour and pattern")
	assert_gt(cloths, 0, "cloth drawn")
	assert_eq(pieces, int(l.counts["pieces"]), "every piece drawn")
	# every piece hangs before a house's front, a metre or two out, its top about 1.9 m over the house's pad
	assert_eq(l.tops.size(), pieces, "every piece's top kept")
	var fp := {}  # each house's footprint (a poor one-room house of the west edge is 5 m deep, a town house 8)
	for r in JSON.parse_string(FileAccess.get_file_as_string("res://data/town_generic.json"))["houses"]:
		fp[String(r["id"])] = r["footprint"]
	for i in l.tops.size():
		if true:
			var top: Vector3 = l.tops[i]
			var found := false
			for h in root.get_children():  # its house: a metre to three out from its front, within its width
				var local := (h as Node3D).to_local(top)
				var hd := float((fp.get(String(h.name), [9.0, 8.0]) as Array)[1]) / 2.0
				if local.z > hd + 1.0 and local.z < hd + 3.0 and absf(local.x) < 6.5 and absf(local.y - 1.85) < 0.3:
					found = true
					break
			assert_true(found, "piece %d on a line before a house's front, at its height" % i)
