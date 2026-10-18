extends GutTest
## The walkers' ground over the town's east and west ends (M2 sprint 6, step 2; IMP-030; tools/town/graph.py GROUND_BOX):
## Pema Ö's porch, the Conch terrace, the west edge, its way down to the Landing and the caravan ground, and the western
## mani wall's place on the graph; the ngakpa quarter's householders going to the temple's service, the west edge's poor
## family of H-SHL-142 on chapter 04's day; and the day's drawn (M2 sprint 10, step 2) from their doors or their ways in.

const GRAPH := "res://assets/generated/terrain/street_graph.json"
const SLICE := Rect2(-145.0, -107.0, 220.0, 366.0)  ## tools/town/graph.py BOX, less its 5 m margin


func _g() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(GRAPH))


func _walker(g: Dictionary, who: String) -> Dictionary:
	for w in g["walkers"]:  # the named and the generic by their key ("who"; their "kind" is their body's)
		if String(w.get("who", "")) == who:
			return w
	return {}


func test_the_ends_are_on_the_walkers_ground() -> void:
	if not FileAccess.file_exists(GRAPH):
		pending("no street graph: run tools/py tools/town/graph.py")
		return
	var a: Dictionary = _g()["anchors"]
	for k in ["pema_o", "conch_terrace", "west_edge", "west_way", "west_mani"]:
		assert_true(a.has(k), "%s on the walkers' ground" % k)


func test_the_quarters_men_go_to_the_service() -> void:
	if not FileAccess.file_exists(GRAPH):
		pending("no street graph")
		return
	var g := _g()
	for kind in ["ngakpa_man", "ngakpa_man_b"]:
		var w := _walker(g, kind)
		assert_false(w.is_empty(), "%s walks" % kind)
		var n := int(String(w["home"]).substr(6))
		assert_between(n, 111, 135, "%s's home in the ngakpa quarter" % kind)
		var at_service := false
		for stop in w["day"]:
			if String(stop[0]) == "pema_o" and float(stop[1]) <= 480.0 and float(stop[2]) >= 540.0:
				at_service = true
		assert_true(at_service, "%s at Pema Ö's service from 08:00" % kind)


func test_the_poor_familys_day() -> void:
	if not FileAccess.file_exists(GRAPH):
		pending("no street graph")
		return
	var g := _g()
	var norbu := _walker(g, "norbu")
	assert_eq(String(norbu.get("home", "")), "H-SHL-142", "Norbu lives in H-SHL-142")
	var left := 0.0
	for stop in norbu["day"]:
		if String(stop[0]) == "H-SHL-142" and float(stop[1]) == 0.0:
			left = float(stop[2])
	assert_almost_eq(left, 400.0, 5.0, "Norbu off to the Landing at 06:40 (chapter 04, 4.2)")
	var dawa := _walker(g, "dawa")
	assert_lt(float(dawa["day"][0][2]), 360.0, "Dawa out for water and dung by 06:00")
	var gm := _walker(g, "poor_grandmother")
	var dusk := false
	for stop in gm["day"]:
		if String(stop[0]) == "west_mani" and float(stop[1]) >= 1020.0:
			dusk = true
	assert_true(dusk, "the grandmother on the lingkor's west side at dusk")


func test_the_days_drawn_from_their_doors_and_ways_in() -> void:  # (until M2 sprint 10 the twenty, drawn from the slice)
	if not FileAccess.file_exists(GRAPH):
		pending("no street graph")
		return
	var g := _g()
	var ground := Rect2(-470.0, -150.0, 740.0, 414.0)  ## tools/town/graph.py GROUND_BOX (over Hejie since M2 sprint 10, step 3)
	var houses: Dictionary = {}
	for f in ["res://data/town_generic.json", "res://data/hejie.json"]:  # Shöl's houses, Hejie's
		for h in (JSON.parse_string(FileAccess.get_file_as_string(f)) as Dictionary)["houses"]:
			houses[String(h["id"])] = h["pos"]
	for b in (JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json")) as Dictionary)["buildings"]:
		if String(b["id"]).begins_with("HEJ-") and b.get("pos") != null:  # Hejie's named, homes to their keepers
			houses[String(b["id"])] = b["pos"]
	var doors := 0
	var ways := 0
	for w in g["walkers"]:
		if not bool(w.get("roster", false)):  # the written days' walkers: their own homes
			continue
		var home := String(w["home"])
		if home.begins_with("H-") or home.begins_with("HEJ-"):
			doors += 1
			var p: Array = houses.get(home, [9999.0, 9999.0])
			assert_true(ground.has_point(Vector2(float(p[0]), float(p[1]))), "%s's home on the walkers' ground" % home)
		else:
			ways += 1
			assert_true((g["anchors"] as Dictionary).has(home), "%s comes in by a place on the graph (%s)" % [w["who"], home])
	assert_gt(doors, 30, "Shöl's own drawn today, from their doors (tools/town/roster.py)")
	assert_gt(ways, 50, "and those who come in: the hamlets to market, the monks, the pilgrims, the caravans' men")
