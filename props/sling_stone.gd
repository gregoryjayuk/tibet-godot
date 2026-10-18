extends RigidBody3D
## A sling stone (spike S19; plan chapter 11, 13.8): about 60 g, loosed at 12-28 m/s, flying as a Jolt body with
## continuous collision so it cannot pass through a pot or a man between two ticks. It staggers a fighter it strikes,
## knocks pots off a wall, sets a straw target swinging, and lies where it falls for a few seconds.
## A clay pot breaks under a sling stone; until things can break, a stone knocks a loose body with twice its own
## momentum (KNOCK), or 60 g would only nudge a pot.

const KNOCK := 2.0

var thrower: Node3D
var debug := false
var _spent := false
var _age := 0.0
var _v := Vector3.ZERO  ## the velocity before this tick's contact: by the time body_entered fires, it has bounced


func _ready() -> void:
	mass = 0.06
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 2
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.035
	cs.shape = sh
	add_child(cs)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.035
	sm.height = 0.07
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#6f6961")
	mi.material_override = m
	add_child(mi)
	body_entered.connect(_on_body)


## The launch velocity that carries a stone from `from` to `target` at `speed` on the low arc; 45 deg when the
## target is out of reach.
static func launch(from: Vector3, target: Vector3, speed: float) -> Vector3:
	var d := target - from
	var h := Vector2(d.x, d.z)
	var x := h.length()
	var y := d.y
	var g := 9.8
	var v2 := speed * speed
	var disc := v2 * v2 - g * (g * x * x + 2.0 * y * v2)
	var ang := atan2(v2 - sqrt(disc), g * x) if disc >= 0.0 and x > 0.01 else PI / 4.0
	var dir := h.normalized() if x > 0.01 else Vector2(0.0, -1.0)
	return Vector3(dir.x * cos(ang), sin(ang), dir.y * cos(ang)) * speed


func _on_body(b: Node) -> void:
	if _spent:
		return
	if b.has_method("take_hit") and b != thrower:
		_spent = true
		var from := global_position - _v.normalized() * 2.0
		b.take_hit(from, global_position.y > (b as Node3D).global_position.y + 1.4, 1.0)
	elif b.has_method("struck"):
		b.struck(self)
		_spent = true
	elif b is RigidBody3D:
		_spent = true
		(b as RigidBody3D).apply_impulse(_v * mass * KNOCK, global_position - (b as Node3D).global_position)
	if debug:
		print("fighting: stone struck %s at %s, %.1f m/s" % [b.name, global_position, _v.length()])


func _physics_process(dt: float) -> void:
	_v = linear_velocity
	_age += dt
	if _age > 8.0:
		queue_free()
