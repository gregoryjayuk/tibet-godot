extends Node3D
## Who uses the Gorge Stair (M3 sprint 2, step 6; plan chapter 02, D07: "nobody sleeps here; 20-60 by day, all in
## transit: monks between Tödé homes and the monastery, pilgrims, the printers, water carriers"; chapter 08, V-17: "a monk
## resting on the bench turning the wheel; two novices racing down the stair"; and "The tulku goes home for the
## afternoon"), added by world/town.gd with the people. Their way runs from the garden lane's foot by H-SHL-095's yard up
## the lane to the Gorge Rim Lookout's terrace, out at its gap, down the west leg, over the raw bridge and up the east leg
## to the West Gate (data/gardens.json `lanes`, data/gorge_stair.json `walk`): Tödé's people come and go at the lane's
## foot until Tödé is built (sprint 4), the monastery's at the gate. Off it, the way down to the water at the bridge's
## west end (data/gorge_stair.json `water`) and the rest gallery's floor to its bench by the wheel.
## - each one's day a list of acts: a walk along one of the ways (WAYS) at their kind's pace (PACE: up a flight, down one,
##   on the level), to a few metres short of its end and to one side of its middle when others walk with them, or a stay
##   at a spot with a clip; their places worked out from the clock's minute, so a still is the same each time;
## - the three Tödé monks down to their families and up again; Tödé's two water carriers down to the channel's head, a
##   barrel filled, back up laden (chapter 05, A-47's hours); the old monk down to the gallery's bench at 13:20, turning
##   the wheel (a hand by it in the group "kora_walkers", world/kora_wheels.gd) till 16:05; two novices racing down from
##   the West Gate at 14:30 to the bridge, the younger catching the elder, a while at its rail over the water, and the
##   long climb back through the gate before it is barred at 17:30;
## - on the full moon (the Tibetan date's 15th; chapter 05's `tulku_visit`, first on 5 November) the tulku and his two
##   attendants down from the West Gate, over the raw bridge at 14:00 (chapter 08: 14:00-15:15), up to the terrace where
##   his mother has waited since 13:55; mother and son sit together there (his home in Tödé is 35 m along the rim, not
##   built until sprint 4), the attendants standing by; at 15:15 the three go back down, she watching them over the
##   bridge before she goes home, they through the West Gate before it is barred.
## Drawn only while the camera is within SEEN of the gorge. `timeline`, `where`, `tulku_day`, `minutes_to` are for the
## tests.

const Town := preload("res://world/town.gd")
const Steps := preload("res://world/steps_people.gd")  ## its polyline helpers (_cum, _at, s_at, time_at)
const PERSON := preload("res://characters/person.gdshader")
const GORGE := "res://data/gorge_stair.json"
const GARDENS := "res://data/gardens.json"
const CLIPS := "res://assets/generated/people/named_clips.json"
const SEEN := 700.0  ## metres from the bridge within which they are drawn
const PER_MIN := 10.0  ## real seconds a game minute at the play rate (autoload/world_clock.gd RATE_PLAY, 0.1 a second)
const STEEP := 0.25  ## a segment of a way rising or falling more than this in a metre is a flight
const STEP_ALONG := 0.345  ## metres along a flight's slope a step
## m/s along a way: up a flight, down one, on the level
const PACE := {"monk": [0.46, 0.66, 0.95], "elder": [0.32, 0.48, 0.7], "novice": [0.6, 0.8, 1.1], "race": [0.6, 1.5, 2.0],
		"race_b": [0.6, 1.62, 2.1], "carrier": [0.42, 0.6, 0.85], "laden": [0.28, 0.42, 0.7], "party": [0.42, 0.58, 0.8]}
