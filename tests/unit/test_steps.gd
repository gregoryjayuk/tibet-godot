extends GutTest
## The 1,080 steps (M3 sprint 1, step 1; plan chapter 02, R-04, RNG-11 and 5.3; chapter 12's M3, acceptance 1):
## tools/town/dungrong.py's way from the Conch Bridge's east end to the South Gate's forecourt: 1,080 steps of 19.5 cm in
## 23 flights of 36-60 with treads of 27-30 cm, 2.4 m wide between their walls; landing 6 the Lhabab Chorten's platform;
## the gate at the top step's level; the monastery's houses off the way; every piece the kit's.

const STEPS := "res://data/dungrong.json"
const MONASTERY := "res://data/monastery.json"
const LANE_KIT := "res://assets/generated/kit/lanes/%s.glb"
const KIT := "res://assets/generated/kit/types/%s.glb"
const Town := preload("res://world/town.gd")


func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(STEPS))


static func _corners(ln: Dictionary) -> PackedVector2Array:
	var o := Vector2(float(ln["from"][0]), float(ln["from"][1]))
	var d := Vector2(float(ln["dir"][0]), float(ln["dir"][1]))
	var n := Vector2(-d.y, d.x)
	var w := float(ln["width"]) / 2.0
	var e := o + d * float(ln["length"])
	return PackedVector2Array([o - n * w, o + n * w, e + n * w, e - n * w])


func test_the_thousand_and_eighty() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json (tools/py tools/town/dungrong.py)")
		return
	var d := _data()
	var n := 0
	var flights := 0
	for ln in d["lanes"]:
		var f = ln.get("flight")
		if f == null or int(f["n"]) == 0:
			continue
		flights += 1
		n += int(f["n"])
		assert_between(int(f["n"]), 36, 60, "%s: 36-60 steps (chapter 02, 5.3)" % ln["id"])
		assert_almost_eq(float(f["rise"]) / int(f["n"]), 0.195, 0.0005, "%s: risers of 19.5 cm" % ln["id"])
		assert_between(float(f["run"]), 0.27, 0.30, "%s: treads of 27-30 cm" % ln["id"])
		assert_almost_eq(float(ln["length"]), int(f["n"]) * float(f["run"]), 0.01, "%s: its flight its lane's length" % ln["id"])
	assert_eq(n, 1080, "1,080 steps: ten rounds of a 108-bead rosary")
	assert_eq(flights, 23, "in 23 flights")
	assert_almost_eq(float(d["width"]), 2.4, 0.001, "2.4 m wide between the walls")
	assert_almost_eq(float(d["foot"]["z"]), 2672.0, 0.01, "from the Conch Bridge's deck (chapter 02: 2,672 m)")
	assert_almost_eq(float(d["top"]["z"]), 2672.0 + 1080 * 0.195, 0.01, "to the top step's level")


func test_the_way_climbs_without_a_break() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json")
		return
	var line: Array = _data()["line"]
	assert_gt(line.size(), 380, "380 m and more of way (chapter 02: 380 m)")
	for k in range(1, line.size()):
		var a: Array = line[k - 1]
		var b: Array = line[k]
		assert_true(float(b[2]) >= float(a[2]) - 0.001, "the way never steps down (at %d m)" % k)
		assert_lt(float(b[2]) - float(a[2]), 1.0, "no more than a metre's rise in a metre (at %d m)" % k)


func test_landing_six_and_the_gate() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json")
		return
	var d := _data()
	var six := {}
	for lg in d["landings"]:
		if int(lg["number"]) == 6:
			six = lg
	assert_eq(String(six.get("kind", "")), "platform", "landing 6 the Lhabab Chorten's platform")
	assert_lt(Vector2(float(six["at"][0]) - 330.0, float(six["at"][1]) + 5.0).length(), 15.0, "near chapter 02's place for the chorten (+330, -5)")
	assert_almost_eq(float(six["z"]), 2672.0 + 360 * 0.195, 0.01, "at its 360th step (chapter 02: 2,742 m)")
	if FileAccess.file_exists(MONASTERY):
		var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MONASTERY))
		assert_almost_eq(float(m["pads"]["MON-17"]["level"]), float(d["top"]["z"]), 0.01, "the South Gate at the top step's level")


