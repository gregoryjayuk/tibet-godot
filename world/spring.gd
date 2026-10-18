extends Node3D
## The Lukhang spring's water carriers (M2 sprint 6, step 3; plan chapter 05, A-47: "carrying the water barrel on the
## back from the spring, a queue at dawn", 05:30-07:30 and 15:30-16:30; its activity zone `spring`: two filling, a queue
## of up to eight, women and girls, no washing, the gossip behind the queue; A-10, milk poured on the naga's rock
## 06:00-06:30), added by world/town.gd with the people. TownSim brings each water carrier on her day to the yard's way
## in (the street graph's anchor `spring`); while her day has her there, this places her (characters/named.gd
## `overrides`): she walks to the line's tail and waits, moving up as those ahead go to the spouts; at a free spout she
## crouches FILL minutes; then she stands talking with the others behind the queue until her day takes her home, and
## is back at the way in by then. The first come is the first served; the old woman who brings the milk pours it on
## the naga's rock before she joins the line. Every place is worked out from the minute (`plan`, `at`: pure, for the
## tests), so a still is the same each time. The two spouts are heard (SND-009).

const FILL := 4.0  ## game minutes at a spout: a 25-litre barrel, a ladle at a time
const MILK_T := 1.5  ## game minutes pouring the milk on the rock, and a prayer
const PACE := 0.85  ## m/s about the yard
const PER_MIN := 10.0  ## real seconds a game minute at the play rate (autoload/world_clock.gd)
const GRAPH := "res://assets/generated/terrain/street_graph.json"
const MILK_WHO := "water_woman_c"  ## who brings the naga's milk (A-10), on her first visit from 05:55
const MILK_FROM := 355.0
const SPOUT_SOUND := "SND-009"
enum { WALK = 0, STAND = 1, TALK = 4, CROUCH = 5 }

var spots := {}  ## "way", "milk", "rock", "naga", "queue" [8], "spout" [2], "water" [2], "side" [4] (Godot, global)
var visits: Array = []  ## the day's visits in the order they come: {i, who, arrive, leave, milk}
var planned: Array = []  ## `plan`'s, one a visit
var _keys: Array[String] = []


## The minutes a walk of `d` metres takes about the yard.
static func walk_min(d: float) -> float:
	return d / PACE / PER_MIN


## How many of those before visit `v` (in `ps`, planned in order) are still waiting for a spout at minute `m`.
static func _rank(ps: Array, v: int, m: float) -> int:
	var r := 0
	for u in v:
		if float(ps[u]["start"]) > m:
			r += 1
	return r


## Each visit's course through the yard, in the order they come (first come, first served; two spouts):
## {i, who, arrive, leave, milk: [t0, t1] or [], line: t she sets off for the line, rank: her place when she gets
## there, ready: t at it, start: t she leaves the line for spout `spout`, fill: [t0, t1], side: a gossip spot or -1,
## back: t she sets off for the way in, home: t she is there (by `leave`, unless the queue kept her: `late`)}.
static func plan(vs: Array, sp: Dictionary) -> Array:
	var out: Array = []
	var free := [-1.0e9, -1.0e9]
	var side_until := [-1.0e9, -1.0e9, -1.0e9, -1.0e9]
	var prev := -1.0e9
	var way: Vector3 = sp["way"]
	var queue: Array = sp["queue"]
	for v in vs.size():
		var vis: Dictionary = vs[v]
		var p := {"i": vis["i"], "who": vis["who"], "arrive": float(vis["arrive"]), "leave": float(vis["leave"]), "milk": []}
		var t: float = p["arrive"]
		var from := way
		if bool(vis.get("milk", false)):
			t += walk_min(way.distance_to(sp["milk"]))
			p["milk"] = [t, t + MILK_T]
			t += MILK_T
			from = sp["milk"]
		p["line"] = t
		var r := mini(_rank(out, v, t + walk_min(from.distance_to(queue[0]))), queue.size() - 1)
		p["rank"] = r
		p["ready"] = t + walk_min(from.distance_to(queue[r]))
		var k := 0 if float(free[0]) <= float(free[1]) else 1
		var start := maxf(maxf(float(p["ready"]), float(free[k])), prev + 0.05)
		p["start"] = start
		p["spout"] = k
		var at_start: Vector3 = queue[0] if start > float(p["ready"]) else queue[r]
		var f0 := start + walk_min(at_start.distance_to(sp["spout"][k]))
		p["fill"] = [f0, f0 + FILL]
		free[k] = f0 + FILL + 0.05
		prev = start
		var end := f0 + FILL
		var side := -1
		for j in 4:
			if float(side_until[j]) < end:
				side = j
				break
		var back := -1.0
		if side >= 0:
			back = float(p["leave"]) - walk_min((sp["side"][side] as Vector3).distance_to(way))
			if back < end + walk_min((sp["spout"][k] as Vector3).distance_to(sp["side"][side])) + 0.3:
				side = -1
			else:
				side_until[side] = float(p["leave"])
		if side < 0:
			back = maxf(end, float(p["leave"]) - walk_min((sp["spout"][k] as Vector3).distance_to(way)))
		p["side"] = side
		p["back"] = back
		var last: Vector3 = sp["side"][side] if side >= 0 else sp["spout"][k]
		p["home"] = back + walk_min(last.distance_to(way))
		p["late"] = float(p["home"]) > float(p["leave"]) + 0.01
		out.append(p)
	return out


