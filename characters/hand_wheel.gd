extends RefCounted
## A hand prayer wheel turning (ISS-124; chapter 05, 3.4): the body build's `wheel_r`, a bone under the right hand that no
## clip moves (../tibet-blender people2/body.py `hand_props`), turned about its length clockwise as seen from the drum's
## top, about 1.4 turns a second, its angle from the animation clock so a still shows it as the clock has it; and its
## whirr (SND-129) from the figure while the camera is near. For characters/named.gd's people and the crowd's near tier.

const BONE := "wheel_r"
const RATE := 1.4  ## turns a second
const HEARD := 7.0  ## metres: its whirr played within this of the camera


## [skeleton, bone] of a figure's wheel, or [] if it carries none.
static func of(root: Node) -> Array:
	var sks := root.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return []
	var sk := sks[0] as Skeleton3D
	var b := sk.find_bone(BONE)
	return [sk, b] if b >= 0 else []


## The wheel at time `t` (seconds of the animation clock), `phase` its own turn's offset (0-1); `sense` -1 turns it the
## other way (a Bön householder's: chapter 05, DS-03; world/tode_people.gd).
static func spin(w: Array, t: float, phase: float, sense := 1.0) -> void:
	(w[0] as Skeleton3D).set_bone_pose_rotation(int(w[1]), Quaternion(Vector3.UP, -TAU * sense * fposmod(RATE * t + phase, 1.0)))


## Its whirr: played while the figure is drawn within HEARD of `eye`, stopped otherwise (a player of its own on the figure,
## by the right hand).
static func whirr(root: Node3D, eye: Vector3) -> void:
	var near := root.visible and root.global_position.distance_to(eye) < HEARD
	var p := root.get_node_or_null("Whirr") as AudioStreamPlayer3D
	if not near:
		if p != null and p.playing:
			p.stop()
		return
	if p == null:
		var ad := root.get_node_or_null("/root/AudioDirector")
		var s: AudioStream = ad.call("stream", "SND-129") if ad != null else null
		if s == null:
			return
		p = AudioStreamPlayer3D.new()
		p.name = "Whirr"
		p.stream = s
		p.bus = &"Foley"
		p.unit_size = 0.6
		p.max_distance = HEARD
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.position = Vector3(0.25, 0.9, 0.1)  # by the right hand, about
		root.add_child(p)
	if not p.playing:
		p.play(randf() * 2.0)
