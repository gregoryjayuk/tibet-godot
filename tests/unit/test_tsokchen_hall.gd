extends GutTest
## The Tsokchen's hall carved and furnished (M3 sprint 5, steps 1-2; plan chapter 04, 3.1): the kit's type with the hall
## inside (tibet-blender kit/monastery.py tsokchen(interior=True), mon01_tsokchen_in) as MON-01's, its three rooms' scenes
## (tools/build/make_rooms.gd from kit/tsokchen_rooms.py) streamed at their ROOM sockets (world/interiors.gd), the lamp
## bank's some 250 flames drawn as one MultiMesh, at most six lights in the hall at the dawn assembly (chapter 04, 8.6);
## and the shafts' sun tables (tools/town/sun_table.py; step 4): the noon shaft through the south windows lit and landing on
## the central aisle three-quarters of the way up.

const Interiors := preload("res://world/interiors.gd")
const Town := preload("res://world/town.gd")
const SunShafts := preload("res://world/shafts.gd")
const SIDE := "res://assets/generated/kit/types/mon01_tsokchen_in_v1.json"
const TABLES := "res://data/sun_tables.json"


func _scene(room: String) -> Node3D:
	var path := Interiors.scene_path(room)
	if not ResourceLoader.exists(path):
		return null
	return (load(path) as PackedScene).instantiate() as Node3D


func test_the_hall_is_carved() -> void:
	assert_eq(Town.kit_file({"id": "MON-01"}), "mon01_tsokchen_in_v1", "MON-01 is the carved Tsokchen")
	if not FileAccess.file_exists(SIDE):
		pending("no mon01_tsokchen_in sidecar: the kit's export")
		return
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SIDE))
	var socks: Dictionary = side["socket_pos"]
	for s in ["SOCK_ROOM_1", "SOCK_ROOM_2", "SOCK_ROOM_3", "SOCK_DOOR_1", "SOCK_LADFOOT_1", "SOCK_LADTOP_1"]:
		assert_true(socks.has(s), "its %s" % s)
	var shafts := 0
	for s in socks:
		if String(s).begins_with("SOCK_SHAFT_"):
			shafts += 1
	assert_eq(shafts, 10, "its lantern's ten windows (two south, four east, four west)")
	assert_gt((side["rooms"] as Array).size(), 8, "the nave, the well, the gallery, the inner chapel, the Nangkor's arms, the doors")


func test_its_rooms_have_scenes() -> void:
	assert_eq(Interiors.ROOMS.get("MON-01", []), ["tsokchen_nave", "tsokchen_chapel", "tsokchen_gallery"], "in its ROOM sockets' order")
	for room in Interiors.ROOMS.get("MON-01", []):
		var sc := _scene(String(room))
		if sc == null:
			fail_test("no scene for %s: tools/build/make_rooms.gd" % room)
			continue
		assert_not_null(sc.get_node_or_null("Room"), "%s's Room node" % room)
		sc.free()


func test_the_lamp_bank_is_one_multimesh() -> void:
	var sc := _scene("tsokchen_nave")
	if sc == null:
		pending("no nave scene")
		return
	var mm := sc.get_node_or_null("Flames") as MultiMeshInstance3D
	assert_not_null(mm, "the lamp bank's flames as one MultiMesh")
	if mm != null:
		assert_gt(mm.multimesh.instance_count, 240, "some 250 lamps and the three cauldrons")
	var lights := 0
	for room in Interiors.ROOMS.get("MON-01", []):
		var r := _scene(String(room))
		if r == null:
			continue
		for c in r.get_children():
			if c is OmniLight3D or c is SpotLight3D:
				lights += 1
		r.free()
	assert_lte(lights, 6, "at most six dynamic lights in the hall (chapter 04, 8.6)")
	sc.free()


func test_the_noon_shaft_on_the_aisle() -> void:
	if not FileAccess.file_exists(TABLES):
		pending("no sun tables: tools/town/sun_table.py")
		return
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TABLES))
	var o: Dictionary = (d["openings"] as Dictionary).get("MON-01:SHAFT_1", {})
	assert_false(o.is_empty(), "the south-west lantern window's table")
	if o.is_empty():
		return
	var sh := SunShafts.new()
	sh._step = int(d["day_step"])
	sh._per = 1440.0 / float(d["samples"])
	var row := ["MON-01:SHAFT_1", null, null, Vector3.ZERO, Vector3.ZERO, 1.2, 1.6, o["lit"], o["reach"]]
	var noon := Calendar.minute_of(1903, 10, 28, 12, 0)
	var tv: Vector2 = sh.at_minute(row, noon)
	assert_gt(tv.x, 0.9, "its noon sun on 28 October")
	assert_eq(sh.at_minute(row, Calendar.minute_of(1903, 10, 28, 3, 0)).x, 0.0, "no sun at 03:00")
	# where the shaft ends: from the window's centre along the sun's way in, the table's reach, in the hall's frame
	var at: Array = o["at"]
	var s := Calendar.sun_direction(noon)  # (Godot: east +x, up +y, north -z)
	var end := Vector3(float(at[0]), float(at[1]), float(at[2])) - Vector3(s.x, -s.z, s.y) * tv.y
	var pad := Vector2(540.0, 150.0)  # MON-01's (its frame the town grid's, turned 180 degrees: data/monastery.json)
	assert_almost_eq(end.x - pad.x, 0.0, 1.6, "on the central aisle (x %.2f)" % (end.x - pad.x))
	var up := (end.y - pad.y + 15.3) / (6.575 + 15.3)
	assert_between(up, 0.65, 0.9, "three-quarters of the way from the door to the inner chapel (%.2f)" % up)
	assert_almost_eq(end.z, 2932.0, 0.5, "on the floor")
	sh.free()
