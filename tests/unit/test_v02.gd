extends GutTest
## V-02, the Conch Eddy at first sun (M2 sprint 5, step 6; plan chapter 08, V-02): the first sun on the confluence's pool
## on the terrain's minute through the horizon map's fine grid (chapter 08: "horizon map check that first sun lands",
## here 07:46:42 on the terrain: docs/terrain/sun-report.md), the moment's record, its quiet by the station, the pool's
## mist lifting over ten minutes from the first sun, the conch's glint only in its window.

const Horizon := preload("res://world/horizon.gd")
const Dawn := preload("res://world/confluence_dawn.gd")
const Moments := preload("res://world/moments.gd")
const BAKE := "res://assets/generated/terrain/horizon.json"


func after_each() -> void:
	Horizon.clear()


func _v02() -> Dictionary:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moments.json"))
	for m in d["moments"]:
		if String(m["id"]) == "V-02":
			return m
	return {}


func test_the_first_sun_lands_on_the_pool_on_its_minute() -> void:
	if not FileAccess.file_exists(BAKE):
		pending("no horizon map: run tools/py tools/terrain/horizon.py")
		return
	assert_true(Horizon.load_globals(), "the map loads")
	var g := Horizon.ground_at(210.0, -95.0)
	var eye := Vector3(210.0, g + 1.6, 95.0)  # Godot: the town's y north is -z
	var before := Calendar.minute_of(1903, 10, 28, 7, 45)
	var after := Calendar.minute_of(1903, 10, 28, 7, 48)
	assert_lt(Horizon.light_at(eye, Calendar.sun_direction(before)), 0.01, "the pool in shadow at 07:45")
	assert_gt(Horizon.light_at(eye, Calendar.sun_direction(after)), 0.99, "the first sun on it by 07:48 (the rays' 07:46:42)")


func test_the_moment_record() -> void:
	var m := _v02()
	assert_false(m.is_empty(), "V-02 in data/moments.json")
	var st: Array = m["stations"][0]["pos"]
	assert_lt(Vector2(float(st[0]), float(st[1])).distance_to(Vector2(199.0, -91.2)), 1.0, "its station at the terrace's lip by its corner")
	assert_true(Moments.window_open(m, 467.0), "its window open at the first sun, 07:47")
	assert_false(Moments.window_open(m, 420.0), "and shut at 07:00")
	assert_eq(String(m["sound_cue"]), "sc_conch_dawn", "its sound cue")
	assert_true((m["cue"] as Dictionary).has("near"), "the quiet by the station")


func test_the_mist_lifts_in_the_first_light() -> void:
	assert_gt(Dawn.mist_at(400.0).x, 0.0, "on the water before the first sun, 06:40")
	var mid := Dawn.mist_at(Dawn.FIRST_SUN + Dawn.LIFT / 2.0)
	assert_between(mid.x, 0.1 * Dawn.DENSE, 0.9 * Dawn.DENSE, "thinning five minutes in")
	assert_gt(mid.y, 0.0, "its top lifting")
	assert_eq(Dawn.mist_at(Dawn.FIRST_SUN + Dawn.LIFT + 1.0).x, 0.0, "gone after ten minutes")
	assert_eq(Dawn.mist_at(720.0).x, 0.0, "none at noon")


func test_the_conch_only_in_its_window() -> void:
	assert_false(Dawn.conch_shown(440.0), "not at 07:20")
	assert_true(Dawn.conch_shown(467.0), "at the first sun")
	assert_false(Dawn.conch_shown(600.0), "not at 10:00")
