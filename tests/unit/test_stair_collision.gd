extends GutTest
## Sprint 3, step 3 (ISS-035; plan chapter 11, 13.2): what the player walks on along the Sky Stair. From the foot of the
## talkers' steps at Tsongra (SHL-40), up the stair's 16 flights (SHL-15), through the gateway chorten (SHL-17) and the
## tunnel under three houses (SHL-16) to the top, placed as world/town.gd places them: the floor the capsule stands on
## (the kit's convex hulls) must be the flights' ramps, on the visible treads' nosing line (never below the treads, never
## more than a rise above them), a standing body must fit all the way (no hull fills a passage), and there must be 2 m of
## headroom over the treads (the tunnel's lintels, the flights' raked cuts). STAIR_DEBUG=1 prints every failing sample.
## First run (26 Sep 2026): the floor stood 0.45 m over the flights (each hull took in its cheek walls) and 2.3 m in the
## tunnel, and the gateway chorten and the tunnel were shut; the kit now exports a ramp per flight and open passages.

const Town := preload("res://world/town.gd")
const FROM := -6.3  ## metres along the stair's line: the talkers' first step is 6.4 m before the stair's
const TO := 240.6
const DS := 0.05


## The visible surface, for the measurement only: a trimesh of every L0 mesh under `root`, on layer 2.
func _visible(root: Node3D) -> void:
	for mi in root.find_children("*_L0", "MeshInstance3D", true, false):
		var sb := StaticBody3D.new()
		sb.collision_layer = 2
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		cs.shape = (mi as MeshInstance3D).mesh.create_trimesh_shape()
		sb.add_child(cs)
		sb.set_meta("mesh", String(mi.get_path()))
		root.add_child(sb)
		sb.global_transform = (mi as MeshInstance3D).global_transform


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, mask)
	q.hit_from_inside = true
	return space.intersect_ray(q)


func test_the_sky_stair_is_walked_on_its_treads() -> void:
	# The stair and what stands round it, placed by world/town.gd as the game places them (bounds round the stair's line).
	var town = JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json"))
	var line: Array = []
	for b in town["buildings"]:
		if b["id"] == "SHL-15":
			line = b["line"]
	assert_false(line.is_empty(), "the stair's line in data/town.json")
	var box := Rect2(Vector2(line[0][0], line[0][1]), Vector2.ZERO).expand(Vector2(line[1][0], line[1][1])).grow(12.0)
	var root := Node3D.new()
	add_child_autofree(root)
	var counts: Dictionary = Town.place(root, box)
	gut.p("placed round the stair: %s" % [counts])
	var town_root: Node3D = root.get_node("Town")
	var st: Node3D = town_root.get_node_or_null("SHL-15")
	assert_not_null(st, "the Sky Stair placed")
	if st == null:
		return
	for id in ["SHL-16", "SHL-17", "SHL-40"]:
		assert_not_null(town_root.get_node_or_null(id), id + " placed")
	_visible(town_root)
	var frame := st.global_transform
	await wait_physics_frames(3)
	var space := root.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.7
	var cq := PhysicsShapeQueryParameters3D.new()
	cq.shape = cap
	cq.collision_mask = 1
	var ref := -3.0
	var high := []  # [s, float] where the floor stands more than a rise over the treads
	var low := []  # where it lies under them (the body would sink into the steps)
	var blocked := []  # where a standing body does not fit
	var low_roof := []  # where what is drawn overhead is under 2 m over the treads
	var worst_hi := -INF
	var worst_lo := INF
	var n := 0
	var s := FROM
	while s <= TO:
		var z := -s
		var vis := _ray(space, frame * Vector3(0.0, ref + 1.2, z), frame * Vector3(0.0, ref - 4.0, z), 2)
		var col := _ray(space, frame * Vector3(0.0, ref + 1.2, z), frame * Vector3(0.0, ref - 4.0, z), 1)
		if not vis.is_empty():
			var yv: float = (frame.affine_inverse() * (vis["position"] as Vector3)).y
			ref = yv
			if col.is_empty():
				low.append([s, -9.0])
			else:
				var d: float = (frame.affine_inverse() * (col["position"] as Vector3)).y - yv
				worst_hi = maxf(worst_hi, d)
				worst_lo = minf(worst_lo, d)
				if d > 0.22:
					high.append([s, d])
				elif d < -0.03:
					low.append([s, d])
				if (d > 0.22 or d < -0.03) and OS.get_environment("STAIR_DEBUG") != "":
					gut.p("  %.2f m: treads %.2f (%s), floor %.2f (%s #%d)" % [s, yv, _who(vis), yv + d, _who(col), int(col["shape"])])
				if n % 5 == 0:
					var fy: float = yv + d
					cq.transform = Transform3D(frame.basis, frame * Vector3(0.0, fy + 0.1 + 0.85, z))
					if not space.intersect_shape(cq, 1).is_empty():
						blocked.append([s, d])
					# Headroom: what is drawn over the treads, and the hulls over the floor.
					var up := _ray(space, frame * Vector3(0.0, yv + 0.3, z), frame * Vector3(0.0, yv + 6.0, z), 2)
					var head: float = (frame.affine_inverse() * (up["position"] as Vector3)).y - yv if not up.is_empty() else 99.0
					if head < 2.0:
						low_roof.append([s, head])
						if OS.get_environment("STAIR_DEBUG") != "":
							gut.p("  %.2f m: headroom %.2f under %s (%s)" % [s, head, _who(up), (up["collider"] as Node).get_meta("mesh", "")])
		n += 1
		s += DS
	gut.p("stair: %d samples, the floor %.2f to %.2f m over the treads; %d too high, %d too low, %d blocked" % [n, worst_lo, worst_hi, high.size(), low.size(), blocked.size()])
	for pair in [["too high", high], ["too low", low], ["blocked", blocked], ["headroom under 2 m", low_roof]]:
		var runs := _runs(pair[1])
		if runs != "":
			gut.p("  %s at %s" % [pair[0], runs])
	assert_eq(high.size(), 0, "the floor never more than a rise over the treads")
	assert_eq(low.size(), 0, "the floor never under the treads")
	assert_eq(blocked.size(), 0, "a standing body fits the whole way")
	assert_eq(low_roof.size(), 0, "2 m of headroom over the treads the whole way")


func _who(hit: Dictionary) -> String:
	var c: Node = hit["collider"]
	var n: String = String(c.get_parent().name) if c.get_parent() != null else ""
	return "%s/%s" % [n, c.name]


## Samples grouped into runs along the line: "12.3-14.1 m (0.45)", the worst value in brackets.
func _runs(samples: Array) -> String:
	var out := []
	var start := -1e9
	var last := -1e9
	var worst := 0.0
	for p in samples:
		if p[0] - last > DS * 6.0:
			if last > -1e8:
				out.append("%.1f-%.1f m (%.2f)" % [start, last, worst])
			start = p[0]
			worst = 0.0
		last = p[0]
		worst = p[1] if absf(p[1]) > absf(worst) else worst
	if last > -1e8:
		out.append("%.1f-%.1f m (%.2f)" % [start, last, worst])
	return ", ".join(out)
