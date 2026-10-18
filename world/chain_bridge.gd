extends Node
## The chain bridge's sway (M2 sprint 4, step 2; plan chapter 06, 8.x: "±0.15 m lateral and ±0.08 m vertical per footfall,
## growing to ±0.3 m when four or more people walk out of step, damped in 3 s"; chapter 11, 13: the deck and the camera
## move, the walker's collider stays on its still deck): two damped oscillators, the deck's first mode sideways and up
## and down, kicked at every footfall of whoever is on the deck (the player, the town's walkers) by the mode's shape where
## they tread, sideways to either side at random, always down. The deck's and the chains' vertices move by it in the
## static shader (`sway`, along with `give_ends`, its two ends), the player's camera by the same at the player's place
## (player.gd `sway_offset`). Attached to the chain bridge's node by world/town.gd.

const FREQ := 0.75  ## its sway's own frequency, Hz (a chain span of 50 m, slack)
const DAMP := 1.0  ## per second: a kick's sway down to 5% in 3 s
const KICK_SIDE := 0.6  ## m/s a footfall gives it sideways, at its middle
const KICK_DOWN := 0.45  ## and downwards
const STEP_S := 0.55  ## seconds between a walker's footfalls
const MAX_SIDE := 0.32
const MAX_DOWN := 0.12

var a := Vector2.ZERO  ## (sideways, up) at its middle, metres
var v := Vector2.ZERO
var length := 48.0
var p0 := Vector3.ZERO  ## its two ends (Godot)
var p1 := Vector3.ZERO
var meshes: Array = []
var side := Vector3.RIGHT  ## its sideways in the world, as its kit's x
var on_deck := 0  ## how many walk on it now (the tests')
var rng := RandomNumberGenerator.new()
var _since := {}  ## walker -> seconds since its last footfall


func setup(bridge: Node3D, a0: Vector3, a1: Vector3) -> void:
	p0 = a0
	p1 = a1
	length = Vector2(a1.x - a0.x, a1.z - a0.z).length()
	side = bridge.global_transform.basis.x.normalized()
	rng.seed = 1903
	for mi in bridge.find_children("*", "MeshInstance3D", true, false):
		meshes.append(mi)
		(mi as MeshInstance3D).set_instance_shader_parameter("give_ends", Vector4(a0.x, a0.z, a1.x, a1.z))


## Where along the bridge (0-1) a point is, and how far off its line sideways, flat; t < 0 or > 1 off its ends.
func along(p: Vector3) -> Vector2:
	var ab := Vector2(p1.x - p0.x, p1.z - p0.z)
	var ap := Vector2(p.x - p0.x, p.z - p0.z)
	var t := ap.dot(ab) / maxf(ab.length_squared(), 1e-4)
	return Vector2(t, absf(ap.cross(ab.normalized())))


func _walker_on(p: Vector3) -> float:
	var q := along(p)
	if q.x <= 0.02 or q.x >= 0.98 or q.y > 1.2:
		return -1.0
	var deck_y := p0.y + (p1.y - p0.y) * q.x
	return q.x if absf(p.y - deck_y) < 6.0 else -1.0


func kick(t: float) -> void:
	var m := sin(PI * t)
	v.x += KICK_SIDE * m * (1.0 if rng.randf() < 0.5 else -1.0)
	v.y -= KICK_DOWN * m


func step(dt: float) -> void:
	var w := TAU * FREQ
	var acc := -w * w * a - 2.0 * DAMP * v
	v += acc * dt
	a += v * dt
	a.x = clampf(a.x, -MAX_SIDE, MAX_SIDE)
	a.y = clampf(a.y, -MAX_DOWN, MAX_DOWN)


func _physics_process(dt: float) -> void:
	on_deck = 0
	var walkers := []
	var p := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if p != null:
		var t := _walker_on(p.global_position)
		if t >= 0.0:
			walkers.append(["player", t, Vector2(p.velocity.x, p.velocity.z).length() > 0.3])
	if TownSim.walkers_on:
		for i in TownSim.count:
			if int(TownSim.state[i]) == 2:
				continue
			var t := _walker_on(TownSim.pos[i])
			if t >= 0.0:
				walkers.append([i, t, int(TownSim.state[i]) == 0])
	for n in get_tree().get_nodes_in_group("deck_walkers"):  # Samkha's crossings (world/samkha_people.gd)
		var nd := n as Node3D
		if nd != null and nd.is_visible_in_tree():
			var t := _walker_on(nd.global_position)
			if t >= 0.0:
				walkers.append([nd.get_instance_id(), t, bool(nd.get_meta("walking", true))])
	for wk in walkers:
		on_deck += 1
		if not wk[2]:
			continue
		var s := float(_since.get(wk[0], rng.randf() * STEP_S)) + dt
		if s >= STEP_S:
			s -= STEP_S
			kick(float(wk[1]))
		_since[wk[0]] = s
	step(dt)
	for mi in meshes:
		if is_instance_valid(mi):
			(mi as MeshInstance3D).set_instance_shader_parameter("sway", Vector4(a.x, a.y, 0.0, 0.0))
	if p != null:
		var t := _walker_on(p.global_position)
		if t >= 0.0:
			p.set("sway_offset", (side * a.x + Vector3.UP * a.y) * sin(PI * t))
		else:
			p.set("sway_offset", Vector3.ZERO)
