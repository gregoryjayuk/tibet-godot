extends Node3D
## Who is on the 1,080 steps (M3 sprint 1, step 5; plan chapter 02, R-04: "pilgrims, monks, the Double Ninth party";
## chapter 12's M3, acceptance 1: "climb the 1,080 steps with pilgrims counting on their rosaries"), added by
## world/town.gd with the people:
## - the day's people (PEOPLE), each up and down the way from Pema Ö's forecourt over the Conch Bridge to the South
##   Gate's forecourt (data/dungrong.json `walk`) from their minutes: pilgrims climbing and standing at the end of each
##   round of the rosary, 108 steps (21.06 m of rise), for PAUSE seconds before they climb on, then down again after the
##   monastery; monks down in the morning to read in the town's houses (the 8th, chapter 04) and back up in the
##   afternoon; novices on errands, quicker. Each at a climber's pace on the flights and a walker's on the landings and
##   the bridge (PACE), the legs in step with it;
## - on the Double Ninth (the calendar's double_ninth: 28 October) Hejie's party: a dozen shopkeepers up from the steps'
##   foot from 13:30 to the Lhabab Chorten's platform at landing 6 with their wine (the kit's double_ninth_party), eight
##   sitting cross-legged in a ring on their rugs, one pouring, one talking, two at the terrace's edge over the valley
##   (V-04), and down again from 16:00 (chapter 02, 8.3);
## - a pilgrim's rosary heard from the nearest climber within HEARD of the camera, a bead at each step (SND-117, a
##   synthesised stand-in; the counting under the breath waits for recordings: no synthetic murmur, Greg, 27 Sep 2026).
## Everyone's place is worked out from the clock's minute, so a still is the same each time; drawn only while the camera
## is within SEEN of the way's middle. `timeline`, `s_at`, `time_at`, `rounds` are pure, for the tests.

const Town := preload("res://world/town.gd")
const PERSON := preload("res://characters/person.gdshader")
const STEPS := "res://data/dungrong.json"
const PARTY_KIT := "res://assets/generated/kit/types/double_ninth_party_v1.glb"
const CLIPS := "res://assets/generated/people/named_clips.json"
const SEEN := 700.0  ## metres from the way's middle within which they are drawn
const PER_MIN := 10.0  ## real seconds a game minute at the play rate (autoload/world_clock.gd RATE_PLAY, 0.1 a second)
const STEEP := 0.25  ## a segment of the way rising more than this in a metre is a flight (a climber's pace), else level
const STEP_ALONG := 0.345  ## metres along a flight's slope a step (a tread of 28.5 cm, a riser of 19.5)
const ROUND := 108.0 * 0.195  ## metres of rise to a round of the rosary
const PAUSE := 10.0  ## real seconds a pilgrim stands at the end of a round
## m/s along the way: up a flight, down one, on the level
const PACE := {"pilgrim": [0.42, 0.6, 0.85], "elder": [0.3, 0.42, 0.65], "monk": [0.46, 0.66, 0.95], "novice": [0.6, 0.8, 1.1],
		"party": [0.4, 0.55, 0.8]}
## the day's people: [body, kind, the way of their first trip, its minute, the minute of the way back (-1: none)]
const PEOPLE := [["elder_woman", "elder", "up", 370.0, 800.0], ["tsomo_nomad", "pilgrim", "up", 395.0, 640.0],
		["villager_man", "pilgrim", "up", 430.0, 730.0], ["nomad_woman", "pilgrim", "up", 460.0, 760.0],
		["elder_man", "elder", "up", 490.0, 930.0], ["villager_woman", "pilgrim", "up", 505.0, 880.0],
		["house_grandmother", "elder", "up", 545.0, 960.0], ["drover", "pilgrim", "up", 560.0, 900.0],
		["townswoman", "pilgrim", "up", 610.0, 990.0], ["townsman", "pilgrim", "up", 665.0, 1010.0],
		["drover_b", "pilgrim", "up", 820.0, -1.0], ["monk", "monk", "down", 420.0, 800.0], ["pema_monk", "monk", "down", 445.0, 850.0],
		["pema_monk_b", "monk", "down", 520.0, 935.0], ["novice", "novice", "down", 475.0, 700.0], ["novice_b", "novice", "down", 575.0, 905.0]]
