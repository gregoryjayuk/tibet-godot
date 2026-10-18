extends GutTest
## V-28's people on the near roofs at dusk (world/roof_people.gd; M1 sprint 8, step 6): six houses, six doings (two
## women at the juniper, the grandmother's rosary, a man calling, someone watching, a girl carrying in), no body twice;
## the juniper women up before the sang at 17:00 and at it; all down by 17:50; gone at noon and at night.

const RoofPeople := preload("res://world/roof_people.gd")

var names := ["H-SHL-101", "H-SHL-044", "H-SHL-017", "H-SHL-090", "H-SHL-063", "H-SHL-008", "H-SHL-120"]


func test_six_roofs_six_doings() -> void:
	var p := RoofPeople.plan(names)
	assert_eq(p.size(), 6, "the six nearest roofs")
	var doings := p.map(func(x): return String(x["doing"]))
	doings.sort()
	assert_eq(doings, ["call", "carry", "juniper", "juniper", "rosary", "watch"], "chapter 08's evening on the roofs")
	var keys := {}
	for x in p:
		assert_false(keys.has(x["key"]), "%s not twice on these roofs" % x["key"])
		keys[x["key"]] = true
		assert_true((RoofPeople.WHO[x["doing"]] as Array).has(x["key"]), "%s may do %s" % [x["key"], x["doing"]])


func test_their_evening() -> void:
	for x in RoofPeople.plan(names):
		assert_eq(RoofPeople.where(x, 12.0 * 60.0), "gone", "no one up there at noon")
		assert_eq(RoofPeople.where(x, 20.0 * 60.0), "gone", "nor at night")
		assert_lte(float(x["down"]), 1070.0, "down by 17:50")
		if x["doing"] == "juniper":
			assert_lt(float(x["up"]), 1017.0, "up before the sang")
			assert_eq(RoofPeople.where(x, 1020.0), "there", "at the burner as it is lit")
			assert_eq(RoofPeople.acting_clip("juniper", 1020.0), "Interact", "feeding it")
		elif x["doing"] != "carry":
			assert_eq(RoofPeople.where(x, 1040.0), "there", "%s on the roof at 17:20" % x["doing"])


func test_the_same_names_the_same_evening() -> void:
	assert_eq(RoofPeople.plan(names), RoofPeople.plan(names), "seeded by the houses' names")
	var other := RoofPeople.plan(["H-TOD-001", "H-TOD-002", "H-TOD-003", "H-TOD-004", "H-TOD-005", "H-TOD-006"])
	assert_ne(other.map(func(x): return x["key"]), RoofPeople.plan(names).map(func(x): return x["key"]), "another street, other people")
