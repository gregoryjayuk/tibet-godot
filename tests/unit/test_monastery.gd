extends GutTest
## Dungkar Gönpa on the spur (M2 sprint 13, steps 2 and 3; plan chapter 02, D08, MON-26 to MON-29; chapter 03, 6.1 and
## 6.9): tools/town/monastery.py's 60 M1 stacked up the west face's rows, the 44 M2 round the south flank and among the
## halls, the four khamtsen each between its two ranges M3; inside the enclosure, clear of the halls and of each other,
## each M2 with its walled yard on its pad on the side its variant gives; drawn by the kit's variants; about two in five
## shut, in the kit's own colours; the halls at the middle of their ground, each drawn by its far form.

const MONASTERY := "res://data/monastery.json"
const TOWN := "res://data/town.json"
const KIT := "res://assets/generated/kit/types/%s.glb"
const Town := preload("res://world/town.gd")
const Households := preload("res://world/households.gd")
const ENCLOSURE := Rect2(430.0, -40.0, 275.0, 310.0)  ## D08: x +430 to +705, y -40 to +270


func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(MONASTERY))


## A footprint's corners in the town grid: width across the front, depth along it.
static func _corners(c: Vector2, w: float, d: float, rot: float) -> PackedVector2Array:
	var th := deg_to_rad(rot)
	var f := Vector2(sin(th), cos(th))
	var a := Vector2(-cos(th), sin(th))  # the kit's +x
	return PackedVector2Array([c - a * w / 2 - f * d / 2, c + a * w / 2 - f * d / 2, c + a * w / 2 + f * d / 2, c - a * w / 2 + f * d / 2])


## A building's ground: its pad where it has one (an M2 and its yard, a khamtsen and its portico), else its footprint.
static func _ground(h: Dictionary) -> PackedVector2Array:
	if h.has("pad"):
		var p: Array = h["pad"]
		return _corners(Vector2(float(p[0]), float(p[1])), float(p[2]), float(p[3]), float(h["rot_deg"]))
	return _corners(Vector2(float(h["pos"][0]), float(h["pos"][1])), float(h["footprint"][0]), float(h["footprint"][1]), float(h["rot_deg"]))


func test_the_monks_houses() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json (tools/py tools/town/monastery.py)")
		return
	var hs: Array = _data()["houses"]
	assert_eq(hs.filter(func(h): return h["type"] == "M1").size(), 60, "MON-27: H-MON-001 to 060")
	assert_eq(hs.filter(func(h): return h["type"] == "M2").size(), 44, "MON-28: H-MON-061 to 104")
	assert_eq(hs.filter(func(h): return h["type"] == "M3").size(), 8, "MON-29: the khamtsen's ranges H-MON-105 to 112")
	var ids := {}
	for h in hs:
		ids[String(h["id"])] = true
		var n := int(String(h["id"]).substr(6))
		var want := "M1" if n <= 60 else ("M2" if n <= 104 else "M3")
		assert_eq(String(h["type"]), want, "%s's number its type's" % h["id"])
		assert_true(ResourceLoader.exists(KIT % Town.kit_file(h)), "%s's kit file %s" % [h["id"], Town.kit_file(h)])
		for p in _ground(h):
			assert_true(ENCLOSURE.has_point(p), "%s inside the enclosure" % h["id"])
	assert_eq(ids.size(), 112, "each its own id")
	var middle := hs.filter(func(h): return h["type"] == "M2" and h["quarter"] == "gonpa.tsokchen").size()
	assert_between(middle, 10, 20, "some of the M2 among the halls of the middle zone (MON-28: lower and middle zones)")
	var face := hs.filter(func(h): return h["type"] == "M1" and float(h["pos"][0]) < 500.0)
	assert_gt(face.size(), 40, "most of the M1 on the west face, the cliff-dwelling face (MON-27)")
	var rows := {}
	for h in face:
		rows[int(h["row"])] = true
	assert_gt(rows.size(), 6, "the face's M1 stacked up its rows, not a single file along its brink")