func test_the_monastery_off_the_way() -> void:
	if not FileAccess.file_exists(STEPS) or not FileAccess.file_exists(MONASTERY):
		pending("no data/dungrong.json or data/monastery.json")
		return
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MONASTERY))
	var hs: Array = (m["houses"] as Array) + (m.get("buildings", []) as Array)
	var clash: Array = []
	for ln in _data()["lanes"]:
		var a := _corners(ln)
		for h in hs:
			var c := Vector2(float(h["pos"][0]), float(h["pos"][1]))
			if c.distance_to(a[0]) > 80.0:
				continue
			var th := deg_to_rad(float(h["rot_deg"]))
			var f := Vector2(sin(th), cos(th))
			var x := Vector2(-cos(th), sin(th))
			var w := float(h["footprint"][0]) / 2.0
			var dd := float(h["footprint"][1]) / 2.0
			var r := PackedVector2Array([c - x * w - f * dd, c + x * w - f * dd, c + x * w + f * dd, c - x * w + f * dd])
			if not Geometry2D.intersect_polygons(a, r).is_empty():
				clash.append("%s/%s" % [ln["id"], h["id"]])
	assert_eq(clash, [], "no monk's house on the way")


func test_every_piece_the_kits() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json")
		return
	var missing: Array = []
	for ln in _data()["lanes"]:
		var f = ln.get("flight")
		if f != null and not ResourceLoader.exists(LANE_KIT % String(f["file"])):
			missing.append(String(f["file"]))
	assert_eq(missing, [], "every flight and landing exported (../tibet-blender export_lanes.py)")


func test_the_conch_bridge_and_the_way_to_it() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json")
		return
	var d := _data()
	var pl: Dictionary = d.get("places", {})
	assert_true(pl.has("RNG-01") and pl.has("RNG-14"), "the Conch Bridge and the tsenkhang placed (step 2)")
	for id in ["RNG-01", "RNG-14"]:
		assert_true(ResourceLoader.exists(KIT % Town.kit_file({"id": id})), "%s drawn by %s" % [id, Town.kit_file({"id": id})])
	var mid := Vector2(float(pl["RNG-01"]["at"][0]), float(pl["RNG-01"]["at"][1]))
	var nearest := INF
	for rv in JSON.parse_string(FileAccess.get_file_as_string("res://data/rivers.json"))["rivers"]:
		for q in rv["pts"]:
			nearest = minf(nearest, mid.distance_to(Vector2(float(q[0]), float(q[1]))))
	assert_lt(nearest, 4.0, "the bridge's middle over the Dungchu's water")
	var foot := Vector2(float(d["foot"]["at"][0]), float(d["foot"]["at"][1]))
	assert_almost_eq(mid.distance_to(foot), 9.0, 0.05, "the steps' foot at its span's east end")
	var w: Dictionary = d["way_in"]
	assert_almost_eq(mid.distance_to(Vector2(float(w["to"][0]), float(w["to"][1]))), 12.2, 0.05, "the way from Pema Ö's forecourt to its deck's west end")
	var found := false
	for ln in d["lanes"]:
		if String(ln["id"]).begins_with("R04.W"):
			found = true
	assert_true(found, "that way a lane, carved and paved")


func test_the_chortens_the_rest_house_and_the_wheels() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json")
		return
	var d := _data()
	var at := {}
	for lg in d["landings"]:
		at[int(lg["number"])] = Vector2(float(lg["at"][0]), float(lg["at"][1]))
	var six: Dictionary = d["places"]["RNG-12"]
	assert_lt(Vector2(float(six["at"][0]), float(six["at"][1])).distance_to(at[6]), 10.0, "the Lhabab Chorten beside landing 6's platform (step 3)")
	assert_almost_eq(float(six["level"]), 2672.0 + 360 * 0.195, 0.01, "at the platform's level")
	assert_true(ResourceLoader.exists(KIT % Town.kit_file({"id": "RNG-12"})), "the Lhabab Chorten drawn by %s" % Town.kit_file({"id": "RNG-12"}))
	var things := {}
	for th in d["things"]:
		things[String(th["id"])] = th
		assert_true(ResourceLoader.exists(KIT % String(th["kit"])), "%s drawn by %s" % [th["id"], th["kit"]])
	for id in ["RNG-13.1", "RNG-13.3"]:
		var q := Vector2(float(things[id]["at"][0]), float(things[id]["at"][1]))
		assert_lt(q.distance_to(at[12]), 12.0, "%s beside landing 12" % id)
	var top := Vector2(float(d["top"]["forecourt"]["at"][0]), float(d["top"]["forecourt"]["at"][1]))
	assert_lt(Vector2(float(things["RNG-13.2"]["at"][0]), float(things["RNG-13.2"]["at"][1])).distance_to(top), 12.0, "the rnam rgyal chorten in the forecourt at the top")
	var niches := 0
	for num in [4, 8, 12, 16, 20]:
		var id := "R04.N%02d" % num
		assert_true(things.has(id) and bool(things[id].get("wheels", false)), "a niche of prayer wheels at landing %d (chapter 02, 5.3)" % num)
		niches += 1
	assert_eq(niches, 5, "at every fourth landing")
	for ln in d["lanes"]:
		if String(ln["id"]) == "R04.L12":
			assert_true(String(ln["flight"]["walls"]) in ["lime_l", "lime_r"], "landing 12's wall open on its terrace's side")


