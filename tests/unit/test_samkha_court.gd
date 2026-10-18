extends GutTest
## Samkha's people (M2 sprint 11, step 5; plan chapter 02, D04: "by day 150, with petitioners at the court, the toll
## traffic and the ula yard"; chapter 05, NPC-03 and NPC-39): the day's cases brought to the Pönpo's morning hearing by
## walkers (tools/town/roster.py CASES, tools/town/graph.py court_day) and drawn on the hall's felts (world/samkha_people.gd),
## the Shöl headman at his side while his walker is in the castle, the great court on the calendar's court days, and the
## loads counted at Sherab's table.

const SamkhaPeople := preload("res://world/samkha_people.gd")
const GRAPH := "res://assets/generated/terrain/street_graph.json"
const ROSTER := "res://data/roster.json"
const NAMED_DAYS := "res://data/named_days.json"
const PEOPLE := "res://assets/generated/people/%s.glb"


func _walkers() -> Array:
	return (JSON.parse_string(FileAccess.get_file_as_string(GRAPH)) as Dictionary)["walkers"]


func test_the_cases_are_brought_by_walkers() -> void:
	if not FileAccess.file_exists(GRAPH):
		pending("no street graph (tools/py tools/town/graph.py)")
		return
	var cases := 0
	for q in (JSON.parse_string(FileAccess.get_file_as_string(ROSTER)) as Dictionary)["people"]:
		if String(q["day"]) == "court":
			cases += 1
	var court: Array = _walkers().filter(func(w): return w.has("court"))
	assert_eq(court.size(), cases, "every party the roster draws walks to the hearing")
	assert_gt(court.size(), 3, "the morning's cases (chapter 05, NPC-03: petitions, a fine in tea bricks)")
	for w in court:
		var c: Array = w["court"]
		assert_true(float(c[0]) >= SamkhaPeople.COURT[0] and float(c[1]) <= SamkhaPeople.COURT[1], "%s's case in the court's hours" % w["who"])
		var waited := false
		var inside := false
		for s in w["day"]:
			if String(s[0]) == "court_wait" and float(s[2]) <= float(c[0]):
				waited = true
			if String(s[0]) == "castle_door" and String(s[3]) == "inside" and absf(float(s[1]) - float(c[0])) < 0.5 and absf(float(s[2]) - float(c[1])) < 0.5:
				inside = true
		assert_true(waited, "%s waits in the ward before its case" % w["who"])
		assert_true(inside, "%s is in the castle for its case" % w["who"])
		for o in court:  # one party a felt at a time
			if o != w and int(o["court"][2]) == int(c[2]):
				assert_true(float(o["court"][1]) <= float(c[0]) or float(o["court"][0]) >= float(c[1]), "%s and %s on one felt at once" % [w["who"], o["who"]])


func test_the_headman_sits_at_the_ponpos_side() -> void:
	var day: Array = (JSON.parse_string(FileAccess.get_file_as_string(NAMED_DAYS)) as Dictionary)["people"]["sonam_wangyal"]["day"]
	var hall: Array = SamkhaPeople.COURT_PEOPLE.filter(func(c): return String(c[1]) == "court_elder")[0]
	var there := false
	for s in day:
		if String(s[0]) == "castle_door" and float(s[1]) <= float(hall[2]) and float(s[2]) >= float(hall[3]):
			there = true
	assert_true(there, "in the castle while he is drawn at the court (his walker up its steps: data/named_days.json)")
	assert_eq(String(hall[0]), "sonam_wangyal", "the Shöl headman himself by the west wall (chapter 05, NPC-03)")


func test_the_great_court_keeps_the_calendars_days() -> void:
	assert_false(SamkhaPeople.great_court(WorldClock.DEFAULT_MINUTE), "not on the default day, 28 October (the 12th)")
	assert_true(SamkhaPeople.great_court(19 * 1440.0 + 9 * 60.0), "on 9 November, the 20th of the ninth month")
	assert_true(SamkhaPeople.great_court(4 * 1440.0 + 9 * 60.0), "on 25 October, the 5th")
	for c in SamkhaPeople.GREAT_COURT:
		assert_true(float(c[2]) >= SamkhaPeople.COURT[0] and float(c[3]) <= SamkhaPeople.COURT[1], "%s within the court's hours" % c[0])
	for c in SamkhaPeople.GREAT_WARD:
		assert_lt(float(c[1]) + 4.0, float(c[2]), "%s in and waiting before it is called" % c[0])
		assert_lt(float(c[2]), float(c[3]), "%s called before it comes out" % c[0])
		assert_true(float(c[3]) <= SamkhaPeople.COURT[1], "%s out by the court's end" % c[0])
	for c in SamkhaPeople.GREAT_COURT + SamkhaPeople.GREAT_WARD:
		var path := PEOPLE % String(c[0])
		if not ResourceLoader.exists(path):
			fail_test("%s's body" % c[0])
			continue
		var n: Node = (load(path) as PackedScene).instantiate()
		var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
		assert_true(ap.has_animation("Sitting_Cross"), "%s sits cross-legged" % c[0])
		n.free()
	var bodies := {}
	for c in SamkhaPeople.COURT_PEOPLE + SamkhaPeople.GREAT_COURT:
		assert_false(bodies.has(String(c[0])), "no two alike in the hall: %s" % c[0])
		bodies[String(c[0])] = true


func test_loads_are_counted_at_the_table() -> void:
	var L := 90.0
	var at := 60.0
	var st := 600.0
	var v := SamkhaPeople.PER_MIN * SamkhaPeople.SPEED
	assert_almost_eq(SamkhaPeople.toll_s(st, st + 3.0, L, at, 1.5), 3.0 * v, 0.001, "walking up to the table")
	assert_almost_eq(SamkhaPeople.toll_s(st, st + at / v + 1.0, L, at, 1.5), at, 0.001, "stood at the table while the load is counted")
	assert_almost_eq(SamkhaPeople.toll_s(st, st + at / v + 2.0, L, at, 1.5), at + 0.5 * v, 0.001, "and on")
	assert_eq(SamkhaPeople.toll_s(st, st + L / v + 1.6, L, at, 1.5), -1.0, "gone")
	var counted := 0
	for c in SamkhaPeople.plan():
		if SamkhaPeople.TOLL_LOADS.has(String(c["load"])):
			counted += 1
			assert_between(float(c["start"]), 390.0, 990.0, "while Sherab keeps the table (06:30-16:45)")
	assert_gt(counted, 6, "the toll's traffic through the day (chapter 02, D04)")
	assert_eq(SamkhaPeople.ARGUE.size(), 2, "two of Ngödrup's men at 10:00 (chapter 05, NPC-39)")
