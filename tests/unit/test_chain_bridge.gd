extends GutTest
## The chain bridge's sway (M2 sprint 4, step 2; world/chain_bridge.gd; chapter 06's amounts: about 0.15 m sideways and
## 0.08 m down at a walker's footfalls, to about 0.3 m when four or more walk out of step, damped in 3 s), and the bridge
## as built (../tibet-blender export_samkha.py): its deck underfoot along its sag and its sides walled to the hand chains.

const ChainBridge := preload("res://world/chain_bridge.gd")
const KIT := "res://assets/generated/kit/samkha/sam03_chain_bridge.glb"


func _bridge() -> Node:
	var b := ChainBridge.new()
	add_child_autofree(b)
	b.set_physics_process(false)
	b.p0 = Vector3(0.0, 0.0, 0.0)
	b.p1 = Vector3(0.0, 4.5, -48.0)
	b.length = 48.0
	b.rng.seed = 7
	return b


func _walk(b: Node, walkers: Array, seconds: float) -> Vector2:
	var most := Vector2.ZERO
	var since := []
	for w in walkers:
		since.append(randf() * b.STEP_S)
	var dt := 1.0 / 60.0
	for n in int(seconds / dt):
		for k in walkers.size():
			since[k] += dt
			if since[k] >= b.STEP_S:
				since[k] -= b.STEP_S
				b.kick(float(walkers[k]))
		b.step(dt)
		most = Vector2(maxf(most.x, absf(b.a.x)), maxf(most.y, absf(b.a.y)))
	return most


func test_one_walker_sways_it_a_little() -> void:
	var b := _bridge()
	seed(11)
	var most := _walk(b, [0.5], 12.0)
	assert_between(most.x, 0.08, 0.22, "one walker at its middle: about 0.15 m sideways")
	assert_between(most.y, 0.04, 0.12, "and about 0.08 m down")


func test_four_out_of_step_sway_it_more() -> void:
	var b := _bridge()
	seed(12)
	var one := _walk(b, [0.5], 12.0).x
	var b4 := _bridge()
	seed(12)
	var four := _walk(b4, [0.35, 0.45, 0.55, 0.62], 12.0).x
	assert_gt(four, one, "four walking out of step sway it more than one")
	assert_between(four, 0.2, 0.33, "to about 0.3 m")


func test_it_settles_in_three_seconds() -> void:
	var b := _bridge()
	b.a = Vector2(0.3, -0.08)
	b.v = Vector2.ZERO
	var dt := 1.0 / 60.0
	for n in int(3.0 / dt):
		b.step(dt)
	assert_lt(absf(b.a.x), 0.3 * 0.08, "a sway left alone dies to under a tenth in 3 s")


func test_the_bridge_holds_the_walker() -> void:
	if not ResourceLoader.exists(KIT):
		fail_test("the chain bridge not built (../tibet-blender export_samkha.py)")
		return
	var sk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/samkha.json"))
	var deck: Array = sk["bridge"]["deck"]
	var n0 := float(sk["bridge"]["north"][0])
	var z0 := float(sk["bridge"]["north"][1])
	var g: Node3D = (load(KIT) as PackedScene).instantiate()
	add_child_autofree(g)
	g.position = Vector3(0.0, -600.0, 0.0)
	await wait_physics_frames(2)
	for k in [3, 8, 12, 18, 22]:
		var q: Array = deck[k]
		var y := absf(float(q[0]) - n0)
		var dz := float(q[1]) - z0
		var space := g.get_world_3d().direct_space_state
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(g.global_transform * Vector3(0.0, dz + 2.0, -y), g.global_transform * Vector3(0.0, dz - 2.0, -y)))
		assert_false(hit.is_empty(), "its deck underfoot %.0f m out" % y)
		if not hit.is_empty():
			assert_almost_eq((g.global_transform.affine_inverse() * (hit["position"] as Vector3)).y, dz, 0.15, "on its sag")
		var side := space.intersect_ray(PhysicsRayQueryParameters3D.create(g.global_transform * Vector3(0.0, dz + 0.7, -y), g.global_transform * Vector3(3.0, dz + 0.7, -y)))
		assert_false(side.is_empty(), "walled to its hand chains %.0f m out: nobody falls" % y)