const FILL := 1.2  ## game minutes a barrel takes to fill at the channel's head (chapter 05, AN-021's 6 s, and the wait)
const BARRED := 1050.0  ## 17:30: the disciplinarian bars the gates after the dusk horns (chapter 05, NPC-36)
const TULKU_BRIDGE := 840.0  ## 14:00 the tulku's party at the raw bridge (chapter 08: 14:00-15:15)
const MOTHER_AT := 835.0  ## 13:55 his mother on the terrace
const GREET := 4.0  ## game minutes they stand together on the terrace
const PARTING := 915.0  ## 15:15 they part on the terrace
const BENCH := [800.0, 965.0]  ## 13:20 the old monk down to the gallery's bench; 16:05 back up
const RACE := 870.0  ## 14:30 the novices race down from the West Gate
const AT_RAIL := 908.0  ## 15:08 they leave the bridge's rail for the climb back
const IN_FILE := [0.0, 0.4, 0.8]  ## game minutes after the tulku his two attendants set out
const SHORT := [0.0, 1.5, 3.0]  ## and the metres short of a stop each stands
const HIPS := 0.4  ## the cross-legged sit's hips lie this far behind the clip's root (people2/body.py)
const SEAT := Vector2(2.6, 0.75)  ## the old monk's place on the rest gallery's bench (../tibet-blender kit/dungrong.py rest_gallery: its x along it, y towards the rock)
const HAND := Vector3(3.05, 0.6, 0.9)  ## the hand on the wheel beside him (the kit's WHEEL at x 3.45, y 0.75)
const WOMEN := ["chodron_tode", "tode_water_woman", "tode_water_girl"]

var ways := {}  ## "<from>><to>": PackedVector3Array (Godot)
var cums := {}  ## and each one's metres along it
var marks := {}  ## the main way's places: metres from the lane's foot ("terrace", "bridge_w", "bridge_e", "gallery", "gate")
var people: Array = []  ## {key, kind, acts}: every day
var party: Array = []  ## the tulku, his attendants and his mother: on the full moon
var spots := {}  ## "fill", "seat", "watch", "meet": [Vector3, yaw]; "hand": Vector3
var hand: Node3D  ## in the group "kora_walkers" by the gallery's wheel while the old monk sits at it
var _tl := {}  ## "<way>:<kind>": timeline
var _speeds := {}  ## body: {clip: its ground speed, m/s}
var _mid := Vector3.ZERO
var _mat: ShaderMaterial
var _built := false
var _party_day := false
var _day := -1


static func _add(p: PackedVector3Array, q: Vector3) -> void:
	if p.is_empty() or p[p.size() - 1].distance_to(q) > 0.05:
		p.append(q)


static func _reversed(p: PackedVector3Array) -> PackedVector3Array:
	var r := p.duplicate()
	r.reverse()
	return r


## The part of a way from `s0` to `s1` metres along it, its ends where they fall.
static func _slice(p: PackedVector3Array, c: PackedFloat32Array, s0: float, s1: float) -> PackedVector3Array:
	var r := PackedVector3Array([Steps._at(p, c, s0)])
	for i in p.size():
		if c[i] > s0 + 0.01 and c[i] < s1 - 0.01:
			r.append(p[i])
	_add(r, Steps._at(p, c, s1))
	return r


