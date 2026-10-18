extends Node
## Fighting (plan chapter 11, 13.8; chapter 14, 3; spike S19), one component for anyone who fights: the player and
## the practice partner use the same rules. Greg chose a real fighting system, fists first, then the period's weapons,
## the sling above all (25 Sep 2026, 20:14).
##
## Strikes are the rig's CC0 clips (Mesh2Motion); each strike's hand reaches furthest at a moment the body build
## measured (assets/generated/people/player_clips.json, "hit"), and the hit is tested in a window round it: the path
## the fist swept since the last frame against the target's body (a segment from the hips to the head), so a slow
## frame cannot carry a fist through a man untouched. A guard facing the
## blow turns it; three unanswered blows knock a fighter down, and they get up again: nobody dies (chapter 14, 3:
## "the player is not killed"). Balance comes back a point every few seconds without a blow, and a stagger can be cut
## short by a blow or a dodge of one's own. No health bar: the body shows it.
## The sling: hold to whirl (the rig holds the overhand throw with the hand at its highest while a cord and stone
## circle over the head), let
## go to loose; the stone leaves at the throw's measured release, faster the longer it whirled (12 to 28 m/s), towards
## the point under the camera's aim, and flies as a Jolt body (props/sling_stone.gd).

const CLIPS := "res://assets/generated/people/player_clips.json"
const STONE := preload("res://props/sling_stone.gd")
const STRIKES := ["Fighting_Left_Jab", "Fighting_Right_Jab"]
const EARLY := 0.07  ## seconds before the measured moment in which a strike can land
const LATE := 0.12  ## and after it: the pose trails the clock by a frame, and each clip blends in over 0.08 s
const REACH := 0.38  ## metres from the wrist to the target's body line that count as a hit
const CLOSE := 0.8  ## the distance a strike closes to: the left jab reaches 0.66 m forward, the right 0.78 m
const DODGE := 0.7  ## the part of a dodge in which blows miss
const TILT := 12.0  ## degrees the whirl's plane rises towards the front
const RECOVER := 3.0  ## seconds without a blow for a point of balance back

var fighter: CharacterBody3D  ## the owner: has `facing`, `body`, `anim`, and forwards take_hit() here
var sling := false  ## the sling in hand instead of fists
var action := ""  ## the clip being played for a fight move ("" when the owner walks and idles as usual)
var t := 0.0
var length := 0.0
var hit_at := -1.0
var hit_done := false
var hand := "r"
var guard := false  ## blocking (fists) or aiming (the sling)
var whirl := 0.0  ## seconds the sling has whirled; 0 when not
var raised_until := 0.0  ## the fists stay up a few seconds after a strike
var balance := 3  ## unanswered blows before going down
var cooldown := 0.0
var aim_point := Vector3.ZERO  ## where the sling aims, set by the owner (the player's camera, or the partner's target)
var times := {}
var debug := false  ## print each strike's reach at its moment (tests)
var _next_left := true
var _mark: Node  ## the fighter a strike is aimed at, which it steps in towards
var _last_fist := Vector3.INF  ## where the striking hand was on the frame before
var _last_blow := 0.0  ## when a blow last landed on this fighter
var _then := ""  ## the clip that follows the current one (getting up after a fall)
var _sling_node: Node3D
var _released := false


func _ready() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(CLIPS)) if FileAccess.file_exists(CLIPS) else null
	if d != null:
		times = d["bodies"]["player_man"]
	add_to_group("fighting")


func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(_dt: float) -> void:
	if balance < 3 and now() - _last_blow > RECOVER:
		balance += 1
		_last_blow = now()


## Whether this component drives the body's clip now (a move, the whirl), so the owner's walking clips wait.
func owns_clip() -> bool:
	return action != "" or whirl > 0.0


## The fists up: after a strike, or while guarding.
func guard_up() -> bool:
	return not sling and (guard or now() < raised_until)


