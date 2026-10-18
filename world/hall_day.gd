extends Node3D
## The Tsokchen's day and the Labrang's (M3 sprint 6, step 3; plan chapter 04, 3.1's and 3.8's "Who is here"; chapter 08,
## V-26, the full-moon assembly), the people world/assembly.gd's seated rows and its disciplinarian leave out, each placed
## where the game's clock puts them, so a still finds them there again:
## - at every session, a tea pass on the session's fifth minute and every half hour after: two novices down the rows with
##   the big kettles, a step and a stop to pour;
## - lay visitors, during the good days' morning assembly and through 12:00-17:00: in at the great door, three
##   prostrations (a stand-in: hands joined, down on their knees, up, until Greg's motion takes), up the west side aisle and
##   twice clockwise round the Nangkor behind the inner chapel, turning its wheels (the group "kora_walkers"), out again;
## - 07:00-09:00: two sweepers along the aisles with their brooms, the sacristan (dkon gnyer) going from lamp bank to lamp
##   bank topping up the lamps;
## - 19:00-05:00 the great door shut, its two leaves across it (the kit's door leaf scaled to it) and no way in (once the
##   player, if still inside at 19:00, has gone out);
## - the incense haze over the rows through each session and half an hour after (shaders/incense_haze.gdshader, a FogVolume
##   in the valley's volumetric fog, lit by the sky's ambient while the camera is in the hall), so the lantern's shafts show;
## - in the Labrang's reception (chapter 04, 3.8): the tulku on his throne 10:00-13:00 (from 11:00 on the good days, after
##   the assembly), his tutor beside him through the audience 10:00-11:30, a petitioner kneeling before the throne now and
##   then, the treasurer kneeling to read out the day's business 11:30-13:00.
## - at the general tea (11:00-11:40) a novice with the big kettle in the aisle by the rows' door end, who serves the
##   guest's place (world/hall_tea.gd, made here under the hall's ROOM 1 socket; while he serves, `overrides` has him).
## Drawn only with the camera near. Added by world/town.gd.

const Assembly := preload("res://world/assembly.gd")
const HallTea := preload("res://world/hall_tea.gd")
const BODY := "res://assets/generated/people/%s.glb"
const KIT := "res://assets/generated/kit/types/%s_v1.glb"
const NEAR := 50.0  ## metres from the hall (or the reception) within which its people are drawn
const WALK := 10.0  ## metres a game minute: 1 m/s at the clock's 6:1
const STEP_CLIP := 0.735  ## the bodies' Walk at rate 1, m/s (named_clips.json)
## The tea passes: [the session's minute of the first, every, minutes a pass lasts, metres along the rows a pass walks]
const TEA := [5.0, 30.0, 6.0, 14.6]
const PILGRIM_CYCLE := 26.0  ## game minutes a lay visitor's visit takes, the next one in
const PILGRIM_HOURS := [[720.0, 1020.0]]  ## 12:00-17:00 (and the good days' morning assembly)
const CLEAN := [420.0, 540.0]  ## 07:00-09:00: the sweepers and the sacristan
const SHUT := [1140.0, 300.0]  ## 19:00-05:00: the great door shut
const DOOR_W := 2.4  ## the great door's clear opening (kit/monastery.py tsokchen: _door_open's 2.4 by 3.6)
const DOOR_H := 3.6
const HAZE_AFTER := 30.0  ## minutes the incense hangs after a session
const INJECT := 0.35  ## the sky's ambient lighting the haze while the camera is in the hall (Environment.volumetric_fog_ambient_inject)