## The metres along a way of its nearest point to `q`, flat.
static func _nearest(p: PackedVector3Array, c: PackedFloat32Array, q: Vector3) -> float:
	var best := INF
	var at := 0.0
	for i in range(1, p.size()):
		var a := Vector2(p[i - 1].x, p[i - 1].z)
		var ab := Vector2(p[i].x, p[i].z) - a
		var f := clampf((Vector2(q.x, q.z) - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var dd := (a + ab * f).distance_to(Vector2(q.x, q.z))
		if dd < best:
			best = dd
			at = c[i - 1] + (c[i] - c[i - 1]) * f
	return at


## A walk along a way: [seconds at each point, metres along the way there]: `up` m/s up its flights (a segment rising
## more than STEEP in a metre), `down` down them, `flat` elsewhere.
static func timeline(p: PackedVector3Array, c: PackedFloat32Array, up: float, down: float, flat: float) -> Array:
	var ts := PackedFloat32Array([0.0])
	var ss := PackedFloat32Array([0.0])
	for i in range(1, p.size()):
		var seg := c[i] - c[i - 1]
		if seg <= 0.0001:
			continue
		var dz := p[i].y - p[i - 1].y
		var v := flat
		if absf(dz) / seg > STEEP:
			v = up if dz > 0.0 else down
		ts.append(ts[ts.size() - 1] + seg / v)
		ss.append(c[i])
	return [ts, ss]


## Whether the tulku goes home on the day of game minute `minute`: the full moon, the Tibetan month's 15th.
static func tulku_day(minute: float) -> bool:
	return int(Calendar.tibetan_date(minute).get("day", 0)) == 15


## A town bearing as a Godot yaw (a figure facing it).
static func _yaw_of(b: float) -> float:
	return atan2(sin(deg_to_rad(b)), -cos(deg_to_rad(b)))


static func _yaw_to(a: Vector3, b: Vector3) -> float:
	return atan2(b.x - a.x, b.z - a.z)


## Lays out the ways from the data and everyone's day. The count of acts in an ordinary day.
func build(_root: Node3D) -> int:
	if not FileAccess.file_exists(GORGE) or not FileAccess.file_exists(GARDENS):
		return 0
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GORGE))
	var gj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GARDENS))
	var main := PackedVector3Array()
	for ln in gj["lanes"]:  # the garden lane's legs from its foot, along their beds
		if not String(ln["id"]).begins_with("GL-"):
			continue
		for q in ln["profile"]:
			var s := float(q[0])
			_add(main, Town.to_godot(float(ln["from"][0]) + float(ln["dir"][0]) * s, float(ln["from"][1]) + float(ln["dir"][1]) * s, float(q[1])))
	var k_terrace := main.size()
	for q in d["walk"]:
		_add(main, Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
	if main.size() < 2 or k_terrace >= main.size():
		return 0
	var cm := Steps._cum(main)
	var br: Dictionary = d["bridge"]
	marks = {"terrace": cm[k_terrace], "gate": cm[cm.size() - 1],
			"bridge_w": _nearest(main, cm, Town.to_godot(float(br["w_end"][0]), float(br["w_end"][1]), float(br["deck"]))),
			"bridge_e": _nearest(main, cm, Town.to_godot(float(br["e_end"][0]), float(br["e_end"][1]), float(br["deck"])))}
	_mid = Town.to_godot(float(br["mid"][0]), float(br["mid"][1]), float(br["deck"]))
	var L: float = marks["gate"]
	var T: float = marks["terrace"]
	var BW: float = marks["bridge_w"]
	ways = {}
	ways["foot>gate"] = main
	ways["gate>foot"] = _reversed(main)
	var lane := _slice(main, cm, 0.0, T)
	ways["terrace>foot"] = _reversed(lane)
	ways["gate>terrace"] = _reversed(_slice(main, cm, T, L))
	ways["terrace>gate"] = _slice(main, cm, T, L)
	var deck := (BW + float(marks["bridge_e"])) / 2.0
	ways["gate>deck"] = _reversed(_slice(main, cm, deck, L))
	ways["deck>gate"] = _slice(main, cm, deck, L)
	# his mother's place on the terrace: a metre in from the way's end there, towards its middle, looking out at the bridge
	var t_end := main[k_terrace]
	var lk := Town.to_godot(258.0, 245.0, t_end.y)  # (tools/town/gorge_stair.py LOOKOUT)
	var watch := t_end + Vector3(lk.x - t_end.x, 0.0, lk.z - t_end.z).normalized() * 1.0
	var bw := Steps._at(main, cm, BW)
	spots["watch"] = [watch, _yaw_to(watch, bw)]
	spots["meet"] = [t_end, _yaw_to(t_end, watch)]
	var view := _yaw_of(34.0)  # (the terrace's view, LOOKOUT_FACING: they sit looking out)
	var fwd := Vector3(sin(view), 0.0, cos(view))
	var left := Vector3(-fwd.z, 0.0, fwd.x) * -1.0  # (her left, looking out)
	spots["sit_son"] = [watch + left * 0.9 + fwd * HIPS, view]  # (side by side, he on her left)
	spots["sit_mother"] = [watch + fwd * HIPS, view]
	# the bridge's downstream rail at its middle, where the novices stand over the water
	var ax := Vector2(float(br["e_end"][0]) - float(br["w_end"][0]), float(br["e_end"][1]) - float(br["w_end"][1])).normalized()
	var dn := Vector2(ax.y, -ax.x)  # (the bridge's axis turned: down the river, tools/town/gorge_stair.py `dn`)
	var rail := Vector2(float(br["mid"][0]), float(br["mid"][1])) + dn * 0.65
	spots["rail"] = [Town.to_godot(rail.x, rail.y, float(br["deck"])), _yaw_of(rad_to_deg(atan2(dn.x, dn.y))), Town.to_godot(ax.x, ax.y, 0.0) - Town.to_godot(0.0, 0.0, 0.0)]
	var to_watch := lane.duplicate()
	_add(to_watch, watch)
	ways["foot>watch"] = to_watch
	ways["watch>foot"] = _reversed(to_watch)
	# the way down to the water: off the main way where it meets the bridge's west landing, down to the channel's head
	var wt: Dictionary = d.get("water", {})
	if wt.has("path"):
		var wp: Array = wt["path"]
		var t0 := Town.to_godot(float(wp[0][0]), float(wp[0][1]), float(wp[0][2]))
		var s0 := _nearest(main, cm, t0)
		var down := _slice(main, cm, 0.0, s0)
		for k in range(1, wp.size()):  # (from the landing's south end: the main way's last steps down onto it)
			_add(down, Town.to_godot(float(wp[k][0]), float(wp[k][1]), float(wp[k][2])))
		ways["foot>water"] = down
		ways["water>foot"] = _reversed(down)
		var fend := down[down.size() - 1]
		var fill := Town.to_godot(float(wt["fill"][0]), float(wt["fill"][1]), fend.y)
		spots["fill"] = [fend, _yaw_to(fend, fill)]
	# the rest gallery's bench by the wheel: in at the gallery's end on the switchback's landing, along its floor
	for th in d["things"]:
		if String(th["kind"]) != "rest_gallery":
			continue
		var f := deg_to_rad(float(th["facing"]))
		var kx := Vector2(-cos(f), sin(f))  # (the kit's +x, along the gallery from the landing's end)
		var ky := Vector2(-sin(f), -cos(f))  # (its +y, to the rock)
		var g := Vector2(float(th["at"][0]), float(th["at"][1]))
		var z := float(th["level"])
		var at := func(u: float, v: float, h: float = 0.0) -> Vector3:
			var q := g + kx * u + ky * v
			return Town.to_godot(q.x, q.y, z + h)
		var s_gal := _nearest(main, cm, at.call(-4.0, 0.0))
		marks["gallery"] = s_gal
		var to_bench := _reversed(_slice(main, cm, s_gal, L))
		for u in [-3.6, -1.0, 1.5, SEAT.x]:
			_add(to_bench, at.call(u, 0.0))
		_add(to_bench, at.call(SEAT.x, SEAT.y - 0.3))
		ways["gate>bench"] = to_bench
		ways["bench>gate"] = _reversed(to_bench)
		spots["seat"] = [at.call(SEAT.x, SEAT.y), _yaw_of(float(th["facing"]))]
		spots["hand"] = at.call(HAND.x, HAND.y, HAND.z)
	for w in ways:
		cums[w] = Steps._cum(ways[w])
	if FileAccess.file_exists(CLIPS):
		var cl: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(CLIPS)) as Dictionary).get("bodies", {})
		for key in cl:
			var sp := {}
			for clip in cl[key]:
				if float((cl[key][clip] as Dictionary).get("speed", 0.0)) > 0.1:
					sp[clip] = float(cl[key][clip]["speed"])
			_speeds[key] = sp
	_days()
	_party()
	hand = Node3D.new()
	hand.name = "WheelHand"
	add_child(hand)
	hand.position = Vector3(0.0, -10000.0, 0.0)
	hand.add_to_group("kora_walkers")
	add_to_group("gorge_people")
	var n := 0
	for p in people:
		n += (p["acts"] as Array).size()
	return n


