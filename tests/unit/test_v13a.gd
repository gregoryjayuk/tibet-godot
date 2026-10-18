extends GutTest
## V-13a, Dungri Karpo in the notch (M2 sprint 6, step 5; plan chapter 08, V-13a; chapter 02, 2.7): the invented peak
## raised into the ring (tools/terrain/peak.py) at chapter 02's 5,420 m, 12.7 km from the Gorge Rim Lookout in the real
## gorge's notch (032.5 degrees: DECISIONS, 9 Oct 2026); seen from the Lookout and the Tsokchen roof, hidden from Tsongra
## (tools/terrain/terrain_check.py's lines); its summit in the sun after the town has gone into shadow; the moment's
## record.

const Horizon := preload("res://world/horizon.gd")
const Moments := preload("res://world/moments.gd")
const BAKE := "res://assets/generated/terrain/horizon.json"
const REPORT := "res://docs/terrain/terrain-report.md"
const SUMMIT := Vector2(7081.0, 10956.0)


func after_each() -> void:
	Horizon.clear()


func test_the_peak_in_the_ring() -> void:
	if not FileAccess.file_exists(BAKE):
		pending("no horizon map: run tools/terrain/build.sh")
		return
	assert_true(Horizon.load_globals(), "the map loads")
	var z := Horizon.ground_at(SUMMIT.x, SUMMIT.y) + 2662.0  # the map's heights over the datum
	assert_between(z, 5150.0, 5450.0, "its summit at chapter 02's 5,420 m (the ring's 128 m grid rounds it down)")
	var lookout := Vector2(258.0, 245.0)
	var d := SUMMIT - lookout
	assert_almost_eq(d.length(), 12700.0, 50.0, "12.7 km from the Lookout (chapter 08)")
	assert_almost_eq(fposmod(rad_to_deg(atan2(d.x, d.y)), 360.0), 32.5, 0.2, "in the real notch, 032.5 degrees")


func test_seen_from_the_lookout_hidden_from_tsongra() -> void:
	if not FileAccess.file_exists(REPORT):
		pending("no terrain report: run tools/terrain/build.sh")
		return
	var rows := FileAccess.get_file_as_string(REPORT).split("\n")
	for want in [["Gorge Rim Lookout V-13", "in the notch"], ["Tsongra (", "hidden"]]:  # (V-05 from the Tsokchen roof: ISS-153)
		var found := ""
		for r in rows:
			if r.begins_with("| " + String(want[0])) and r.contains("Dungri Karpo") and r.contains(String(want[1])):
				found = r
		assert_ne(found, "", "%s's line on Dungri Karpo" % want[0])
		assert_true(found.ends_with("as designed |"), "%s: %s" % [want[0], found.get_slice("|", 4).strip_edges()])


func test_its_summit_lit_after_the_town_is_in_shadow() -> void:
	if not FileAccess.file_exists(BAKE) or not FileAccess.file_exists("res://docs/terrain/sun-report.md"):
		pending("no horizon map or sun report")
		return
	assert_true(Horizon.load_globals(), "the map loads")
	var town := Vector3(0.0, Horizon.ground_at(0.0, 0.0) + 1.6, 0.0)
	var m := Calendar.minute_of(1903, 10, 30, 17, 8)
	assert_lt(Horizon.light_at(town, Calendar.sun_direction(m)), 0.01, "Tsongra in shadow at 17:08 (from 16:08)")
	# the summit's own last sun by its rays (tools/terrain/horizon.py's report; the shader lights the highest summits by the
	# sun alone, the ring's coarse map shading a sharp peak by itself): chapter 02's 17:17, its alpenglow from 17:05
	var row := ""
	for r in FileAccess.get_file_as_string("res://docs/terrain/sun-report.md").split("\n"):
		if r.begins_with("| Dungri Karpo summit"):
			row = r
	assert_ne(row, "", "the summit in the sun report")
	var last := row.get_slice("|", 9).strip_edges()  # its last sun by the rays, hh:mm:ss
	var mins := float(last.get_slice(":", 0)) * 60.0 + float(last.get_slice(":", 1)) + float(last.get_slice(":", 2)) / 60.0
	assert_almost_eq(mins, 17.0 * 60.0 + 17.0, 3.0, "its last sun at 17:17 (chapter 02, 2.8), by its rays: %s" % last)


func test_the_moment_record() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moments.json"))
	var v: Dictionary = {}
	for m in d["moments"]:
		if String(m["id"]) == "V-13a":
			v = m
	assert_false(v.is_empty(), "V-13a in data/moments.json")
	var st: Array = v["stations"][0]["pos"]
	assert_lt(Vector2(float(st[0]), float(st[1])).distance_to(Vector2(258.8, 246.7)), 1.0, "its station at the terrace's tip")
	assert_true(Moments.window_open(v, 17.0 * 60.0 + 8.0), "its window open at 17:08")
	assert_false(Moments.window_open(v, 16.0 * 60.0), "and shut at 16:00")
	assert_eq(String(v["sound_cue"]), "sc_notch_dusk", "its sound cue (chapter 08)")