static func _yaw(d: Vector3) -> float:
	return atan2(d.x, d.z)


static func _go(a: Vector3, b: Vector3, t0: float, m: float) -> Dictionary:
	var dur := walk_min(a.distance_to(b))
	var u := clampf((m - t0) / maxf(dur, 0.001), 0.0, 1.0)
	return {"pos": a.lerp(b, u), "yaw": _yaw(b - a), "state": WALK, "speed": PACE}


## Where visit `v` (of `ps`) is at minute `m`, and doing what: {pos, yaw, state, speed}, or {} outside its visit.
static func at(ps: Array, v: int, sp: Dictionary, m: float) -> Dictionary:
	var p: Dictionary = ps[v]
	if m < float(p["arrive"]) or m >= maxf(float(p["home"]), float(p["leave"])):
		return {}
	var way: Vector3 = sp["way"]
	var queue: Array = sp["queue"]
	var k: int = p["spout"]
	var spout: Vector3 = sp["spout"][k]
	var water: Vector3 = sp["water"][k]
	var milk: Array = p["milk"]
	if not milk.is_empty():
		if m < float(milk[0]):
			return _go(way, sp["milk"], float(p["arrive"]), m)
		if m < float(milk[1]):
			return {"pos": sp["milk"], "yaw": _yaw((sp["rock"] as Vector3) - (sp["milk"] as Vector3)), "state": STAND, "speed": 0.0}
	var from: Vector3 = way if milk.is_empty() else sp["milk"]
	var r0: int = p["rank"]
	if m < float(p["ready"]):
		return _go(from, queue[r0], float(p["line"]), m)
	var start: float = p["start"]
	if m < start:  # in the line, moving up a place as each ahead of her goes to a spout
		var r := mini(_rank(ps, v, m), r0)
		var last_change := -1.0
		for u in v:
			var s := float(ps[u]["start"])
			if s > float(p["ready"]) and s <= m:
				last_change = maxf(last_change, s)
		var here: Vector3 = queue[r]
		if last_change >= 0.0 and r + 1 < queue.size():
			var g := _go(queue[r + 1], here, last_change, m)
			if (g["pos"] as Vector3).distance_to(here) > 0.01:
				return g
		var ahead: Vector3 = queue[r - 1] if r > 0 else (spout + (sp["spout"][1 - k] as Vector3)) * 0.5
		return {"pos": here, "yaw": _yaw(ahead - here), "state": STAND, "speed": 0.0}
	var fill: Array = p["fill"]
	var waited: Vector3 = queue[0] if start > float(p["ready"]) else queue[r0]
	if m < float(fill[0]):
		return _go(waited, spout, start, m)
	if m < float(fill[1]):
		var to := Vector3(water.x - spout.x, 0.0, water.z - spout.z)
		return {"pos": spout, "yaw": _yaw(to), "state": CROUCH, "speed": 0.0}
	var side: int = p["side"]
	if side >= 0:
		var sd: Vector3 = sp["side"][side]
		if m < float(fill[1]) + walk_min(spout.distance_to(sd)):
			return _go(spout, sd, float(fill[1]), m)
		if m < float(p["back"]):
			var mid := Vector3.ZERO
			for s in sp["side"]:
				mid += s as Vector3
			mid /= 4.0
			return {"pos": sd, "yaw": _yaw(mid - sd), "state": TALK, "speed": 0.0}
		return _go(sd, way, float(p["back"]), m)
	if m < float(p["back"]):
		return {"pos": spout, "yaw": _yaw(way - spout), "state": STAND, "speed": 0.0}
	return _go(spout, way, float(p["back"]), m)


