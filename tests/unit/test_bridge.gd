extends GutTest
## The plank-and-rope bridge over the Sky Stair (IMP-023 (3), after Greg's 1773; tools/town/bridges.py,
## ../tibet-blender/export_bridges.py), placed as world/town.gd places it: its deck walked on all the way along its sag,
## no gap a foot goes through, walls along both sides that nobody falls past, room under it for the pilgrims on the
## stair, and a way onto both its roofs (a ladder up the east house's wall, a plank from the lane behind the west).

const Town := preload("res://world/town.gd")
const BRIDGES := "res://assets/generated/terrain/bridges.json"

var br: Dictionary
var bj: Dictionary


func before_all() -> void:
	if FileAccess.file_exists(BRIDGES):
		bj = JSON.parse_string(FileAccess.get_file_as_string(BRIDGES))
		if not (bj["bridges"] as Array).is_empty():
			br = bj["bridges"][0]


func _deck(q: float) -> float:
	## The deck's top at q (0 to 1) along the bridge, in the town grid's metres, as the kit builds it.
	var L := float(br["length"])
	var rest := float(br["rest"])
	var y := q * L
	if y <= rest:
		return float(br["a"][2])
	if y >= L - rest:
		return float(br["b"][2])
	var k := (y - rest) / (L - 2.0 * rest)
	return float(br["a"][2]) + float(br["rise"]) * k - 4.0 * float(br["sag"]) * k * (1.0 - k)


func test_a_bridge_and_its_ways() -> void:
	if br.is_empty():
		pending("no bridges.json (tools/town/bridges.py)")
		return
	assert_eq(String(br["ends"][0]), "H-SHL-061.0")
	assert_eq(String(br["ends"][1]), "H-SHL-080.0")
	assert_gt(float(br["under"]), 2.5, "room under it for the stair's walkers")
	assert_lt(absf(float(br["rise"])), 1.2, "level enough to run")
	var onto := {}
	for pc in bj["pieces"]:
		onto[String(pc["deck"])] = String(pc["kind"])
	for d in br["ends"]:
		assert_true(onto.has(String(d)), "a way onto %s" % d)


func test_walked_on_its_deck_between_its_walls() -> void:
	if br.is_empty():
		pending("no bridges.json")
		return
	var a := Vector2(float(br["a"][0]), float(br["a"][1]))
	var b := Vector2(float(br["b"][0]), float(br["b"][1]))
	var box := Rect2(a, Vector2.ZERO).expand(b).grow(8.0)
	var root := Node3D.new()
	add_child_autofree(root)
	var counts: Dictionary = Town.place(root, box)
	gut.p("placed round the bridge: %s" % [counts])
	var bn := root.find_child("BRIDGE_BR-01", true, false) as Node3D
	assert_not_null(bn, "the bridge placed")
	if bn != null:  # its deck gives under the walker (IMP-027), all its meshes alike
		for mi in bn.find_children("*", "MeshInstance3D", true, false):
			assert_gt(float((mi as MeshInstance3D).get_instance_shader_parameter("give")), 0.0, "%s gives" % mi.name)
	var ladders := 0
	for l in get_tree().get_nodes_in_group("ladders"):
		if String(l.name).begins_with("BRIDGE_BR-01"):
			ladders += 1
	assert_eq(ladders, (bj["pieces"] as Array).filter(func(p: Dictionary) -> bool: return p["kind"] != "plank").size(), "its ladders placed")
	assert_gt(ladders, 0, "a ladder up a house's wall")
	await wait_physics_frames(3)
	var space := root.get_world_3d().direct_space_state
	var dv := (b - a).normalized()
	var side := Vector2(-dv.y, dv.x)
	var worst := 0.0
	var holes := 0
	for k in range(1, 88):
		var q := k / 88.0
		var p := a + (b - a) * q
		var z := _deck(q)
		var from := Town.to_godot(p.x, p.y, z + 1.0)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -2.5, 0)))
		if hit.is_empty():
			holes += 1
			continue
		worst = maxf(worst, absf((hit["position"] as Vector3).y - Town.to_godot(p.x, p.y, z).y))
	assert_eq(holes, 0, "no gap in the deck")
	assert_lt(worst, 0.15, "the deck where the planks are, along its sag (worst %.2f m)" % worst)
	for q: float in [0.25, 0.5, 0.75]:  # walls either side, at the hip
		var p := a + (b - a) * q
		var c := Town.to_godot(p.x, p.y, _deck(q) + 0.6)
		for sgn: float in [-1.0, 1.0]:
			var out := Town.to_godot(p.x + side.x * sgn * 1.2, p.y + side.y * sgn * 1.2, _deck(q) + 0.6)
			assert_false(space.intersect_ray(PhysicsRayQueryParameters3D.create(c, out)).is_empty(), "a wall at %.2f on the %s" % [q, "left" if sgn < 0 else "right"])