## The Tsokchen in its own kit frame (x across, y in from the door, the floor at 0.05): the door just inside, the side
## aisles beyond the rows' ends, the Nangkor's arms' middles round the inner chapel (kit/monastery.py _hall_inside:
## IX 12.3, IY 15.3, the corridor 1.5 m), the nave's head between the thrones and the lamp banks.
const IN_DOOR := Vector2(0.0, -14.4)
const AISLE_W := -11.5
const AISLE_E := 11.5
const HEAD_Y := 5.3
const NANGKOR := [Vector2(-11.55, 6.9), Vector2(-11.55, 14.55), Vector2(11.55, 14.55), Vector2(11.55, 6.9), Vector2(11.55, HEAD_Y), Vector2(-11.5, HEAD_Y)]
const LAMP_SPOTS := [Vector2(-3.0, 5.2), Vector2(-1.0, 5.2), Vector2(1.0, 5.2), Vector2(3.0, 5.2)]
## The reception in its room's frame (the Labrang's ROOM 1 socket: the kit's labrang_reception, x along it, the throne
## at the east end facing west): [x, y, seat height, facing (degrees from +x, the kit's)].
const THRONE := [-3.75, 3.3, 1.2, 0.0]
const TUTOR := [-3.35, 1.6, 0.5, 0.0]
const BEFORE := [-1.6, 3.3, 0.06, 180.0]  ## kneeling before the throne: a petitioner, the treasurer
## The general tea's guest (world/hall_tea.gd): the bowl on the book-stand before the nave's SEAT 1, in the nave room's
## frame (its ROOM 1 socket: the hall's frame 15.3 m in; kit/tsokchen_rooms.py, the rows at 1.8 + 1.3 k, the stands 0.52 m
## before them, their tops at 0.311); and where the novice who serves the back rows stands, in the hall's frame.
const GUEST_BOWL := Vector3(-1.28, 2.431, 0.311)
const SERVER_AT := Vector2(-0.7, -12.2)
const BACK := 0.4  ## the sitting pose's root this far before the hips (world/assembly.gd)

class Figure:
	var root: Node3D
	var ap: AnimationPlayer
	var clip := ""
	var prop: Node3D  ## carried before them: a kettle, a broom
	var prop_at := Vector3(0.24, 0.82, 0.32)  ## from the feet: right, up, forward

var hall: Node3D
var reception: Node3D  ## the Labrang's ROOM 1 socket
var figures := {}  ## name -> Figure
var haze: FogVolume
var leaves: Array = []  ## the great door's two leaves, shown shut
var _inject_back := -1.0  ## the environment's ambient inject before the haze took it, while it has it
var tea: Node3D  ## the general tea's guest bowl (world/hall_tea.gd)
var overrides := {}  ## the serving novice while he serves the guest (world/tea.gd's way: 0 -> {pos, yaw, state, speed, clip})
var bar: StaticBody3D


## Finds the Tsokchen and the Labrang, makes their people (hidden), the haze and the shut door. The figures' count.
func build(root: Node) -> int:
	hall = root.find_child("MON-01", true, false) as Node3D
	var lab := root.find_child("MON-09", true, false) as Node3D
	reception = lab.find_child("SOCK_ROOM_1", true, false) as Node3D if lab != null else null
	if hall != null:
		for n in [["kettle_w", "novice_c", "tea_pot"], ["kettle_e", "novice_d", "tea_pot"], ["pilgrim_1", "elder_woman", ""],
				["pilgrim_2", "townswoman_b", ""], ["sweeper_1", "novice", "broom"], ["sweeper_2", "novice_b", "broom"],
				["sacristan", "gallery_monk", ""], ["server", "novice", "tea_pot"]]:
			_figure(n[0], n[1], n[2])
		for k in ["pilgrim_1", "pilgrim_2"]:
			if figures.has(k):
				(figures[k] as Figure).root.add_to_group("kora_walkers")  # (world/kora_wheels.gd: their right hands turn the wheels)
		_haze()
		_door()
		var room := hall.find_child("SOCK_ROOM_1", true, false) as Node3D
		if room != null and figures.has("server"):
			tea = HallTea.new()
			tea.name = "HallTea"
			tea.set("hall_day", self)
			tea.set_meta("r", 0.06)
			tea.set_meta("stand", 0.0)
			room.add_child(tea)
			tea.position = Vector3(GUEST_BOWL.x, GUEST_BOWL.z, -GUEST_BOWL.y)
	if reception != null:
		for n in [["tulku", "dungkar_tulku"], ["tutor", "labrang_attendant"], ["petitioner", "elder_man"], ["treasurer", "tode_monk"]]:
			_figure(n[0], n[1], "")
	return figures.size()


