extends GutTest
## The Gorge Stair R-07 (M3 sprint 2, step 1; plan chapter 02, R-07, RNG-02, RNG-07, RNG-08, MON-18; chapter 03's Gorge
## Stair row): tools/town/gorge_stair.py's way from the Gorge Rim Lookout's terrace down the gorge's west wall, over the
## upper bridge RNG-02 and up the east face to the West Gate: risers of 0.19 m, treads of 0.26, 1.2 m clear; the walk
## down then up, never the wrong way; the bridge near the chapter's place, 6 m over the water; the monastery's houses off
## the way; every piece the kit's.

const GORGE := "res://data/gorge_stair.json"
const MONASTERY := "res://data/monastery.json"
const LANE_KIT := "res://assets/generated/kit/lanes/%s.glb"
const KIT := "res://assets/generated/kit/types/%s.glb"
const Town := preload("res://world/town.gd")


func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(GORGE))


static func _corners(ln: Dictionary) -> PackedVector2Array:
	var o := Vector2(float(ln["from"][0]), float(ln["from"][1]))
	var d := Vector2(float(ln["dir"][0]), float(ln["dir"][1]))
	var n := Vector2(-d.y, d.x)
	var w := float(ln["width"]) / 2.0
	var e := o + d * float(ln["length"])
	return PackedVector2Array([o - n * w, o + n * w, e + n * w, e - n * w])


func test_the_steps() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json (tools/py tools/town/gorge_stair.py)")
		return
	var d := _data()
	var n := {"R07W": 0, "R07E": 0}
	for ln in d["lanes"]:
		var f = ln.get("flight")
		if f == null or int(f["n"]) == 0:
			continue
		var leg := String(ln["id"]).substr(0, 4)
		n[leg] += int(f["n"])
		assert_almost_eq(float(f["rise"]) / int(f["n"]), 0.19, 0.005, "%s: risers of 19 cm (chapter 03)" % ln["id"])
		assert_between(float(f["run"]), 0.24, 0.28, "%s: treads of 24-28 cm" % ln["id"])
		assert_almost_eq(float(ln["length"]), int(f["n"]) * float(f["run"]), 0.01, "%s: its flight its lane's length" % ln["id"])
		assert_gte(float(ln["width"]), 1.2, "%s: 1.2 m clear (with its parapet where it stands on a fill)" % ln["id"])
	assert_between(int(n["R07W"]), 300, 420, "the west leg's steps (chapter 02: 385; the real ground's height from the Lookout)")
	assert_between(int(n["R07E"]), 800, 950, "the east leg's (chapter 02: 885)")


func test_down_then_up() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var d := _data()
	var walk: Array = d["walk"]
	var deck := float(d["bridge"]["deck"])
	var lowest := INF
	var k_low := 0
	for k in walk.size():
		if float(walk[k][2]) < lowest:
			lowest = float(walk[k][2])
			k_low = k
	assert_almost_eq(lowest, deck, 0.05, "the way's lowest the bridge's deck")
	for k in range(1, walk.size()):
		var a: Array = walk[k - 1]
		var b: Array = walk[k]
		var run := Vector2(float(b[0]) - float(a[0]), float(b[1]) - float(a[1])).length()
		var dz := float(b[2]) - float(a[2])
		if k <= k_low:
			assert_true(dz <= 0.001, "down the west leg (at point %d)" % k)
		else:
			assert_true(dz >= -0.001, "up the east leg (at point %d)" % k)
		assert_lt(absf(dz), maxf(run, 0.5) * 0.9, "no steeper than the stair (at point %d)" % k)


