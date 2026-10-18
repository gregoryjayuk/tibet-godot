extends GutTest
## Dungkar Gönpa whole, step 4 (M3 sprint 3; tools/town/monastery.py LEVEL, FACING, FORECOURT, EXTRA; ../tibet-blender
## kit/monastery.py labrang, residence, estate_office, granary, jakhang, dronkhang, kangyur, gonpa_yard; world/hearths.gd,
## world/door_dressing.gd, world/corners.gd): the Labrang turned so its bay and V-06 look up the gorge, the working
## buildings and the small yards placed; the Jakhang's smoke at the morning and midday tea; the monks' houses lived in or
## shut: smoke and things in an M2's yard, or a barred and padlocked door and nothing.

const Town := preload("res://world/town.gd")
const Hearths := preload("res://world/hearths.gd")
const Households := preload("res://world/households.gd")
const Dressing := preload("res://world/door_dressing.gd")
const Corners := preload("res://world/corners.gd")
const MONASTERY := "res://data/monastery.json"
const SIDE := "res://assets/generated/kit/types/%s.json"
const KIT := "res://assets/generated/kit/types/%s.glb"


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func test_the_buildings_placed() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var m := _json(MONASTERY)
	var pads: Dictionary = m["pads"]
	for spec in [["MON-09", "mon09_labrang_in_v1"], ["MON-10", "mon10_abbots_house_v1"], ["MON-11", "mon11_estate_office_v1"], ["MON-12", "mon12_kitchen_in_v1"],
			["MON-13", "mon13_guest_house_v1"], ["MON-14", "mon14_library_in_v1"], ["MON-30", "mon30_novices_yard_v1"], ["MON-34", "mon34_geese_pen_v1"]]:
		assert_eq(String(pads[spec[0]]["kit"]), spec[1], "%s its own kit" % spec[0])
		assert_true(ResourceLoader.exists(KIT % spec[1]), "%s exported and imported" % spec[1])
	assert_almost_eq(float(pads["MON-09"]["facing"]), 218.0, 0.01, "the Labrang turned: its back, the bay's, at 038 up the gorge")
	assert_almost_eq(float(pads["MON-09"]["level"]), 2982.5, 0.01, "its door up 11 steps from the slope")
	assert_almost_eq(float(pads["MON-12"]["level"]), 2928.2, 0.01, "the Jakhang where its flume's trestles were measured")
	assert_almost_eq(float(pads["MON-13"].get("yard", 0.0)), 6.5, 0.01, "the guest house's stable yard levelled before it")
	var extra := {}
	for b in m["buildings"]:
		extra[String(b["id"])] = b
	for spec in [["MON-11G", "mon11_granary"], ["MON-38", "mon38_kennel"]]:
		assert_true(extra.has(spec[0]), "%s placed" % spec[0])
		if extra.has(spec[0]):
			var b: Dictionary = extra[spec[0]]
			assert_eq(String(Town.kit_file(b)), "%s_v1" % spec[1], "%s drawn by its kit" % spec[0])
			assert_true(ResourceLoader.exists(KIT % ("%s_v1" % spec[1])), "%s exported and imported" % spec[1])


func test_the_labrangs_bay_and_v06() -> void:
	if not FileAccess.file_exists(SIDE % "mon09_labrang_v1"):
		pending("no mon09_labrang_v1 (export_types.py)")
		return
	var pos: Dictionary = _json(SIDE % "mon09_labrang_v1")["socket_pos"]
	var bay := false
	for k in pos:
		var p: Array = pos[k]
		if String(k).begins_with("SOCK_WIN_") and float(p[1]) > 7.0 and float(p[2]) > 9.0 and float(p[2]) < 12.0:
			bay = true  # (on its back, the top floor's: the yellow bay)
	assert_true(bay, "the tulku's bay on its back's top floor")
	var vj := _json("res://data/viewpoints.json")
	var v06: Dictionary = {}
	for v in vj["views"]:
		if String(v["id"]) == "V-06":
			v06 = v
	assert_false(v06.is_empty(), "V-06 among the viewpoints")
	if v06.is_empty():
		return
	var lab: Dictionary = _json(MONASTERY)["pads"]["MON-09"]
	var off := Vector2(float(v06["seat"][0]) - float(lab["at"][0]), float(v06["seat"][1]) - float(lab["at"][1]))
	var b := fposmod(rad_to_deg(atan2(off.x, off.y)), 360.0)
	assert_between(off.length(), 4.0, 8.0, "on the roof by its front edge")
	assert_between(b, 190.0, 250.0, "by its front edge over the monastery (it was %.0f)" % b)
	assert_almost_eq(float(v06["seat"][2]), float(lab["level"]) + 13.6, 0.2, "at the roof's level")
	assert_between(float(v06["bearing"]), 200.0, 270.0, "over the monastery and down the valley (chapter 08's view up the gorge hidden by the spur: ISS-202)")


