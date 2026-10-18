extends Node3D
## The dawn and dusk horns' players on the Tsokchen's rear block (plan chapter 08, V-05a: "two monks are extending the
## telescoping horns", "the two horn players in maroon with the yellow crested hats of assembly, the dung chen 3 m long
## resting on the parapet, bells towards the town"; the game's M3 sprint 6, step 5): at the hall's two HORN sockets
## (tibet-blender kit/monastery.py tsokchen, by the west parapet of its roof terrace MON-40) a monk stands from 05:25 to
## 07:05 and from 17:10 to 17:25 in the yellow crested hat, the kit's dungchen before him from his hands across the
## parapet's top, its bell to the town. A few seconds before each call (data/sound.json's schedule: SND-103 at 05:30,
## SND-104 at 17:15, marked placeholders until Greg's recordings and consent) he lifts the mouthpiece to his lips, blows
## for the call's length and lowers it again: both hands on the horn (a TwoBoneIK3D on each arm, the body's own idle
## under them), a stand-in until Greg's motion takes. The call comes back off the western ridge about 27 s later
## (autoload/audio/sound.gd's echo). A novice waits on the roof by the head of the hall's ladder-stair from 05:20 to 05:45
## (chapter 08: "a novice leads the player up the ladder-stair onto the roof in the dark"). Drawn while the camera is
## near; added by world/town.gd.

const BODIES := ["tode_monk", "tode_monk_b"]
const NOVICE := "novice"
const BODY := "res://assets/generated/people/%s.glb"
const HORN := "res://assets/generated/kit/types/dungchen_v1.glb"
const HOURS := [[325.0, 425.0], [1030.0, 1045.0]]  ## 05:25-07:05 and 17:10-17:25, minutes of the day
const CALLS := [330.0, 1035.0]  ## the calls' minutes (data/sound.json's schedule)
const BLOW := 3.7  ## game minutes a call is blown: the placeholder's 36.5 s at the clock's 6:1
const LIFT := 0.3  ## game minutes to lift the mouthpiece to the lips, and to lower it (3 s)
const NOVICE_HOURS := [320.0, 345.0]  ## 05:20-05:45: the novice by the ladder-stair's head
const MOUTH := Vector3(0.0, 1.6, -0.12)  ## a standing monk's lips over his feet, in his socket's frame (Godot: -z ahead)
const HELD := Vector3(0.05, 1.1, -0.3)  ## the mouthpiece in his hands at his waist, between the calls
const SUPPORT := Vector3(0.0, 0.6, -2.95)  ## where the horn lies across the parapet's top, ahead of him
const LENGTH := 3.0  ## the kit's dungchen, mouthpiece to bell
const GRIP := [0.34, 0.78]  ## his right and left hands this far along the horn from its mouthpiece
const SEEN := 400.0  ## metres: drawn while the camera is this near
const HAT := Color(0.93, 0.71, 0.15)  ## the assembly's yellow crested hat (design)

var players: Array = []  ## {socket, body, ap, horn, grips: [right, left], poles: [right, left], ik}
var novice: Node3D
var _novice_at := Transform3D.IDENTITY
var _shown := -1
var _t := 0.0


## At the hall's HORN sockets: the players, their hats and horns; the novice by the ladder-stair's head. The count.
func build(root: Node3D) -> int:
	var hall := root.get_node_or_null("MON-01") as Node3D
	if hall == null:
		return 0
	var socks := hall.find_children("SOCK_HORN_*", "Node3D", true, false)
	socks.sort_custom(func(a, b): return String(a.name) < String(b.name))
	for k in socks.size():
		var body := _body(BODIES[k % BODIES.size()], "HornPlayer%d" % (k + 1))
		if body == null:
			continue
		_hat(body)
		var pl := {"socket": socks[k], "body": body, "ap": body.find_children("*", "AnimationPlayer", true, false)[0],
				"horn": null, "grips": [], "poles": [], "ik": null}
		if ResourceLoader.exists(HORN):
			var h: Node3D = (load(HORN) as PackedScene).instantiate()
			h.visible = false
			add_child(h)
			pl["horn"] = h
		for side in 2:
			var g := Node3D.new()
			add_child(g)
			(pl["grips"] as Array).append(g)
			var e := Node3D.new()
			add_child(e)
			(pl["poles"] as Array).append(e)
		pl["ik"] = _ik(body, pl["grips"], pl["poles"])
		players.append(pl)
	var top := hall.find_child("SOCK_LADTOP_1", true, false) as Node3D
	if top != null and not players.is_empty():
		novice = _body(NOVICE, "HornNovice")
		if novice != null:
			# on the roof 0.9 m in from the ladder's head (the kit's +y, Godot's -z of the hall), turned to the players
			var at := top.global_position + hall.global_basis * Vector3(0.0, -0.45, -0.9)
			var to: Vector3 = (players[0]["socket"] as Node3D).global_position - at
			_novice_at = Transform3D(Basis(Vector3.UP, atan2(to.x, to.z)), at)
	return players.size()


## A body as world/hall_day.gd draws its people: the person shader, its idle looping, hidden until its hour.
func _body(name_: String, node_name: String) -> Node3D:
	if not ResourceLoader.exists(BODY % name_):
		return null
	var b: Node3D = (load(BODY % name_) as PackedScene).instantiate()
	b.name = node_name
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://characters/person.gdshader")
	PersonLook.apply(b, mat)
	b.top_level = true
	b.visible = false
	add_child(b)
	var ap := b.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	if ap.has_animation("Idle_A"):
		ap.get_animation("Idle_A").loop_mode = Animation.LOOP_LINEAR
		ap.play("Idle_A")
	return b


