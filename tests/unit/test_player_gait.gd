extends GutTest
## The player's gaits (Greg, 10 Oct 2026, 11:00; ISS-176, ISS-178; IMP-043, 14 Oct 2026): the jog the default, Option
## toggling the walk (and back; Shift until 14 Oct 2026), Shift held the sprint; the breath, which runs out after about
## 15 s of sprint and comes back after a few seconds' jog; the pace on flights by the gait; the ladder's clips looping,
## so a climb longer than the clip's 3.6 s keeps climbing (they had played once and the body slid on up the log frozen).

const PlayerScript := preload("res://player/player.gd")

var player: CharacterBody3D


func before_each() -> void:
	player = PlayerScript.new()
	player.third_person = true
	add_child_autofree(player)


func _key(k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	player._unhandled_input(e)


func test_the_jog_is_the_default_and_option_walks() -> void:
	assert_false(player.walking, "jogging unless the walk is toggled on")
	_key(KEY_ALT)
	assert_true(player.walking, "Option: the walk")
	_key(KEY_ALT)
	assert_false(player.walking, "Option again: the jog")
	_key(KEY_SHIFT)
	assert_false(player.walking, "Shift is the sprint, held; never the walk's toggle (it was until 14 Oct 2026)")


func test_the_paces() -> void:
	var floor := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 0.2, 80)
	cs.shape = box
	floor.add_child(cs)
	add_child_autofree(floor)
	floor.global_position = Vector3(0, -0.1, 0)
	player.global_position = Vector3(0, 0.05, 30)
	await wait_physics_frames(6)
	player.scripted = true
	for c in [[0.0, PlayerScript.WALK, "walk"], [1.0, PlayerScript.RUN, "jog"], [2.0, PlayerScript.SPRINT, "sprint"]]:
		player.scripted_move = Vector3(0.0, c[0], -1.0)
		await wait_physics_frames(6)
		assert_eq(player.gait, c[2], "scripted %.0f: the %s" % [c[0], c[2]])
		assert_almost_eq(Vector2(player.velocity.x, player.velocity.z).length(), float(c[1]), 0.2, "at %.1f m/s" % c[1])
	player.scripted_move = Vector3.ZERO
	assert_gt(PlayerScript.SPRINT / PlayerScript.RUN, 1.5, "the sprint clearly faster than the jog (Greg)")
	assert_lt(PlayerScript.SPRINT, 8.0, "but slower than the pony's canter, so the animals still matter (Greg; chapter 06, 10.2)")


func test_the_breath_runs_out_and_comes_back() -> void:
	player.gait = "sprint"
	player.velocity = Vector3(PlayerScript.SPRINT, 0.0, 0.0)
	var t := 0.0
	while not player.winded and t < 30.0:
		player._breathe(0.1)
		t += 0.1
	assert_almost_eq(t, PlayerScript.BREATH, 0.2, "winded after about 15 s of sprint")
	assert_gt(player.puff, 0.9, "breathing hard: the panting and the vignette")
	player.gait = "jog"
	player.velocity = Vector3(PlayerScript.RUN, 0.0, 0.0)
	t = 0.0
	while player.winded and t < 30.0:
		player._breathe(0.1)
		t += 0.1
	assert_between(t, 2.0, 5.0, "a few seconds' jog and the sprint is back")
	for i in 40:
		player._breathe(0.1)
	assert_lt(player.puff, 0.1, "and the breathing quiet again")


func test_the_pace_on_flights() -> void:
	assert_eq(PlayerScript.STAIR["walk"], [2.0, 2.6], "the walk's treads a second up and down, as Greg had it on 26 Sep 2026")
	assert_eq(PlayerScript.STAIR["jog"], [4.0, 5.0], "the jog's")
	assert_eq(PlayerScript.STAIR["sprint"], [6.0, 7.0], "the sprint's")
	assert_true(PlayerScript.STAIR_TWO.has("sprint"), "two treads a stride at the sprint")
	assert_almost_eq(1080.0 / PlayerScript.STAIR["jog"][0] / 60.0, 4.5, 0.1, "the 1,080 steps in about 4.5 minutes of stepping at the jog")
	assert_almost_eq(PlayerScript.CLIMB, 0.75, 0.001, "notched logs at 0.75 m/s")


func test_the_ladder_clips_loop() -> void:
	await wait_frames(2)
	var bodies: Dictionary = player.get("_bodies")
	if bodies.is_empty():
		pending("no player bodies (../tibet-blender people2/body.py)")
		return
	for k in bodies:
		var ap: AnimationPlayer = bodies[k][1]
		for n in ["Climb_Ladder", "Ladder_Idle"]:
			if not ap.has_animation(n):
				fail_test("%s has no %s" % [k, n])
				continue
			assert_eq(ap.get_animation(n).loop_mode, Animation.LOOP_LINEAR, "%s's %s loops: a long climb keeps climbing" % [k, n])