func test_the_bridge() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var d := _data()
	var b: Dictionary = d["bridge"]
	var mid := Vector2(float(b["mid"][0]), float(b["mid"][1]))
	assert_lt(mid.distance_to(Vector2(330.0, 185.0)), 25.0, "near chapter 02's place (+330, +185)")
	assert_almost_eq(float(b["deck"]) - float(b["water"]), 6.0, 0.01, "its deck 6 m over the water")
	var nearest := INF
	for rv in JSON.parse_string(FileAccess.get_file_as_string("res://data/rivers.json"))["rivers"]:
		for q in rv["pts"]:
			nearest = minf(nearest, mid.distance_to(Vector2(float(q[0]), float(q[1]))))
	assert_lt(nearest, 5.0, "its middle over the Dungchu's water")
	var pl: Dictionary = d["places"]["RNG-02"]
	assert_true(ResourceLoader.exists(KIT % Town.kit_file({"id": "RNG-02"})), "drawn by %s" % Town.kit_file({"id": "RNG-02"}))
	assert_almost_eq(float(pl["level"]), float(b["deck"]), 0.01, "placed at its deck's level")


func test_the_ends() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var d := _data()
	var walk: Array = d["walk"]
	var first := Vector2(float(walk[0][0]), float(walk[0][1]))
	assert_lt(first.distance_to(Vector2(258.0, 245.0)), 3.0, "from the Gorge Rim Lookout's terrace")
	var last := Vector2(float(walk[walk.size() - 1][0]), float(walk[walk.size() - 1][1]))
	assert_lt(last.distance_to(Vector2(445.0, 160.0)), 1.0, "to the West Gate's place (chapter 02: +445, +160)")
	assert_eq((d["galleries"] as Array).size(), 3, "three galleries' places on the east leg (chapter 02: RNG-08)")


func test_the_monastery_off_the_way() -> void:
	if not FileAccess.file_exists(GORGE) or not FileAccess.file_exists(MONASTERY):
		pending("no data/gorge_stair.json or data/monastery.json")
		return
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MONASTERY))
	var hs: Array = (m["houses"] as Array) + (m.get("buildings", []) as Array)
	var clash: Array = []
	for ln in _data()["lanes"]:
		var a := _corners(ln)
		for h in hs:
			var c := Vector2(float(h["pos"][0]), float(h["pos"][1]))
			if c.distance_to(a[0]) > 60.0:
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
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var missing: Array = []
	for ln in _data()["lanes"]:
		var f = ln.get("flight")
		if f != null and not ResourceLoader.exists(LANE_KIT % String(f["file"])):
			missing.append(String(f["file"]))
	assert_eq(missing, [], "every flight and landing exported (../tibet-blender export_lanes.py)")


func test_v09_on_the_bridge() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var b: Dictionary = _data()["bridge"]
	var mid := Vector2(float(b["mid"][0]), float(b["mid"][1]))
	var ax := Vector2(sin(deg_to_rad(float(b["axis"]))), cos(deg_to_rad(float(b["axis"]))))
	var v09 := {}
	for v in JSON.parse_string(FileAccess.get_file_as_string("res://data/viewpoints.json"))["views"]:
		if String(v["id"]) == "V-09":
			v09 = v
	assert_false(v09.is_empty(), "V-09 a viewpoint to sit at (step 2; chapter 02 and 08)")
	var seat := Vector2(float(v09["seat"][0]), float(v09["seat"][1])) - mid
	assert_lt(absf(seat.dot(Vector2(-ax.y, ax.x))), 0.8, "its seat on the deck, between the rails")
	assert_lt(absf(seat.dot(ax)), float(b["span"]) / 2.0, "over the span")
	assert_almost_eq(float(v09["seat"][2]), float(b["deck"]), 0.05, "at the deck's level")
	assert_between(float(v09["bearing"]), 95.0, 115.0, "looking up the face (chapter 02: 105 degrees)")
	assert_gt(float(v09["pitch"]), 20.0, "up")
	var Moments := preload("res://world/moments.gd")
	for m in JSON.parse_string(FileAccess.get_file_as_string("res://data/moments.json"))["moments"]:
		if String(m["id"]) == "V-09":
			assert_true(Moments.window_open(m, 11.5 * 60.0), "its moment open at 11:30")
			assert_false(Moments.window_open(m, 14.0 * 60.0), "and closed at 14:00, the gorge's floor in shade")


