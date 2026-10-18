extends GutTest
## The hearths' smoke (world/hearths.gd; M1 sprint 8, step 2): a thread from every kitchen but a left house's and a few
## cold hearths; each household its own hours: nearly all smoking at 07:00 and at 18:30, none at 03:00 or 22:00, some at
## noon, only the kept threads mid-afternoon; each thread leaves its wall outwards.

const Hearths := preload("res://world/hearths.gd")
const TYPES := ["town_house_b2_v1", "town_house_b1_v1", "town_house_b4_v1", "poor_house_e1_v1", "town_house_b3_v1"]

var root: Node3D
var hearths: Node3D
var flags: Node


func before_each() -> void:
	root = Node3D.new()
	add_child_autofree(root)
	for i in 40:
		var h: Node3D = (load("res://assets/generated/kit/types/%s.glb" % TYPES[i % TYPES.size()]) as PackedScene).instantiate()
		h.name = "H-%03d" % i
		root.add_child(h)
		h.position = Vector3(float(i % 8) * 30.0, 0.0, float(i / 8) * 30.0)
		h.rotation.y = float(i) * 0.7
	flags = autofree((load("res://world/flags.gd") as GDScript).new())
	flags.set("per_house", {"H-007": ["left", 2, 0], "H-008": ["bundle", 1, 9]})
	hearths = Hearths.new()
	root.add_child(hearths)
	hearths.build(root, flags)


func _share(m: float) -> float:
	var n := 0
	for i in hearths.hearths.size():
		if hearths.smoking(i, m) > 0.05:
			n += 1
	return float(n) / float(hearths.hearths.size())


func test_every_kitchen_but_the_left_and_the_cold() -> void:
	var names: Array = hearths.hearths.map(func(h): return h[0])
	assert_false(names.has("H-007"), "no smoke from a left house")
	assert_true(hearths.cold.has("H-007"))
	assert_eq(hearths.hearths.size() + hearths.cold.size(), 40, "every house with a kitchen: a thread, or cold")
	assert_lt(hearths.cold.size(), 8, "a few cold hearths, not many")


func test_their_hours() -> void:
	assert_gt(_share(7.0 * 60.0), 0.9, "the morning fires at 07:00")
	assert_gt(_share(18.5 * 60.0), 0.9, "the evening fires at 18:30")
	assert_eq(_share(3.0 * 60.0), 0.0, "none at 03:00")
	assert_eq(_share(22.0 * 60.0), 0.0, "none at 22:00")
	assert_between(_share(12.0 * 60.0), 0.35, 0.95, "some at noon")
	assert_between(_share(15.0 * 60.0), 0.1, 0.6, "only the kept threads mid-afternoon")


func test_no_two_alike() -> void:
	var seen := {}
	for h in hearths.hearths:
		var d: Dictionary = h[1]
		var key := "%.1f %.1f" % [float(d["morning"][0]), float(d["evening"][0])]
		assert_false(seen.has(key), "%s's hours its own" % h[0])
		seen[key] = true


func test_out_of_the_wall() -> void:
	assert_eq((hearths.smoke as MultiMeshInstance3D).multimesh.instance_count, hearths.hearths.size())
	for i in hearths.hearths.size():
		var xf: Transform3D = hearths.hearths[i][2]  # (a headless run's renderer gives no instance back)
		var house := root.get_node(String(hearths.hearths[i][0])) as Node3D
		var away := xf.origin - house.global_position
		away.y = 0.0
		assert_gt(xf.basis.x.dot(away.normalized()), 0.2, "%s's thread leaves its wall outwards" % hearths.hearths[i][0])
