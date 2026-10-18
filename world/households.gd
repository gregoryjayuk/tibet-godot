extends Node
## Each household its own (IMP-019; Greg, 27 Sep 2026: "the houses already have way too many uniform features"; "would
## things in this time and place really be this uniform?"). Every town house, seeded by its name: its upkeep (a few
## limed and painted fresh this season, for a wedding or a year's mind; most limed at Losar and weathered since, the
## wash going grey-yellow and thin to the earth plaster, the log storeys' oxblood fading; a poor or absent household's
## logs gone to grey timber), its woodwork's paint (the kit's red, blue and green swapped round, so one kit variant is
## several households), its lime's warmth (cool or creamy, its quarry and its earth); and whether it is shut, its
## household away (with a caravan, on pilgrimage, with the herds): its shutters closed, no smoke from its kitchen, no one
## on its roof at dusk (world/hearths.gd, world/roof_people.gd), its flags not renewed at Losar (world/flags.gd); and a
## few of those its people have left for good: bare poles on the roof, the lime and the paint long gone, grass on the
## earth. The townspeople's homes and the houses to enter are never shut. Drawn through
## shaders/stylized_static.gdshader's `household` instance uniform (its weathering stack takes the upkeep). Added by
## world/town.gd first of the town's life: the flags, the hearths, the roofs and the doors ask it.

const SHUT := 0.2  ## the share of houses shut: about a fifth (chapter 03's "forty shut houses" of Shöl's 150 were a quarter)
const SHUT_MONKS := 0.38  ## the monks' houses': chapter 02's MON-27 and 28, about 25 of 60 and 15 of 44 shut, their owners away
const LEFT := 0.05  ## of them, the share its people have left for good (as world/flags.gd's "left" drew them until 29 Sep 2026)
const FRESH := 0.2  ## the share limed and painted fresh this season
const PLAIN := Vector4(1.0, 0.0, 0.5, 0.0)  ## the shader's default: the kit's own lime and paint, lived in
const CAST_HOMES: Array[String] = ["H-SHL-020", "H-SHL-044", "H-SHL-078", "H-SHL-141", "H-HEJ-27", "H-HEJ-31"]  ## the named
## cast's homes among the town's generic houses (chapter 05, 4.1: Pasang, Nyima, Kalsang Drölma, Gönpo the coracle man, Wang Gui,
## Zhang Changshun), never shut (M2 sprint 10, step 1)
const LIVERY: Array[String] = ["H-SAM-01", "H-SAM-02", "H-SAM-03", "H-SAM-04", "H-SAM-05", "H-SAM-06", "H-SAM-07", "H-SAM-08"]  ## Samkha's
## retainers on Castle Lane (M2 sprint 11, step 2): the castle's colours in small, black strips and red woodwork, each its
## red door (chapter 03, 5.3): the kit's own paint, never swapped round
const HAN := "H-HEJ-"  ## Hejie's Han houses (M2 sprint 9, step 4): their paint -1, the shader's sign for no Tibetan paint on their woodwork, their rooms on the ground floor lit at night and the lanterns by their doors

static var plain := false  ## tests/terrain/s3.gd's --off=households: every house as the kit drew it (a before-and-after)

var per_house := {}  ## house name -> {upkeep, paint, warmth, shut, left}


## The houses that must stay lived in: every walker's home (the street graph's, tools/town/graph.py, with the "near:"
## homes resolved; before it is built, the named and generic days' own), the houses to enter (world/interiors.gd) and the
## named cast's (CAST_HOMES).
static func kept() -> Dictionary:
	var keep := {}
	var graph := "res://assets/generated/terrain/street_graph.json"
	if FileAccess.file_exists(graph):
		var g = JSON.parse_string(FileAccess.get_file_as_string(graph))
		if g is Dictionary:
			for w in (g as Dictionary).get("walkers", []):
				if not bool((w as Dictionary).get("roster", false)):  # (the day's drawn come from households at home: never a shut house)
					keep[String((w as Dictionary).get("home", ""))] = true
	for f in ["res://data/named_days.json", "res://data/generic_days.json"]:
		if not FileAccess.file_exists(f):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string(f))
		if d is Dictionary:
			for k in (d["people"] as Dictionary):
				keep[String(((d["people"] as Dictionary)[k] as Dictionary).get("home", ""))] = true
	for h in (load("res://world/interiors.gd") as GDScript).get("ROOMS").keys():
		keep[String(h)] = true
	for h in CAST_HOMES:
		keep[h] = true
	for h in keep.keys():  # only houses: not the places (dechen, yak_gate) or the unresolved near: ones
		if not String(h).begins_with("H-"):
			keep.erase(h)
	return keep


## One house's household, seeded by its name: {upkeep, paint, warmth, shut, left}. The town draws it (build) and
## tools/town/households_dump.gd writes it for tools/town/population.py, so the population's households away are the
## houses drawn shut (M2 sprint 10, step 1).
static func decide(name: String, keep: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name + ":household")
	var roll := rng.randf()
	var shut: bool = not keep.has(name) and roll < (SHUT_MONKS if name.begins_with("H-MON-") else SHUT)
	var left: bool = shut and roll < LEFT
	# upkeep: left long ago, away since before Losar, limed fresh this season, or limed at Losar (the poorest not)
	var upkeep := rng.randf_range(0.05, 0.25) if left else (rng.randf_range(0.2, 0.45) if shut else
			(rng.randf_range(0.9, 1.0) if rng.randf() < FRESH else rng.randf_range(0.3, 0.88)))
	var paint := rng.randi_range(0, 5)
	if name.begins_with(HAN):
		paint = -1
	elif name in LIVERY or name.begins_with("H-MON-"):  # (a monk's house: the kit's maroon and black, never a household's colours)
		paint = 0
	var warmth := rng.randf()
	return {"upkeep": upkeep, "paint": paint, "warmth": warmth, "shut": shut, "left": left}


## Decides every town house's household under `root` (the town) and draws it. Returns {houses, shut, left}.
func build(root: Node) -> Dictionary:
	var keep := kept()
	var n := 0
	var left_n := 0
	var shut_n := 0
	for h in root.get_children():
		var name := String(h.name)
		if not name.begins_with("H-"):
			continue
		var d := decide(name, keep)
		if plain:  # as before IMP-019: only the left houses cold (world/hearths.gd did that already)
			d["shut"] = d["left"]
		per_house[name] = d
		var shut: bool = d["shut"]
		var left: bool = d["left"]
		var upkeep: float = d["upkeep"]
		var paint: int = d["paint"]
		var warmth: float = d["warmth"]
		var v := Vector4(upkeep, float(paint), warmth, 1.0 if shut else 0.0)
		if not plain:  # (plain: the shader's default, PLAIN, drawn without setting it)
			for g in h.find_children("*", "GeometryInstance3D", true, false):
				(g as GeometryInstance3D).set_instance_shader_parameter("household", v)
		n += 1
		shut_n += int(shut)
		left_n += int(left)
	return {"houses": n, "shut": shut_n, "left": left_n}


func is_shut(house: String) -> bool:
	return bool((per_house.get(house, {}) as Dictionary).get("shut", false))


func is_left(house: String) -> bool:
	return bool((per_house.get(house, {}) as Dictionary).get("left", false))
