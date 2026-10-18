extends GutTest
## The prayer flags (world/flags.gd; M1 sprint 8, after Greg's walk): each house its own, seeded by its name, so the
## same town builds the same flags; no two houses alike (Greg: "don't make the flags or other things too uniform"),
## some flying none; strings between neighbours; a banner on a courtyard pole; heard where they fly (SND-013 loops,
## gone with the flags).

const Flags := preload("res://world/flags.gd")


func _town(n: int) -> Node3D:
	var root := Node3D.new()
	add_child_autofree(root)
	for k in n:
		var h := Node3D.new()
		h.name = "H-TEST-%03d" % k
		root.add_child(h)
		h.position = Vector3((k % 8) * 9.0, 8.0 + (k % 3) * 0.5, (k / 8) * 9.0)
		for c in 4:
			var m := Marker3D.new()
			m.name = "SOCK_PIER_%d" % (c + 1)
			h.add_child(m)
			m.position = Vector3(3.0 if c % 2 else -3.0, 0.0, 3.0 if c > 1 else -3.0)
			var cr := Marker3D.new()
			cr.name = "SOCK_CORNER_%d" % (c + 1)
			h.add_child(cr)
			cr.position = m.position - Vector3(0.0, 0.9, 0.0)
	var yard := Node3D.new()
	yard.name = "SHL-04"
	root.add_child(yard)
	var mast := Marker3D.new()
	mast.name = "SOCK_MAST_1"
	yard.add_child(mast)
	mast.position = Vector3(0.0, 9.0, 0.0)
	return root


func test_the_same_town_the_same_flags() -> void:
	var a: Node3D = Flags.new()
	add_child_autofree(a)
	var ca: Dictionary = a.build(_town(40))
	var b: Node3D = Flags.new()
	add_child_autofree(b)
	var cb: Dictionary = b.build(_town(40))
	assert_eq(ca, cb, "seeded by the houses' names")
	assert_eq(int(ca["houses"]), 40, "every house decides")
	assert_gt(int(ca["flags"]), 150, "flags")
	assert_gt(int(ca["lines"]), 5, "strings")
	assert_eq(int(ca["banners"]), 1, "the courtyard pole's banner")


func test_no_two_houses_alike() -> void:
	var f: Node3D = Flags.new()
	add_child_autofree(f)
	f.build(_town(40))
	var ph: Dictionary = f.get("per_house")
	var kinds := {}
	var styles := {}
	var none := 0
	for h in ph:
		kinds["%s/%d/%d" % ph[h]] = true
		styles[String(ph[h][0])] = true
		if int(ph[h][2]) == 0:
			none += 1
	assert_gt(kinds.size(), 25, "40 houses, their flags in more than 25 different ways")
	assert_gt(styles.size(), 5, "in more than five kinds of way (poles, strings to the ground, across, torn, juniper...)")
	assert_gt(none, 0, "some fly none")
	assert_lt(none, 16, "most fly some")
	var poles: Array = ph.values().map(func(v): return int(v[1]))
	assert_gt(poles.filter(func(n): return n == 0).size(), 10, "many houses without a pole on their roof")
	assert_lt(poles.filter(func(n): return n >= 3).size(), 10, "three or four poles on few")


func test_the_households_say_who_left() -> void:
	# with the households (world/households.gd; IMP-019): a left house's bare poles and a few grey rags; the others never left
	var root := _town(200)
	var hh: Node = (load("res://world/households.gd") as GDScript).new()
	add_child_autofree(hh)
	hh.build(root)
	var f: Node3D = Flags.new()
	add_child_autofree(f)
	f.build(root, hh)
	var left := 0
	for h in f.per_house:
		var is_left: bool = String((f.per_house[h] as Array)[0]) == "left"
		assert_eq(is_left, bool(hh.is_left(String(h))), "%s: left as its household says" % h)
		if is_left:
			left += 1
			assert_lte(int((f.per_house[h] as Array)[2]), 10, "%s left: one or two bare poles, a few grey rags on each at most" % h)
	gut.p("%d of %d houses left" % [left, f.per_house.size()])


func test_heard_where_they_fly() -> void:
	var f: Node3D = Flags.new()
	add_child_autofree(f)
	f.build(_town(40))
	var rustle: Array = f.get("rustle")
	assert_gt(rustle.size(), 3, "the flags heard from several places")
	for i in rustle.size():
		for j in range(i + 1, rustle.size()):
			if (rustle[i][0] as Vector3).distance_to(rustle[j][0]) <= 5.0:
				fail_test("clusters %d and %d closer than 5 m" % [i, j])
	var loops: Dictionary = AudioDirector.sound.get("_loops")
	var keys: Array = f.get("_rustle_keys")
	assert_eq(keys.size(), rustle.size() + (f.get("gorge_rustle") as Array).size(), "a loop each, and each span across the gorge its own (SND-015)")
	for k in keys:
		assert_true(loops.has(k), "%s registered" % k)
	f.free()
	for k in keys:
		assert_false(loops.has(k), "%s gone with the flags" % k)