func _timeline_of(way: String, kind: String) -> Array:
	var k := way + ":" + kind
	if not _tl.has(k):
		var pc: Array = PACE[kind]
		_tl[k] = timeline(ways[way], cums[way], float(pc[0]), float(pc[1]), float(pc[2]))
	return _tl[k]


## Game minutes a walk along `way` at `kind`'s pace takes to reach `s` metres along it.
func minutes_to(way: String, kind: String, s: float) -> float:
	return Steps.time_at(_timeline_of(way, kind), s) / PER_MIN


func way_length(way: String) -> float:
	var c: PackedFloat32Array = cums[way]
	return c[c.size() - 1]


## A walk along `way` from game minute `t0`, stopping `short` metres before its end, `side` metres right of its middle.
## Its end minute.
func _go(acts: Array, way: String, kind: String, t0: float, short := 0.0, side := 0.0) -> float:
	if not ways.has(way):
		return t0
	var end := maxf(0.0, way_length(way) - short)
	var t1 := t0 + minutes_to(way, kind, end)
	acts.append({"go": way, "kind": kind, "t0": t0, "t1": t1, "end": end, "side": side})
	return t1


func _stay(acts: Array, at: Vector3, yaw: float, clip: String, t0: float, t1: float, turning := false) -> void:
	acts.append({"stay": true, "at": at, "yaw": yaw, "clip": clip, "t0": t0, "t1": t1, "turning": turning})


