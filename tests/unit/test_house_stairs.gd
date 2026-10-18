extends GutTest
## The town houses' outside stairs stand solid (Greg's walk, 27 Sep 2026: "when I try to climb the stairs in front of
## each house ... I just walk straight through them"): each B house carries its flight's collision ramp, with its steps
## (the shape's `stair` metadata, addons/dungkardo_import), and a ray down onto the flight's middle meets it.

const TYPES := ["town_house_b1_v1", "town_house_b2_v1", "town_house_b3_v1", "town_house_b4_v1", "workshop_tailor_v1", "headman_house_v1"]


func test_every_outside_stair_is_solid() -> void:
	for k in TYPES.size():
		var t: String = TYPES[k]
		var path := "res://assets/generated/kit/types/%s.glb" % t
		if not ResourceLoader.exists(path):
			fail_test("%s not built" % t)
			continue
		var house: Node3D = (load(path) as PackedScene).instantiate()
		add_child_autofree(house)
		house.position = Vector3(60.0 * k, -100.0, 0.0)  # each its own place: a ray must meet its own house
		await wait_physics_frames(2)
		var flights: Array = []
		for s in house.find_children("*", "CollisionShape3D", true, false):
			if (s as Node).has_meta("stair"):
				flights.append(s)
		assert_gt(flights.size(), 0, "%s: its outside stair's ramp" % t)
		for s in flights:
			var st: Dictionary = (s as Node).get_meta("stair")
			var toe: Vector3 = house.global_transform * (st["toe"] as Vector3)
			var dir: Vector3 = (house.global_transform.basis * (st["dir"] as Vector3)).normalized()
			var mid := toe + dir * float(st["run"]) * float(st["n"]) * 0.5
			var tread := mid + Vector3(0.0, float(st["rise"]) * float(st["n"]) * 0.5, 0.0)
			# from a metre over the tread's height, clear of a gallery or a passage's roof above it
			var q := PhysicsRayQueryParameters3D.create(tread + Vector3(0.0, 1.0, 0.0), tread - Vector3(0.0, 1.5, 0.0))
			var hit := house.get_world_3d().direct_space_state.intersect_ray(q)
			assert_false(hit.is_empty(), "%s: a foot on the flight's middle meets it" % t)
			if not hit.is_empty():
				var want := (st["toe"] as Vector3).y + float(st["rise"]) * float(st["n"]) * 0.5
				assert_almost_eq((hit["position"] as Vector3).y - house.global_position.y, want, 0.45, "%s: at its height" % t)