## How much of the owner's walking speed a move allows.
func move_scale() -> float:
	if action in ["Hit_Knockback", "LayToIdle", "OverhandThrow"] or action in STRIKES or whirl > 0.0:
		return 0.0
	if action.begins_with("Dodge") or action.begins_with("Hit"):
		return 0.0
	return 0.45 if guard else 1.0


func busy() -> bool:
	if action in STRIKES and t > length * 0.6:  # a strike's last part can be cut by the next
		return false
	if action.begins_with("Hit_") and action != "Hit_Knockback" and t > length * 0.5:  # and a stagger's second half
		return false
	return action != ""


## A strike with the alternate hand, turned towards the nearest fighter within reach.
func strike() -> void:
	if sling or busy() or cooldown > 0.0 or fighter.body == null:
		return
	var clip: String = STRIKES[0] if _next_left else STRIKES[1]
	_next_left = not _next_left
	_mark = nearest(2.2)
	if _mark != null:
		var to: Vector3 = _mark.fighter.global_position - fighter.global_position
		fighter.facing = atan2(-to.x, -to.z)
	_play(clip)
	hit_at = float(times.get(clip, {}).get("hit", 0.35))
	hand = String(times.get(clip, {}).get("hand", "r"))
	hit_done = false
	_last_fist = Vector3.INF
	raised_until = now() + 3.0
	cooldown = 0.25


func dodge(dir: String) -> void:
	if busy() or fighter.body == null:
		return
	_play("Dodge_" + dir)


func start_whirl() -> void:
	if not sling or busy() or whirl > 0.0:
		return
	whirl = 0.001
	_released = false
	_show_sling(true)


func release() -> void:
	if whirl <= 0.0:
		return
	var spun := whirl
	whirl = 0.0
	_play("OverhandThrow")
	var wind := float(times.get("OverhandThrow", {}).get("windup", 0.25))
	t = wind
	fighter.anim.seek(wind, true)
	hit_at = float(times.get("OverhandThrow", {}).get("release", 0.35))
	hit_done = false
	_released = false
	set_meta("speed", lerpf(12.0, 28.0, clampf((spun - 0.3) / 0.7, 0.0, 1.0)))


## A blow landing on this fighter; `from` is the striker's position. Returns true if it was turned by the guard or
## dodged: a dodge moves the body in its clip but not the capsule the blows are tested against, so for most of the
## dodge (DODGE of its length) blows find nothing.
func take_hit(from: Vector3, head: bool, power := 1.0) -> bool:
	if action == "Hit_Knockback" or action == "LayToIdle":
		return false
	if action.begins_with("Dodge") and t < length * DODGE:
		return true
	var to_striker := from - fighter.global_position
	var fwd := Vector3(-sin(fighter.facing), 0.0, -cos(fighter.facing))
	if guard and not sling and fwd.dot(to_striker.normalized()) > 0.3:
		_play("Defend")
		_sound("SND-610.block")
		return true
	whirl = 0.0
	_show_sling(false)
	_last_blow = now()
	balance -= int(ceil(power))
	if balance <= 0:
		balance = 3
		_play("Hit_Knockback")
		_then = "LayToIdle"
		_sound("SND-610.punch_heavy")
	else:
		_play("Hit_Head" if head else "Hit_Chest")
		_sound("SND-610.punch")
	return false


## A blow's sound where it lands (Kenney's CC0 impacts, through the AudioDirector; sprint 8, step 4).
func _sound(id: String) -> void:
	var ad: Node = fighter.get_node_or_null("/root/AudioDirector") if fighter != null else null
	if ad != null:
		ad.call("play", id, fighter.global_position + Vector3(0.0, 1.3, 0.0))


## The distance from a fist's path this frame, `p` to `q`, to this fighter's body line from the hips to the head.
func gap(p: Vector3, q: Vector3) -> float:
	var a := fighter.global_position + Vector3(0, 0.85, 0)
	var b := fighter.global_position + Vector3(0, 1.65, 0)
	if p.is_equal_approx(q):
		return Geometry3D.get_closest_point_to_segment(p, a, b).distance_to(p)
	var c := Geometry3D.get_closest_points_between_segments(p, q, a, b)
	return c[0].distance_to(c[1])


