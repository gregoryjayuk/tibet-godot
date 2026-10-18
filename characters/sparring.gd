extends CharacterBody3D
## A practice partner (spike S19; plan chapter 11, 13.8): a townsman who spars with the player, with the same fighting
## rules (characters/fighting.gd). A small state machine, rethought three times a second: close in to arm's length,
## then jab, guard or step back at random; stagger when hit; go down after three unanswered blows and get up again.
## He spars rather than brawls: after landing a blow he breaks off a pace, and while the other is down he waits until
## he is up (`rest_until`; the yard also gives the player a moment to square up at the start). He only spars with
## fists: while the other has his sling out, or stands more than FAR away, he stands and watches.

const FAR := 5.0
## Its body is one of the player's (MPFB, dressed), tinted so the two do not look alike.

const PERSON := preload("res://characters/person.gdshader")
const Fighting := preload("res://characters/fighting.gd")

var body_path := "res://assets/generated/people/player_man.glb"
var target: Node3D  ## whom it spars with
var passive := false  ## stands its ground and does nothing of its own accord (scripted tests)
var tint := 0.82
var facing := 0.0
var body: Node3D
var anim: AnimationPlayer
var fight: Node
var _clip := ""
var rest_until := 0.0  ## no blows before this time (Time.get_ticks_msec() / 1000.0)
var _think := 0.0
var _guard_until := 0.0


func _ready() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	add_child(cs)
	body = (load(body_path) as PackedScene).instantiate()
	body.top_level = true
	var mat := ShaderMaterial.new()
	mat.shader = PERSON
	PersonLook.apply(body, mat)
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		(mi as GeometryInstance3D).set_instance_shader_parameter("tint", tint)
	add_child(body)
	anim = body.find_children("*", "AnimationPlayer", true, false)[0]
	for n in ["Fighting_Idle", "Walk", "Idle_A"]:
		if anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	fight = Fighting.new()
	fight.fighter = self
	add_child(fight)


func take_hit(from: Vector3, head: bool, power := 1.0) -> bool:
	return fight.take_hit(from, head, power)


## Called by the fighting when one of his blows lands: break off for a moment.
func landed() -> void:
	rest_until = Time.get_ticks_msec() / 1000.0 + randf_range(1.0, 1.8)


func _physics_process(dt: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * dt
	velocity.x = 0.0
	velocity.z = 0.0
	if target != null and not fight.owns_clip() and not passive:
		var to := target.global_position - global_position
		to.y = 0.0
		var d := to.length()
		var now := Time.get_ticks_msec() / 1000.0
		var other = target.get("fight")
		if other != null and other.action in ["Hit_Knockback", "LayToIdle"]:
			rest_until = maxf(rest_until, now + 1.2)  # let him get up, and a moment more
		var resting := now < rest_until
		var want := 2.0 if resting else 1.05  # a pace off while resting, arm's length when sparring
		facing = lerp_angle(facing, atan2(-to.x, -to.z), 1.0 - exp(-6.0 * dt))
		var watching: bool = d > FAR or (other != null and other.sling)
		if watching:
			pass  # stands where he is and watches
		elif d > want + 0.1:
			var dir := to.normalized()
			velocity.x = dir.x * 1.2
			velocity.z = dir.z * 1.2
		elif resting and d < want - 0.4:
			var back := -to.normalized()
			velocity.x = back.x * 0.8
			velocity.z = back.z * 0.8
		_think -= dt
		if _think <= 0.0 and d <= 1.3 and not resting and not watching:
			_think = randf_range(0.25, 0.45)
			var r := randf()
			fight.guard = now < _guard_until
			if r < 0.38:
				fight.strike()
			elif r < 0.55:
				_guard_until = now + 0.8
				fight.guard = true
			elif r < 0.62:
				fight.dodge("back")
	var lv: Vector3 = fight.lunge_velocity()
	if lv != Vector3.ZERO:
		velocity.x = lv.x
		velocity.z = lv.z
	move_and_slide()


func _process(dt: float) -> void:
	body.global_transform = Transform3D(Basis(Vector3.UP, facing + PI), global_position)
	if fight.owns_clip():
		fight.drive(dt)
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.2
	var clip := "Walk" if moving else "Fighting_Idle"
	if clip != _clip:
		anim.play(clip, 0.2)
		_clip = clip
	anim.speed_scale = 1.5 if moving else 1.0