func test_the_galleries_houses_and_rest() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var d := _data()
	var lanes := {}
	var top := 0
	for ln in d["lanes"]:
		lanes[String(ln["id"])] = ln
		if String(ln["id"]).begins_with("R07E.F"):
			top = maxi(top, int(String(ln["id"]).substr(6)))
	var gals := 0
	for ln in d["lanes"]:
		if ln.get("gallery", false) and ln.get("flight") != null:
			gals += 1
			assert_true(absi(int(ln["flight"].get("inner", 0))) == 1, "%s: its beams' side into the rock" % ln["id"])
	assert_eq(gals, 3, "three galleries on socketed beams (chapter 02, RNG-08)")
	var over := 0
	var rest := {}
	for th in d["things"]:
		assert_true(ResourceLoader.exists(KIT % String(th["kit"])), "%s drawn by %s" % [th["id"], th["kit"]])
		if String(th["kind"]) == "house_over":
			over += 1
			var ln: Dictionary = lanes[String(th["over"])]
			assert_gt(int(String(ln["id"]).substr(6)), top - 5, "%s over one of the stair's top flights (chapter 02: its top 40 m)" % th["id"])
			assert_between(float(th["level"]) - float(ln["z_b"]), 0.5, 4.5, "%s: its floor over the stair's treads" % th["id"])
		elif String(th["kind"]) == "rest_gallery":
			rest = th
	assert_between(over, 2, 3, "monks' houses built across the stair's top (chapter 02: three; two fit clear of its other pieces)")
	assert_false(rest.is_empty(), "the rest gallery RNG-09")
	assert_lt(Vector2(float(rest["at"][0]), float(rest["at"][1])).distance_to(Vector2(390.0, 175.0)), 20.0, "near chapter 02's place for it (+390, +175)")
	assert_true(bool(rest.get("wheels", false)), "its prayer wheel turned under a hand (world/kora_wheels.gd)")
	var v17 := {}
	for v in JSON.parse_string(FileAccess.get_file_as_string("res://data/viewpoints.json"))["views"]:
		if String(v["id"]) == "V-17":
			v17 = v
	assert_false(v17.is_empty(), "V-17 a viewpoint on its bench")
	assert_lt(Vector2(float(v17["seat"][0]), float(v17["seat"][1])).distance_to(Vector2(float(rest["at"][0]), float(rest["at"][1]))), 2.0, "its seat in the gallery")
	assert_between(float(v17["bearing"]), 270.0, 300.0, "across the gorge to Tödé (chapter 08: 290 degrees)")


func test_the_water_wheel_and_the_naga_shrine() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var d := _data()
	var w: Dictionary = d["wheel"]
	var at := Vector2(float(w["at"][0]), float(w["at"][1]))
	assert_lt(at.distance_to(Vector2(318.0, 172.0)), 15.0, "the water wheel RNG-04 near chapter 02's place (+318, +172)")
	var nearest := INF
	for rv in JSON.parse_string(FileAccess.get_file_as_string("res://data/rivers.json"))["rivers"]:
		for q in rv["pts"]:
			nearest = minf(nearest, at.distance_to(Vector2(float(q[0]), float(q[1]))))
	assert_between(nearest, 3.0, 9.0, "on the bank by the Dungchu, a side channel's run from it")
	var feed: Array = d["leat"][0]["pts"]
	for k in range(1, feed.size()):
		assert_true(float(feed[k][2]) <= float(feed[k - 1][2]) + 0.001, "its channel's water running down to it (at %d)" % k)
	assert_almost_eq(float(feed[feed.size() - 1][2]), float(w["level"]), 0.01, "into it at its level")
	var race: Array = d["leat"][1]["pts"]
	assert_lt(float(race[1][2]), float(race[0][2]), "its race down to the river")
	assert_true(ResourceLoader.exists(KIT % "ser09_wheel_house_v1"), "the Serchu's wheel house (world/mills.gd turns its drum)")
	var naga := {}
	for th in d["things"]:
		if String(th["kind"]) == "naga_shrine":
			naga = th
	assert_false(naga.is_empty(), "the naga shrine RNG-05")
	assert_lt(Vector2(float(naga["at"][0]), float(naga["at"][1])).distance_to(Vector2(345.0, 230.0)), 15.0, "near chapter 02's place (+345, +230)")
	assert_true(ResourceLoader.exists(KIT % String(naga["kit"])), "drawn by %s" % naga["kit"])


