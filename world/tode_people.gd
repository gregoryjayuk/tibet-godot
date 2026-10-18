extends Node3D
## Tödé's people (M3 sprint 4, step 6; plan chapter 05's Tödé households, DS-03, A-06, A-44, A-45, A-47, NPC-10 and
## NPC-38), added by world/town.gd with the people: each one's day as tools/town/tode_days.py planned it from their own
## door along the field paths (data/tode_people.json): the Bön circuit round the chapel TOD-02 at dawn, anticlockwise, the
## wheels in its niches turned as they pass (in the group "kora_walkers": world/kora_wheels.gd, its sense -1); the
## threshers in a line at the four floors with their flails, neighbours striking alternately, the women winnowing from
## 13:00; two on each of four rammed-earth roofs; the millers by turns at their doors and by their stones; the water
## carriers at the leat; the traders and porters down the Tödé Stair to Shöl and back; two in the fields.
## - a walk follows its points at their minutes (on a flight, a segment rising more than STEEP in a metre, its steps' pace);
##   a stay holds its place and clip, `phase` seconds into it so a still shows neighbours' flails apart;
## - the flail: its handle gripped in the right hand, its angle the swing's own (the clip's Chop_Tree swings the right hand
##   from behind the head down to the front at the waist): over the shoulder when the hand is highest (RAISED), the
##   swingle hanging from its end, down to the floor ahead at the stroke (STRIKE), the swingle flat on the grain; drawn
##   only while threshing; a hand wheel's drum folded away meanwhile (Gyaltsen's), and his turning the other way
##   (characters/hand_wheel.gd, `sense`);
## - drawn while the camera is within SEEN of Tödé's middle, each figure within NEAR of the camera; Chödrön not after her
##   `full_moon` minute on the full moon (she is with her son at the Lookout: world/gorge_people.gd).
## `where` and `people` are for the tests.

const Town := preload("res://world/town.gd")
const HandWheel := preload("res://characters/hand_wheel.gd")
const PERSON := preload("res://characters/person.gdshader")
const DATA := "res://data/tode_people.json"
const CLIPS := "res://assets/generated/people/named_clips.json"
const MIDDLE := Vector2(-60.0, 450.0)  ## Tödé's middle, the town grid
const SEEN := 700.0  ## metres from it within which they are drawn
const NEAR := 260.0  ## and each within this of the camera
const PER_MIN := 10.0  ## real seconds a game minute at the play rate (world/gorge_people.gd)
const STEEP := 0.25  ## a segment rising or falling more than this in a metre is a flight
const STEP_ALONG := 0.345  ## metres along a flight's slope a step
const POLE := 1.6  ## the flail's handle, metres, gripped 0.15 m from its butt
const BEATER := 0.75  ## its swingle
const STRIKE := -38.0  ## degrees: the handle's angle to the level at the stroke, the hand at its lowest
const RAISED := 115.0  ## and over the shoulder, the hand at its highest
const HAND_LOW := 1.0  ## metres: the swing's right hand at the stroke and at the top (tode_man's, hips 0.92 m)
const HAND_HIGH := 1.52
const WOMEN_WALK := ["tode_woman", "tode_woman_b", "tode_woman_c", "tode_woman_d", "chodron_tode", "water_woman_b",
		"water_woman_c", "water_woman_d", "water_girl_b", "porter_woman", "townswoman_b"]
const BON := ["yungdrung_gyaltsen"]  ## whose hand wheel turns the other way (chapter 05, DS-03)
const LOOPED := ["Walk", "Walk_Female", "Walk_Carry", "Idle_A", "Idle_FoldArms", "Sitting_Idle", "Crouch_Idle", "Interact",
		"Chop_Tree", "Farm_Harvest"]

var people: Array = []  ## {key, kind, acts, full_moon, ...}: the day's
var _speeds := {}  ## body: {clip: its ground speed, m/s}
var _mid := Vector3.ZERO
var _mat: ShaderMaterial
var _wood: StandardMaterial3D
var _built := false
var _full := false
var _day := -1


