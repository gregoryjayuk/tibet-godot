extends GutTest
## Tödé's people (M3 sprint 4, step 6; tools/town/tode_days.py, world/tode_people.gd): the Bön circuit round the chapel
## TOD-02 at dawn, anticlockwise, close by its wheels; six threshers at each floor on its FLAIL sockets, neighbours
## striking alternately, with their flails; everyone from their own door and home again, never in two places at once; the
## day's count by the hour; the chapel's wheels turning the other way.

const People := preload("res://world/tode_people.gd")
const KoraWheels := preload("res://world/kora_wheels.gd")
const Town := preload("res://world/town.gd")
const DATA := "res://data/tode_people.json"
const THINGS := "res://data/tode_things.json"
const TODE := "res://data/tode.json"


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func _scene() -> Node3D:
	var tp: Node3D = People.new()
	add_child_autofree(tp)
	tp.build(null)
	return tp


func test_the_bon_circuit() -> void:
	if not FileAccess.file_exists(DATA) or not FileAccess.file_exists(THINGS):
		pending("no data/tode_people.json (tools/py tools/town/tode_days.py)")
		return
	var walkers := 0
	for p in _json(DATA)["people"]:
		for a in p["acts"]:
			if not a.has("go") or not bool(a.get("kora", false)):
				continue
			walkers += 1
			var pts: Array = a["go"]
			var ts: Array = a["ts"]
			assert_between(float(ts[0]), 325.0, 345.0, "%s on the circuit from about 05:30 (chapter 05, A-06)" % p.get("name", p["key"]))
			assert_between(float(ts[ts.size() - 1]), 360.0, 390.0, "until about 06:30")
			var area := 0.0  # the first round's signed area on the town grid (north up): positive, anticlockwise
			for k in 8:
				var q: Array = pts[k]
				var r: Array = pts[k + 1]
				area += float(q[0]) * float(r[1]) - float(r[0]) * float(q[1])
			assert_gt(area, 0.0, "round the chapel anticlockwise, keeping it on the left (chapter 02, R-24)")
			var ch: Dictionary = _json(TODE)["named"]["TOD-02"]
			for q in pts:
				var d := Vector2(float(q[0]) - float(ch["at"][0]), float(q[1]) - float(ch["at"][1])).length()
				assert_between(d, 4.0, 7.5, "on its terrace, round its walls")
	assert_eq(walkers, 2, "Yungdrung Gyaltsen and a woman of another Bön household (A-06: two)")


func test_the_threshers() -> void:
	if not FileAccess.file_exists(DATA) or not FileAccess.file_exists(THINGS):
		pending("no data")
		return
	var floors := {}
	for t in _json(THINGS)["things"]:
		if String(t["id"]) in ["TOD-11", "TOD-12", "TOD-13", "TOD-14"]:
			floors[String(t["id"])] = t
	var at_floor := {}
	for p in _json(DATA)["people"]:
		for a in p["acts"]:
			if not a.has("stay") or not bool(a.get("flail", false)):
				continue
			var q: Array = a["stay"]
			for fid in floors:
				var t: Dictionary = floors[fid]
				if Vector2(float(q[0]) - float(t["at"][0]), float(q[1]) - float(t["at"][1])).length() < 6.5:
					if not at_floor.has(fid):
						at_floor[fid] = {}
					var k := String(p.get("who", p["key"])) + String(p["key"])
					if not at_floor[fid].has(k) or float(a["t0"]) < float(at_floor[fid][k][0]):  # (the first of the day's)
						at_floor[fid][k] = [float(a["t0"]), float(a.get("phase", 0.0)), q]
	for fid in floors:
		assert_true(at_floor.has(fid), "threshers at %s" % fid)
		if not at_floor.has(fid):
			continue
		var crew: Dictionary = at_floor[fid]
		assert_eq(crew.size(), 6, "a line of six at %s (its FLAIL sockets)" % fid)
		var phases := {}
		for k in crew:
			assert_lt(float(crew[k][0]), 540.0, "%s at %s by 09:00 (A-44 from 08:30)" % [k, fid])
			phases[snappedf(fposmod(float(crew[k][1]), 0.9583), 0.01)] = true
		assert_gt(phases.size(), 1, "neighbours striking alternately at %s" % fid)


