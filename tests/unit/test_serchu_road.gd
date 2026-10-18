extends GutTest
## The Serchu road's last kilometre (M2 sprint 12, step 1; plan chapter 02, D09, R-01, SER-04, SER-20): R-01 from the
## Serchu Zampa's south abutment down the river's south bank past the road chorten SER-20 to the cliff gallery's east end
## (tools/terrain/serchu_road.py), its bed falling evenly, its lanes joined end to end, above the water and clear of its
## channel all the way.

const DATA := "res://data/serchu_road.json"
const RIVERS := "res://data/rivers.json"


func _d() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))


func test_its_ends_and_its_fall() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no data/serchu_road.json (tools/py tools/terrain/serchu_road.py)")
		return
	var d := _d()
	var path: Array = d["path"]
	var z: Dictionary = d["zampa"]
	assert_almost_eq(Vector2(float(path[0][0]), float(path[0][1])).distance_to(Vector2(float(z["south"][0]), float(z["south"][1]))), 0.0, 2.0, "it starts at the Zampa's south abutment")
	assert_almost_eq(float(path[0][2]), 2812.0, 0.05, "at the Zampa's deck (chapter 02: 2,812 m)")
	var last: Array = path[path.size() - 1]
	assert_almost_eq(Vector3(float(last[0]), float(last[1]), float(last[2])).distance_to(Vector3(420.0, -245.0, 2712.0)), 0.0, 0.05, "it ends at the cliff gallery's east end, where the arrival's road goes on (data/arrival.json)")
	var chorten := Vector2(430.0, -250.0)  # SER-20, 3 x 3: passed on its south side, never walked through
	for k in range(1, path.size()):
		var a := Vector2(float(path[k - 1][0]), float(path[k - 1][1]))
		var b := Vector2(float(path[k][0]), float(path[k][1]))
		var q := Geometry2D.get_closest_point_to_segment(chorten, a, b)
		assert_gt(q.distance_to(chorten), 3.4, "the road chorten SER-20 clear of the bed (%d)" % k)
		if q.distance_to(chorten) < 8.0:
			assert_lt(q.y, chorten.y, "and passed on its south side, on the right going down (%d)" % k)
	assert_between(float(d["length"]), 820.0, 960.0, "the last kilometre")
	assert_lt(float(d["grade"]), 0.13, "an even fall a laden yak takes")
	assert_between(float(z["at"][2]) - float(z["water"]), 6.0, 8.0, "the deck 7 m over the water")
	for k in range(1, path.size()):
		assert_lt(float(path[k][2]), float(path[k - 1][2]) + 0.01, "falling all the way (%d)" % k)


func test_its_lanes_join() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no data/serchu_road.json")
		return
	var lanes: Array = _d()["lanes"]
	assert_gt(lanes.size(), 10, "a road that bends with the bank")
	for k in lanes.size():
		var ln: Dictionary = lanes[k]
		assert_true(bool(ln["road"]), "%s a road lane (pads.py carves it with its walls' step)" % ln["id"])
		var L := float(ln["length"]) - 1.0
		assert_lt(absf(float(ln["z_b"]) - float(ln["z_a"])) / L, 0.15, "%s no steeper than 15%%" % ln["id"])
		if k > 0 and String(ln["id"]).get_slice(".", 0) == String(lanes[k - 1]["id"]).get_slice(".", 0) and not String(ln["id"]).ends_with(".L"):
			# (each of its two roads' lanes from the bridge outwards: R-01S down the south bank, R-01N up the north; the
			# north's landing where it turns out of the gateway chorten, R-01N.L, stands alone)
			var a: Dictionary = lanes[k - 1]
			var end := Vector2(float(a["from"][0]), float(a["from"][1])) + Vector2(float(a["dir"][0]), float(a["dir"][1])) * (float(a["length"]) - 1.0)
			assert_almost_eq(end.distance_to(Vector2(float(ln["from"][0]), float(ln["from"][1]))), 0.0, 0.05, "%s starts where %s ends" % [ln["id"], a["id"]])
			assert_almost_eq(float(ln["z_a"]), float(a["z_b"]), 0.01, "%s at %s's level" % [ln["id"], a["id"]])
			var turn := absf(rad_to_deg(Vector2(float(a["dir"][0]), float(a["dir"][1])).angle_to(Vector2(float(ln["dir"][0]), float(ln["dir"][1])))))
			var last := k == lanes.size() - 1 or String(lanes[k + 1]["id"]).get_slice(".", 0) != String(ln["id"]).get_slice(".", 0)
			var first_turn := String(a["id"]) == "R-01N.1"  # out of the chorten up the bank, on the landing
			assert_lt(turn, 90.0 if first_turn else (55.0 if last else 35.0), "%s bends gently from %s (past SER-20 onto the gallery, out of the chorten on the landing)" % [ln["id"], a["id"]])


