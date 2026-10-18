extends Node3D
## CV-02's pack mules and riding ponies (plan chapter 06, 8.4: "72 yak, 6 pack mules, 5 riding ponies and mules"; M2
## sprint 4, step 6): held at the south pavilion while the toll steward counts their loads, then led in file after the
## yak down Samkha's south ramp, over the lower cantilever bridge at about 15:16 (under a walker crossing the chain bridge
## at V-10, 20 m above them) and up the north ramp through the Yak Gate, where they go on into the town and out of sight.
## A muleteer leads the first mule. Placed on world/caravan.gd's way (the arrival's road, the south ramp, the lower deck,
## the north ramp), worked out from the clock's minute, so a still is the same each time. The mules are Mesh2Motion's
## horse as the yak are (../tibet-blender/people2/stand_ins.py `mules`), not made broad: dark, each its pack saddle and two
## tea cases; the ponies bay, dun and black, saddled, a rug under each saddle. `lead_s` and `shown` are pure, for the tests.

const MULE := "res://assets/generated/people/mule.glb"
const PONY := "res://assets/generated/people/pony.glb"
const LEADER := "res://assets/generated/people/porter.glb"
const PERSON := preload("res://characters/person.gdshader")
const DECK_AT := 916.0  ## 15:16: the first mule steps onto the lower bridge's deck from the slot's south side
const SPEED := 7.0  ## metres a game minute (0.7 m/s at the clock's 6:1)
const GAP := 3.0  ## metres from one animal's middle to the next
const MULES := 6
const PONIES := 3
const BEFORE := 30.0  ## metres before the south ramp's head where the string is first seen (by the south pavilion)
const BEYOND := 30.0  ## metres past the Yak Gate where it goes out of sight into the town
const WALK_CLIP := 0.9  ## m/s the horse's Walk clip plays at (its stride at the stand-in's scale)
const MULE_COATS := ["#4A4038", "#3E342C", "#5A4A3E", "#2E2824", "#4E443A", "#3A322C"]
const PONY_COATS := ["#6B4228", "#8A6A4A", "#2E2420"]

var way: PackedVector3Array
var cum: PackedFloat32Array
var from_s := 0.0  ## the stretch of the caravan's way the string is seen on
var to_s := 0.0
var deck_s := 0.0  ## the lower deck's south end along the way
var animals: Array = []  ## {root, ap, clip, offset}
var leader := {}


## The first mule's place along the way at minute `m` (metres), from its deck time.
static func lead_s(m: float, deck: float) -> float:
	return deck + (m - DECK_AT) * SPEED


## Whether an animal at `s` along the way is in sight (between the south ramp's foot of the road and past the Yak Gate).
static func shown(s: float, lo: float, hi: float) -> bool:
	return s >= lo and s <= hi


