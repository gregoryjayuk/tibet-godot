extends GutTest
## The Parkhang carved (M3 sprint 5, step 8; plan chapter 04, 3.6): RNG-10 the kit's rng10_parkhang_in (tibet-blender
## kit/dungrong.py parkhang(interior=True)): its gate open, the stair hall off the arcade with its back door to the steps'
## side, the two stair-ladders (the kit's 4.5 m and 4 m, at 65 degrees) up to the printing room and the block store, the
## chapel; their rooms' scenes streamed at their ROOM sockets (world/interiors.gd), the block store's thousands of blocks
## casting no shadow (interiors/room.gd `shadows`).

const Interiors := preload("res://world/interiors.gd")
const Town := preload("res://world/town.gd")
const SIDE := "res://assets/generated/kit/types/%s.json"


func _socks(t: String) -> Dictionary:
	if not FileAccess.file_exists(SIDE % t):
		return {}
	return (JSON.parse_string(FileAccess.get_file_as_string(SIDE % t)) as Dictionary)["socket_pos"]


func test_it_is_carved() -> void:
	assert_eq(Town.kit_file({"id": "RNG-10"}), "rng10_parkhang_in_v1", "RNG-10 is the carved Parkhang")
	var socks := _socks("rng10_parkhang_in_v1")
	if socks.is_empty():
		pending("no rng10_parkhang_in sidecar: the kit's export")
		return
	for s in ["SOCK_ROOM_1", "SOCK_ROOM_2", "SOCK_ROOM_3", "SOCK_DOOR_1", "SOCK_LADFOOT_1", "SOCK_LADTOP_1", "SOCK_LADFOOT_2", "SOCK_LADTOP_2"]:
		assert_true(socks.has(s), "its %s" % s)


func test_its_rooms_have_scenes() -> void:
	assert_eq(Interiors.ROOMS.get("RNG-10", []), ["parkhang_printing", "parkhang_blocks", "parkhang_chapel"], "in its ROOM sockets' order")
	for room in Interiors.ROOMS.get("RNG-10", []):
		var path := Interiors.scene_path(String(room))
		if not ResourceLoader.exists(path):
			fail_test("no scene for %s: tools/build/make_rooms.gd" % room)
			continue
		var sc := (load(path) as PackedScene).instantiate()
		var rn := sc.get_node_or_null("Room")
		assert_not_null(rn, "%s's Room node" % room)
		if rn != null:
			assert_eq(bool(rn.get("shadows")), room != "parkhang_blocks", "%s's furnishings cast shadows unless the blocks'" % room)
		var lights := 0
		for c in sc.get_children():
			if c is OmniLight3D:
				lights += 1
		assert_lte(lights, 3, "%s: at most three lights" % room)
		sc.free()


func test_the_two_ladders() -> void:
	var socks := _socks("rng10_parkhang_in_v1")
	if socks.is_empty():
		pending("no rng10_parkhang_in sidecar")
		return
	for k in [[1, 4.5], [2, 4.0]]:
		var a: Array = socks["SOCK_LADFOOT_%d" % k[0]]
		var b: Array = socks["SOCK_LADTOP_%d" % k[0]]
		var f := Vector3(a[0], a[1], a[2])
		var t := Vector3(b[0], b[1], b[2])
		assert_between(f.distance_to(t), float(k[1]) - 0.5, float(k[1]), "ladder %d within the kit's %.1f m stair-ladder" % k)
		var lean := rad_to_deg(atan2(t.z - f.z, Vector2(t.x - f.x, t.y - f.y).length()))
		assert_almost_eq(lean, 65.0, 1.5, "ladder %d at 65 degrees" % k[0])
		assert_true(ResourceLoader.exists("res://assets/generated/kit/types/stair_ladder_%d_v1.glb" % int(k[1] * 10.0)), "the kit's stair_ladder_%d" % int(k[1] * 10.0))


func test_the_canyon() -> void:
	if not FileAccess.file_exists(SIDE % "parkhang_blocks_v1"):
		pending("no parkhang_blocks sidecar")
		return
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SIDE % "parkhang_blocks_v1"))
	assert_gt(int(side["triangles"]["L0"]), 200000, "some 10,000 blocks on edge, each its end and its handle (chapter 04, 3.6: about 9,000)")
	var b: Array = side["rooms"][0]
	assert_almost_eq(float(b[1]) - float(b[0]), 26.4, 0.1, "the block store 26 m long")
	assert_almost_eq(float(b[5]) - float(b[4]), 3.0, 0.25, "and some 3 m high")
	var socks: Dictionary = side["socket_pos"]
	assert_true(socks.has("SOCK_WINDOW_1"), "its one window at the far end")
