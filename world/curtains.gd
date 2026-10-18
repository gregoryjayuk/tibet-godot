extends Node3D
## The halls' yak-hair curtains parted (M3 sprint 6, step 1; plan chapter 04, 3.1 "Entering": "the heavy black yak-hair
## curtain", pushed aside; chapter 08, V-26: "compression and release reversed, bright to dark", "the curtain's thump
## behind the player cuts the courtyard off"): the kit's sidecars' `curtains` (tibet-blender kit/elements.py
## hang_curtain: the Tsokchen's great door, the Jampa Lhakhang's, the Gönkhang's two, the library's and the Labrang's),
## hung by world/town.gd as the kit's yak_curtain types in the group "curtains" (their width and height as metadata).
## As the player or one of the town's walkers comes through, the cloth round where they push bends ahead of them, nothing
## at its batten and most at its foot; once they are through it swings back behind them and settles, and its thump is
## heard (SND-220). The bending is shaders/stylized_static.gdshader's: `give` the curtain's height below 0, `sway` the push
## (x along it, the side it goes to, metres at its foot, the spread either side).

const ZONE := 1.0  ## metres before or behind the curtain within which one pushes it
const EDGE := 0.35  ## and past its edges
const AHEAD := 0.8  ## metres the cloth's foot stands ahead of the chest as one pushes through
const MOST := 1.3  ## the most it bends, at its foot
const THROUGH := 0.5  ## metres past its plane at which one is through and lets it go
const SPRING := 38.0  ## the cloth swinging back: its stiffness, its damping (heavy: a swing or two and still)
const DAMP := 5.0
const SPREAD := 0.55  ## metres either side of the push over which the cloth bends
const WATCH := 80.0  ## metres from the camera within which the curtains are pushed at all
const PLAYER := -1  ## `who` for the player; a walker is its TownSim index; nobody NOBODY
const NOBODY := -2

var curtains: Array = []  ## {node, meshes, w, h, bend, vel, x, side, who, pushed}
var thumps := 0  ## the times a curtain fell back with its thump (the tests')


## Takes the town's hung curtains (the group "curtains") and gives each its height for the shader. The count.
func build(root: Node) -> int:
	for n in root.get_tree().get_nodes_in_group("curtains"):
		var h := float((n as Node).get_meta("h", 2.6))
		var meshes: Array = (n as Node).find_children("*", "GeometryInstance3D", true, false)
		for m in meshes:
			(m as GeometryInstance3D).set_instance_shader_parameter("give", -h)
			# its whole grid drawn: Godot's automatic LOD takes a flat cloth down to a few triangles even close to, and the
			# shader has nothing left between its corners to bend
			(m as GeometryInstance3D).lod_bias = 128.0
		curtains.append({"node": n, "meshes": meshes, "w": float((n as Node).get_meta("w", 1.8)), "h": h, "bend": 0.0, "vel": 0.0,
				"x": 0.0, "side": 1.0, "who": NOBODY, "pushed": false})
	return curtains.size()


## The push on a curtain from a point (Godot) at `d` metres past its plane along the way the walker came: the bend at
## its foot, towards the way through (pure, for the tests).
static func push_for(d: float) -> float:
	if d >= THROUGH:
		return 0.0
	return clampf(d + AHEAD, 0.0, MOST)


## The stills (tests/terrain/s3.gd, a station "_parted"): the curtain nearest `at` (a point the camera looks at) held half
## parted towards the eye `eye` (`at` if not given), as if someone had just pushed through from the far side; or,
## `parted` false, every curtain let hang.
func hold(at: Vector3, parted: bool, eye := Vector3.INF) -> void:
	if eye == Vector3.INF:
		eye = at
	var best := {}
	var d := 15.0
	for c in curtains:
		c["held"] = false
		c["bend"] = 0.0
		c["vel"] = 0.0
		var n: Node3D = c["node"]
		if parted and is_instance_valid(n) and n.global_position.distance_to(at) < d:
			d = n.global_position.distance_to(at)
			best = c
	if not best.is_empty():
		var n: Node3D = best["node"]
		best["held"] = true
		best["bend"] = MOST
		best["side"] = 1.0 if n.to_local(eye).z < 0.0 else -1.0  # towards the eye: from outside, in (the model's -z)
		best["x"] = float(best["w"]) / 2.0 - 0.35  # pushed through by its edge: the corner swings, the light comes past it
	for c in curtains:
		_settle(c, float(c["bend"]), 0.0)


