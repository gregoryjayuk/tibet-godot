extends Node
## TownSim (plan chapter 11, 12.1; chapter 05, 9.8): the town's people as data, not nodes. Agents live in packed
## arrays and walk a street graph from node to node; nothing is a node until characters/crowd.gd draws it.
## Bands by distance from the player ration the work (chapter 05, 9.8): positions move every frame for everyone,
## because a drawn figure must move smoothly, but the per-agent thinking runs near (0-35 m) every frame, middle
## (35-250 m) at 2 Hz and far at 0.2 Hz. Thinking today is the choice of the next street at a crossing and, near the
## player, keeping a shoulder's width from each other; schedules, evaluate(t) and smart objects come with M1.
## Spike S5's first cut (roadmap RT-13). `last_us` is the cost of the last step, for the spike's budget (2.5 ms).
## Since M1 sprint 4, step 4, a second way: walkers on the street graph (tools/town/graph.py), along its fastest routes
## at their own paces (Tobler's function on slopes, their own step times on flights), with their stays (standing,
## indoors out of sight, round the great wheel, round the mani wall). Since sprint 6, step 1, each walks a default day
## at the clock (chapter 05, 7.2; IMP-017): places to be at by clock times, left at clock times; each departure is
## worked back from its arrival by the route's time at the clock's 6:1 (chapter 12's "schedules as arrival times"), so
## the day is the same at any clock rate. A day is a line of knots in game minutes from midnight, and where anyone is
## at the clock's minute is looked up, not simulated (chapter 11, 12.1: evaluate(t)).
## Since sprint 6, step 3, the named eight walk among them (their kind is their key, not one of the crowd's: kind 255,
## drawn by characters/named.gd): at a place a stop can have a seat, where the walker's feet go and which way it faces,
## walked to straight from the place's anchor and back; and a walker can sit (on a ledge), crouch or talk as well as
## stand. Every knot keeps the way the walker faces while it is there, so a look-up at any minute faces it right.

const NEAR := 35.0
const MIDDLE := 250.0
const MIDDLE_EVERY := 0.5
const FAR_EVERY := 5.0
const SHOULDER := 0.8  ## near agents keep this far apart, sideways on their street

var nodes := PackedVector3Array()
var adj: Array[PackedInt32Array] = []
var count := 0
var kind := PackedByteArray()  ## archetype index, for the crowd
var from_node := PackedInt32Array()
var to_node := PackedInt32Array()
var along := PackedFloat32Array()  ## metres along the current edge
var edge_len := PackedFloat32Array()
var speed := PackedFloat32Array()  ## metres a second
var side := PackedFloat32Array()  ## sideways offset on the street, metres (right of travel)
var next_think := PackedFloat32Array()  ## sim time of the agent's next thinking step
var band := PackedByteArray()  ## 0 near, 1 middle, 2 far
var pos := PackedVector3Array()  ## where the agent is drawn, this frame
var yaw := PackedFloat32Array()  ## the direction of travel, as rotation.y for a figure that faces +Z
var time := 0.0
var running := false
## the walkers' way (setup_walkers): per walker its round's knots, from k0[i] to k0[i + 1] - 1 in the flat arrays: the
## time into the round, the place, and what it does until the next knot (0 walks, 1 stands, 2 is indoors)
var walkers_on := false
var state := PackedByteArray()  ## 0 walking, 1 standing, 2 indoors (not drawn), 3 sitting, 4 talking, 5 crouching, 6 sitting
## cross-legged (on a Tibetan bench or the floor: ISS-088)
var vel := PackedVector3Array()  ## m/s, this frame (the great wheel reads who pushes it)
var cur_speed := PackedFloat32Array()  ## m/s along the ground, this frame (the crowd's walk rate)
var round_len := PackedFloat32Array()  ## a day's game minutes (1440)
var day_minute := 0.0  ## the minute of the day the walkers were last looked up at
var slipped := 0  ## arrivals later than their schedule (a route longer than the time its walker left for it)
var slips: Array = []  ## each: [walker's kind, place, minutes late]
var k0 := PackedInt32Array()
var cursor := PackedInt32Array()
var kt := PackedFloat32Array()
var kp := PackedVector3Array()
var ks := PackedByteArray()
var ky := PackedFloat32Array()  ## the way the walker faces from each knot (rotation.y of a figure facing +Z)
var key := PackedStringArray()  ## each walker's kind by name (the crowd's archetype, or a named walker's key)
var who := PackedStringArray()  ## each walker's own name (a named walker's key in its days file, though it wear another's body; the crowd's kind)
var days: Array = []  ## each walker's day as graph.py wrote it (the named eight's are read by characters/named.gd)
var keeper := PackedByteArray()  ## 1 for a market stall's keeper (tools/town/graph.py; M2 sprint 10, step 4): it hardly moves,
## so the crowd moves it down a tier first (chapter 05, 13.1)
var court := {}  ## walker -> [from, to, felt]: a party to the Pönpo's morning hearing (tools/town/graph.py; M2 sprint 11,
## step 5), in the castle then and on its felt in the hall (world/samkha_people.gd draws it there)
const NAMED := 255  ## the kind of a walker the crowd does not draw
const UNSEEN := 254  ## the kind of one of the day's drawn whose figure the crowd was not given: it walks, undrawn
const Town := preload("res://world/town.gd")
var last_us := 0
var thinks := 0
var _rng := RandomNumberGenerator.new()
var _near := PackedInt32Array()


