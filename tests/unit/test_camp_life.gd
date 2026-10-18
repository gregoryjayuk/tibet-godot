extends GutTest
## The camp at dusk (M2 sprint 9, step 3; plan chapter 06, 8.6): world/herd.gd's 62 unloaded where they halted, then to
## the hay or lying down in twos and threes; world/camp_animals.gd's CV-01, picket line and corral by the clock; world/
## camp.gd's fires lit at their hours; the camp's beasts never on top of one another.

const Caravan := preload("res://world/caravan.gd")
const Herd := preload("res://world/herd.gd")
const Camp := preload("res://world/camp.gd")
const CampAnimals := preload("res://world/camp_animals.gd")
const Named := preload("res://characters/named.gd")
const STREETS := "res://assets/generated/terrain/street_graph.json"
const DATA := "res://data/caravan_ground.json"
const CROWD: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]

var keep := {}


func before_all() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]


func _herd() -> Node3D:
	if not FileAccess.file_exists(STREETS):
		return null
	TownSim.setup_walkers(STREETS, CROWD)
	var named := Named.new()
	add_child_autofree(named)
	named.setup(TownSim, null)
	var cv: Node3D = Caravan.new()
	add_child_autofree(cv)
	if not cv.setup(TownSim, null, JSON.parse_string(FileAccess.get_file_as_string(STREETS))):
		return null
	var h: Node3D = Herd.new()
	add_child_autofree(h)
	return h if h.setup(cv) else null


func test_unloaded_then_to_the_hay_or_lying() -> void:
	var h := _herd()
	if h == null:
		pending("no caravan, street graph or yak_laden")
		return
	var halt: float = h.get("halt_minute")
	var states := {}
	for i in Herd.N:
		var q: Array = h.place_of(i, halt - 1.0)
		if q[3] and Herd._s_at(h.get("yaks")[i]["knots"], halt - 1.0) >= 0.0:
			assert_ne(String(q[4]), "free", "yak %d still laden before the halt" % i)
	for i in Herd.N:
		var q: Array = h.place_of(i, halt + 60.0)
		states[String(q[4])] = int(states.get(String(q[4]), 0)) + 1
	assert_eq(int(states.get("laden", 0)), 0, "every load off within the hour: %s" % str(states))
	assert_gt(int(states.get("eat", 0)) + int(states.get("lie", 0)), 50, "most at the hay or lying by then: %s" % str(states))
	var lying := 0
	for i in Herd.N:
		var q: Array = h.place_of(i, 21.0 * 60.0)
		if String(q[4]) == "lie":
			lying += 1
	assert_eq(lying, Herd.N, "all lying and chewing by 21:00")
	assert_almost_eq(float(h.place_of(0, Herd.day_minute(1.0 * 60.0))[3]), 1.0, 0.01, "still there at 01:00")


func test_the_camps_beasts_apart() -> void:
	var an: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))["animals"]
	var ps: Array = []
	for k in ["cv02_hay", "cv02_lie", "cv01", "corral"]:
		for q in an[k]:
			ps.append(Vector2(float(q[0]), float(q[1])))
	for q in an["picket"]:
		ps.append(Vector2(float(q[1]), float(q[2])))
	assert_eq((an["cv02_hay"] as Array).size() + (an["cv02_lie"] as Array).size(), 62, "a place for each of CV-02's 62")
	assert_eq((an["cv01"] as Array).size(), 60, "CV-01's 60 yak")
	assert_eq((an["picket"] as Array).filter(func(q): return q[0] == "mule").size(), 12, "twelve mules on the picket line")
	assert_eq((an["picket"] as Array).filter(func(q): return q[0] == "pony").size(), 9, "nine ponies")
	assert_eq((an["picket"] as Array).filter(func(q): return q[0] == "mastiff").size(), 2, "a mastiff at each end")
	assert_eq((an["corral"] as Array).size(), 8, "the hirer's eight mules")
	var closest := 99.0
	for a in ps.size():
		for b in range(a + 1, ps.size()):
			closest = minf(closest, (ps[a] as Vector2).distance_to(ps[b]))
	assert_gt(closest, 0.7, "no two beasts within 0.7 m of each other's middles")


func test_by_the_clock() -> void:
	assert_eq(String(CampAnimals.state_of("cv01_eat", 9.0 * 60.0, 0)[0]), "", "CV-01 still at the river at 09:00")
	assert_eq(String(CampAnimals.state_of("cv01_eat", 12.0 * 60.0, 0)[0]), "Eating", "at its hay at noon")
	assert_true(bool(CampAnimals.state_of("cv01_lie", 17.0 * 60.0, 3)[1]), "lying by the afternoon")
	assert_eq(String(CampAnimals.state_of("picket", 15.0 * 60.0, 0)[0]), "", "no one on the picket line at 15:00")
	assert_ne(String(CampAnimals.state_of("picket", 20.0 * 60.0, 0)[0]), "", "picketed at 20:00")
	assert_ne(String(CampAnimals.state_of("picket", Herd.day_minute(3.0 * 60.0), 1)[0]), "", "and at 03:00")
	assert_ne(String(CampAnimals.state_of("corral", 10.0 * 60.0, 1)[0]), "", "the hirer's mules in the corral all day")


func test_the_fires() -> void:
	assert_gt(Camp.fire_lit("CV-01", 17.0 * 60.0, Camp.DEFAULT_HALT), 0.9, "CV-01's fires at 17:00")
	assert_almost_eq(Camp.fire_lit("CV-01", 23.75 * 60.0, Camp.DEFAULT_HALT), 0.0, 0.01, "out by 23:45")
	assert_gt(Camp.fire_lit("CV-01", 6.0 * 60.0, Camp.DEFAULT_HALT), 0.9, "the dawn's tea fire")
	assert_almost_eq(Camp.fire_lit("CV-02", Camp.DEFAULT_HALT + 10.0, Camp.DEFAULT_HALT), 0.0, 0.01, "CV-02's not yet ten minutes after its halt")
	assert_gt(Camp.fire_lit("CV-02", Camp.DEFAULT_HALT + 40.0, Camp.DEFAULT_HALT), 0.9, "lit by forty")
	WorldClock.minute = 18.0 * 60.0
	var camp: Node3D = Camp.new()
	add_child_autofree(camp)
	var c: Dictionary = camp.build()
	if c["things"] == 0:
		pending("no kit files")
		return
	assert_eq(int(c["fires"]), 6, "six fires (chapter 06, 8.6)")
	var lit := 0
	for f in camp.get("fires"):
		if float(f[6]) > 0.9:
			lit += 1
	assert_eq(lit, 6, "all six burning at 18:00")
