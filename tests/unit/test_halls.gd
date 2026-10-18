extends GutTest
## The monastery's other hero rooms (M3 sprint 5, steps 6-8; plan chapter 04, 3.2-3.5): the Jampa Lhakhang, the
## Gönkhang, the library and the Jakhang carved in their places (tibet-blender kit/monastery.py `interior=True`), their
## rooms' scenes streamed at their doors (world/interiors.gd), the Jampa Lhakhang's stair-ladder the kit's 5 m one, and
## V-30 (chapter 08): its lantern window's sun at noon on 5 November falling on Maitreya's face.

const Interiors := preload("res://world/interiors.gd")
const Town := preload("res://world/town.gd")
const SunShafts := preload("res://world/shafts.gd")
const SIDE := "res://assets/generated/kit/types/%s.json"
const TABLES := "res://data/sun_tables.json"


func test_the_halls_are_carved() -> void:
	for spec in [["MON-04", "mon04_maitreya_chapel_in_v1"], ["MON-05", "mon05_protector_chapel_in_v1"], ["MON-12", "mon12_kitchen_in_v1"],
			["MON-14", "mon14_library_in_v1"]]:
		assert_eq(Town.kit_file({"id": spec[0]}), spec[1], "%s carved" % spec[0])
		if FileAccess.file_exists(SIDE % spec[1]):
			var socks: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(SIDE % spec[1])) as Dictionary)["socket_pos"]
			assert_true(socks.has("SOCK_ROOM_1"), "%s's room at its door" % spec[0])


func test_their_rooms_have_scenes() -> void:
	for house in ["MON-04", "MON-05", "MON-12", "MON-14"]:
		var rooms: Array = Interiors.ROOMS.get(house, [])
		assert_false(rooms.is_empty(), "%s's rooms streamed" % house)
		for room in rooms:
			var path := Interiors.scene_path(String(room))
			if not ResourceLoader.exists(path):
				fail_test("no scene for %s: tools/build/make_rooms.gd" % room)
				continue
			var sc := (load(path) as PackedScene).instantiate()
			assert_not_null(sc.get_node_or_null("Room"), "%s's Room node" % room)
			var lights := 0
			for c in sc.get_children():
				if c is OmniLight3D:
					lights += 1
			assert_lte(lights, 3, "%s: at most three lights" % room)
			sc.free()


func test_the_jampa_ladder() -> void:
	var path := SIDE % "mon04_maitreya_chapel_in_v1"
	if not FileAccess.file_exists(path):
		pending("no mon04_maitreya_chapel_in sidecar")
		return
	var socks: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary)["socket_pos"]
	var f := Vector3(socks["SOCK_LADFOOT_1"][0], socks["SOCK_LADFOOT_1"][1], socks["SOCK_LADFOOT_1"][2])
	var t := Vector3(socks["SOCK_LADTOP_1"][0], socks["SOCK_LADTOP_1"][1], socks["SOCK_LADTOP_1"][2])
	assert_between(f.distance_to(t), 4.6, 5.0, "a 5 m stair-ladder (the kit's stair_ladder_50) from the floor to the gallery")
	var lean := rad_to_deg(atan2(t.z - f.z, Vector2(t.x - f.x, t.y - f.y).length()))
	assert_almost_eq(lean, 65.0, 1.5, "at 65 degrees (chapter 04, 3.2)")


func test_v30_on_the_face() -> void:
	if not FileAccess.file_exists(TABLES):
		pending("no sun tables: tools/town/sun_table.py")
		return
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TABLES))
	var o: Dictionary = (d["openings"] as Dictionary).get("MON-04:SHAFT_1", {})
	assert_false(o.is_empty(), "the Jampa Lhakhang's lantern window's table")
	if o.is_empty():
		return
	var sh := SunShafts.new()
	sh._step = int(d["day_step"])
	sh._per = 1440.0 / float(d["samples"])
	var row := ["MON-04:SHAFT_1", null, null, Vector3.ZERO, Vector3.ZERO, 1.2, 1.4, o["lit"], o["reach"]]
	var noon := Calendar.minute_of(1903, 11, 5, 11, 45)
	assert_gt(sh.at_minute(row, noon).x, 0.9, "its sun at 11:45 on 5 November (V-30's first day)")
	# its ray from the window's middle to the face's plane, 4.5 m north of the window's (kit/monastery.py J_FACE_Y)
	var at: Array = o["at"]
	var s := Calendar.sun_direction(noon)
	var st := Vector3(s.x, -s.z, s.y)  # (the town grid: x east, y north, z up)
	var k := (163.3 - float(at[1])) / -st.y  # (the face's plane at the hall's y 3.3: MON-04 at y 160)
	var hit := Vector3(float(at[0]), float(at[1]), float(at[2])) - st * k
	assert_almost_eq(hit.x - 585.0, 0.0, 0.5, "across the face (%.2f m)" % (hit.x - 585.0))
	assert_between(hit.z - 2945.0, 5.7, 6.9, "between the chin and the brow (%.2f m)" % (hit.z - 2945.0))
	sh.free()
