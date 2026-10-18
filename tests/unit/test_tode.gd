extends GutTest
## Tödé, the upper quarter (M3 sprint 4, step 1; tools/town/tode.py, data/tode.json; chapter 02, D06 and TOD-01 to TOD-26;
## chapter 03, 3.2 and 3.5; ../tibet-blender kit/tode.py): its 68 houses dispersed in their fields, each kind where chapter
## 02 puts it, each on its own pad with its kit; the tulku's family house, the masons' and the empty tower-house at
## chapter 02's places; the four Bön households round their chapel.

const Town := preload("res://world/town.gd")
const TODE := "res://data/tode.json"
const KIT := "res://assets/generated/kit/types/%s.glb"
const BOX := Rect2(-365.0, 250.0, 665.0, 400.0)  # D06 (tools/town/tode.py BOX)
const LEAT := 2978.0


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func _houses() -> Array:
	return _json(TODE)["houses"]


func test_its_68_houses_and_the_empty_one() -> void:
	if not FileAccess.file_exists(TODE):
		pending("no data/tode.json (tools/py tools/town/tode.py)")
		return
	var by := {}
	for h in _houses():
		by[String(h["type"])] = int(by.get(String(h["type"]), 0)) + 1
	assert_eq(int(by.get("C", 0)), 15, "the 14 tower-houses of TOD-16 and the empty one TOD-26")
	assert_eq(int(by.get("A", 0)), 30, "the 30 log-storey houses of TOD-17")
	assert_eq(int(by.get("D", 0)), 20, "the 16 rammed-earth houses of TOD-18 and the four Bön households' of TOD-03")
	assert_eq(int(by.get("E", 0)), 4, "the 4 poor houses of TOD-19")
	for h in _houses():
		var f := Town.kit_file(h)
		assert_true(ResourceLoader.exists(KIT % f), "%s's kit %s" % [h["id"], f])


func test_where_chapter_02_puts_them() -> void:
	if not FileAccess.file_exists(TODE):
		pending("no data/tode.json")
		return
	var ids := {}
	for h in _houses():
		ids[String(h["id"])] = h
		var at := Vector2(float(h["pos"][0]), float(h["pos"][1]))
		assert_true(BOX.has_point(at), "%s in D06" % h["id"])
		assert_lt(float(h["pos"][2]), LEAT, "%s below the leat" % h["id"])
	var named := {"H-TOD-001": Vector2(60.0, 500.0), "H-TOD-002": Vector2(-280.0, 330.0), "TOD-26": Vector2(-230.0, 520.0)}
	for hid in named:
		assert_true(ids.has(hid), "%s placed" % hid)
		if ids.has(hid):
			var h: Dictionary = ids[hid]
			assert_lt(Vector2(float(h["pos"][0]), float(h["pos"][1])).distance_to(named[hid]), 30.0, "%s at chapter 02's place, or near it" % hid)
	assert_eq(int(ids.get("TOD-26", {}).get("ruin", 0)), 1, "TOD-26 abandoned (chapter 03, 12.3, level 1)")
	var chapel: Array = _json(TODE)["named"]["TOD-02"]["at"]
	var bon := 0
	for h in _houses():
		if h.get("bon", false):
			bon += 1
			assert_lt(Vector2(float(h["pos"][0]), float(h["pos"][1])).distance_to(Vector2(float(chapel[0]), float(chapel[1]))), 50.0,
				"%s round the chapel TOD-02" % h["id"])
			assert_true(String(h["kit"]).begins_with("tode_bon_house"), "%s a Bön household's house" % h["id"])
	assert_eq(bon, 4, "the four Bön households (TOD-03)")


func test_dispersed_none_alike_near() -> void:
	if not FileAccess.file_exists(TODE):
		pending("no data/tode.json")
		return
	var hs := _houses()
	for i in hs.size():
		var a := Vector2(float(hs[i]["pos"][0]), float(hs[i]["pos"][1]))
		var nearest := INF
		var twin := ""
		for j in hs.size():
			if i == j:
				continue
			var dd := a.distance_to(Vector2(float(hs[j]["pos"][0]), float(hs[j]["pos"][1])))
			if dd < nearest:
				nearest = dd
				twin = Town.kit_file(hs[j])
		assert_gt(nearest, 15.0, "%s in its own fields: its nearest neighbour %.0f m off" % [hs[i]["id"], nearest])
		assert_ne(Town.kit_file(hs[i]), twin, "%s unlike its nearest neighbour" % hs[i]["id"])