func _figure(fname: String, body: String, prop: String) -> void:
	if not ResourceLoader.exists(BODY % body):
		return
	var f := Figure.new()
	f.root = (load(BODY % body) as PackedScene).instantiate()
	f.root.name = fname.capitalize().replace(" ", "")
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://characters/person.gdshader")
	PersonLook.apply(f.root, mat)
	f.root.top_level = true
	add_child(f.root)
	f.root.visible = false
	f.ap = f.root.find_children("*", "AnimationPlayer", true, false)[0]
	for c in ["Walk", "Idle_A", "Interact", "Crouch_Idle", "Sitting_Cross", "Idle_FoldArms", "Greeting", "Idle_Listening"]:
		if f.ap.has_animation(c):
			f.ap.get_animation(c).loop_mode = Animation.LOOP_LINEAR
	if prop == "tea_pot" and ResourceLoader.exists(KIT % "tea_pot"):
		f.prop = (load(KIT % "tea_pot") as PackedScene).instantiate()
		f.prop.scale = Vector3.ONE * 1.6  # the temple's big kettle, copper, a novice's two hands
	elif prop == "broom":
		f.prop = _broom()
		f.prop_at = Vector3(0.2, 0.0, 0.45)
	if f.prop != null:
		f.prop.top_level = true
		f.prop.visible = false
		add_child(f.prop)
	figures[fname] = f


## A broom of twigs bound on a stick, its head on the floor before the sweeper.
func _broom() -> Node3D:
	var b := Node3D.new()
	var stick := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.014
	cm.bottom_radius = 0.016
	cm.height = 1.1
	cm.radial_segments = 5
	stick.mesh = cm
	stick.position = Vector3(0.0, 0.62, -0.18)
	stick.rotation.x = -0.45
	var head := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.04
	hm.bottom_radius = 0.11
	hm.height = 0.32
	hm.radial_segments = 7
	head.mesh = hm
	head.position = Vector3(0.0, 0.12, 0.05)
	head.rotation.x = -0.45
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.36, 0.26, 0.16)
	var twigs := StandardMaterial3D.new()
	twigs.albedo_color = Color(0.55, 0.47, 0.33)
	stick.material_override = wood
	head.material_override = twigs
	b.add_child(stick)
	b.add_child(head)
	return b


## The incense haze over the rows: a FogVolume the size of the nave's rows under its ceiling.
func _haze() -> void:
	haze = FogVolume.new()
	haze.name = "IncenseHaze"
	haze.size = Vector3(23.0, 5.2, 18.5)
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/incense_haze.gdshader")
	var nt := NoiseTexture3D.new()
	nt.width = 48
	nt.height = 24
	nt.depth = 48
	nt.seamless = true
	var fn := FastNoiseLite.new()
	fn.frequency = 0.035
	fn.fractal_octaves = 3
	nt.noise = fn
	m.set_shader_parameter("noise_tex", nt)
	haze.material = m
	add_child(haze)
	haze.global_transform = Transform3D(hall.global_basis, _hall_at(0.0, -5.6, 2.7))
	haze.visible = false


## The great door's leaves, shut across it from 19:00 (the kit's rich red leaf, scaled to the door), and the bar that
## keeps everyone out.
func _door() -> void:
	var door := hall.find_child("SOCK_DOOR_1", true, false) as Node3D
	if door == null or not ResourceLoader.exists(KIT % "door_leaf_red_rich"):
		return
	for side in [-1.0, 1.0]:
		var leaf: Node3D = (load(KIT % "door_leaf_red_rich") as PackedScene).instantiate()
		door.add_child(leaf)
		leaf.position = Vector3(side * DOOR_W / 2.0, 0.0, 0.05)
		leaf.scale = Vector3(DOOR_W / 2.0 / 0.495, DOOR_H / 1.85, 1.0)
		if side > 0.0:  # the right leaf hinged at the right, along -x: turned round and mirrored, its face still out
			leaf.rotation.y = PI
			leaf.scale.z = -1.0
		leaf.visible = false
		leaves.append(leaf)
	bar = StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(DOOR_W + 0.2, DOOR_H, 0.25)
	cs.shape = box
	bar.add_child(cs)
	door.add_child(bar)
	bar.position = Vector3(0.0, DOOR_H / 2.0, 0.1)
	bar.collision_layer = 0


