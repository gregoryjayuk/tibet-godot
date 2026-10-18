extends GutTest
## Boots off in the halls and the Gönkhang's rule (M3 sprint 6, step 2; plan chapter 04, 9 "Shoes" and 3.3; world/boots.gd):
## the halls whose rooms take the boots off; the player stockinged and stooped a second, soft-footed while they are off;
## the keeper's reach before the Gönkhang's curtain; his line in chapter 07's data.

const Boots := preload("res://world/boots.gd")
const PlayerScript := preload("res://player/player.gd")
const Barks := preload("res://world/barks.gd")

var player: CharacterBody3D


func before_each() -> void:
	player = PlayerScript.new()
	player.third_person = true
	add_child_autofree(player)
	player.global_position = Vector3(0, 0.05, 0)
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	cs.shape = box
	b.add_child(cs)
	add_child_autofree(b)
	b.global_position = Vector3(0, -0.1, 0)


func test_the_halls() -> void:
	for r in ["tsokchen_nave", "tsokchen_chapel", "jampa_ground", "gonkhang_room", "kangyur_room", "labrang_reception", "parkhang_chapel"]:
		assert_true(Boots.in_hall(r), "%s: boots off" % r)
	for r in ["dechen_tibetan", "jakhang_room", "monk_cell", "parkhang_printing", "headman_kitchen"]:
		assert_false(Boots.in_hall(r), "%s: boots on" % r)


func test_stockinged_and_stooped() -> void:
	await wait_physics_frames(4)
	player.scripted = true
	player.scripted_move = Vector3(0.0, 1.0, -1.0)
	player.boots_off(true, 1.0)
	assert_true(player.bare_feet, "the boots off")
	var meshes: Array = []
	var bodies: Dictionary = player.get("_bodies")
	for k in bodies:
		meshes.append_array((bodies[k][0] as Node).find_children("*", "GeometryInstance3D", true, false))
	if meshes.is_empty():
		pending("no player bodies (../tibet-blender people2/body.py)")
	else:
		assert_eq(float((meshes[0] as GeometryInstance3D).get_instance_shader_parameter("bare")), 1.0, "drawn stockinged")
	await wait_physics_frames(10)
	assert_lt(Vector2(player.velocity.x, player.velocity.z).length(), 0.1, "still for a second, bent to them")
	await wait_physics_frames(30)
	assert_gt(Vector2(player.velocity.x, player.velocity.z).length(), 1.0, "and on again")
	var steps: Node = player.get_node("Steps")
	assert_eq(String(steps.call("surface")), "rug", "soft-footed in stockings")
	player.boots_off(false, 1.0)
	assert_false(player.bare_feet, "the boots on again")
	if not meshes.is_empty():
		assert_eq(float((meshes[0] as GeometryInstance3D).get_instance_shader_parameter("bare")), 0.0, "drawn booted")
	player.scripted_move = Vector3.ZERO


func test_the_keepers_reach() -> void:
	assert_true(Boots.at_the_curtain(Vector3(0.0, 0.0, 1.0)), "a metre out before the curtain: stopped")
	assert_true(Boots.at_the_curtain(Vector3(0.8, 0.0, 0.2)), "at its side, close")
	assert_false(Boots.at_the_curtain(Vector3(0.0, 0.0, 3.0)), "three metres out on the porch: free")
	assert_false(Boots.at_the_curtain(Vector3(0.0, 0.0, -1.5)), "inside: never (a man went in)")


func test_his_line() -> void:
	var l: Dictionary = Barks.line(Boots.LINE)
	assert_ne(String(l.get("script", "")), "", "PB-T62 in Tibetan (chapter 07)")
	assert_string_contains(String(l.get("english", "")), "rule", "the monastery's rule, not the game's opinion (chapter 04, 3.3)")


class FakeRoom:
	extends Node
	var room_id := "gonkhang_room"


class FakeInteriors:
	extends Node
	var room: Node = null

	func room_at(_p: Vector3) -> Node:
		return room


func test_off_in_a_hall_on_again_under_the_sky() -> void:
	await wait_physics_frames(4)
	var rooms := FakeInteriors.new()
	rooms.add_to_group("interiors")
	add_child_autofree(rooms)
	var room := FakeRoom.new()
	add_child_autofree(room)
	var b := Boots.new()
	add_child_autofree(b)
	b.set_physics_process(false)  # (after it is in the tree: its ready turns it on) the test steps it
	rooms.room = room
	b.call("_boots", player)
	assert_true(b.off, "into the Gönkhang's room: the boots off")
	assert_true(player.bare_feet, "the player stockinged")
	if ResourceLoader.exists(Boots.KIT % "boots_player_man"):
		assert_not_null(b.pair, "the boots stood by the door")
	rooms.room = null
	var roof := StaticBody3D.new()  # out of the room, still under the hall's roof (its Nangkor, its stair): on still
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 0.3, 6)
	cs.shape = box
	roof.add_child(cs)
	add_child_autofree(roof)
	roof.global_position = player.global_position + Vector3(0, 4.0, 0)
	await wait_physics_frames(2)
	assert_false(bool(b.call("_under_sky", player)), "the roof found overhead")
	b.call("_boots", player)
	assert_true(b.off, "under the roof between rooms: the boots stay off")
	roof.queue_free()
	await wait_physics_frames(2)
	b.call("_boots", player)
	assert_false(b.off, "under the sky: on again")
	assert_false(player.bare_feet, "the player booted")
	assert_null(b.pair, "and the pair taken up")
	room.queue_free()


func test_the_keeper_turns_a_woman_away() -> void:
	await wait_physics_frames(2)
	var g := Node3D.new()
	g.name = "MON-05"
	add_child_autofree(g)
	var d := Node3D.new()
	d.name = "SOCK_DOOR_1"
	g.add_child(d)
	var b := Boots.new()
	add_child_autofree(b)
	b.set_physics_process(false)
	var keepers: int = b.build(self)
	assert_eq(keepers, 1 if ResourceLoader.exists(Boots.KEEPER_BODY) else 0, "the keeper by the Gönkhang's door")
	var keep := [WorldClock.minute, WorldClock.frozen]
	WorldClock.frozen = true
	WorldClock.minute = 600.0  # 10:00, his hours
	player.woman = true
	player.global_position = d.global_position + Vector3(0.0, 0.0, 1.0)  # a metre out before its curtain
	b.call("_rule", player)
	assert_eq(b.bar.collision_layer, 1, "the bar across its doorway for a woman")
	assert_eq(b.turned_away, 1, "turned away, the keeper's gesture and his line")
	b.call("_rule", player)
	assert_eq(b.turned_away, 1, "and not said again at once")
	player.woman = false
	b.call("_rule", player)
	assert_eq(b.bar.collision_layer, 0, "a man goes in")
	WorldClock.minute = keep[0]
	WorldClock.frozen = keep[1]
