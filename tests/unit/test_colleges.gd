extends GutTest
## Dungkar Gönpa whole, step 2 (M3 sprint 3; tools/town/monastery.py MOVE, LEVEL, FORECOURT; tools/town/gonpa_ways.py
## CHORA_WALK; ../tibet-blender kit/monastery.py college, chora): the Tsenyi Dratsang beside the Chöra at its level, its
## side door facing the court's west gate across a flagged walk; both colleges and the court drawn by their own kits; the
## court's gate open and its walls met, as world/town.gd places them.

const Town := preload("res://world/town.gd")
const MONASTERY := "res://data/monastery.json"
const GONPA := "res://data/gonpa_ways.json"
const KIT := "res://assets/generated/kit/types/%s.glb"


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func test_the_college_beside_its_court() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var pads: Dictionary = _json(MONASTERY)["pads"]
	var c: Dictionary = pads["MON-06"]
	var k: Dictionary = pads["MON-07"]
	assert_almost_eq(float(c["level"]), float(k["level"]), 0.01, "the Tsenyi Dratsang at the Chöra's level")
	var east := float(c["at"][0]) + 9.0  # (18 m wide, facing 180: its east wall)
	var west := float(k["at"][0]) - 15.0  # (the court 30 m)
	assert_between(west - east, 4.0, 8.0, "its east wall across a few metres from the court's west wall")
	assert_almost_eq(float(c["at"][1]), float(k["at"][1]), 0.5, "its side door facing the court's gate")
	assert_true(c.has("moved_from"), "moved beside the court (chapter 02's place stood it 13 m north of it)")
	assert_almost_eq(float(c.get("yard", 0.0)), 5.7, 0.01, "its portico and forecourt levelled with it, its steps down from their front")
	assert_almost_eq(float(pads["MON-08"].get("yard", 0.0)), 7.6, 0.01, "the Gyüpa's closed forecourt on level ground to its front wall and past")
	assert_eq(String(k["kit"]), "mon07_chora_v1", "the Chöra its own kit")
	for kt in ["mon06_philosophy_college_v1", "mon08_tantric_college_v1", "mon07_chora_v1"]:
		assert_true(ResourceLoader.exists(KIT % kt), "%s exported and imported" % kt)


func test_the_walk_to_the_court() -> void:
	if not FileAccess.file_exists(GONPA):
		pending("no data/gonpa_ways.json")
		return
	var walk: Dictionary = {}
	for ln in _json(GONPA)["lanes"]:
		if String(ln["id"]) == "MON-C.01":
			walk = ln
	assert_false(walk.is_empty(), "the walk from the college's side door to the court's gate")
	if walk.is_empty() or not FileAccess.file_exists(MONASTERY):
		return
	var k: Dictionary = _json(MONASTERY)["pads"]["MON-07"]
	assert_almost_eq(float(walk["z_a"]), float(k["level"]), 0.01, "at the court's level")
	var a := Vector2(float(walk["from"][0]), float(walk["from"][1]))
	var b := a + Vector2(float(walk["dir"][0]), float(walk["dir"][1])) * float(walk["length"])
	assert_lt(a.x, float(k["at"][0]) - 15.0, "from outside the court")
	assert_gt(b.x, float(k["at"][0]) - 15.0, "in through its west wall")


func test_the_courts_gate_open() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var root := Node3D.new()
	add_child_autofree(root)
	Town.place(root, Rect2(Vector2(580.0, 50.0), Vector2(80.0, 50.0)))
	await wait_physics_frames(3)
	var space := root.get_world_3d().direct_space_state
	var k: Dictionary = _json(MONASTERY)["pads"]["MON-07"]
	var cx := float(k["at"][0])
	var cy := float(k["at"][1])
	var z := float(k["level"])
	for h in [0.6, 1.2, 1.8]:
		var q := PhysicsRayQueryParameters3D.create(Town.to_godot(cx - 19.0, cy, z + h), Town.to_godot(cx - 9.0, cy, z + h), 1)
		var hit := space.intersect_ray(q)
		assert_true(hit.is_empty(), "in at the west gate at %.1f m%s" % [h, "" if hit.is_empty() else ": met %s" % hit["collider"]])
	var q2 := PhysicsRayQueryParameters3D.create(Town.to_godot(cx, cy + 9.0, z + 1.2), Town.to_godot(cx, cy + 14.0, z + 1.2), 1)
	assert_false(space.intersect_ray(q2).is_empty(), "its north wall met")
