extends GutTest
## Who is on the 1,080 steps (M3 sprint 1, step 5; world/steps_people.gd): the rosary's rounds along the way, a pilgrim
## standing at each; a climber's pace on the flights; the day's people on the steps by the hour, the monks down in the
## morning and up in the afternoon; the Double Ninth party on its day only, at its places on landing 6's platform and
## terrace from about 14:00 to 16:00, clear of the way; the rosary's sound.

const People := preload("res://world/steps_people.gd")
const Town := preload("res://world/town.gd")
const STEPS := "res://data/dungrong.json"


func _scene() -> Node3D:
	var sp: Node3D = People.new()
	add_child_autofree(sp)
	sp.build(null)
	return sp


func test_the_rounds_of_the_rosary() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json (tools/py tools/town/dungrong.py)")
		return
	var sp := _scene()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STEPS))
	var z0 := Town.to_godot(0.0, 0.0, float(d["foot"]["z"])).y
	assert_eq(sp.pauses.size(), 9, "nine stands: the end of each round of 108 but the tenth, at the gate")
	for k in sp.pauses.size():
		var q: Vector3 = People._at(sp.way_up, sp.cum_up, sp.pauses[k])
		assert_almost_eq(q.y - z0, (k + 1) * 108 * 0.195, 0.01, "round %d ends at its 108th step's rise" % (k + 1))
		if k > 0:
			assert_gt(sp.pauses[k], sp.pauses[k - 1], "in order up the way")


func test_a_pilgrims_climb() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json")
		return
	var sp := _scene()
	var tl: Array = sp._tl["pilgrim:up"]
	var ts: PackedFloat32Array = tl[0]
	var total: float = ts[ts.size() - 1]
	assert_between(total, 15.0 * 60.0, 30.0 * 60.0, "a pilgrim's climb from Pema Ö's forecourt to the gate: %.1f real minutes" % (total / 60.0))
	var at := People.time_at(tl, sp.pauses[0])
	assert_almost_eq(People.s_at(tl, at + People.PAUSE / 2.0).x, sp.pauses[0], 0.01, "standing at the first round's end")
	assert_eq(People.s_at(tl, at + People.PAUSE / 2.0).y, 0.0, "still")
	assert_gt(People.s_at(tl, at + People.PAUSE + 2.0).x, sp.pauses[0], "and on")
	var mon: Array = sp._tl["monk:up"]
	assert_lt(float((mon[0] as PackedFloat32Array)[(mon[0] as PackedFloat32Array).size() - 1]), total, "a monk climbs without standing")
	var mid := People.s_at(tl, 300.0)
	assert_between(mid.y, 0.4, 0.9, "a pilgrim's pace a climber's or a walker's")


func test_the_day_on_the_steps() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json")
		return
	var sp := _scene()
	var count := func(m: float) -> int:
		var n := 0
		for p in sp.people:
			if bool(sp.where(p, m)[0]):
				n += 1
		return n
	assert_eq(count.call(180.0), 0, "03:00 nobody on the steps")
	assert_gte(count.call(510.0), 4, "08:30 pilgrims and monks on them")
	assert_gte(count.call(900.0), 3, "15:00 some coming down, the monks going up")
	assert_eq(count.call(1300.0), 0, "21:40 nobody")
	var down_am := 0
	var up_pm := 0
	for p in sp.people:
		if String(p["kind"]) != "monk":
			continue
		for tr in p["trips"]:
			if String(tr[0]) == "down" and float(tr[1]) < 600.0:
				down_am += 1
			if String(tr[0]) == "up" and float(tr[1]) > 720.0:
				up_pm += 1
	assert_eq(down_am, 3, "the monks down in the morning")
	assert_eq(up_pm, 3, "and up in the afternoon")
	for p in sp.people:
		var trips: Array = p["trips"]
		if trips.size() == 2:
			var tl: Array = sp._tl[String(p["kind"]) + ":" + String(trips[0][0])]
			var ts: PackedFloat32Array = tl[0]
			assert_gt(float(trips[1][1]), float(trips[0][1]) + ts[ts.size() - 1] / People.PER_MIN, "%s back only after the first way's done" % p["key"])
	var counting := 0
	for m in range(400, 1000, 5):
		for p in sp.people:
			var r: Array = sp.where(p, float(m))
			if bool(r[0]) and bool(r[5]):
				counting += 1
	assert_gt(counting, 50, "pilgrims climbing with their rosaries through the day")


func test_the_double_ninth_party() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json")
		return
	assert_true(People.party_day(Calendar.minute_of(1903, 10, 28, 14, 0)), "28 October 1903, the Double Ninth")
	assert_false(People.party_day(Calendar.minute_of(1903, 10, 29, 14, 0)), "not the 29th")
	var sp := _scene()
	assert_eq(sp.party.size(), 12, "a dozen (chapter 02, 8.3)")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STEPS))
	var walk := PackedVector2Array()
	for q in d["walk"]:
		walk.append(Vector2(float(q[0]), float(q[1])))
	var six := {}
	for lg in d["landings"]:
		if int(lg["number"]) == 6:
			six = lg
	var plat := PackedVector2Array()
	for q in six["corners"]:
		plat.append(Vector2(float(q[0]), float(q[1])))
	var t12: Array = d["places"]["RNG-12"]["at"]
	var tc := Vector2(float(t12[0]), float(t12[1]))
	var sitting := 0
	for pp in sp.party:
		assert_false(bool(sp.party_where(pp, 805.0)[0]), "13:25 not yet set out")
		var r: Array = sp.party_where(pp, 880.0)
		assert_true(bool(r[0]), "14:40 at landing 6")
		assert_eq(String(r[3]), String(pp["place"][2]), "%s in his place" % pp["role"])
		var g: Vector3 = r[1]
		var q := Vector2(g.x, -g.z)  # (the town grid: Town.to_godot's x, -y)
		if String(pp["role"]) == "view":
			assert_lt(maxf(absf((q - tc).x), absf((q - tc).y)), 5.7, "on the chorten's terrace (8 x 8 m, turned)")
		else:
			assert_true(Geometry2D.is_point_in_polygon(q, plat), "%s on landing 6's platform" % pp["role"])
			var near := INF
			for i in range(1, walk.size()):
				near = minf(near, Geometry2D.get_closest_point_to_segment(q, walk[i - 1], walk[i]).distance_to(q))
			assert_gt(near, 0.6, "%s clear of the way across it" % pp["role"])
		if String(r[3]) == "Sitting_Cross":
			sitting += 1
		assert_false(bool(sp.party_where(pp, 1080.0)[0]), "18:00 gone home")
	assert_eq(sitting, 8, "eight in the ring")
	assert_eq(String(sp.party_where(sp.party[0], 845.0)[3]).begins_with("Walk"), true, "14:05 the first still climbing or arriving")


func test_the_rosary_heard() -> void:
	var snd: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sound.json"))
	var rec: Dictionary = (snd.get("sounds", snd) as Dictionary).get(People.ROSARY, {})
	assert_false(rec.is_empty(), "SND-117 in data/sound.json (tools/audio/sound_data.py)")
	assert_eq((rec.get("files", []) as Array).size(), 4, "four runs of beads")