## A point in the Tsokchen's kit frame, Godot's world.
func _hall_at(x: float, y: float, z := 0.05) -> Vector3:
	return hall.global_transform * Vector3(x, z, -y)


## A point in the reception's room frame (the kit's labrang_reception), Godot's world.
func _room_at(x: float, y: float, z: float) -> Vector3:
	return reception.global_transform * Vector3(x, z, -y)


## Along a path of points (Godot) `walked` metres: [position, the way (flat), done].
static func along(path: Array, walked: float) -> Array:
	for i in path.size() - 1:
		var a: Vector3 = path[i]
		var b: Vector3 = path[i + 1]
		var l := a.distance_to(b)
		if walked <= l:
			return [a.lerp(b, walked / maxf(l, 0.001)), Vector3(b.x - a.x, 0.0, b.z - a.z).normalized(), false]
		walked -= l
	var e: Vector3 = path[path.size() - 1]
	var p: Vector3 = path[path.size() - 2]
	return [e, Vector3(e.x - p.x, 0.0, e.z - p.z).normalized(), true]


static func length_of(path: Array) -> float:
	var t := 0.0
	for i in path.size() - 1:
		t += (path[i] as Vector3).distance_to(path[i + 1])
	return t


## Whether a point in the Tsokchen's own frame (Godot's axes: -z in from the door) is inside its walls, past the door.
static func inside_hall(local: Vector3) -> bool:
	return absf(local.x) < 13.0 and -local.z > IN_DOOR.y - 1.9 and -local.z < 16.5 and local.y > -1.0 and local.y < 14.0


## Whether `m` lies in the span [from, to) of the day, a span through midnight when to < from.
static func in_span(m: float, span: Array) -> bool:
	var a := float(span[0])
	var b := float(span[1])
	return (m >= a and m < b) if a <= b else (m >= a or m < b)


func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var minute := fposmod(WorldClock.minute, 1440.0)
	var good := Assembly.good_day(WorldClock.minute)
	var seen_hall := hall != null and cam.global_position.distance_to(_hall_at(0.0, 0.0)) < NEAR
	var seen_room := reception != null and cam.global_position.distance_to(reception.global_position) < NEAR * 0.5
	var states := {}  # figure -> [position, way, clip, rate] or null (hidden)
	if seen_hall:
		var k := Assembly.session_at(minute, good)
		_tea(states, minute, k)
		_pilgrims(states, minute, good)
		_cleaning(states, minute)
		_server(states, k)
		_haze_at(minute, good)
		_shut(in_span(minute, SHUT))
	else:
		if haze != null:
			haze.visible = false
	_air(seen_hall and haze != null and haze.visible and inside_hall(hall.to_local(cam.global_position)))
	if seen_room:
		_reception(states, minute, good)
	for fname in figures:
		_show(figures[fname], states.get(fname))


## The tea pass: two novices down the rows, the west's and the east's, a few steps and a stop to pour.
func _tea(states: Dictionary, m: float, k: int) -> void:
	if k < 0:
		return
	var t := m - float(Assembly.SESSIONS[k][0]) - float(TEA[0])
	if t < 0.0:
		return
	var n := int(t / float(TEA[1]))
	t -= n * float(TEA[1])
	if t >= float(TEA[2]):
		return
	var walked := float(TEA[3]) * t / float(TEA[2])
	var pouring := fposmod(t * 10.0, 4.0) < 1.8  # (a stop every few steps to pour: about 11 s of every 24)
	for side in [["kettle_w", -1.0], ["kettle_e", 1.0]]:
		var lane := float(side[1]) * (2.4 + 1.3 * float((n * 3 + (1 if side[1] > 0.0 else 0)) % 6))  # a different lane each pass
		var path := [_hall_at(lane, -12.9), _hall_at(lane, -12.9 + float(TEA[3]))]
		var w := along(path, walked)
		states[side[0]] = [w[0], w[1], "Interact" if pouring else "Walk", 1.0 if pouring else 0.4 / STEP_CLIP]


