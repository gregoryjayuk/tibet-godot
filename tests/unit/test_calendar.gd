extends GutTest
## Spike S13 (plan chapter 11, 15.4): the calendar is correct or the game is wrong. The season's dates (chapter 01, 3.2),
## the dawn rule (15.2), the runtime sun against chapter 02's table 2.8 (within 0.2 deg and one minute; azimuths,
## given to the whole degree there, within 0.7) and the moon of chapter 01 (3.3). The same checks run on the build
## tool in tools/calendar/test_tibcal.py; Janson's Table 1, the Qing dates and Skyfield wait for IMP-005.


func _tib(y: int, mo: int, d: int, hh: int = 12, mm: int = 0) -> String:
	var t := Calendar.tibetan_date(Calendar.minute_of(y, mo, d, hh, mm))
	return "%d/%d" % [t.get("month", 0), t.get("day", 0)]


func test_the_year_is_loaded() -> void:
	assert_eq(Calendar._days.size(), 354, "a Tibetan year of 354 civil days")
	assert_eq(Calendar._days[0]["date"], "1903-02-28", "from Losar, Saturday 28 February 1903")
	assert_eq(Calendar._days[-1]["date"], "1904-02-16", "to the year's last day, Tuesday 16 February 1904")
	assert_eq(Calendar.minute_of(1903, 10, 21), 0.0, "game minute 0 is 00:00 on 21 October 1903")
	assert_eq(int(Calendar.year["year_of_rabjung"]), 37, "the 37th year of the rab byung")


func test_the_season() -> void:
	assert_eq(_tib(1903, 2, 28), "1/1", "Losar")
	assert_eq(_tib(1903, 10, 5), "8/14", "Mid-Autumn")
	assert_eq(_tib(1903, 10, 21), "9/1", "the season opens on the new moon")
	assert_eq(_tib(1903, 10, 28), "9/8", "the default day")
	assert_eq(_tib(1903, 11, 5), "9/15", "the full moon")
	assert_eq(_tib(1903, 11, 11), "9/22", "Lhabab Düchen")
	assert_eq(_tib(1903, 12, 13), "10/25", "Ganden Ngamchö")
	assert_eq(_tib(1903, 11, 1) + _tib(1903, 11, 2), "9/129/12", "9/12 doubled on 1-2 November")
	assert_eq(Calendar.tibetan_date(Calendar.minute_of(1903, 11, 1, 12))["doubled"], "first", "the first of the pair is marked")
	assert_eq(_tib(1903, 11, 6) + " " + _tib(1903, 11, 7), "9/16 9/17", "9/18 is skipped, so 9/17 and 9/19 are neighbours...")
	assert_eq(_tib(1903, 11, 8), "9/19", "...9/19 follows 9/17")
	assert_true("good_day" in Calendar.flags(Calendar.minute_of(1903, 10, 28, 12)), "the 8th is a good day")
	assert_true("EV-DD" in Calendar.flags(Calendar.minute_of(1903, 10, 28, 12)), "the default day's schedule")
	assert_true("lhabab_duchen" in Calendar.flags(Calendar.minute_of(1903, 11, 11, 12)), "the festival's flag")


func test_the_qing_dates() -> void:
	var q := Calendar.chinese_date(Calendar.minute_of(1903, 10, 28, 12))
	assert_eq("%d/%d" % [q.get("month", 0), q.get("day", 0)], "9/9", "the default day is the Double Ninth")
	assert_true("double_ninth" in Calendar.flags(Calendar.minute_of(1903, 10, 28, 12)), "and flagged as such")
	assert_eq(String(Calendar.chinese_date(Calendar.minute_of(1903, 10, 24, 12)).get("term", "")), "霜降", "Frost's Descent on 24 October")
	assert_eq(int(Calendar.chinese_date(Calendar.minute_of(1903, 11, 11, 12)).get("day", 0)), 23, "Lhabab Düchen is Qing 9/23")
	assert_true("market_zh" in Calendar.flags(Calendar.minute_of(1903, 10, 28, 12)), "the 9th is one of Hejie's market days")
	assert_true(Calendar.chinese_date(Calendar.minute_of(1904, 1, 2, 12)).is_empty(), "no Qing dates for 1904 yet")


