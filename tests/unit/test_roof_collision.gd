extends GutTest
## Sprint 3, step 3 (plan chapter 03, 2.5: the roof is the town's second street; chapter 11, 13.3): what the player walks
## on over a town house's roof. On a grid over each house type's roof, the floor the capsule stands on (the kit's
## convex hulls) must be the roof's own surface within a few centimetres, never an invisible slab at the parapet's top
## or over the fuel stacks, and a standing body must fit on the open roof. STAIR_DEBUG=1 prints the worst points.

const KIT := "res://assets/generated/kit/types/%s.glb"
const TYPES := ["town_house_b1_v1", "town_house_b2_v1", "town_house_b2_s2_v1", "town_house_b3_v1", "poor_house_e1_v1", "trading_house_v1",
		"log_house_a1_v1", "log_house_a2_v1", "log_house_a3_v1", "log_house_a4_v1"]


func _visible(root: Node3D) -> void:
	for mi in root.find_children("*_L0", "MeshInstance3D", true, false):
		var sb := StaticBody3D.new()
		sb.collision_layer = 2
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		cs.shape = (mi as MeshInstance3D).mesh.create_trimesh_shape()
		sb.add_child(cs)
		root.add_child(sb)
		sb.global_transform = (mi as MeshInstance3D).global_transform


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, mask)
	q.hit_from_inside = true
	return space.intersect_ray(q)


func test_roofs_are_walked_on_their_surface() -> void:
	var worst_all := 0.0
	var bad_types := []
	for ti in TYPES.size():
		var t: String = TYPES[ti]
		if not ResourceLoader.exists(KIT % t):
			continue
		var root: Node3D = (load(KIT % t) as PackedScene).instantiate()
		root.position.x = 60.0 * ti  # each type on its own ground: at one origin a lower roof was measured under a taller one's
		add_child_autofree(root)
		_visible(root)
		await wait_physics_frames(2)
		var space := root.get_world_3d().direct_space_state
		var hatches := root.find_children("SOCK_HATCH*", "Marker3D", true, false)
		if hatches.is_empty():
			gut.p("%s: no HATCH socket" % t)
			continue
		var n := 0
		var high := 0
		var worst := 0.0
		var where := Vector3.ZERO
		var roof_y := 0.0
		# Every roof: a grid 7 m square round each hatch, at the hatch's level (a trading house has a roof on each range).
		for hatch in hatches:
			roof_y = (hatch as Marker3D).global_position.y
			var hx: float = (hatch as Marker3D).global_position.x
			var hz: float = (hatch as Marker3D).global_position.z
			var x := hx - 3.5
			while x <= hx + 3.5:
				var z := hz - 3.5
				while z <= hz + 3.5:
					var from := Vector3(x, roof_y + 3.0, z)
					var to := Vector3(x, roof_y - 1.0, z)
					var vis := _ray(space, from, to, 2)
					var col := _ray(space, from, to, 1)
					# Only where the visible surface is the roof itself (within 0.15 m of the hatch's level, and level: a ray
					# grazing the parapet's outer face is not the roof).
					if not vis.is_empty() and absf((vis["position"] as Vector3).y - roof_y) < 0.15 and (vis["normal"] as Vector3).y > 0.9:
						n += 1
						var d: float = ((col["position"] as Vector3).y if not col.is_empty() else roof_y - 1.0) - (vis["position"] as Vector3).y
						if absf(d) > 0.1:
							high += 1
							if OS.get_environment("STAIR_DEBUG") != "":
								gut.p("  %s %.1f, %.1f: drawn %.2f, floor %s" % [t, x - root.position.x, z, (vis["position"] as Vector3).y, str((col["position"] as Vector3).y) if not col.is_empty() else "none"])
							if absf(d) > absf(worst):
								worst = d
								where = Vector3(x, 0.0, z)
					z += 0.5
				x += 0.5
		gut.p("%s: %d roofs, %d points on them, %d with the floor off the roof by more than 0.1 m (worst %+.2f m at %.1f, %.1f)" % [t, hatches.size(), n, high, worst, where.x - root.position.x, where.z])
		worst_all = maxf(worst_all, absf(worst))
		if high > 0 or n < 50:
			bad_types.append(t)
	assert_eq(bad_types, [], "every roof walked on its own surface")