## Standing where the last walk stopped, facing on along it.
func _hold(acts: Array, clip: String, t1: float) -> void:
	var a: Dictionary = acts[acts.size() - 1]
	var r := _on_way(String(a["go"]), float(a["end"]), 0.0, float(a["side"]), "", String(a["kind"]))
	_stay(acts, r[1], float(r[2]), clip, float(a["t1"]), t1)


## The ordinary day's people (and the old monk's hand on the wheel).
func _days() -> void:
	people = []
	var a: Array = []
	# the monks with Tödé families (chapter 02, R-07): down after the morning's assembly and classes, up again
	_go(a, "gate>foot", "monk", 425.0)  # 07:05
	_go(a, "foot>gate", "monk", 820.0)  # 13:40, up for the afternoon's debate
	people.append({"key": "tode_monk", "kind": "monk", "acts": a})
	a = []
	_go(a, "gate>foot", "elder", 620.0)  # 10:20
	_go(a, "foot>gate", "elder", 870.0)  # 14:30, through the gate before it is barred
	people.append({"key": "tode_monk_b", "kind": "elder", "acts": a})
	a = []
	_go(a, "foot>gate", "monk", 400.0)  # 06:40 up from home for the morning's classes
	_go(a, "gate>foot", "monk", 950.0)  # 15:50 home
	people.append({"key": "tode_monk_c", "kind": "monk", "acts": a})
	# Tödé's water carriers down to the Dungchu at the channel's head (chapter 05, A-47: 05:30-07:30, 15:30-16:30)
	if spots.has("fill"):
		for w in [["tode_water_woman", 390.0, 890.0], ["tode_water_girl", 440.0, 915.0]]:
			a = []
			for m in [float(w[1]), float(w[2])]:
				var t := _go(a, "foot>water", "carrier", m)
				_stay(a, spots["fill"][0], float(spots["fill"][1]), "Crouch_Idle", t, t + FILL)
				_go(a, "water>foot", "laden", t + FILL)
			people.append({"key": String(w[0]), "kind": "carrier", "acts": a})
	# the old monk resting on the gallery's bench and turning its wheel (chapter 08, V-17)
	if spots.has("seat"):
		a = []
		var t2 := _go(a, "gate>bench", "elder", BENCH[0])
		_stay(a, spots["seat"][0], float(spots["seat"][1]), "Sitting_Idle", t2, BENCH[1], true)
		_go(a, "bench>gate", "elder", BENCH[1])
		people.append({"key": "gallery_monk", "kind": "elder", "acts": a})
	# two novices racing down to the bridge (chapter 08, V-17): the younger a few seconds behind and quicker, a side each;
	# a while at the downstream rail looking down at the water, then the long climb back
	if spots.has("rail"):
		for nv in [["novice_c", "race", 0.0, 0.0, 0.3, -0.45, "Idle_A"], ["novice_d", "race_b", 0.25, 0.0, -0.3, 0.45, "Idle_FoldArms"]]:
			a = []
			var t3 := _go(a, "gate>deck", String(nv[1]), RACE + float(nv[2]), float(nv[3]), float(nv[4]))
			var at_rail: Vector3 = spots["rail"][0] + (spots["rail"][2] as Vector3) * float(nv[5])
			_stay(a, at_rail, float(spots["rail"][1]), String(nv[6]), t3, AT_RAIL + float(nv[2]))
			_go(a, "deck>gate", "novice", AT_RAIL + float(nv[2]), 0.0, float(nv[4]))
			people.append({"key": String(nv[0]), "kind": "novice", "acts": a})


