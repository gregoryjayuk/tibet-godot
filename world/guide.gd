extends Node3D
## A child of the house leads the way up the Rooftop Way (M1's acceptance, walk 5: "at 16:45 follow a child of the house
## up the Rooftop Way, never able to fall"; chapter 08, V-28: "at 16:45 a child of the house leads the way up R-06";
## sprint 8, step 8). A daughter of Dechen-tsang waits at the Way's foot in its guest yard from 16:40; when the player
## comes to her there before 17:20 she greets them and leads: along the Way's legs (assets/generated/terrain/rooftop.json,
## tools/town/rooftop.py), up and down its stair-ladders and notched logs facing them, over its planks and roof steps and
## up the side lanes, some metres ahead, stopping to look back and wait whenever the player falls behind (never on a
## ladder), and on the last roof, V-28's, she stands and watches the town. With nobody come by 17:20 she goes in; she
## goes in at 17:50 from the roof too. Her body: ../tibet-blender people2/body.py `dechen_child` (the townspeople's
## clips and the player's two ladder clips). Drawn only while the townspeople are out (TownSim's walkers). `path` and
## `step` are what the tests drive.

const BODY := "res://assets/generated/people/dechen_child.glb"
const WAY := "res://assets/generated/terrain/rooftop.json"
const COME := 1000.0  ## 16:40: she is at the Way's foot
const LATE := 1040.0  ## 17:20: nobody came, she goes in
const HOME := 1070.0  ## 17:50: she goes down from the roof
const MEET := 5.0  ## metres: the player this near her at the foot, she greets them and sets off
const LEAD := 4.0  ## she walks on while the player is this near
const WAIT := 7.0  ## and waits, turned to them, when they fall this far behind
const WALK := 1.1  ## m/s
const CLIMB := 0.5  ## m/s along a ladder
const GREET_S := 2.5  ## seconds of her greeting before she sets off

var segs: Array = []  ## {kind: "walk" or "climb", a, b (Godot), len, yaw (a climb faces its ladder)}
var total := 0.0
var s := 0.0  ## metres along the path
var mode := "away"  ## away, waiting, greeting, leading, pausing, arrived
var pos := Vector3.ZERO
var yaw := 0.0
var clip := "Idle_A"
var _t := 0.0  ## seconds in the greeting
var _body: Node3D
var _ap: AnimationPlayer
var _playing := ""
var _speeds := {}  ## clip -> the ground speed its feet keep (named_clips.json)
var hold := false  ## a still's pose: she stays where `show_at` put her


## The Way as her path, from its legs: the walked points, and each ladder a climb from foot to top (or top to foot going
## down), met square: the walk comes to its foot (or to its top from the deck) before the climb.
static func path(to_godot: Callable) -> Array:
	if not FileAccess.file_exists(WAY):
		return []
	var legs: Array = JSON.parse_string(FileAccess.get_file_as_string(WAY))["legs"]
	var out: Array = []
	var st := {"last": Vector3.INF}  # shared with _walk_to (a lambda would take `last` by value)
	for k in legs.size():
		var leg: Dictionary = legs[k]
		if leg.has("points"):
			for q in leg["points"]:
				_walk_to(out, st, to_godot.call(float(q[0]), float(q[1]), float(q[2])))
			continue
		var pc = leg.get("piece")
		if pc == null or not (String(pc["kind"]) in ["log", "stair"]) or st["last"] == Vector3.INF:
			continue  # steps, planks, lanes: walked straight to the next leg's first point
		var nxt: Array = legs[k + 1]["points"][0] if k + 1 < legs.size() and (legs[k + 1] as Dictionary).has("points") else []
		var foot: Vector3 = to_godot.call(float(pc["foot"][0]), float(pc["foot"][1]), float(pc["foot"][2]))
		var top: Vector3 = to_godot.call(float(pc["top"][0]), float(pc["top"][1]), float(pc["top"][2]))
		var up: bool = nxt.is_empty() or float(nxt[2]) > float(pc["foot"][2]) + 0.5
		var ax := _dir(float(pc.get("bearing", 0.0)))  # the ladder's way from its foot to its wall
		var face := atan2(ax.x, ax.z)  # a figure facing +Z turned to face the ladder
		var low := foot - ax * 0.35
		var high := top + ax * 0.45 if not up else top
		if up:
			_walk_to(out, st, low)
			out.append({"kind": "climb", "a": low, "b": high, "len": low.distance_to(high), "yaw": face})
			st["last"] = high
		else:
			_walk_to(out, st, high)
			out.append({"kind": "climb", "a": high, "b": low, "len": high.distance_to(low), "yaw": face})
			st["last"] = low
	return out


