extends GutTest
## The town houses to enter (sprint 8, step 7; ../tibet-blender kit/houses.py town_house(interior=True), kit/rooms.py
## house_kitchen): each variant's door stands open, so a ray through it at chest height goes well into the room; the
## room's floor, a side wall and its ceiling stand where its sidecar says (the collision's boxes round the carved room);
## its kitchen's furnishings fit inside the room; and its guest's tea (ISS-105) stands at the kitchen's BOWL, within
## reach of the household's seat and of a free seat beside it.

const VARIANTS := 3


static func godot(p: Array) -> Vector3:
	return Vector3(float(p[0]), float(p[2]), -float(p[1]))  # the kit's frame (x, y, z up) -> Godot's (x, z, -y)


func _ray(house: Node3D, from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(house.global_transform * from, house.global_transform * to)
	return house.get_world_3d().direct_space_state.intersect_ray(q)


func test_the_houses_open_onto_their_kitchens() -> void:
	for v in range(1, VARIANTS + 1):
		var t := "town_house_b2_in_v%d" % v
		var path := "res://assets/generated/kit/types/%s.glb" % t
		if not ResourceLoader.exists(path):
			fail_test("%s not built" % t)
			continue
		var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path.get_basename() + ".json"))
		var house: Node3D = (load(path) as PackedScene).instantiate()
		add_child_autofree(house)
		house.position = Vector3(60.0 * v, -100.0, 0.0)  # each its own place: a ray must meet its own house
		await wait_physics_frames(2)
		var r: Array = side["rooms"][0]  # x0, x1, y0, y1, z0 (the floor), z1 (the ceiling), in the kit's frame
		var door: Vector3 = godot(side["socket_pos"]["SOCK_DOOR_1"])
		var mid := godot([(float(r[0]) + float(r[1])) / 2.0, (float(r[2]) + float(r[3])) / 2.0, float(r[4])])
		# through the open door at chest height: nothing until well inside
		var from := door + Vector3(0.0, 1.2, 1.0)
		var hit := _ray(house, from, from + Vector3(0.0, 0.0, -12.0))
		var went := 12.0 if hit.is_empty() else (house.global_transform.affine_inverse() * (hit["position"] as Vector3)).distance_to(from)
		assert_gt(went, 3.0, "%s: its door open, the way in clear" % t)
		# the floor under the room's middle, a side wall, the ceiling
		var f := _ray(house, mid + Vector3(0.0, 1.0, 0.0), mid - Vector3(0.0, 1.0, 0.0))
		assert_false(f.is_empty(), "%s: a floor in the room" % t)
		if not f.is_empty():
			assert_almost_eq((house.global_transform.affine_inverse() * (f["position"] as Vector3)).y, float(r[4]), 0.05, "%s: at its height" % t)
		var w := _ray(house, mid + Vector3(0.0, 1.2, 0.0), mid + Vector3(8.0, 1.2, 0.0))
		assert_false(w.is_empty(), "%s: its side wall" % t)
		if not w.is_empty():
			assert_almost_eq((house.global_transform.affine_inverse() * (w["position"] as Vector3)).x, float(r[1]), 0.1, "%s: where the room ends" % t)
		var c := _ray(house, mid + Vector3(0.0, 1.0, 0.0), mid + Vector3(0.0, 4.0, 0.0))
		assert_false(c.is_empty(), "%s: its ceiling" % t)
		if not c.is_empty():
			assert_almost_eq((house.global_transform.affine_inverse() * (c["position"] as Vector3)).y, float(r[5]), 0.1, "%s: its height" % t)


func test_each_kitchen_fits_its_room() -> void:
	for v in range(1, VARIANTS + 1):
		var t := "house_kitchen_b2_in_v%d" % v
		var path := "res://assets/generated/kit/types/%s.glb" % t
		if not ResourceLoader.exists(path):
			fail_test("%s not built" % t)
			continue
		var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path.get_basename() + ".json"))
		var r: Array = side["rooms"][0]  # the room in the kitchen's own frame: lx0, lx1, 0, depth, -0.2, height
		var room := AABB(Vector3(float(r[0]), -0.25, -float(r[3])), Vector3(float(r[1]) - float(r[0]), float(r[5]) + 0.25, float(r[3])))
		var k: Node3D = (load(path) as PackedScene).instantiate()
		add_child_autofree(k)
		for m in k.find_children("*_L0", "MeshInstance3D", true, false):
			var box := (m as MeshInstance3D).transform * (m as MeshInstance3D).get_aabb()
			assert_true(room.grow(0.3).encloses(box), "%s: its furnishings inside the room (%s in %s)" % [t, box, room])
		assert_true((side["socket_pos"] as Dictionary).has("SOCK_FIRE_1"), "%s: the stove's fire" % t)
		assert_true((side["socket_pos"] as Dictionary).has("SOCK_FLAME_1"), "%s: the shrine's lamp" % t)


func test_tea_in_each_kitchen() -> void:
	var Tea: GDScript = load("res://world/tea.gd")
	var reach: float = Tea.get_script_constant_map()["REACH"]
	var near: float = Tea.get_script_constant_map()["NEAR"]
	var days: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/generic_days.json"))["people"]
	var host_seat := {}  # kitchen variant -> the household's seat (data/generic_days.json, room:<kitchen>:seat:<n>)
	for who in days:
		for stop in days[who]["day"]:
			if stop.size() > 5 and stop[5] is String and String(stop[5]).begins_with("room:house_kitchen_b2_in_v"):
				var parts := String(stop[5]).split(":")
				host_seat[parts[1]] = int(parts[3])
	for v in range(1, VARIANTS + 1):
		var t := "house_kitchen_b2_in_v%d" % v
		var room: Node3D = (load("res://interiors/houses/%s.tscn" % t) as PackedScene).instantiate()
		add_child_autofree(room)
		var tea := room.find_child("Tea", true, false) as Node3D
		assert_not_null(tea, "%s: its guest's tea" % t)
		if tea == null:
			continue
		assert_almost_eq(float(tea.get_meta("r", 0.0)), 0.06, 0.001, "%s: its bowl's size" % t)
		var seats := room.find_children("SOCK_SEAT_*", "Node3D", true, false)
		assert_true(host_seat.has(t), "%s: a household seated in it" % t)
		var free_near := false
		for st in seats:
			var d := Vector2((st as Node3D).position.x - tea.position.x, (st as Node3D).position.z - tea.position.z).length()
			if String(st.name) == "SOCK_SEAT_%d" % int(host_seat.get(t, -1)):
				assert_lt(d, reach, "%s: the household's seat within reach of the guest's bowl" % t)
			elif d < near:
				free_near = true
		assert_true(free_near, "%s: a free seat by the guest's bowl" % t)
