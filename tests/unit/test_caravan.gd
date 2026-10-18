extends GutTest
## The caravan CV-02's ten yak for Dechen-tsang (M1 sprint 6, step 5; chapter 06, 8.4-8.5; chapter 12, M1's acceptance 1:
## "At the Yak Gate at 15:15, watch the ten yak come up the ramp below ... follow them through Dechen-tsang's passage one
## at a time"): worked out once from the street graph's way (world/caravan.gd), they come up the north ramp through the
## Yak Gate after 15:15, go one at a time through the passage, stand in Yard 0 before 16:00, lose their loads to the
## platform by 16:40 and are gone to the camp by 17:20; the drovers are placed with them and hidden before and after.

const Caravan := preload("res://world/caravan.gd")
const Named := preload("res://characters/named.gd")
const STREETS := "res://assets/generated/terrain/street_graph.json"
const CROWD: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]

var keep := {}
var cv: Node3D
var named: Node3D


func before_all() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}


func before_each() -> void:
	WorldClock.frozen = true
	if not FileAccess.file_exists(STREETS):
		return
	TownSim.setup_walkers(STREETS, CROWD)
	named = Named.new()
	add_child_autofree(named)
	named.setup(TownSim, null)
	cv = Caravan.new()
	add_child_autofree(cv)


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]


func _ready_caravan() -> bool:
	if not FileAccess.file_exists(STREETS):
		pending("no street graph (tools/town/graph.py)")
		return false
	if not cv.setup(TownSim, named, JSON.parse_string(FileAccess.get_file_as_string(STREETS))):
		pending("no caravan's way or no yak")
		return false
	return true


## The first game minute a knot list reaches s.
static func _when(knots: Array, s: float) -> float:
	for k in knots:
		if (k as Vector2).y >= s:
			return (k as Vector2).x
	return INF


func test_the_arrival() -> void:
	if not _ready_caravan():
		return
	var lead: Array = cv.yaks[0]["knots"]
	var last: Array = cv.yaks[cv.N - 1]["knots"]
	assert_between(_when(lead, cv.gate_s), 915.0, 930.0, "the lead through the Yak Gate between 15:15 and 15:30")
	assert_lt(_when(last, cv.gate_s), 945.0, "the last through it before 15:45")
	assert_eq(int(cv.in_passage_most), 1, "one at a time through the passage")
	for i in cv.N:
		var kn: Array = cv.yaks[i]["knots"]
		assert_lt((kn[kn.size() - 1] as Vector2).x, 960.0, "yak %d in its place in Yard 0 before 16:00" % i)


func test_the_unloading_and_home() -> void:
	if not _ready_caravan():
		return
	assert_lt(cv.UNLOAD + cv.UNLOAD_EVERY * (cv.N - 1), cv.LEAVE, "every load off before they set off home")
	assert_lt(cv.done_minute, 1040.0, "all gone to the camp by 17:20")
	WorldClock.minute = 7.0 * 1440.0 + 16.5 * 60.0
	cv.update(Vector3.ZERO)
	var shown := 0
	for y in cv.yaks:
		shown += 1 if (y["node"] as Node3D).visible else 0
	assert_eq(shown, cv.N, "all ten in Yard 0 at 16:30")
	assert_false((cv.yaks[0]["load"] as Node3D).visible, "the lead's load on the platform")
	WorldClock.minute = 7.0 * 1440.0 + 14.5 * 60.0
	cv.update(Vector3.ZERO)
	assert_true((cv.yaks[0]["node"] as Node3D).visible, "at 14:30 on its way by the Serchu road, down the south ramp (M2 sprint 3)")
	WorldClock.minute = 7.0 * 1440.0 + 9.5 * 60.0
	cv.update(Vector3.ZERO)
	assert_false((cv.yaks[0]["node"] as Node3D).visible, "at 09:30 not yet come (it sets out on the north bank's road about 10:20: M2 sprint 12, step 6)")


func test_it_comes_by_the_serchu_road() -> void:
	if not _ready_caravan():
		return
	assert_gt(cv.road_s, 1700.0, "the road before the deck: the north bank's road, the Serchu Zampa, R-01 down the south bank, SER-20, the gallery, the chorten, the toll, the south ramp")
	assert_between(cv.start, 600.0, 640.0, "setting out on the north bank's road about 10:20, worked back from the deck (ISS-137; M2 sprint 12, step 6)")
	var lead: Dictionary = cv.yaks[0]
	assert_almost_eq(_when(lead["knots"], cv.road_s), cv.ARRIVE, 1.0, "on the lower bridge's deck at 14:55, as before the road")
	var p: Vector3 = cv._at(lead["path"], lead["cum"], 240.0)  # 240 m on: over the Serchu Zampa (its deck 230-250 m)
	var g := Vector3(p.x, -p.z, p.y + 2662.0)
	assert_lt(Vector2(g.x - 1250.0, g.y + 520.0).length(), 12.0, "240 m on, on the Zampa's deck")
	var gal: Vector3 = cv._at(lead["path"], lead["cum"], 1250.0)  # and on the cliff gallery after the road's 1,140 m
	assert_between(gal.x, 285.0, 420.0, "1,250 m on, on the gallery")


func test_the_drovers_go_with_it() -> void:
	if not _ready_caravan():
		return
	var d: int = cv.drovers[0]
	assert_gt(d, -1, "the drover is one of the twenty")
	WorldClock.minute = 7.0 * 1440.0 + 15.3 * 60.0
	cv.update(Vector3.ZERO)
	assert_true(named.overrides.has(d), "placed by the caravan while it is out")
	var lead: Vector3 = (cv.yaks[0]["node"] as Node3D).position
	assert_lt((named.overrides[d]["pos"] as Vector3).distance_to(lead), 3.0, "at the lead's head")
	WorldClock.minute = 7.0 * 1440.0 + 18.0 * 60.0
	cv.update(Vector3.ZERO)
	assert_false(named.overrides.has(d), "back to his day (at the camp) once it is home")
