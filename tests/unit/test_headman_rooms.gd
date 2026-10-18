extends GutTest
## The headman's house's rooms furnished and lit (M2 sprint 7, steps 2-3; plan chapter 04, 4.1): a scene for each of the
## house's eleven rooms (tools/build/make_rooms.gd from tibet-blender kit/headman_rooms.py), streamed in at its ROOM
## socket (world/interiors.gd); at most three lights on a floor and, the floors' bands not meeting, never two floors lit
## at once (chapter 04: "Dynamic lights 5 across the house, at most 3 on one floor"); the kitchen's stove and smoke-hole,
## the shrine's lamps, the reception's guest bowl.

const Interiors := preload("res://world/interiors.gd")
const SIDE := "res://assets/generated/kit/types/headman_house_v1.json"


func _scene(room: String) -> Node3D:
	var path := Interiors.scene_path(room)
	if not ResourceLoader.exists(path):
		return null
	return (load(path) as PackedScene).instantiate() as Node3D


func test_every_room_has_its_scene() -> void:
	var rooms: Array = Interiors.ROOMS.get("SHL-19", [])
	assert_eq(rooms.size(), 11, "the house's eleven rooms in its ROOM sockets' order")
	for room in rooms:
		var sc := _scene(String(room))
		if sc == null:
			fail_test("no scene for %s: tools/build/make_rooms.gd" % room)
			continue
		var r := sc.get_node_or_null("Room")
		assert_not_null(r, "%s's Room node" % room)
		if r != null:
			assert_gt((r.get("box") as AABB).size.x, 1.0, "%s's box" % room)
		sc.free()


func test_never_two_floors_lit() -> void:
	if not FileAccess.file_exists(SIDE):
		pending("no headman_house sidecar")
		return
	var socks: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(SIDE)) as Dictionary)["socket_pos"]
	var rooms: Array = Interiors.ROOMS["SHL-19"]
	var spans: Array = []  # [the camera's lowest and highest height in the house's frame, the room's lights]
	for k in rooms.size():
		var sc := _scene(String(rooms[k]))
		if sc == null:
			continue
		var n := 0
		for c in sc.get_children():
			if c is OmniLight3D:
				n += 1
		var band: Vector2 = sc.get_node("Room").get("floor_band")
		var floor_z := float(socks["SOCK_ROOM_%d" % (k + 1)][2])
		spans.append([floor_z + band.x, floor_z + band.y, n])
		sc.free()
	var worst := 0
	for i in 140:
		var z := -1.0 + i * 0.1
		var lit := 0
		for sp in spans:
			if z >= float(sp[0]) and z <= float(sp[1]):
				lit += int(sp[2])
		worst = maxi(worst, lit)
	assert_between(worst, 1, 3, "at most three lights at any height of the camera (chapter 04: three a floor, five a house)")


func test_the_kitchen_the_shrine_the_reception() -> void:
	var k := _scene("headman_kitchen")
	if k == null:
		pending("no kitchen scene")
		return
	assert_not_null(k.get_node_or_null("Fire_fire_1"), "the stove's fire lit (LR-04)")
	assert_not_null(k.find_child("Shaft", false, false), "the smoke-hole's shaft of day")
	assert_eq(String(k.get_node("Room").get("recipe")), "LR-04")
	k.free()
	var s := _scene("headman_shrine")
	assert_not_null(s.get_node_or_null("Flame_flame_1"), "the butter lamps' light (LR-02)")
	s.free()
	var r := _scene("headman_reception")
	assert_not_null(r.find_child("SOCK_BOWL_1", true, false), "the guest's bowl on the lower bench's table")
	assert_eq(String(r.get_node("Room").get("recipe")), "LR-09T")
	r.free()