const WOMEN := ["elder_woman", "tsomo_nomad", "nomad_woman", "villager_woman", "house_grandmother", "townswoman"]
const COUNTING := ["pilgrim", "elder"]
const ROSARY := "SND-117"
const HEARD := 12.0  ## metres
const ROSARY_EVERY := 3.6  ## real seconds: each one-shot is a run of beads this long
## the Double Ninth party: [body, what they do at landing 6: "sit" in the ring, "pour", "talk", "view" from the terrace]
const PARTY := [["han_man", "sit"], ["hejie_trader", "sit"], ["pieman", "sit"], ["han_man", "sit"], ["hejie_trader", "pour"],
		["pieman", "sit"], ["han_man", "sit"], ["hejie_trader", "sit"], ["pieman", "talk"], ["han_man", "sit"],
		["hejie_trader", "view"], ["pieman", "view"]]
const PARTY_UP := 810.0  ## 13:30 they set out up the steps' foot, a man every PARTY_GAP minutes
const PARTY_DOWN := 960.0  ## 16:00 they get up to go
const PARTY_GAP := 0.4
const RING := 1.3  ## metres from the ring's middle to a sitter's hips (the kit's rugs reach 1.6 m)
const RING_AT := Vector2(2.4, -1.6)  ## the ring's middle on landing 6's platform: metres along the way in, and to its left
const HIPS := 0.4  ## the cross-legged sit's hips lie this far behind the clip's root (people2/body.py)

var way_up: PackedVector3Array  ## from Pema Ö's forecourt over the bridge up to the South Gate's forecourt (Godot)
var cum_up: PackedFloat32Array
var way_down: PackedVector3Array
var cum_down: PackedFloat32Array
var pauses := PackedFloat32Array()  ## the ends of the rosary's rounds along way_up
var people: Array = []  ## {key, kind, trips: [[dir, start minute]], root, ap, clip}
var party: Array = []  ## {key, role, k, place: [Vector3 root, yaw, clip], scale, root, ap, clip}
var party_things: Node3D
var clicks := 0  ## rosaries heard, for the tests
var _tl := {}  ## "<kind>:<up|down>": timeline
var _len := 0.0
var _s6 := 0.0  ## landing 6's middle along way_up
var _c6 := Vector3.ZERO
var _mid := Vector3.ZERO
var _speeds := {}  ## body: its walk clip's ground speed, m/s
var _mat: ShaderMaterial
var _built := false
var _party_day := false
var _day := -1
var _click_t := 0.0


static func _cum(p: PackedVector3Array) -> PackedFloat32Array:
	var c := PackedFloat32Array([0.0])
	for i in range(1, p.size()):
		c.append(c[i - 1] + p[i].distance_to(p[i - 1]))
	return c


static func _at(p: PackedVector3Array, c: PackedFloat32Array, s: float) -> Vector3:
	s = clampf(s, 0.0, c[c.size() - 1])
	for i in range(1, p.size()):
		if s <= c[i]:
			var f := (s - c[i - 1]) / maxf(c[i] - c[i - 1], 0.0001)
			return p[i - 1].lerp(p[i], f)
	return p[p.size() - 1]


## A walk along a way: [seconds at each breakpoint, metres along the way there]: `climb` m/s on its flights (a segment
## rising or falling more than STEEP in a metre), `flat` elsewhere, standing `pause` seconds at each of `stops` (metres
## along it, in order).
static func timeline(p: PackedVector3Array, c: PackedFloat32Array, climb: float, flat: float, stops: PackedFloat32Array, pause: float) -> Array:
	var ts := PackedFloat32Array([0.0])
	var ss := PackedFloat32Array([0.0])
	var k := 0
	for i in range(1, p.size()):
		var seg := c[i] - c[i - 1]
		if seg <= 0.0001:
			continue
		var v := climb if absf(p[i].y - p[i - 1].y) / seg > STEEP else flat
		var s0 := c[i - 1]
		while k < stops.size() and stops[k] <= c[i] + 0.0001:
			if stops[k] >= s0:
				ts.append(ts[ts.size() - 1] + (stops[k] - s0) / v)
				ss.append(stops[k])
				ts.append(ts[ts.size() - 1] + pause)
				ss.append(stops[k])
				s0 = stops[k]
			k += 1
		ts.append(ts[ts.size() - 1] + (c[i] - s0) / v)
		ss.append(c[i])
	return [ts, ss]