## The spring's places from the kit's sockets (kit/spring.py) and the street graph's way in; the day's visits from the
## walkers' days; the plan; the spouts heard. Returns how many visits.
func build(root: Node3D) -> int:
	add_to_group("named_placers")  # characters/named.gd asks `place` before it draws a frame
	var sh := root.get_node_or_null("SHL-14") as Node3D
	if sh == null or not FileAccess.file_exists(GRAPH):
		return 0
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GRAPH))
	var a: Array = (g["anchors"] as Dictionary).get("spring", [])
	if a.is_empty():
		return 0
	spots = places(sh)
	spots["way"] = preload("res://world/town.gd").to_godot(float(a[0]), float(a[1]), float(a[2]))
	visits = day_visits(g["walkers"])
	planned = plan(visits, spots)
	var sd: Node = AudioDirector.sound if is_instance_valid(AudioDirector) else null
	if sd != null:
		for k in (spots["water"] as Array).size():
			var key := "spring_spout_%d" % k
			sd.call("loop_start", key, SPOUT_SOUND, spots["water"][k], -1.0 * k)
			_keys.append(key)
	return visits.size()


## The yard's places from its sockets, each kind in its order (Godot, global).
static func places(sh: Node3D) -> Dictionary:
	var out := {}
	for kind in ["QUEUE", "SPOUT", "WATER", "SIDE"]:
		var found: Array = sh.find_children("SOCK_%s_*" % kind, "Node3D", true, false)
		found.sort_custom(func(x, y): return int(String(x.name).get_slice("_", 2)) < int(String(y.name).get_slice("_", 2)))
		out[kind.to_lower()] = found.map(func(n): return (n as Node3D).global_position)
	for kind in ["MILK", "ROCK", "NAGA", "OUTFLOW"]:
		var n := sh.find_child("SOCK_%s_1" % kind, true, false) as Node3D
		out[kind.to_lower()] = n.global_position if n != null else sh.global_position
	return out


## Every stop at the spring in the walkers' days, in the order they come: {i, who, arrive, leave, milk}.
static func day_visits(walkers: Array) -> Array:
	var out: Array = []
	var milked := false
	for i in walkers.size():
		var w: Dictionary = walkers[i]
		for stop in w["day"]:
			if String(stop[0]) == "spring":
				out.append({"i": i, "who": String(w.get("who", w["kind"])), "arrive": float(stop[1]), "leave": float(stop[2]), "milk": false})
	out.sort_custom(func(x, y): return float(x["arrive"]) < float(y["arrive"]))
	for v in out:
		if not milked and String(v["who"]) == MILK_WHO and float(v["arrive"]) >= MILK_FROM:
			v["milk"] = true
			milked = true
	return out


## Each water carrier in the yard where the plan has her at this minute (characters/named.gd calls it before drawing);
## one in the yard on none of her visits goes back to her day.
func place(named: Node) -> void:
	if planned.is_empty():
		return
	var ov: Dictionary = named.get("overrides")
	var people: Dictionary = named.get("people")
	var m := fposmod(WorldClock.minute, 1440.0)
	var here := {}
	for v in planned.size():
		var i: int = planned[v]["i"]
		if people.has(i) and not here.has(i):
			var o := at(planned, v, spots, m)
			if not o.is_empty():
				here[i] = o
	for i in ov.keys():
		if (ov[i] as Dictionary).get("by", "") == "spring" and not here.has(i):
			ov.erase(i)
	for i in here:
		if ov.has(i) and (ov[i] as Dictionary).get("by", "") != "spring":
			continue  # another's (a conversation, a greeting) for now
		var o: Dictionary = here[i]
		o["by"] = "spring"
		ov[i] = o


func _exit_tree() -> void:
	var sd: Node = AudioDirector.sound if is_instance_valid(AudioDirector) else null
	if sd != null:
		for key in _keys:
			sd.call("loop_stop", key)
	_keys.clear()
