extends GutTest
## The rivers' water (M2 sprint 5; tools/terrain/rivers.py, world/rivers.gd): every river in the data, its water inside
## its banks as built and its stretches drawn, the Conch Fall's arc on the slot, the pool at the confluence and the
## rivers joining it, the ribbon's arrays as the shader reads them.

const Rivers := preload("res://world/rivers.gd")
const Town := preload("res://world/town.gd")


func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/rivers.json"))


func test_every_river_and_its_waters() -> void:
	var d := _data()
	var names := []
	for r in d["rivers"]:
		names.append(String(r["name"]))
		assert_eq((r["pts"] as Array).size(), (r["water"] as Array).size(), "%s: a water for each point" % r["name"])
		for w in r["water"]:
			assert_has(["dungchu", "serchu", "mixed", "yalong"], String(w), "%s: a water the shader knows" % r["name"])
	for n in ["Yalong", "Dungchu gorge", "Samkha slot", "Dungchu fan", "Serchu"]:
		assert_has(names, n, "%s in the data" % n)


func test_the_conch_fall_is_an_arc() -> void:
	var d := _data()
	var fall: Dictionary = d["fall"]
	var lip := int(fall["lip"])
	var foot := int(fall["foot"])
	assert_gt(lip, 0, "the fall's lip on the slot")
	assert_eq(foot - lip, 6, "seven points on the arc")
	for r in d["rivers"]:
		if String(r["name"]) != "Samkha slot":
			continue
		var pts: Array = r["pts"]
		for i in range(lip + 1, foot + 1):
			assert_lt(float(pts[i][2]), float(pts[i - 1][2]), "the water falls all the way down the arc (%d)" % i)
			assert_eq(int(pts[i][5]), 1, "the arc drawn (%d)" % i)
		assert_almost_eq(float(pts[lip][2]) - float(pts[foot][2]), float(fall["drop"]), 0.05, "the arc falls the fall's height")
		var throw := Vector2(float(pts[foot][0]) - float(pts[lip][0]), float(pts[foot][1]) - float(pts[lip][1])).length()
		assert_between(throw, 2.0, 4.5, "thrown out over the rock's step, clear of its face")
		var last := Vector2(float(pts[foot][0]) - float(pts[foot - 1][0]), float(pts[foot][1]) - float(pts[foot - 1][1])).length()
		assert_gt((float(pts[foot - 1][2]) - float(pts[foot][2])) / maxf(last, 0.01), 3.0, "near vertical at its foot")


func test_the_pool_where_they_meet() -> void:
	var d := _data()
	assert_true(d.has("pool"), "the pool at the confluence in the data")
	var pool: Dictionary = d["pool"]
	var z := float(pool["z"])
	for r in d["rivers"]:
		var name := String(r["name"])
		if not name in ["Dungchu gorge", "Serchu", "Samkha slot"]:
			continue
		var pts: Array = r["pts"]
		var join := -1
		for i in pts.size():
			if int(pts[i][5]) == 2:
				join = i
		assert_gt(join, -1, "%s joins the pool" % name)
		assert_almost_eq(float(pts[join][2]), z - 0.05, 0.011, "%s just under the pool's surface where it joins it" % name)
		if name == "Samkha slot":
			for i in join:
				assert_eq(int(pts[i][5]), 0, "the slot's head inside the pool left to it (%d)" % i)
			assert_lt(float(pts[join + 1][2]), z, "the slot's water leaving the pool lower than it")
		else:
			for i in range(join + 1, pts.size()):
				assert_eq(int(pts[i][5]), 0, "%s's last metres left to the pool (%d)" % [name, i])
			assert_gt(float(pts[join - 1][2]), z, "%s's water over the pool's before it joins" % name)


func test_the_pool_and_the_spray_are_built() -> void:
	var rv := Rivers.new()
	add_child_autofree(rv)
	rv.build(null)
	assert_not_null(rv.pool, "the pool's surface")
	assert_not_null(rv.spray, "the Conch Fall's spray")
	assert_gt(rv.fall_foot, 0, "the fall's foot found")
	var foot_at := Vector3(rv.spray.transform.origin)
	var d := _data()
	for r in d["rivers"]:
		if String(r["name"]) == "Samkha slot":
			var q: Array = r["pts"][int(d["fall"]["foot"])]
			var want := Town.to_godot(float(q[0]), float(q[1]), float(q[2]))
			assert_almost_eq(foot_at.distance_to(want), 0.0, 0.01, "the spray at the fall's foot")
	var wobble := 0.0
	for k in 64:
		wobble = maxf(wobble, absf(Rivers.shore(d["pool"], TAU * k / 64.0) - 1.0))
	assert_between(wobble, 0.05, 0.3, "the pool's shore wanders, not an ellipse")


func test_runs_carry_through_short_dry_gaps() -> void:
	var pts := []
	for w in [1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]:
		pts.append([0.0, 0.0, 0.0, 1.0, 1.0, w])
	var runs := Rivers.wet_runs(pts)
	assert_eq(runs, [[0, 6], [15, 16]], "a two-point dry gap carried, an eight-point one not")


func test_a_ribbon_as_the_shader_reads_it() -> void:
	var at := PackedVector3Array([Vector3(0, 0, 0), Vector3(0, -0.5, -5), Vector3(0, -1.0, -10)])
	var wl := PackedFloat32Array([2.0, 2.0, 2.0])
	var wr := PackedFloat32Array([3.0, 3.0, 3.0])
	var code := PackedFloat32Array([2.0, 2.0, 2.0])
	var fc := PackedFloat32Array([0.0, 5.0, 10.0])
	var a := Rivers.ribbon(at, wl, wr, code, fc)
	var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	assert_eq(verts.size(), 3 * (Rivers.ACROSS + 1), "ACROSS+1 vertices a point")
	var uvs: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	assert_almost_eq(uvs[uvs.size() - 1].y, at[0].distance_to(at[1]) + at[1].distance_to(at[2]), 0.01, "UV.y metres along the water")
	var custom: PackedFloat32Array = a[Mesh.ARRAY_CUSTOM0]
	assert_almost_eq(custom[0], 2.0, 0.001, "CUSTOM0.x the water")
	assert_almost_eq(custom[1], 0.1, 0.01, "CUSTOM0.y the slope, a drop of 0.1 a metre")
	assert_eq((a[Mesh.ARRAY_INDEX] as PackedInt32Array).size(), 2 * Rivers.ACROSS * 6, "two triangles a strip a step")
	var mid: Vector3 = verts[1 * (Rivers.ACROSS + 1) + 0]
	assert_almost_eq(mid.x, -2.35 * 2.0 / 3.0, 0.01, "the middle point's left edge 2 m out and EDGE beyond, looking downstream (-z), a short stretch's taper on it")
	var joined := Rivers.ribbon(at, wl, wr, code, fc, true, true)
	var jv: PackedVector3Array = joined[Mesh.ARRAY_VERTEX]
	assert_almost_eq(jv[0].x, -2.35, 0.01, "where it joins the pool its end is square, not tapered")