## Whether a chest at `l` (the curtain's own frame: x along it, its foot at -h, the way in -z) is by the curtain, pushing.
static func by(l: Vector3, w: float, h: float) -> bool:
	return absf(l.x) < w / 2.0 + EDGE and l.y < 0.5 and l.y > -h - 0.6 and absf(l.z) < ZONE


func _process(dt: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	var cam := get_viewport().get_camera_3d()
	var eye: Vector3 = cam.global_position if cam != null else (p.global_position if p != null else Vector3.ZERO)
	for c in curtains:
		var n: Node3D = c["node"]
		if not is_instance_valid(n) or bool(c.get("held", false)):
			continue
		if n.global_position.distance_squared_to(eye) > WATCH * WATCH:
			if float(c["bend"]) != 0.0:
				_settle(c, 0.0, dt)
			continue
		var w: float = c["w"]
		var h: float = c["h"]
		var l := _chest(c, int(c["who"]), p, n)  # the one pushing it already, while they still are
		if l == Vector3.INF or not by(l, w, h):
			c["who"] = NOBODY
			l = Vector3.INF
			if p != null:  # the player first, then the first of the town's walkers by it
				var lp := n.to_local(p.global_position + Vector3(0.0, 1.1, 0.0))
				if by(lp, w, h):
					c["who"] = PLAYER
					l = lp
			if l == Vector3.INF:
				var i := _walker_by(n, w, h)
				if i >= 0:
					c["who"] = i
					l = _chest(c, i, p, n)
			if l != Vector3.INF:
				c["side"] = 1.0 if -l.z <= 0.0 else -1.0  # (from outside the push goes in: the model's -z)
		var target := 0.0
		if l != Vector3.INF:
			target = push_for(-l.z * float(c["side"]))
			c["x"] = clampf(l.x, -w / 2.0 + 0.2, w / 2.0 - 0.2)
		if target > 0.3:
			c["pushed"] = true
		elif bool(c["pushed"]) and target == 0.0:  # through: it falls back behind them
			c["pushed"] = false
			thumps += 1
			var ad := get_node_or_null("/root/AudioDirector")
			if ad != null:
				ad.call("play", "SND-220", n.global_position + n.global_basis * Vector3(0.0, -h * 0.6, 0.0))
		_settle(c, target, dt)


## A pusher's chest in the curtain's frame: the player's (PLAYER) or walker `who`'s, or Vector3.INF if there is none (or
## the walker has gone indoors, out of the drawn crowd).
func _chest(_c: Dictionary, who: int, p: Node3D, n: Node3D) -> Vector3:
	if who == PLAYER and p != null:
		return n.to_local(p.global_position + Vector3(0.0, 1.1, 0.0))
	if who >= 0 and who < TownSim.count and who < TownSim.pos.size() and int(TownSim.state[who]) != 2:
		return n.to_local((TownSim.pos[who] as Vector3) + Vector3(0.0, 1.1, 0.0))
	return Vector3.INF


## The first of the town's walkers by a curtain, pushing it, or -1.
func _walker_by(n: Node3D, w: float, h: float) -> int:
	var at := n.global_position
	var reach := w / 2.0 + EDGE + ZONE
	for i in mini(TownSim.count, TownSim.pos.size()):
		if int(TownSim.state[i]) == 2:
			continue
		var q: Vector3 = TownSim.pos[i]
		if absf(q.x - at.x) > reach or absf(q.z - at.z) > reach or absf(q.y - at.y) > h + 1.0:
			continue
		if by(n.to_local(q + Vector3(0.0, 1.1, 0.0)), w, h):
			return i
	return -1


## The cloth's bend towards `target`: pushed, it follows the pusher at once; let go, it swings back on its spring.
func _settle(c: Dictionary, target: float, dt: float) -> void:
	var b: float = c["bend"]
	if target > b:
		c["bend"] = target
		c["vel"] = 0.0
	else:
		var v: float = c["vel"] + (SPRING * (target - b) - DAMP * float(c["vel"])) * dt
		c["vel"] = v
		c["bend"] = b + v * dt
		if absf(float(c["bend"])) < 0.002 and absf(v) < 0.01 and target == 0.0:
			c["bend"] = 0.0
			c["vel"] = 0.0
	var push := Vector4(float(c["x"]), float(c["side"]), float(c["bend"]), SPREAD)
	for m in c["meshes"]:
		if is_instance_valid(m):
			(m as GeometryInstance3D).set_instance_shader_parameter("sway", push)