## A graph (node positions and, per node, its neighbours) and n agents of `kinds` archetypes, placed at random.
func setup(p_nodes: PackedVector3Array, p_adj: Array, n: int, kinds: int, seed_value := 1903) -> void:
	walkers_on = false
	nodes = p_nodes
	adj.clear()
	for a in p_adj:
		adj.append(PackedInt32Array(a))
	count = n
	_rng.seed = seed_value
	kind.resize(n)
	band.resize(n)
	from_node.resize(n)
	to_node.resize(n)
	along.resize(n)
	edge_len.resize(n)
	speed.resize(n)
	side.resize(n)
	next_think.resize(n)
	yaw.resize(n)
	pos.resize(n)
	for i in n:
		kind[i] = i % kinds
		var a := _rng.randi_range(0, nodes.size() - 1)
		from_node[i] = a
		to_node[i] = adj[a][_rng.randi_range(0, adj[a].size() - 1)]
		edge_len[i] = nodes[a].distance_to(nodes[to_node[i]])
		along[i] = _rng.randf() * edge_len[i]
		speed[i] = _rng.randf_range(0.9, 1.3)
		side[i] = _rng.randf_range(-1.2, 1.2)
		next_think[i] = _rng.randf() * FAR_EVERY
		band[i] = 2
	time = 0.0
	running = true
	_place_all()


func _place_all() -> void:
	for i in count:
		_place(i)


func _place(i: int) -> void:
	var a := nodes[from_node[i]]
	var b := nodes[to_node[i]]
	var d := b - a
	var t := along[i] / maxf(edge_len[i], 0.001)
	var right := Vector3(-d.z, 0.0, d.x).normalized()
	pos[i] = a + d * t + right * side[i]
	yaw[i] = atan2(d.x, d.z)