func test_the_flags_across_the_gorge() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var d := _data()
	var spans: Array = d["flags"]
	assert_eq(spans.size(), 6, "six strings across the gorge (chapter 02, RNG-06)")
	var rest := {}
	for th in d["things"]:
		if String(th["kind"]) == "rest_gallery":
			rest = th
	var g := Vector2(float(rest["at"][0]), float(rest["at"][1]))
	var eye := float(rest["level"]) + 1.6
	var v17 := 0
	for sp in spans:
		var a: Array = sp["a"]
		var b: Array = sp["b"]
		var span := Vector2(float(b[0]) - float(a[0]), float(b[1]) - float(a[1])).length()
		assert_between(span, 175.0, 245.0, "180-240 m (chapter 02)")
		assert_between(float(sp["sag"]), 2.0, span * 0.1, "sagging")
		if bool(sp.get("v17", false)):
			v17 += 1
			assert_lt(Vector2(float(b[0]), float(b[1])).distance_to(g), 10.0, "V-17's beside the rest gallery (chapter 08: the nearest 8 m out)")
			var t := 0.94
			var z := lerpf(float(a[2]), float(b[2]), t) - 4.0 * float(sp["sag"]) * t * (1.0 - t)
			assert_almost_eq(z, eye, 1.5, "at eye level a little way out")
	assert_eq(v17, 1, "one of them V-17's")
	var snd: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sound.json"))
	assert_true((snd["sounds"] as Dictionary).has("SND-015"), "heard: the flag mass of the gorge's spans (SND-015)")


func test_the_way_down_to_the_water() -> void:
	if not FileAccess.file_exists(GORGE):
		pending("no data/gorge_stair.json")
		return
	var d := _data()
	var w: Dictionary = d["water"]
	var path: Array = w["path"]
	var br: Dictionary = d["bridge"]
	assert_almost_eq(float(path[0][2]), float(br["deck"]), 0.01, "off the bridge's west landing at its deck's level")
	var fill: Array = w["fill"]
	var end: Array = path[path.size() - 1]
	assert_lt(Vector2(float(end[0]) - float(fill[0]), float(end[1]) - float(fill[1])).length(), 1.5, "down beside the wheel's channel's head")
	assert_between(float(end[2]) - float(fill[2]), 0.2, 0.8, "a little over its water")
	assert_almost_eq(float(w["riser"]), 0.19, 0.005, "risers of 19 cm (chapter 03)")
	var flights := 0
	for ln in d["lanes"]:
		if String(ln["id"]).begins_with("R07W.W") and ln["flight"] != null and int(ln["flight"].get("n", 0)) > 0:
			flights += 1
			assert_gt(float(ln["flight"]["rise"]), 0.0, "%s laid from its foot up" % ln["id"])
	assert_eq(flights, 2, "two flights")
	# clear of the bridge's west abutment: 3.8 m wide, from the span's end 3.2 m back (../tibet-blender kit/infra.py)
	var mid := Vector2(float(br["mid"][0]), float(br["mid"][1]))
	var ax := Vector2(float(br["e_end"][0]) - float(br["w_end"][0]), float(br["e_end"][1]) - float(br["w_end"][1])).normalized()
	for k in range(1, path.size()):
		for t in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var q := Vector2(lerpf(float(path[k - 1][0]), float(path[k][0]), t), lerpf(float(path[k - 1][1]), float(path[k][1]), t)) - mid
			var u := q.dot(ax)
			var v := absf(q.dot(ax.orthogonal()))
			if u > -15.2 and u < -12.0:
				assert_gt(v, 1.9 + 0.8, "the way's middle clear of the abutment's side (u %.1f)" % u)