func test_a_path_to_every_house() -> void:
	if not FileAccess.file_exists(TODE):
		pending("no data/tode.json")
		return
	var d := _json(TODE)
	var ways: Dictionary = d.get("ways", {})
	var entries := [Vector2(253.0, 239.0)]  # (tools/town/tode.py: the Tödé Stair's top since step 2, the garden lane's top)
	if FileAccess.file_exists("res://data/tode_stair.json"):
		var top: Array = _json("res://data/tode_stair.json")["top"]
		entries.append(Vector2(float(top[0]), float(top[1])))
	for h in d["houses"]:
		var hid := String(h["id"])
		assert_true(ways.has(hid), "%s has a way" % hid)
		if not ways.has(hid):
			continue
		var w: Array = ways[hid]
		var end := Vector2(float(w[w.size() - 1][0]), float(w[w.size() - 1][1]))
		assert_true(entries.any(func(e): return end.distance_to(e) < 1.5),
			"%s's way ends at the Tödé Stair's top or the garden lane's top" % hid)
		var pad: Array = h["pad"]
		var start := Vector2(float(w[0][0]), float(w[0][1]))
		var off := start.distance_to(Vector2(float(pad[0]), float(pad[1])))
		# (tools/town/tode.py: its pad's half-width, its level apron 1.5 m, 2.5 m clear and a metre, on the 3 m grid)
		assert_between(off, float(pad[2]) / 2.0 + 2.5, float(pad[2]) / 2.0 + 8.5, "%s's way from beside its pad (%.1f m from its middle)" % [hid, off])
	var flights := 0
	for ln in d.get("lanes", []):
		var grade := absf(float(ln["z_b"]) - float(ln["z_a"])) / float(ln["length"])
		if ln.get("flight") != null:  # a stone flight where the slope is too steep for a ramp, built from its foot up
			flights += 1
			assert_true(bool(ln.get("steps", false)), "%s a flight of steps (export_lanes.py)" % ln["id"])
			assert_lt(grade, 0.9, "%s no steeper than its treads allow (%.0f%%)" % [ln["id"], grade * 100.0])
			assert_gt(float(ln["z_b"]), float(ln["z_a"]), "%s from its foot up" % ln["id"])
		else:
			assert_lt(grade, 0.31, "%s climbs at most 28%% (%.0f%%)" % [ln["id"], grade * 100.0])
			assert_true(bool(ln.get("road", false)), "%s carved and walled as a road (dry stone, trodden earth)" % ln["id"])
	assert_gt(flights, 10, "flights where the ground is too steep for a ramp's zigzags")


