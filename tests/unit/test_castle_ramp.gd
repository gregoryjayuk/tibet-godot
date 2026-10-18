extends GutTest
## The Castle Ramp SAM-10 (M2 sprint 11, step 1; plan chapter 02, D04, SAM-10 and R-16): tools/town/castle_ramp.py's way
## out of the castle ward's gate and its three legs down the knob's west flank to Hejie's East Gate, at one grade, its two
## switchbacks' landings level, ending at River Street's level in the gate; walled where cut or filled (tools/town/
## walls.py); the ula yard SAM-09 moved off the flank it crosses (pads.py reads it).

const DATA := "res://data/castle_ramp.json"
const SAMKHA := "res://data/samkha.json"
const HEJIE := "res://data/hejie.json"
const WALLS := "res://assets/generated/terrain/walls.json"


func _d() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))


func test_three_legs_at_one_grade() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no data/castle_ramp.json (tools/py tools/town/castle_ramp.py)")
		return
	var d := _d()
	var legs := (d["lanes"] as Array).filter(func(ln): return String(ln["id"]).substr(7).is_valid_int())
	var landings := (d["lanes"] as Array).filter(func(ln): return String(ln["id"]).begins_with("SAM-10.L"))
	assert_eq(legs.size(), 3, "chapter 02's three legs")
	assert_eq(landings.size(), 2, "two switchbacks")
	var steepest := 0.0
	var length := 0.0
	for ln in legs:
		var prof: Array = ln["profile"]
		for k in range(1, prof.size()):
			steepest = maxf(steepest, absf(float(prof[k][1]) - float(prof[k - 1][1])) / maxf(float(prof[k][0]) - float(prof[k - 1][0]), 0.01))
		length += float(ln["length"])
		assert_true(bool(ln.get("road", false)), "%s carved and walled as a road" % ln["id"])
	assert_lt(steepest, 0.2215, "no leg steeper than 22% (chapter 02's 15% would cut the flank 10-20 m deep)")
	assert_between(length, 200.0, 320.0, "about 220 m of legs (chapter 02: 300 m)")
	for ln in landings:
		assert_almost_eq(float(ln["z_a"]), float(ln["z_b"]), 0.001, "%s level" % ln["id"])
	assert_lt(float(landings[1]["z_a"]), float(landings[0]["z_a"]) - 10.0, "the second switchback a leg's fall below the first")


func test_from_the_ward_to_the_east_gate() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no data/castle_ramp.json")
		return
	var d := _d()
	var sk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMKHA))
	var gate := Vector2(float(sk["ward_gate"][0]), float(sk["ward_gate"][1]))
	var top: Array = d["top"]
	assert_lt(Vector2(float(top[0]), float(top[1])).distance_to(gate), 3.0, "from the ward's gate")
	assert_almost_eq(float(top[2]), float(sk["ward"]["z"]), 0.5, "at the ward's level")
	var street: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(HEJIE))["lanes"] as Array)[0]
	var foot: Array = d["foot"]
	assert_lt(Vector2(float(foot[0]), float(foot[1])).distance_to(Vector2(float(street["from"][0]), float(street["from"][1]))), 1.5,
			"into the East Gate where River Street begins")
	assert_almost_eq(float(foot[2]), float(street["z_a"]), 0.05, "at its level")
	for q in d["path"]:  # never inside Hejie's wall (x -214 up to its north-east corner at y 12) before the gate
		if float(q[0]) < -213.5:
			assert_almost_eq(float(q[1]), -80.0, 4.5, "only through the East Gate's gap")


func test_walled_where_cut_or_filled() -> void:
	if not FileAccess.file_exists(WALLS):
		pending("no walls: run tools/terrain/build.sh")
		return
	var w: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WALLS))
	var runs := (w["runs"] as Array).filter(func(r): return String(r["of"]).begins_with("SAM-10"))
	assert_gt(runs.size(), 3, "the ramp's legs walled along their cut and filled edges")
	var tallest := 0.0
	for r in runs:
		for p in r["pts"]:
			tallest = maxf(tallest, float(p[5]) - float(p[4]))
	assert_lt(tallest, 10.5, "no wall along it over 10.5 m: the legs fitted to the ground (the second landing's, on the bank over the water, about 10)")


func test_the_ula_yard_moved_off_it() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no data/castle_ramp.json")
		return
	var pads: Dictionary = _d()["pads"]
	assert_true(pads.has("SAM-09"), "the ula yard placed by the ramp")
	var at := Vector2(float(pads["SAM-09"]["at"][0]), float(pads["SAM-09"]["at"][1]))
	for ln in _d()["lanes"]:
		var a := Vector2(float(ln["from"][0]), float(ln["from"][1]))
		var u := Vector2(float(ln["dir"][0]), float(ln["dir"][1]))
		var s := clampf((at - a).dot(u), 0.0, float(ln["length"]))
		assert_gt((a + u * s).distance_to(at), 15.0, "the yard's middle clear of %s" % ln["id"])
