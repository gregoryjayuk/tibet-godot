extends GutTest
## The Caravan Ground's ground (M2 sprint 9, step 1; plan chapter 02, D02 and R-03: "South pavilion -> the camp, 600 m,
## -80 m, 13%, 5 zigzags"; chapter 06, 7.1 and 8.6): tools/town/caravan_ground.py's Caravan Ramp, its legs at 13% and
## its five switchbacks' landings level, walled where they are cut or filled (tools/town/walls.py); the camp's yards on
## their ground; world/camp.gd's windbreaks, hay, fodder yard and dung walls, each caravan's from its hour.

const DATA := "res://data/caravan_ground.json"
const WALLS := "res://assets/generated/terrain/walls.json"
const Camp := preload("res://world/camp.gd")

var _minute := 0.0


func before_each() -> void:
	_minute = WorldClock.minute


func after_each() -> void:
	WorldClock.minute = _minute


func _d() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))


func test_the_ramp_keeps_its_grade() -> void:
	var d := _d()
	var legs := (d["lanes"] as Array).filter(func(ln): return String(ln["id"]).substr(5).is_valid_int())
	var landings := (d["lanes"] as Array).filter(func(ln): return String(ln["id"]).begins_with("R-03.L"))
	assert_eq(legs.size(), 6, "six legs")
	assert_eq(landings.size(), 5, "five switchbacks, chapter 02's five zigzags")
	var steepest := 0.0
	var length := 0.0
	for ln in legs:
		var prof: Array = ln["profile"]
		for k in range(1, prof.size()):
			steepest = maxf(steepest, absf(float(prof[k][1]) - float(prof[k - 1][1])) / maxf(float(prof[k][0]) - float(prof[k - 1][0]), 0.01))
		length += float(ln["length"])
	assert_lt(steepest, 0.1305, "no leg steeper than 13%")
	for ln in landings:
		assert_almost_eq(float(ln["z_a"]), float(ln["z_b"]), 0.001, "%s level" % ln["id"])
	assert_between(length, 550.0, 700.0, "about chapter 02's 600 m")
	assert_almost_eq(float(d["top"][2]), 2655.0, 0.01, "from R-01's level by the south pavilion")
	var down := float(d["top"][2]) - float(d["foot"][2])
	assert_between(down, 70.0, 85.0, "about chapter 02's 80 m down")
	for k in range(1, landings.size()):  # each landing lower than the one before, by a leg's fall
		assert_lt(float(landings[k]["z_a"]), float(landings[k - 1]["z_a"]) - 5.0, "the zigzag goes down")


func test_walled_where_cut_or_filled() -> void:
	if not FileAccess.file_exists(WALLS):
		pending("no walls: run tools/terrain/build.sh")
		return
	var w: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WALLS))
	var runs := (w["runs"] as Array).filter(func(r): return String(r["of"]).begins_with("R-03"))
	assert_gt(runs.size(), 10, "the ramp's legs walled along their cut and filled edges")
	var tallest := 0.0
	var parapets := 0
	for r in runs:
		for k in (r["pts"] as Array).size():
			var p: Array = r["pts"][k]
			var hh := float(p[5]) - float(p[4])
			tallest = maxf(tallest, hh)
			if String(r["kind"]) == "fill" and hh >= 1.52:  # (walls.json's heights rounded to the centimetre)
				assert_eq(int(r["flags"][k]) & 3, 3, "a high fill solid with a parapet (%s)" % r["of"])
				parapets += 1
	assert_lt(tallest, 6.5, "no wall along it over 6.5 m: the legs fitted to the ground")
	assert_gt(parapets, 0, "parapets over its high fills")
	var corral := (w["runs"] as Array).filter(func(r): return String(r["of"]) == "GAR-09")
	assert_eq(corral.size(), 1, "the corral's walls")
	if not corral.is_empty():
		assert_gt((corral[0]["pts"] as Array).size(), 90, "round it but for its gate")


func test_the_camp_on_its_ground() -> void:
	var d := _d()
	var pads: Dictionary = d["pads"]
	assert_true(pads.has("GAR-13") and pads["GAR-13"].has("at"), "the fodder yard moved onto the terrace")
	assert_true("GAR-09" in d["follow"] and "GAR-14" in d["follow"], "the corral and the drowned footings on the ground as it is")
	for t in d["things"]:
		if String(t["of"]) == "GAR-13":
			assert_almost_eq(float(t["at"][2]), float(pads["GAR-13"]["level"]), 0.01, "the yard on its pad")
	var walk: Array = d["walk"]
	assert_eq(walk.size(), 3, "the route's way on into the camp")


func test_each_caravans_by_the_clock() -> void:
	assert_false(Camp.shown_at(940.0, -1.0, 14.0 * 60.0), "a thing from 15:40 not yet at 14:00")
	assert_true(Camp.shown_at(940.0, -1.0, 16.0 * 60.0), "stacked by 16:00")
	assert_true(Camp.shown_at(940.0, -1.0, 2.0 * 60.0), "and through the night")
	assert_false(Camp.shown_at(940.0, -1.0, 4.5 * 60.0), "a new day from 04:00")
	assert_true(Camp.shown_at(660.0, -1.0, 12.0 * 60.0), "CV-01's wool from 11:00")
	assert_true(Camp.shown_at(-1.0, -1.0, 5.0 * 60.0), "the rest all day")


func test_the_camp_built() -> void:
	var d := _d()
	WorldClock.minute = 14.0 * 60.0
	var camp: Node3D = Camp.new()
	add_child_autofree(camp)
	var c: Dictionary = camp.build()
	if c["things"] == 0:
		pending("no kit files: ../tibet-blender export_types.py --types camp_tea_stack_3,...")
		return
	assert_eq(c["things"] + c["missing"], (d["things"] as Array).size(), "every thing placed")
	assert_eq(c["missing"], 0, "every kit file there")
	var hidden := 0
	for th in camp.get("things"):
		if not (th[0] as Node3D).visible:
			hidden += 1
	assert_eq(hidden, (d["things"] as Array).filter(func(t): return t.has("after") or (t["from"] != null and float(t["from"]) > 14.0 * 60.0)).size(), "CV-02's not yet at 14:00 (after its herd halts)")
	await wait_physics_frames(2)
	for th in camp.get("things"):
		if not (th[0] as Node3D).visible:
			for cs in (th[0] as Node3D).find_children("*", "CollisionShape3D", true, false):
				assert_true((cs as CollisionShape3D).disabled, "a stack not yet built is no wall")
	WorldClock.minute = Camp.DEFAULT_HALT + 35.0
	camp._process(0.0)
	for th in camp.get("things"):
		assert_true((th[0] as Node3D).visible, "all of it within 35 minutes of CV-02's halt (its tent pitched at 30)")