static func _yaw_of(b: float) -> float:
	return atan2(sin(deg_to_rad(b)), -cos(deg_to_rad(b)))


## Reads the day (data/tode_people.json) into Godot's frame. The count of acts.
func build(_root: Node3D) -> int:
	if not FileAccess.file_exists(DATA):
		return 0
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	people = []
	var n := 0
	for p in d.get("people", []):
		var acts: Array = []
		for a in p["acts"]:
			if a.has("go"):
				var pts := PackedVector3Array()
				for q in a["go"]:
					pts.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
				var ts := PackedFloat32Array()
				for t in a["ts"]:
					ts.append(float(t))
				acts.append({"go": pts, "ts": ts, "kind": String(a.get("kind", "man")), "side": float(a.get("side", 0.0)),
						"kora": bool(a.get("kora", false)), "t0": ts[0], "t1": ts[ts.size() - 1]})
			else:
				var q: Array = a["stay"]
				acts.append({"stay": Town.to_godot(float(q[0]), float(q[1]), float(q[2])), "yaw": _yaw_of(float(a["facing"])),
						"clip": String(a["clip"]), "t0": float(a["t0"]), "t1": float(a["t1"]), "flail": bool(a.get("flail", false)),
						"phase": float(a.get("phase", 0.0))})
		acts.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["t0"]) < float(y["t0"]))
		n += acts.size()
		people.append({"key": String(p["key"]), "kind": String(p.get("kind", "man")), "acts": acts, "role": String(p.get("role", "")),
				"name": String(p.get("name", "")), "house": String(p.get("house", "")), "full_moon": float(p.get("full_moon", 1e9)),
				"flails": acts.any(func(a: Dictionary) -> bool: return bool(a.get("flail", false)))})
	_mid = Town.to_godot(MIDDLE.x, MIDDLE.y, 2900.0)
	if FileAccess.file_exists(CLIPS):
		var cl: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(CLIPS)) as Dictionary).get("bodies", {})
		for key in cl:
			var sp := {}
			for clip in cl[key]:
				if float((cl[key][clip] as Dictionary).get("speed", 0.0)) > 0.1:
					sp[clip] = float(cl[key][clip]["speed"])
			_speeds[key] = sp
	process_priority = 100  # (after the figures' AnimationPlayers: the flails follow this frame's pose)
	add_to_group("tode_people")
	return n


## Where `p` is at minute `m` of the day: [shown, position, yaw, clip, the clip's speed, the act or {}].
func where(p: Dictionary, m: float) -> Array:
	for a in p["acts"]:
		if m < float(a["t0"]) or m >= float(a["t1"]):
			continue
		if a.has("stay"):
			return [true, a["stay"], float(a["yaw"]), String(a["clip"]), 1.0, a]
		var pts: PackedVector3Array = a["go"]
		var ts: PackedFloat32Array = a["ts"]
		var i := ts.bsearch(m, true) - 1
		i = clampi(i, 0, pts.size() - 2)
		var dt := maxf(ts[i + 1] - ts[i], 0.0001)
		var f := clampf((m - ts[i]) / dt, 0.0, 1.0)
		var q := pts[i].lerp(pts[i + 1], f)
		var seg := pts[i + 1] - pts[i]
		var flat := Vector3(seg.x, 0.0, seg.z)
		var L := seg.length()
		var steep := L > 0.001 and absf(seg.y) / L > STEEP
		var dir := flat.normalized() if flat.length() > 0.001 else Vector3(0.0, 0.0, 1.0)
		var at := q + Vector3(-dir.z, 0.0, dir.x) * float(a["side"])
		var pace := L / (dt * PER_MIN)
		var key := String(p["key"])
		var sp: Dictionary = _speeds.get(key, {})
		var clip := "Walk_Carry" if String(a["kind"]) == "laden" else ("Walk_Female" if WOMEN_WALK.has(key) else "Walk")
		var speed := clampf(pace / STEP_ALONG / 1.2, 0.55, 1.4) if steep else clampf(pace / float(sp.get(clip, 0.74)), 0.6, 1.3)
		return [true, at, atan2(dir.x, dir.z), clip, speed, a]
	return [false, Vector3.ZERO, 0.0, "", 1.0, {}]