func test_the_tibetan_day_begins_at_dawn() -> void:
	assert_eq(_tib(1903, 11, 11, 4, 30), "9/21", "a lamp lit at 04:30 on 11 November belongs to 9/21, the eve")
	assert_eq(_tib(1903, 11, 11, 5, 30), "9/22", "after dawn it is 9/22")
	assert_eq(Calendar.clock(Calendar.minute_of(1903, 10, 28, 16, 10)), "16:10", "the clock reads local mean time")


func _cross(y: int, mo: int, d: int, from_min: int, to_min: int, h0: float, moon := false) -> float:
	var prev := INF
	var base := Calendar.minute_of(y, mo, d)
	for m in range(from_min, to_min + 1):
		var a := (Calendar.moon_alt_az(base + m).x if moon else Calendar.sun_alt_az(base + m).x) - h0
		if prev != INF and (prev < 0.0) != (a < 0.0):
			return m - 1 + prev / (prev - a)
		prev = a
	return -1.0


func test_the_sun_on_the_default_day() -> void:
	var rise := _cross(1903, 10, 28, 300, 480, -0.833)
	var sset := _cross(1903, 10, 28, 960, 1140, -0.833)
	var dusk := _cross(1903, 10, 28, 1020, 1200, -6.0)
	gut.p("sun on 28 October at the site: rise %.1f, set %.1f, civil dusk %.1f (minutes LMT)" % [rise, sset, dusk])
	assert_almost_eq(rise, 370.0, 1.0, "rises at 06:10")
	assert_almost_eq(sset, 1037.0, 1.0, "sets at 17:17")
	assert_almost_eq(dusk, 1062.0, 1.0, "civil twilight ends at 17:42")
	var base := Calendar.minute_of(1903, 10, 28)
	assert_almost_eq(Calendar.sun_alt_az(base + 703).x, 47.3, 0.2, "47.3 deg at noon, 11:43")
	var table := [[420, 9.5, 111], [480, 21.3, 120], [540, 31.9, 131], [600, 40.5, 146], [660, 46.0, 164],
		[780, 43.5, 206], [840, 36.1, 222], [900, 26.3, 235], [960, 15.0, 245], [1020, 2.9, 253]]
	for row in table:
		var aa := Calendar.sun_alt_az(base + row[0])
		assert_almost_eq(aa.x, float(row[1]), 0.2, "altitude at %s" % Calendar.clock(base + row[0]))
		assert_almost_eq(aa.y, float(row[2]), 0.7, "azimuth at %s" % Calendar.clock(base + row[0]))
	var noon := Calendar.sun_direction(base + 703)
	assert_almost_eq(noon.x, 0.0, 0.01, "at noon the sun stands due south: no east-west part")
	assert_almost_eq(noon.z, cos(deg_to_rad(47.3)), 0.01, "south is +Z (north is -Z), 47.3 deg up")


func test_the_moon_on_the_default_day() -> void:
	var lit := Calendar.moon_illumination(Calendar.minute_of(1903, 10, 28, 20))
	assert_between(lit, 0.45, 0.57, "half lit on the default evening (%.2f)" % lit)
	var mset := _cross(1903, 10, 28, 1320, 1500, -0.833, true)
	gut.p("moon on 28 October: sets %.1f minutes LMT" % mset)
	assert_almost_eq(mset, 1420.0, 15.0, "sets at about 23:40")
	assert_gt(Calendar.moon_illumination(Calendar.minute_of(1903, 11, 5, 20)), 0.98, "full on 5 November")
