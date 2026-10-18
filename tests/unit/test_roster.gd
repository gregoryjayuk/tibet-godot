extends GutTest
## The day's 300 (M2 sprint 10, step 2; plan chapter 05, 2.3-2.4): tools/town/roster.py's draw holds chapter 05's
## archetypes, the forty-one named and today's walkers, nobody away, everyone once; and the street graph's day's drawn
## walkers are the roster's who walk in Shöl, each in its figure for its archetype, coming from its door or its way in.

const ROSTER := "res://data/roster.json"
const POP := "res://data/population.json"
const GRAPH := "res://assets/generated/terrain/street_graph.json"

var r := {}


func before_all() -> void:
	if FileAccess.file_exists(ROSTER):
		r = JSON.parse_string(FileAccess.get_file_as_string(ROSTER))


func test_the_300() -> void:
	if r.is_empty():
		pending("no data/roster.json (tools/py tools/town/roster.py)")
		return
	var people: Array = r["people"]
	assert_between(people.size(), 300, 320, "the day's 300, the named and today's walkers among them (2.3)")
	var roles := {}
	var seen := {}
	for p in people:
		roles[String(p["role"])] = int(roles.get(String(p["role"]), 0)) + 1
		assert_false(seen.has(String(p["who"])), "%s drawn once" % p["who"])
		seen[String(p["who"])] = true
	for a in {"TM": 52, "TW": 70, "TE": 18, "TB": 24, "TG": 20, "MK": 20, "HM": 9, "HC": 15, "CV": 22}:
		var want: int = {"TM": 52, "TW": 70, "TE": 18, "TB": 24, "TG": 20, "MK": 20, "HM": 9, "HC": 15, "CV": 22}[a]
		assert_between(int(roles.get(a, 0)), want, want + 4, "%s about chapter 05's %d" % [a, want])
	assert_eq(people.filter(func(p): return p.has("named")).size(), 41, "the forty-one named always among them")
	assert_eq(String(r["date"]), "1903-10-28", "the default day, chapter 02's")


func test_nobody_away_drawn() -> void:
	if r.is_empty() or not FileAccess.file_exists(POP):
		pending("no roster or population")
		return
	var pop: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POP))
	var away := {}
	for h in pop["households"]:
		for m in h["members"]:
			if h["away"] != null or m.has("away"):
				away[String(m["id"])] = true
	for p in r["people"]:
		assert_false(away.has(String(p["who"])), "%s is at home to be drawn" % p["who"])


func test_the_drawn_walk() -> void:
	if r.is_empty() or not FileAccess.file_exists(GRAPH):
		pending("no roster or street graph")
		return
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GRAPH))
	var drawn := {}
	for p in r["people"]:
		drawn[String(p["who"])] = p
	var n := 0
	var kinds: Array = g.get("kinds", [])
	var written_done := false
	for w in g["walkers"]:
		if not bool(w.get("roster", false)):
			assert_false(written_done, "the written days' walkers first (the town's lookups by figure find them first)")
			continue
		written_done = true
		n += 1
		var p: Dictionary = drawn.get(String(w["who"]), {})
		assert_false(p.is_empty(), "%s one of the day's drawn" % w["who"])
		if p.is_empty():
			continue
		assert_true(String(p["day"]) in ["shol", "hejie", "samkha", "court"], "%s walks in Shöl, about Hejie or Samkha, or to the Pönpo's hearing today (%s)" % [w["who"], p["day"]])
		assert_eq(String(w["role"]), String(p["role"]), "%s its archetype" % w["who"])
		assert_true(String(w["kind"]) in kinds, "%s's figure %s among the crowd's" % [w["who"], w["kind"]])
		var day: Array = w["day"]
		assert_eq(String(day[0][0]), String(w["home"]), "%s starts at its door or its way in" % w["who"])
		assert_eq(String(day[day.size() - 1][0]), String(w["home"]), "and ends there")
	assert_gt(n, 120, "the day's drawn in Shöl walk")