## Whether `p` is out at minute `m` (the tests).
func out_at(p: Dictionary, m: float) -> bool:
	return bool(where(p, m)[0])


## A flail: its handle along -z from the grip (the hand) and its swingle hinged at the handle's end, bent down.
func _flail() -> Node3D:
	var f := Node3D.new()
	f.name = "Flail"
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.016
	pm.bottom_radius = 0.02
	pm.height = POLE
	pm.radial_segments = 6
	pm.rings = 1
	pm.material = _wood
	pole.mesh = pm
	pole.rotation.x = -PI / 2.0
	pole.position = Vector3(0.0, 0.0, -(POLE / 2.0 - 0.15))
	f.add_child(pole)
	var hinge := Node3D.new()  # (its place and angle set each frame: _show)
	hinge.name = "Swingle"
	f.add_child(hinge)
	var beat := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.026
	bm.bottom_radius = 0.026
	bm.height = BEATER
	bm.radial_segments = 6
	bm.rings = 1
	bm.material = _wood
	beat.mesh = bm
	beat.rotation.x = -PI / 2.0
	beat.position = Vector3(0.0, 0.0, -BEATER / 2.0)
	hinge.add_child(beat)
	for mi in [pole, beat]:
		(mi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return f


func _bodies() -> void:
	_built = true
	_mat = ShaderMaterial.new()
	_mat.shader = PERSON
	_wood = StandardMaterial3D.new()
	_wood.albedo_color = Color(0.42, 0.33, 0.22)
	_wood.roughness = 0.9
	var i := 0
	for p in people:
		i += 1
		var path := "res://assets/generated/people/%s.glb" % p["key"]
		if not ResourceLoader.exists(path):
			continue
		var root: Node3D = (load(path) as PackedScene).instantiate()
		root.name = "Tode_%d_%s" % [i, String(p["key"])]
		PersonLook.apply(root, _mat)
		var ap: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		for n in LOOPED:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		var tint := 0.92 + 0.16 * fposmod(i * 0.618034, 1.0)  # a small tone shift each (characters/crowd.gd)
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			(mi as GeometryInstance3D).set_instance_shader_parameter("tint", tint)
		add_child(root)
		root.visible = false
		p["root"] = root
		p["ap"] = ap
		p["clip"] = ""
		p["i"] = i
		var sk: Skeleton3D = root.find_children("*", "Skeleton3D", true, false)[0]
		p["sk"] = sk
		p["wheel"] = HandWheel.of(root)
		if bool(p["flails"]):
			var fl := _flail()
			add_child(fl)
			fl.visible = false
			p["flail"] = fl
			p["hand"] = sk.find_bone("hand_r")
			var pel := sk.find_bone("pelvis")
			p["scale"] = clampf(sk.get_bone_global_rest(pel).origin.y / 0.92, 0.6, 1.3) if pel >= 0 else 1.0


func _process(_dt: float) -> void:
	if people.is_empty():
		return
	var cam := get_viewport().get_camera_3d()
	var on: bool = cam != null and Vector2(cam.global_position.x - _mid.x, cam.global_position.z - _mid.z).length() < SEEN
	if not on:
		if _built:
			for p in people:
				_hide(p)
		return
	if not _built:
		_bodies()
	var day := int(floor(WorldClock.minute / 1440.0))
	if day != _day:
		_day = day
		_full = int(Calendar.tibetan_date(WorldClock.minute).get("day", 0)) == 15
	var m := fposmod(WorldClock.minute, 1440.0)
	var frozen: bool = WorldClock.frozen
	var g: float = WorldClock.anim_time
	var eye := cam.global_position
	for p in people:
		if not p.has("root"):
			continue
		var r := where(p, m)
		if bool(r[0]) and _full and m >= float(p["full_moon"]):
			r[0] = false
		if bool(r[0]) and (r[1] as Vector3).distance_to(eye) > NEAR:
			r[0] = false
		_show(p, r, frozen, g)


func _hide(p: Dictionary) -> void:
	if p.has("root"):
		(p["root"] as Node3D).visible = false
		if (p["ap"] as AnimationPlayer).active:  # (not animated out of sight)
			(p["ap"] as AnimationPlayer).active = false
		if (p["root"] as Node3D).is_in_group("kora_walkers"):
			(p["root"] as Node3D).remove_from_group("kora_walkers")
	if p.has("flail"):
		(p["flail"] as Node3D).visible = false


func _show(p: Dictionary, r: Array, frozen: bool, g: float) -> void:
	var root: Node3D = p["root"]
	if not bool(r[0]):
		_hide(p)
		return
	root.visible = true
	root.global_position = r[1]
	root.rotation.y = float(r[2])
	var a: Dictionary = r[5]
	var kora := bool(a.get("kora", false))
	if kora and not root.is_in_group("kora_walkers"):
		root.add_to_group("kora_walkers")
	elif not kora and root.is_in_group("kora_walkers"):
		root.remove_from_group("kora_walkers")
	var ap: AnimationPlayer = p["ap"]
	if not ap.active:
		ap.active = true
	var clip := String(r[3])
	if not ap.has_animation(clip):
		clip = "Walk" if clip.begins_with("Walk") and ap.has_animation("Walk") else "Idle_A"
	if String(p["clip"]) != clip:
		ap.play(clip, 0.0 if frozen or String(p["clip"]) == "" else 0.3)
		p["clip"] = clip
	var phase := float(a.get("phase", int(p["i"]) * 0.37))
	if frozen:  # the stills: the pose from the animation clock
		ap.speed_scale = 0.0
		ap.seek(fposmod(g * float(r[4]) + phase, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = float(r[4])
	var threshing := bool(a.get("flail", false))
	var w: Array = p["wheel"]
	if not w.is_empty():  # a hand wheel turns as its bearer walks or stands, folded away while the hands hold a flail
		var sk := w[0] as Skeleton3D
		sk.set_bone_pose_scale(int(w[1]), Vector3.ONE * (0.001 if threshing else 1.0))
		if not threshing:
			HandWheel.spin(w, g, fposmod(int(p["i"]) * 0.29, 1.0), -1.0 if BON.has(String(p["key"])) else 1.0)
	if p.has("flail"):
		var fl: Node3D = p["flail"]
		fl.visible = threshing
		if threshing:
			var sk: Skeleton3D = p["sk"]
			if frozen:
				sk.force_update_all_bone_transforms()
			var hand := (sk.global_transform * sk.get_bone_global_pose(int(p["hand"]))).origin
			var s := clampf(((hand.y - root.global_position.y) / float(p["scale"]) - HAND_LOW) / (HAND_HIGH - HAND_LOW), 0.0, 1.0)
			var phi := deg_to_rad(lerpf(STRIKE, RAISED, s))
			var fwd := root.global_transform.basis.z.normalized()  # (the figure faces its +z; its right hand at its -x)
			var right := -root.global_transform.basis.x.normalized()
			var dir := (fwd * cos(phi) + Vector3.UP * sin(phi) + right * 0.12).normalized()
			fl.global_transform = Transform3D(Basis.looking_at(dir, right.cross(dir).normalized()), hand)
			var tip := hand + dir * (POLE - 0.15)
			var bd := (fwd * (1.0 - s) + Vector3.DOWN * (0.2 + s)).normalized()  # flat on the floor at the stroke, hanging raised
			(fl.get_node("Swingle") as Node3D).global_transform = Transform3D(Basis.looking_at(bd, right.cross(bd).normalized()), tip)
