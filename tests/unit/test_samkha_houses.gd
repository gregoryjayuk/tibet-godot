extends GutTest
## Samkha's houses (M2 sprint 11, step 2; plan chapter 02, SAM-14 and SAM-15; chapter 03, 5.3): tools/town/builder.py's
## retainers' eight town houses facing each other across Castle Lane on four terraces along the Castle Ramp's first leg,
## the lane 2 m wide stepping down between them; the four poor houses against the ward's north wall; clear of the ramp,
## the ward and the trading houses; each the population's household's (three of them two); the retainers' in the castle's
## colours (world/households.gd LIVERY).

const GENERIC := "res://data/town_generic.json"
const LANES := "res://data/town_lanes.json"
const RAMP := "res://data/castle_ramp.json"
const POP := "res://data/population.json"
const KIT := "res://assets/generated/kit/types/%s.glb"
const Town := preload("res://world/town.gd")
const Households := preload("res://world/households.gd")
const WARD := Rect2(-150.0, -96.0, 40.0, 28.0)
const KEEP_OFF := [Rect2(-106.0, -64.0, 62.0, 48.0), Rect2(-155.0, -8.0, 30.0, 26.0)]  ## Dechen-tsang's and Norbu-tsang's pads


func _sam() -> Array:
	var hs: Array = JSON.parse_string(FileAccess.get_file_as_string(GENERIC))["houses"]
	return hs.filter(func(h): return String(h["id"]).begins_with("H-SAM-"))


static func _corners(h: Dictionary) -> PackedVector2Array:
	var c := Vector2(float(h["pos"][0]), float(h["pos"][1]))
	var w := float(h["footprint"][0]) / 2.0
	var d := float(h["footprint"][1]) / 2.0
	var th := deg_to_rad(float(h["rot_deg"]))
	var f := Vector2(sin(th), cos(th))
	var a := Vector2(f.y, -f.x)
	return PackedVector2Array([c - a * w - f * d, c + a * w - f * d, c + a * w + f * d, c - a * w + f * d])


func test_twelve_houses() -> void:
	var sam := _sam()
	assert_eq(sam.size(), 12, "H-SAM-01 to 12")
	assert_eq(sam.filter(func(h): return h["type"] == "B" and h["quarter"] == "samkha.castle_lane").size(), 8, "the retainers' eight on Castle Lane (SAM-14)")
	assert_eq(sam.filter(func(h): return h["type"] == "E" and h["quarter"] == "samkha.rock").size(), 4, "the four poor houses under the rock (SAM-15)")
	for i in sam.size():
		var a := _corners(sam[i])
		assert_true(ResourceLoader.exists(KIT % Town.kit_file(sam[i])), "%s's kit file" % sam[i]["id"])
		for j in range(i + 1, sam.size()):
			assert_eq(Geometry2D.intersect_polygons(a, _corners(sam[j])).size(), 0, "%s and %s apart" % [sam[i]["id"], sam[j]["id"]])
		for p in a:
			assert_false(WARD.has_point(p), "%s outside the ward" % sam[i]["id"])
			for r in KEEP_OFF:
				assert_false((r as Rect2).has_point(p), "%s off the trading houses' pads" % sam[i]["id"])


func test_clear_of_the_ramp() -> void:
	if not FileAccess.file_exists(RAMP):
		pending("no data/castle_ramp.json")
		return
	for ln in JSON.parse_string(FileAccess.get_file_as_string(RAMP))["lanes"]:
		var o := Vector2(float(ln["from"][0]), float(ln["from"][1]))
		var u := Vector2(float(ln["dir"][0]), float(ln["dir"][1]))
		var n := Vector2(-u.y, u.x)
		var hw := float(ln["width"]) / 2.0 + 1.0
		var band := PackedVector2Array([o - n * hw, o + u * float(ln["length"]) - n * hw, o + u * float(ln["length"]) + n * hw, o + n * hw])
		for h in _sam():
			assert_eq(Geometry2D.intersect_polygons(_corners(h), band).size(), 0, "%s a metre clear of %s" % [h["id"], ln["id"]])


func test_castle_lane() -> void:
	var lanes := (JSON.parse_string(FileAccess.get_file_as_string(LANES))["lanes"] as Array).filter(func(ln): return String(ln["id"]).begins_with("CL-"))
	assert_eq(lanes.size(), 4, "a lane a terrace")
	var by_id := {}
	for h in _sam():
		by_id[String(h["id"])] = h
	var flights := 0
	for ln in lanes:
		assert_almost_eq(float(ln["width"]), 2.0, 0.01, "%s 2 m wide (chapter 03, 5.3)" % ln["id"])
		for hid in ln["between"]:  # the terrace's two houses at the lane's level, facing each other across it
			assert_almost_eq(float(by_id[String(hid)]["pos"][2]), float(ln["z_a"]), 0.01, "%s at %s's level" % [hid, ln["id"]])
		var a: Dictionary = by_id[String(ln["between"][0])]
		var b: Dictionary = by_id[String(ln["between"][1])]
		assert_almost_eq(absf(fposmod(float(a["rot_deg"]) - float(b["rot_deg"]), 360.0) - 180.0), 0.0, 0.5, "%s's houses face each other" % ln["id"])
		if ln["flight"] != null:
			flights += 1
			assert_gt(float(ln["z_b"]), float(ln["z_a"]), "%s steps up towards the castle" % ln["id"])
	assert_gte(flights, 2, "a stepped lane")


func test_their_households() -> void:
	if not FileAccess.file_exists(POP):
		pending("no data/population.json")
		return
	var count := {}
	for hh in JSON.parse_string(FileAccess.get_file_as_string(POP))["households"]:
		var house := String(hh.get("house", ""))
		if house.begins_with("H-SAM-"):
			count[house] = int(count.get(house, 0)) + 1
	for h in _sam():
		assert_gte(int(count.get(String(h["id"]), 0)), 1, "%s lived in by its household" % h["id"])
	assert_eq(count.values().filter(func(c): return c == 2).size(), 3, "three of the retainers' houses hold two households (chapter 02, SAM-14)")


func test_the_castle_colours() -> void:
	for i in range(1, 9):
		assert_eq(int(Households.decide("H-SAM-%02d" % i, {})["paint"]), 0, "H-SAM-%02d the kit's own red woodwork and black strip" % i)
