extends GutTest
## The moments (plan chapter 08, 2; M2 sprint 3, step 5; world/moments.gd): V-01's record as chapter 08 sets it out, the
## reveal's stretches along R-01 (data/arrival.json), the town's buses held down on the gallery and in the chorten's
## passage and risen again over 2 s outside it, and the moment logged once at its station in its window.

const Moments := preload("res://world/moments.gd")
const Town := preload("res://world/town.gd")

var m: Node
var player: Node3D
var _clock := 0.0


func before_each() -> void:
	m = Moments.new()
	add_child_autofree(m)
	player = Node3D.new()
	player.add_to_group("player")
	add_child_autofree(player)
	_clock = WorldClock.minute
	Story.set_flag("moment:V-01", false)


func after_each() -> void:
	WorldClock.minute = _clock
	Story.set_flag("moment:V-01", false)
	for bus in ["Beds", "Crowd", "Voices", "Ritual", "Distant"]:
		AudioDirector.set_offset("moment", bus, 0.0)


func _at(x: float, y: float, z: float) -> void:
	player.global_position = Town.to_godot(x, y, z)


func test_v01_is_chapter_08s_record() -> void:
	assert_gt(m.moments.size(), 0, "the moments")
	var v: Dictionary = m.moments[0]
	assert_eq(String(v["id"]), "V-01", "the first, M2 sprint 3's")
	for each in m.moments:  # every record as chapter 08, 2.1 has it (V-02 since M2 sprint 5)
		for k in ["stations", "window", "weather", "rarity", "preset", "sound_cue", "dressing", "frame_clear", "requires", "log_once", "tiers"]:
			assert_true((each as Dictionary).has(k), "%s: %s (chapter 08, 2.1)" % [String(each["id"]), k])
	assert_eq(String(v["sound_cue"]), "sc_gate_reveal")
	assert_gt(m.road.size(), 3, "the road from SER-20 to the chorten")


func test_the_town_is_not_heard_on_the_gallery_and_rises_out_of_the_chorten() -> void:
	var cue: Dictionary = m.moments[0]["cue"]
	_at(352.5, -197.5, 2706.0)  # on the gallery
	assert_eq(m.stretch(Moments.grid(player.global_position), cue), "quiet", "the gallery: quiet")
	m._cue(Moments.grid(player.global_position), cue, 0.1)
	assert_almost_eq(AudioDirector.offset("moment", "Crowd"), -18.0, 0.01, "the town's crowd 18 dB down on the gallery")
	_at(240.0, -158.0, 2697.0)  # in the cutting
	assert_eq(m.stretch(Moments.grid(player.global_position), cue), "quiet", "the cutting: quiet")
	_at(170.0, -175.0, 2692.0)  # in the passage
	assert_eq(m.stretch(Moments.grid(player.global_position), cue), "room", "the chorten's passage")
	for i in 20:
		m._cue(Moments.grid(player.global_position), cue, 0.1)
	assert_almost_eq(AudioDirector.offset("moment", "Beds"), -12.0, 0.01, "the beds 12 dB down in the dead stone room")
	_at(150.0, -165.0, 2690.0)  # out on its west side
	assert_eq(m.stretch(Moments.grid(player.global_position), cue), "none")
	m._cue(Moments.grid(player.global_position), cue, 1.0)
	assert_between(AudioDirector.offset("moment", "Crowd"), -10.0, -8.0, "risen half way after a second")
	m._cue(Moments.grid(player.global_position), cue, 1.0)
	assert_almost_eq(AudioDirector.offset("moment", "Crowd"), 0.0, 0.01, "the town at its own level after two")


func test_the_reveal_is_logged_once_at_its_station_in_its_window() -> void:
	var v: Dictionary = m.moments[0]
	WorldClock.minute = 14.0 * 60.0
	_at(166.0, -175.0, 2694.0)
	m._log(v, Moments.grid(player.global_position))
	assert_false(Story.flag("moment:V-01"), "not at 14:00, outside its windows")
	WorldClock.minute = 14.9 * 60.0
	m._log(v, Moments.grid(player.global_position))
	assert_true(Story.flag("moment:V-01"), "logged at 14:54 (the first arrival's window)")
	m._log(v, Moments.grid(player.global_position))
	assert_eq(m.logged.size(), 1, "once")
