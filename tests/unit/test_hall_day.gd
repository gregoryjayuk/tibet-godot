extends GutTest
## The Tsokchen's day and the Labrang's (M3 sprint 6, step 3; plan chapter 04, 3.1 and 3.8; chapter 08, V-26;
## world/hall_day.gd, world/assembly.gd): the good days' morning assembly; a path walked; the spans through midnight;
## a lay visitor's visit (three prostrations at the door, then round the Nangkor, gone at its end).

const HallDay := preload("res://world/hall_day.gd")
const Assembly := preload("res://world/assembly.gd")


func test_the_good_days_morning_assembly() -> void:
	assert_eq(Assembly.session_at(600.0, true), Assembly.GOOD_SESSION, "10:00 on a good day: the morning assembly (V-26)")
	assert_eq(Assembly.session_at(600.0, false), -1, "10:00 on any other day: the hall empty but for its pilgrims")
	assert_eq(Assembly.session_at(345.0, true), 0, "the dawn assembly as ever")


func test_along_a_path() -> void:
	var path := [Vector3(0, 0, 0), Vector3(0, 0, -10), Vector3(5, 0, -10)]
	assert_almost_eq(HallDay.length_of(path), 15.0, 0.001, "its length")
	var w := HallDay.along(path, 12.0)
	assert_almost_eq((w[0] as Vector3).x, 2.0, 0.001, "12 m on: round the corner")
	assert_false(bool(w[2]), "not yet at its end")
	assert_true(bool(HallDay.along(path, 20.0)[2]), "past its end: done")


func test_spans() -> void:
	assert_true(HallDay.in_span(1200.0, HallDay.SHUT), "20:00: the door shut")
	assert_true(HallDay.in_span(120.0, HallDay.SHUT), "02:00: still shut")
	assert_false(HallDay.in_span(600.0, HallDay.SHUT), "10:00: open")
	assert_true(HallDay.in_span(480.0, HallDay.CLEAN), "08:00: the sweepers")


func test_a_lay_visitors_visit() -> void:
	var h := HallDay.new()
	var hall := Node3D.new()
	add_child_autofree(hall)
	add_child_autofree(h)
	h.hall = hall
	var at_door: Array = h.pilgrim_at(0.1)
	assert_eq(String(at_door[2]), "Greeting", "at the door, hands joined first")
	assert_eq(String(h.pilgrim_at(0.3)[2]), "Crouch_Idle", "then down on the knees")
	var going: Array = h.pilgrim_at(8.0)
	assert_eq(String(going[2]), "Walk", "then round the hall")
	assert_true(h.pilgrim_at(HallDay.PILGRIM_CYCLE - 0.1).is_empty(), "and gone before the next comes in")


func test_v26_only_on_the_good_days() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moments.json"))
	var v26 := {}
	for m in data["moments"]:
		if String(m.get("id", "")) == "V-26":
			v26 = m
	assert_false(v26.is_empty(), "V-26 is in data/moments.json")
	var Moments := preload("res://world/moments.gd")
	var keep := WorldClock.minute
	var good := -1
	var other := -1
	for d in range(0, 40):  # a good day and another from the calendar's first weeks
		var m := float(d) * 1440.0 + 600.0
		if Assembly.good_day(m) and good < 0:
			good = d
		elif not Assembly.good_day(m) and other < 0:
			other = d
	assert_true(good >= 0 and other >= 0, "the calendar has both")
	WorldClock.minute = float(good) * 1440.0 + 600.0
	assert_true(Moments.window_open(v26, 600.0), "10:00 on a good day: open")
	assert_false(Moments.window_open(v26, 700.0), "11:40: over")
	WorldClock.minute = float(other) * 1440.0 + 600.0
	assert_false(Moments.window_open(v26, 600.0), "10:00 on another day: the hall has no assembly to see")
	WorldClock.minute = keep


func test_inside_the_hall() -> void:
	assert_true(HallDay.inside_hall(Vector3(0.0, 0.1, 10.0)), "among the rows")
	assert_true(HallDay.inside_hall(Vector3(-11.5, 0.1, -14.5)), "in the Nangkor's far corner")
	assert_false(HallDay.inside_hall(Vector3(0.0, 0.1, 18.0)), "on the porch")
	assert_false(HallDay.inside_hall(Vector3(0.0, 20.0, 0.0)), "on the roof")


func test_the_general_teas_guest() -> void:
	var HallTea := preload("res://world/hall_tea.gd")
	assert_true(HallTea.tea_on(7.0 * 1440.0 + 670.0), "11:10: the general tea, the novice serves the guest's place")
	assert_false(HallTea.tea_on(7.0 * 1440.0 + 720.0), "12:00: over")
	assert_eq(HallTea.lesson_of(0.3, 1, true), "left_a_little", "refilled, enough, a little left: as a guest does")
	assert_eq(HallTea.lesson_of(0.0, 2, true), "drained", "the bowl drained")
	assert_eq(HallTea.lesson_of(0.9, 0, true), "refused", "covered at the first pour")
	var a: Node3D = autofree(Assembly.new())
	assert_false(a.taken(Assembly.GUEST_SEAT, Assembly.GENERAL, false), "the guest's place is kept free at the general tea")
