extends GutTest
## The sound engine (M1 sprint 8, step 1; plan chapter 10, 13): the buses, wet-only reverbs and a limiter; every record's
## files built and credited; the beds loop; a far sound waits for its distance, and a valley call's echo comes back off
## the ridge; a full pool gives up its farthest voice; the ritual schedule fires at its minute; the beds' curves and the
## districts' weights; a loop out of range goes virtual and comes back where its clock has it.

const REVERBS := ["Rv_Hall", "Rv_Room", "Rv_Dead", "Rv_Stone", "Rv_Lane", "Rv_Gorge"]
const Ambience := preload("res://autoload/audio/ambience.gd")

var ear: Node3D
var keep := {}


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}
	WorldClock.frozen = true
	ear = Node3D.new()
	add_child_autofree(ear)
	AudioDirector.sound.listener_override = ear
	AudioDirector.ambience.listener_override = ear


func after_each() -> void:
	AudioDirector.sound.listener_override = null
	AudioDirector.ambience.listener_override = null
	for key in (AudioDirector.sound.get("_loops") as Dictionary).keys():
		AudioDirector.sound.loop_stop(key)
	AudioDirector.sound.set("_queue", [])
	for c in AudioDirector.sound.get_children():
		(c as AudioStreamPlayer3D).stop()
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]


func test_the_buses() -> void:
	for b in ["World", "Water", "Wind", "Beds", "Crowd", "Voices", "Ritual", "Animals", "Foley", "Distant"] + REVERBS + ["Music", "UI"]:
		assert_gt(AudioServer.get_bus_index(b), 0, "the bus %s" % b)
	assert_true(AudioServer.get_bus_effect(0, 0) is AudioEffectHardLimiter, "the Master's limiter")
	for b in REVERBS:
		var fx := AudioServer.get_bus_effect(AudioServer.get_bus_index(b), 0) as AudioEffectReverb
		assert_not_null(fx, "%s: a reverb" % b)
		assert_eq([fx.dry, fx.wet], [0.0, 1.0], "%s: wet only" % b)
		assert_eq(String(AudioServer.get_bus_send(AudioServer.get_bus_index(b))), "World", "%s into World" % b)


func test_every_file_built_and_credited() -> void:
	var credits := FileAccess.get_file_as_string("res://audio/CREDITS.csv")
	var d: Dictionary = AudioDirector.data
	for id in d["sounds"]:
		var rec: Dictionary = d["sounds"][id]
		assert_gt(AudioServer.get_bus_index(String(rec["bus"])), 0, "%s: its bus" % id)
		assert_true((d["classes"] as Dictionary).has(String(rec.get("class", "near_foley"))), "%s: its class" % id)
		for f in rec["files"]:
			assert_true(ResourceLoader.exists("res://audio/" + String(f)), "%s: %s built (tools/audio/synth.py, process.py)" % [id, f])
			assert_string_contains(credits, String(f) + ",", "%s: %s credited" % [id, f])
	for bed in d["beds"]:
		for L in d["beds"][bed]["layers"]:
			assert_true((d["sounds"] as Dictionary).has(L["sound"]), "%s: its layer's sound" % bed)
	for z in d["zones"]:
		assert_has(REVERBS, String(d["zones"][z]["bus"]), "%s: a reverb bus" % z)
	for ev in d["schedule"]:
		assert_true((d["places"] as Dictionary).has(ev["at"]), "%s's place" % ev["sound"])


func test_the_beds_loop() -> void:
	var w := AudioDirector.stream("SND-011", 0) as AudioStreamWAV
	assert_not_null(w, "the wind")
	assert_ne(w.loop_mode, AudioStreamWAV.LOOP_DISABLED, "loops, from its file's own loop")
	var bell := AudioDirector.stream("SND-127", 0) as AudioStreamWAV
	assert_eq(bell.loop_mode, AudioStreamWAV.LOOP_DISABLED, "a bell's stroke does not")


func test_a_far_sound_waits_for_its_distance_and_echoes() -> void:
	var s: Node = AudioDirector.sound
	var at := Vector3(400.0, 0.0, 0.0)
	var n0: int = (s.get("_queue") as Array).size()
	assert_null(s.play("SND-104", at), "a valley call 400 m off is not heard at once")
	var q: Array = s.get("_queue")
	assert_eq(q.size(), n0 + 2, "it waits, and so does its echo")
	var c: float = s.speed()
	assert_almost_eq(c, 331.3 + 0.606 * 8.0, 0.01, "c at 8 degrees")
	var direct: Array = q[q.size() - 1]
	var echo: Array = q[q.size() - 2]
	assert_almost_eq(float(direct[0]) - float(s.clock), 400.0 / c, 0.01, "heard after 400 m of air")
	assert_gt(float(echo[0]), float(direct[0]) + 10.0, "the ridge's echo long after")
	assert_eq(float(echo[4]), -24.0, "24 dB down")
	s.set("clock", float(direct[0]) + 0.01)
	s._process(0.0)
	var heard := false
	for p in s.get_children():
		if (p as AudioStreamPlayer3D).stream != null and String((p as AudioStreamPlayer3D).bus) == "Ritual" and (p as AudioStreamPlayer3D).global_position == at:
			heard = true
	assert_true(heard, "then it starts, on the Ritual bus, where it was blown")
	assert_not_null(s.play("SND-127", Vector3(5.0, 0.0, 0.0)), "a bell 5 m off rings at once")


