extends GutTest
## Dechen-tsang at night (M2 sprint 8, step 4; plan chapter 04, 4.3: "22:00 Gate barred; mastiffs loose in Yard 1";
## "at night the bard's fire in Yard 2 and a lantern at the gate"): world/dechen_night.gd's gate shut and barred from
## 22:00 to 05:00, a knock from outside letting the player in, the two mastiffs loose only by night; world/lamps.gd's
## front yard's fire giving way at 21:00 to the bard's in the guest yard, let die from 21:50 before the bar, and the gate's
## lantern dusk to dawn.

const DechenNight := preload("res://world/dechen_night.gd")
const Lamps := preload("res://world/lamps.gd")

var _minute := 0.0


func before_each() -> void:
	_minute = WorldClock.minute


func after_each() -> void:
	WorldClock.minute = _minute


func _night(minute: float) -> Node3D:
	WorldClock.minute = minute
	var house := Node3D.new()
	add_child_autofree(house)
	var n: Node3D = DechenNight.new()
	house.add_child(n)
	if not n.setup():
		return null
	return n


func test_the_gates_hours() -> void:
	assert_true(DechenNight.shut_at(22.0 * 60.0) and DechenNight.shut_at(4.9 * 60.0), "shut from 22:00 to 05:00")
	assert_false(DechenNight.shut_at(21.9 * 60.0) or DechenNight.shut_at(5.0 * 60.0) or DechenNight.shut_at(15.0 * 60.0), "open by day")


func test_shut_and_barred_at_night() -> void:
	var n := _night(23.0 * 60.0)
	if n == null:
		pending("no gate (the kit's dechen_gate_leaf, dechen_gate_bar)")
		return
	assert_eq((n.get("leaves") as Array).size(), 2, "two leaves")
	assert_true(n.is_shut() and float(n.get("state")) >= 1.0, "barred at 23:00")
	await wait_physics_frames(2)
	assert_false((n.get("block") as CollisionShape3D).disabled, "the gateway closed to a body")
	var d := _night(15.0 * 60.0)
	assert_false(d.is_shut(), "open at 15:00")
	await wait_physics_frames(2)
	assert_true((d.get("block") as CollisionShape3D).disabled, "the way through clear by day")


func test_a_knock_lets_the_player_in() -> void:
	var n := _night(23.0 * 60.0)
	if n == null:
		pending("no gate")
		return
	var outside := n.to_global(Vector3(0.0, 1.0, DechenNight.HINGE_Z + 1.6))
	var inside := n.to_global(Vector3(0.0, 1.0, DechenNight.HINGE_Z - 3.0))
	assert_false(n.knock(inside), "no knock from the yard")
	assert_true(n.knock(outside), "heard from the street")
	n._process(0.1)
	assert_false(n.is_shut(), "the bar drawn, the gate opening")
	WorldClock.minute += DechenNight.LET_IN + 1.0
	n._process(0.1)
	assert_true(n.is_shut(), "barred again once the player is through")


func test_the_mastiffs_only_by_night() -> void:
	var n := _night(23.0 * 60.0)
	if n == null or (n.get("dogs") as Array).is_empty():
		pending("no mastiff body: ../tibet-blender people2/stand_ins.py -- mastiff")
		return
	n._process(0.1)
	for d in n.get("dogs"):
		assert_true((d["node"] as Node3D).visible, "loose in Yard 1 at 23:00")
	WorldClock.minute = 10.0 * 60.0
	n._process(0.1)
	for d in n.get("dogs"):
		assert_false((d["node"] as Node3D).visible, "chained out of sight by day")


func test_the_fires_and_the_lantern() -> void:
	assert_gt(Lamps.lit("fire", 0, 19.0 * 60.0), 0.9, "the front yard's fire at 19:00")
	assert_almost_eq(Lamps.lit("fire", 0, 21.5 * 60.0), 0.0, 0.01, "out by 21:30")
	assert_almost_eq(Lamps.lit("fire2", 0, 20.0 * 60.0), 0.0, 0.01, "the guest yard's not yet at 20:00")
	assert_gt(Lamps.lit("fire2", 0, 21.5 * 60.0), 0.9, "the bard's fire at 21:30")
	assert_almost_eq(Lamps.lit("fire2", 0, 23.0 * 60.0), 0.0, 0.01, "out by 23:00")
	assert_eq(Lamps.lit("lantern", 0, 23.0 * 60.0), 1.0, "the gate's lantern at night")
	assert_eq(Lamps.lit("lantern", 0, 12.0 * 60.0), 0.0, "and not by day")
