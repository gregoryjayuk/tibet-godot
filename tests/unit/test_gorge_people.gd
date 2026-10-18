extends GutTest
## Who uses the Gorge Stair (M3 sprint 2, step 6; world/gorge_people.gd): the ways from the garden lane's foot to the
## West Gate, down to the water and in to the rest gallery's bench; the day's people on them by the hour, through the
## West Gate before it is barred; the novices racing past V-17's gallery in its window, the old monk at its wheel; the
## water carriers at the channel's head; the tulku's afternoon home on the full moon only.

const People := preload("res://world/gorge_people.gd")
const Steps := preload("res://world/steps_people.gd")
const Town := preload("res://world/town.gd")
const GORGE := "res://data/gorge_stair.json"


func _scene() -> Node3D:
	var gp: Node3D = People.new()
	add_child_autofree(gp)
	gp.build(null)
	return gp


func _who(gp: Node3D, key: String) -> Dictionary:
	for p in gp.people + gp.party:
		if String(p["key"]) == key:
			return p
	return {}


func test_the_ways() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json (tools/py tools/town/gorge_stair.py)")
		return
	var gp := _scene()
	for w in ["foot>gate", "gate>foot", "foot>water", "water>foot", "gate>bench", "bench>gate", "gate>deck", "deck>gate", "gate>terrace", "terrace>gate", "foot>watch", "watch>foot"]:
		assert_true(gp.ways.has(w), "the way %s" % w)
	var mk: Dictionary = gp.marks
	assert_lt(float(mk["terrace"]), float(mk["bridge_w"]), "the lane, then the west leg down to the bridge")
	assert_lt(float(mk["bridge_w"]), float(mk["bridge_e"]), "over it")
	assert_lt(float(mk["bridge_e"]), float(mk["gallery"]), "up the east leg past the rest gallery")
	assert_lt(float(mk["gallery"]), float(mk["gate"]), "to the West Gate")
	assert_almost_eq(float(mk["bridge_e"]) - float(mk["bridge_w"]), 29.2, 1.0, "the bridge's deck end to end (24 m and its hulls)")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GORGE))
	var fill: Array = d["water"]["fill"]
	var down: PackedVector3Array = gp.ways["foot>water"]
	var end := down[down.size() - 1]
	var f := Town.to_godot(float(fill[0]), float(fill[1]), float(fill[2]))
	assert_lt(Vector2(end.x - f.x, end.z - f.z).length(), 1.5, "down to the channel's head")
	assert_between(end.y - f.y, 0.2, 0.8, "standing a little over its water")
	var bench: PackedVector3Array = gp.ways["gate>bench"]
	assert_lt(bench[bench.size() - 1].distance_to(gp.spots["seat"][0]), 0.5, "in along the gallery's floor to the bench by the wheel")


func test_the_day_on_the_gorge_stair() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var gp := _scene()
	var count := func(m: float) -> int:
		var n := 0
		for p in gp.people:
			if bool(gp.where(p, m)[0]):
				n += 1
		return n
	assert_eq(count.call(180.0), 0, "03:00 nobody")
	assert_gte(count.call(480.0), 2, "08:00 the monks and the water carriers")
	assert_gte(count.call(900.0), 4, "15:00 the monks, the novices, the old monk on the bench")
	assert_eq(count.call(1200.0), 0, "20:00 nobody")
	var trips := 0
	for p in gp.people:
		for a in p["acts"]:
			if a.has("go"):
				trips += 1
				if String(a["go"]).ends_with(">gate"):
					assert_lt(float(a["t1"]), People.BARRED, "%s through the West Gate before it is barred" % p["key"])
	assert_gte(trips, 18, "twenty passings a day (chapter 02, D07: all in transit)")