## The street graph's walkers (tools/town/graph.py's street_graph.json), drawn as `kinds` (the crowd's archetypes, by
## name; any other kind is NAMED, drawn by characters/named.gd), each on its day: [place, arrive, leave, how, loops,
## seat] in game minutes from midnight. Between two places the walker leaves the first at the second's arrival less the
## way's time (off its seat, the route, onto the next: its pace, the clock's 6:1), or on leaving it if that is later (the
## arrival slips: `slipped`); at a place it stands, talks, sits, crouches, is indoors, goes twice round the great wheel
## or round the mani wall `loops` times, and stays until its time to leave.
func setup_walkers(path: String, kinds: Array[String], _seed_value := 1903) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var routes: Dictionary = data["routes"]
	var anchors: Dictionary = data.get("anchors", {})
	var ws: Array = data["walkers"]
	var rate := float(data.get("rate", WorldClock.RATE_PLAY))
	count = ws.size()
	walkers_on = true
	kind.resize(count)  # one by one: a packed array put in a list is copied
	keeper.resize(count)
	court.clear()
	key.resize(count)
	who.resize(count)
	days.resize(count)
	band.resize(count)
	state.resize(count)
	speed.resize(count)
	cur_speed.resize(count)
	round_len.resize(count)
	yaw.resize(count)
	pos.resize(count)
	vel.resize(count)
	cursor.resize(count)
	k0.resize(count + 1)
	kt.clear()
	kp.clear()
	ks.clear()
	ky.clear()
	slipped = 0
	slips.clear()
	var cache := {}  # route name -> its points in Godot
	for i in count:
		var w: Dictionary = ws[i]
		var k := kinds.find(String(w["kind"]))
		kind[i] = NAMED if bool(w.get("named", false)) or (k < 0 and not bool(w.get("roster", false))) else (k if k >= 0 else UNSEEN)
		# (a written day's walker is characters/named.gd's, though the crowd draw others in its figure: M2 sprint 10, step 2)
		key[i] = String(w["kind"])
		keeper[i] = 1 if w.has("keeper") else 0
		if w.has("court"):
			court[i] = w["court"]
		who[i] = String(w.get("who", w["kind"]))
		speed[i] = float(w["pace"])
		k0[i] = kt.size()
		var day: Array = w["day"]
		days[i] = day
		var here := String(day[0][0])
		kt.append(0.0)
		kp.append(_anchor(anchors, here))
		ks.append(_state(String(day[0][3]), {}))
		ky.append(0.0)
		var t := float(day[0][2])  # when it leaves home
		var seat_was := {}  # the seat it is on (it walks off it to the place's anchor first)
		for s in range(1, day.size()):
			var stop: Array = day[s]
			var to := String(stop[0])
			var arrive := float(stop[1])
			var name := "%s>%s" % [here, to]
			var seat: Dictionary = stop[5] if stop.size() > 5 and stop[5] is Dictionary else {}
			var off_at := _anchor(anchors, here)  # off a seat to where the way on begins (a place can be left elsewhere)
			if routes.has(name):
				off_at = _route_points(routes, cache, name)[0]
			var on_at := _anchor(anchors, to)
			# A seat's way (sprint 7: a room's, from the house's gate): off along it back to the anchor, on along it. Between
			# two seats of one place whose ways share a start (two rooms of a house), only back to where they part and on.
			var off_pts := _seat_way(seat_was, true)
			var on_pts := _seat_way(seat, false)
			var off_in := _seat_hidden(seat_was, true)
			var on_in := _seat_hidden(seat, false)
			var direct := false
			if here == to and seat_was.has("via") and seat.has("via"):
				var m := _shared(seat_was["via"], seat["via"])
				if m > 0:
					off_pts = off_pts.slice(0, off_pts.size() - (m - 1))
					off_in = off_in.slice(0, off_in.size() - (m - 1))
					on_pts = on_pts.slice(m)
					on_in = on_in.slice(m)
					direct = true
			var dur := 0.0
			if direct:
				dur = _path_time(off_pts + on_pts, w) * rate
			else:
				dur = _walk_time(routes, cache, name, w) * rate
				if not seat_was.is_empty():
					var back := off_pts.duplicate()
					back.append(off_at)
					dur += _path_time(back, w) * rate
				if not seat.is_empty():
					var into := PackedVector3Array([on_at])
					into.append_array(on_pts)
					dur += _path_time(into, w) * rate
			var leave := maxf(t, arrive - dur)
			if leave > arrive - dur + 0.01:
				slipped += 1
				slips.append([String(w["kind"]), to, snappedf(leave - (arrive - dur), 0.1)])
			_hold(leave)  # where it was, until it sets off
			t = leave
			var how := String(stop[3])
			if direct:
				for j in range(1, off_pts.size()):
					t = _walk_line(off_pts[j], t, w, rate, bool(off_in[j]))
				for j in on_pts.size():
					t = _walk_line(on_pts[j], t, w, rate, bool(on_in[j]))
			else:
				if not seat_was.is_empty():
					for j in range(1, off_pts.size()):
						t = _walk_line(off_pts[j], t, w, rate, bool(off_in[j]))
					t = _walk_line(off_at, t, w, rate)
				t = _walk(routes, cache, name, t, w, rate)
				if how == "wheel":  # in at the door, twice round the great wheel, out
					t = _walk(routes, cache, "wheel", t, w, rate)
				elif how == "mani":  # round the mani wall: the barkor's, or the one at the place (the western's first section)
					var loop := "mani_loop" if to == "mani" or not routes.has("mani_loop_" + to) else "mani_loop_" + to
					for n in int(stop[4]):
						t = _walk(routes, cache, loop, t, w, rate)
				for j in on_pts.size():
					t = _walk_line(on_pts[j], t, w, rate, bool(on_in[j]))
			var f = seat.get("face")  # none: it faces the way it came (since 9 Oct 2026 for a walk between two seats of one
			if f is Array:  # house too: it had faced the way it came in, its back to the room, from its seat on the bench)
				ky[ky.size() - 1] = atan2(float(f[0]), -float(f[1]))  # the town grid's (x, y) is Godot's (x, -z)
			ks[ks.size() - 1] = _state(how, seat)
			t = maxf(t, float(stop[2]))
			_hold(t)
			here = to
			seat_was = seat
		round_len[i] = 1440.0
		kt[kt.size() - 1] = 1440.0  # the night at home to midnight, where the day began
		cursor[i] = k0[i]
	k0[count] = kt.size()
	running = true
	if slipped > 0:
		print("TownSim: %d arrivals later than their schedule" % slipped)
	day_minute = fposmod(WorldClock.minute, 1440.0)
	for i in count:
		_eval(i)


