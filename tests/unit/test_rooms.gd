extends GutTest
## Dechen-tsang's rooms (M1 sprint 7, step 1; plan chapter 04, 4.3, 8.2-8.6 and 10): the four rooms the trading house
## carves (tibet-blender kit/trading.py, rooms_plan) are walked on their drawn floors, 15 cm over the yard's flags; each
## doorway has its sill and is otherwise open through to the room; each room's scene (interiors/shl_04, made by
## tools/build/make_rooms.gd) carries its own light, at most three lights, unshadowed and out of the valley's haze, a
## gain for the eye, and its box round the room's socket.

const HOUSE := "res://assets/generated/kit/types/trading_house_v1"
const ROOMS := ["dechen_tibetan", "dechen_chinese", "dechen_guest", "dechen_kitchen"]
const SCENE := "res://interiors/shl_04/%s.tscn"


func _visible(root: Node3D) -> void:
	for mi in root.find_children("*_L0", "MeshInstance3D", true, false):
		var sb := StaticBody3D.new()
		sb.collision_layer = 2
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		cs.shape = (mi as MeshInstance3D).mesh.create_trimesh_shape()
		sb.add_child(cs)
		root.add_child(sb)
		sb.global_transform = (mi as MeshInstance3D).global_transform


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, mask)
	q.hit_from_inside = true
	return space.intersect_ray(q)


## The house, its drawn surfaces as trimeshes on layer 2, and its rooms (x0, x1, y0, y1, z0, z1 in the kit's frame).
func _house() -> Array:
	if not ResourceLoader.exists(HOUSE + ".glb"):
		return []
	var root: Node3D = (load(HOUSE + ".glb") as PackedScene).instantiate()
	add_child_autofree(root)
	_visible(root)
	await wait_physics_frames(2)
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HOUSE + ".json"))
	return [root, side.get("rooms", [])]


func test_the_floors_are_walked_on_their_surface() -> void:
	var h: Array = await _house()
	if h.is_empty():
		pending("no trading house (the kit's export)")
		return
	var root: Node3D = h[0]
	var rooms: Array = h[1]
	assert_eq(rooms.size(), 6, "six rooms carved in the house: the four of M1 sprint 7, the chapel and Dolkar's reception room in Yard 3 (M2 sprint 8)")
	var space := root.get_world_3d().direct_space_state
	for r in rooms:
		var n := 0
		var off := 0
		var x := float(r[0]) + 0.3
		while x < float(r[1]) - 0.3:
			var y := float(r[2]) + 0.3
			while y < float(r[3]) - 0.3:
				var p := Vector3(x, float(r[4]), -y)  # the kit's (x, y, z) is Godot's (x, z, -y)
				var vis := _ray(space, p + Vector3(0, 1.2, 0), p - Vector3(0, 0.5, 0), 2)
				var col := _ray(space, p + Vector3(0, 1.2, 0), p - Vector3(0, 0.5, 0), 1)
				n += 1
				if vis.is_empty() or col.is_empty() or absf((vis["position"] as Vector3).y - float(r[4])) > 0.03 \
						or absf((col["position"] as Vector3).y - (vis["position"] as Vector3).y) > 0.03:
					off += 1
				y += 0.5
			x += 0.5
		assert_eq(off, 0, "room at %.1f, %.1f: all %d points walked on the drawn floor, at its level" % [r[0], r[2], n])


func test_the_doorways_have_sills_and_are_open() -> void:
	var h: Array = await _house()
	if h.is_empty():
		pending("no trading house (the kit's export)")
		return
	var root: Node3D = h[0]
	var space := root.get_world_3d().direct_space_state
	for k in 4:
		var sock := root.find_child("SOCK_ROOM_%d" % (k + 1), true, false) as Node3D
		assert_not_null(sock, "the ROOM socket %d" % (k + 1))
		if sock == null:
			continue
		var into := -sock.global_transform.basis.z  # the room's +y in the kit, Godot's -z
		var door := sock.global_position
		var out := door - into * 1.6
		# over the sill's invisible box, from the yard to 1.5 m inside: nothing in the way
		var chest := _ray(space, out + Vector3(0, 1.3, 0), door + into * 1.5 + Vector3(0, 1.3, 0), 1)
		assert_true(chest.is_empty(), "room %d: the doorway open at the chest (hit %s)" % [k + 1, str(chest.get("position", ""))])
		var ankle := _ray(space, out + Vector3(0, 0.02, 0), door + Vector3(0, 0.02, 0), 1)
		assert_false(ankle.is_empty(), "room %d: something in the doorway at the ankle" % (k + 1))


## Chapter 04, 10: each threshold 0.15-0.35 m over the ground it stands on (the gate's 35 cm), stepped over, never on:
## its collision a box a metre high, which a body can neither walk onto nor stop on.
func test_the_thresholds_are_stepped_over_never_on() -> void:
	var h: Array = await _house()
	if h.is_empty():
		pending("no trading house (the kit's export)")
		return
	var root: Node3D = h[0]
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HOUSE + ".json"))
	var sills: Array = side.get("sills", [])
	assert_eq(sills.size(), 7, "the gate's threshold and the six rooms' sills")
	var space := root.get_world_3d().direct_space_state
	for sl in sills:
		assert_between(float(sl[5]), 0.15, 0.35, "a sill %.2f m high" % float(sl[5]))
		var c := Vector3(float(sl[0]), float(sl[2]), -float(sl[1]))
		var top := _ray(space, c + Vector3(0, 2.0, 0), c - Vector3(0, 0.2, 0), 1)
		assert_false(top.is_empty(), "a box over the sill at %.1f, %.1f" % [sl[0], sl[1]])
		if not top.is_empty():
			assert_gt((top["position"] as Vector3).y - c.y, 1.0, "the box over the sill at %.1f, %.1f a metre high" % [sl[0], sl[1]])
	assert_eq(float(sills[0][4]), 3.2, "the gate's threshold the width of its gateway")


func test_each_room_scene_has_its_own_light() -> void:
	for room in ROOMS:
		if not ResourceLoader.exists(SCENE % room):
			pending("no %s (tools/build/make_rooms.gd)" % room)
			continue
		var n: Node3D = (load(SCENE % room) as PackedScene).instantiate()
		add_child_autofree(n)
		var r := n.get_node_or_null("Room")
		assert_not_null(r, "%s: its Room node" % room)
		assert_eq(n.get_child(0), r, "%s: the Room node first, so the Streamer adds it after the lights" % room)
		var lights := n.find_children("*", "OmniLight3D", true, false)
		assert_between(lights.size(), 1, 3, "%s: one to three lights (chapter 04, 8.6)" % room)
		for l in lights:
			assert_false((l as OmniLight3D).shadow_enabled, "%s: %s unshadowed" % [room, l.name])
			assert_eq((l as OmniLight3D).light_volumetric_fog_energy, 0.0, "%s: %s out of the valley's haze" % [room, l.name])
		assert_gt(float(r.get("gain")), 1.0, "%s: the eye opens up inside" % room)
		var box: AABB = r.get("box")
		assert_true(box.has_point(Vector3(0.0, 1.0, -1.0)), "%s: its box holds a point a metre in from the door" % room)
		assert_false(box.has_point(Vector3(0.0, 1.0, 1.0)), "%s: and not one a metre out in the yard" % room)
		assert_gt(n.find_children("*_COL*", "", true, false).size() + n.find_children("*", "CollisionShape3D", true, false).size(), 0,
				"%s: its furnishings stand in the way" % room)
