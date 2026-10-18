extends SkeletonModifier3D
## Feet on the treads (plan chapter 11, 13.2; M1 sprint 3, step 3; ISS-035). On a flight the capsule glides on the kit's
## ramp through the nosings, up to a rise (19 cm) over the treads, so the walk's feet would float over the steps. This
## modifier runs before the legs' two-bone IK (a TwoBoneIK3D, the next child of the skeleton): it lowers the pelvis by
## the larger of the two feet's drops to their treads and sets each ankle's target on its own tread, keeping the height
## the walk lifts it by, with the knee's pole ahead of the knee; off the stairs it eases out.
## `tread` answers the tread's height under a point (world space), or NAN off a flight (player/player.gd).

const FEET := [["thigh_l", "calf_l", "foot_l", "ball_l"], ["thigh_r", "calf_r", "foot_r", "ball_r"]]
const PELVIS := "pelvis"
const EASE := 10.0  ## per second: how fast the drop and the IK's weight follow

var tread: Callable
var ik: TwoBoneIK3D
var drop := 0.0  ## the pelvis's drop now (metres), eased
var weight := 0.0  ## the IK's influence now, eased
var _targets: Array[Node3D] = []
var _poles: Array[Node3D] = []
var _bones := []  ## per foot: [thigh, calf, foot, ball]
var _pelvis := -1
var _ankle_h := 0.1  ## the ankle over the sole, from the rest pose


## Builds the IK beside this modifier under `sk`, after it (modifiers run in child order).
func setup(sk: Skeleton3D) -> void:
	name = "Feet"
	sk.add_child(self)
	ik = TwoBoneIK3D.new()
	ik.name = "LegsIK"
	sk.add_child(ik)
	ik.setting_count = 2
	_pelvis = sk.find_bone(PELVIS)
	for i in 2:
		var b := []
		for n in FEET[i]:
			b.append(sk.find_bone(n))
		_bones.append(b)
		var t := Node3D.new()
		t.name = "Target%d" % i
		t.top_level = true
		ik.add_child(t)
		_targets.append(t)
		var p := Node3D.new()
		p.name = "Pole%d" % i
		p.top_level = true
		ik.add_child(p)
		_poles.append(p)
		ik.set_root_bone_name(i, FEET[i][0])
		ik.set_middle_bone_name(i, FEET[i][1])
		ik.set_end_bone_name(i, FEET[i][2])
		ik.set_target_node(i, ik.get_path_to(t))
		ik.set_pole_node(i, ik.get_path_to(p))
	ik.influence = 0.0
	var root_rest := sk.get_bone_global_rest(0).origin
	_ankle_h = absf((sk.global_transform.basis * (sk.get_bone_global_rest(_bones[0][2]).origin - root_rest)).y)


func _process_modification_with_delta(delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or _pelvis < 0 or ik == null:
		return
	var st := sk.global_transform
	var base := st * sk.get_bone_global_pose(0).origin  # the body's feet level: the rig's root
	var ground := [NAN, NAN]
	var lift := [0.0, 0.0]
	var want := -INF
	if tread.is_valid():
		for i in 2:
			var ankle: Vector3 = st * sk.get_bone_global_pose(_bones[i][2]).origin
			var ball: Vector3 = st * sk.get_bone_global_pose(_bones[i][3]).origin
			var g := maxf(float(tread.call(ankle)), float(tread.call(ball)))  # the foot rests on the higher of the treads under it
			if is_nan(g):
				want = -INF
				break
			ground[i] = g
			lift[i] = maxf(0.0, ankle.y - base.y - _ankle_h)
			want = maxf(want, base.y - g)
	var on := want > -INF
	var k := 1.0 - exp(-EASE * delta)
	weight = lerpf(weight, 1.0 if on else 0.0, k)
	drop = lerpf(drop, clampf(want, -0.1, 0.3) if on else 0.0, k)
	ik.influence = weight
	if absf(drop) > 0.001:
		var pelvis_g: Vector3 = st * sk.get_bone_global_pose(_pelvis).origin
		var parent := sk.get_bone_parent(_pelvis)
		var parent_g: Transform3D = st * (sk.get_bone_global_pose(parent) if parent >= 0 else Transform3D())
		sk.set_bone_pose_position(_pelvis, parent_g.affine_inverse() * (pelvis_g - Vector3(0.0, drop, 0.0)))
	if weight < 0.01:
		return
	var fwd := Vector3.ZERO  # the way the feet point, ankle to ball: the knees bend that way
	for i in 2:
		fwd += st * sk.get_bone_global_pose(_bones[i][3]).origin - st * sk.get_bone_global_pose(_bones[i][2]).origin
	fwd.y = 0.0
	fwd = fwd.normalized()
	for i in 2:
		var ankle: Vector3 = st * sk.get_bone_global_pose(_bones[i][2]).origin
		var knee: Vector3 = st * sk.get_bone_global_pose(_bones[i][1]).origin
		var g: float = ground[i] if not is_nan(ground[i]) else ankle.y - _ankle_h
		_targets[i].global_position = Vector3(ankle.x, g + _ankle_h + lift[i], ankle.z)
		_poles[i].global_position = knee + fwd * 0.6
