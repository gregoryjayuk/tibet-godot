extends GutTest
## The Shade Wood SER-16 (M2 sprint 12, step 4; plan chapter 02, D09; chapter 11, 5.2): tools/town/forest.py's trees on
## the bank above the Serchu road and the south rim, every kind there, larch the most; none on the road or in V-01's view
## west; world/forest.gd drawing them in cells at three levels of detail.

const DATA := "res://assets/generated/terrain/forest.json"
const ROAD := "res://data/serchu_road.json"
const ARRIVAL := "res://data/arrival.json"
const Forest := preload("res://world/forest.gd")


func _trees() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))["trees"]


func test_the_wood_on_its_ground() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no forest.json (tools/py tools/town/forest.py)")
		return
	var trees := _trees()
	assert_between(trees.size(), 2000, 20000, "a wood of thousands (chapter 11: about 16,000 at one to 25 m²)")
	var kinds := {}
	for t in trees:
		kinds[String(t[0])] = int(kinds.get(String(t[0]), 0)) + 1
	for k in ["larch", "spruce", "fir", "birch", "maple"]:
		assert_true(kinds.has(k), "%s in it" % k)
	assert_gt(int(kinds["larch"]), int(kinds["spruce"]) + int(kinds["fir"]), "the shaded slope's larch the most (chapter 09)")
	var line: Array = JSON.parse_string(FileAccess.get_file_as_string(ROAD))["line"]
	var v01: Array = JSON.parse_string(FileAccess.get_file_as_string(ARRIVAL))["v01"]["eye"]
	for t in trees:
		var p := Vector2(float(t[2]), float(t[3]))
		for k in range(1, line.size()):
			var q := Geometry2D.get_closest_point_to_segment(p, Vector2(float(line[k - 1][0]), float(line[k - 1][1])), Vector2(float(line[k][0]), float(line[k][1])))
			if q.distance_to(p) < 6.0:
				fail_test("a tree on the Serchu road at %s" % p)
				return
		var d := p - Vector2(float(v01[0]), float(v01[1]))
		var b := fposmod(rad_to_deg(atan2(d.x, d.y)), 360.0)
		if b > 252.0 and b < 308.0 and d.length() < 400.0:
			fail_test("a tree in V-01's view west at %s" % p)
			return


func test_drawn_in_cells() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no forest.json")
		return
	var f := Forest.new()
	add_child_autofree(f)
	var n := f.build()
	if n == 0:
		pending("no forest kit (../tibet-blender export_types.py forest_*)")
		return
	assert_eq(n, _trees().size(), "every tree drawn")
	assert_between(f.cells, 5, 40, "in a few dozen cells")
	var mmis := f.find_children("*", "MultiMeshInstance3D", true, false)
	assert_eq(mmis.size() % 3, 0, "each cell's kinds at three levels")
	var groups := mmis.size() / 3
	assert_lt(groups, 160, "draw calls with the whole wood in view (%d)" % groups)
