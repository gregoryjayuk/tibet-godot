extends GutTest
## The western mani wall SHL-10 and the lingkor's west side (M2 sprint 6, step 6; plan chapter 02: "260 m, 2,620-2,780 m,
## the lingkor's west side", R-25 beside it with the wall on the right going up; chapter 04, 4.2: the poor family's
## grandmother does the lingkor's west side at dusk): its four walls stepping up the bed tools/terrain/pads.py carves,
## a gloss of its own for a walker going the wrong way, the street graph's loop round its first section, clockwise, and
## the grandmother walking it at dusk.

const MANI := "res://assets/generated/terrain/mani_walls.json"
const GRAPH := "res://assets/generated/terrain/street_graph.json"


func _wall() -> Dictionary:
	if not FileAccess.file_exists(MANI):
		return {}
	for w in (JSON.parse_string(FileAccess.get_file_as_string(MANI)) as Dictionary)["walls"]:
		if String(w["id"]) == "SHL-10":
			return w
	return {}


func test_four_walls_stepping_up_the_slope() -> void:
	var w := _wall()
	if w.is_empty():
		pending("no mani walls: run tools/terrain/build.sh")
		return
	var segs: Array = w["segments"]
	assert_gt(segs.size(), 110, "about 260 m of 2 m segments, less the ways between")
	assert_eq((w["ends"] as Array).size(), 8, "a pillar at each end of its four walls")
	assert_eq((w["sections"] as Array).size(), 4, "in four walls with a way between")
	var rise := float(segs[segs.size() - 1][2]) - float(segs[0][2])
	assert_between(rise, 100.0, 130.0, "stepping up the slope over 260 m")
	var steps := 0
	for k in range(1, segs.size()):
		if float(segs[k][2]) > float(segs[k - 1][2]):
			steps += 1
	assert_eq(steps, segs.size() - 1, "every segment above the one below it")
	assert_true(w.has("gloss") and String(w["gloss"]).contains("right"), "its own gloss: kept on the right")


func test_the_loop_round_its_first_wall() -> void:
	if not FileAccess.file_exists(GRAPH):
		pending("no street graph")
		return
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GRAPH))
	assert_true((g["anchors"] as Dictionary).has("west_mani"), "its foot on the walkers' ground")
	var r: Dictionary = (g["routes"] as Dictionary).get("mani_loop_west_mani", {})
	assert_false(r.is_empty(), "the loop round its first wall")
	var p: Array = r["p"]
	var pts: Array = []
	for i in range(0, p.size(), 3):
		pts.append(Vector3(float(p[i]), float(p[i + 1]), float(p[i + 2])))
	var top := 0
	for i in pts.size():
		if (pts[i] as Vector3).z > (pts[top] as Vector3).z:
			top = i
	var u := Vector2(sin(deg_to_rad(352.0)), cos(deg_to_rad(352.0)))  # the bed's way up
	var east := Vector2(u.y, -u.x)
	var up_side := (Vector2(pts[top / 2].x, pts[top / 2].y) - Vector2(-320.0, 62.0)).dot(east)
	var down_side := (Vector2(pts[(top + pts.size()) / 2].x, pts[(top + pts.size()) / 2].y) - Vector2(-320.0, 62.0)).dot(east)
	assert_lt(up_side, -1.0, "up its west side")
	assert_gt(down_side, 1.0, "and down its east: the wall on the right, clockwise")
	assert_gt((pts[top] as Vector3).z - (pts[0] as Vector3).z, 25.0, "up its first wall's 62 m")


func test_the_grandmother_at_dusk() -> void:
	if not FileAccess.file_exists(GRAPH):
		pending("no street graph")
		return
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GRAPH))
	var found := false
	for w in g["walkers"]:
		if String(w.get("who", "")) != "poor_grandmother":
			continue
		for stop in w["day"]:
			if String(stop[0]) == "west_mani" and String(stop[3]) == "mani" and int(stop[4]) >= 1 and float(stop[1]) >= 1020.0:
				found = true
	assert_true(found, "round the western wall's first section at dusk (chapter 04, 4.2)")
