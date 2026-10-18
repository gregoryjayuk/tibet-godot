extends GutTest
## The chest in Dechen-tsang's guest room (world/wardrobe.gd; IMP-025, Greg's 1771): what the walker wears changes at
## once, each of the two keeping their own; at the chest the camera stands where the room has most room and the walker
## turns on the spot before it.

const PlayerScript := preload("res://player/player.gd")

var player: CharacterBody3D


func before_each() -> void:
	player = PlayerScript.new()
	player.third_person = true
	player.scripted = true
	add_child_autofree(player)
	player.global_position = Vector3(0, 0.05, 0)


func _slab(size: Vector3, at: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	body.add_child(cs)
	add_child_autofree(body)
	body.global_position = at


func test_every_outfit_built() -> void:
	for k in PlayerScript.OUTFITS:
		for o in PlayerScript.OUTFITS[k]:
			assert_true(ResourceLoader.exists(String(o[1])), "%s's %s: %s (people2/body.py)" % [k, o[0], o[1]])


func test_wear_changes_the_body() -> void:
	_slab(Vector3(20, 0.2, 20), Vector3(0, -0.1, 0))
	await wait_physics_frames(2)
	if player.body == null:
		pending("no player bodies built")
		return
	var old: Node3D = player.body
	assert_true(player.wear(2), "the man into his best")
	assert_eq(int(player.outfit["man"]), 2)
	assert_ne(player.body, old, "another body")
	assert_true(player.body.visible, "and shown")
	assert_false(player.wear(2), "already worn: no change")
	player.woman = true
	player._show_body()
	assert_eq(int(player.outfit["woman"]), 0, "the woman still in her own")
	assert_true(player.wear(1), "the woman into her town clothes")
	assert_eq(int(player.outfit["woman"]), 1)
	assert_eq(int(player.outfit["man"]), 2, "the man's kept")


## A small room open one way: the camera goes that way, the walker turned to it, and stays inside as they turn.
func test_the_camera_where_the_room_has_room() -> void:
	_slab(Vector3(20, 0.2, 20), Vector3(0, -0.1, 0))
	_slab(Vector3(8, 4, 0.3), Vector3(0, 2, 1.05))  # walls 0.9 m off on three sides
	_slab(Vector3(8, 4, 0.3), Vector3(0, 2, -1.05))
	_slab(Vector3(0.3, 4, 8), Vector3(1.05, 2, 0))
	_slab(Vector3(0.3, 4, 8), Vector3(-3.15, 2, 0))  # and 3 m off on the fourth
	await wait_physics_frames(3)
	player.dress(true)
	assert_true(player.dressing)
	assert_almost_eq(player._dress_cam.x, -1.0, 0.05, "the camera on the open side")
	assert_gt(player._dress_reach, 2.0, "back far enough for the whole walker")
	var fwd := Vector3(-sin(player.facing), 0.0, -cos(player.facing))
	assert_gt(fwd.dot(player._dress_cam), 0.95, "the walker turned to the camera")
	var f0: float = player.facing
	await wait_process_frames(20)
	assert_ne(player.facing, f0, "turning")
	var c: Vector3 = player.cam.global_position
	assert_between(c.x, -3.0, -1.0, "the camera inside the room")
	assert_lt(absf(c.z), 0.9)
	var look: Vector3 = -(player.cam as Camera3D).global_transform.basis.z
	assert_gt(look.dot((player.global_position + Vector3(0, 0.9, 0) - c).normalized()), 0.9, "looking at the walker")
	player.dress(false)
	assert_false(player.dressing)