func test_the_jakhangs_smoke() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var k := Node3D.new()
	k.name = "MON-12"
	root.add_child(k)
	var s := Node3D.new()
	s.name = "SOCK_KITCHEN_1"
	k.add_child(s)
	var hs: Node3D = Hearths.new()
	root.add_child(hs)
	assert_eq(hs.build(root), 1, "the Jakhang's lantern smokes, never a cold hearth")
	var h: Dictionary = hs.hearths[0][1]
	assert_eq(String(hs.hearths[0][0]), "MON-12")
	assert_almost_eq(float(h["morning"][0]), 300.0, 0.01, "from five, the assembly's tea")
	assert_almost_eq(float(h["noon"]), 660.0, 0.01, "the midday tea at eleven")
	assert_almost_eq(float(h["evening"][1]) - float(h["evening"][0]), 0.0, 0.01, "no evening fire")
	assert_false(bool(h["kept"]), "not kept warm all day")
	if FileAccess.file_exists(SIDE % "mon12_kitchen_v1"):
		var pos: Dictionary = _json(SIDE % "mon12_kitchen_v1")["socket_pos"]
		assert_true(pos.has("SOCK_KITCHEN_1") and float(pos["SOCK_KITCHEN_1"][2]) > 8.0, "its KITCHEN over its lantern")


## The monks' houses lived in or shut (chapter 03, 6.9): their real records, so the town's rules apply as they do there.
func test_the_monks_houses_dressed() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var root := Node3D.new()
	add_child_autofree(root)
	var n := 0
	for h in _json(MONASTERY)["houses"]:
		if String(h["type"]) != "M2":
			continue
		var f := "res://assets/generated/kit/types/monk_house_m2_v%d.glb" % int(h["seed"])
		var node: Node3D = (load(f) as PackedScene).instantiate()
		node.name = String(h["id"])
		node.position = Town.to_godot(float(h["pos"][0]), float(h["pos"][1]), float(h["pos"][2]))
		node.rotation.y = -deg_to_rad(float(h["rot_deg"]) - 180.0)
		root.add_child(node)
		n += 1
	await wait_physics_frames(1)
	var hh: Node = Households.new()
	root.add_child(hh)
	hh.build(root)
	var dd: Node3D = Dressing.new()
	root.add_child(dd)
	var dr: Dictionary = dd.build(root, hh)
	var cn: Node3D = Corners.new()
	root.add_child(cn)
	cn.build(root, hh)
	var hs: Node3D = Hearths.new()
	root.add_child(hs)
	hs.build(root, null, hh)
	var smoking := {}
	for e in hs.hearths:
		smoking[String(e[0])] = true
	var shut := 0
	var lived_things := 0
	for h in dd.per_house:
		var files: Array = dd.per_house[h]
		if hh.is_shut(String(h)):
			shut += 1
			assert_eq(files, ["door_bar_v1"], "%s shut: its door barred and padlocked, nothing else" % h)
			assert_false(cn.per_house.has(h), "%s shut: nothing by its walls" % h)
			assert_false(smoking.has(h), "%s shut: no smoke" % h)
		else:
			assert_eq(files.size(), 0, "%s lived in: no household's things at a monk's door" % h)
			lived_things += int(cn.per_house.has(h))
	assert_eq(int(dr["barred"]), shut, "every shut M2 barred")
	assert_between(shut, 8, 30, "some 15 of the 44 M2 shut (chapter 02, MON-28)")
	assert_gt(lived_things, 5, "the lived-in ones' things in their yards")
	assert_gt(smoking.size(), 10, "their hearths smoking")
