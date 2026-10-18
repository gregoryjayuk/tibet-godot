extends GutTest
## Tödé's leat TOD-10 (M3 sprint 4, step 4; tools/town/tode_leat.py; plan chapter 02, TOD-05 to TOD-10, R-12): along the
## contour at Tödé's top with the leat walk beside it, then down through the terraces through the upper mill, two water
## prayer wheel houses, the lower mill and the last wheel house, its water falling all the way, under the field paths in
## culverts, off the houses' pads; the machines at tools/town/tode.py's places, placed and turned by world/mills.gd.

const Town := preload("res://world/town.gd")
const LEAT := "res://data/tode_leat.json"
const TODE := "res://data/tode.json"


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func test_its_water_falls_along_it() -> void:
	if not FileAccess.file_exists(LEAT):
		pending("no data/tode_leat.json (tools/py tools/town/tode_leat.py)")
		return
	var tl := _json(LEAT)
	var st: Array = tl["leat"]
	var first: Array = st[0]["pts"]
	assert_almost_eq(float(first[0][2]), 2978.0, 0.05, "it comes into the quarter at Tödé's top (chapter 02: 2,978 m)")
	var L := 0.0
	for k in range(1, first.size()):
		L += Vector2(float(first[k][0]) - float(first[k - 1][0]), float(first[k][1]) - float(first[k - 1][1])).length()
	var grade := (float(first[0][2]) - float(first[first.size() - 1][2])) / maxf(L, 1.0)
	assert_between(grade, 0.005, 0.009, "along the contour at R-12's 0.7%")
	assert_gt(L, 100.0, "the contour stretch's length")
	for s in st:
		var pts: Array = s["pts"]
		for k in range(1, pts.size()):
			assert_true(float(pts[k][2]) <= float(pts[k - 1][2]) + 0.005, "%s's water never rises (point %d)" % [s["id"], k])
	assert_false((tl.get("walk", []) as Array).is_empty(), "the leat walk R-12 beside it")


func test_the_machines_where_tode_placed_them() -> void:
	if not FileAccess.file_exists(LEAT) or not FileAccess.file_exists(TODE):
		pending("no data")
		return
	var tl := _json(LEAT)
	var named: Dictionary = _json(TODE)["named"]
	var ids: Array = []
	for m in tl["mills"]:
		ids.append(String(m["id"]))
		var n: Dictionary = named[String(m["id"])]
		assert_lt(Vector2(float(m["at"][0]), float(m["at"][1])).distance_to(Vector2(float(n["at"][0]), float(n["at"][1]))), 0.05, "%s at its place" % m["id"])
		assert_almost_eq(float(m["head"][2]) - float(m["level"]), 1.8, 0.01, "%s's chute's head 1.8 m over its floor" % m["id"])
	for w in tl["wheels"]:
		ids.append(String(w["id"]))
		var n: Dictionary = named[String(w["id"])]
		assert_lt(Vector2(float(w["at"][0]), float(w["at"][1])).distance_to(Vector2(float(n["at"][0]), float(n["at"][1]))), 0.05, "%s at its place" % w["id"])
		assert_almost_eq(float(w["in"][2]) - float(w["out"][2]), 0.9, 0.01, "%s takes 0.9 m of fall" % w["id"])
	ids.sort()
	assert_eq(ids, ["TOD-05", "TOD-06", "TOD-07", "TOD-08", "TOD-09"], "two mills and three water prayer wheels (chapter 02)")
	for c in tl["culverts"]:
		assert_gt(float(c["road"]) - float(c["water"]), 0.4, "its water under %s's bed in a culvert" % c["path"])


func test_off_the_houses_pads() -> void:
	if not FileAccess.file_exists(LEAT) or not FileAccess.file_exists(TODE):
		pending("no data")
		return
	var st: Array = _json(LEAT)["leat"]
	var bad: Array = []
	for h in _json(TODE)["houses"]:
		var p: Array = h["pad"]
		var th := deg_to_rad(float(h["rot_deg"]))
		var u := Vector2(sin(th), cos(th))
		for s in st:
			var pts: Array = s["pts"]
			for k in range(2, pts.size() - 2):
				var r := Vector2(float(pts[k][0]) - float(p[0]), float(pts[k][1]) - float(p[1]))
				if absf(r.dot(u)) < float(p[3]) / 2.0 and absf(r.dot(Vector2(-u.y, u.x))) < float(p[2]) / 2.0:
					bad.append("%s over %s" % [s["id"], h["id"]])
					break
	assert_eq(bad.size(), 0, "no stretch over a house's pad%s" % ("" if bad.is_empty() else ": " + ", ".join(bad.slice(0, 4))))


func test_placed_and_turning() -> void:
	if not FileAccess.file_exists(LEAT):
		pending("no data/tode_leat.json")
		return
	var root := Node3D.new()
	add_child_autofree(root)
	Town.place(root, Rect2(Vector2(-20.0, 300.0), Vector2(140.0, 320.0)))
	for id in ["TOD-05", "TOD-06", "TOD-07", "TOD-08", "TOD-09"]:
		var h := root.get_node_or_null("Town/Mills/%s" % id) as Node3D
		assert_not_null(h, "%s placed (world/mills.gd)" % id)
		if h != null:
			assert_not_null(h.find_child("%s_turning" % id, true, false), "%s's turning part on its socket" % id)
	assert_not_null(root.find_child("TODE_LEAT_leat_tod10_1", true, false), "the contour stretch's channel (export_serchu.py)")
