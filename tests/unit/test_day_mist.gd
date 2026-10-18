extends GutTest
## The valley's mist by the minute (world/day.gd mist_at; IMP-021, chapter 09, 9.3): the river mist full in the small
## hours and at dawn, lifting and thinning away from 07:00 to 08:30, none by day; a thin haze gathering from 17:15 and
## thickening into the night's; the mist sea higher and denser, lifting later.

const Day := preload("res://world/day.gd")


func test_the_river_mist() -> void:
	var dawn := Day.mist_at(5.0 * 60.0)
	assert_almost_eq(dawn.x, 2610.0, 0.1, "its top at 2,610 m")
	assert_gt(dawn.y, 0.015, "full at 05:00")
	assert_between(Day.mist_at(7.75 * 60.0).y, 0.001, dawn.y * 0.9, "thinning at 07:45")
	assert_eq(Day.mist_at(9.0 * 60.0).y, 0.0, "gone by 09:00")
	assert_eq(Day.mist_at(13.0 * 60.0).y, 0.0, "none by day")


func test_the_evening_haze_into_the_night() -> void:
	assert_eq(Day.mist_at(17.0 * 60.0).y, 0.0, "not before 17:15")
	var dusk := Day.mist_at(18.0 * 60.0)
	assert_between(dusk.y, 0.003, 0.012, "a thin haze at 18:00")
	assert_between(dusk.x, 2570.0, 2600.0, "in the valley's bottom")
	assert_gt(Day.mist_at(2.0 * 60.0).y, Day.mist_at(22.0 * 60.0).y, "thicker in the small hours than at 22:00")


func test_the_mist_sea() -> void:
	var sea := Day.mist_at(6.0 * 60.0, true)
	assert_almost_eq(sea.x, 2720.0, 0.1, "its top at 2,720 m: Tsongra under it, V-28 above")
	assert_gt(sea.y, Day.mist_at(6.0 * 60.0).y, "denser than the river mist")
	assert_gt(Day.mist_at(8.25 * 60.0, true).y, Day.mist_at(8.25 * 60.0).y, "lifting later")
