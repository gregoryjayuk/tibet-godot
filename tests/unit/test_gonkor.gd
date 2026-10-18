extends GutTest
## Dungkar Gönpa whole, step 6 (M3 sprint 3; tools/town/monastery.py GAL_*, KORA_ENDS, `lanes`; ../tibet-blender
## kit/monastery.py wheel_gallery, wheel_house; world/kora_wheels.gd, world/great_wheel.gd): the Gönkor's 128 wheels in
## eight galleries of 16 on the wall's south line, the wall itself their backs; its south stretch along them, level through
## each and ramped between, walked clockwise (westward) with the wheels on the right, each wheel turned under a passing hand;
## the great wheel house MON-23 with its 3.5 m wheel at its WHEEL socket and its bell. The rest of the circuit (M3 sprint
## 7, step 1; tools/town/gonkor.py, data/gonkor.json): up the east side, behind the Labrang, down the north side round the
## wall's west end to the West Gate, along the face's shelf and its timber gallery to the 1,080 steps and back to the
## south stretch; its flights no steeper than 45 degrees and broken by landings, joined to the steps' and the Gorge
## Stair's landings at their gaps.

const Town := preload("res://world/town.gd")
const KoraWheels := preload("res://world/kora_wheels.gd")
const MONASTERY := "res://data/monastery.json"
const SIDE := "res://assets/generated/kit/types/%s.json"
const KIT := "res://assets/generated/kit/types/%s.glb"
const LINE := -40.0  # the wall MON-21's south line (tools/town/monastery.py WALL_LINE)
const GONKOR := "res://data/gonkor.json"
const GORGE := "res://data/gorge_stair.json"
const STEPS := "res://data/dungrong.json"


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func _galleries(m: Dictionary) -> Array:
	return (m["buildings"] as Array).filter(func(b): return String(b["id"]).begins_with("MON-22"))


func test_the_galleries_on_the_wall() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var m := _json(MONASTERY)
	var gals := _galleries(m)
	assert_eq(gals.size(), 8, "eight sections (chapter 02, MON-22)")
	var wheels := 0
	for g in gals:
		assert_almost_eq(float(g["pos"][1]) + 1.65, LINE, 0.05, "%s's wall on the line" % g["id"])
		var f := Town.kit_file(g)
		assert_true(ResourceLoader.exists(KIT % f), "%s's kit %s" % [g["id"], f])
		var side := _json(SIDE % f)
		wheels += (side["socket_pos"] as Dictionary).keys().filter(func(k): return String(k).begins_with("SOCK_WHEEL_")).size()
		for run in m["walls"]:  # the wall MON-21 broken where a gallery stands: its wall is the wall's length there
			for q in run["pts"]:
				var inside := absf(float(q[0]) - float(g["pos"][0])) < 7.5 and absf(float(q[1]) - LINE) < 0.5
				assert_false(inside, "no second wall through %s at %s" % [g["id"], q])
	assert_eq(wheels, 128, "128 wheels (chapter 02)")


func test_the_south_stretch() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var m := _json(MONASTERY)
	var lanes: Array = (m.get("lanes", []) as Array).filter(func(l): return bool(l.get("gonkor", false)))  # (not the hero monk's house's way)
	assert_gt(lanes.size(), 14, "a lane through each gallery and one between each two")
	var last := Vector3.INF
	for ln in lanes:
		var a := Vector3(float(ln["from"][0]), float(ln["from"][1]), float(ln["z_a"]))
		if last != Vector3.INF:
			assert_lt(a.distance_to(last), 0.05, "%s goes on from the lane before" % ln["id"])
		assert_lt(float(ln["dir"][0]), 0.0, "%s westward: clockwise round the monastery" % ln["id"])
		var grade := absf(float(ln["z_b"]) - float(ln["z_a"])) / float(ln["length"])
		assert_lt(grade, 0.21, "%s climbs at most a fifth (%.0f%%)" % [ln["id"], grade * 100.0])
		last = Vector3(a.x + float(ln["dir"][0]) * float(ln["length"]), a.y + float(ln["dir"][1]) * float(ln["length"]), float(ln["z_b"]))
	for g in _galleries(m):  # through each gallery at its level, the wheels within a hand of the walk's middle
		var at := false
		for ln in lanes:
			var x0 := float(ln["from"][0])
			if absf(x0 - (float(g["pos"][0]) + 8.0)) < 0.1 and absf(float(ln["z_a"]) - float(g["pos"][2])) < 0.05:
				at = true
				var wy := float((m.get("gonkor", {}) as Dictionary).get("walk_y", 0.0))
				assert_lt(absf(wy - (LINE - 1.65 + 0.75)), KoraWheels.REACH, "the wheels within a hand of the walk's middle in %s" % ln["id"])
				assert_true(absf(wy - float(ln["from"][1])) < float(ln["width"]) / 2.0 - 0.5, "the walk's middle on %s's bed" % ln["id"])
				assert_gt(float(ln["from"][1]) + float(ln["width"]) / 2.0, LINE, "%s's bed under the wall's line (the wall on the walk)" % ln["id"])
		assert_true(at, "the walk through %s at its floor" % g["id"])