static func _walk_to(out: Array, st: Dictionary, p: Vector3) -> void:
	var last: Vector3 = st["last"]
	if last != Vector3.INF and last.distance_to(p) > 0.02:
		out.append({"kind": "walk", "a": last, "b": p, "len": last.distance_to(p), "yaw": 0.0})
	st["last"] = p


## A bearing (degrees clockwise from north) as a direction in Godot's frame (north is -Z).
static func _dir(bearing: float) -> Vector3:
	var r := deg_to_rad(bearing)
	return Vector3(sin(r), 0.0, -cos(r))


func _ready() -> void:
	add_to_group("guide")


func build(to_godot: Callable) -> int:
	segs = path(to_godot)
	total = 0.0
	for g in segs:
		total += float(g["len"])
	if not segs.is_empty():
		pos = segs[0]["a"]
	return segs.size()


## Where she is and which way she faces at `s` metres along the path.
func at(d: float) -> Array:
	var run := 0.0
	for g in segs:
		var l: float = g["len"]
		if d <= run + l or g == segs[segs.size() - 1]:
			var k := clampf((d - run) / maxf(l, 0.001), 0.0, 1.0)
			var a: Vector3 = g["a"]
			var b: Vector3 = g["b"]
			var y := float(g["yaw"]) if g["kind"] == "climb" else atan2(b.x - a.x, b.z - a.z)
			return [a.lerp(b, k), y, String(g["kind"])]
		run += l
	return [pos, yaw, "walk"]


