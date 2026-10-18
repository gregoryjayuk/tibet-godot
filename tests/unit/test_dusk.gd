extends GutTest
## V-28's dusk (world/dusk.gd; M1 sprint 4, step 6): (the horns are the sound schedule's now: test_sound.gd) the ladders that stand
## on the ground drawn up from 17:40 unless the player is near (never one standing on a roof), set down again at dawn.

const Dusk := preload("res://world/dusk.gd")

var root: Node3D
var cam: Camera3D
var near_l: Node3D
var far_l: Node3D
var roof_l: Node3D
var keep := {}


func _ladder(at: Vector3, from: String) -> Node3D:
	var l := Node3D.new()
	l.position = at
	l.set_meta("parapet", at + Vector3(0.0, 3.0, -1.2))
	l.set_meta("way", Vector3(0.0, 0.0, -1.0))
	l.set_meta("from", from)
	l.add_to_group("ladders")
	root.add_child(l)
	return l


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}
	WorldClock.frozen = true
	root = Node3D.new()
	add_child_autofree(root)
	cam = Camera3D.new()
	root.add_child(cam)
	cam.current = true
	cam.position = Vector3(0.0, 2.0, 0.0)
	near_l = _ladder(Vector3(10.0, 0.0, 0.0), "ground")
	far_l = _ladder(Vector3(200.0, 0.0, 0.0), "ground")
	roof_l = _ladder(Vector3(210.0, 0.0, 0.0), "H-SHL-001.1")


func after_each() -> void:
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]


func _dusk() -> Node3D:
	var d: Node3D = Dusk.new()
	root.add_child(d)
	return d


## The clock at an hour of the default day, then `seconds` of frames.
func _at(d: Node3D, hour: float, seconds := 0.0) -> void:
	WorldClock.minute = 7.0 * 1440.0 + hour * 60.0
	d._process(0.0)
	var t := 0.0
	while t < seconds:
		d._process(0.1)
		t += 0.1


func test_the_ladders_are_drawn_up_at_dusk() -> void:
	var d := _dusk()
	var down: Vector3 = far_l.position
	_at(d, 18.0, 7.0)  # after 17:40 and the ten minutes the households take
	assert_false(far_l.is_in_group("ladders"), "a ladder from the ground, far from the player: drawn up")
	assert_gt(far_l.position.y, down.y + 2.0, "up at the roof")
	assert_true(near_l.is_in_group("ladders"), "10 m from the player: it waits")
	assert_true(roof_l.is_in_group("ladders"), "one standing on a roof stays")
	cam.position = Vector3(-400.0, 2.0, 0.0)
	_at(d, 18.5, 7.0)
	assert_false(near_l.is_in_group("ladders"), "once the player has gone, it goes up too")
	_at(d, 5.75, 7.0)  # after 05:30 and its ten minutes
	assert_true(far_l.is_in_group("ladders"), "set down at dawn")
	assert_almost_eq(far_l.position.distance_to(down), 0.0, 0.01, "back at its foot")


func test_an_uncapped_run_stays_uncapped_through_a_tier_change() -> void:
	var before := {"tier": Quality.tier, "base": Quality.base_tier, "fps": Engine.max_fps, "uncapped": Quality.uncapped}
	Quality.uncapped = true
	Quality.set_tier("QT-BATT", "a test: on battery")
	assert_eq(Engine.max_fps, 0, "the battery tier does not put the cap back on a performance run")
	Quality.uncapped = false
	Quality.set_tier("QT-BATT", "a test: on battery")
	assert_eq(Engine.max_fps, 30, "a game run has the tier's cap")
	Quality.uncapped = before["uncapped"]
	Quality.set_tier(String(before["base"]))
	Quality.set_tier(String(before["tier"]), "a test: back")
	Engine.max_fps = int(before["fps"])


## The shader's strength of burner i's thread at `hour` (shaders/smoke.gdshader's windows, from its instance data as
## world/dusk.gd keeps it: a headless run's MultiMesh keeps none).
func _on(d: Node3D, i: int, hour: float) -> float:
	var c: Color = (d.get("_base") as Array)[i]
	var m := hour * 60.0
	var e := smoothstep(1020.0 + c.g, 1024.0 + c.g, m) * (1.0 - smoothstep(1065.0, 1080.0, m))
	var a := smoothstep(345.0 + c.g, 349.0 + c.g, m) * (1.0 - smoothstep(390.0, 405.0, m))
	return maxf(e, a) * c.b


func test_juniper_lights_its_burner() -> void:
	# Greg's walk, 27 Sep 2026: juniper laid on Dechen-tsang's burner before its household's minute made no smoke
	var sock := Node3D.new()
	sock.name = "SOCK_SANG_1"
	root.add_child(sock)
	sock.position = Vector3(30.0, 5.0, 0.0)
	var d := _dusk()
	_at(d, 16.97)
	assert_eq(d.burners, 1, "the burner found")
	assert_eq(_on(d, 0, 16.97), 0.0, "at 16:58, before its household lights it: no thread")
	assert_true(d.boost(sock.global_position), "juniper laid on it")
	d._process(0.1)
	assert_gt(_on(d, 0, 16.97), 0.6, "lit there and then")
	_at(d, 17.3, 30.0)
	assert_gt(_on(d, 0, 17.3), 0.6, "and burning on after the juniper's thickening has eased away")