func test_a_galleries_wheels_turn() -> void:
	if not ResourceLoader.exists(KIT % "mon22_wheel_gallery_v1"):
		pending("no mon22_wheel_gallery_v1 (export_types.py)")
		return
	var gal: Node3D = (load(KIT % "mon22_wheel_gallery_v1") as PackedScene).instantiate()
	add_child_autofree(gal)
	var kw := KoraWheels.new()
	gal.add_child(kw)
	assert_eq(kw.setup(gal), 16, "its sixteen wheels hung")
	var hand := Node3D.new()
	hand.add_to_group("kora_walkers")
	add_child_autofree(hand)
	var w0 := kw.wheels[0].global_position
	hand.global_position = Vector3(w0.x, w0.y - 0.9, w0.z + 0.8)  # (on the walk's middle beside it: the kit's -y is Godot's +z)
	kw._process(0.1)
	assert_gt(kw.speed[0], 0.0, "the wheel by the hand turns")
	assert_eq(kw.speed[3], 0.0, "the one three on does not")


func test_the_great_wheel_house() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var pd: Dictionary = _json(MONASTERY)["pads"]["MON-23"]
	assert_eq(String(pd["kit"]), "mon23_wheel_house_v1", "MON-23 whole")
	assert_gt(float(pd["at"][0]), 705.0 + 3.5, "out beyond the wall's east line, on the Gönkor (M3 sprint 7, step 1)")
	assert_almost_eq(float(pd["facing"]), 270.0, 0.01, "its door facing the circuit")
	if FileAccess.file_exists(GONKOR):  # the circuit comes to its door
		var marks: Dictionary = _json(GONKOR).get("marks", {})
		assert_true(marks.has("great wheel house"), "the circuit's mark before its door")
		if marks.has("great wheel house"):
			var door := Vector2(float(pd["at"][0]), float(pd["at"][1])) + Vector2(sin(deg_to_rad(float(pd["facing"]))), cos(deg_to_rad(float(pd["facing"])))) * 3.5
			assert_lt(Vector2(float(marks["great wheel house"][0]), float(marks["great wheel house"][1])).distance_to(door), 2.0, "the way before its door")
	var root := Node3D.new()
	add_child_autofree(root)
	Town.place(root, Rect2(Vector2(float(pd["at"][0]) - 10.0, float(pd["at"][1]) - 10.0), Vector2(20.0, 20.0)))
	var wheel := root.get_node_or_null("Town/MON-23_wheel") as Node3D
	assert_not_null(wheel, "its 3.5 m wheel at its WHEEL socket")
	if wheel != null:
		assert_not_null(wheel.get("bell"), "its bell for the peg to strike")
		var sock := root.get_node("Town/MON-23").find_child("SOCK_WHEEL_1", true, false) as Node3D
		assert_lt(wheel.global_position.distance_to(sock.global_position), 0.01, "on its axis in the hall")


func _end_near(lanes: Array, p: Vector2, r: float) -> bool:
	for ln in lanes:
		var a := Vector2(float(ln["from"][0]), float(ln["from"][1]))
		var b := a + Vector2(float(ln["dir"][0]), float(ln["dir"][1])) * float(ln["length"])
		if a.distance_to(p) < r or b.distance_to(p) < r:
			return true
	return false