## Whether walker i is seated, on a ledge or cross-legged (it turns its head to someone, not its body).
func seated(i: int) -> bool:
	return state[i] == 3 or state[i] == 6


## A stop's state: indoors, sitting on its seat's ledge, crouched, talking, or standing (at the wheel and the wall too).
static func _state(how: String, seat: Dictionary) -> int:
	if how == "inside":
		return 2
	var pose := String(seat.get("pose", ""))
	if pose == "cross":
		return 6
	if pose == "chair":
		return 3
	if pose == "crouch" or how == "crouch":
		return 5
	return 4 if how == "talk" else (0 if how == "walk" else 1)


static func _anchor(anchors: Dictionary, place: String) -> Vector3:
	var a: Array = anchors.get(place, [0.0, 0.0, 2660.0])
	return Town.to_godot(float(a[0]), float(a[1]), float(a[2]))


static func _seat_at(seat: Dictionary) -> Vector3:
	var a: Array = seat["at"]
	return Town.to_godot(float(a[0]), float(a[1]), float(a[2]))


## A seat's way, in Godot: on (from the place's anchor) its `via` then the seat; off, the seat then its via back to where
## it began. Empty for no seat; the seat alone when it has no via (walked to straight).
static func _seat_way(seat: Dictionary, off: bool) -> PackedVector3Array:
	var pts := PackedVector3Array()
	if seat.is_empty():
		return pts
	for q in seat.get("via", []):
		pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
	pts.append(_seat_at(seat))
	if off:
		pts.reverse()
	return pts


