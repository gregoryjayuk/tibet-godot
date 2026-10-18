extends GutTest
## The poor family's one room on the west edge, H-SHL-142 (ISS-105; plan chapter 04, 4.2; ../tibet-blender
## kit/houses.py poor_house(interior=True), kit/rooms.py house_room): the house to enter is that one, its outside as the
## other poor houses'; its doorway open to the room with its lintel at 1.6 m, the room's floor, walls and ceiling where
## its sidecar says; the hearth under the smoke hole, the log beside it with the guest's place and bowl; its scene's
## three lights, the shaft of day under the hole, the lamp lit at dusk, and the guest's tea, thin; and the player ducks
## under a lintel that low (chapter 04, 10: "at 1.70 m or less the player ducks automatically").

const Town := preload("res://world/town.gd")
const Interiors := preload("res://world/interiors.gd")
const PlayerScript := preload("res://player/player.gd")
const VARIANTS := 3


static func godot(p: Array) -> Vector3:
	return Vector3(float(p[0]), float(p[2]), -float(p[1]))  # the kit's frame (x, y, z up) -> Godot's (x, z, -y)


func _ray(house: Node3D, from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(house.global_transform * from, house.global_transform * to)
	return house.get_world_3d().direct_space_state.intersect_ray(q)


func test_the_house_to_enter_is_h_shl_142() -> void:
	var town: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/town_generic.json"))
	var found := 0
	for h in town["houses"]:
		if String(h["type"]) != "E" or String(h.get("quarter", "")) != "shol.nub":
			continue
		var f := Town.kit_file(h)
		if String(h["id"]) == "H-SHL-142":
			found += 1
			assert_eq(f, "poor_house_e1_in_v%d" % int(h["seed"]), "H-SHL-142: its room carved")
			assert_eq(Interiors.ROOMS["H-SHL-142"], ["house_room_e1_in_v%d" % int(h["seed"])], "and its room's things the same variant's")
		else:
			assert_false(f.contains("_in_"), "%s: shut, its outside as the kit draws it" % h["id"])
	assert_eq(found, 1, "H-SHL-142 among the west edge's houses")


func test_the_poor_house_opens_onto_its_room() -> void:
	for v in range(1, VARIANTS + 1):
		var t := "poor_house_e1_in_v%d" % v
		var path := "res://assets/generated/kit/types/%s.glb" % t
		if not ResourceLoader.exists(path):
			fail_test("%s not built" % t)
			continue
		var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path.get_basename() + ".json"))
		var out: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/kit/types/poor_house_e1_v%d.json" % v))
		for s in out["socket_pos"]:  # its outside the other poor houses' (the room carved after every draw)
			assert_eq(side["socket_pos"].get(s), out["socket_pos"][s], "%s: %s as poor_house_e1_v%d's" % [t, s, v])
		assert_eq((side["ground"] as Array).size(), 0, "%s: its walls are not things on the ground" % t)
		var house: Node3D = (load(path) as PackedScene).instantiate()
		add_child_autofree(house)
		house.position = Vector3(60.0 * v, -100.0, 0.0)
		await wait_physics_frames(2)
		var r: Array = side["rooms"][0]
		var door: Vector3 = godot(side["socket_pos"]["SOCK_DOOR_1"])
		var mid := godot([(float(r[0]) + float(r[1])) / 2.0, (float(r[2]) + float(r[3])) / 2.0, float(r[4])])
		var from := door + Vector3(0.0, 1.0, 1.0)  # through the doorway at the chest: well into the room
		var hit := _ray(house, from, from + Vector3(0.0, 0.0, -12.0))
		var went := 12.0 if hit.is_empty() else (house.global_transform.affine_inverse() * (hit["position"] as Vector3)).distance_to(from)
		assert_gt(went, 3.0, "%s: its doorway open to the room" % t)
		from = door + Vector3(0.0, 1.66, 1.0)  # at the head: its lintel
		hit = _ray(house, from, from + Vector3(0.0, 0.0, -3.0))
		assert_false(hit.is_empty(), "%s: a lintel at 1.6 m, ducked under" % t)
		var f := _ray(house, mid + Vector3(0.0, 1.0, 0.0), mid - Vector3(0.0, 1.0, 0.0))
		assert_false(f.is_empty(), "%s: a floor in the room" % t)
		if not f.is_empty():
			assert_almost_eq((house.global_transform.affine_inverse() * (f["position"] as Vector3)).y, float(r[4]), 0.03, "%s: at its height" % t)
		var w := _ray(house, mid + Vector3(0.0, 1.2, 0.0), mid + Vector3(8.0, 1.2, 0.0))
		assert_false(w.is_empty(), "%s: its side wall" % t)
		if not w.is_empty():
			assert_almost_eq((house.global_transform.affine_inverse() * (w["position"] as Vector3)).x, float(r[1]), 0.1, "%s: where the room ends" % t)
		var c := _ray(house, mid + Vector3(0.0, 1.0, 0.0), mid + Vector3(0.0, 4.0, 0.0))
		assert_false(c.is_empty(), "%s: its ceiling" % t)
		if not c.is_empty():
			assert_almost_eq((house.global_transform.affine_inverse() * (c["position"] as Vector3)).y, float(r[5]), 0.1, "%s: its height" % t)
		var leaves: Array = side["leaves"]
		assert_eq(leaves.size(), 1, "%s: one leaf" % t)
		if not leaves.is_empty():
			assert_eq(String(leaves[0][7]), "door_leaf_raw", "%s: of raw planks" % t)