func test_v17_people() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var gp := _scene()
	var gq := Steps._at(gp.ways["foot>gate"], gp.cums["foot>gate"], float(gp.marks["gallery"]))
	for key in ["novice_c", "novice_d"]:
		var p := _who(gp, key)
		var passed := -1.0
		for k in range(870 * 10, 930 * 10):
			var r: Array = gp.where(p, k / 10.0)
			if bool(r[0]) and Vector2((r[1] as Vector3).x - gq.x, (r[1] as Vector3).z - gq.z).length() < 3.0:
				passed = k / 10.0
				assert_eq(String(r[3]), "Run_Female", "%s running down past it" % key)
				break
		assert_between(passed, 870.0, 930.0, "%s past the rest gallery in V-17's window (14:30-15:30)" % key)
	var old := _who(gp, "gallery_monk")
	for m in [870.0, 900.0, 930.0]:
		var r: Array = gp.where(old, m)
		assert_true(bool(r[0]) and String(r[3]) == "Sitting_Idle", "the old monk on the bench at %.0f" % m)
		assert_lt((r[1] as Vector3).distance_to(gp.spots["seat"][0]), 0.01, "at its end by the wheel")
		assert_true(gp.turning(old, m), "turning the wheel")
	assert_false(gp.turning(old, 1000.0), "not after he has gone up")
	# the hand by the wheel (../tibet-blender kit/dungrong.py rest_gallery: WHEEL at x 3.45, y 0.75, 0.61 up)
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GORGE))
	for th in d["things"]:
		if String(th["kind"]) == "rest_gallery":
			var f := deg_to_rad(float(th["facing"]))
			var w := Vector2(float(th["at"][0]), float(th["at"][1])) + Vector2(-cos(f), sin(f)) * 3.45 + Vector2(-sin(f), -cos(f)) * 0.75
			var wq := Town.to_godot(w.x, w.y, float(th["level"]) + 0.61)
			var h: Vector3 = gp.spots["hand"]
			assert_lt(Vector2(h.x - wq.x, h.z - wq.z).length(), 0.85, "the hand within reach of the wheel's axis (world/kora_wheels.gd REACH)")
			assert_lt(absf(h.y - wq.y), 2.0, "at its height")


func test_the_water_carriers() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var gp := _scene()
	for key in ["tode_water_woman", "tode_water_girl"]:
		var p := _who(gp, key)
		var fills := 0
		for a in p["acts"]:
			if a.has("stay") and String(a["clip"]) == "Crouch_Idle":
				fills += 1
				assert_lt((a["at"] as Vector3).distance_to(gp.spots["fill"][0]), 0.01, "%s filling at the channel's head" % key)
				var after: Array = gp.where(p, float(a["t1"]) + 2.0)
				assert_eq(String(after[3]), "Walk_Carry", "and up again laden")
		assert_eq(fills, 2, "%s: two barrels a day (chapter 05, A-47: dawn and afternoon)" % key)


func test_the_tulkus_afternoon_home() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var gp := _scene()
	assert_true(People.tulku_day(15.0 * 1440.0 + 840.0), "5 November, the full moon (chapter 05's tulku_visit)")
	assert_false(People.tulku_day(7.0 * 1440.0 + 840.0), "not 28 October")
	assert_false(People.tulku_day(16.0 * 1440.0 + 840.0), "not 6 November")
	var tulku := _who(gp, "dungkar_tulku")
	var mother := _who(gp, "chodron_tode")
	assert_false(tulku.is_empty() or mother.is_empty(), "the tulku and his mother")
	var mid: Vector3 = gp._mid
	var on_bridge := -1.0
	for k in range(800 * 10, 900 * 10):
		var r: Array = gp.where(tulku, k / 10.0)
		if bool(r[0]) and Vector2((r[1] as Vector3).x - mid.x, (r[1] as Vector3).z - mid.z).length() < 1.0:
			on_bridge = k / 10.0
			break
	assert_between(on_bridge, 840.0, 855.0, "over the raw bridge at 14:00 (chapter 08: 14:00-15:15)")
	var r_m: Array = gp.where(mother, 845.0)
	assert_true(bool(r_m[0]) and (r_m[1] as Vector3).distance_to(gp.spots["watch"][0]) < 0.01, "his mother waiting on the terrace as he crosses")
	var r_t: Array = gp.where(tulku, 900.0)
	var r_m2: Array = gp.where(mother, 900.0)
	assert_eq(String(r_t[3]), "Sitting_Cross", "mother and son sitting together on the terrace at 15:00")
	assert_eq(String(r_m2[3]), "Sitting_Cross", "both")
	assert_lt((r_t[1] as Vector3).distance_to(r_m2[1]), 1.6, "side by side")
	for p in gp.party:
		var last: Dictionary = (p["acts"] as Array)[(p["acts"] as Array).size() - 1]
		if String(p["key"]) == "chodron_tode":
			assert_eq(String(last["go"]), "watch>foot", "she goes home by the lane")
			assert_gt(float(last["t0"]), People.PARTING + 10.0, "after watching them down and over the bridge")
		else:
			assert_eq(String(last["go"]), "terrace>gate", "%s back to the West Gate" % p["key"])
			assert_lt(float(last["t1"]), People.BARRED, "before it is barred")
