extends GutTest
## The hand prayer wheels (characters/hand_wheel.gd; ISS-124): the elders and the crowd's townsman_b carry a wheel on a
## bone of its own under the right hand, the plain townsman none; turning it moves the drum round its axis and leaves the
## hand where the clip has it; clockwise as seen from the drum's top, a whole turn in 1/RATE seconds.

const HandWheel := preload("res://characters/hand_wheel.gd")


func _body(key: String) -> Node3D:
	var b: Node3D = (load("res://assets/generated/people/%s.glb" % key) as PackedScene).instantiate()
	add_child_autofree(b)
	return b


func test_who_carries_one() -> void:
	for k in ["elder_man", "elder_woman", "townsman_b"]:
		assert_false(HandWheel.of(_body(k)).is_empty(), "%s: a wheel" % k)
	assert_true(HandWheel.of(_body("townsman")).is_empty(), "the townsman: none")


func test_it_turns_about_its_axis() -> void:
	var w := HandWheel.of(_body("elder_woman"))
	var sk: Skeleton3D = w[0]
	var bone: int = w[1]
	var hand := sk.find_bone("hand_r")
	var axis := sk.get_bone_global_rest(bone).basis.y.normalized()  # the drum's axis, along its bone
	HandWheel.spin(w, 0.0, 0.0)
	var hand0 := sk.get_bone_global_pose(hand)
	var at0 := sk.get_bone_global_pose(bone)
	HandWheel.spin(w, 0.25 / HandWheel.RATE, 0.0)  # a quarter turn on
	var at1 := sk.get_bone_global_pose(bone)
	assert_almost_eq(at1.origin.distance_to(at0.origin), 0.0, 0.0001, "the drum stays on its handle")
	assert_true(sk.get_bone_global_pose(hand).is_equal_approx(hand0), "the hand as the clip has it")
	var x0 := at0.basis.x.normalized()
	var x1 := at1.basis.x.normalized()
	assert_almost_eq(x0.dot(x1), 0.0, 0.01, "a quarter turn")
	assert_lt(x0.cross(x1).dot(axis), 0.0, "clockwise seen from the drum's top")
	HandWheel.spin(w, 1.0 / HandWheel.RATE, 0.0)
	assert_true(sk.get_bone_global_pose(bone).basis.is_equal_approx(at0.basis), "a whole turn in 1/RATE seconds")
