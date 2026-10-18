extends GutTest
## Upper Shöl's people crossing the bridge over the Sky Stair (world/bridge_people.gd; IMP-027): the day's crossings, each
## its own minute and some from either end; the deck sagging between its ends, the most half way; a crossing in a still
## half way across while its minutes last; and in the town, both roofs' hatches found and every crossing planned.

const BridgePeople := preload("res://world/bridge_people.gd")
const Town := preload("res://world/town.gd")


func test_the_days_crossings() -> void:
	var plan: Array = BridgePeople.plan()
	assert_gt(plan.size(), 5, "several crossings a day")
	var ends := {}
	var minutes := {}
	var afternoon := 0
	for p in plan:
		ends[int(p["from"])] = true
		minutes[float(p["start"])] = true
		if float(p["start"]) >= 13.0 * 60.0 and float(p["start"]) < 17.0 * 60.0:
			afternoon += 1
		assert_true(ResourceLoader.exists("res://assets/generated/people/%s.glb" % p["key"]), "%s's body built" % p["key"])
	assert_eq(ends.size(), 2, "crossings from both ends")
	assert_eq(minutes.size(), plan.size(), "each at its own minute")
	assert_gt(afternoon, 1, "more than one in the slice's afternoon")


func test_the_deck_sags() -> void:
	var a := Vector3(0.0, 10.0, 0.0)
	var b := Vector3(20.0, 10.4, 0.0)
	assert_almost_eq(BridgePeople.deck_at(a, b, 0.7, 0.0).distance_to(a), 0.0, 0.001, "at its a end")
	assert_almost_eq(BridgePeople.deck_at(a, b, 0.7, 1.0).distance_to(b), 0.0, 0.001, "at its b end")
	assert_almost_eq(BridgePeople.deck_at(a, b, 0.7, 0.5).y, 10.2 - 0.7, 0.001, "the most sag half way")
	assert_gt(BridgePeople.deck_at(a, b, 0.7, 0.25).y, BridgePeople.deck_at(a, b, 0.7, 0.5).y, "less a quarter of the way")


func test_in_a_still() -> void:
	var p := {"start": 870.0}
	assert_eq(BridgePeople.at_minute(p, 869.0), "gone", "not before its minute")
	assert_eq(BridgePeople.at_minute(p, 872.0), "look", "half way across, looking down, while its minutes last")
	assert_eq(BridgePeople.at_minute(p, 875.0), "gone", "gone after")


func test_in_the_town() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var g = JSON.parse_string(FileAccess.get_file_as_string("res://data/town_generic.json"))
	var at := []
	for h in g["houses"]:
		if h["id"] in ["H-SHL-061", "H-SHL-080"]:
			at.append(Vector2(h["pos"][0], h["pos"][1]))
	assert_eq(at.size(), 2, "the bridge's two houses")
	var box := Rect2(at[0], Vector2.ZERO).expand(at[1]).grow(15.0)
	Town.place(root, box)
	var bp := root.find_child("BridgePeople", true, false)
	assert_not_null(bp, "the crossings built")
	if bp == null:
		return
	assert_eq((bp.get("hatches") as Array).size(), 2, "both roofs' hatches")
	assert_eq((bp.get("people") as Array).size(), BridgePeople.plan().size(), "every crossing planned")
	var a: Vector3 = bp.get("a")
	var b: Vector3 = bp.get("b")
	assert_almost_eq(a.distance_to(b), 22.1, 0.3, "the bridge's span")
	for h in bp.get("hatches"):  # each hatch on its roof just below the deck's end on its side
		var near: float = minf((h as Vector3).distance_to(a), (h as Vector3).distance_to(b))
		assert_lt(near, 8.0, "a hatch near the bridge's end")
