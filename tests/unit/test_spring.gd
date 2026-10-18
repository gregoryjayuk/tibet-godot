extends GutTest
## The Lukhang spring SHL-14 (M2 sprint 6, step 3; plan chapter 02: "yard 12 x 8, women with barrels at dawn, drinking
## water for Shöl; no washing at the spring"; chapter 03: the naga's niche; chapter 05, A-47 and A-10): the kit's yard
## and its places (../tibet-blender kit/spring.py), placed on its pad, its way in on the walkers' ground, the water
## carriers' visits, and world/spring.gd's queue: first come first served, never two at a spout, each home by her
## day's time, a queue at first light, the milk on the naga's rock.

const Spring := preload("res://world/spring.gd")
const KIT := "res://assets/generated/kit/types/sh14_lukhang_v1"
const GRAPH := "res://assets/generated/terrain/street_graph.json"


func _yard() -> Node3D:
	var n := (load(KIT + ".glb") as PackedScene).instantiate() as Node3D
	add_child_autofree(n)
	return n


func _spots(n: Node3D) -> Dictionary:
	var sp := Spring.places(n)
	sp["way"] = Vector3(5.0, 0.05, 2.5)  # the street graph's way in, in the kit's frame (tools/town/graph.py: 5 m east, 2.5 m down)
	return sp


func _visits() -> Array:
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GRAPH))
	return Spring.day_visits(g["walkers"])


func test_the_yard_and_its_places() -> void:
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(KIT + ".json"))
	var socks: Dictionary = side["socket_pos"]
	var count := func(kind: String) -> int:
		return socks.keys().filter(func(k): return String(k).begins_with("SOCK_%s_" % kind)).size()
	assert_eq(count.call("QUEUE"), 8, "a queue of up to eight (chapter 05's zone `spring`)")
	assert_eq(count.call("SPOUT"), 2, "two filling")
	assert_eq(count.call("WATER"), 2, "two spouts heard")
	assert_eq(count.call("SIDE"), 4, "the talk behind the queue")
	for k in ["NAGA", "ROCK", "MILK", "OUTFLOW"]:
		assert_eq(count.call(k), 1, "its %s" % k)
	var naga: Array = socks["SOCK_NAGA_1"]
	assert_between(float(naga[2]), 1.0, 2.1, "the niche over the spring at a hand's height")


func test_placed_on_its_pad() -> void:
	var town: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json"))
	var b := {}
	for x in town["buildings"]:
		if String(x["id"]) == "SHL-14":
			b = x
	assert_eq(b.get("footprint", []), [12.0, 8.0], "its yard, 12 x 8 (chapter 02)")
	assert_eq(int(b.get("rot_deg", 180)), 190, "facing down its slope")
	var named: Dictionary = load("res://world/town.gd").NAMED
	assert_true(named.has("SHL-14"), "placed by the town")
	assert_eq(float(named["SHL-14"][1]), 2775.0, "at chapter 02's 2,775 m")


func test_the_way_in_on_the_walkers_ground() -> void:
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GRAPH))
	var a: Array = (g["anchors"] as Dictionary).get("spring", [])
	assert_false(a.is_empty(), "the spring on the walkers' ground")
	assert_lt(Vector2(float(a[0]), float(a[1])).distance_to(Vector2(-110.0, 234.5)), 7.5, "its way in at the yard's east side")
	assert_almost_eq(float(a[2]), 2775.0, 0.6, "on its level")


func test_the_water_carriers_come() -> void:
	var vs := _visits()
	var dawn := vs.filter(func(v): return float(v["arrive"]) >= 330.0 and float(v["arrive"]) < 460.0)
	var after := vs.filter(func(v): return float(v["arrive"]) >= 925.0 and float(v["arrive"]) < 990.0)
	assert_gte(dawn.size(), 10, "trips from first light to half past seven (A-47)")
	assert_gte(after.size(), 6, "and from half past three")
	var bunch := vs.filter(func(v): return float(v["arrive"]) >= 340.0 and float(v["arrive"]) <= 342.0)
	assert_gte(bunch.size(), 5, "most of them at first light")
	var who := {}
	for v in vs:
		who[String(v["who"])] = true
	for k in ["water_woman", "water_woman_b", "water_woman_c", "water_woman_d", "water_girl", "water_girl_b", "kalsang_drolma"]:
		assert_true(who.has(k), "%s comes for water" % k)
		if k.begins_with("water"):
			assert_true(ResourceLoader.exists("res://assets/generated/people/%s.glb" % k), "%s's body, her barrel on her back" % k)


func test_first_come_first_served() -> void:
	var sp := _spots(_yard())
	var vs := _visits()
	var ps := Spring.plan(vs, sp)
	assert_eq(ps.size(), vs.size(), "every visit planned")
	var last := -1.0e9
	var fills := [[], []]
	var longest := 0
	for p in ps:
		assert_gte(float(p["start"]), last, "%s's turn after those who came before her" % p["who"])
		last = float(p["start"])
		(fills[int(p["spout"])] as Array).append(p["fill"])
		assert_false(bool(p["late"]), "%s at the way in by %.0f, her day's time to go" % [p["who"], float(p["leave"])])
		assert_lte(float(p["fill"][1]), float(p["leave"]), "%s filled before she goes" % p["who"])
		longest = maxi(longest, int(p["rank"]))
	for k in 2:
		var f: Array = fills[k]
		for j in range(1, f.size()):
			assert_gte(float(f[j][0]), float(f[j - 1][1]), "one at a time at spout %d" % k)
	assert_gte(longest, 2, "a queue at first light")
	var milk := ps.filter(func(p): return not (p["milk"] as Array).is_empty())
	assert_eq(milk.size(), 1, "the naga's milk once (A-10)")
	assert_eq(String(milk[0]["who"]), Spring.MILK_WHO, "by the old woman")
	assert_between(float(milk[0]["milk"][0]), 355.0, 390.0, "between six and half past (A-10)")