## Where a timeline is `t` seconds in: Vector2(metres along the way, its pace there in m/s: 0 standing).
static func s_at(tl: Array, t: float) -> Vector2:
	var ts: PackedFloat32Array = tl[0]
	var ss: PackedFloat32Array = tl[1]
	var hi := ts.size() - 1
	if t <= 0.0:
		return Vector2(0.0, 0.0)
	if t >= ts[hi]:
		return Vector2(ss[hi], 0.0)
	var lo := 0
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if ts[mid] <= t:
			lo = mid
		else:
			hi = mid
	var dt := maxf(ts[hi] - ts[lo], 0.0001)
	return Vector2(lerpf(ss[lo], ss[hi], (t - ts[lo]) / dt), (ss[hi] - ss[lo]) / dt)


## The seconds into a timeline when it first reaches `s` metres along its way.
static func time_at(tl: Array, s: float) -> float:
	var ts: PackedFloat32Array = tl[0]
	var ss: PackedFloat32Array = tl[1]
	for i in range(1, ss.size()):
		if ss[i] >= s - 0.0001:
			if ss[i] - ss[i - 1] < 0.0001:
				return ts[i - 1]
			return lerpf(ts[i - 1], ts[i], (s - ss[i - 1]) / (ss[i] - ss[i - 1]))
	return ts[ts.size() - 1]


## The ends of the rosary's rounds along a way climbing from `z0`: the metres along it where its level first reaches
## z0 + k ROUND, k = 1, 2, ... (the tenth round ends at the top: no standing in the gate).
static func rounds(p: PackedVector3Array, c: PackedFloat32Array, z0: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var k := 1
	for i in range(1, p.size()):
		while p[i].y >= z0 + k * ROUND - 0.001 and p[i - 1].y < z0 + k * ROUND - 0.001:
			var f := (z0 + k * ROUND - p[i - 1].y) / maxf(p[i].y - p[i - 1].y, 0.0001)
			out.append(c[i - 1] + (c[i] - c[i - 1]) * f)
			k += 1
	if out.size() > 0 and absf(out[out.size() - 1] - c[c.size() - 1]) < 2.0:
		out.remove_at(out.size() - 1)
	return out


## Gathers the way from the data, lays out the party's places. The count of trips on the steps in a day.
func build(_root: Node3D) -> int:
	if not FileAccess.file_exists(STEPS):
		return 0
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STEPS))
	way_up = PackedVector3Array()
	for q in d["walk"]:
		var g := Town.to_godot(float(q[0]), float(q[1]), float(q[2]))
		if way_up.is_empty() or way_up[way_up.size() - 1].distance_to(g) > 0.05:
			way_up.append(g)
	if way_up.size() < 2:
		return 0
	cum_up = _cum(way_up)
	way_down = way_up.duplicate()
	way_down.reverse()
	cum_down = _cum(way_down)
	_len = cum_up[cum_up.size() - 1]
	pauses = rounds(way_up, cum_up, Town.to_godot(0.0, 0.0, float(d["foot"]["z"])).y)
	for kind in PACE:
		var pc: Array = PACE[kind]
		_tl[kind + ":up"] = timeline(way_up, cum_up, float(pc[0]), float(pc[2]), pauses if COUNTING.has(kind) else PackedFloat32Array(), PAUSE)
		_tl[kind + ":down"] = timeline(way_down, cum_down, float(pc[1]), float(pc[2]), PackedFloat32Array(), 0.0)
	_mid = _at(way_up, cum_up, _len / 2.0)
	people = []
	for t in PEOPLE:
		var back := "down" if String(t[2]) == "up" else "up"
		var trips: Array = [[String(t[2]), float(t[3])]]
		if float(t[4]) >= 0.0:
			trips.append([back, float(t[4])])
		people.append({"key": String(t[0]), "kind": String(t[1]), "trips": trips})
	_party_places(d)
	if FileAccess.file_exists(CLIPS):
		var cl: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(CLIPS)) as Dictionary).get("bodies", {})
		for key in cl:
			var w: Dictionary = (cl[key] as Dictionary).get("Walk", {})
			if float(w.get("speed", 0.0)) > 0.1:
				_speeds[key] = float(w["speed"])
	add_to_group("steps_people")
	var n := 0
	for p in people:
		n += (p["trips"] as Array).size()
	return n