## How far along her path the player is: the nearest point of the path within 40 m of her either way (the Way doubles
## back on itself; the nearest point overall could be a leg far off), or -INF with no player.
func progress_of(player: Vector3) -> float:
	if player == Vector3.INF:
		return -INF
	var run := 0.0
	var best := INF
	var at_d := -INF
	for g in segs:
		var l: float = g["len"]
		if run + l >= s - 40.0 and run <= s + 40.0:
			var a: Vector3 = g["a"]
			var b: Vector3 = g["b"]
			var ab := b - a
			var k := clampf((player - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			var d := player.distance_to(a + ab * k)
			if d < best:
				best = d
				at_d = run + k * l
		run += l
	return at_d if best < 6.0 else -INF  # off the Way altogether: not following


## A still's pose (tests/terrain/s3.gd's guide_ stations): `d` metres along her way, leading, held there.
func show_at(d: float) -> void:
	mode = "leading"
	s = clampf(d, 0.0, total)
	var w: Array = at(s)
	pos = w[0]
	yaw = w[1]
	clip = _clip_for(false)
	hold = true


## Metres along her way to the start of her `n`th climb (0 the first).
func climb_at(n: int) -> float:
	var run := 0.0
	var k := 0
	for g in segs:
		if g["kind"] == "climb":
			if k == n:
				return run
			k += 1
		run += float(g["len"])
	return run


## One step of her evening: the player's feet at `player` (or Vector3.INF with no player), the minute of the day `m`.
func step(dt: float, player: Vector3, m: float) -> void:
	if segs.is_empty() or hold:
		return
	var start: Vector3 = segs[0]["a"]
	var near := player != Vector3.INF and player.distance_to(pos) < WAIT
	match mode:
		"away":
			if m >= COME and m < LATE and s == 0.0:
				mode = "waiting"
				pos = start
		"waiting":
			pos = start
			if m >= LATE or m < COME:
				mode = "away"
			elif player != Vector3.INF and player.distance_to(start) < MEET:
				mode = "greeting"
				_t = 0.0
		"greeting":
			_t += dt
			if _t >= GREET_S:
				mode = "leading"
		"leading", "pausing":
			var here: Array = at(s)
			var on_ladder: bool = here[2] == "climb"
			var ps := progress_of(player)  # the player's place along the Way (ahead of her is fine: she leads on)
			var behind := ps < s - WAIT
			if mode == "leading" and behind and not on_ladder:
				mode = "pausing"
			elif mode == "pausing" and ps >= s - LEAD:
				mode = "leading"
			if mode == "leading":
				s = minf(s + (CLIMB if on_ladder else WALK) * dt, total)
				if s >= total:
					mode = "arrived"
		"arrived":
			if m >= HOME or m < COME:
				mode = "away"
				s = 0.0
	if mode in ["leading", "pausing", "arrived"]:
		var w: Array = at(s)
		pos = w[0]
		yaw = w[1]
	if mode == "pausing" or mode == "greeting" or (mode == "waiting" and near):
		if player != Vector3.INF:  # turned to the player
			yaw = atan2(player.x - pos.x, player.z - pos.z)
	if mode == "arrived":  # over the town to the south, as V-28 looks (chapter 08: facing 150-175 degrees)
		var v := _dir(165.0)
		yaw = atan2(v.x, v.z)
	clip = _clip_for(near)


func _clip_for(near: bool) -> String:
	match mode:
		"greeting":
			return "Greeting"
		"leading":
			return "Climb_Ladder" if at(s)[2] == "climb" else "Walk_Female"
		"pausing":
			return "Ladder_Idle" if at(s)[2] == "climb" else "Idle_Listening"
		"arrived":
			return "Idle_Subtle"
		"waiting":
			return "Idle_Listening" if near else "Idle_A"
	return "Idle_A"


func _process(dt: float) -> void:
	if segs.is_empty():
		return
	var cam := get_viewport().get_camera_3d()
	var on: bool = TownSim.walkers_on and cam != null and cam.global_position.distance_to(pos) < 250.0
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	var m := fposmod(WorldClock.minute, 1440.0)
	step(dt, pl.global_position if pl != null else Vector3.INF, m)
	if not on or mode == "away":
		if _body != null:
			_body.visible = false
		return
	if _body == null:
		if not ResourceLoader.exists(BODY):
			set_process(false)
			return
		_body = (load(BODY) as PackedScene).instantiate()
		_body.name = "DechenChild"
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://characters/person.gdshader")
		PersonLook.apply(_body, mat)
		add_child(_body)
		_ap = _body.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk_Female", "Climb_Ladder", "Ladder_Idle", "Idle_A", "Idle_Listening", "Idle_Subtle"]:
			if _ap.has_animation(n):
				_ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		var info = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/people/named_clips.json"))
		if info is Dictionary:
			var c: Dictionary = (info["bodies"] as Dictionary).get("dechen_child", {})
			for k in c:
				_speeds[k] = float((c[k] as Dictionary).get("speed", 0.0))
	_body.visible = true
	var p := pos
	if at(s)[2] != "climb":  # her feet on what is under them: a roof, a plank, a step, the lane
		var q := PhysicsRayQueryParameters3D.create(pos + Vector3(0.0, 1.0, 0.0), pos - Vector3(0.0, 1.2, 0.0))
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and absf((hit["position"] as Vector3).y - pos.y) < 0.9:
			p.y = (hit["position"] as Vector3).y
	_body.global_position = p
	_body.rotation.y = yaw
	var c2 := clip if _ap.has_animation(clip) else "Idle_A"
	if c2 != _playing:
		_ap.play(c2, 0.25)
		_playing = c2
	if WorldClock.frozen:
		_ap.speed_scale = 0.0
		_ap.seek(fposmod(WorldClock.anim_time, _ap.get_animation(c2).length), true)
	elif c2 == "Walk_Female" and float(_speeds.get(c2, 0.0)) > 0.05:
		_ap.speed_scale = WALK / float(_speeds[c2])  # her feet at her pace
	elif c2 == "Climb_Ladder":
		_ap.speed_scale = 1.2
	else:
		_ap.speed_scale = 1.0
