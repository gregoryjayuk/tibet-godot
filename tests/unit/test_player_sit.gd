extends GutTest
## Sitting (chapter 11, 13.1 and 15.1): with a ledge 0.3-0.65 m high a step behind, the player sits on it; with none,
## kneels; seated, time runs at the watch rate, 60:1. Needs the player's bodies (../tibet-blender/people2/body.py).

const PlayerScript := preload("res://player/player.gd")
const BODY := "res://assets/generated/people/player_man.glb"

var player: CharacterBody3D


func before_each() -> void:
	player = PlayerScript.new()
	player.third_person = true
	add_child_autofree(player)
	player.global_position = Vector3(0, 0.05, 0)
	player.facing = 0.0  # facing -Z: behind is +Z
	_slab(Vector3(6, 0.2, 6), Vector3(0, -0.1, 0))


func after_each() -> void:
	WorldClock.rate = WorldClock.RATE_PLAY


func _slab(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	b.add_child(cs)
	add_child_autofree(b)
	b.global_position = at


func test_sits_on_a_ledge_behind() -> void:
	if not ResourceLoader.exists(BODY):
		pending("no player body: run ../tibet-blender/people2/body.py")
		return
	_slab(Vector3(2.0, 0.45, 0.5), Vector3(0, 0.225, 0.56))  # a step 0.45 m high, from 0.31 m behind
	await wait_physics_frames(6)
	player.sit()
	assert_eq(player.rest_kind, "chair", "a ledge at seat height: sit on it")
	assert_almost_eq(player.seat_height, 0.45, 0.06)


func test_kneels_where_there_is_no_ledge() -> void:
	if not ResourceLoader.exists(BODY):
		pending("no player body: run ../tibet-blender/people2/body.py")
		return
	await wait_physics_frames(6)
	player.sit()
	assert_eq(player.rest_kind, "kneel")


func test_time_watches_while_seated() -> void:
	if not ResourceLoader.exists(BODY):
		pending("no player body: run ../tibet-blender/people2/body.py")
		return
	await wait_physics_frames(6)
	player.sit()
	await wait_seconds(0.8)  # kneeling takes 0.4 s
	await wait_physics_frames(2)
	assert_eq(player.rest, PlayerScript.Rest.SEATED)
	assert_eq(WorldClock.rate, WorldClock.RATE_WATCH, "seated: 60:1")
	player.stand()
	await wait_seconds(0.6)
	await wait_physics_frames(2)
	assert_eq(WorldClock.rate, WorldClock.RATE_PLAY, "standing again: 6:1")