## The party's places at landing 6: the ring on the platform's free side (RING_AT, clear of the way across it), the
## pourer by the jars, the talker standing at the ring's edge towards the way, the two at the terrace's outer edge
## beyond the chorten, looking out.
func _party_places(d: Dictionary) -> void:
	party = []
	var six := {}
	for lg in d["landings"]:
		if int(lg["number"]) == 6:
			six = lg
	if six.is_empty() or not (d.get("places", {}) as Dictionary).has("RNG-12"):
		return
	var c := Vector2(float(six["at"][0]), float(six["at"][1]))
	var z := float(six["z"])
	var b := deg_to_rad(float(six["bearing"]))
	var fwd := Vector2(sin(b), cos(b))  # the way in across the platform
	var left := Vector2(-fwd.y, fwd.x)
	_c6 = Town.to_godot(c.x, c.y, z)
	_s6 = _nearest_s(_c6)
	var r := c + fwd * RING_AT.x + left * RING_AT.y
	var g := func(q: Vector2) -> Vector3: return Town.to_godot(q.x, q.y, z)
	var rc: Vector3 = g.call(r)
	var t12: Array = d["places"]["RNG-12"]["at"]
	var tc := Vector2(float(t12[0]), float(t12[1]))
	var out := (tc - c).normalized()  # from the platform to the chorten's terrace, and out over the valley
	var side := Vector2(-out.y, out.x)
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var jars := (-left * 0.22 - fwd * 0.07).normalized()  # (the kit's jars: its +x is the platform's left, its -y the way in)
	var pour_j := 0  # nine places round the ring: the pourer's by the jars, the eight sitters' in the others
	for j in 9:
		if Vector2.from_angle(TAU * (j + 0.5) / 9.0).dot(jars) > Vector2.from_angle(TAU * (pour_j + 0.5) / 9.0).dot(jars):
			pour_j = j
	var sitters := 0
	var views := 0
	for k in PARTY.size():
		var role := String(PARTY[k][1])
		var at := Vector3.ZERO
		var face := Vector3.ZERO  # a point they face
		var clip := "Idle_A"
		match role:
			"sit":
				var j := sitters + (1 if sitters >= pour_j else 0)
				sitters += 1
				var a := TAU * (j + 0.5) / 9.0 + rng.randf_range(-0.1, 0.1)
				var hips: Vector3 = g.call(r + Vector2.from_angle(a) * (RING + rng.randf_range(-0.08, 0.06)))
				at = hips + (rc - hips).normalized() * HIPS
				face = rc
				clip = "Sitting_Cross"
			"pour":
				at = g.call(r + Vector2.from_angle(TAU * (pour_j + 0.5) / 9.0) * 0.95)
				face = rc
				clip = "Crouch_Idle"
			"talk":  # (beside the ring, not between it and the way)
				at = g.call(r + (c - r).normalized().orthogonal() * 2.0)
				face = rc
				clip = "Idle_Talking"
			"view":
				var lat := 2.5 if views == 0 else -2.5
				views += 1
				at = g.call(tc + out * 3.45 + side * lat)
				face = g.call(tc + out * 20.0 + side * lat)
				clip = "Idle_FoldArms" if views == 1 else "Idle_A"
		var dv := face - at
		party.append({"key": String(PARTY[k][0]), "role": role, "k": k, "place": [at, atan2(dv.x, dv.z), clip], "scale": rng.randf_range(0.96, 1.04)})
	if ResourceLoader.exists(PARTY_KIT):  # their things, in the ring's middle while they are there
		party_things = (load(PARTY_KIT) as PackedScene).instantiate()
		party_things.name = "DoubleNinthThings"
		party_things.position = rc
		party_things.rotation.y = -deg_to_rad(float(six["bearing"]) - 180.0)
		party_things.visible = false
		add_child(party_things)


