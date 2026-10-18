extends GutTest
## Who is there at Pema Ö at first sun (M2 sprint 5, step 5; world/pema_o_people.gd): the lama's morning by the clock,
## down to the terrace's burner, at the lip through the first sun (07:46 on the terrain) and back for the service; the
## monks at the bowls, then on the rows; the old woman round the kora; the terrace's burner lit late, for the lama.

const PemaOPeople := preload("res://world/pema_o_people.gd")
const Dusk := preload("res://world/dusk.gd")
const Lamps := preload("res://world/lamps.gd")


func test_the_lamas_morning() -> void:
	var L := 57.2  # metres from his seat to the burner (lama_way: the aisle, the porch, the stair, across the terrace)
	assert_eq(PemaOPeople.lama_doing(300.0, L), "away", "not yet at 05:00, at his practice")
	assert_eq(PemaOPeople.lama_doing(380.0, L), "seat", "on his seat at 06:20")
	assert_eq(PemaOPeople.lama_doing(400.0, L), "down", "on his way down at 06:40")
	assert_eq(PemaOPeople.lama_doing(406.0, L), "sang", "laying the juniper at 06:46")
	assert_eq(PemaOPeople.lama_doing(466.0, L), "lip", "at the lip at the first sun, 07:46")
	assert_eq(PemaOPeople.lama_doing(467.0, L), "lip", "and the minute after it")
	assert_eq(PemaOPeople.lama_doing(478.0, L), "up", "going back up at 07:58")
	assert_eq(PemaOPeople.lama_doing(500.0, L), "service", "at the service at 08:20")
	assert_eq(PemaOPeople.lama_doing(600.0, L), "away", "gone after it, 10:00")
	var arrive := PemaOPeople.LAMA_OUT + L / (PemaOPeople.SPEED * PemaOPeople.PER_MIN)
	assert_lt(arrive, 406.0, "down by 06:46 at his pace")


func test_the_monks_and_the_kora() -> void:
	assert_eq(PemaOPeople.monks_doing(395.0), "bowls", "filling the bowls at 06:35")
	assert_eq(PemaOPeople.monks_doing(450.0), "away", "between, 07:30")
	assert_eq(PemaOPeople.monks_doing(490.0), "sit", "at the service, 08:10")
	assert_eq(PemaOPeople.kora_s(370.0, 67.5), -1.0, "the old woman not yet at 06:10")
	var s := PemaOPeople.kora_s(400.0, 67.5)
	assert_between(s, 0.0, 67.5, "on the corridor at 06:40")
	assert_eq(PemaOPeople.kora_s(530.0, 67.5), -1.0, "gone at 08:50")


func test_the_terrace_burner_burns_for_the_first_sun() -> void:
	assert_true(Dusk.LATE.has("SHL-12"), "the Conch terrace's burner lit on its own minute")
	var late := float(Dusk.LATE["SHL-12"])
	var c := Color(0.0, late, 1.0, 0.0)
	assert_eq(Lamps.lit("ember", 0, 400.0, c), 0.0, "cold before the lama comes, 06:40")
	assert_gt(Lamps.lit("ember", 0, 420.0, c), 0.9, "glowing after he lays the juniper, 07:00")
	assert_gt(Lamps.lit("ember", 0, 466.0, c), 0.9, "still at the first sun, 07:46")
	assert_eq(Lamps.lit("ember", 0, 500.0, c), 0.0, "out by 08:20")
	assert_eq(Lamps.lit("ember", 0, 1040.0, c), 0.0, "and none at dusk: a morning's alone")
	var town := Color(0.0, 3.0, 1.0, 0.0)  # a household's roof burner, as before
	assert_gt(Lamps.lit("ember", 0, 360.0, town), 0.9, "the town's roofs at 06:00 unchanged")
	assert_gt(Lamps.lit("ember", 0, 1040.0, town), 0.9, "and at dusk")