## Which of a seat's way's points are reached out of sight (a via point with a fourth element, "in": up a house's stair
## from its door to its roof's hatch), in the same order as _seat_way's.
static func _seat_hidden(seat: Dictionary, off: bool) -> Array:
	var h := []
	if seat.is_empty():
		return h
	for q in seat.get("via", []):
		h.append((q as Array).size() > 3 and String(q[3]) == "in")
	h.append(false)
	if off:  # walked back, a stretch is hidden where it was on the way in: its far end's flag moves to its near end
		var back := []
		for k in range(h.size() - 1, -1, -1):
			back.append(h[k + 1] if k + 1 < h.size() else false)
		return back
	return h


## How many points two ways share from their start.
static func _shared(a: Array, b: Array) -> int:
	var m := 0
	while m < a.size() and m < b.size() and a[m] == b[m]:
		m += 1
	return m


## A polyline's time in real seconds, stretch by stretch as TownSim walks it.
static func _path_time(pts: PackedVector3Array, w: Dictionary) -> float:
	var t := 0.0
	for k in pts.size() - 1:
		t += _stretch(pts[k + 1] - pts[k], 0, 0, w)
	return t


## A route's time in real seconds at the walker's pace (its steps' on flights).
func _walk_time(routes: Dictionary, cache: Dictionary, name: String, w: Dictionary) -> float:
	if not routes.has(name):
		return 0.0
	var pts := _route_points(routes, cache, name)
	var r: Dictionary = routes[name]
	var kinds_: Array = r["k"]
	var steps: Array = r["n"]
	var t := 0.0
	for k in pts.size() - 1:
		t += _stretch(pts[k + 1] - pts[k], int(kinds_[k]), int(steps[k]), w)
	return t


func _route_points(routes: Dictionary, cache: Dictionary, name: String) -> PackedVector3Array:
	if not cache.has(name):
		var p: Array = (routes[name] as Dictionary)["p"]
		var pts := PackedVector3Array()
		for k in range(0, p.size(), 3):
			pts.append(Town.to_godot(float(p[k]), float(p[k + 1]), float(p[k + 2])))
		cache[name] = pts
	return cache[name]


## One stretch's time in real seconds: on a flight its steps', on the ground Tobler's function of its slope; a stretch
## steeper than 45 degrees (a door on its pad over the ground before it) as steps of 0.2 m.
static func _stretch(d: Vector3, kind_: int, steps: int, w: Dictionary) -> float:
	if kind_ == 1:
		return steps * (float(w["up"]) if d.y > 0.0 else float(w["down"]))
	var flat := Vector2(d.x, d.z).length()
	if absf(d.y) > flat and absf(d.y) > 0.3:  # steeper than 45 degrees: a door's few steps up onto its pad, taken as steps
		return absf(d.y) / 0.2 * (float(w["up"]) if d.y > 0.0 else float(w["down"]))  # (Tobler's function gave 0.8 m 24 minutes)
	var s := d.y / maxf(flat, 0.01)
	return flat / (float(w["pace"]) * exp(-3.5 * (absf(s + 0.05) - 0.05)))


## Where the walker is now it stays, until game minute t.
func _hold(t: float) -> void:
	if kt[kt.size() - 1] < t:
		kt.append(t)
		kp.append(kp[kp.size() - 1])
		ks.append(ks[ks.size() - 1])
		ky.append(ky[ky.size() - 1])


## Walk straight from where the walker is to p (onto a seat from the place's anchor, or off it), from game minute t;
## `hidden`, out of sight all the way (indoors: up a house's stair to its roof).
func _walk_line(p: Vector3, t: float, w: Dictionary, rate: float, hidden := false) -> float:
	var d := p - kp[kp.size() - 1]
	if d.length() < 0.02:
		return t
	ks[ks.size() - 1] = 2 if hidden else 0
	if Vector2(d.x, d.z).length() > 0.01:
		ky[ky.size() - 1] = atan2(d.x, d.z)
	t += _stretch(d, 0, 0, w) * rate
	kt.append(t)
	kp.append(p)
	ks.append(1)
	ky.append(ky[ky.size() - 1])
	return t