func _nearest_s(q: Vector3) -> float:
	var best := INF
	var at := 0.0
	for i in range(1, way_up.size()):
		var a := way_up[i - 1]
		var ab := way_up[i] - a
		var f := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var dd := (a + ab * f).distance_to(q)
		if dd < best:
			best = dd
			at = cum_up[i - 1] + (cum_up[i] - cum_up[i - 1]) * f
	return at


## Whether the Double Ninth party climbs on the day of game minute `minute` (the calendar's double_ninth).
static func party_day(minute: float) -> bool:
	return Calendar.flags(minute).has("double_ninth")


## Where `p` is at minute `m` of the day: [shown, position, yaw, clip, the clip's speed, counting a bead a step].
func where(p: Dictionary, m: float) -> Array:
	for tr in p["trips"]:
		var dir := String(tr[0])
		var tl: Array = _tl[String(p["kind"]) + ":" + dir]
		var ts: PackedFloat32Array = tl[0]
		var e := (m - float(tr[1])) * PER_MIN
		if e < 0.0 or e > ts[ts.size() - 1]:
			continue
		var sv := s_at(tl, e)
		var r := _on_way(dir, sv, String(p["key"]))
		r.append(dir == "up" and COUNTING.has(String(p["kind"])) and sv.y > 0.0)
		return r
	return [false, Vector3.ZERO, 0.0, "", 1.0, false]


## A walker at `sv` (metres, pace) on the way up or down: [shown, position, yaw, clip, the clip's speed].
func _on_way(dir: String, sv: Vector2, key: String) -> Array:
	var up := dir == "up"
	var w: PackedVector3Array = way_up if up else way_down
	var c: PackedFloat32Array = cum_up if up else cum_down
	var q := _at(w, c, sv.x)
	var ahead := _at(w, c, sv.x + 0.6)
	var flat := Vector3(ahead.x - q.x, 0.0, ahead.z - q.z)
	var yaw := atan2(flat.x, flat.z) if flat.length() > 0.001 else 0.0
	if sv.y <= 0.0:
		return [true, q, yaw, "Idle_A", 1.0]
	var steep := absf(ahead.y - q.y) / 0.6 > STEEP
	var speed := clampf(sv.y / STEP_ALONG / 1.2, 0.55, 1.4) if steep else clampf(sv.y / float(_speeds.get(key, 0.74)), 0.6, 1.3)
	return [true, q, yaw, "Walk_Female" if WOMEN.has(key) else "Walk", speed]


## Where one of the party is at minute `m` of the Double Ninth: [shown, position, yaw, clip, the clip's speed].
func party_where(pp: Dictionary, m: float) -> Array:
	var none := [false, Vector3.ZERO, 0.0, "", 1.0]
	var k := int(pp["k"])
	var e := (m - (PARTY_UP + k * PARTY_GAP)) * PER_MIN  # seconds since he set out
	if e < 0.0 or _s6 <= 0.0:
		return none
	var up: Array = _tl["party:up"]
	var at_c := time_at(up, _s6)
	var place: Array = pp["place"]
	var spot: Vector3 = place[0]
	var walk_in := Vector2(spot.x - _c6.x, spot.z - _c6.z).length() / float(PACE["party"][2])
	var leave := (PARTY_DOWN + k * PARTY_GAP * 0.6 - (PARTY_UP + k * PARTY_GAP)) * PER_MIN
	var level := Vector2(0.0, float(PACE["party"][2]))
	if e < at_c:
		return _on_way("up", s_at(up, e), String(pp["key"]))
	if e < at_c + walk_in:  # from the way's middle on the platform to his place
		var dv := spot - _c6
		var r := _on_way("up", level, String(pp["key"]))
		return [true, _c6.lerp(spot, (e - at_c) / maxf(walk_in, 0.001)), atan2(dv.x, dv.z), r[3], r[4]]
	if e < leave:
		return [true, spot, float(place[1]), String(place[2]), 1.0]
	if e < leave + walk_in:
		var dv := _c6 - spot
		var r := _on_way("up", level, String(pp["key"]))
		return [true, spot.lerp(_c6, (e - leave) / maxf(walk_in, 0.001)), atan2(dv.x, dv.z), r[3], r[4]]
	var down: Array = _tl["party:down"]
	var sv := s_at(down, time_at(down, _len - _s6) + e - leave - walk_in)
	if sv.x >= _len - 0.01:
		return none  # (down at the foot and away home)
	return _on_way("down", sv, String(pp["key"]))