func hand_position(which: String) -> Vector3:
	var sk: Skeleton3D = fighter.body.find_children("*", "Skeleton3D", true, false)[0] if fighter.body != null else null
	if sk == null:
		return fighter.global_position + Vector3(0, 1.4, 0)
	var i := sk.find_bone("hand_" + which)
	return sk.global_transform * sk.get_bone_global_pose(i).origin


func _play(clip: String) -> void:
	action = clip
	t = 0.0
	length = fighter.anim.get_animation(clip).length if fighter.anim.has_animation(clip) else 0.6
	fighter.anim.play(clip, 0.08)
	fighter.anim.speed_scale = 1.0
	fighter._clip = clip


## The nearest other fighter within `reach` metres, or null.
func nearest(reach: float) -> Node:
	var best: Node = null
	var bd := reach
	for f in get_tree().get_nodes_in_group("fighting"):
		if f == self:
			continue
		var d: float = (f.fighter.global_position - fighter.global_position).length()
		if d < bd:
			bd = d
			best = f
	return best


## The step into a strike: towards the fighter it is aimed at, until arm's length, before the fist lands; the owner's
## physics uses it in place of its walking velocity.
func lunge_velocity() -> Vector3:
	if not (action in STRIKES) or _mark == null or t >= hit_at:
		return Vector3.ZERO
	var to: Vector3 = _mark.fighter.global_position - fighter.global_position
	to.y = 0.0
	var d := to.length()
	if d <= CLOSE:
		return Vector3.ZERO
	return to / d * minf(3.5, (d - CLOSE) / maxf(hit_at - t, 0.05))


## Every frame while owns_clip(): play the move, land its blow, loose the stone, and hand the body back when done.
func drive(dt: float) -> void:
	cooldown = maxf(0.0, cooldown - dt)
	if whirl > 0.0:
		whirl += dt
		var wind := float(times.get("OverhandThrow", {}).get("windup", 0.25))
		if fighter._clip != "OverhandThrow":
			fighter.anim.play("OverhandThrow", 0.1)
			fighter._clip = "OverhandThrow"
		# held by seeking back each frame, not by speed 0: the cross-fade into the throw runs on the clip's clock, and
		# frozen it never ends, which left the body in its guard with the whirl through the chest
		fighter.anim.speed_scale = 1.0
		fighter.anim.seek(wind, true)
		_spin_sling(dt)
		return
	if action == "":
		return
	t += dt
	if action in STRIKES and not hit_done:
		var fist := hand_position(hand)
		var was := fist if _last_fist == Vector3.INF else _last_fist
		_last_fist = fist
		if t > hit_at - EARLY and t < hit_at + LATE:
			for f in get_tree().get_nodes_in_group("fighting"):
				if f == self:
					continue
				var g: float = f.gap(was, fist)
				if debug:
					print("fighting: %s t %.2f apart %.2f fist-to-body %.2f" % [action, t, f.fighter.global_position.distance_to(fighter.global_position), g])
				if g < REACH:
					var turned: bool = f.take_hit(fighter.global_position, fist.y > f.fighter.global_position.y + 1.4)
					hit_done = true
					if not turned and fighter.has_method("landed"):
						fighter.landed()
					break
	if action == "OverhandThrow" and not _released and t >= hit_at:
		_released = true
		_loose_stone()
		_show_sling(false)
	if t >= length:
		if _then != "":
			var nxt := _then
			_then = ""
			_play(nxt)
			return
		action = ""
		fighter._clip = ""


