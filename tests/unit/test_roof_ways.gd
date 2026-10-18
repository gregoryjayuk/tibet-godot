extends GutTest
## A way onto every roof the town can reach (tools/town/roof_ways.py; IMP-026, ISS-114): each piece leads onto a roof,
## none stands by a door, and placed as world/town.gd places them each plank can be walked along its length.

const Town := preload("res://world/town.gd")
const WAYS := "res://assets/generated/terrain/roof_ways.json"

var pieces: Array = []


func before_all() -> void:
	if FileAccess.file_exists(WAYS):
		pieces = JSON.parse_string(FileAccess.get_file_as_string(WAYS))["pieces"]


func test_each_onto_a_roof() -> void:
	if pieces.is_empty():
		pending("no roof_ways.json (tools/town/roof_ways.py)")
		return
	assert_gt(pieces.size(), 20, "ways onto many roofs")
	var kinds := {}
	for pc in pieces:
		assert_true(String(pc["deck"]).contains("."), "%s onto a roof" % pc["deck"])
		kinds[String(pc["kind"])] = true
		assert_has(["log", "stair", "wall", "steps", "plank"], String(pc["kind"]))
	assert_true(kinds.has("plank"), "planks from the upper yards")


func test_the_planks_walked_along() -> void:
	if pieces.is_empty():
		pending("no roof_ways.json")
		return
	var planks := pieces.filter(func(p: Dictionary) -> bool: return p["kind"] == "plank")
	var box := Rect2()
	for i in planks.size():
		var a: Array = planks[i]["from"]
		var r := Rect2(Vector2(a[0], a[1]), Vector2.ZERO).grow(4.0)
		box = r if i == 0 else box.merge(r)
	var root := Node3D.new()
	add_child_autofree(root)
	var counts: Dictionary = Town.place(root, box)
	gut.p("placed round the planks: %s" % [counts])
	assert_gt(int(counts.get("roof_ways", 0)), planks.size() - 1, "the pieces placed")
	await wait_physics_frames(3)
	var space := root.get_world_3d().direct_space_state
	var bad := 0
	for pc in planks:
		var a: Array = pc["from"]
		var b: Array = pc["to"]
		for q in [0.25, 0.5, 0.75]:
			var x := lerpf(a[0], b[0], q)
			var y := lerpf(a[1], b[1], q)
			var z := lerpf(a[2], b[2], q)
			var top := Town.to_godot(x, y, z + 1.0)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top + Vector3(0, -2.0, 0)))
			if hit.is_empty() or absf((hit["position"] as Vector3).y - Town.to_godot(x, y, z).y) > 0.25:
				bad += 1
				gut.p("plank onto %s: nothing to walk on at %.2f" % [pc["deck"], q])
	assert_eq(bad, 0, "every plank walked along")