func test_from_their_doors_never_in_two_places() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no data")
		return
	var d := _json(DATA)
	var td := _json(TODE)
	var houses := {}
	for h in td["houses"]:
		houses[String(h["id"])] = h
	assert_between((d["people"] as Array).size(), 35, 60, "Tödé's people out by day")
	for p in d["people"]:
		var spans: Array = []
		for a in p["acts"]:
			spans.append([float(a["ts"][0]), float(a["ts"][a["ts"].size() - 1])] if a.has("go") else [float(a["t0"]), float(a["t1"])])
		spans.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		for k in range(1, spans.size()):
			assert_true(float(spans[k][0]) >= float(spans[k - 1][1]) - 0.01, "%s (%s) in one place at a time" % [p.get("name", p["who"]), p["role"]])
		var h: Dictionary = houses.get(String(p["house"]), {})
		var first: Dictionary = p["acts"][0]
		if first.has("go") and not bool(p.get("roof", false)) and not h.is_empty():
			var q: Array = first["go"][0]
			assert_lt(Vector2(float(q[0]) - float(h["pos"][0]), float(q[1]) - float(h["pos"][1])).length(), 12.0, "%s out of the door of %s" % [p["key"], p["house"]])


func test_the_day_by_the_hour() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no data")
		return
	var tp := _scene()
	var count := func(m: float) -> int:
		var n := 0
		for p in tp.people:
			if tp.out_at(p, m):
				n += 1
		return n
	assert_eq(count.call(300.0), 0, "05:00: indoors")
	assert_eq(count.call(345.0), 2, "05:45: the two on the Bön circuit")
	assert_gt(count.call(600.0), 30, "10:00: threshing, the millers, the fields")
	assert_lt(count.call(1140.0), 2, "19:00: home")
	var shown := 0
	for p in tp.people:
		var r: Array = tp.where(p, 600.0)
		if bool(r[0]) and String(r[3]) == "Chop_Tree":
			shown += 1
	assert_gt(shown, 24, "10:00: the flails going on the floors and the roofs")


func test_the_chapel_and_its_wheels() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	Town.place(root, Rect2(Vector2(-280.0, 530.0), Vector2(60.0, 60.0)))
	var ch := root.get_node_or_null("Town/TOD-02") as Node3D
	assert_not_null(ch, "the Bön chapel TOD-02 placed (world/town.gd NAMED)")
	if ch == null:
		return
	var kw := ch.get_node_or_null("KoraWheels")
	assert_not_null(kw, "its wheels hung (world/kora_wheels.gd)")
	if kw == null:
		return
	assert_eq(kw.wheels.size(), 4, "four wheels in their niches by the door")
	assert_eq(kw.sense, -1.0, "turning anticlockwise (chapter 03, 3.2)")
	var w: Node3D = kw.wheels[0]
	var y0 := w.rotation.y
	kw.speed[0] = 0.8  # set turning, then a tenth of a second without a hand on it
	kw._process(0.1)
	assert_gt(w.rotation.y, y0, "seen from above, anticlockwise")


func test_the_bon_households_niches() -> void:
	if not FileAccess.file_exists(THINGS):
		pending("no data")
		return
	var niches: Array = []
	for t in _json(THINGS)["things"]:
		if String(t["id"]).begins_with("TOD-03.W"):
			niches.append(t)
	assert_eq(niches.size(), 4, "a wheel niche by each of the four Bön households' gates (chapter 03, 3.2)")
	var root := Node3D.new()
	add_child_autofree(root)
	Town.place(root, Rect2(Vector2(-300.0, 500.0), Vector2(100.0, 110.0)))
	for t in niches:
		var n := root.get_node_or_null("Town/%s" % String(t["id"]).validate_node_name()) as Node3D
		assert_not_null(n, "%s placed (world/town.gd)" % t["id"])
		if n == null:
			continue
		var kw := n.get_node_or_null("KoraWheels")
		assert_not_null(kw, "%s's wheels hung" % t["id"])
		if kw != null:
			assert_eq(kw.wheels.size(), 3, "%s: three wheels on its sill" % t["id"])
			assert_eq(kw.sense, -1.0, "%s: turning anticlockwise" % t["id"])