## Walk a route from game minute t: a knot at each of its points, each stretch timed by the walker's pace (on the
## ground by Tobler's function of its slope, on a flight by its steps), in game minutes at `rate` (a minute a real
## second times it). Returns when it arrives.
func _walk(routes: Dictionary, cache: Dictionary, name: String, t: float, w: Dictionary, rate: float) -> float:
	if not routes.has(name):
		if not name.begins_with(name.get_slice(">", 1) + ">"):  # from a place to itself there is no route and no need of one
			push_warning("TownSim: no route %s" % name)
		return t
	var pts := _route_points(routes, cache, name)
	var r: Dictionary = routes[name]
	var kinds_: Array = r["k"]
	var steps: Array = r["n"]
	ks[ks.size() - 1] = 0  # it sets off from the last knot
	var face := ky[ky.size() - 1]
	for k in pts.size() - 1:
		var d := pts[k + 1] - pts[k]
		if Vector2(d.x, d.z).length() > 0.01:
			face = atan2(d.x, d.z)
		if k > 0:
			kt.append(t)
			kp.append(pts[k])
			ks.append(0)
			ky.append(face)
		else:
			ky[ky.size() - 1] = face
		t += _stretch(d, int(kinds_[k]), int(steps[k]), w) * rate
	# arrived, it faces the way it came over the last metre and a half (the route's last stretch can be the few
	# centimetres from the ground's lattice to the anchor, pointing anywhere)
	var end := pts[pts.size() - 1]
	for k in range(pts.size() - 2, -1, -1):
		var d := end - pts[k]
		if Vector2(d.x, d.z).length() >= 1.5 or k == 0:
			if Vector2(d.x, d.z).length() > 0.01:
				face = atan2(d.x, d.z)
			break
	kt.append(t)
	kp.append(end)
	ks.append(1)  # standing, until the next knot says otherwise
	ky.append(face)
	return t


## Walker i at the day's minute: its knot (moving on from the last one looked up), its place between that knot and the
## next, which way it faces and how fast it goes (in metres a real second at the clock's 6:1).
func _eval(i: int) -> void:
	var a := k0[i]
	var b := k0[i + 1] - 1  # the last knot: midnight, at home
	var tau := day_minute
	var c := cursor[i]
	if tau < kt[c]:
		c = a
	while c < b - 1 and kt[c + 1] <= tau:
		c += 1
	cursor[i] = c
	var t0 := kt[c]
	var t1 := kt[c + 1]
	var p0 := kp[c]
	var p1 := kp[c + 1]
	var f := 0.0 if t1 <= t0 else clampf((tau - t0) / (t1 - t0), 0.0, 1.0)
	pos[i] = p0.lerp(p1, f)
	state[i] = ks[c]
	yaw[i] = ky[c]
	var d := p1 - p0
	if ks[c] == 0 and t1 > t0:
		var secs := (t1 - t0) / WorldClock.RATE_PLAY  # its real seconds at the clock's 6:1
		vel[i] = d / secs
		cur_speed[i] = Vector2(d.x, d.z).length() / secs
	else:
		vel[i] = Vector3.ZERO
		cur_speed[i] = 0.0


## The game minutes walker i came to where it is now and will leave it, in the state it is in (a sit's start and end,
## for sitting down and getting up): the run of its knots in that state at that place.
func rest_span(i: int) -> Vector2:
	var c := cursor[i]
	var s := c
	while s > k0[i] and ks[s - 1] == ks[c] and kp[s - 1] == kp[c]:
		s -= 1
	var e := c + 1
	while e < k0[i + 1] - 1 and ks[e] == ks[c] and kp[e] == kp[c]:
		e += 1
	return Vector2(kt[s], kt[e])