func setup(p_way: PackedVector3Array, p_cum: PackedFloat32Array, ramp_s: float, p_deck_s: float, gate_s: float) -> bool:
	if not ResourceLoader.exists(MULE) or not ResourceLoader.exists(PONY) or p_way.is_empty():
		return false
	way = p_way
	cum = p_cum
	deck_s = p_deck_s
	from_s = maxf(0.0, ramp_s - BEFORE)
	to_s = minf(cum[cum.size() - 1], gate_s + BEYOND)
	var wood := _mat("#6B4A2E")
	var hide_ := _mat("#8C7050")
	var lash := _mat("#3E3226")
	for k in MULES + PONIES:
		var pony := k >= MULES
		var fig: Node3D = (load(PONY if pony else MULE) as PackedScene).instantiate()
		var root := Node3D.new()
		root.name = "Pony%d" % (k - MULES) if pony else "Mule%d" % k
		add_child(root)
		root.add_child(fig)
		var coat := _mat(PONY_COATS[(k - MULES) % PONY_COATS.size()] if pony else MULE_COATS[k % MULE_COATS.size()])
		for mi in fig.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = coat
		var sk: Skeleton3D = fig.find_children("*", "Skeleton3D", true, false)[0]
		if not pony:  # a mule's long ears (bones the clips never move)
			for e in ["ear_1_r", "ear_1_l"]:
				var bi := sk.find_bone(e)
				if bi >= 0:
					sk.set_bone_pose_scale(bi, Vector3(1.25, 1.7, 1.25))
		var mid := _on_bone(fig, sk, "spine_2")
		var hk := 0.889 if pony else 0.944  # its back's height against the yak's (the horse at 0.64 and 0.68 against 0.72)
		if pony:  # a riding saddle on a rug
			var rug := _mat(["#8E2A22", "#2E4A6B", "#A2362C"][(k - MULES) % 3])
			_part(mid, _box(Vector3(0.62, 0.03, 0.8)), rug, Vector3(0.0, 1.0 * hk, 0.0))
			_part(mid, _box(Vector3(0.36, 0.14, 0.5)), _mat("#5A2A1E"), Vector3(0.0, 1.08 * hk, 0.0))
			_part(mid, _box(Vector3(0.3, 0.12, 0.08)), wood, Vector3(0.0, 1.18 * hk, 0.22))
		else:  # a pack saddle and two rawhide tea cases, lashed
			_part(mid, _box(Vector3(0.28, 0.1, 0.5)), wood, Vector3(0.0, 1.0 * hk, 0.0))
			for sx in [-1.0, 1.0]:
				_part(mid, _box(Vector3(0.22, 0.34, 0.58)), hide_, Vector3(sx * 0.24, 0.88 * hk, 0.0))
				_part(mid, _box(Vector3(0.23, 0.04, 0.6)), lash, Vector3(sx * 0.24, 0.96 * hk, 0.0))
		var ap: AnimationPlayer = fig.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Idle"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		for g in fig.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.visible = false
		animals.append({"root": root, "ap": ap, "clip": "", "offset": GAP * k + (1.5 if pony else 0.0)})
	if ResourceLoader.exists(LEADER):
		var lr: Node3D = (load(LEADER) as PackedScene).instantiate()
		lr.name = "Muleteer"
		var pm := ShaderMaterial.new()
		pm.shader = PERSON
		PersonLook.apply(lr, pm)
		add_child(lr)
		lr.visible = false
		var lap: AnimationPlayer = lr.find_children("*", "AnimationPlayer", true, false)[0]
		if lap.has_animation("Walk"):
			lap.get_animation("Walk").loop_mode = Animation.LOOP_LINEAR
		leader = {"root": lr, "ap": lap, "clip": ""}
	return true


func _process(_dt: float) -> void:
	if animals.is_empty():
		return
	var m := fposmod(WorldClock.minute, 1440.0)
	var frozen: bool = WorldClock.frozen
	var g: float = WorldClock.anim_time
	var s0 := lead_s(m, deck_s)
	for k in animals.size():
		var a: Dictionary = animals[k]
		var s := s0 - float(a["offset"])
		var root: Node3D = a["root"]
		root.visible = shown(s, from_s, to_s)
		if not root.visible:
			continue
		var p := _at(s)
		var d := _at(s + 0.6) - p
		root.position = p
		root.rotation.y = atan2(d.x, d.z) if Vector2(d.x, d.z).length() > 0.01 else root.rotation.y
		_play(a, "Walk", SPEED / 10.0 / WALK_CLIP * 1.2, frozen, g, k)
	if not leader.is_empty():
		var s := s0 + 1.7
		var lr: Node3D = leader["root"]
		lr.visible = shown(s, from_s, to_s)
		if lr.visible:
			var p := _at(s)
			var d := _at(s + 0.6) - p
			lr.position = p
			lr.rotation.y = atan2(d.x, d.z) if Vector2(d.x, d.z).length() > 0.01 else lr.rotation.y
			_play(leader, "Walk", 1.0, frozen, g, 11)


func _at(s: float) -> Vector3:
	s = clampf(s, 0.0, cum[cum.size() - 1])
	for i in range(1, way.size()):
		if s <= cum[i]:
			return way[i - 1].lerp(way[i], (s - cum[i - 1]) / maxf(cum[i] - cum[i - 1], 0.0001))
	return way[way.size() - 1]


func _play(a: Dictionary, clip: String, speed: float, frozen: bool, g: float, i: int) -> void:
	var ap: AnimationPlayer = a["ap"]
	if not ap.has_animation(clip):
		return
	if String(a["clip"]) != clip:
		ap.play(clip, 0.0)
		a["clip"] = clip
	if frozen:
		ap.speed_scale = 0.0
		ap.seek(fposmod(g * speed + i * 0.29, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = speed


func _mat(hex: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 1.0
	return m


static func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _part(parent: Node3D, mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
	return mi


## A holder that follows `bone`, in whose frame parts are placed in the model's own coordinates (world/caravan.gd's).
func _on_bone(fig: Node3D, sk: Skeleton3D, bone: String) -> Node3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	sk.add_child(ba)
	var holder := Node3D.new()
	ba.add_child(holder)
	var rest := sk.get_bone_global_rest(sk.find_bone(bone))
	holder.transform = rest.affine_inverse() * _rel(fig, sk).affine_inverse()
	return holder


static func _rel(top: Node3D, node: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != top:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t
