extends GutTest
## Dungkar Gönpa whole, step 5 (M3 sprint 3; tools/town/monastery.py spread's `stack`, STACK_REACH; ../tibet-blender
## kit/monastery.py monk_house `gallery`, its type monk_house_face): the west face as a cliff-dwelling: its monks'
## houses each with a timber gallery over the gorge, some stacked straight up the fall line so each roof is the next
## house's yard, on their pads' dry-stone fill walls (their podia, chapter 03's 2-6 m).

const Town := preload("res://world/town.gd")
const MONASTERY := "res://data/monastery.json"
const SIDE := "res://assets/generated/kit/types/%s.json"
const KIT := "res://assets/generated/kit/types/%s.glb"


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func _face() -> Array:
	return (_json(MONASTERY)["houses"] as Array).filter(func(h): return String(h["type"]) == "M1" and float(h["pos"][0]) < 500.0)


func test_the_face_houses_galleried() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var face := _face()
	assert_gt(face.size(), 54, "the M1 up the west face (chapter 02, D08: some 60)")
	for h in face:
		assert_true(String(h.get("kit", "")) in ["monk_house_face", "monk_house_face_in"], "%s galleried (H-MON-012 carved: M3 sprint 5, step 9)" % h["id"])
		assert_true(ResourceLoader.exists(KIT % Town.kit_file(h)), "%s's kit %s" % [h["id"], Town.kit_file(h)])
	if not FileAccess.file_exists(SIDE % "monk_house_face_v1"):
		return
	for v in range(1, 9):
		var a := _json(SIDE % ("monk_house_m1_v%d" % v))
		var b := _json(SIDE % ("monk_house_face_v%d" % v))
		assert_eq((b["socket_pos"] as Dictionary).keys(), (a["socket_pos"] as Dictionary).keys(), "v%d: the M1's own house, its sockets the same" % v)
		assert_eq(int(b["collision_hulls"]), int(a["collision_hulls"]) + 2, "v%d: its gallery's deck and rail walked on and leaned on" % v)


func test_stacked_up_the_fall_line() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var face := _face()
	var stacked := face.filter(func(h): return bool(h.get("stacked", false)))
	assert_gt(stacked.size(), 7, "some of the face's houses stacked (11 when built)")
	for h in stacked:
		var f := deg_to_rad(float(h["rot_deg"]))
		var front := Vector2(float(h["pos"][0]), float(h["pos"][1])) + Vector2(sin(f), cos(f)) * 3.0
		var under := {}
		for o in face:
			if int(o["row"]) != int(h["row"]) - 1:
				continue
			var fo := deg_to_rad(float(o["rot_deg"]))
			var back := Vector2(float(o["pos"][0]), float(o["pos"][1])) - Vector2(sin(fo), cos(fo)) * 3.0
			if back.distance_to(front) < 4.5:
				under = o
		assert_false(under.is_empty(), "%s: its front on the back of a house in the row below" % h["id"])
		if not under.is_empty():
			var rise := float(h["pos"][2]) - float(under["pos"][2])
			assert_between(rise, 3.5, 7.5, "%s: its floor about that one's roof (%.1f m up)" % [h["id"], rise])