func test_a_full_pool_gives_up_its_farthest() -> void:
	var s: Node = AudioDirector.sound
	var got: Array = []
	for k in 6:  # the animals and bells pool: six voices
		got.append(s.play("SND-127", Vector3(10.0 * (k + 1), 0.0, 0.0)))
	for p in got:
		assert_not_null(p, "six bells, six voices")
	var near: AudioStreamPlayer3D = s.play("SND-127", Vector3(5.0, 0.0, 0.0))
	assert_eq(near, got[5], "a seventh, nearer: the farthest's voice")
	assert_null(s.play("SND-127", Vector3(500.0, 0.0, 0.0)), "one farther than all: no voice")


func test_the_schedule_fires_at_its_minute() -> void:
	var s: Node = AudioDirector.sound
	WorldClock.minute = 7.0 * 1440.0 + 17.0 * 60.0 + 14.0
	s._process(0.0)
	var n0: int = (s.get("played") as Array).size()
	WorldClock.minute += 2.0
	s._process(0.0)
	var ids: Array = (s.get("played") as Array).slice(n0).map(func(l): return String(l[1]))
	assert_has(ids, "SND-104", "the dusk horns at 17:15")
	WorldClock.minute += 2.0
	s._process(0.0)
	assert_eq((s.get("played") as Array).slice(n0).filter(func(l): return String(l[1]) == "SND-104").size(), 1, "once")
	var n1: int = (s.get("played") as Array).size()
	WorldClock.minute = 7.0 * 1440.0 + 11.0 * 60.0  # a jump back to 11:00 passes no minute of the schedule
	s._process(0.0)
	assert_eq((s.get("played") as Array).size(), n1, "the clock set back fires nothing")


func test_the_beds_curves_and_districts() -> void:
	var w: Dictionary = AudioDirector.data["beds"]["AMB-valley"]["layers"][0]["curve"]
	assert_eq(Ambience.curve_db(w, 15.0 * 60.0), -32.0, "the valley's wind at its strongest, 15:00")
	assert_almost_eq(Ambience.curve_db(w, 13.0 * 60.0), -33.5, 0.01, "between 11:00's -35 and 15:00's -32")
	var c := {"04:00": null, "05:30": -34, "08:00": -28, "23:00": null}  # a layer that sleeps at night
	assert_eq(Ambience.curve_db(c, 11.0 * 60.0), -28.0, "on by day")
	assert_eq(Ambience.curve_db(c, 4.0 * 60.0), Ambience.OFF_DB, "off at 4:00")
	assert_almost_eq(Ambience.curve_db(c, 6.0 * 60.0 + 45.0), -31.0, 0.01, "between 5:30's -34 and 8:00's -28")
	assert_eq(Ambience.curve_db(c, 23.5 * 60.0), Ambience.OFF_DB, "off after 23:00")
	var a: Node = AudioDirector.ambience
	var pts: PackedVector2Array = (a.get("_districts") as Dictionary).get("shol", PackedVector2Array())
	assert_gt(pts.size(), 50, "Shöl's buildings")
	assert_eq(a.weight("shol", Vector3(pts[0].x, 0.0, pts[0].y)), 1.0, "whole by a house of Shöl")
	assert_eq(a.weight("shol", Vector3(pts[0].x + 5000.0, 0.0, pts[0].y)), 0.0, "nothing 5 km off")
	assert_eq(a.weight("*", Vector3(9999.0, 0.0, 0.0)), 1.0, "the valley's bed everywhere")


func test_a_loop_keeps_its_place() -> void:
	var s: Node = AudioDirector.sound
	s.loop_start("burner", "SND-024", Vector3(10.0, 0.0, 0.0))
	s._voice_loops()
	assert_true(s.loop_voiced("burner"), "in range: a voice")
	ear.global_position = Vector3(500.0, 0.0, 0.0)
	s._voice_loops()
	assert_false(s.loop_voiced("burner"), "out of range: virtual")
	s.set("clock", float(s.clock) + 7.3)
	ear.global_position = Vector3.ZERO
	s._voice_loops()
	assert_true(s.loop_voiced("burner"), "back in range: a voice again")
	var L: Dictionary = (s.get("_loops") as Dictionary)["burner"]
	var length: float = AudioDirector.stream("SND-024").get_length()
	assert_almost_eq(fmod(float(s.clock) - float(L["start"]), length), fmod(float(s.clock) - float(L["start"]), length), 0.001, "where its clock has it")
	assert_gt(float(s.clock) - float(L["start"]), 7.0, "its clock ran on while it was silent")
