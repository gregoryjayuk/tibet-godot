extends GutTest
## The arrival by the Serchu road (M2 sprint 3; data/arrival.json, data/south_ramp.json, ../tibet-blender
## export_arrival.py, the kit's ser01_gate_chorten and chorten8_f1-f8): R-01's line from SER-20 by the cliff gallery
## and the Gate Chorten to the south pavilion, no stretch steeper than a laden animal takes; the gallery's deck
## underfoot along its length and a wall at its outer edge, so nobody falls; the Gate Chorten's passage open on the
## road's level and closed above its lintels; the south ramp down to the lower bridge's deck at the north ramp's level;
## the eight chortens built, all eight forms.

const ARRIVAL := "res://data/arrival.json"
const GALLERY := "res://assets/generated/kit/arrival/ser03_gallery.glb"
const GATE := "res://assets/generated/kit/types/ser01_gate_chorten_v1.glb"


func _ray(root: Node3D, a: Vector3, b: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(root.global_transform * a, root.global_transform * b)
	return root.get_world_3d().direct_space_state.intersect_ray(q)


func test_the_road_runs_from_ser20_to_the_pavilion() -> void:
	var a: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARRIVAL))
	var road: Array = a["road_west"]
	assert_eq([road[0][0], road[0][1]], [430.0, -250.0], "from SER-20")
	assert_eq([road[road.size() - 1][0], road[road.size() - 1][1]], [-122.0, -141.0], "to the south pavilion's front")
	var through := false
	for k in road.size() - 1:
		var p: Array = road[k]
		var q: Array = road[k + 1]
		var run := Vector2(float(q[0]) - float(p[0]), float(q[1]) - float(p[1])).length()
		assert_lt(absf(float(q[2]) - float(p[2])) / maxf(run, 0.01), 0.17, "stretch %d no steeper than 17%%" % k)
		if Vector2(float(p[0]), float(p[1])).distance_to(Vector2(170.0, -175.0)) < 9.0:
			through = true
	assert_true(through, "by the Gate Chorten")
	var ramp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/south_ramp.json"))
	var north: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/north_ramp.json"))
	assert_lt(float(ramp["grade"]), 0.16, "the south ramp's legs at the north ramp's pitch, about 15%")
	assert_almost_eq(float(ramp["foot"][2]), float(north["foot"][2]), 0.01, "down to the lower bridge's deck")


func test_the_gallery_holds_the_walker() -> void:
	if not ResourceLoader.exists(GALLERY):
		fail_test("the gallery not built (../tibet-blender export_arrival.py)")
		return
	var a: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARRIVAL))
	var ga: Array = a["gallery"]["from"]
	var gb: Array = a["gallery"]["to"]
	var L := Vector2(float(gb[0]) - float(ga[0]), float(gb[1]) - float(ga[1])).length()
	var drop := float(gb[2]) - float(ga[2])
	var g: Node3D = (load(GALLERY) as PackedScene).instantiate()
	add_child_autofree(g)
	g.position = Vector3(0.0, -400.0, 0.0)
	await wait_physics_frames(2)
	for f in [0.1, 0.33, 0.5, 0.8, 0.95]:
		var y: float = L * f
		var deck: float = drop * f
		var hit := _ray(g, Vector3(0.0, deck + 2.0, -y), Vector3(0.0, deck - 2.0, -y))  # the kit's y along it is Godot's -z
		assert_false(hit.is_empty(), "the deck underfoot %.0f m along" % y)
		if not hit.is_empty():
			assert_almost_eq((g.global_transform.affine_inverse() * (hit["position"] as Vector3)).y, deck, 0.12, "at the deck's level")
		var edge := _ray(g, Vector3(0.0, deck + 0.6, -y), Vector3(3.0, deck + 0.6, -y))  # out over the slot (the kit's +x)
		assert_false(edge.is_empty(), "a wall at its outer edge %.0f m along: nobody falls" % y)


func test_the_gate_chorten_passage_is_open() -> void:
	if not ResourceLoader.exists(GATE):
		fail_test("the Gate Chorten not built")
		return
	var c: Node3D = (load(GATE) as PackedScene).instantiate()
	add_child_autofree(c)
	c.position = Vector3(0.0, -500.0, 0.0)
	await wait_physics_frames(2)
	assert_true(_ray(c, Vector3(0.0, 1.5, 6.0), Vector3(0.0, 1.5, -6.0)).is_empty(), "the passage open at head height, portal to portal")
	assert_false(_ray(c, Vector3(0.0, 4.2, 6.0), Vector3(0.0, 4.2, -6.0)).is_empty(), "closed above the lintels")
	assert_false(_ray(c, Vector3(2.5, 1.5, 6.0), Vector3(2.5, 1.5, -6.0)).is_empty(), "its walls beside the passage")


func test_the_eight_chortens_are_built() -> void:
	for k in range(1, 9):
		assert_true(ResourceLoader.exists("res://assets/generated/kit/types/chorten8_f%d_v1.glb" % k), "form %d built" % k)
