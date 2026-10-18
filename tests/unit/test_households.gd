extends GutTest
## Each household its own (world/households.gd; IMP-019): about a fifth of the town's houses shut, never a walker's home
## or a house to enter, and a few of those left for good, long unkept, their flags bare poles (world/flags.gd), a shut
## house's flags old rags; every house's upkeep, paint and warmth its own and in range, a few limed fresh
## and a few poorly kept, all six paint schemes in use, and each set on every mesh of its house as the shader's
## `household`; the plain switch (tests/terrain/s3.gd --off=households) draws them as the kit does; and a shut house's
## hearth is cold (world/hearths.gd).

const Households := preload("res://world/households.gd")
const Hearths := preload("res://world/hearths.gd")
const N := 300
const TYPES := ["town_house_b2_v1", "town_house_b1_v1", "town_house_b4_v1", "poor_house_e1_v1", "town_house_b3_v1"]

var root: Node3D


func _house(name: String) -> void:
	var h := Node3D.new()
	h.name = name
	for k in 2:
		var m := MeshInstance3D.new()
		m.mesh = BoxMesh.new()
		h.add_child(m)
	root.add_child(h)


func before_each() -> void:
	root = Node3D.new()
	add_child_autofree(root)
	for i in N:
		_house("H-T%03d" % i)
	for h in Households.kept():
		_house(String(h))


func after_each() -> void:
	Households.plain = false


func test_a_fifth_shut_a_few_left_never_the_kept() -> void:
	var kept := Households.kept()
	assert_true(kept.has("H-SHL-007"), "a house to enter is kept")
	assert_true(kept.has("H-SHL-020"), "a named townsperson's home is kept")
	assert_gt(kept.size(), 20, "every walker's home is kept")
	var hh := Households.new()
	add_child_autofree(hh)
	var r: Dictionary = hh.build(root)
	assert_eq(int(r["houses"]), N + kept.size(), "every house its household")
	assert_between(float(r["shut"]) / float(N), 0.14, 0.27, "about a fifth shut")
	assert_between(float(r["left"]) / float(N), 0.01, 0.1, "a few left for good")
	for h in kept:
		assert_false(hh.is_shut(String(h)), "%s lived in" % h)
		assert_false(hh.is_left(String(h)), "%s not left" % h)
	for h in hh.per_house:
		if hh.is_left(String(h)):
			assert_true(hh.is_shut(String(h)), "%s left: shut" % h)
			assert_lt(float(hh.per_house[h]["upkeep"]), 0.3, "%s left: long unkept" % h)


func test_each_its_own_and_drawn() -> void:
	var hh := Households.new()
	add_child_autofree(hh)
	hh.build(root)
	var seen := {}
	var schemes := {}
	var lived := 0
	var fresh := 0
	var poor := 0
	var drawn := 0
	for h in root.get_children():
		var name := String(h.name)
		var d: Dictionary = hh.per_house[name]
		assert_between(float(d["upkeep"]), 0.0, 1.0, "%s's upkeep" % name)
		assert_between(int(d["paint"]), -1 if name.begins_with(Households.HAN) else 0, 5, "%s's paint (a Han house's -1: none of the town's)" % name)
		assert_between(float(d["warmth"]), 0.0, 1.0, "%s's lime" % name)
		var key := "%.5f %d %.5f" % [d["upkeep"], d["paint"], d["warmth"]]
		assert_false(seen.has(key), "%s its own" % name)
		seen[key] = true
		if int(d["paint"]) >= 0:
			schemes[int(d["paint"])] = true
		if not bool(d["shut"]):
			lived += 1
			fresh += int(float(d["upkeep"]) >= 0.9)
			poor += int(float(d["upkeep"]) < 0.45)
		var want := Vector4(d["upkeep"], float(d["paint"]), d["warmth"], 1.0 if d["shut"] else 0.0)
		for m in h.get_children():
			var v = (m as GeometryInstance3D).get_instance_shader_parameter("household")
			if v != null:  # the rendering server keeps it (it does headless too)
				assert_eq(v, want, "%s drawn as its household" % name)
				drawn += 1
	assert_eq(schemes.size(), 6, "every paint scheme in use")
	assert_between(float(fresh) / float(lived), 0.1, 0.3, "a few limed fresh this season")
	assert_between(float(poor) / float(lived), 0.1, 0.35, "a few poorly kept")
	assert_gt(drawn, 0, "the household set on the meshes")


func test_plain_draws_the_kit() -> void:
	Households.plain = true
	var hh := Households.new()
	add_child_autofree(hh)
	var r: Dictionary = hh.build(root)
	assert_eq(int(r["shut"]), int(r["left"]), "only the left houses cold, as before")
	for h in root.get_children():
		for m in h.get_children():
			var v = (m as GeometryInstance3D).get_instance_shader_parameter("household")
			if v != null:
				assert_eq(v, Households.PLAIN, "%s as the kit draws it" % h.name)


func test_a_shut_house_has_a_cold_hearth() -> void:
	var town := Node3D.new()
	add_child_autofree(town)
	for i in 40:
		var h: Node3D = (load("res://assets/generated/kit/types/%s.glb" % TYPES[i % TYPES.size()]) as PackedScene).instantiate()
		h.name = "H-%03d" % i
		town.add_child(h)
		h.position = Vector3(float(i % 8) * 30.0, 0.0, float(i / 8) * 30.0)
	var hh := Households.new()
	add_child_autofree(hh)
	var r: Dictionary = hh.build(town)
	assert_gt(int(r["shut"]), 2, "some shut among forty")
	var hearths := Hearths.new()
	town.add_child(hearths)
	hearths.build(town, null, hh)
	var smoking := {}
	for t in hearths.hearths:
		smoking[String(t[0])] = true
	for h in hh.per_house:
		if hh.is_shut(String(h)):
			assert_false(smoking.has(h), "no smoke from %s, shut" % h)
			assert_true(hearths.cold.has(h), "%s's hearth cold" % h)