## The novice who serves the back rows at the general tea: in the aisle by their door end, the kettle at his side, turned
## to the rows; serving the guest, where world/hall_tea.gd puts him (his kettle then the tea's own, in his hand).
func _server(states: Dictionary, k: int) -> void:
	if overrides.has(0):
		var o: Dictionary = overrides[0]
		var yaw := float(o["yaw"])
		var walking := int(o.get("state", 1)) == 0
		states["server"] = [o["pos"], Vector3(sin(yaw), 0.0, cos(yaw)), "Walk" if walking else String(o.get("clip", "Idle_A")),
				float(o.get("speed", 0.9)) / STEP_CLIP if walking else 1.0, true]
	elif k == Assembly.GENERAL:
		var at := server_spot()
		var to := _hall_at(SERVER_AT.x - 1.0, SERVER_AT.y) - at
		states["server"] = [at, Vector3(to.x, 0.0, to.z).normalized(), "Idle_A", 1.0]


## Where the serving novice stands between pours (Godot's world).
func server_spot() -> Vector3:
	return _hall_at(SERVER_AT.x, SERVER_AT.y)


## The lay visitors: their visits in their hours, each in at the door, three prostrations, round the Nangkor twice, out.
func _pilgrims(states: Dictionary, m: float, good: bool) -> void:
	var spans := PILGRIM_HOURS.duplicate()
	if good:
		spans.append([float(Assembly.SESSIONS[Assembly.GOOD_SESSION][0]), float(Assembly.SESSIONS[Assembly.GOOD_SESSION][1])])
	for j in 2:
		var fname := "pilgrim_%d" % (j + 1)
		for sp in spans:
			if not in_span(m, sp):
				continue
			var t := fposmod(m - float(sp[0]) - j * 12.0, PILGRIM_CYCLE)
			if m - float(sp[0]) - j * 12.0 < 0.0:
				break
			var st := pilgrim_at(t)
			if st.is_empty():
				break
			states[fname] = st
			break


## Where a lay visitor is `t` minutes into a visit: [position, way, clip, rate], or empty when gone.
func pilgrim_at(t: float) -> Array:
	var door := _hall_at(IN_DOOR.x, IN_DOOR.y)
	var face := (_hall_at(0.0, 0.0) - door)
	face.y = 0.0
	face = face.normalized()
	if t < 1.5:  # three prostrations (a stand-in: hands joined, down on the knees, up), half a minute each
		var ph := fposmod(t, 0.5) / 0.5
		return [door, face, "Greeting" if ph < 0.35 else ("Crouch_Idle" if ph < 0.8 else "Idle_A"), 1.0]
	var path := [door, _hall_at(AISLE_W, IN_DOOR.y + 0.4), _hall_at(AISLE_W, HEAD_Y)]
	for lap in 2:
		for q in NANGKOR:
			path.append(_hall_at((q as Vector2).x, (q as Vector2).y))
	path.append_array([_hall_at(AISLE_W, IN_DOOR.y + 0.4), door])
	var walked := (t - 1.5) * WALK * 0.8  # (slowly, 0.8 m/s)
	var w := along(path, walked)
	if bool(w[2]):
		return []
	return [w[0], w[1], "Walk", 0.8 / STEP_CLIP]


## 07:00-09:00: the sweepers along the aisles, back and forth, and the sacristan at the lamp banks.
func _cleaning(states: Dictionary, m: float) -> void:
	if not in_span(m, CLEAN):
		return
	var t := m - float(CLEAN[0])
	for s in [["sweeper_1", 0.0], ["sweeper_2", AISLE_W]]:
		var path := [_hall_at(float(s[1]), -13.0), _hall_at(float(s[1]), HEAD_Y - 0.6), _hall_at(float(s[1]) + 0.01, -13.0)]
		var span := length_of(path)
		var walked := fposmod(t * WALK * 0.3, span)  # (0.3 m/s, sweeping)
		var w := along(path, walked)
		states[s[0]] = [w[0], w[1], "Walk", 0.3 / STEP_CLIP]
	var k := int(t / 4.0) % LAMP_SPOTS.size()  # four minutes at each bank, topping up its lamps
	var spot: Vector2 = LAMP_SPOTS[k]
	var at := _hall_at(spot.x, spot.y)
	var to := _hall_at(spot.x, spot.y + 1.0) - at
	states["sacristan"] = [at, Vector3(to.x, 0.0, to.z).normalized(), "Interact", 0.6]


