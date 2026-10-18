extends GutTest
## The Gorge Rim Lookout SHL-32 and the lane to it through upper Shöl's walled gardens SHL-33 (M2 sprint 6, step 4; plan
## chapter 02; chapter 08, V-13a: "up through the walled gardens of upper Shöl along a lane between garden walls 2.5 m
## high, which hides everything; the terrace opens on the gorge rim"): tools/town/gardens.py's lane, plots and trees,
## tools/town/walls.py's walls along it, the terrace placed facing the notch, the walkers' way there.

const GARDENS := "res://data/gardens.json"
const WALLS := "res://assets/generated/terrain/walls.json"
const GRAPH := "res://assets/generated/terrain/street_graph.json"


func _g() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(GARDENS))


func test_the_lane_keeps_its_grade() -> void:
	var g := _g()
	var legs: Array = g["lanes"]
	assert_gte(legs.size(), 10, "the lane in its legs")
	var steepest_ramp := 0.0
	var steepest_flat := 0.0
	for ln in legs:
		var prof: Array = ln["profile"]
		for k in range(1, prof.size()):
			var grade := absf(float(prof[k][1]) - float(prof[k - 1][1])) / maxf(float(prof[k][0]) - float(prof[k - 1][0]), 0.01)
			if float(ln["s0"]) + float(prof[k][0]) < 32.0:
				steepest_ramp = maxf(steepest_ramp, grade)
			else:
				steepest_flat = maxf(steepest_flat, grade)
	assert_lt(steepest_ramp, 0.29, "the shoulder's ramp no steeper than 16 degrees")
	assert_lt(steepest_flat, 0.065, "and along the contour all but level (5%, its levels to the centimetre)")
	assert_almost_eq(float(legs[0]["z_a"]), 2769.5, 0.05, "from H-SHL-095's yard")
	assert_almost_eq(float(legs[legs.size() - 1]["z_b"]), 2781.5, 0.05, "to the terrace, built out 3.5 m over chapter 02's 2,778 m")


func test_walled_the_whole_way() -> void:
	if not FileAccess.file_exists(WALLS):
		pending("no walls: run tools/terrain/build.sh")
		return
	var g := _g()
	var w: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WALLS))
	var legs: Array = g["lanes"]
	var length := 0.0
	for ln in legs:
		length += float(ln["length"])
	var runs := (w["runs"] as Array).filter(func(r): return String(r["of"]) == "GL")
	assert_eq(runs.size(), 2, "one wall each side, the whole lane long")
	var low := 99.0
	for r in runs:
		assert_gte((r["pts"] as Array).size(), int(length) - 2, "unbroken from the yard to the terrace")
		for p in r["pts"]:
			var best := 1.0e9
			var bed := 0.0
			for ln in legs:  # the nearest leg's bed, at the point's foot on its line
				var sl := clampf((float(p[0]) - float(ln["from"][0])) * float(ln["dir"][0]) + (float(p[1]) - float(ln["from"][1])) * float(ln["dir"][1]), 0.0, float(ln["length"]))
				var q := Vector2(float(ln["from"][0]) + float(ln["dir"][0]) * sl, float(ln["from"][1]) + float(ln["dir"][1]) * sl)
				var d := q.distance_to(Vector2(float(p[0]), float(p[1])))
				if d < best:
					best = d
					bed = _bed(ln, sl)
			low = minf(low, float(p[6]) - bed)
	assert_gte(low, 2.4, "the walls' tops 2.5 m over the bed (chapter 08), all the way")
	var plots := 0
	for r in w["runs"]:
		if String(r["of"]).begins_with("plot"):
			plots += 1
	assert_gte(plots, 12, "the plots walled round")


func _bed(ln: Dictionary, s: float) -> float:
	var prof: Array = ln["profile"]
	for k in range(1, prof.size()):
		if s <= float(prof[k][0]):
			var t := (s - float(prof[k - 1][0])) / maxf(float(prof[k][0]) - float(prof[k - 1][0]), 0.01)
			return lerpf(float(prof[k - 1][1]), float(prof[k][1]), clampf(t, 0.0, 1.0))
	return float(prof[prof.size() - 1][1])


func test_the_orchards() -> void:
	var g := _g()
	assert_eq((g["plots"] as Array).size(), 12, "twelve plots (chapter 02)")
	var kinds := {}
	for t in g["trees"]:
		kinds[String(t["kind"])] = int(kinds.get(String(t["kind"]), 0)) + 1
	for k in ["walnut", "apple", "pear"]:
		assert_gt(int(kinds.get(k, 0)), 0, "%s trees" % k)
		assert_true(ResourceLoader.exists("res://assets/generated/kit/types/tree_%s_v1.glb" % k), "the kit's %s" % k)
	assert_eq((g["gates"] as Array).size(), 12, "a door into each plot from the lane")


func test_the_terrace_faces_the_notch() -> void:
	var named: Dictionary = load("res://world/town.gd").NAMED
	assert_true(named.has("SHL-32"), "placed by the town")
	assert_eq(float(named["SHL-32"][3]), 34.0, "facing the notch, 034 on the real ground (chapter 08's 040: DECISIONS)")
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/kit/types/sh32_lookout_v1.json"))
	for k in ["SOCK_SANG_1", "SOCK_MAST_1", "SOCK_STAND_1"]:
		assert_true((side["socket_pos"] as Dictionary).has(k), "its %s" % k)


func test_the_walkers_way_there() -> void:
	if not FileAccess.file_exists(GRAPH):
		pending("no street graph")
		return
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GRAPH))
	assert_true((g["anchors"] as Dictionary).has("lookout"), "the terrace on the walkers' ground")
	var found := false
	for w in g["walkers"]:
		if String(w.get("who", "")) == "lookout_woman":
			found = true
			var dusk := false
			for stop in w["day"]:
				if String(stop[0]) == "lookout" and float(stop[1]) <= 1020.0 and float(stop[2]) >= 1050.0:
					dusk = true
			assert_true(dusk, "the old woman at its burner from before five to after half past (chapter 08)")
	assert_true(found, "the old woman of upper Shöl goes up")
	assert_true((g["routes"] as Dictionary).has("H-SHL-095>lookout"), "by the garden lane from the house at its foot")
