extends GutTest
## The town's birds (world/birds.gd; M1 sprint 8, step 2): chapter 02's counts (30 choughs, 10 ravens, 5 griffons,
## 40 of its 60 pigeons); no two flocks alike; out by day and in by night, the griffons only on the midday thermals,
## thinned from every flock alike; over two minutes of flight every bird keeps its kind's floor over the ground and
## stays inside its MultiMesh's box; a flock keeps together, and a pair of ravens a length or two apart.

const Birds := preload("res://world/birds.gd")
const Horizon := preload("res://world/horizon.gd")

var birds: Node3D
var had_horizon := false


func before_all() -> void:
	had_horizon = not Horizon._grids.is_empty()
	if not had_horizon:
		Horizon.load_globals()


func after_all() -> void:
	if not had_horizon:
		Horizon.clear()


func before_each() -> void:
	var town: GDScript = load("res://world/town.gd")
	birds = Birds.new()
	add_child_autofree(birds)
	birds.set_process(false)
	birds.build(func(x: float, y: float, z: float) -> Vector3: return town.call("to_godot", x, y, z))


func test_counts() -> void:
	assert_eq((birds.birds["chough"] as Array).size(), 30, "choughs, chapter 02")
	assert_eq((birds.birds["raven"] as Array).size(), 10, "ravens")
	assert_eq((birds.birds["griffon"] as Array).size(), 5, "griffons")
	assert_eq((birds.birds["pigeon"] as Array).size(), 40, "pigeons over Tsongra, Hejie and Samkha")
	assert_eq(birds.flocks.size(), 14)


func test_no_two_flocks_alike() -> void:
	var seen := {}
	for name in birds.flocks:
		var kind: String = birds.flocks[name]["kind"]
		var p: Array = (birds.birds[kind] as Array)[int((birds.flocks[name]["birds"] as Array)[0])]
		var key := "%.2f %.2f %.3f %.3f" % [(p[3] as Vector3).x, (p[3] as Vector3).y, (p[1] as Vector3).y, (p[2] as Vector3).z]
		assert_false(seen.has(key), "%s is its own (ellipse, bearing, pace, wander)" % name)
		seen[key] = name


func test_their_day() -> void:
	assert_eq(Birds.out_count("chough", 30, 3 * 60.0), 0, "none at 03:00")
	assert_eq(Birds.out_count("chough", 30, 12 * 60.0), 30, "all out at noon")
	assert_eq(Birds.out_count("chough", 30, 19 * 60.0), 0, "in their roost by 19:00")
	assert_between(Birds.out_count("chough", 30, 400.0), 1, 29, "coming out one by one at 06:40")
	assert_eq(Birds.out_count("griffon", 5, 8 * 60.0), 0, "no griffon before the thermals")
	assert_eq(Birds.out_count("griffon", 5, 13 * 60.0), 5, "all on the midday thermals")
	assert_eq(Birds.out_count("griffon", 5, 17 * 60.0), 0, "down by 17:00")
	assert_eq(Birds.out_count("raven", 10, 12 * 60.0), 10)


func test_thinned_from_every_flock() -> void:
	var half := 15
	for name in birds.flocks:
		if birds.flocks[name]["kind"] != "chough":
			continue
		var idx: Array = birds.flocks[name]["birds"]
		var out := idx.filter(func(j): return int(j) < half).size()
		assert_between(out, 1, maxi(idx.size() - 1, 1), "%s: some of its %d out when half the choughs are" % [name, idx.size()])


func test_clear_of_the_ground_and_in_the_box() -> void:
	var worst := INF
	var worst_at := ""
	for kind in birds.birds:
		var floor_m: float = Birds.KINDS[kind]["floor"]
		var box: AABB = (birds.mmis[kind] as MultiMeshInstance3D).multimesh.custom_aabb
		for i in (birds.birds[kind] as Array).size():
			for k in 240:
				var t := 1000.0 + float(k) * 0.5
				var p: Vector3 = birds.pos_at(kind, i, t)
				if not box.grow(0.5).has_point(p):
					fail_test("%s %d at %.1f s outside its box" % [kind, i, t])
				var g := Horizon.ground_at(p.x, -p.z)
				if not is_nan(g) and p.y - g - floor_m < worst:
					worst = p.y - g - floor_m
					worst_at = "%s %d at %.1f s" % [kind, i, t]
	assert_gt(worst, -0.01, "every bird at its kind's floor over the ground or above it (the lowest: %s, %.1f m over its floor)" % [worst_at, worst])


func test_flocks_keep_together() -> void:
	for name in birds.flocks:
		var kind: String = birds.flocks[name]["kind"]
		if kind == "griffon":
			continue
		var idx: Array = birds.flocks[name]["birds"]
		var widest := 0.0
		for k in 60:
			var t := 500.0 + float(k) * 2.0
			for a in idx:
				for b in idx:
					widest = maxf(widest, (birds.pos_at(kind, int(a), t) as Vector3).distance_to(birds.pos_at(kind, int(b), t)))
		assert_lt(widest, {"chough": 80.0, "raven": 25.0, "pigeon": 45.0}[kind], "%s keeps together (%.0f m at its widest)" % [name, widest])
