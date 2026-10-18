extends GutTest
## The player's steps (M1 sprint 8, step 4; player/steps.gd; Greg, 27 Sep 2026: "sound effects like quiet footsteps and
## doors etc might be good"): a step every stride, 0.72 m walking and 1.15 m running; wood underfoot on a plank; a
## teleport is no step, and nor is standing still.

const PlayerScript := preload("res://player/player.gd")

var player: CharacterBody3D


func before_each() -> void:
	player = PlayerScript.new()
	player.third_person = true
	add_child_autofree(player)
	player.global_position = Vector3(0, 0.05, 0)


func _slab(called: String) -> void:
	var b := StaticBody3D.new()
	b.name = called
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 0.2, 60)
	cs.shape = box
	b.add_child(cs)
	add_child_autofree(b)
	b.global_position = Vector3(0, -0.1, 0)


func _count() -> int:
	return (player.get_node("Steps").get("steps") as Array).size()


## Walks (or runs) forward for `frames` physics frames; returns [metres, steps].
func _go(run: bool, frames: int) -> Array:
	await wait_physics_frames(6)
	var p0 := player.global_position
	var n0 := _count()
	player.scripted = true
	player.scripted_move = Vector3(0.0, 1.0 if run else 0.0, -1.0)
	await wait_physics_frames(frames)
	player.scripted_move = Vector3.ZERO
	var d := Vector2(player.global_position.x - p0.x, player.global_position.z - p0.z).length()
	return [d, _count() - n0]


func test_a_step_every_stride_walking() -> void:
	_slab("ground")
	var r: Array = await _go(false, 300)
	assert_gt(float(r[0]), 5.0, "walked some way")
	assert_almost_eq(float(r[1]), float(r[0]) / 0.72, 1.5, "a step every 0.72 m")


func test_longer_strides_running() -> void:
	_slab("ground")
	var r: Array = await _go(true, 300)
	assert_gt(float(r[0]), 12.0, "ran some way")
	assert_almost_eq(float(r[1]), float(r[0]) / 1.15, 2.0, "a step every 1.15 m")


func test_wood_on_a_plank() -> void:
	_slab("plank")
	await wait_physics_frames(6)
	assert_eq(String(player.get_node("Steps").call("surface")), "wood")
	var r: Array = await _go(false, 120)
	assert_gt(int(r[1]), 0, "steps")
	var steps: Array = player.get_node("Steps").get("steps")
	assert_eq(steps[-1], "wood", "each on the wood")


func test_no_step_standing_or_teleported() -> void:
	_slab("ground")
	await wait_physics_frames(30)
	var n0 := _count()
	player.global_position = Vector3(12.0, 0.05, -8.0)
	await wait_physics_frames(30)
	assert_eq(_count() - n0, 0, "no step for standing still, nor for a jump across the map")
