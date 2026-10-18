extends GutTest
## The town's lamps at dusk (world/lamps.gd; IMP-021 (3)): the Mani Lhakhang's altar lit from 17:00 and out at 21:00 but
## its middle lamp; the tunnel's never out; each burner's ember with its juniper; the fire in Dechen-tsang's yard for the
## evening; and each in its place in the town.

const Lamps := preload("res://world/lamps.gd")
const Town := preload("res://world/town.gd")


func test_their_hours() -> void:
	assert_eq(Lamps.lit("altar", 0, 14.0 * 60.0), 0.0, "the altar dark in the afternoon")
	assert_eq(Lamps.lit("altar", 6, 17.5 * 60.0), 1.0, "all seven lit by half past five")
	assert_eq(Lamps.lit("altar", 0, 23.0 * 60.0), 0.0, "out by night")
	assert_eq(Lamps.lit("altar", 3, 23.0 * 60.0), 1.0, "but the middle one")
	assert_eq(Lamps.lit("altar", 3, 3.0 * 60.0), 1.0, "till the morning")
	assert_eq(Lamps.lit("altar", 0, 6.0 * 60.0), 1.0, "all lit again for the morning")
	assert_eq(Lamps.lit("tunnel", 0, 12.0 * 60.0), 1.0, "the tunnel's lamp by day")
	assert_eq(Lamps.lit("fire", 0, 17.5 * 60.0), 0.0, "no fire before a quarter to six")
	assert_eq(Lamps.lit("fire", 0, 19.0 * 60.0), 1.0, "the fire in the evening")
	assert_eq(Lamps.lit("fire", 0, 22.0 * 60.0), 0.0, "out by ten")
	var c := Color(0.5, 3.0, 0.8, 10.0)  # a burner lit three minutes after its window opens
	assert_eq(Lamps.lit("ember", 0, 17.0 * 60.0 + 1.0, c), 0.0, "an ember not before its household's minute")
	assert_almost_eq(Lamps.lit("ember", 0, 17.0 * 60.0 + 20.0, c), 0.8, 0.001, "glowing while its juniper burns")
	assert_eq(Lamps.lit("ember", 0, 19.0 * 60.0, c), 0.0, "out after")


func test_in_their_places() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var town = JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json"))
	var at := {}
	for b in town["buildings"]:
		if b["id"] in ["SHL-08", "SHL-04"]:
			at[b["id"]] = b["pos"]
	var box := Rect2(Vector2(at["SHL-04"][0], at["SHL-04"][1]), Vector2.ZERO).expand(Vector2(at["SHL-08"][0], at["SHL-08"][1])).grow(40.0)
	var counts: Dictionary = Town.place(root, box)
	gut.p("placed: %s" % [counts])
	var lamps := root.find_child("Lamps", true, false)
	assert_not_null(lamps, "the lamps built")
	if lamps == null:
		return
	var c := 0
	for p in lamps.placed:
		if p[0] == "altar":
			c += 1
	assert_eq(c, 7, "the altar's seven lamps")
	assert_not_null(lamps.hall, "a light in the hall")
	assert_not_null(lamps.fire, "the yard's fire")
	var embers := 0
	for p in lamps.placed:
		if p[0] == "ember":
			embers += 1
	assert_gt(embers, 0, "embers in the burners")
	WorldClock.minute = 18.5 * 60.0
	lamps._update(18.5 * 60.0)
	assert_almost_eq(float(lamps.strength.get("altar", 0.0)), 7.0, 0.01, "the altar lit at half past six")
	assert_true(lamps.hall.visible, "the hall's light on")
	assert_true(lamps.fire.visible, "the fire burning")
	lamps._update(14.0 * 60.0)
	assert_false(lamps.hall.visible, "no light in the hall in the afternoon")
	assert_false(lamps.fire.visible, "no fire")
