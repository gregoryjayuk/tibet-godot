extends GutTest
## Who is on the Serchu road (M2 sprint 12, step 6; world/serchu_people.gd): a traveller's place along its way by the
## minute, its rest at the porters' rest; the gold washers' day (at work by day, round their fires early and late, abed
## at night); the millers' hours and their turns at the door; the woodcutters' hours; the washers' fires; the way up the
## road keeping the mani wall on its right; the woodcutters by their trees above the road; CV-02 now over the Zampa.

const People := preload("res://world/serchu_people.gd")


func test_a_travellers_way_and_its_rest() -> void:
	assert_eq(People.trip_s(600.0, 590.0, 1000.0), -1.0, "not yet set out")
	assert_almost_eq(People.trip_s(600.0, 610.0, 1000.0), 80.0, 0.001, "8 m a game minute")
	assert_eq(People.trip_s(600.0, 800.0, 1000.0), -1.0, "gone past the way's end")
	assert_almost_eq(People.trip_s(600.0, 610.0, 1000.0, 300.0), 380.0, 0.001, "from the foot of a woodcutter's path")
	# a rest at 120 m: reached at 15 minutes, held 8, then on
	assert_almost_eq(People.trip_s(600.0, 617.0, 1000.0, 0.0, 120.0, 8.0), 120.0, 0.001, "propped at the rest")
	assert_almost_eq(People.trip_s(600.0, 624.0, 1000.0, 0.0, 120.0, 8.0), 128.0, 0.001, "on again after its 8 minutes")


func test_the_washers_day() -> void:
	assert_eq(People.washer_doing(0, 120.0), "abed", "02:00 in the huts")
	assert_eq(People.washer_doing(0, 400.0), "fire", "06:40 round the morning's fire")
	assert_eq(People.washer_doing(1, 600.0), "trough", "10:00 the first three at the troughs")
	assert_eq(People.washer_doing(5, 600.0), "water", "the next six at the water's edge")
	assert_eq(People.washer_doing(10, 600.0), "camp", "the last three about the huts")
	assert_eq(People.washer_doing(5, 730.0), "noon", "12:10 their noon at the camp")
	assert_eq(People.washer_doing(5, 1140.0), "fire", "19:00 round the fires")
	assert_eq(People.washer_doing(5, 1300.0), "abed", "21:40 in")


func test_the_millers_and_the_woodcutters() -> void:
	assert_eq(People.miller_doing(300.0, 0), "away", "05:00 not yet at the mill")
	var door := 0
	for m in range(420, 480):
		if People.miller_doing(float(m), 2) == "door":
			door += 1
	assert_eq(door, 10, "ten minutes an hour at his door")
	assert_eq(People.miller_doing(1200.0, 0), "away", "20:00 gone home")
	assert_true(People.cutter_working(600.0), "10:00 at his tree")
	assert_false(People.cutter_working(920.0), "15:20 gone down with his wood")


func test_the_washers_fires() -> void:
	assert_eq(People.fire_lit(720.0), 0.0, "noon: no fire")
	assert_gt(People.fire_lit(1140.0), 0.99, "19:00 lit")
	assert_gt(People.fire_lit(380.0), 0.99, "06:20 the morning's tea")
	assert_eq(People.fire_lit(1380.0), 0.0, "23:00 out")


func test_the_way_up_keeps_the_mani_wall_on_its_right() -> void:
	var sr: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/serchu_road.json"))
	if not sr.has("path_up"):
		pending("no path_up (tools/terrain/serchu_road.py)")
		return
	var wall: Array = sr["mani_wall"]["line"]
	var mid: Array = wall[wall.size() / 2]
	var a: Array = wall[0]
	var b: Array = wall[wall.size() - 1]
	var down := Vector2(float(b[0]) - float(a[0]), float(b[1]) - float(a[1])).normalized()  # the wall's way, down the road
	var near_up: Array = []
	for q in sr["path_up"]:
		if Vector2(float(q[0]) - float(mid[0]), float(q[1]) - float(mid[1])).length() < 20.0:
			near_up.append(q)
	assert_false(near_up.is_empty(), "the way up passes the wall")
	for q in near_up:  # going up (against `down`, east), the wall on the right: the walker north of it, right of `down`
		var side := down.x * (float(q[1]) - float(mid[1])) - down.y * (float(q[0]) - float(mid[0]))
		assert_lt(side, 0.0, "going up, the walker passes on the wall's north side")


func test_the_woodcutters_by_their_trees() -> void:
	var path := "res://assets/generated/terrain/forest.json"
	if not FileAccess.file_exists(path):
		pending("no forest.json (tools/py tools/town/forest.py)")
		return
	var fo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var cs: Array = fo.get("cutters", [])
	assert_gt(cs.size(), 1, "woodcutters in the Shade Wood")
	for c in cs:
		var d := Vector2(float(c["at"][0]) - float(c["tree"][0]), float(c["at"][1]) - float(c["tree"][1])).length()
		assert_between(d, 0.8, 1.5, "a woodcutter beside his tree")
	assert_eq((fo.get("paths", []) as Array).size(), cs.size(), "each his path down to the road")


func test_the_caravan_comes_over_the_zampa() -> void:
	var g := "res://assets/generated/terrain/street_graph.json"
	if not FileAccess.file_exists(g):
		pending("no street graph (tools/py tools/town/graph.py)")
		return
	var c: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(g)) as Dictionary).get("caravan", {})
	var road: Array = c.get("road", [])
	assert_false(road.is_empty(), "the caravan's road")
	var zampa := false
	for q in road:
		if Vector2(float(q[0]) - 1250.0, float(q[1]) + 520.0).length() < 14.0:
			zampa = true
	assert_true(zampa, "CV-02's way over the Serchu Zampa (from the north bank's road)")