## The reception: the tulku on his throne, his tutor beside him at the audience, a petitioner kneeling now and then, the
## treasurer reading out the day's business; seated, their hips over their seats.
func _reception(states: Dictionary, m: float, good: bool) -> void:
	var from := 660.0 if good else 600.0
	if m >= from and m < 780.0:
		states["tulku"] = _seated(THRONE, "Sitting_Cross")
	if m >= from and m < 690.0:
		states["tutor"] = _seated(TUTOR, "Sitting_Cross")
		if fposmod(m - from, 12.0) < 5.0:  # a petitioner every twelve minutes, five before the throne
			states["petitioner"] = _seated(BEFORE, "Crouch_Idle")
	if m >= 690.0 and m < 780.0:
		states["treasurer"] = _seated(BEFORE, "Crouch_Idle")


func _seated(seat: Array, clip: String) -> Array:
	var a := deg_to_rad(float(seat[3]))
	var f := (reception.global_basis * Vector3(cos(a), 0.0, -sin(a))).normalized()
	var at := _room_at(float(seat[0]), float(seat[1]), float(seat[2]))
	if clip == "Sitting_Cross":
		at += f * BACK
	return [at, f, clip, 1.0]


## The incense through each session and a while after.
func _haze_at(m: float, good: bool) -> void:
	if haze == null:
		return
	var on := false
	for k in Assembly.SESSIONS.size():
		if k == Assembly.GOOD_SESSION and not good:
			continue
		if m >= float(Assembly.SESSIONS[k][0]) and m < float(Assembly.SESSIONS[k][1]) + HAZE_AFTER:
			on = true
	if haze.visible != on:
		print("hall day: the incense haze %s at %s (%s, %s)" % ["on" if on else "off", Calendar.clock(WorldClock.minute), str(haze.global_position.snapped(Vector3(0.1, 0.1, 0.1))), str(haze.size)])
	haze.visible = on


## The haze lit by the sky's ambient while the camera is in the hall with it, the environment as it was once out.
func _air(lit: bool) -> void:
	if lit == (_inject_back >= 0.0):
		return
	var dn := get_tree().get_first_node_in_group("day")
	var env: Environment = dn.get("env") if dn != null else null
	if env == null:
		return
	if lit:
		_inject_back = env.volumetric_fog_ambient_inject
		env.volumetric_fog_ambient_inject = INJECT
	else:
		env.volumetric_fog_ambient_inject = _inject_back
		_inject_back = -1.0


## The great door shut (its leaves across it, no way in) or open; never on the player still inside at 19:00: the
## sacristan waits for them to go out.
func _shut(on: bool) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if on and p != null and inside_hall(hall.to_local(p.global_position)):
		on = false
	for l in leaves:
		(l as Node3D).visible = on
	if bar != null:
		bar.collision_layer = 1 if on else 0


func _show(f: Figure, st) -> void:
	var on: bool = st != null
	f.root.visible = on
	if f.prop != null:
		f.prop.visible = on and not ((st as Array).size() > 4 and bool(st[4]))  # (serving the guest: the tea's own kettle in his hand)
	if not on:
		return
	var at: Vector3 = st[0]
	var way: Vector3 = st[1]
	f.root.global_transform = Transform3D(Basis(Vector3.UP, atan2(way.x, way.z)), at)  # (the rig faces +Z)
	if f.prop != null:
		var right := Vector3(way.z, 0.0, -way.x)
		f.prop.global_transform = Transform3D(Basis(Vector3.UP, atan2(way.x, way.z)), at - right * f.prop_at.x + Vector3.UP * f.prop_at.y + way * f.prop_at.z)
	var clip := String(st[2])
	if not f.ap.has_animation(clip):
		clip = "Idle_A"
	if clip != f.clip:
		f.ap.play(clip, 0.3)
		f.clip = clip
	f.ap.speed_scale = float(st[3])