func _loose_stone() -> void:
	var from := hand_position("r") + Vector3(0, 0.15, 0)
	var speed: float = get_meta("speed", 20.0)
	var stone := RigidBody3D.new()
	stone.set_script(STONE)
	fighter.get_parent().add_child(stone)
	stone.global_position = from
	stone.add_collision_exception_with(fighter)
	var target := aim_point if aim_point != Vector3.ZERO else from + Vector3(-sin(fighter.facing), 0.0, -cos(fighter.facing)) * 20.0
	stone.linear_velocity = STONE.launch(from, target, speed)
	stone.thrower = fighter
	stone.debug = debug
	if debug:
		print("fighting: stone from %s to %s at %.1f m/s, velocity %s" % [from, target, speed, stone.linear_velocity])


# ------------------------------------------------------------------ the sling's cord and stone, whirling at the hand
func _show_sling(on: bool) -> void:
	if on and _sling_node == null and fighter.body != null:
		_sling_node = Node3D.new()  # the whirl's plane, over the hand, tilted and turned with the fighter
		var spin := Node3D.new()  # the cord and stone going round in it
		spin.name = "Spin"
		_sling_node.add_child(spin)
		var cord := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.006
		cm.bottom_radius = 0.006
		cm.height = 0.7
		cm.radial_segments = 4
		cord.mesh = cm
		cord.rotation.z = PI / 2
		cord.position.x = 0.35
		cord.name = "Cord"
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color("#8a6a3e")
		cord.material_override = cmat
		spin.add_child(cord)
		var st := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.04
		sm.height = 0.08
		sm.radial_segments = 8
		sm.rings = 4
		st.mesh = sm
		st.position.x = 0.7
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color("#6f6961")
		st.material_override = smat
		spin.add_child(st)
		# the blur of the whirl: a faint disc swept by the cord, darker where the stone runs, so a still reads as
		# whirling and not as a stick; it thickens as the sling speeds up
		var disc := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(1.5, 1.5)
		disc.mesh = pm
		var dmat := ShaderMaterial.new()
		dmat.shader = _blur_shader()
		disc.material_override = dmat
		disc.name = "Blur"
		_sling_node.add_child(disc)
		fighter.get_parent().add_child(_sling_node)
	if _sling_node != null:
		_sling_node.visible = on
		if not on:
			_sling_node.queue_free()
			_sling_node = null


func _spin_sling(dt: float) -> void:
	if _sling_node == null:
		_show_sling(true)
	if _sling_node == null:
		return
	var rate := lerpf(1.5, 4.0, clampf(whirl / 0.8, 0.0, 1.0))  # turns a second, building up
	var tilt := Basis(Vector3.UP, fighter.facing) * Basis(Vector3.RIGHT, deg_to_rad(TILT))
	_sling_node.global_transform = Transform3D(tilt, hand_position("r") + Vector3(0, 0.12, 0))
	var spin := _sling_node.get_node("Spin") as Node3D
	spin.rotation.y += TAU * rate * dt
	var blur := _sling_node.get_node_or_null("Blur") as GeometryInstance3D
	if blur != null:
		blur.transparency = 1.0 - clampf((rate - 1.5) / 2.5, 0.0, 1.0)
	var cord := _sling_node.get_node_or_null("Spin/Cord") as GeometryInstance3D
	if cord != null:  # at full speed the cord is a blur the eye cannot hold: only the stone and the disc remain
		cord.transparency = clampf((rate - 2.0) / 2.0, 0.0, 0.6)


static var _blur: Shader


static func _blur_shader() -> Shader:
	if _blur == null:
		_blur = Shader.new()
		_blur.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
void fragment() {
	float r = length(UV - 0.5) * 2.0;  // 1.0 at 0.75 m; the stone runs at 0.7 m
	float ring = smoothstep(0.84, 0.92, r) * (1.0 - smoothstep(0.96, 1.0, r));
	ALBEDO = mix(vec3(0.54, 0.42, 0.24), vec3(0.44, 0.41, 0.38), ring);
	ALPHA = (0.14 * (1.0 - smoothstep(0.9, 0.97, r)) + 0.5 * ring) * step(r, 1.0);
}"""
	return _blur