func _bodies() -> void:
	_built = true
	_mat = ShaderMaterial.new()
	_mat.shader = PERSON
	var i := 0
	for p in people + party:
		i += 1
		var path := "res://assets/generated/people/%s.glb" % p["key"]
		if not ResourceLoader.exists(path):
			continue
		var root: Node3D = (load(path) as PackedScene).instantiate()
		root.name = "Steps_%s_%d" % [String(p["key"]), i]
		PersonLook.apply(root, _mat)
		var ap: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Walk_Female", "Idle_A", "Idle_FoldArms", "Idle_Talking", "Sitting_Cross", "Crouch_Idle"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		if p.has("scale"):
			root.scale = Vector3.ONE * float(p["scale"])
		var tint := 0.92 + 0.16 * fposmod(i * 0.618034, 1.0)  # a small tone shift each (as the town's crowd, characters/crowd.gd)
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			(mi as GeometryInstance3D).set_instance_shader_parameter("tint", tint)
		add_child(root)
		root.visible = false
		p["root"] = root
		p["ap"] = ap
		p["clip"] = ""


func _process(dt: float) -> void:
	if way_up.size() < 2:
		return
	var cam := get_viewport().get_camera_3d()
	var eye := cam.global_position if cam != null else _mid
	var on: bool = cam != null and Vector2(eye.x - _mid.x, eye.z - _mid.z).length() < SEEN
	if not on:
		for p in people + party:
			if p.has("root"):
				(p["root"] as Node3D).visible = false
		if party_things != null:
			party_things.visible = false
		return
	if not _built:
		_bodies()
	var day := int(floor(WorldClock.minute / 1440.0))
	if day != _day:
		_day = day
		_party_day = party_day(WorldClock.minute)
	var m := fposmod(WorldClock.minute, 1440.0)
	var frozen: bool = WorldClock.frozen
	var g: float = WorldClock.anim_time
	var nearest := INF
	var near_at := Vector3.ZERO
	var i := 0
	for p in people:
		var r: Array = where(p, m)
		if _show(p, r, frozen, g, i) and bool(r[5]):
			var dd: float = (r[1] as Vector3).distance_to(eye)
			if dd < nearest:
				nearest = dd
				near_at = r[1]
		i += 1
	var there := false
	for pp in party:
		var r: Array = party_where(pp, m) if _party_day else [false, Vector3.ZERO, 0.0, "", 1.0]
		_show(pp, r, frozen, g, i)
		i += 1
		there = there or (bool(r[0]) and String(r[3]) == String(pp["place"][2]))
	if party_things != null:
		party_things.visible = there
	if nearest < HEARD and not frozen:  # the nearest climber's rosary, a bead at each step
		_click_t += dt
		if _click_t >= ROSARY_EVERY:
			_click_t = 0.0
			clicks += 1
			if is_instance_valid(AudioDirector):
				AudioDirector.play(ROSARY, near_at + Vector3(0.0, 1.1, 0.0))


func _show(p: Dictionary, r: Array, frozen: bool, g: float, i: int) -> bool:
	if not p.has("root"):
		return false
	var root: Node3D = p["root"]
	root.visible = bool(r[0])
	if not bool(r[0]):
		return false
	root.global_position = r[1]
	root.rotation.y = float(r[2])
	_play(p, String(r[3]), float(r[4]), frozen, g, i)
	return true


func _play(p: Dictionary, clip: String, speed: float, frozen: bool, g: float, i: int) -> void:
	var ap: AnimationPlayer = p["ap"]
	if not ap.has_animation(clip):
		clip = "Walk" if clip.begins_with("Walk") and ap.has_animation("Walk") else "Idle_A"
	if String(p["clip"]) != clip:
		ap.play(clip, 0.0 if frozen or String(p["clip"]) == "" else 0.3)
		p["clip"] = clip
	if frozen:  # the stills: the pose from the animation clock
		ap.speed_scale = 0.0
		ap.seek(fposmod(g * speed + i * 0.37, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = speed