func test_the_tode_stair() -> void:
	## M3 sprint 4, step 2 (tools/town/tode_stair.py): the Sky Stair's way on up the band over the Tödé chorten, in flights
	## and landings from the forecourt to the band's top, where the field paths begin.
	if not FileAccess.file_exists("res://data/tode_stair.json") or not FileAccess.file_exists(TODE):
		pending("no data/tode_stair.json")
		return
	var st := _json("res://data/tode_stair.json")
	var foot: Array = st["foot"]
	var top: Array = st["top"]
	assert_almost_eq(float(foot[2]), 2782.0, 0.05, "from the forecourt at the Sky Stair's head")
	assert_gt(float(top[2]) - float(foot[2]), 80.0, "up the whole band (2,786 to some 2,870 m)")
	var steps := 0
	for ln in st["lanes"]:
		assert_true(bool(ln.get("steps", false)), "%s a piece of the stair (export_lanes.py)" % ln["id"])
		var fl: Dictionary = ln["flight"]
		if int(fl.get("n", 0)) > 0:
			steps += int(fl["n"])
			assert_almost_eq(float(fl["rise"]) / float(fl["n"]), 0.19, 0.01, "%s's risers 0.19 m" % ln["id"])
	assert_almost_eq(float(steps) * 0.19, float(top[2]) - float(foot[2]), 1.0, "its steps fill its height")
	var near := false
	for w in (_json(TODE)["ways"] as Dictionary).values():  # the field paths from its top
		var e: Array = w[w.size() - 1]
		near = near or Vector2(float(e[0]), float(e[1])).distance_to(Vector2(float(top[0]), float(top[1]))) < 0.5
	assert_true(near, "the field paths begin at the stair's top")
	# its top terrace (tools/town/tode.py TERRACE_*): level along the contour from its last step, where every way begins
	var ter: Dictionary = {}
	for ln in _json(TODE)["lanes"]:
		if bool(ln.get("terrace", false)):
			ter = ln
	assert_false(ter.is_empty(), "the stair's top terrace among the paths")
	if ter.is_empty():
		return
	var t0 := Vector2(float(ter["from"][0]), float(ter["from"][1]))
	var tu := Vector2(float(ter["dir"][0]), float(ter["dir"][1]))
	assert_lt(t0.distance_to(Vector2(float(top[0]), float(top[1]))), 0.1, "from the stair's last step")
	assert_almost_eq(float(ter["z_a"]), float(top[2]), 0.05, "at its top's level")
	assert_almost_eq(float(ter["z_b"]), float(ter["z_a"]), 0.01, "level")
	var ways: Dictionary = _json(TODE)["ways"]
	for h in ways:
		var w: Array = ways[h]
		if Vector2(float(w[w.size() - 1][0]), float(w[w.size() - 1][1])).distance_to(t0) > 0.5:
			continue
		var q: Array = w[w.size() - 2]
		var r := Vector2(float(q[0]), float(q[1])) - t0
		var u := r.dot(tu)
		var v := absf(r.dot(Vector2(-tu.y, tu.x)))
		assert_true(u > -0.5 and u < float(ter["length"]) + 0.5 and v < float(ter["width"]) / 2.0 + 0.5, "%s's way leaves the terrace from on it" % h)


func test_no_pieces_cross_at_two_heights() -> void:
	## M3 sprint 4, step 2 (tools/town/tode.py field_paths): two pieces cross only where they meet, or at one height (a
	## crossroads); crossing at two heights, the higher bed buried the lower's steps and the walker stalled.
	if not FileAccess.file_exists(TODE):
		pending("no data/tode.json")
		return
	var segs: Array = []
	for ln in _json(TODE)["lanes"]:
		if bool(ln.get("terrace", false)):
			continue
		var a := Vector2(float(ln["from"][0]), float(ln["from"][1]))
		var b := a + Vector2(float(ln["dir"][0]), float(ln["dir"][1])) * float(ln["length"])
		segs.append([a, b, float(ln["z_a"]), float(ln["z_b"]), String(ln["id"])])
	var bad: Array = []
	for i in segs.size():
		var p1: Vector2 = segs[i][0]
		var p2: Vector2 = segs[i][1]
		for j in range(i + 1, segs.size()):
			var q1: Vector2 = segs[j][0]
			var q2: Vector2 = segs[j][1]
			if maxf(p1.x, p2.x) < minf(q1.x, q2.x) or maxf(q1.x, q2.x) < minf(p1.x, p2.x) or maxf(p1.y, p2.y) < minf(q1.y, q2.y) or maxf(q1.y, q2.y) < minf(p1.y, p2.y):
				continue
			var x = Geometry2D.segment_intersects_segment(p1, p2, q1, q2)
			if x == null:
				continue
			var c: Vector2 = x
			if minf(minf(c.distance_to(p1), c.distance_to(p2)), minf(c.distance_to(q1), c.distance_to(q2))) < 1.5:
				continue  # (a junction, a way meeting another at a cell)
			var za := lerpf(float(segs[i][2]), float(segs[i][3]), c.distance_to(p1) / maxf(p1.distance_to(p2), 0.01))
			var zb := lerpf(float(segs[j][2]), float(segs[j][3]), c.distance_to(q1) / maxf(q1.distance_to(q2), 0.01))
			if absf(za - zb) > 0.5:
				bad.append("%s x %s" % [segs[i][4], segs[j][4]])
	assert_eq(bad.size(), 0, "no two pieces cross at two heights%s" % ("" if bad.is_empty() else ": " + ", ".join(bad.slice(0, 5))))