func test_the_khamtsen_between_their_ranges() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var d := _data()
	var ks: Array = (d.get("buildings", []) as Array).filter(func(b): return String(b.get("type", "")) == "khamtsen hall")  # (the
	# granary range and the kennel are `buildings` too since M3 sprint 3, step 4)
	assert_eq(ks.size(), 4, "MON-26: the Dungkar, Minyak, Nyarong and Litang houses")
	for k in ks:
		assert_true(ResourceLoader.exists(KIT % Town.kit_file(k)), "%s's kit file %s" % [k["id"], Town.kit_file(k)])
		var group := String(k["name_en"]).get_slice("the ", 1).get_slice(" house", 0)
		var c := Vector2(float(k["pos"][0]), float(k["pos"][1]))
		var near := (d["houses"] as Array).filter(func(h): return h["type"] == "M3" and String(h.get("group", "")) == group and Vector2(float(h["pos"][0]), float(h["pos"][1])).distance_to(c) < 30.0)
		assert_eq(near.size(), 2, "the %s house between its two ranges" % group)


func test_clear_of_the_halls_and_each_other() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var d := _data()
	var all: Array = (d["houses"] as Array) + (d.get("buildings", []) as Array)
	var pads: Dictionary = d.get("pads", {})
	var halls: Array = []
	for b in JSON.parse_string(FileAccess.get_file_as_string(TOWN))["buildings"]:
		if String(b.get("id", "")).begins_with("MON-") and b.get("pos") != null and b.get("footprint") != null and b["pos"][2] != null and not (d.get("follow", []) as Array).has(b["id"]):
			var at: Array = (pads.get(b["id"], {}) as Dictionary).get("at", b["pos"])
			var rot := float((pads.get(b["id"], {}) as Dictionary).get("facing", b.get("rot_deg", 180.0) if b.get("rot_deg") != null else 180.0))
			halls.append([b["id"], _corners(Vector2(float(at[0]), float(at[1])), float(b["footprint"][0]), float(b["footprint"][1]), rot)])
	assert_gt(halls.size(), 10, "the halls of the gazetteer")
	for i in all.size():
		var a := _ground(all[i])
		for hl in halls:
			assert_eq(Geometry2D.intersect_polygons(a, hl[1]).size(), 0, "%s clear of %s" % [all[i]["id"], hl[0]])
		for j in range(i + 1, all.size()):
			assert_eq(Geometry2D.intersect_polygons(a, _ground(all[j])).size(), 0, "%s and %s apart" % [all[i]["id"], all[j]["id"]])


func test_an_m2s_yard_on_its_variants_side() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	for h in _data()["houses"]:
		if h["type"] != "M2":
			continue
		assert_true(h.has("pad"), "%s's pad, its yard's ground with its own" % h["id"])
		var th := deg_to_rad(float(h["rot_deg"]))
		var kx := Vector2(-cos(th), sin(th))
		var off := (Vector2(float(h["pad"][0]), float(h["pad"][1])) - Vector2(float(h["pos"][0]), float(h["pos"][1]))).dot(kx)
		var side := 1.0 if int(h["seed"]) % 2 == 0 else -1.0  # the kit's monk_house: v2, v4, v6 on its +x
		assert_almost_eq(off, side * 2.0, 0.05, "%s: its yard on its variant's side, the house half a yard off the pad's middle" % h["id"])


func test_variants_differ_from_their_neighbours() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var hs: Array = _data()["houses"]
	var same := 0
	var pairs := 0
	for i in hs.size():
		for j in range(i + 1, hs.size()):
			if hs[i]["type"] != hs[j]["type"]:
				continue
			var dd := Vector2(float(hs[i]["pos"][0]) - float(hs[j]["pos"][0]), float(hs[i]["pos"][1]) - float(hs[j]["pos"][1])).length()
			if dd < 12.0:
				pairs += 1
				if hs[i].get("variant", hs[i]["seed"]) == hs[j].get("variant", hs[j]["seed"]):  # (the carved H-MON-012's own variant)
					same += 1
	assert_gt(pairs, 20, "neighbours")
	assert_eq(same, 0, "no two neighbours the same variant (avoid uniformity)")


