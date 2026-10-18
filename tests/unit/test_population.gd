extends GutTest
## The population as data (M2 sprint 10, step 1; plan chapter 05, 2.1-2.4): tools/town/population.py's households hold
## chapter 05's communities, the forty-one named once each and today's walkers once each; the households away are the
## houses the town draws shut (world/households.gd `decide`), and no named or walking household is in one.

const DATA := "res://data/population.json"
const GRAPH := "res://assets/generated/terrain/street_graph.json"
const Households := preload("res://world/households.gd")

var d := {}


func before_all() -> void:
	if FileAccess.file_exists(DATA):
		d = JSON.parse_string(FileAccess.get_file_as_string(DATA))


func _people(community: String) -> Array:
	var out := []
	for r in d["households"]:
		if String(r["community"]) == community:
			out.append_array(r["members"])
	return out


func test_the_communities() -> void:
	if d.is_empty():
		pending("no data/population.json (tools/py tools/town/population.py)")
		return
	var count := func(c: String) -> int: return (d["households"] as Array).filter(func(r): return String(r["community"]) == c).size()
	assert_gte(count.call("shol"), 170, "Shöl's 170 households and its named houses (chapter 05, 2.1)")
	assert_between(_people("shol").size(), 1140, 1320, "about 1,140 people and the named houses'")
	assert_eq(count.call("tode"), 74, "Tödé's 72 and the masons' two families")
	assert_between(_people("tode").size(), 490, 510, "490 and the masons' 12")
	assert_eq(count.call("samkha"), 16, "Samkha's 16")
	assert_eq(_people("samkha").size(), 107, "107")
	assert_eq(count.call("hui"), 5, "the Hui's five")
	assert_eq(_people("hui").size(), 24, "24")
	var han_men := _people("hejie").filter(func(m): return String(m["role"]) in ["HM", "HP"]).size()
	assert_between(han_men, 160, 172, "about 160 Han men, and the walkers lodged there")
	assert_between(_people("hejie").filter(func(m): return String(m["role"]) == "HW").size(), 95, 97, "their 95 wives, and Dickyi at the post")
	assert_between(_people("hejie").filter(func(m): return String(m["role"]) == "QS").size(), 17, 19, "the post's 17 present, and Wang Gui in his house")
	var kids := _people("shol").filter(func(m): return int(m["age"]) < 15).size()
	assert_between(float(kids) / _people("shol").size(), 0.2, 0.3, "about a quarter children (2.2)")


func test_the_named_and_the_walkers_once() -> void:
	if d.is_empty():
		pending("no data/population.json")
		return
	var named := {}
	var walkers := 0
	for r in d["households"]:
		for m in r["members"]:
			if m.has("named"):
				named[String(m["named"])] = int(named.get(String(m["named"]), 0)) + 1
			if m.has("walker"):
				walkers += 1
	for m in d["monastery"]["named"]:
		if not m.has("walker"):
			named[String(m["key"])] = int(named.get(String(m["key"]), 0)) + 1
		else:
			walkers += 1
	assert_eq(named.size(), 41, "chapter 05's forty-one")
	for k in named:
		assert_eq(int(named[k]), 1, "%s once" % k)
	if FileAccess.file_exists(GRAPH):  # the written days' walkers placed by their keys; the day's drawn are members already
		var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GRAPH))
		var written := (g["walkers"] as Array).filter(func(w): return not bool(w.get("roster", false))).size()
		assert_eq(walkers, written, "every written walker of today's street graph in a household (or the monastery)")
		var ids := {}
		for r in d["households"]:
			for m in r["members"]:
				ids[String(m["id"])] = true
		for w in g["walkers"]:
			if bool(w.get("roster", false)):
				assert_true(ids.has(String(w["who"])) or String(w["who"]).contains("MON-"), "%s, drawn, one of the population (or the monastery's)" % w["who"])


func test_away_as_the_town_draws_it() -> void:
	if d.is_empty():
		pending("no data/population.json")
		return
	var keep := Households.kept()
	var checked := 0
	for r in d["households"]:
		var house := String(r["house"])
		if not String(r["id"]).begins_with("household:") or not (house.begins_with("H-SHL-") or house.begins_with("H-HEJ-")):
			continue
		var shut: bool = Households.decide(house, keep)["shut"]
		var someone := (r["members"] as Array).any(func(m): return m.has("named") or m.has("walker"))
		assert_false(shut and someone, "%s: no named or walking household in a shut house" % r["id"])
		assert_eq(r["away"] != null, shut, "%s away as its house is drawn %s" % [r["id"], "shut" if shut else "lived in"])
		checked += 1
	assert_gt(checked, 150, "the town's houses checked")


func test_the_lanes_six_to_four() -> void:
	if d.is_empty():
		pending("no data/population.json")
		return
	var men := 0
	var women := 0
	for r in d["households"]:
		if String(r["community"]) != "shol" or r["away"] != null:
			continue
		for m in r["members"]:
			if int(m["age"]) >= 15 and int(m["age"]) < 50 and not m.has("away"):
				if String(m["sex"]) == "m":
					men += 1
				else:
					women += 1
	assert_between(float(women) / maxf(1.0, float(men)), 1.3, 1.7, "women outnumber men at home about 6 to 4 (2.2): %d to %d" % [women, men])
