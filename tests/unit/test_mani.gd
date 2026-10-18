extends GutTest
## Sprint 4, step 3: the great wheel turns only clockwise, with the walker (world/great_wheel.gd), and a walker going the
## wrong way along the mani wall is told once how its lane is walked (world/mani_wall.gd). Both read the node in the
## group "player" and gloss through the node in the group "hud"; here a bare body and a stand-in HUD that records.

const GreatWheel := preload("res://world/great_wheel.gd")
const ManiWall := preload("res://world/mani_wall.gd")


class Hud:
	extends Node
	var keys: Array[String] = []

	func gloss(_text: String, key := "") -> void:
		if not keys.has(key):
			keys.append(key)


var walker: CharacterBody3D
var hud: Hud


func before_each() -> void:
	walker = CharacterBody3D.new()
	walker.add_to_group("player")
	add_child_autofree(walker)
	hud = Hud.new()
	hud.add_to_group("hud")
	add_child_autofree(hud)


func _run(node: Node, seconds: float) -> void:
	for k in int(seconds * 30.0):
		node._physics_process(1.0 / 30.0)


func test_the_wheel_turns_clockwise_with_the_walker() -> void:
	var wheel: Node3D = GreatWheel.new()
	add_child_autofree(wheel)
	walker.global_position = Vector3(2.2, 0.0, 0.0)  # east of the axis, among the bars
	walker.velocity = Vector3(0.0, 0.0, 1.3)  # south: clockwise seen from above
	_run(wheel, 1.0)
	assert_almost_eq(float(wheel.get("omega")), 1.3 / 2.2, 0.01, "it turns at the walker's own pace round it")
	assert_lt(wheel.rotation.y, 0.0, "clockwise from above, about +Y")
	assert_false(hud.keys.has("great_wheel"), "a tenth of a turn says nothing yet")
	_run(wheel, 2.0)
	assert_true(hud.keys.has("great_wheel"), "the first quarter turn brings its gloss")


func test_the_wheel_is_not_turned_backwards() -> void:
	var wheel: Node3D = GreatWheel.new()
	add_child_autofree(wheel)
	walker.global_position = Vector3(2.2, 0.0, 0.0)
	walker.velocity = Vector3(0.0, 0.0, -1.3)  # north: anticlockwise
	_run(wheel, 2.0)
	assert_eq(float(wheel.get("turns")), 0.0, "walked round the other way it does not turn")


func test_the_wheel_runs_down_and_rings_each_turn() -> void:
	var wheel: Node3D = GreatWheel.new()
	add_child_autofree(wheel)
	walker.global_position = Vector3(2.2, 0.0, 0.0)
	walker.velocity = Vector3(0.0, 0.0, 1.3)
	_run(wheel, 1.0)
	walker.global_position = Vector3(6.0, 0.0, 0.0)  # let go: out of reach of the bars
	_run(wheel, 8.0)
	assert_eq(float(wheel.get("omega")), 0.0, "let go, it stops within eight seconds")
	wheel.set("turns", 0.0)
	wheel.set("rings", 0)
	walker.global_position = Vector3(2.2, 0.0, 0.0)
	_run(wheel, 2.2 * TAU / 1.3 * 2.0 + 0.5)  # two turns' walking (held at a tangent, the push stays on)
	assert_eq(int(wheel.get("rings")), int(float(wheel.get("turns"))), "the bell rings once each whole turn")
	assert_gte(int(wheel.get("rings")), 2, "two turns, two strokes")


func test_the_wall_is_kept_on_the_right() -> void:
	var wall: Node3D = ManiWall.new()
	wall.set("a", Vector3(0.0, 0.0, 0.0))  # its west end
	wall.set("b", Vector3(20.0, 0.0, 0.0))  # its east end (east is +x; north is -z)
	add_child_autofree(wall)
	walker.global_position = Vector3(10.0, 0.0, -2.0)  # on its north side
	walker.velocity = Vector3(1.3, 0.0, 0.0)  # going east: the wall on the right
	_run(wall, 4.0)
	assert_false(hud.keys.has("mani_wall"), "east on the north side is the way")
	walker.global_position = Vector3(10.0, 0.0, 2.0)  # on its south side
	walker.velocity = Vector3(-1.3, 0.0, 0.0)  # going west: the wall on the right
	_run(wall, 4.0)
	assert_false(hud.keys.has("mani_wall"), "west on the south side is the way")
	walker.velocity = Vector3(1.3, 0.0, 0.0)  # east on the south side: the wall on the left
	_run(wall, 2.5)
	assert_false(hud.keys.has("mani_wall"), "a moment the wrong way says nothing")
	_run(wall, 1.0)
	assert_true(hud.keys.has("mani_wall"), "three seconds the wrong way brings the gloss")
