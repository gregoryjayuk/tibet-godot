extends GutTest
## The north bank at the Serchu's mills (M2 sprint 12, step 5; tools/town/serchu_mills.py, data/serchu_mills.json): the
## leat falls as a cascade (1% along each stretch, a mill's head or a wheel's drop between them), its mills stand below
## their chutes' heads and their tail races over the river, the footbridge's deck stands over the water with its ends on
## the banks, the Yak Road and the path keep their grades, the river runs wet by the mills again, and the kit's houses'
## sockets are where the planner put the chutes' feet and the arches.

const Town := preload("res://world/town.gd")
const DATA := "res://data/serchu_mills.json"
const KIT := "res://assets/generated/kit/types/%s.glb"

var d: Dictionary


func before_all() -> void:
	if FileAccess.file_exists(DATA):
		d = JSON.parse_string(FileAccess.get_file_as_string(DATA))


func _len(a: Array, b: Array) -> float:
	return Vector2(float(b[0]) - float(a[0]), float(b[1]) - float(a[1])).length()


func test_the_leat_falls_as_a_cascade() -> void:
	if d.is_empty():
		pending("no data/serchu_mills.json (tools/py tools/town/serchu_mills.py)")
		return
	var last := INF
	for st in d["leat"]:
		var pts: Array = st["pts"]
		if st.get("race", false):
			assert_lt(float(pts[pts.size() - 1][2]), float(pts[0][2]), "the race falls to the river")
			continue
		assert_true(float(pts[0][2]) <= last + 0.01, "%s starts no higher than the last ended" % st["id"])
		var run := 0.0
		for k in range(1, pts.size()):
			run += _len(pts[k - 1], pts[k])
			assert_true(float(pts[k][2]) <= float(pts[k - 1][2]) + 0.001, "%s never climbs" % st["id"])
		if run > 5.0:
			var grade := (float(pts[0][2]) - float(pts[pts.size() - 1][2])) / run
			assert_almost_eq(grade, 0.01, 0.004, "%s falls at 1%%" % st["id"])
		last = float(pts[pts.size() - 1][2])


func test_the_mills_stand_below_their_heads_over_the_river() -> void:
	if d.is_empty():
		pending("no data")
		return
	var rv: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rivers.json"))
	var serchu: Array = []
	for r in rv["rivers"]:
		if String(r["name"]) == "Serchu":
			serchu = r["pts"]
	assert_eq((d["mills"] as Array).size(), 4, "four mills")
	for m in d["mills"]:
		assert_almost_eq(float(m["head"][2]) - float(m["level"]), 1.8, 0.01, "%s's floor 1.8 m under its chute's head" % m["id"])
		var near: Array = serchu[0]
		for q in serchu:
			if _len(q, m["at"]) < _len(near, m["at"]):
				near = q
		assert_gt(float(m["arch"][2]) - float(near[2]), 1.0, "%s's tail race over the river" % m["id"])
		assert_gt(_len(near, m["at"]) - maxf(float(near[3]), float(near[4])), 4.0, "%s clear of the water" % m["id"])
		assert_between(float(m["chute"]), 20.0, 55.0, "%s's chute falls steeply" % m["id"])
	assert_eq((d["wheels"] as Array).size(), 2, "two water prayer wheels")


func test_the_footbridge_over_the_water() -> void:
	if d.is_empty():
		pending("no data")
		return
	var br: Dictionary = d["bridge"]
	assert_almost_eq(float(br["deck"]) - float(br["water"]), 2.6, 0.05, "its deck 2.6 m over the water")
	assert_almost_eq(_len(br["north"], br["south"]), 12.0, 0.05, "a 12 m span")
	for end in ["north", "south"]:
		assert_between(float(br[end][2]), -0.6, 3.4, "the %s crib's height over the bank" % end)


func test_the_roads_grades() -> void:
	if d.is_empty():
		pending("no data")
		return
	for ln in d["lanes"]:
		var id := String(ln["id"])
		var L := float(ln["length"]) - 1.0
		if L < 2.0 or ln.get("channel", false):
			continue
		var g := absf(float(ln["z_b"]) - float(ln["z_a"])) / L
		if id.begins_with("R-09."):
			assert_lt(g, 0.36, "%s: the Yak Road no steeper than its hump over the leat" % id)
		elif id.begins_with("SER-11.p"):
			assert_lt(g, 0.36, "%s: the path up the south bank" % id)
		elif ln.get("leat", false):
			assert_lt(g, 0.03, "%s: the leat's shelf" % id)
	var legs: Array = d["yak_road"]
	assert_gt(legs.size(), 1, "the Yak Road's first legs")
	for k in range(1, legs.size()):
		var leg: Array = legs[k]
		var run := 0.0
		for i in range(1, leg.size()):
			run += _len(leg[i - 1], leg[i])
		assert_almost_eq((float(leg[leg.size() - 1][2]) - float(leg[0][2])) / run, 0.12, 0.01, "leg %d at 12%%" % (k + 1))
	for c in d["culverts"]:
		assert_gt(float(c["road"]) - float(c["water"]), 0.4, "the road over the leat on its slabs")


func test_the_river_runs_by_the_mills() -> void:
	var rv: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rivers.json"))
	for r in rv["rivers"]:
		if String(r["name"]) != "Serchu":
			continue
		var run := 0
		var longest := 0
		for q in r["pts"]:
			if float(q[0]) > 525.0 and float(q[0]) < 570.0 and int(q[5]) < 1:
				run += 1
				longest = maxi(longest, run)
			else:
				run = 0
		assert_lt(longest, 2, "the Serchu runs past the mills, a gravel bar of a point at most (its bed's hump cut: it ran dry for 20 m)")


func test_the_kits_sockets_where_the_planner_put_them() -> void:
	if d.is_empty() or not ResourceLoader.exists(KIT % "ser05_mill_v1"):
		pending("no data or no mill built (../tibet-blender export_types.py --types ser05_mill)")
		return
	var m: Dictionary = d["mills"][0]
	var h: Node3D = (load(KIT % "ser05_mill_v1") as PackedScene).instantiate()
	add_child_autofree(h)
	h.position = Town.to_godot(float(m["at"][0]), float(m["at"][1]), float(m["level"]))
	h.rotation.y = -deg_to_rad(float(m["facing"]) - 180.0)
	await wait_frames(1)
	var jet := h.find_child("SOCK_JET_1", true, false) as Node3D
	var tail := h.find_child("SOCK_TAIL_1", true, false) as Node3D
	assert_not_null(jet, "the mill's JET socket")
	assert_not_null(tail, "its TAIL")
	if jet != null:
		var want := Town.to_godot(float(m["jet"][0]), float(m["jet"][1]), float(m["jet"][2]))
		assert_lt(jet.global_position.distance_to(want), 0.05, "the chute's foot at the mill's JET")
	if tail != null:
		var a := Town.to_godot(float(m["arch"][0]), float(m["arch"][1]), float(m["arch"][2]))
		assert_lt(tail.global_position.distance_to(a), 0.15, "the tail race at its arch")