func test_the_room_has_its_few_things() -> void:
	for v in range(1, VARIANTS + 1):
		var t := "house_room_e1_in_v%d" % v
		var path := "res://assets/generated/kit/types/%s.glb" % t
		if not ResourceLoader.exists(path):
			fail_test("%s not built" % t)
			continue
		var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path.get_basename() + ".json"))
		var r: Array = side["rooms"][0]
		var room := AABB(Vector3(float(r[0]), -0.25, -float(r[3])), Vector3(float(r[1]) - float(r[0]), float(r[5]) + 0.25, float(r[3])))
		var k: Node3D = (load(path) as PackedScene).instantiate()
		add_child_autofree(k)
		for m in k.find_children("*_L0", "MeshInstance3D", true, false):
			var box := (m as MeshInstance3D).transform * (m as MeshInstance3D).get_aabb()
			assert_true(room.grow(0.05).encloses(box), "%s: its things inside the room (%s in %s)" % [t, box, room])
		var s: Dictionary = side["socket_pos"]
		for want in ["SOCK_FIRE_1", "SOCK_SMOKEHOLE_1", "SOCK_SEAT_1", "SOCK_BOWL_1", "SOCK_FLAME_1"]:
			assert_true(s.has(want), "%s: %s" % [t, want])
		if not (s.has("SOCK_FIRE_1") and s.has("SOCK_SMOKEHOLE_1") and s.has("SOCK_SEAT_1") and s.has("SOCK_BOWL_1")):
			continue
		var fire := godot(s["SOCK_FIRE_1"])
		var hole := godot(s["SOCK_SMOKEHOLE_1"])
		assert_almost_eq(Vector2(fire.x - hole.x, fire.z - hole.z).length(), 0.0, 0.01, "%s: the hearth under the smoke hole" % t)
		assert_almost_eq(hole.y, float(r[5]), 0.01, "%s: the hole in its ceiling" % t)
		var seat := godot(s["SOCK_SEAT_1"])  # the guest's hips, cross-legged on the sheepskin behind the log (ISS-088)
		var bowl := godot(s["SOCK_BOWL_1"])
		assert_almost_eq(seat.y, 0.0, 0.01, "%s: the guest on the floor" % t)
		var d := Vector2(seat.x - fire.x, seat.z - fire.z).length()
		assert_between(d, 1.0, 1.6, "%s: the guest's place behind the log, the fire before it" % t)
		var yaw := deg_to_rad(float(side["socket_yaw"]["SOCK_SEAT_1"]))  # the way the sitter faces (the kit's +y), from +x
		var faces := Vector2(cos(yaw), -sin(yaw))  # in Godot's x, z
		assert_gt(faces.dot(Vector2(fire.x - seat.x, fire.z - seat.z).normalized()), 0.8, "%s: facing the fire" % t)
		assert_between(Vector2(bowl.x - seat.x, bowl.z - seat.z).length(), 0.4, 0.75, "%s: the cup on the log before the guest" % t)
		assert_almost_eq(bowl.y, 0.24, 0.01, "%s: on the log" % t)
		assert_true(s.has("SOCK_HOST_1"), "%s: where the host stands to pour" % t)
		if s.has("SOCK_HOST_1"):
			var host := godot(s["SOCK_HOST_1"])
			assert_between(Vector2(host.x - bowl.x, host.z - bowl.z).length(), 0.4, 0.7, "%s: within her arm's reach of the bowl" % t)
			assert_gt(Vector2(host.x - fire.x, host.z - fire.z).length(), 0.6, "%s: off the hearth" % t)
			var hy := deg_to_rad(float(side["socket_yaw"]["SOCK_HOST_1"]))
			assert_gt(Vector2(cos(hy), -sin(hy)).dot(Vector2(bowl.x - host.x, bowl.z - host.z).normalized()), 0.9, "%s: facing the bowl" % t)


