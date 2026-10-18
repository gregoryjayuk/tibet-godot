extends GutTest
## Hejie at a distance (M2 sprint 9, step 4; plan chapter 02, D03; chapter 03, 9): tools/town/hejie.py's houses, 32 F
## shop-houses and 8 G courtyard houses inside the wall and on no other's ground; its wall about chapter 02's 720 m;
## every named building the kit can build given its type (world/town.gd), standing at its pad's level on the real ground;
## its houses Han households (world/households.gd HAN); River Street a lane a stretch, from gate to gate, never too steep.

const DATA := "res://data/hejie.json"
const TOWN := "res://data/town.json"
const WALLS := "res://assets/generated/terrain/walls.json"
const Town := preload("res://world/town.gd")
const KIT := "res://assets/generated/kit/types/%s.glb"


func _d() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))


static func _corners(h: Dictionary) -> Array:
	var x := float(h["pos"][0])
	var y := float(h["pos"][1])
	var w := float(h["footprint"][0]) / 2.0
	var d := float(h["footprint"][1]) / 2.0
	var th := deg_to_rad(float(h.get("rot_deg", 180.0)))
	var f := Vector2(sin(th), cos(th))
	var a := Vector2(f.y, -f.x)
	return [Vector2(x, y) - a * w - f * d, Vector2(x, y) + a * w - f * d, Vector2(x, y) + a * w + f * d, Vector2(x, y) - a * w + f * d]


func test_its_houses() -> void:
	var houses: Array = _d()["houses"]
	assert_eq(houses.filter(func(h): return h["type"] == "F").size(), 32, "H-HEJ-01 to 32, F shop-houses")
	assert_eq(houses.filter(func(h): return h["type"] == "G").size(), 8, "H-HEJ-33 to 40, G courtyard houses")
	for i in houses.size():
		var a := _corners(houses[i])
		for j in range(i + 1, houses.size()):
			var b := _corners(houses[j])
			assert_false(Geometry2D.intersect_polygons(PackedVector2Array(a), PackedVector2Array(b)).size() > 0,
					"%s and %s apart" % [houses[i]["id"], houses[j]["id"]])
		assert_true(ResourceLoader.exists(KIT % Town.kit_file(houses[i])), "%s's kit file" % houses[i]["id"])


func test_the_wall() -> void:
	var walls: Array = _d()["walls"]
	var length := 0
	for w in walls:
		length += (w["pts"] as Array).size()
	assert_between(length, 680, 800, "about chapter 02's 720 m")
	assert_eq(walls.size(), 3, "broken for the East Gate, the Water Gate and the postern")
	if FileAccess.file_exists(WALLS):
		var runs := (JSON.parse_string(FileAccess.get_file_as_string(WALLS))["runs"] as Array).filter(func(r): return String(r["of"]) == "HEJ-01")
		assert_eq(runs.size(), 3, "walls.py builds it")


func test_the_named_buildings() -> void:
	var pads: Dictionary = _d()["pads"]
	var town: Array = JSON.parse_string(FileAccess.get_file_as_string(TOWN))["buildings"]
	var built := 0
	for b in town:
		if not String(b["id"]).begins_with("HEJ-") or b.get("pos") == null or b.get("footprint") == null:
			continue
		var f := Town.kit_file(b)
		if f == "":
			continue
		built += 1
		assert_true(ResourceLoader.exists(KIT % f), "%s's kit file %s" % [b["id"], f])
		assert_true(pads.has(String(b["id"])), "%s on its ground's level" % b["id"])
	assert_gte(built, 26, "the post, the temple, the gates, the inns, the godown, the shops")


func test_its_households_han() -> void:
	var Households: GDScript = load("res://world/households.gd")
	var root := Node3D.new()
	add_child_autofree(root)
	for name in ["H-HEJ-01", "H-SHL-001"]:
		var h := Node3D.new()
		h.name = name
		var m := MeshInstance3D.new()
		m.mesh = BoxMesh.new()
		h.add_child(m)
		root.add_child(h)
	var hh: Node = Households.new()
	add_child_autofree(hh)
	hh.build(root)
	assert_eq(int(hh.per_house["H-HEJ-01"]["paint"]), -1, "a Han house: no Tibetan paint, lit on its ground floor and by its lanterns")
	assert_between(int(hh.per_house["H-SHL-001"]["paint"]), 0, 5, "a Tibetan house its paint")


func test_river_street() -> void:
	var d := _d()
	var lanes: Array = d.get("lanes", [])
	assert_eq(lanes.size(), (d["street"] as Array).size() - 1, "a lane a stretch, from the East Gate down to the Water Gate")
	var last := INF
	for ln in lanes:
		var prof: Array = ln["profile"]
		if last != INF:
			assert_almost_eq(float(prof[0][1]), last, 0.05, "%s meets the stretch before it" % ln["id"])
		for k in range(1, prof.size()):
			var grade := absf(float(prof[k][1]) - float(prof[k - 1][1])) / maxf(float(prof[k][0]) - float(prof[k - 1][0]), 0.01)
			assert_lt(grade, 0.3, "%s not steeper than 30%% at %.0f m" % [ln["id"], float(prof[k][0])])
		last = float(prof[prof.size() - 1][1])
		assert_true(bool(ln.get("street", false)), "carved as a street (tools/terrain/pads.py)")
	var pads: Dictionary = d["pads"]
	assert_almost_eq(float(lanes[0]["z_a"]), float(pads["HEJ-02"]["level"]), 0.05, "met by the East Gate's floor")
	assert_almost_eq(float(lanes[lanes.size() - 1]["z_b"]), float(pads["HEJ-03"]["level"]), 0.05, "and the Water Gate's")
	for id in ["HEJ-09", "HEJ-11", "HEJ-12", "HEJ-14", "HEJ-16", "HEJ-20"]:  # the named buildings it bends between
		assert_true(pads.has(id), "%s on its ground" % id)
