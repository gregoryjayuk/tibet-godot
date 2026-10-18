extends GutTest
## The Tödé tower TOD-01 (M3 sprint 4, step 3; chapter 03, 12.1; ../tibet-blender kit/tode.py star_tower): at
## tools/town/tode.py's place and level on its own pad, its door down the fall line 6 m over its foot, the notched log up to
## its sill outside and the eight inside from floor to floor through the hatches, a path to it from the Tödé Stair's
## terrace, and V-12 on its top: the monastery at eye level across the gorge, Shöl's roofs below.

const Town := preload("res://world/town.gd")
const TODE := "res://data/tode.json"
const VIEWS := "res://data/viewpoints.json"
const TOWER := "res://assets/generated/kit/types/tod01_tower_v1.glb"


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func _bearing(a: Vector2, b: Vector2) -> float:
	return fposmod(rad_to_deg(atan2(b.x - a.x, b.y - a.y)), 360.0)


func test_the_tower_and_its_logs() -> void:
	if not FileAccess.file_exists(TODE) or not ResourceLoader.exists(TOWER):
		pending("no data/tode.json or no tod01_tower (../tibet-blender export_types.py)")
		return
	var tw: Dictionary = _json(TODE)["named"]["TOD-01"]
	assert_true(tw.has("facing") and tw.has("pad"), "its door's bearing down the fall line, its pad (tools/town/tode.py)")
	var at := Vector2(float(tw["at"][0]), float(tw["at"][1]))
	var root := Node3D.new()
	add_child_autofree(root)
	Town.place(root, Rect2(at - Vector2(30.0, 30.0), Vector2(60.0, 60.0)))
	var t := root.get_node_or_null("Town/TOD-01") as Node3D
	assert_not_null(t, "TOD-01 placed (world/town.gd NAMED, tode_named)")
	if t == null:
		return
	var p := t.global_position
	assert_lt(Vector2(p.x, -p.z).distance_to(at), 0.05, "at its place")
	assert_almost_eq(p.y, Town.to_godot(at.x, at.y, float(tw["level"])).y, 0.05, "on its pad's level")
	var door := t.find_child("SOCK_DOOR_1", true, false) as Node3D
	assert_not_null(door, "its door")
	if door != null:
		var d := door.global_position
		assert_almost_eq(d.y - p.y, 6.0, 0.1, "its door 6 m over its foot (chapter 03, 12.1)")
		var b := _bearing(Vector2(p.x, -p.z), Vector2(d.x, -d.z))
		assert_lt(absf(angle_difference(deg_to_rad(b), deg_to_rad(float(tw["facing"])))), deg_to_rad(10.0), "its door down the fall line")
	for k in range(1, 10):
		var lg := root.get_node_or_null("Town/DOORLOG_TOD-01_%d" % k) as Node3D
		assert_not_null(lg, "its notched log %d hung (world/town.gd)" % k)
		if lg == null:
			continue
		var top := t.find_child("SOCK_LOGTOP_%d" % k, true, false) as Node3D
		assert_lt((lg.get_meta("parapet") as Vector3).distance_to(top.global_position), 0.05, "log %d up to its socket" % k)
		assert_eq(bool(lg.get_meta("indoors", false)), k < 9, "log %d %s" % [k, "inside, under the floors" if k < 9 else "outside, up to the door"])


func test_a_path_to_it() -> void:
	if not FileAccess.file_exists(TODE):
		pending("no data/tode.json")
		return
	var td := _json(TODE)
	var tw: Dictionary = td["named"]["TOD-01"]
	var w: Array = (td["ways"] as Dictionary).get("TOD-01", [])
	assert_false(w.is_empty(), "a way to the tower (tools/town/tode.py: its goal as a house's)")
	if w.is_empty():
		return
	var d := Vector2(float(w[0][0]), float(w[0][1])).distance_to(Vector2(float(tw["at"][0]), float(tw["at"][1])))
	assert_between(d, float(tw["pad"][2]) / 2.0, float(tw["pad"][2]) / 2.0 + 8.0, "to the side of its pad")
	if FileAccess.file_exists("res://data/tode_stair.json"):
		var top: Array = _json("res://data/tode_stair.json")["top"]
		var e: Array = w[w.size() - 1]
		assert_lt(Vector2(float(e[0]), float(e[1])).distance_to(Vector2(float(top[0]), float(top[1]))), 0.5, "from the Tödé Stair's top")


func test_v12_on_its_top() -> void:
	if not FileAccess.file_exists(TODE) or not FileAccess.file_exists(VIEWS):
		pending("no data")
		return
	var v12: Dictionary = {}
	for v in _json(VIEWS)["views"]:
		if String(v["id"]) == "V-12":
			v12 = v
	assert_false(v12.is_empty(), "V-12 among the viewpoints (world/viewpoints.gd)")
	if v12.is_empty():
		return
	var tw: Dictionary = _json(TODE)["named"]["TOD-01"]
	var seat := Vector3(float(v12["seat"][0]), float(v12["seat"][1]), float(v12["seat"][2]))
	assert_lt(Vector2(seat.x, seat.y).distance_to(Vector2(float(tw["at"][0]), float(tw["at"][1]))), 2.5, "on the tower")
	assert_almost_eq(seat.z - float(tw["level"]), 32.0, 0.2, "on its top, 32 m over its foot")
	var town: Dictionary = {}
	for b in _json("res://data/town.json")["buildings"]:
		town[String(b["id"])] = b
	var s := Vector2(seat.x, seat.y)
	var to_mon := _bearing(s, Vector2(float(town["MON-01"]["pos"][0]), float(town["MON-01"]["pos"][1])))
	var to_town := _bearing(s, Vector2(float(town["SHL-01"]["pos"][0]), float(town["SHL-01"]["pos"][1])))
	var half := float(v12["fov"]) / 2.0
	for pair in [["the Tsokchen across the gorge", to_mon], ["Tsongra below", to_town]]:
		var off := rad_to_deg(absf(angle_difference(deg_to_rad(float(v12["bearing"])), deg_to_rad(float(pair[1])))))
		assert_lt(off, half, "%s in its frame" % pair[0])
	var d_mon := s.distance_to(Vector2(float(town["MON-01"]["pos"][0]), float(town["MON-01"]["pos"][1])))
	var up := rad_to_deg(atan2(float(town["MON-01"]["pos"][2]) - seat.z - 1.5, d_mon))
	assert_between(up, -4.0, 4.0, "the monastery at eye level (M3's acceptance 4)")