func test_its_scene_is_lit_as_a_poor_room() -> void:
	for v in range(1, VARIANTS + 1):
		var t := "house_room_e1_in_v%d" % v
		var room: Node3D = (load("res://interiors/houses/%s.tscn" % t) as PackedScene).instantiate()
		add_child_autofree(room)
		assert_eq(room.find_children("*", "OmniLight3D", true, false).size(), 3, "%s: three lights, the fire, the hole's day and the door's" % t)
		var shaft := room.find_child("Shaft", true, false)
		assert_true(shaft != null and shaft.has_meta("shaft"), "%s: the shaft of day under the hole" % t)
		var dusk := room.find_children("Flame_*", "MeshInstance3D", true, false).filter(func(n: Node) -> bool: return n.has_meta("dusk"))
		assert_eq(dusk.size(), 1, "%s: its one lamp, lit at dusk" % t)
		var tea := room.find_child("Tea", true, false) as Node3D
		assert_not_null(tea, "%s: the guest's tea" % t)
		if tea != null:
			assert_true(bool(tea.get_meta("thin", false)), "%s: thin, little butter" % t)
			assert_almost_eq(float(tea.get_meta("r", 0.0)), 0.06, 0.001, "%s: in a plain bowl" % t)
			assert_eq(String(tea.get_meta("vessel", "")), "ladle", "%s: poured from the copper ladle" % t)
			assert_true(tea.has_meta("host"), "%s: from the log's end" % t)
		assert_eq(String((room.get_node("Room") as Node).get("recipe")), "LR-04", "%s: LR-04, its hearth heard" % t)


func test_the_player_ducks_under_a_low_lintel() -> void:
	var player: CharacterBody3D = PlayerScript.new()
	player.third_person = true
	add_child_autofree(player)
	player.global_position = Vector3(0.0, 0.05, 0.0)
	_box(Vector3(8.0, 0.2, 14.0), Vector3(0.0, -0.1, -4.0))  # the ground
	_box(Vector3(2.0, 2.4, 0.6), Vector3(-1.4, 1.2, -3.0))  # the wall either side of a doorway 0.8 wide
	_box(Vector3(2.0, 2.4, 0.6), Vector3(1.4, 1.2, -3.0))
	_box(Vector3(0.8, 0.8, 0.6), Vector3(0.0, 2.0, -3.0))  # its lintel's underside at 1.6 m
	await wait_physics_frames(6)
	player.scripted = true
	player.yaw = 0.0  # facing -Z, through the doorway
	player.scripted_move = Vector3(0.0, 0.0, -1.0)
	var ducked := false
	var under := false
	for i in 300:
		await wait_physics_frames(1)
		ducked = ducked or bool(player.get("ducking"))
		if absf(player.global_position.z + 3.0) < 0.2:
			under = under or bool(player.get("ducking"))
		if player.global_position.z < -5.0:
			break
	player.scripted_move = Vector3.ZERO
	assert_true(under, "ducked under the lintel")
	assert_lt(player.global_position.z, -5.0, "and through the doorway")
	await wait_physics_frames(10)
	assert_false(bool(player.get("ducking")), "and up again past it")