## The tulku's afternoon home (chapter 08; chapter 05, NPC-04 and NPC-10): the three down the east leg to be at the
## bridge at TULKU_BRIDGE, up to the terrace in file; his mother there from MOTHER_AT; a greeting, then mother and son
## sit side by side looking out till PARTING, the attendants standing by; the three back down and on to the West Gate,
## she standing to watch them over the bridge before she goes home by the lane.
func _party() -> void:
	party = []
	if not spots.has("watch"):
		return
	var t0 := TULKU_BRIDGE - minutes_to("gate>terrace", "party", float(marks["gate"]) - float(marks["bridge_e"]))
	var arrive := 0.0
	var bodies := ["dungkar_tulku", "labrang_attendant", "labrang_attendant_b"]
	for k in 3:
		var a: Array = []
		var t := _go(a, "gate>terrace", "party", t0 + IN_FILE[k], SHORT[k])
		if k == 0:
			arrive = t
			_stay(a, spots["meet"][0], float(spots["meet"][1]), "Idle_A", t, t + GREET)
			_stay(a, spots["sit_son"][0], float(spots["sit_son"][1]), "Sitting_Cross", t + GREET, PARTING)
		else:
			_hold(a, "Idle_FoldArms" if k == 1 else "Idle_A", PARTING)
		_go(a, "terrace>gate", "party", PARTING + 1.0 + IN_FILE[k], 0.0, 0.0)
		party.append({"key": bodies[k], "kind": "party", "acts": a})
	var m: Array = []
	var walk_in := minutes_to("foot>watch", "party", way_length("foot>watch"))
	_go(m, "foot>watch", "party", MOTHER_AT - walk_in)
	_stay(m, spots["watch"][0], float(spots["watch"][1]), "Idle_FoldArms", MOTHER_AT, arrive)
	var face := _yaw_to(spots["watch"][0], spots["meet"][0])
	_stay(m, spots["watch"][0], face, "Greeting", arrive, arrive + 1.0)
	_stay(m, spots["watch"][0], face, "Idle_Talking", arrive + 1.0, arrive + GREET)
	_stay(m, spots["sit_mother"][0], float(spots["sit_mother"][1]), "Sitting_Cross", arrive + GREET, PARTING)
	var over := PARTING + 1.0 + minutes_to("terrace>gate", "party", float(marks["bridge_e"]) - float(marks["terrace"])) + 1.5
	_stay(m, spots["watch"][0], float(spots["watch"][1]), "Idle_FoldArms", PARTING, over)  # (until they are over the bridge)
	_go(m, "watch>foot", "party", over)
	party.append({"key": "chodron_tode", "kind": "party", "acts": m})


## Where `p` is at minute `m` of the day: [shown, position, yaw, clip, the clip's speed].
func where(p: Dictionary, m: float) -> Array:
	for a in p["acts"]:
		if m < float(a["t0"]) or m >= float(a["t1"]):
			continue
		if a.has("stay"):
			return [true, a["at"], float(a["yaw"]), String(a["clip"]), 1.0]
		var way := String(a["go"])
		var sv := Steps.s_at(_timeline_of(way, String(a["kind"])), (m - float(a["t0"])) * PER_MIN)
		return _on_way(way, minf(sv.x, float(a["end"])), sv.y, float(a["side"]), String(p["key"]), String(a["kind"]))
	return [false, Vector3.ZERO, 0.0, "", 1.0]


## Whether `p` is turning the gallery's wheel at minute `m`.
func turning(p: Dictionary, m: float) -> bool:
	for a in p["acts"]:
		if m >= float(a["t0"]) and m < float(a["t1"]):
			return bool(a.get("turning", false))
	return false