func test_about_two_in_five_shut_in_the_kits_colours() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var shut := 0
	for h in _data()["houses"]:
		var dd := Households.decide(String(h["id"]), {})
		if dd["shut"]:
			shut += 1
		assert_eq(int(dd["paint"]), 0, "%s in the kit's maroon and black" % h["id"])
	assert_between(shut, 30, 60, "MON-27 to 29: about 25 of 60, 15 of 44 and some of the ranges' shut (chapter 03, 6.9: about 40)")


func test_the_halls_at_their_far_form() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var pads: Dictionary = _data()["pads"]
	for id in ["MON-01", "MON-04", "MON-05", "MON-06", "MON-08", "MON-09", "MON-10", "MON-11", "MON-12", "MON-13", "MON-14", "MON-15", "MON-16", "MON-17", "MON-19"]:
		assert_true(pads.has(id), "%s placed" % id)
		var rec := {"id": id}
		assert_true(ResourceLoader.exists(KIT % Town.kit_file(rec)), "%s drawn by %s" % [id, Town.kit_file(rec)])
	assert_eq(Town.kit_file({"id": "MON-01"}), "mon01_tsokchen_in_v1", "the Tsokchen whole, its hall carved (M3 sprint 5, step 1; test_tsokchen.gd)")
	assert_true((pads["MON-08"] as Dictionary).has("moved_from"), "the tantric college off its 26 m of fall")
	assert_false(pads.has("MON-41"), "the thangka terrace on the slope until its site is settled (ISS-188)")
	assert_eq(float(pads["MON-16"]["facing"]), 225.0, "the thangka wall faces 225 degrees, over the confluence")


func test_the_wall() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var d := _data()
	var runs: Array = d.get("walls", [])
	assert_gt(runs.size(), 1, "the wall MON-21 in runs (step 4)")
	var total := 0.0
	# (the Gönkor's galleries stand on its line, the wall run to their ends: test_gonkor.gd keeps it out of them)
	var all: Array = (d["houses"] as Array) + (d.get("buildings", []) as Array).filter(func(b): return String(b["type"]) != "wheel arcade")
	var door := false
	var in_door := 0
	var through: Array = []
	var grounds: Array = all.map(func(h): return _ground(h))
	for r in runs:
		assert_eq(String(r["of"]), "MON-21", "the monastery's wall")
		assert_between(float(r["h"]), 3.0, 4.0, "3-4 m high (chapter 03, 6.8)")
		var pts: Array = r["pts"]
		for i in pts.size():
			var q := Vector2(float(pts[i][0]), float(pts[i][1]))
			if i > 0:
				total += q.distance_to(Vector2(float(pts[i - 1][0]), float(pts[i - 1][1])))
			if q.distance_to(Vector2(660.0, 270.0)) < 0.85:
				in_door += 1
			for k in grounds.size():
				if Geometry2D.is_point_in_polygon(q, grounds[k]):
					through.append(all[k]["id"])
		if Vector2(float(pts[pts.size() - 1][0]), float(pts[pts.size() - 1][1])).distance_to(Vector2(660.0, 270.0)) < 2.0:
			door = true
	assert_eq(in_door, 0, "no wall in the Upper Gate's door")
	assert_eq(through, [], "the wall through no building")
	for b in (d.get("buildings", []) as Array):  # the Gönkor's galleries stand on its line, their walls its length there (M3
		# sprint 3, step 6)
		if String(b["id"]).begins_with("MON-22"):
			total += float(b["footprint"][0])
	assert_between(total, 750.0, 950.0, "chapter 03's 1,050 m less the west face, whose houses are the wall")
	assert_true(door, "a run ends at the Upper Gate's door")

