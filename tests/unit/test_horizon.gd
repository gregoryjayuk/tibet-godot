extends GutTest
## Art step A8 (plan chapter 09, 10.2; chapter 11, 6.3; spike S12): the horizon map as the game loads it
## (world/horizon.gd), read on the CPU as the shaders read it, holds the ridge shadow to chapter 02's minute. The map
## is generated (tools/terrain/horizon.py, not versioned): without it the tests are pending, not failed.

const Horizon := preload("res://world/horizon.gd")
const BAKE := "res://assets/generated/terrain/horizon.json"


func after_each() -> void:
	Horizon.clear()


## The western ridge takes Tsongra at 16:10 in the design (chapter 02, table 2.8); art step A8's gate is 3 minutes.
func test_the_shadow_takes_tsongra_on_time() -> void:
	if not FileAccess.file_exists(BAKE):
		pending("no horizon map: run tools/py tools/terrain/horizon.py")
		return
	assert_true(Horizon.load_globals(), "the map loads")
	var eye := Vector3(0.0, Horizon.ground_at(0.0, 0.0) + 1.6, 0.0)
	var before := Calendar.minute_of(1903, 10, 28, 16, 7)
	var after := Calendar.minute_of(1903, 10, 28, 16, 13)
	assert_gt(Horizon.light_at(eye, Calendar.sun_direction(before)), 0.99, "Tsongra in the sun at 16:07")
	assert_lt(Horizon.light_at(eye, Calendar.sun_direction(after)), 0.01, "Tsongra in the ridge's shadow at 16:13")


## The minute of the default day when `pos` loses the sun, scanned from 15:00 in 5 s steps; -1 if it keeps it.
func _last_lit(pos: Vector3) -> float:
	var m0 := float(Calendar.minute_of(1903, 10, 28, 15, 0))
	var t := m0
	while t < m0 + 150.0:
		if Horizon.light_at(pos, Calendar.sun_direction(t)) < 0.5:
			return t
		t += 1.0 / 12.0
	return -1.0


## The shadow climbs: 15 s after the street loses the sun, 20 m up still has it. Found by scanning, not at a fixed
## minute, since the moment follows the terrain (16:09:45 on the real ground; about 16:07:30 since the sculpting).
func test_the_shadow_climbs_the_walls() -> void:
	if not FileAccess.file_exists(BAKE):
		pending("no horizon map: run tools/py tools/terrain/horizon.py")
		return
	assert_true(Horizon.load_globals())
	var ground := Horizon.ground_at(0.0, 0.0)
	var dark := _last_lit(Vector3(0.0, ground + 1.6, 0.0))
	assert_gt(dark, 0.0, "the street loses the afternoon sun")
	var sun := Calendar.sun_direction(dark + 0.25)
	assert_lt(Horizon.light_at(Vector3(0.0, ground + 1.6, 0.0), sun), 0.01, "the street dark 15 s later")
	assert_gt(Horizon.light_at(Vector3(0.0, ground + 20.0, 0.0), sun), 0.99, "a roof 20 m up still lit")


## The draft street stands on its own ground: set down at Tsongra, its y is its height above the ground.
func test_the_street_is_set_down_at_tsongra() -> void:
	if not FileAccess.file_exists(BAKE):
		pending("no horizon map: run tools/py tools/terrain/horizon.py")
		return
	assert_true(Horizon.load_globals(Horizon.STREET_PLACE))
	var dark := _last_lit(Vector3(0.0, 1.6, 0.0))
	assert_gt(dark, 0.0, "the street's ground loses the afternoon sun")
	var sun := Calendar.sun_direction(dark + 0.25)
	assert_lt(Horizon.light_at(Vector3(0.0, 1.6, 0.0), sun), 0.01, "the street's ground dark 15 s later")
	assert_gt(Horizon.light_at(Vector3(0.0, 20.0, 0.0), sun), 0.99, "its roofs lit")


## Without a map every surface is lit, as the draft's reference shots need.
func test_no_map_no_shadow() -> void:
	Horizon.clear()
	assert_eq(Horizon.light_at(Vector3.ZERO, Vector3(0.0, -0.2, 1.0)), 1.0)
