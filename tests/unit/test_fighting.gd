extends GutTest
## Spike S19, fists and the sling (plan chapter 11, 13.8): the parts that can be checked without a body. The stone's
## launch solution passes through the point it was aimed at; a fist's swept path finds a body the frames straddle;
## the HUD's aiming dot shows at the screen's centre while the sling is out, and only then.

const Fighting := preload("res://characters/fighting.gd")
const STONE := preload("res://props/sling_stone.gd")
const Hud := preload("res://ui/hud.gd")


class FakeFight:
	extends Node
	var sling := false


class FakePlayer:
	extends Node
	var fight: FakeFight


class Catcher:  # stands in for the player, which takes its clicks and mouse motion in _unhandled_input
	extends Node
	var events := 0

	func _unhandled_input(e: InputEvent) -> void:
		if e is InputEventMouseButton or e is InputEventMouseMotion:
			events += 1


## Where a stone launched with `v` from `from` is when it has come `x` metres across, under gravity alone.
func _height_at(from: Vector3, v: Vector3, x: float) -> float:
	var t := x / Vector2(v.x, v.z).length()
	return from.y + v.y * t - 0.5 * 9.8 * t * t


func test_the_stone_passes_through_the_aimed_point() -> void:
	for c in [[Vector3(0, 1.5, 0), Vector3(-15, 1.35, 0.5), 20.0], [Vector3(0, 1.5, 0), Vector3(-6, 0.3, -3), 12.0],
			[Vector3(2, 1.4, 1), Vector3(-25, 4.0, 10), 28.0]]:
		var from: Vector3 = c[0]
		var to: Vector3 = c[1]
		var v := STONE.launch(from, to, c[2])
		assert_almost_eq(v.length(), float(c[2]), 0.001, "loosed at the sling's speed")
		var across := Vector2(to.x - from.x, to.z - from.z)
		assert_almost_eq(Vector2(v.x, v.z).normalized().dot(across.normalized()), 1.0, 0.0001, "straight at it")
		assert_almost_eq(_height_at(from, v, across.length()), to.y, 0.02, "and at its height when it gets there")


func test_out_of_reach_the_stone_goes_at_45_degrees() -> void:
	var v := STONE.launch(Vector3.ZERO, Vector3(-60, 0, 0), 12.0)  # 12 m/s carries 14.7 m at best
	assert_almost_eq(v.y, Vector2(v.x, v.z).length(), 0.001)


func test_a_fist_finds_a_body_between_two_frames() -> void:
	var man := CharacterBody3D.new()
	add_child_autofree(man)
	man.global_position = Vector3(0, 0, 0)
	var f := Fighting.new()
	f.fighter = man
	add_child_autofree(f)
	# a fist at chest height going 0.6 m from one side of the body line to the other in one frame
	assert_almost_eq(f.gap(Vector3(-0.3, 1.3, 0.1), Vector3(0.3, 1.3, 0.1)), 0.1, 0.001, "the path passes 0.1 m from it")
	assert_gt(f.gap(Vector3(-0.3, 1.3, 0.1), Vector3(-0.3, 1.3, 0.1)), 0.3, "either end alone is further")
	assert_almost_eq(f.gap(Vector3(0, 2.0, 0), Vector3(0, 2.0, 0)), 0.35, 0.001, "above the head: from the top of the line")


func test_the_aiming_dot_shows_at_the_centre_with_the_sling() -> void:
	var p := FakePlayer.new()
	p.fight = FakeFight.new()
	p.add_child(p.fight)
	add_child_autofree(p)
	var hud := Hud.new()
	hud.player = p
	add_child_autofree(hud)
	await wait_process_frames(2)
	assert_false(hud.dot.visible, "no dot with fists")
	p.fight.sling = true
	await wait_process_frames(2)
	assert_true(hud.dot.visible, "the dot with the sling out")
	var centre := hud.dot.get_global_rect().get_center()
	var screen := hud.get_viewport().get_visible_rect().get_center()
	assert_almost_eq(centre.x, screen.x, 1.0, "at the screen's centre")
	assert_almost_eq(centre.y, screen.y, 1.0)


## Greg, 25 Sep 2026, 21:09: with the sling out "there's no way to then aim or whirl". The captured mouse sits at the
## screen's centre, under the dot, and a control that stops the mouse swallows every click and motion there. Tested in a
## viewport of its own (GUT's panel covers the centre of the test window), with the dot set back to stopping the mouse
## as the control: the harness must see the fault it guards against.
func test_the_dot_lets_the_mouse_through() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	add_child_autofree(vp)
	var p := FakePlayer.new()
	p.fight = FakeFight.new()
	p.add_child(p.fight)
	p.fight.sling = true
	vp.add_child(p)
	var hud := Hud.new()
	hud.player = p
	vp.add_child(hud)
	var c := Catcher.new()
	vp.add_child(c)
	await wait_process_frames(2)
	assert_true(hud.dot.visible, "the dot is up")
	_mouse_at(vp, hud.dot.get_global_rect().get_center())
	assert_eq(c.events, 2, "the click and the motion at the dot reach the game")
	hud.dot.mouse_filter = Control.MOUSE_FILTER_STOP
	_mouse_at(vp, hud.dot.get_global_rect().get_center())
	assert_eq(c.events, 2, "the control: a dot that stops the mouse swallows both")


func _mouse_at(vp: Viewport, at: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	click.global_position = at
	vp.push_input(click)
	var move := InputEventMouseMotion.new()
	move.position = at
	move.global_position = at
	move.relative = Vector2(4, 0)
	vp.push_input(move)