func test_above_the_water_and_off_its_channel() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no data/serchu_road.json")
		return
	var serchu: Array = (JSON.parse_string(FileAccess.get_file_as_string(RIVERS))["rivers"] as Array).filter(func(r): return String(r["name"]) == "Serchu")[0]["pts"]
	var path: Array = _d()["path"]
	for k in range(1, path.size() - 1):  # (its ends: the Zampa's abutment over the bank, SER-20 at the gallery)
		var p := Vector2(float(path[k][0]), float(path[k][1]))
		var near: Array = serchu.reduce(func(a, q): return q if p.distance_to(Vector2(float(q[0]), float(q[1]))) < p.distance_to(Vector2(float(a[0]), float(a[1]))) else a)
		assert_gt(p.distance_to(Vector2(float(near[0]), float(near[1]))), 9.0, "the road's line %d clear of the channel" % k)
		assert_gt(float(path[k][2]) - float(near[2]), 5.0, "and well over the water (%d)" % k)


func test_the_zampa_its_chorten_and_the_rest() -> void:  # M2 sprint 12, step 2
	if not FileAccess.file_exists(DATA):
		pending("no data/serchu_road.json")
		return
	var d := _d()
	var pl: Dictionary = d["places"]
	var z: Dictionary = d["zampa"]
	assert_eq(Vector2(float(pl["SER-04"]["at"][0]), float(pl["SER-04"]["at"][1])), Vector2(1250.0, -520.0), "the Zampa at chapter 02's SER-04")
	var mid := Vector2(1250.0, -520.0)
	var north := Vector2(float(z["north"][0]), float(z["north"][1]))
	var ch := Vector2(float(pl["SER-04C"]["at"][0]), float(pl["SER-04C"]["at"][1]))
	assert_almost_eq((ch - mid).normalized().dot((north - mid).normalized()), 1.0, 0.01, "its gateway chorten on the bridge's axis, at the north end")
	assert_between(ch.distance_to(mid), 9.0 + 2.6, 9.0 + 2.6 + 4.6, "past the deck's end, on the abutment")
	var np_: Array = d["north_path"]
	assert_almost_eq(Vector2(float(np_[0][0]), float(np_[0][1])).distance_to(north), 0.0, 0.05, "the north bank's road from the Zampa's north face")
	for k in range(1, np_.size()):
		assert_gt(float(np_[k][2]), float(np_[k - 1][2]) - 0.01, "rising or level up the river (%d)" % k)
	var rest: Dictionary = d["pads"]["SER-19"]
	var path: Array = d["path"]
	var r := Vector2(float(rest["at"][0]), float(rest["at"][1]))
	var nearest := INF
	var level := 0.0
	for k in range(1, path.size()):
		var a := Vector2(float(path[k - 1][0]), float(path[k - 1][1]))
		var b := Vector2(float(path[k][0]), float(path[k][1]))
		var q := Geometry2D.get_closest_point_to_segment(r, a, b)
		if q.distance_to(r) < nearest:
			nearest = q.distance_to(r)
			level = lerpf(float(path[k - 1][2]), float(path[k][2]), a.distance_to(q) / maxf(a.distance_to(b), 0.001))  # the road's level beside it
	assert_between(nearest, 4.0, 5.0, "the porters' rest beside the road, open to it")
	assert_almost_eq(float(rest["level"]), level, 1.0, "at the road's level (the gazetteer's place lay 4 m under it)")
	for f in ["ser04_zampa_v1", "ser04_gate_chorten_v1", "ser19_porters_rest_v1"]:
		assert_true(FileAccess.file_exists("res://assets/generated/kit/types/%s.json" % f), "the kit's %s (../tibet-blender export_types.py)" % f)