## The yellow crested hat: a half-disc of wool from brow to nape over the crown, on the head bone.
func _hat(body: Node3D) -> void:
	var sk := body.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	if sk.find_bone("head") < 0:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = "head"
	sk.add_child(att)
	var crest := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.15
	cm.bottom_radius = 0.15
	cm.height = 0.07
	cm.radial_segments = 20
	var m := StandardMaterial3D.new()
	m.albedo_color = HAT
	m.roughness = 0.95
	cm.material = m
	crest.mesh = cm
	crest.rotation.z = PI / 2.0  # its axis across the head: the disc stands from brow to nape
	crest.position = Vector3(0.0, 0.13, -0.01)
	att.add_child(crest)
	var band := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.105
	bm.bottom_radius = 0.112
	bm.height = 0.05
	bm.radial_segments = 16
	bm.material = m
	band.mesh = bm
	band.position = Vector3(0.0, 0.13, 0.0)
	att.add_child(band)


## Both arms reaching for the horn: a TwoBoneIK3D on the skeleton, the right arm's setting 0 and the left's 1.
func _ik(body: Node3D, grips: Array, poles: Array) -> Node:
	var sk := body.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	if sk.find_bone("hand_r") < 0 or sk.find_bone("hand_l") < 0:
		return null
	var ik := TwoBoneIK3D.new()
	ik.name = "HornIK"
	ik.set_setting_count(2)
	for k in 2:
		var s := "r" if k == 0 else "l"
		ik.set_root_bone_name(k, "upperarm_" + s)
		ik.set_middle_bone_name(k, "lowerarm_" + s)
		ik.set_end_bone_name(k, "hand_" + s)
	ik.set_mutable_bone_axes(true)  # (without it the solve leaves the arms as the clip has them: world/tea.gd)
	sk.add_child(ik)
	for k in 2:
		ik.set_target_node(k, ik.get_path_to(grips[k]))
		ik.set_pole_node(k, ik.get_path_to(poles[k]))
	return ik


## Whether the horns are out at `minute` of the day.
static func out_at(minute: float) -> bool:
	var m := fposmod(minute, 1440.0)
	for h in HOURS:
		if m >= float(h[0]) and m < float(h[1]):
			return true
	return false


## How far the mouthpiece is lifted at `minute` of the day: 0 at the waist, 1 at the lips (the calls' few seconds' lift
## before their minute, their length blown, the lowering after).
static func lift_at(minute: float) -> float:
	var m := fposmod(minute, 1440.0)
	for c in CALLS:
		var t := m - float(c)
		if t >= -LIFT and t < 0.0:
			return smoothstep(-LIFT, 0.0, t)
		if t >= 0.0 and t < BLOW:
			return 1.0
		if t >= BLOW and t < BLOW + LIFT:
			return 1.0 - smoothstep(BLOW, BLOW + LIFT, t)
	return 0.0


## Where a player's horn lies, in his socket's frame (Godot): from its mouthpiece, at his lips as lifted or at his waist,
## across the parapet's top to its bell 3 m on. [mouthpiece, bell]
static func horn_line(s: Transform3D, lift: float = 1.0) -> Array:
	var mouth := s * HELD.lerp(MOUTH, lift)
	var way := ((s * SUPPORT) - mouth).normalized()
	return [mouth, mouth + way * LENGTH]


func _process(dt: float) -> void:
	_t -= dt
	var cam := get_viewport().get_camera_3d()
	var on := 1 if out_at(WorldClock.minute) and cam != null and not players.is_empty() \
			and cam.global_position.distance_to((players[0]["socket"] as Node3D).global_position) < SEEN else 0
	var lift := lift_at(WorldClock.minute)
	var moving := lift > 0.0 and lift < 1.0
	if on == _shown and not moving and _t > 0.0:
		return
	_t = 0.5
	_shown = on
	for pl in players:
		var st := (pl["socket"] as Node3D).global_transform.orthonormalized()
		var body: Node3D = pl["body"]
		body.visible = on == 1
		var horn: Node3D = pl["horn"]
		if horn != null:
			horn.visible = on == 1
		if on == 0:
			continue
		var f := -st.basis.z  # (he faces his socket's +y, Godot's -z)
		body.global_transform = Transform3D(Basis(Vector3.UP, atan2(f.x, f.z)), st.origin)  # (the rig faces +Z)
		var line := horn_line(st, lift)
		var a: Vector3 = line[0]
		var x: Vector3 = ((line[1] as Vector3) - a).normalized()
		var z := x.cross(Vector3.UP).normalized()
		if horn != null:
			horn.global_transform = Transform3D(Basis(x, z.cross(x), z), a)
		var right := f.cross(Vector3.UP).normalized()
		for k in 2:
			(pl["grips"][k] as Node3D).global_position = a + x * float(GRIP[k])
			var side := right if k == 0 else -right
			(pl["poles"][k] as Node3D).global_position = st.origin + side * 0.7 + Vector3(0.0, 0.9, 0.0) - f * 0.2
	if novice != null:
		var m := fposmod(WorldClock.minute, 1440.0)
		novice.visible = cam != null and cam.global_position.distance_to(_novice_at.origin) < SEEN \
				and m >= float(NOVICE_HOURS[0]) and m < float(NOVICE_HOURS[1])
		novice.global_transform = _novice_at
