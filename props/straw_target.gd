extends StaticBody3D
## A straw target on a post (spike S19): struck by a fist or a stone, the bundle swings and settles.

var bundle: Node3D
var _swing := 0.0
var _v := 0.0


func _ready() -> void:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.28
	sh.height = 1.7
	cs.shape = sh
	cs.position.y = 0.85
	add_child(cs)
	var post := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.05
	pm.bottom_radius = 0.06
	pm.height = 1.7
	post.mesh = pm
	post.position.y = 0.85
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#5f3e28")
	post.material_override = wood
	add_child(post)
	bundle = Node3D.new()
	bundle.position.y = 1.7
	add_child(bundle)
	var straw := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.2
	sm.bottom_radius = 0.26
	sm.height = 0.8
	sm.radial_segments = 10
	straw.mesh = sm
	straw.position.y = -0.4
	var sy := StandardMaterial3D.new()
	sy.albedo_color = Color("#c9a962")
	straw.material_override = sy
	bundle.add_child(straw)


func struck(_by: Node) -> void:
	_v += 3.0


func take_hit(_from: Vector3, _head: bool, _power := 1.0) -> bool:
	_v += 2.0
	return false


func _process(dt: float) -> void:
	_v += (-_swing * 30.0 - _v * 3.0) * dt
	_swing += _v * dt
	bundle.rotation.x = _swing * 0.3
