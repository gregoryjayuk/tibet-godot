extends GutTest
## The third-person camera (M1 sprint 2, step 4; plan chapter 11, 13.1): its arm shortens against a wall behind the
## player and stays under a 2.4 m ceiling, the height of the town's passages, so the camera keeps its head indoors.

const PlayerScript := preload("res://player/player.gd")

var player: CharacterBody3D
var props: Array = []


func before_each() -> void:
	player = PlayerScript.new()
	player.third_person = true
	player.scripted = true
	add_child_autofree(player)
	player.global_position = Vector3(0, 0.05, 0)
	player.yaw = 0.0
	player.pitch = 0.0


func _slab(size: Vector3, at: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	body.add_child(cs)
	add_child_autofree(body)
	body.global_position = at


func test_the_arm_is_full_in_the_open() -> void:
	_slab(Vector3(20, 0.2, 20), Vector3(0, -0.1, 0))  # the ground
	await wait_physics_frames(3)
	await wait_process_frames(3)
	assert_almost_eq(player.arm_len, Vector2(PlayerScript.ARM.y, PlayerScript.ARM.z).length(), 0.05, "nothing in the way: the whole arm")


func test_the_arm_shortens_against_a_wall() -> void:
	_slab(Vector3(20, 0.2, 20), Vector3(0, -0.1, 0))
	_slab(Vector3(8, 6, 0.4), Vector3(0, 3, 1.2))  # a wall 1 m behind (the camera looks along -Z, the arm reaches +Z)
	await wait_physics_frames(3)
	await wait_process_frames(3)
	assert_lt(player.arm_len, 1.1, "the arm stops short of the wall")
	assert_lt(player.cam.global_position.z, 1.0 - PlayerScript.PROBE * 0.5, "the camera stays in front of the wall")


## Sprint 7: with a wall close behind (a doorway, a small room) the arm has no room: the view goes to the eyes and the
## body is hidden, and comes back over the shoulder once there is room again.
func test_cramped_the_view_goes_to_the_eyes() -> void:
	_slab(Vector3(20, 0.2, 20), Vector3(0, -0.1, 0))
	_slab(Vector3(8, 6, 0.4), Vector3(0, 3, 0.75))  # a wall 0.55 m behind
	await wait_physics_frames(3)
	await wait_process_frames(3)
	assert_true(player.cramped, "no room for the arm: cramped")
	assert_almost_eq(player.cam.global_position.y, player.global_position.y + PlayerScript.EYE, 0.05, "the camera at the eyes")
	if player.body != null:
		assert_false(player.body.visible, "the body hidden")
	player.global_position = Vector3(0, 0.05, -4.0)  # walked away from the wall
	await wait_physics_frames(3)
	await wait_process_frames(3)
	assert_false(player.cramped, "room again: back over the shoulder")


func test_the_camera_stays_under_a_low_ceiling() -> void:
	_slab(Vector3(20, 0.2, 20), Vector3(0, -0.1, 0))
	_slab(Vector3(20, 0.2, 20), Vector3(0, 2.5, 0))  # a passage 2.4 m high
	player.pitch = -0.6  # looking down, so the arm reaches up and back
	await wait_physics_frames(3)
	await wait_process_frames(3)
	assert_lt(player.cam.global_position.y, 2.4, "the camera is under the ceiling")
	assert_gt(player.cam.global_position.y, 1.0, "and still above the shoulders")