func test_where_they_are() -> void:
	var sp := _spots(_yard())
	var ps := Spring.plan(_visits(), sp)
	var queued := -1
	for v in ps.size():
		if int(ps[v]["rank"]) >= 1 and float(ps[v]["start"]) > float(ps[v]["ready"]) + 0.5:
			queued = v
			break
	assert_gt(queued, -1, "someone waits in the line")
	var p: Dictionary = ps[queued]
	var o := Spring.at(ps, queued, sp, (float(p["ready"]) + float(p["start"])) / 2.0)
	assert_eq(int(o["state"]), Spring.STAND, "waiting, standing")
	var near_spot := false
	for q in sp["queue"]:
		if (o["pos"] as Vector3).distance_to(q) < 1.0:
			near_spot = true
	assert_true(near_spot, "in the line")
	var f: Array = p["fill"]
	o = Spring.at(ps, queued, sp, (float(f[0]) + float(f[1])) / 2.0)
	assert_eq(int(o["state"]), Spring.CROUCH, "crouched at the spout")
	assert_lt((o["pos"] as Vector3).distance_to(sp["spout"][int(p["spout"])]), 0.05, "at her spout")
	assert_true(Spring.at(ps, queued, sp, float(p["arrive"]) - 1.0).is_empty(), "not before she comes")
	assert_true(Spring.at(ps, queued, sp, float(p["leave"]) + 1.0).is_empty(), "nor after she goes")
	for v in ps.size():
		if int(ps[v]["side"]) >= 0 and float(ps[v]["back"]) > float(ps[v]["fill"][1]) + 2.0:
			o = Spring.at(ps, v, sp, float(ps[v]["back"]) - 0.5)
			assert_eq(int(o["state"]), Spring.TALK, "talking behind the queue")
			break
	for v in ps.size():
		if not (ps[v]["milk"] as Array).is_empty():
			var m: Array = ps[v]["milk"]
			o = Spring.at(ps, v, sp, (float(m[0]) + float(m[1])) / 2.0)
			assert_lt((o["pos"] as Vector3).distance_to(sp["milk"]), 0.05, "at the naga's rock with the milk")


func test_in_the_towns_frame() -> void:  # as world/town.gd places it, with the street graph's way in (world/spring.gd build)
	var Town := load("res://world/town.gd")
	var n := _yard()
	var nm: Array = Town.NAMED["SHL-14"]
	n.position = Town.to_godot(float(nm[2][0]), float(nm[2][1]), float(nm[1]))
	n.rotation.y = -deg_to_rad(float(nm[3]) - 180.0)
	var sp := Spring.places(n)
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GRAPH))
	var a: Array = g["anchors"]["spring"]
	sp["way"] = Town.to_godot(float(a[0]), float(a[1]), float(a[2]))
	assert_lt((sp["way"] as Vector3).distance_to(sp["queue"][7]), 3.0, "the way in by the line's tail")
	assert_almost_eq(float((sp["way"] as Vector3).y), float((sp["spout"][0] as Vector3).y), 0.6, "on the yard's level")
	for p in Spring.plan(_visits(), sp):
		assert_false(bool(p["late"]), "%s home on time in the town's frame" % p["who"])


class FakeNamed:  # characters/named.gd as world/spring.gd sees it
	extends Node
	var overrides := {}
	var people := {}


func test_placed_at_their_hours() -> void:  # every carrier in the yard on one of her visits gets her place, the rest none
	var spring := Spring.new()
	add_child_autofree(spring)
	var sp := _spots(_yard())
	spring.spots = sp
	spring.visits = _visits()
	spring.planned = Spring.plan(spring.visits, sp)
	var fake := FakeNamed.new()
	add_child_autofree(fake)
	for p in spring.planned:
		fake.people[int(p["i"])] = {}
	var was: float = WorldClock.minute
	var frozen: bool = WorldClock.frozen
	WorldClock.frozen = true
	WorldClock.minute = 343.98  # first light: two at the spouts, three in the line, Kalsang talking
	spring.place(fake)
	assert_eq(fake.overrides.size(), 6, "six in the yard at 05:44")
	var crouched := fake.overrides.values().filter(func(o): return int(o["state"]) == Spring.CROUCH)
	assert_eq(crouched.size(), 2, "two filling")
	var gap := -1.0  # a minute of the morning with no one's visit near it (the day's drawn may fetch water any time)
	for t in range(420, 900):
		if spring.visits.filter(func(v): return float(t) > float(v["arrive"]) - 5.0 and float(t) < float(v["leave"]) + 5.0).is_empty():
			gap = float(t)
			break
	assert_gt(gap, 0.0, "a quiet minute at the spring in the morning")
	WorldClock.minute = gap  # nobody at the spring
	spring.place(fake)
	assert_eq(fake.overrides.size(), 0, "and none left placed after")
	WorldClock.minute = was
	WorldClock.frozen = frozen


func test_the_codex_nods_here() -> void:
	var sites: Array = load("res://world/codex_sites.gd").SITES
	var here := sites.filter(func(s): return String(s[2]).begins_with("SHL-14"))
	assert_eq(here.size(), 2, "CX-061 at the niche, CX-062 at the spouts")