func test_the_circuit_whole() -> void:
	if not FileAccess.file_exists(GONKOR) or not FileAccess.file_exists(MONASTERY):
		pending("no data/gonkor.json (tools/town/gonkor.py)")
		return
	var g := _json(GONKOR)
	for sid in g["stretches"]:
		assert_false(String(g["stretches"][sid]).begins_with("no way"), "stretch %s laid: %s" % [sid, g["stretches"][sid]])
	var m := _json(MONASTERY)
	var kora: Array = (m["lanes"] as Array).filter(func(l): return bool(l.get("gonkor", false)))
	var k0: Dictionary = kora[0]
	var k1: Dictionary = kora[-1]
	var wy := float((m.get("gonkor", {}) as Dictionary).get("walk_y", -41.7))
	var east := Vector2(float(k0["from"][0]), wy)
	var west := Vector2(float(k1["from"][0]) + float(k1["dir"][0]) * float(k1["length"]), wy)
	var loop: Array = g["loop"]
	assert_lt(Vector2(float(loop[0][0]), float(loop[0][1])).distance_to(east), 2.0, "the loop from the south stretch's east end")
	assert_lt(Vector2(float(loop[-1][0]), float(loop[-1][1])).distance_to(west), 2.0, "round to its west end")
	var hi := -INF
	var lo := INF
	var walked := 0.0
	for k in loop.size():
		hi = maxf(hi, float(loop[k][2]))
		lo = minf(lo, float(loop[k][2]))
		if k > 0:
			walked += Vector2(float(loop[k][0]), float(loop[k][1])).distance_to(Vector2(float(loop[k - 1][0]), float(loop[k - 1][1])))
	assert_gt(hi, 3000.0, "behind the Labrang over 3,000 m (chapter 02: 3,005)")
	assert_between(walked, 850.0, 1200.0, "the loop beyond the south stretch (chapter 02's 1.1 km round)")
	var gallery := 0.0
	for ln in g["lanes"]:
		var f = ln.get("flight")
		if f == null:
			continue
		if bool(ln.get("gallery", false)):
			gallery += float(ln["length"])
			assert_true(bool(f.get("deck", false)), "%s a deck along the face" % ln["id"])
			assert_lt(absf(float(f["rise"])) / float(ln["length"]), 0.29, "%s's deck no steeper than a ramp" % ln["id"])
			continue
		if int(f.get("n", 0)) > 0:
			var grade := absf(float(ln["z_b"]) - float(ln["z_a"])) / float(ln["length"])
			assert_lt(grade, 1.01, "%s no steeper than 45 degrees" % ln["id"])
			assert_lt(float(ln["length"]), 10.6, "%s broken by landings" % ln["id"])
	assert_between(gallery, 30.0, 70.0, "the timber gallery on the gorge face (chapter 02: 40 m)")
	var face: Array = (g["lanes"] as Array).filter(func(l): return String(l.get("gonkor_way", "")) in ["F", "S"])
	var gs := _json(GORGE)
	var by := {}
	for ln in gs["lanes"]:
		by[ln["id"]] = ln
	var l23: Dictionary = by["R07E.L23"]
	var mid23 := Vector2(float(l23["from"][0]), float(l23["from"][1])) + Vector2(float(l23["dir"][0]), float(l23["dir"][1])) * float(l23["length"]) / 2.0
	assert_true(_end_near(face, mid23, float(l23["width"]) / 2.0 + 0.2), "the face's way onto the Gorge Stair's landing 23")
	var ds := _json(STEPS)
	for ln in ds["lanes"]:
		by[ln["id"]] = ln
	var l20: Dictionary = by["R04.L20"]
	var mid20 := Vector2(float(l20["from"][0]), float(l20["from"][1])) + Vector2(float(l20["dir"][0]), float(l20["dir"][1])) * float(l20["length"]) / 2.0
	assert_true(_end_near(face, mid20, float(l20["width"]) / 2.0 + 0.2), "the way from the south onto the 1,080 steps' landing 20")
	assert_true((g["steps_gaps"] as Dictionary).has("R04.L20"), "a gap in landing 20's south wall")
