extends Node
## The attention budget (plan chapter 05, 9.6; M1 sprint 6, step 3): at any moment at most two people within 10 m look
## at the player, each look lasting 0.6-1.5 s before the head goes back to its own business: a LookAtModifier3D on the
## head bone (±70 degrees of yaw, ±30 of pitch), eased in and out over 0.4 s. Who looks is drawn four times a second
## from those near enough whose body faces within 70 degrees of the player, by an interest score: a child ×3, an elder
## ×1.5, a busy worker ×0.3, anyone else ×1 (the figure's own weight); ×2 while the player runs (9.6's strangeness);
## divided by one more than the looks this person has already given today. Nobody looks again for 5-12 s after a look.
## People further than 10 m never turn their heads for the player (9.6).

const RADIUS := 10.0
const MOST := 2
const EASE := 0.4
const YAW := 70.0
const PITCH := 30.0
const EVERY := 0.25  ## seconds between draws
const RATE := 0.25  ## looks a second an eligible person of weight 1 starts, before today's count divides it

var target := Node3D.new()  ## at the player's eyes: every head that looks turns to it
var time := 0.0
var looking := {}  ## id -> {"mod": LookAtModifier3D, "until": the look's end, "k": 0-1 into the ease}
var seen := {}  ## id -> looks given today
var rest_until := {}  ## id -> no look before this time
var looks := 0  ## looks begun in all (the tests')
var most_at_once := 0  ## the most heads turned at once (the tests')
var _next := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	target.name = "Eyes"
	add_child(target)
	_rng.seed = 1903


## A head look for a skeleton of the MPFB bodies (the head bone faces +Z, up +Y), off until a look turns it on.
static func head_look(sk: Skeleton3D) -> LookAtModifier3D:
	var m := LookAtModifier3D.new()
	m.name = "HeadLook"
	m.bone_name = "head"
	m.forward_axis = SkeletonModifier3D.BONE_AXIS_PLUS_Z
	m.primary_rotation_axis = Vector3.AXIS_Y
	m.use_secondary_rotation = true
	m.use_angle_limitation = true
	m.symmetry_limitation = true
	m.primary_limit_angle = deg_to_rad(YAW * 2.0)  # the whole range, both sides
	m.secondary_limit_angle = deg_to_rad(PITCH * 2.0)
	m.influence = 0.0
	m.active = false
	sk.add_child(m)
	return m


## One frame: the looks under way eased in, held and eased out; four times a second, perhaps new ones. `candidates`:
## [id, figure (facing +Z), its head look, interest], from characters/named.gd and the crowd's hero tier; `strange` the
## player's strangeness (2 running, else 1).
func update(dt: float, eyes: Vector3, strange: float, candidates: Array) -> void:
	time += dt
	target.global_position = eyes
	var busy := 0
	for id in looking.keys():
		var l: Dictionary = looking[id]
		var m: LookAtModifier3D = l["mod"]
		if not is_instance_valid(m):
			looking.erase(id)
			continue
		var on := time < float(l["until"])
		busy += 1 if on else 0
		l["k"] = move_toward(float(l["k"]), 1.0 if on else 0.0, dt / EASE)
		m.influence = smoothstep(0.0, 1.0, float(l["k"]))
		if not on and float(l["k"]) <= 0.0:
			m.active = false
			looking.erase(id)
	most_at_once = maxi(most_at_once, busy)
	if time < _next or busy >= MOST:
		return
	_next = time + EVERY
	var order := range(candidates.size())
	for k in range(order.size() - 1, 0, -1):  # a fair order each draw: nobody always first
		var j := _rng.randi_range(0, k)
		var tmp: int = order[k]
		order[k] = order[j]
		order[j] = tmp
	for k in order:
		var c: Array = candidates[k]
		var id: String = c[0]
		if looking.has(id) or time < float(rest_until.get(id, 0.0)):
			continue
		var fig: Node3D = c[1]
		var to := eyes - fig.global_position
		var flat := Vector2(to.x, to.z)
		if flat.length() > RADIUS or flat.length() < 0.5:
			continue
		var fwd := fig.global_transform.basis.z
		if absf(rad_to_deg(Vector2(fwd.x, fwd.z).angle_to(flat))) > YAW:
			continue
		var p := EVERY * RATE * float(c[3]) * strange / (1.0 + float(seen.get(id, 0)))
		if _rng.randf() >= p:
			continue
		var m: LookAtModifier3D = c[2]
		m.target_node = m.get_path_to(target)
		m.active = true
		looking[id] = {"mod": m, "until": time + _rng.randf_range(0.6, 1.5), "k": 0.0}
		seen[id] = int(seen.get(id, 0)) + 1
		rest_until[id] = time + 1.5 + _rng.randf_range(5.0, 12.0)
		looks += 1
		busy += 1
		if busy >= MOST:
			break
