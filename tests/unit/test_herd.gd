extends GutTest
## CV-02's whole herd (M2 sprint 9, step 2; plan chapter 06, 8.4: "72 yak at about 3 m apart make a string 220 m long";
## chapter 12's M2: "all 72 yak of CV-02 down the Caravan Ramp"): world/herd.gd's 62 behind world/caravan.gd's ten, in
## file on the cliff gallery, abreast on the road, two abreast down the Caravan Ramp, each to its spot in the block by
## the windbreaks; never into the ten, never two in one place, on their way at their paces; world/camp.gd's CV-02 things
## after the herd's halt.

const Caravan := preload("res://world/caravan.gd")
const Herd := preload("res://world/herd.gd")
const Camp := preload("res://world/camp.gd")
const Named := preload("res://characters/named.gd")
const STREETS := "res://assets/generated/terrain/street_graph.json"
const CROWD: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]

var keep := {}
var cv: Node3D
var herd: Node3D


func before_all() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}


func before_each() -> void:
	WorldClock.frozen = true
	if not FileAccess.file_exists(STREETS):
		return
	TownSim.setup_walkers(STREETS, CROWD)
	var named := Named.new()
	add_child_autofree(named)
	named.setup(TownSim, null)
	cv = Caravan.new()
	add_child_autofree(cv)
	herd = Herd.new()
	add_child_autofree(herd)


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]


func _ready_herd() -> bool:
	if not FileAccess.file_exists(STREETS):
		pending("no street graph (tools/town/graph.py)")
		return false
	if not cv.setup(TownSim, null, JSON.parse_string(FileAccess.get_file_as_string(STREETS))):
		pending("no caravan's way or no yak")
		return false
	if not herd.setup(cv):
		pending("no yak_laden (../tibet-blender people2/stand_ins.py -- yak) or no caravan_ground.json")
		return false
	return true


func test_all_of_them_to_the_camp() -> void:
	if not _ready_herd():
		return
	assert_eq((herd.get("yaks") as Array).size(), 62, "the 62 beside the ten: CV-02's 72")
	var halt: float = herd.get("halt_minute")
	var done: float = herd.get("done_minute")
	assert_gt(halt, float(herd.get("start")), "the lead halts after it sets out")
	assert_between(done - halt, 2.0, 60.0, "the block filled within the hour")
	gut.p("herd: set out %.1f, the lead halted %.1f, the last %.1f" % [float(herd.get("start")), halt, done])
	assert_almost_eq(halt, Camp.DEFAULT_HALT, 6.0, "camp.gd's CV-02 things wait for the herd as it is worked out")
	for i in 62:
		var y: Dictionary = herd.get("yaks")[i]
		var cum: PackedFloat32Array = y["cum"]
		assert_almost_eq(Herd._s_at(y["knots"], done + 1.0), cum[cum.size() - 1], 0.05, "yak %d in its spot" % i)


func test_behind_the_ten_and_in_order() -> void:
	if not _ready_herd():
		return
	var ten: Array = cv.get("yaks")
	var tail: Array = (ten[ten.size() - 1] as Dictionary)["knots"]
	var junction: float = herd.get("junction_s")
	var yaks: Array = herd.get("yaks")
	for m in range(int(herd.get("start")), int(herd.get("halt_minute")), 3):
		var lead := Herd._s_at(yaks[0]["knots"], float(m))
		var t := Caravan._s_at(tail, float(m))
		if t < junction:
			assert_lte(lead, t - Herd.GAP + 0.01, "the herd's lead behind the ten's last at %d" % m)
		for i in range(1, 62):
			var a := Herd._s_at(yaks[i - 1]["knots"], float(m))
			var b := Herd._s_at(yaks[i]["knots"], float(m))
			if a < float((herd.get("shared_cum") as PackedFloat32Array)[(herd.get("shared_cum") as PackedFloat32Array).size() - 1]):
				assert_lte(b, a + 0.01, "yak %d never past yak %d on the way, at %d" % [i, i - 1, m])


func test_in_file_on_the_gallery_and_abreast_after() -> void:
	if not _ready_herd():
		return
	var g: Vector2 = herd.get("gallery")
	assert_gt(g.y, g.x, "the gallery found along the way")
	assert_almost_eq(herd.breadth_at((g.x + g.y) / 2.0), 0.0, 0.01, "in file on the gallery's planks")
	var j: float = herd.get("junction_s")
	assert_gt(herd.breadth_at(j - 30.0), 4.0, "four abreast on the road to the south pavilion")
	assert_almost_eq(herd.breadth_at(j + 60.0), 1.6, 0.01, "two abreast down the ramp")
	assert_almost_eq(Herd.gap_for(0.0), Herd.GAP, 0.001, "3 m apart in file")
	assert_almost_eq(Herd.gap_for(4.8), Herd.GAP / 4.0, 0.001, "a rank of four")


func test_never_two_in_one_place() -> void:
	if not _ready_herd():
		return
	var halt: float = herd.get("halt_minute")
	for m in [float(herd.get("start")) + 40.0, float(herd.get("start")) + 100.0, halt - 20.0, halt + 30.0]:
		var ps := []
		for i in 62:
			var q: Array = herd.place_of(i, m)
			if q[3]:
				ps.append(q[0])
		var closest := 99.0
		for a in ps.size():
			for b in range(a + 1, ps.size()):
				closest = minf(closest, Vector2((ps[a] as Vector3).x - (ps[b] as Vector3).x, (ps[a] as Vector3).z - (ps[b] as Vector3).z).length())
		assert_gt(closest, 0.6, "no two yak within 0.6 m at %.0f (%d seen)" % [m, ps.size()])


func test_seen_only_once_out() -> void:
	if not _ready_herd():
		return
	var q: Array = herd.place_of(0, float(herd.get("start")) - 30.0)
	assert_false(q[3], "not yet on this side of the gallery")
	var night: Array = herd.place_of(61, Herd.day_minute(2.0 * 60.0))
	assert_true(night[3], "still standing in the block at 02:00")
	assert_false(night[2], "at rest")
