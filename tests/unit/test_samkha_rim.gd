extends GutTest
## Samkha's rim (M2 sprint 11, step 4; plan chapter 02, SAM-11, SAM-12 and SAM-16; chapter 03, 5.1 and 12.3): the Leat
## Fall's outlet in the slot's face and its water's path down to the river (tools/town/samkha_rim.py), the latrine's
## midden on a ledge under the castle's latrine bay, the 1861 breach a ruin at level 2; the kit's types for them and the
## town's places (world/town.gd rim_places).

const DATA := "res://data/samkha_rim.json"
const RIVERS := "res://data/rivers.json"
const KIT := "res://assets/generated/kit/types/%s.json"
const Town := preload("res://world/town.gd")


func _d() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))


func test_the_leat_fall() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no data/samkha_rim.json (tools/py tools/town/samkha_rim.py)")
		return
	var lf: Dictionary = _d()["leat_fall"]
	var path: Array = lf["path"]
	assert_gt(path.size(), 10, "its water's line down the face")
	for k in range(1, path.size()):
		assert_lte(float(path[k][2]), float(path[k - 1][2]) + 0.001, "falling all the way (%d)" % k)
		assert_lte(float(path[k][1]), float(path[k - 1][1]) + 0.001, "out from the face, never back into it (%d)" % k)
	assert_between(float(lf["drop"]), 25.0, 50.0, "chapter 02's 30 m, or what the real face gives")
	var out: Array = lf["outlet"]
	assert_lt(float(out[0]), -79.5, "west of the north ramp's landings")
	assert_gt(float(out[0]), -89.0, "east of the 1861 breach")
	var slot: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(RIVERS))["rivers"] as Array).filter(func(r): return String(r["name"]) == "Samkha slot")[0]
	var near: Array = (slot["pts"] as Array).reduce(func(a, q): return q if absf(float(q[0]) - float(out[0])) < absf(float(a[0]) - float(out[0])) else a)
	assert_almost_eq(float(lf["foot"][2]), float(near[2]), 0.3, "into the slot's river at its level")


func test_the_midden() -> void:
	if not FileAccess.file_exists(DATA):
		pending("no data/samkha_rim.json")
		return
	var m: Array = _d()["midden"]
	assert_almost_eq(float(m[0]), -136.9, 0.01, "under the latrine bay's column (the castle at -130, its bay at u -6.9)")
	assert_between(2649.0 - float(m[2]), 4.0, 14.0, "on a ledge under the rim, not in the torrent (the klu)")
	assert_lt(float(m[1]), -96.0, "south of the castle's face, on the slot's")


func test_the_kit_and_the_places() -> void:
	for f in ["sam16_breach_v1", "sam11_leat_outlet_v1", "sam12_midden_v1"]:
		if not FileAccess.file_exists(KIT % f):
			pending("no kit type %s (../tibet-blender export_types.py)" % f)
			return
	var socks: Array = JSON.parse_string(FileAccess.get_file_as_string(KIT % "sam11_leat_outlet_v1"))["sockets"]
	assert_has(socks, "SOCK_LIP_1", "the water's lip")
	var breach: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(KIT % "sam16_breach_v1"))
	assert_gt(int(breach["collision_hulls"]), 6, "the shell's walls walked round, its breach's floor walked over")
	var places := Town.rim_places()
	assert_true(places.has("SAM-11") and places.has("SAM-12"), "the outlet and the midden placed from the rim's data")
	assert_eq(Town.kit_file({"id": "SAM-16"}), "sam16_breach_v1", "the breach the kit's ruin")