func test_the_parkhang() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json")
		return
	var d := _data()
	var pk: Dictionary = d["places"].get("RNG-10", {})
	assert_true(bool(pk.get("pad", false)), "the Parkhang placed on a pad of its own (step 4)")
	assert_true(ResourceLoader.exists(KIT % Town.kit_file({"id": "RNG-10"})), "drawn by %s" % Town.kit_file({"id": "RNG-10"}))
	var c := Vector2(float(pk["at"][0]), float(pk["at"][1]))
	assert_lt(c.distance_to(Vector2(float(d["foot"]["at"][0]), float(d["foot"]["at"][1]))), 60.0, "at the foot of the stair (chapter 03, 6.10)")
	assert_between(float(pk["facing"]), 135.0, 225.0, "its entrance to the south")
	var th := deg_to_rad(float(pk["facing"]))
	var f := Vector2(sin(th), cos(th))
	var x := Vector2(-cos(th), sin(th))
	var r := PackedVector2Array([c - x * 14.0 - f * 10.0, c + x * 14.0 - f * 10.0, c + x * 14.0 + f * 10.0, c - x * 14.0 + f * 10.0])
	var clash: Array = []
	for ln in d["lanes"]:
		if not Geometry2D.intersect_polygons(r, _corners(ln)).is_empty():
			clash.append(ln["id"])
	assert_eq(clash, [], "off the steps and their landings")
	var P := preload("res://world/parkhang.gd")
	assert_true(P.at_work(600.0), "its printers at work at 10:00")
	assert_false(P.at_work(1200.0), "and gone at 20:00")



func test_v04_on_the_lhabab_terrace() -> void:
	if not FileAccess.file_exists(STEPS):
		pending("no data/dungrong.json")
		return
	var t12: Array = _data()["places"]["RNG-12"]["at"]
	var tc := Vector2(float(t12[0]), float(t12[1]))
	var v04 := {}
	for v in JSON.parse_string(FileAccess.get_file_as_string("res://data/viewpoints.json"))["views"]:
		if String(v["id"]) == "V-04":
			v04 = v
	assert_false(v04.is_empty(), "V-04 a viewpoint to sit at (step 6; world/viewpoints.gd)")
	var seat := Vector2(float(v04["seat"][0]), float(v04["seat"][1]))
	assert_between(seat.distance_to(tc), 3.0, 5.7, "its seat on the chorten's terrace, clear of the chorten (6 x 6 on its 8 x 8)")
	assert_between(float(v04["bearing"]), 240.0, 255.0, "looking over Shöl, the slot and Hejie (chapter 02: 245 degrees)")
	assert_between(float(v04["hour"]), 16.0, 16.67, "in its window, 16:00-16:40")
	var Moments := preload("res://world/moments.gd")
	var m04 := {}
	for m in JSON.parse_string(FileAccess.get_file_as_string("res://data/moments.json"))["moments"]:
		if String(m["id"]) == "V-04":
			m04 = m
	assert_false(m04.is_empty(), "and a moment, logged once")
	assert_true(Moments.window_open(m04, 16.3 * 60.0), "open at 16:18")
	assert_false(Moments.window_open(m04, 17.0 * 60.0), "closed at 17:00")
