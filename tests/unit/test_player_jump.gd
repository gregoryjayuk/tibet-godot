extends GutTest
## The jump (M1 sprint 5, step 1; Greg, 26 Sep 2026: "The ability to jump seems to be gone too"): Space jumps about
## half a metre and lands; with the guard up it dodges instead; and a jump never carries the player off a drop (never
## able to fall): on a roof's edge the jump goes straight up and comes down where it began.

const PlayerScript := preload("res://player/player.gd")

var player: CharacterBody3D


func before_each() -> void:
	player = PlayerScript.new()
	player.third_person = true
	add_child_autofree(player)
	player.global_position = Vector3(0, 0.05, 0)
	_slab(Vector3(6, 0.2, 6), Vector3(0, -0.1, 0))


func _slab(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	b.add_child(cs)
	add_child_autofree(b)
	b.global_position = at


func _space() -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.pressed = true
	player._unhandled_input(e)


func test_space_jumps_and_lands() -> void:
	await wait_physics_frames(6)
	var y0 := player.global_position.y
	_space()
	var top := y0
	for i in 60:
		await wait_physics_frames(1)
		top = maxf(top, player.global_position.y)
	assert_between(top - y0, 0.4, 0.7, "about half a metre up")
	assert_almost_eq(player.global_position.y, y0, 0.05, "and down again")
	assert_false(player.get("_airborne"), "landed")


func test_a_jump_never_carries_off_a_drop() -> void:
	player.global_position = Vector3(1.5, 0.05, 0.0)  # 1.5 m from the slab's edge at x = 3; beyond it, nothing
	await wait_physics_frames(6)
	player.scripted = true
	player.yaw = -PI / 2.0  # facing +X, towards the edge
	player.scripted_move = Vector3(0.0, 1.0, -1.0)  # running: a jump would carry 3 m
	await wait_physics_frames(2)
	_space()
	for i in 45:
		await wait_physics_frames(1)
	player.scripted_move = Vector3.ZERO
	await wait_physics_frames(10)
	assert_lt(player.global_position.x, 3.0, "still on the slab")
	assert_gt(player.global_position.y, -0.1, "not fallen")


func test_a_running_jump_carries_on() -> void:
	# Greg, 27 Sep 2026: "when I'm running and then I jump, the momentum doesn't keep him moving forward": the keys let go
	# just after the take-off, the run carries on through the air
	_slab(Vector3(30, 0.2, 30), Vector3(0, -0.1, 0))
	player.global_position = Vector3(-8.0, 0.05, 0.0)
	await wait_physics_frames(6)
	player.scripted = true
	player.yaw = -PI / 2.0  # facing +X, the slab ahead
	player.scripted_move = Vector3(0.0, 1.0, -1.0)  # running
	await wait_physics_frames(20)
	_space()
	await wait_physics_frames(1)
	player.scripted_move = Vector3.ZERO  # the keys let go
	var x0 := player.global_position.x
	var air := 0
	var gone := 0.0
	for i in 40:
		await wait_physics_frames(1)
		if player.get("_airborne"):
			air += 1
			gone = player.global_position.x - x0
	assert_gt(air, 5, "it left the ground")
	assert_gt(gone / (air / float(Engine.physics_ticks_per_second)), PlayerScript.RUN * 0.8, "and carried on at the run, the keys let go")