func test_along_the_road() -> void:  # M2 sprint 12, step 3: the mani wall, the cairn, the gold washings
	if not FileAccess.file_exists(DATA):
		pending("no data/serchu_road.json")
		return
	var d := _d()
	var path: Array = d["line"]  # (the road's own middle: its `path` is the way walked, past the wall by its south side)
	var on_road := func(x: float, y: float) -> float:  # the distance from the road's line
		var best := INF
		for k in range(1, path.size()):
			var q := Geometry2D.get_closest_point_to_segment(Vector2(x, y), Vector2(float(path[k - 1][0]), float(path[k - 1][1])), Vector2(float(path[k][0]), float(path[k][1])))
			best = minf(best, q.distance_to(Vector2(x, y)))
		return best
	var wall: Array = d["mani_wall"]["line"]
	assert_gt(Vector2(float(wall[0][0]), float(wall[0][1])).distance_to(Vector2(float(wall[wall.size() - 1][0]), float(wall[wall.size() - 1][1]))), 80.0, "SER-15 about chapter 02's 90 m")
	for q in wall:
		assert_lt(float(on_road.call(float(q[0]), float(q[1]))), 0.6, "the wall down the road's middle")
	var wide: Array = (d["lanes"] as Array).filter(func(ln): return ln.get("mani", false))
	assert_gt(wide.size(), 0, "the road widened round the wall")
	for ln in wide:
		assert_almost_eq(float(ln["width"]), 8.5, 0.01, "%s room either side of the wall" % ln["id"])
	var mw := "res://assets/generated/terrain/mani_walls.json"
	if FileAccess.file_exists(mw):
		var ser: Array = (JSON.parse_string(FileAccess.get_file_as_string(mw))["walls"] as Array).filter(func(w): return String(w["id"]) == "SER-15")
		assert_eq(ser.size(), 1, "tools/town/mani.py sets its segments")
	var cairn: Dictionary = d["places"]["SER-14"]
	assert_between(float(on_road.call(float(cairn["at"][0]), float(cairn["at"][1]))), 2.5, 4.5, "the cairn beside the road, on its edge")
	assert_gt(((d["paths"] as Array)[0] as Array).size(), 4, "the durtro path up from it")
	var serchu: Array = (JSON.parse_string(FileAccess.get_file_as_string(RIVERS))["rivers"] as Array).filter(func(r): return String(r["name"]) == "Serchu")[0]["pts"]
	var huts := 0
	for th in d["things"]:
		var p := Vector2(float(th["at"][0]), float(th["at"][1]))
		var near: Array = serchu.reduce(func(a, q): return q if p.distance_to(Vector2(float(q[0]), float(q[1]))) < p.distance_to(Vector2(float(a[0]), float(a[1]))) else a)
		var off := p.distance_to(Vector2(float(near[0]), float(near[1])))
		if String(th["kit"]) == "ser12_hut_v1":
			huts += 1
			assert_gt(off, float(near[3]) + 2.0, "%s back from the water's edge" % th["id"])
			assert_gt(float(on_road.call(p.x, p.y)), 10.0, "%s down on the bank, off the road" % th["id"])
			assert_gt(float(th["level"]) - float(near[2]), 0.5, "%s above the water" % th["id"])
		else:
			assert_almost_eq(off, float(near[3]), 1.2, "%s at the water's edge" % th["id"])
	assert_eq(huts, 3, "the washers' three huts (chapter 02)")
	var walked: Array = d["path"]  # the way walked keeps the wall on the right going down: by its south side
	for q in walked:
		for w in wall:
			assert_gt(Vector2(float(q[0]), float(q[1])).distance_to(Vector2(float(w[0]), float(w[1]))), 1.5, "the way walked clear of the wall")
