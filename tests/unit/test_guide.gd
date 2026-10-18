extends GutTest
## The child who leads the way up the Rooftop Way (world/guide.gd; M1's acceptance, walk 5): her path is the Way's, from
## its foot in Dechen-tsang's guest yard to V-28's roof, with a climb for each of its ladders; she waits at the foot from
## 16:40, greets the player who comes and leads them, never more than a few metres on ahead (she waits, turned to them,
## when they fall behind, and never on a ladder), to the last roof; with nobody come by 17:20 she goes in.

const Guide := preload("res://world/guide.gd")

var guide: Node3D


func before_each() -> void:
	var town: GDScript = load("res://world/town.gd")
	guide = Guide.new()
	add_child_autofree(guide)
	guide.set_process(false)
	guide.build(func(x: float, y: float, z: float) -> Vector3: return town.call("to_godot", x, y, z))


func test_her_path_is_the_way() -> void:
	assert_gt(guide.segs.size(), 20, "the Way's legs")
	var climbs: Array = guide.segs.filter(func(g): return g["kind"] == "climb")
	var way: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/terrain/rooftop.json"))
	var ladders: Array = way["pieces"].filter(func(pc): return String(pc.get("kind", "")) in ["log", "stair"])
	assert_gt(ladders.size(), 4, "the Way climbs")
	assert_eq(climbs.size(), ladders.size(), "a climb for each ladder and notched log")
	var town: GDScript = load("res://world/town.gd")
	var end: Vector3 = guide.segs[guide.segs.size() - 1]["b"]
	var v28: Vector3 = town.call("to_godot", -95.0, 205.0, 2755.72)  # H-SHL-056's middle at its roof's level
	assert_lt(Vector2(end.x - v28.x, end.z - v28.z).length(), 5.5, "to V-28's roof (wherever the Way lands on it: IMP-023)")
	assert_almost_eq(end.y, v28.y, 0.3, "on its roof")
	for k in range(1, guide.segs.size()):
		assert_lt((guide.segs[k - 1]["b"] as Vector3).distance_to(guide.segs[k]["a"]), 0.05, "unbroken at %d" % k)


func test_she_waits_then_leads_the_player_up() -> void:
	guide.step(0.1, Vector3.INF, 16.5 * 60.0)
	assert_eq(guide.mode, "away", "not there before 16:40")
	guide.step(0.1, Vector3.INF, 16.7 * 60.0)
	assert_eq(guide.mode, "waiting", "at the Way's foot at 16:42")
	var start: Vector3 = guide.segs[0]["a"]
	# the player walks the path a few metres behind her, a little slower than she does, and stops for a while halfway
	var p := start + Vector3(0.0, 0.0, 3.0)
	var ahead := 0.0
	var waited := false
	var t := 0.0
	var m := 16.75 * 60.0
	var ps := 0.0  # the player's metres along her path
	while t < 900.0 and guide.mode != "arrived":
		var dt := 0.1
		t += dt
		m += dt / 10.0  # the clock at 6:1
		if guide.mode in ["leading", "pausing"]:
			if not (t > 200.0 and t < 230.0):  # a stop to look at the view
				ps = minf(ps + 1.0 * dt, guide.total)
			p = guide.at(maxf(ps - 2.5, 0.0))[0]
		guide.step(dt, p, m)
		if guide.mode == "pausing":
			waited = true
			if guide.at(guide.s)[2] == "climb":
				fail_test("she waited on a ladder")
		ahead = maxf(ahead, guide.s - ps)
	assert_eq(guide.mode, "arrived", "on V-28's roof, %.0f s after she set off" % t)
	assert_true(waited, "she waited for the player when they stopped")
	assert_lt(ahead, 12.0, "never far ahead along the Way (%.1f m at most)" % ahead)


func test_nobody_came() -> void:
	guide.step(0.1, Vector3.INF, 16.7 * 60.0)
	guide.step(0.1, Vector3.INF, 17.4 * 60.0)
	assert_eq(guide.mode, "away", "gone in by 17:20 with nobody come")