## The stop of walker i's day it is at or on its way to at the day's minute: [place, arrive, leave, how, loops, seat].
func stop_now(i: int) -> Array:
	var day: Array = days[i]
	for s in range(1, day.size()):
		if day_minute < float(day[s][2]):
			return day[s]
	return day[day.size() - 1]


## The minute of the day, from m0 to m1 every `step_m` minutes, when most walkers are out of doors within `radius` of
## `center` (the stills'): looked up, not simulated. The walkers are left where they were.
func busiest_time(center: Vector3, radius: float, m0: float, m1: float, step_m := 0.5) -> float:
	var best := m0
	var most := -1
	var keep := day_minute
	var m := m0
	while m <= m1:
		day_minute = fposmod(m, 1440.0)
		var n := 0
		for i in count:
			_eval(i)
			if state[i] != 2 and Vector2(pos[i].x - center.x, pos[i].z - center.z).length() < radius:
				n += 1
		if n > most:
			most = n
			best = m
		m += step_m
	day_minute = keep
	for i in count:
		_eval(i)
	return best


## How many walkers are out of doors at the day's minute m (the stills' and the tests').
func out_at(m: float) -> int:
	var keep := day_minute
	day_minute = fposmod(m, 1440.0)
	var n := 0
	for i in count:
		_eval(i)
		n += 1 if state[i] != 2 else 0
	day_minute = keep
	for i in count:
		_eval(i)
	return n


## One frame: move everyone, think for those whose band is due, and keep near agents apart.
func step(dt: float, focus: Vector3) -> void:
	if not running:
		return
	if walkers_on:  # the day at the clock's minute (dt does not move them: the clock does)
		var tw := Time.get_ticks_usec()
		day_minute = fposmod(WorldClock.minute, 1440.0)
		for i in count:
			_eval(i)
		last_us = Time.get_ticks_usec() - tw
		return
	var t0 := Time.get_ticks_usec()
	time += dt
	thinks = 0
	_near.clear()
	for i in count:
		var s := along[i] + speed[i] * dt
		if s >= edge_len[i]:
			_turn(i, s - edge_len[i])
		else:
			along[i] = s
		if time >= next_think[i]:
			var dist := pos[i].distance_to(focus)
			band[i] = 0 if dist < NEAR else (1 if dist < MIDDLE else 2)
			next_think[i] = time + (0.0 if band[i] == 0 else (MIDDLE_EVERY if band[i] == 1 else FAR_EVERY))
			thinks += 1
		if band[i] == 0:
			_near.append(i)
		_place(i)
	_keep_apart(dt)
	last_us = Time.get_ticks_usec() - t0


## At a crossing: on to a neighbour other than the way it came, unless the street ends.
func _turn(i: int, carry: float) -> void:
	var here := to_node[i]
	var options := adj[here]
	var nxt := options[_rng.randi_range(0, options.size() - 1)]
	if nxt == from_node[i] and options.size() > 1:
		nxt = options[(options.find(nxt) + 1) % options.size()]
	from_node[i] = here
	to_node[i] = nxt
	edge_len[i] = nodes[here].distance_to(nodes[nxt])
	along[i] = minf(carry, edge_len[i])


## Near agents step sideways from anyone within a shoulder's width (a first cut of avoidance, O(k²) over k ≤ 40).
func _keep_apart(dt: float) -> void:
	var k := _near.size()
	for x in k:
		var i := _near[x]
		for y in range(x + 1, k):
			var j := _near[y]
			var d := pos[i] - pos[j]
			d.y = 0.0
			var l := d.length()
			if l < SHOULDER and l > 0.001:
				var push := (SHOULDER - l) * 0.5 * minf(dt * 4.0, 1.0)
				side[i] = clampf(side[i] + push * signf(side[i] - side[j] + 0.001), -2.0, 2.0)
				side[j] = clampf(side[j] - push * signf(side[i] - side[j] + 0.001), -2.0, 2.0)
