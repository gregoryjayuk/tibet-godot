extends GutTest
## The weather's snow (world/day.gd SNOW; IMP-021, item 4): the season's own lies above 4,300 m and nothing in the town;
## a dusting brings the line to 3,500 m; V-31's snowfall to the monastery's 2,880 m, falling, the town wet; the morning
## after a snowfall lies in the town; while it falls, flakes round the camera (world/snowfall.gd) and an overcast light.

const Day := preload("res://world/day.gd")

var day: Node
var sun: DirectionalLight3D


func before_each() -> void:
	sun = DirectionalLight3D.new()
	add_child_autofree(sun)
	day = Day.new()
	day.sun = sun
	add_child_autofree(day)


func after_each() -> void:
	RenderingServer.global_shader_parameter_set("g_snow_line", 99999.0)
	RenderingServer.global_shader_parameter_set("g_snow", 0.0)


func _at(snow: String) -> Dictionary:
	day.snow = snow
	day.update(WorldClock.DEFAULT_MINUTE)
	return day.last


func test_the_season_own() -> void:
	var v := _at("")
	assert_eq(float(v["snow_line"]), 4300.0, "fresh autumn snow above 4,300 m (chapter 01, 9.1)")
	assert_eq(float(v["snow"]), 0.0, "none in the town")
	assert_null(day.snowfall, "nothing falling")


func test_the_presets() -> void:
	assert_eq(float(_at("dust")["snow_line"]), 3500.0, "a dusting down to 3,500 m")
	var v31 := _at("v31")
	assert_eq(float(v31["snow_line"]), 2880.0, "V-31: down to the monastery")
	assert_eq(float(v31["snow"]), 0.0, "the town wet, not white")
	assert_not_null(day.snowfall, "falling")
	var town := _at("town")
	assert_lt(float(town["snow_line"]), 2540.0, "down into the valley, under the town's lowest")
	assert_gt(float(town["snow"]), 0.5, "lying in the town")


func test_falling_dims_the_sun() -> void:
	var clear := _at("town")
	var e_clear := sun.light_energy
	_at("falling")
	assert_true((day.snowfall as GPUParticles3D).emitting, "the flakes falling")
	assert_lt(sun.light_energy, e_clear * 0.7, "the overcast's thinner light")
	assert_eq(clear["snow_line"], day.last["snow_line"], "the same snow line")
