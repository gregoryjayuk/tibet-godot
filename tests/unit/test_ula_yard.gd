extends GutTest
## The ula yard SAM-09 and the castle's stables SAM-08 (M2 sprint 11, step 3; plan chapter 02, chapter 03, 5.3, chapter
## 05, A-57, chapter 06, 8.10): placed by the Castle Ramp's planner, the stables against the yard's uphill side at its
## level; the kit's yard walled, its gate, rings, mounting block, notice-post, the scribe's place and the count's; the
## stables' doors, loft door and the Pönpo's mule's place; world/ula_yard.gd's day: the animals in the yard by day, the
## afternoon's brought in at their minutes, the count at A-57's hours.

const RAMP := "res://data/castle_ramp.json"
const KIT := "res://assets/generated/kit/types/%s.json"
const UlaYard := preload("res://world/ula_yard.gd")


func _sockets(f: String) -> Array:
	return (JSON.parse_string(FileAccess.get_file_as_string(KIT % f))["sockets"] as Array).map(func(s): return String(s))


func test_placed_by_the_ramp() -> void:
	if not FileAccess.file_exists(RAMP):
		pending("no data/castle_ramp.json")
		return
	var pads: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RAMP))["pads"]
	assert_true(pads.has("SAM-09") and pads.has("SAM-08"), "the yard and the stables")
	var y: Dictionary = pads["SAM-09"]
	var s: Dictionary = pads["SAM-08"]
	assert_almost_eq(float(s["level"]), float(y["level"]), 0.01, "the stables at the yard's level, their doors into it")
	assert_almost_eq(float(s["facing"]), float(y["facing"]), 0.01, "facing the same way")
	var back := Vector2(sin(deg_to_rad(float(y["facing"]) + 180.0)), cos(deg_to_rad(float(y["facing"]) + 180.0)))
	var d := Vector2(float(s["at"][0]) - float(y["at"][0]), float(s["at"][1]) - float(y["at"][1]))
	assert_almost_eq(d.dot(back), 15.0, 0.05, "against the yard's back: half its 20 m and half the range's 10")
	assert_almost_eq(absf(d.cross(back)), 0.0, 0.05, "on its axis")


func test_the_kit() -> void:
	if not FileAccess.file_exists(KIT % "sam09_ula_yard_v1"):
		pending("no kit types: ../tibet-blender export_types.py --types sam08_stables,sam09_ula_yard")
		return
	var ys := _sockets("sam09_ula_yard_v1")
	assert_gte(ys.filter(func(n): return n.begins_with("SOCK_TIE_")).size(), 15, "tethering rings along its walls (chapter 03, 5.3)")
	assert_eq(ys.filter(func(n): return n.begins_with("SOCK_COUNT_")).size(), 3, "the headman's men's three places (A-57)")
	for k in ["SOCK_GATE_1", "SOCK_POST_1", "SOCK_MOUNT_1", "SOCK_TALLY_1"]:
		assert_has(ys, k, "the yard's %s" % k)
	var ss := _sockets("sam08_stables_v1")
	assert_gte(ss.filter(func(n): return n.begins_with("SOCK_DOOR_")).size(), 2, "its stable doors")
	assert_has(ss, "SOCK_LOFT_1", "the granary loft's loading door")
	assert_has(ss, "SOCK_MULE_1", "the Pönpo's mule's place")


func test_the_day() -> void:
	assert_true(UlaYard.shown(0.0, 7.0 * 60.0), "the overnight animals there in the morning")
	assert_true(UlaYard.shown(0.0, 15.0 * 60.0), "and in the afternoon")
	assert_false(UlaYard.shown(0.0, 22.0 * 60.0), "out of sight at night")
	assert_false(UlaYard.shown(950.0, 14.0 * 60.0), "an afternoon's animal not yet brought in")
	assert_true(UlaYard.shown(950.0, 16.0 * 60.0), "brought in by 16:00")
	assert_eq(UlaYard.COUNTS, [[450.0, 540.0], [930.0, 1020.0]], "the count at 07:30-09:00 and 15:30-17:00 (A-57)")
	var morning := UlaYard.TIED.filter(func(t): return String(t[0]) != "" and float(t[1]) <= 0.0).size()
	var all := UlaYard.TIED.filter(func(t): return String(t[0]) != "").size()
	assert_between(morning, 6, 12, "a few overnight")
	assert_between(all, 12, 22, "the yard fuller by the afternoon, never as full as the order (chapter 06, 8.10)")
