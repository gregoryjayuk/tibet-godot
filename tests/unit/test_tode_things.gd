extends GutTest
## Tödé's fields' and yards' things (M3 sprint 4, step 5; tools/town/tode_things.py, tools/town/mani.py; plan chapter 02,
## TOD-11 to 14, 20, 22 to 25; chapter 03, 11.8): the threshing floors on their pads, the byres in rammed-earth yards clear
## of the gate's way in, the racks on house pads, the walnut grove off the pads and paths, the window stall by the
## forecourt facing it, the mani wall TOD-23 stepping up through Tödé's west edge; placed by world/town.gd.

const Town := preload("res://world/town.gd")
const THINGS := "res://data/tode_things.json"
const TODE := "res://data/tode.json"
const MANI := "res://assets/generated/terrain/mani_walls.json"


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func _on_pad(h: Dictionary, x: float, y: float, grow: float) -> bool:
	var p: Array = h["pad"]
	var th := deg_to_rad(float(h["rot_deg"]))
	var u := Vector2(sin(th), cos(th))
	var r := Vector2(x - float(p[0]), y - float(p[1]))
	return absf(r.dot(u)) < float(p[3]) / 2.0 + grow and absf(r.dot(Vector2(-u.y, u.x))) < float(p[2]) / 2.0 + grow


func test_the_floors_byres_and_racks() -> void:
	if not FileAccess.file_exists(THINGS) or not FileAccess.file_exists(TODE):
		pending("no data/tode_things.json (tools/py tools/town/tode_things.py)")
		return
	var td := _json(TODE)
	var houses := {}
	for h in td["houses"]:
		houses[String(h["id"])] = h
	var n_floor := 0
	var n_byre := 0
	for t in _json(THINGS)["things"]:
		var id := String(t["id"])
		if id in ["TOD-11", "TOD-12", "TOD-13", "TOD-14"]:
			n_floor += 1
			var n: Dictionary = td["named"][id]
			assert_almost_eq(float(t["level"]), float(n["level"]), 0.01, "%s on its pad" % id)
			assert_true(String(t["kit"]).begins_with("tod_threshing_floor_%d" % (14 if id in ["TOD-11", "TOD-12"] else 12)), "%s's size (chapter 02)" % id)
		elif id.begins_with("TOD-22."):
			n_byre += 1
			var h: Dictionary = houses[String(t["house"])]
			assert_eq(String(h["type"]), "D", "%s in a rammed-earth house's yard" % id)
			assert_true(_on_pad(h, float(t["at"][0]), float(t["at"][1]), -2.0), "%s within its house's pad" % id)
		elif id.begins_with("TOD-24."):
			var h: Dictionary = houses[String(t["house"])]
			assert_true(_on_pad(h, float(t["at"][0]), float(t["at"][1]), 0.0), "%s on its house's pad" % id)
	assert_eq(n_floor, 4, "the four threshing floors")
	assert_between(n_byre, 5, 20, "byres in some of the rammed-earth yards (chapter 02: \"some\")")


func test_the_walnut_grove_and_the_window_stall() -> void:
	if not FileAccess.file_exists(THINGS) or not FileAccess.file_exists(TODE):
		pending("no data")
		return
	var td := _json(TODE)
	var trees := 0
	var stall := {}
	for t in _json(THINGS)["things"]:
		var id := String(t["id"])
		if id.begins_with("TOD-20."):
			trees += 1
			for h in td["houses"]:
				assert_false(_on_pad(h, float(t["at"][0]), float(t["at"][1]), 1.0), "%s off %s's pad" % [id, h["id"]])
		elif id == "TOD-25":
			stall = t
	assert_between(trees, 15, 40, "the walnut grove's trees (60 by 40 m)")
	assert_false(stall.is_empty(), "the window stall TOD-25")
	if not stall.is_empty():
		assert_lt(Vector2(float(stall["at"][0]), float(stall["at"][1])).distance_to(Vector2(-10.0, 270.0)), 0.5, "at chapter 02's place by the Sky Stair's head")
		var to_fc := fposmod(rad_to_deg(atan2(-20.0 - float(stall["at"][0]), 258.0 - float(stall["at"][1]))), 360.0)
		assert_lt(absf(angle_difference(deg_to_rad(float(stall["facing"])), deg_to_rad(to_fc))), deg_to_rad(5.0), "its window to the forecourt")


func test_the_mani_wall_through_tode() -> void:
	if not FileAccess.file_exists(MANI):
		pending("no mani_walls.json (tools/py tools/town/mani.py)")
		return
	var wall: Dictionary = {}
	for w in _json(MANI)["walls"]:
		if String(w["id"]) == "TOD-23":
			wall = w
	assert_false(wall.is_empty(), "TOD-23 among the mani walls")
	if wall.is_empty():
		return
	var segs: Array = wall["segments"]
	var a := Vector2(float(segs[0][0]), float(segs[0][1]))
	var b := Vector2(float(segs[segs.size() - 1][0]), float(segs[segs.size() - 1][1]))
	assert_between(a.distance_to(b), 80.0, 92.0, "some 90 m (chapter 02)")
	assert_gt(float(segs[segs.size() - 1][2]), float(segs[0][2]), "stepping up through Tödé's west edge")
	if FileAccess.file_exists(TODE):
		for s in segs:
			for h in _json(TODE)["houses"]:
				assert_false(_on_pad(h, float(s[0]), float(s[1]), 1.0), "off %s's pad" % h["id"])


func test_placed() -> void:
	if not FileAccess.file_exists(THINGS):
		pending("no data")
		return
	var root := Node3D.new()
	add_child_autofree(root)
	Town.place(root, Rect2(Vector2(-380.0, 230.0), Vector2(650.0, 450.0)))
	for id in ["TOD-25", "TOD-11", "TOD-20.1"]:
		assert_not_null(root.get_node_or_null("Town/%s" % id.validate_node_name()), "%s placed (world/town.gd)" % id)  # (a node's name
		# keeps no dot: TOD-20_1)
