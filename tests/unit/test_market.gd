extends GutTest
## Tsongra's market on the market day (M2 sprint 10, step 4; plan chapter 05, 8.2 and 7.2): tools/town/market.py's
## stalls on the square's two levels, apart, clear of the steps, the flagpole and the basin, facing into the square,
## each its goods and a keeper of the day's drawn; set up for the morning and packed by noon (world/market.gd); in the
## street graph their keepers at them through the market's hours, their fronts places to buy at, two or so at each at
## 10:30, and the keepers the crowd's first moved down a tier (TownSim's `keeper`).

const DATA := "res://data/market.json"
const GRAPH := "res://assets/generated/terrain/street_graph.json"
const Market := preload("res://world/market.gd")
const LEVEL_Z := {"upper": 2662.0, "lower": 2660.0}
const KEEP_OFF := [Rect2(-10.6, 7.0, 21.2, 8.5), Rect2(-6.8, -4.6, 13.6, 5.4), Rect2(10.0, 6.3, 4.0, 3.0), Rect2(-9.5, 3.5, 3.0, 3.0)]

var d := {}


func before_all() -> void:
	if FileAccess.file_exists(DATA):
		d = JSON.parse_string(FileAccess.get_file_as_string(DATA))


func test_the_stalls() -> void:
	if d.is_empty():
		pending("no data/market.json (tools/py tools/town/market.py)")
		return
	var stalls: Array = d["stalls"]
	assert_between(stalls.size(), 10, 16, "a dozen or so stalls besides the fuel stalls (chapter 05, 8.2)")
	for i in stalls.size():
		var s: Dictionary = stalls[i]
		var p := Vector2(float(s["pos"][0]), float(s["pos"][1]))
		assert_almost_eq(float(s["pos"][2]), float(LEVEL_Z[String(s["level"])]), 0.01, "%s on its level" % s["id"])
		for r in KEEP_OFF:
			assert_false((r as Rect2).has_point(p), "%s clear of the steps, the basin and the flagpole" % s["id"])
		var c := Vector2(0.0, 7.5 if String(s["level"]) == "upper" else -7.5)
		var f := Vector2(sin(deg_to_rad(float(s["facing"]))), cos(deg_to_rad(float(s["facing"]))))
		assert_gt(f.dot((c - p).normalized()), 0.3, "%s faces into the square" % s["id"])
		assert_ne(String(s.get("goods", "")), "", "%s its goods" % s["id"])
		assert_true(String(s["kit"]) in ["stall_sh03", "stall_sh04"], "%s a kit stall" % s["id"])
		for j in range(i + 1, stalls.size()):
			var q := Vector2(float(stalls[j]["pos"][0]), float(stalls[j]["pos"][1]))
			assert_gt(p.distance_to(q), 3.0, "%s and %s apart" % [s["id"], stalls[j]["id"]])
	assert_gte(stalls.filter(func(s): return s.get("keeper") != null).size(), stalls.size() - 2, "nearly every stall kept")


func test_set_up_for_the_morning() -> void:
	var a := 7.6 * 60.0
	var b := 12.1 * 60.0
	assert_false(Market.set_up_at(a, b, 6.0 * 60.0), "not yet at 06:00")
	assert_true(Market.set_up_at(a, b, 8.0 * 60.0), "open at 08:00")
	assert_true(Market.set_up_at(a, b, 11.5 * 60.0), "at 11:30")
	assert_false(Market.set_up_at(a, b, 13.0 * 60.0), "packed by 13:00")
	assert_false(Market.set_up_at(a, b, 2.0 * 60.0), "nor in the night")


func test_kept_and_bought_at() -> void:
	if d.is_empty() or not FileAccess.file_exists(GRAPH):
		pending("no market or street graph")
		return
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GRAPH))
	var keepers := 0
	var at_1030 := 0
	for w in g["walkers"]:
		for s in w["day"]:
			if String(s[0]).begins_with("MKT-") and float(s[1]) <= 630.0 and 630.0 < float(s[2]):
				at_1030 += 1
		if not w.has("keeper"):
			continue
		keepers += 1
		var stop: Array = (w["day"] as Array).filter(func(s): return String(s[0]) == String(w["keeper"]))[0]
		assert_lt(float(stop[1]), 8.0 * 60.0, "%s at %s by the opening" % [w["who"], w["keeper"]])
		assert_gt(float(stop[2]), 11.6 * 60.0, "until it packs up")
		assert_eq(String(stop[5]["name"]), "stall", "behind its stall")
		assert_true((g["anchors"] as Dictionary).has(String(w["keeper"])), "its front a place on the graph")
	assert_gte(keepers, 10, "the stalls' keepers walk")
	assert_between(at_1030, 18, 45, "two or three at each stall at 10:30, its keeper among them (chapter 05, 8.2)")


func test_the_keepers_first_down() -> void:
	if not FileAccess.file_exists(GRAPH):
		pending("no street graph")
		return
	TownSim.setup_walkers(GRAPH, ["townsman", "townswoman"] as Array[String])
	var n := 0
	for i in TownSim.count:
		n += int(TownSim.keeper[i])
	assert_gte(n, 10, "TownSim knows the keepers")
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
