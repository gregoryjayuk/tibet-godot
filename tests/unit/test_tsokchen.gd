extends GutTest
## Dungkar Gönpa whole, step 1 (M3 sprint 3; tools/town/gonpa_ways.py, tools/town/monastery.py, ../tibet-blender
## kit/monastery.py tsokchen, tsokchen_court, south_gate): the Tsokchen on its platform 4 m over its courtyard (chapter
## 02's 2,932 and 2,928 m), each drawn by its own kit; the way up from the South Gate's passage to the courtyard's, its
## steps of 19 cm, the monks' houses kept off it; the gate's passage and the courtyard's open, as world/town.gd places them.

const Town := preload("res://world/town.gd")
const MONASTERY := "res://data/monastery.json"
const GONPA := "res://data/gonpa_ways.json"
const KIT := "res://assets/generated/kit/types/%s.glb"


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func test_the_hall_over_its_courtyard() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var pads: Dictionary = _json(MONASTERY)["pads"]
	assert_almost_eq(float(pads["MON-01"]["level"]), 2932.0, 0.01, "the hall's floor at 2,932 m (chapter 02)")
	assert_almost_eq(float(pads["MON-02"]["level"]), 2928.0, 0.01, "its courtyard at 2,928 m, 4 m below: the twenty steps (ISS-190)")
	assert_eq(String(pads["MON-01"]["kit"]), "mon01_tsokchen_in_v1", "the Tsokchen whole, its hall carved (M3 sprint 5, step 1)")
	assert_eq(String(pads["MON-02"]["kit"]), "mon02_tsokchen_court_v1", "its courtyard, its galleries, darchen and burner")
	for k in ["mon01_tsokchen_in_v1", "mon02_tsokchen_court_v1", "mon17_south_gate_v1"]:
		assert_true(ResourceLoader.exists(KIT % k), "%s exported and imported" % k)
	assert_false(pads.has("MON-25"), "the courtyard's sang burner the courtyard's own, not a pad of its own")


func test_the_way_up_from_the_south_gate() -> void:
	if not FileAccess.file_exists(GONPA):
		pending("no data/gonpa_ways.json (tools/py tools/town/gonpa_ways.py)")
		return
	var g := _json(GONPA)
	var legs: Dictionary = g["legs"]
	assert_between(int(legs["steps"]), 200, 280, "some 240 steps from the gate's 2,882.6 m to the courtyard's 2,928 m")
	assert_almost_eq(float(legs["riser"]), 0.19, 0.006, "risers of 19 cm (chapter 03)")
	var walk: Array = g["walk"]
	var gate := Vector2(465.0, 65.0)
	var near_gate := INF
	for q in walk:
		near_gate = minf(near_gate, Vector2(float(q[0]), float(q[1])).distance_to(gate))
	assert_lt(near_gate, 3.5, "in through the South Gate's passage")
	var court: Dictionary = g["court"]
	var c := Vector2(float(court["at"][0]), float(court["at"][1]))
	var last := Vector2(float(walk[walk.size() - 1][0]), float(walk[walk.size() - 1][1]))
	assert_true(absf(last.x - c.x) < float(court["size"][0]) / 2.0 and absf(last.y - c.y) < float(court["size"][1]) / 2.0, "into the courtyard")
	assert_almost_eq(float(walk[walk.size() - 1][2]), float(court["z"]), 0.01, "at its level")
	if not FileAccess.file_exists(MONASTERY):
		return
	var m := _json(MONASTERY)
	var houses: Array = (m["houses"] as Array) + (m.get("buildings", []) as Array)
	var bad: Array = []  # a house standing on the way: its middle nearer a lane's middle line than its own half-width
	for ln in g["lanes"]:
		var o := Vector2(float(ln["from"][0]), float(ln["from"][1]))
		var d := Vector2(float(ln["dir"][0]), float(ln["dir"][1]))
		var L := float(ln["length"])
		for h in houses:
			var hp := Vector2(float(h["pos"][0]), float(h["pos"][1]))
			var s := clampf((hp - o).dot(d), 0.0, L)
			var r := minf(float(h["footprint"][0]), float(h["footprint"][1])) / 2.0 + float(ln["width"]) / 2.0
			if (o + d * s).distance_to(hp) < r:
				bad.append("%s on %s" % [h["id"], ln["id"]])
	assert_eq(bad.size(), 0, "the monks' houses kept off the way: %s" % [bad])


## The passages open as the town places them: a body's height through the South Gate's and the courtyard's south range's.
func test_the_passages_open() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var root := Node3D.new()
	add_child_autofree(root)
	Town.place(root, Rect2(Vector2(450.0, 50.0), Vector2(100.0, 70.0)))
	await wait_physics_frames(3)
	var space := root.get_world_3d().direct_space_state
	for spec in [["MON-17", -3.6, 2.9], ["MON-02", -21.0, -10.0]]:  # (the gate's through its gatehouse only: the way's first flight rises 1 m beyond its back)
		var n := root.get_node_or_null("Town/%s" % spec[0]) as Node3D
		assert_not_null(n, "%s placed" % spec[0])
		if n == null:
			continue
		for h in [0.6, 1.2, 1.8]:
			var a: Vector3 = n.global_transform * Vector3(0.0, h, -float(spec[1]))  # (the kit's (0, y, h): Godot's (0, h, -y))
			var b: Vector3 = n.global_transform * Vector3(0.0, h, -float(spec[2]))
			var q := PhysicsRayQueryParameters3D.create(a, b, 1)
			var hit := space.intersect_ray(q)
			assert_true(hit.is_empty(), "%s's passage open at %.1f m%s" % [spec[0], h, "" if hit.is_empty() else ": met %s at %s" % [hit["collider"], hit["position"]]])