## A walker at `s` metres along `way` at `pace` m/s (0 standing), `side` metres right of its middle: [shown, position,
## yaw, clip, the clip's speed].
func _on_way(way: String, s: float, pace: float, side: float, key: String, kind: String) -> Array:
	var w: PackedVector3Array = ways[way]
	var c: PackedFloat32Array = cums[way]
	var q := Steps._at(w, c, s)
	var ahead := Steps._at(w, c, s + 0.6)
	var flat := Vector3(ahead.x - q.x, 0.0, ahead.z - q.z)
	var steep := absf(ahead.y - q.y) / 0.6 > STEEP
	if flat.length() < 0.001:  # (at the way's end: facing the way it came)
		var behind := Steps._at(w, c, s - 0.6)
		flat = Vector3(q.x - behind.x, 0.0, q.z - behind.z)
		steep = false
	var f := flat.normalized() if flat.length() > 0.001 else Vector3(0.0, 0.0, 1.0)
	var at := q + Vector3(-f.z, 0.0, f.x) * side
	var yaw := atan2(f.x, f.z)
	if pace <= 0.0:
		return [true, at, yaw, "Idle_A", 1.0]
	var sp: Dictionary = _speeds.get(key, {})
	if kind.begins_with("race"):
		var run := clampf(pace / 1.8, 0.7, 1.2) if steep else clampf(pace / float(sp.get("Run_Female", 2.6)), 0.6, 1.3)
		return [true, at, yaw, "Run_Female", run]
	var clip := "Walk_Carry" if kind == "laden" else ("Walk_Female" if WOMEN.has(key) else "Walk")
	var speed := clampf(pace / STEP_ALONG / 1.2, 0.55, 1.4) if steep else clampf(pace / float(sp.get(clip, 0.74)), 0.6, 1.3)
	return [true, at, yaw, clip, speed]


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
		root.name = "Gorge_%s" % String(p["key"])
		PersonLook.apply(root, _mat)
		var ap: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Walk_Female", "Walk_Carry", "Run_Female", "Idle_A", "Idle_FoldArms", "Idle_Talking", "Greeting", "Sitting_Idle", "Crouch_Idle"]:
			if ap.has_animation(n) and n != "Greeting":
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		var tint := 0.92 + 0.16 * fposmod(i * 0.618034, 1.0)  # a small tone shift each (as the town's crowd, characters/crowd.gd)
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			(mi as GeometryInstance3D).set_instance_shader_parameter("tint", tint)
		add_child(root)
		root.visible = false
		p["root"] = root
		p["ap"] = ap
		p["clip"] = ""


func _process(_dt: float) -> void:
	if ways.is_empty():
		return
	var cam := get_viewport().get_camera_3d()
	var on: bool = cam != null and Vector2(cam.global_position.x - _mid.x, cam.global_position.z - _mid.z).length() < SEEN
	if not on:
		for p in people + party:
			if p.has("root"):
				(p["root"] as Node3D).visible = false
		hand.position = Vector3(0.0, -10000.0, 0.0)
		return
	if not _built:
		_bodies()
	var day := int(floor(WorldClock.minute / 1440.0))
	if day != _day:
		_day = day
		_party_day = tulku_day(WorldClock.minute)
	var m := fposmod(WorldClock.minute, 1440.0)
	var frozen: bool = WorldClock.frozen
	var g: float = WorldClock.anim_time
	var i := 0
	var turned := false
	for p in people:
		_show(p, where(p, m), frozen, g, i)
		turned = turned or turning(p, m)
		i += 1
	for p in party:
		_show(p, where(p, m) if _party_day else [false, Vector3.ZERO, 0.0, "", 1.0], frozen, g, i)
		i += 1
	hand.global_position = spots["hand"] if turned and spots.has("hand") else Vector3(0.0, -10000.0, 0.0)


func _show(p: Dictionary, r: Array, frozen: bool, g: float, i: int) -> void:
	if not p.has("root"):
		return
	var root: Node3D = p["root"]
	root.visible = bool(r[0])
	if not bool(r[0]):
		return
	root.global_position = r[1]
	root.rotation.y = float(r[2])
	var ap: AnimationPlayer = p["ap"]
	var clip := String(r[3])
	if not ap.has_animation(clip):
		clip = "Walk" if clip.begins_with("Walk") and ap.has_animation("Walk") else "Idle_A"
	if String(p["clip"]) != clip:
		ap.play(clip, 0.0 if frozen or String(p["clip"]) == "" else 0.3)
		p["clip"] = clip
	if frozen:  # the stills: the pose from the animation clock
		ap.speed_scale = 0.0
		ap.seek(fposmod(g * float(r[4]) + i * 0.37, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = float(r[4])