func _box(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	b.add_child(cs)
	add_child_autofree(b)
	b.global_position = at


func test_the_grandmother_is_at_home() -> void:  # but for her dusk lingkor (M2 sprint 6, step 2)
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/terrain/street_graph.json"))
	assert_true((g["anchors"] as Dictionary).has("H-SHL-142"), "her door's outside an anchor, on the walkers' ground since M2 sprint 6")
	var found := false
	for w in g["walkers"]:
		if String(w.get("who", "")) != "poor_grandmother":
			continue
		found = true
		var seats := 0
		var out := []
		for st in w["day"]:
			if String(st[0]) != "H-SHL-142":
				out.append(String(st[0]))
			elif st.size() > 5 and st[5] is Dictionary:
				seats += 1
				assert_true(String((st[5] as Dictionary)["name"]).begins_with("room:house_room_e1_in_v2"), "in its room")
		assert_eq(out, ["west_mani"], "out of her house only for the lingkor's west side at dusk (chapter 04, 4.2; M2 sprint 6)")
		assert_eq(seats, 2, "by the door spinning, by the fire at dusk")
		assert_true(w["day"].any(func(st: Array) -> bool: return st.size() > 5 and st[5] is Dictionary and String((st[5] as Dictionary)["pose"]) == "cross"), "cross-legged by the fire")
	assert_true(found, "the poor grandmother among the walkers")


func test_the_player_sits_cross_legged_in_a_tibetan_room() -> void:
	var player: CharacterBody3D = PlayerScript.new()
	player.third_person = true
	add_child_autofree(player)
	var rooms := Node.new()  # a stand-in for world/interiors.gd: the player is in a Tibetan room
	var src := GDScript.new()
	src.source_code = "extends Node\nvar room_id := \"house_kitchen_b2_in_v1\"\nfunc room_at(_p: Vector3) -> Node:\n\treturn self\n"
	src.reload()
	rooms.set_script(src)
	add_child_autofree(rooms)
	rooms.add_to_group("interiors")
	_box(Vector3(8.0, 0.2, 8.0), Vector3(0.0, -0.1, 0.0))  # the floor
	_box(Vector3(2.0, 0.4, 0.7), Vector3(0.0, 0.2, 0.55))  # a bench 0.4 high, its front edge 0.2 m behind the player
	player.global_position = Vector3(0.0, 0.05, 0.0)
	await wait_physics_frames(10)
	player.facing = 0.0  # facing -Z, the bench at its back (+Z)
	player.sit()
	assert_eq(String(player.get("rest_kind")), "cross", "cross-legged, as in a Tibetan room")
	var at: Vector3 = player.get("_cross_at")
	assert_almost_eq(at.y - player.global_position.y, 0.4, 0.05, "on the bench")
	assert_almost_eq(at.z, 0.2, 0.06, "its root at the bench's front edge, the hips 0.4 m in")
	for i in 60:
		await wait_physics_frames(1)
	var body: Node3D = player.get("body")
	if body != null:
		assert_almost_eq(body.global_position.z, 0.2, 0.06, "the body there once sat")


func test_the_townspeople_sit_cross_legged() -> void:
	assert_eq(TownSim._state("cross", {"pose": "cross"}), 6, "a cross-legged stop: state 6")
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/people/named_clips.json"))
	for k in ["house_grandmother", "house_mother", "house_man", "ngodrup_dedpon", "poor_grandmother"]:
		assert_true((info["bodies"][k] as Dictionary).has("Sitting_Cross"), "%s: the cross-legged clip" % k)
