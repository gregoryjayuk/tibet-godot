extends GutTest
## The controls (IMP-044; Greg's brief of 14 Oct 2026, docs/brief-movement-controls.md): every action of
## autoload/controls.gd in project.godot's map (tools/build/make_input.gd); a PS4 controller's buttons and sticks fed
## through the actions as joypad events (GTA's way: the left stick from the camera, a light tilt walking, cross held
## sprinting, the right stick turning the camera); the mouse's drags as World of Warcraft has them (the left button
## swings the camera and not the walker, the right turns the walker to it, both walk on, the wheel zooms), and the keys'
## A and D turning the walker; the prompts and the replies labelled for the controller.

const PlayerScript := preload("res://player/player.gd")

var player: CharacterBody3D


func before_each() -> void:
	Controls.pad = false
	player = PlayerScript.new()
	player.third_person = true
	add_child_autofree(player)
	player.global_position = Vector3(0, 0.05, 0)
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 0.2, 60)
	cs.shape = box
	b.add_child(cs)
	add_child_autofree(b)
	b.global_position = Vector3(0, -0.1, 0)


func after_each() -> void:
	for a in Controls.ACTIONS:
		Input.action_release(a)
	Controls.pad = false


func _feed(e: InputEvent) -> void:
	e.device = 0
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _axis(axis: JoyAxis, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = v
	_feed(e)


func _button(b: JoyButton, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = down
	_feed(e)


func _mouse(b: MouseButton, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = b
	e.pressed = down
	_feed(e)


func _drag(dx: float, dy := 0.0) -> void:
	var e := InputEventMouseMotion.new()
	e.relative = Vector2(dx, dy)
	_feed(e)


func _hspeed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()


func test_every_action_is_in_the_map() -> void:
	for a in Controls.ACTIONS:
		if not InputMap.has_action(a):
			fail_test("%s is not in project.godot's [input]: run tools/build/make_input.gd" % a)
			continue
		var want: Array = Controls.events_of(a)
		var have := InputMap.action_get_events(a)
		assert_eq(have.size(), want.size(), "%s: as many events as the table's" % a)
		for e in want:
			var found := false
			for h in have:
				found = found or (h as InputEvent).is_match(e as InputEvent, true)
			assert_true(found, "%s: %s" % [a, (e as InputEvent).as_text()])
		assert_almost_eq(InputMap.action_get_deadzone(a), float((Controls.ACTIONS[a] as Array)[1]), 0.001, "%s's dead zone" % a)


func test_the_controllers_buttons_are_the_briefs() -> void:
	for c in [[JOY_BUTTON_A, "sprint"], [JOY_BUTTON_X, "jump"], [JOY_BUTTON_Y, "use"], [JOY_BUTTON_B, "sit"],
			[JOY_BUTTON_RIGHT_SHOULDER, "strike"], [JOY_BUTTON_LEFT_SHOULDER, "guard"], [JOY_BUTTON_DPAD_UP, "answer_1"],
			[JOY_BUTTON_DPAD_RIGHT, "answer_2"], [JOY_BUTTON_DPAD_DOWN, "answer_3"], [JOY_BUTTON_DPAD_LEFT, "answer_4"],
			[JOY_BUTTON_RIGHT_STICK, "view"], [JOY_BUTTON_TOUCHPAD, "ledger"], [JOY_BUTTON_START, "codex"]]:
		_button(c[0], true)
		assert_true(Input.is_action_pressed(c[1]), "%s: %s" % [Controls.PAD_BUTTONS[c[0]], c[1]])
		_button(c[0], false)
		assert_false(Input.is_action_pressed(c[1]), "%s let go" % c[1])
	_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	assert_true(Input.is_action_pressed("whirl"), "R2: the sling's whirl")
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	assert_true(Controls.pad, "the controller was the last thing used")


func test_the_left_stick_moves_from_the_camera() -> void:
	await wait_physics_frames(6)
	player.yaw = PI / 2.0  # the camera looking down -X
	player.facing = 0.0
	_axis(JOY_AXIS_LEFT_Y, -1.0)  # pushed full forward
	await wait_physics_frames(8)
	assert_eq(player.gait, "jog", "full tilt: the jog")
	assert_almost_eq(_hspeed(), PlayerScript.RUN, 0.2, "at the jog's 4.5 m/s")
	assert_lt(player.velocity.x, -4.0, "the way the camera looks, not the way the body faced")
	_axis(JOY_AXIS_LEFT_Y, -0.4)  # a light tilt
	await wait_physics_frames(4)
	assert_eq(player.gait, "walk", "a light tilt: the walk")
	assert_almost_eq(_hspeed(), PlayerScript.WALK, 0.2, "at 1.5 m/s")
	_axis(JOY_AXIS_LEFT_Y, -1.0)
	_button(JOY_BUTTON_A, true)  # cross held
	await wait_physics_frames(6)
	assert_eq(player.gait, "sprint", "cross held: the sprint")
	assert_almost_eq(_hspeed(), PlayerScript.SPRINT, 0.3, "at 7 m/s")
	_button(JOY_BUTTON_A, false)
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	await wait_physics_frames(4)
	assert_lt(_hspeed(), 0.1, "let go: still")


func test_the_right_stick_turns_the_camera() -> void:
	player.yaw = 0.0
	_axis(JOY_AXIS_RIGHT_X, 1.0)
	await wait_seconds(0.3)
	var turned: float = -player.yaw
	assert_gt(turned, 0.3, "to the right, about 2.4 radians a second")
	_axis(JOY_AXIS_RIGHT_X, 0.1)  # within the dead zone
	var y: float = player.yaw
	await wait_seconds(0.1)
	assert_almost_eq(player.yaw, y, 0.0001, "not past the dead zone: still")
	_axis(JOY_AXIS_RIGHT_X, 0.0)
	assert_lt(Controls.look(1.0 / 60.0).length(), 0.0001, "and let go")


func test_the_mouse_as_world_of_warcraft_has_it() -> void:
	await wait_physics_frames(4)
	player.yaw = 0.0
	player.heading = 0.0
	player.facing = 0.0
	_mouse(MOUSE_BUTTON_LEFT, true)
	_drag(200.0)
	assert_true(player.orbiting, "the left button held")
	assert_almost_eq(player.yaw, -0.5, 0.001, "dragged: the camera swings round")
	assert_almost_eq(player.heading, 0.0, 0.001, "and the walker keeps its way")
	_mouse(MOUSE_BUTTON_LEFT, false)
	assert_false(player.orbiting, "let go")
	_mouse(MOUSE_BUTTON_RIGHT, true)
	assert_almost_eq(player.heading, player.yaw, 0.001, "the right button: the walker turns to the camera's way at once")
	_drag(-100.0)
	assert_almost_eq(player.heading, -0.25, 0.001, "and steers with it")
	_mouse(MOUSE_BUTTON_LEFT, true)  # both: on along the way
	await wait_physics_frames(8)
	var v := Vector2(player.velocity.x, player.velocity.z)
	assert_almost_eq(v.length(), PlayerScript.RUN, 0.2, "both buttons: the jog")
	assert_almost_eq(atan2(-v.x, -v.y), -0.25, 0.05, "along the walker's way")
	_mouse(MOUSE_BUTTON_LEFT, false)
	_mouse(MOUSE_BUTTON_RIGHT, false)
	await wait_physics_frames(4)
	assert_lt(_hspeed(), 0.1, "both let go: still")
	var z: float = player.zoom
	_mouse(MOUSE_BUTTON_WHEEL_UP, true)
	_mouse(MOUSE_BUTTON_WHEEL_UP, false)
	assert_lt(player.zoom, z, "the wheel: the camera closer")
	for i in 30:
		_mouse(MOUSE_BUTTON_WHEEL_DOWN, true)
		_mouse(MOUSE_BUTTON_WHEEL_DOWN, false)
	assert_almost_eq(player.zoom, PlayerScript.ZOOM_MAX, 0.001, "no further than ZOOM_MAX")


func test_a_and_d_turn_the_walker_and_the_camera() -> void:
	await wait_physics_frames(4)
	player.yaw = 0.0
	player.heading = 0.0
	Input.action_press("move_left")
	await wait_physics_frames(15)  # half a second
	Input.action_release("move_left")
	assert_almost_eq(player.heading, PlayerScript.TURN * 0.5, 0.15, "A: turned left at World of Warcraft's pace")
	assert_almost_eq(player.yaw, player.heading, 0.15, "the camera turned with it")
	assert_lt(_hspeed(), 0.1, "on the spot")
	Input.action_press("move_back")
	await wait_physics_frames(8)
	Input.action_release("move_back")
	assert_eq(player.gait, "back", "S: backing away")
	assert_almost_eq(_hspeed(), PlayerScript.BACK, 0.2, "at a walk")


func test_the_fists_go_up_on_r() -> void:
	await wait_frames(2)
	if player.fight == null:
		pending("no player bodies (../tibet-blender people2/body.py)")
		return
	var r := InputEventKey.new()
	r.keycode = KEY_R
	r.pressed = true
	_feed(r)
	assert_true(player.fists, "R: the fists up")
	_mouse(MOUSE_BUTTON_RIGHT, true)
	assert_true(player.fight.guard, "the right button guards with them up")
	assert_false(player.steering, "and does not steer")
	_mouse(MOUSE_BUTTON_RIGHT, false)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	_feed(esc)
	assert_false(player.fists, "Esc lowers them")


func test_the_prompts_and_replies_for_the_controller() -> void:
	assert_eq(Controls.say("E  open the door"), "E  open the door", "on the keys as written")
	Controls.pad = true
	assert_eq(Controls.say("E  open the door"), "△  open the door", "triangle on the controller")
	assert_eq(Controls.say("E  sip        R  enough (a palm over the bowl)"), "△  sip        □  enough (a palm over the bowl)", "and square for enough")
	assert_eq(Controls.say("E  sip        C  stand"), "△  sip        ○  stand")
	assert_eq(Controls.say("1-2  answer"), "↑ →  answer", "the D-pad's answers")
	assert_eq(Controls.answer_label(2), "↓", "the third reply on the D-pad's down")
	Controls.pad = false
	assert_eq(Controls.answer_label(2), "3", "on the keys its number")
