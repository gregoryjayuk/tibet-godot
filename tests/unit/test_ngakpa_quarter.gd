extends GutTest
## The ngakpa quarter (M2 sprint 6, step 1; plan chapter 02, SHL-36: H-SHL-111 to 135, the 25 households of married tantric
## practitioners round Pema Ö Lhakhang at the town's east end, 2,665-2,720 m, types A and B): the town builder's fourth
## pass (tools/town/builder.py) in data/town_generic.json, its side lanes in data/town_lanes.json after the town's, and the
## rest of the town's houses and lanes as they were.

const GENERIC := "res://data/town_generic.json"
const LANES := "res://data/town_lanes.json"


func _houses() -> Array:
	return (JSON.parse_string(FileAccess.get_file_as_string(GENERIC)) as Dictionary)["houses"]


func test_twenty_five_households_round_pema_o() -> void:
	var q := _houses().filter(func(h: Dictionary) -> bool: return String(h.get("quarter", "")) == "shol.ngakpa")
	assert_eq(q.size(), 25, "SHL-36's 25 households")
	var ids := []
	var kinds := {}
	for h in q:
		ids.append(String(h["id"]))
		kinds[String(h["type"])] = true
		var p: Array = h["pos"]
		assert_lt(Vector2(float(p[0]) - 165.0, float(p[1]) + 55.0).length(), 110.0, "%s round Pema Ö" % h["id"])
		assert_between(float(p[2]), 2660.0, 2722.0, "%s within the quarter's heights (its pad)" % h["id"])
	ids.sort()
	assert_eq(ids[0], "H-SHL-111", "the gazetteer's first")
	assert_eq(ids[24], "H-SHL-135", "and its last")
	assert_true(kinds.has("A") and kinds.has("B"), "both kinds, town houses and log-storey houses")


func test_clear_of_the_temple_and_its_ground() -> void:
	# Pema Ö's pad with its corridor and forecourt (tools/terrain/pads.py SIZE, YARDS), turned to 140 degrees, and R-08's ramp
	var th := deg_to_rad(180.0 - 140.0)
	for h in _houses():
		if String(h.get("quarter", "")) != "shol.ngakpa":
			continue
		var p: Array = h["pos"]
		var d := Vector2(float(p[0]) - 165.0, float(p[1]) + 55.0)
		var local := Vector2(d.x * cos(th) + d.y * sin(th), -d.x * sin(th) + d.y * cos(th))  # into the temple's frame
		var r := maxf(float(h["footprint"][0]), float(h["footprint"][1])) / 2.0
		assert_false(absf(local.x) < 9.9 + r and local.y > -13.0 - r and local.y < 8.9 + r, "%s clear of Pema Ö's pad" % h["id"])
		assert_false(float(p[0]) > 145.0 - r and float(p[0]) < 166.0 + r and absf(float(p[1]) + 69.6) < 3.6 + r, "%s clear of R-08's ramp" % h["id"])


func test_its_lanes_after_the_towns() -> void:
	var lanes: Array = (JSON.parse_string(FileAccess.get_file_as_string(LANES)) as Dictionary)["lanes"]
	var town_last := 0
	var quarter_first := 1000
	var ngakpa := {}
	for h in _houses():
		if String(h.get("quarter", "")) == "shol.ngakpa":
			ngakpa[String(h["id"])] = true
	for l in lanes:
		var id := String(l["id"])
		if not id.begins_with("LN-"):
			continue
		var n := int(id.substr(3))
		var between: Array = l.get("between", [])
		if between.size() == 2 and ngakpa.has(String(between[0])):
			quarter_first = mini(quarter_first, n)
		elif between.size() == 2:
			town_last = maxi(town_last, n)
	assert_lt(town_last, quarter_first, "the town's side lanes keep their numbers, the quarter's after them")
	assert_lt(quarter_first, 1000, "the quarter has side lanes of its own")
