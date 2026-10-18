extends Node3D
## V-28's people on the near roofs at dusk (plan chapter 08, V-28: "on the six nearest roofs: women feeding juniper, a
## girl dragging in the grain cloth, a grandmother with a rosary, a man calling his son off a neighbour's roof"; M1 sprint
## 8, step 6). Before five someone climbs up through each of the nearest roofs' hatches, goes to the burner or the
## parapet and does what the evening asks: feeds the juniper as the sang is lit, sits with a rosary, watches the valley,
## calls across to the next roof, or carries in what was drying and goes down with it; and goes down again as the
## ladders come up, by 17:50. Each house seeded by its name: who, what and when; no body twice on these roofs (the
## generic townspeople's, characters/named.gd's clips). Only while the townspeople are out (TownSim's walkers), and only
## drawn near V-28. `plan` and `where` are pure, for the tests.

const PERSON := preload("res://characters/person.gdshader")
const CLIPS := "res://assets/generated/people/named_clips.json"
const V28 := Vector2(-95.0, 205.0)  ## V-28's roof in the town grid (chapter 08)
const NEAR := 90.0  ## metres: the roofs within this of V-28 have their people
const HOUSES := 6
const SEEN := 260.0  ## metres: drawn while the camera is this near V-28
const WALK := 1.0  ## m/s on a roof
const CLIMB := 1.2  ## seconds up through the hatch, or down
## what the six do, in the order the nearest houses take them (each list shuffled by the house's seed), and who may
## do it: the women feed juniper, the old woman sits with her rosary, a man calls to the next roof, a girl carries in
const DOINGS := ["juniper", "juniper", "rosary", "call", "watch", "carry"]
const WOMEN := ["elder_woman", "stall_woman", "porter_woman", "nomad_woman", "kitchen_woman", "girl"]
const WHO := {"juniper": ["stall_woman", "porter_woman", "nomad_woman", "kitchen_woman"], "rosary": ["elder_woman"],
		"call": ["elder_man", "stall_man"], "watch": ["boy", "stall_man", "nomad_woman"], "carry": ["girl"]}

var people: Array = []  ## each: {house, doing, key, up, down, hatch, spot, face, root, ap, clip, phase, t, pos, yaw}
var _info = null
var _mat: ShaderMaterial
var _built := false


## The houses near V-28 with a hatch on the roof: [house node, its hatch, its burner or null, the spot to stand at, the
## way that spot faces], nearest first. `root` is the town.
static func roofs(root: Node, v28: Vector3, households: Node = null) -> Array:
	var found: Array = []
	for s in root.find_children("SOCK_HATCH_*", "Node3D", true, false):
		var n := s as Node3D
		var h := n.get_parent() as Node3D
		while h != null and h.get_parent() != root:
			h = h.get_parent() as Node3D
		if h == null or not String(h.name).begins_with("H-"):
			continue
		if households != null and households.call("is_shut", String(h.name)):  # its household away (world/households.gd)
			continue
		var d := Vector2(n.global_position.x - v28.x, n.global_position.z - v28.z).length()
		if d < 4.0 or d > NEAR:  # V-28's own roof is the player's
			continue
		var sang: Node3D = null
		for b in h.find_children("SOCK_SANG_*", "Node3D", true, false):
			if absf((b as Node3D).global_position.y - n.global_position.y) < 1.5:
				sang = b
		var edge := _front_spot(h, n)
		found.append([h, n, sang, edge[0], edge[1], d])
	found.sort_custom(func(a, b): return float(a[5]) < float(b[5]))
	return found


## A spot on the roof's front parapet, clear of its piers and stacks, from the kit's sidecar (the roof's rectangle and its
## obstacles, in the kit's frame: x, y, height); and the way out over the parapet. Falls back to 2 m in front of the hatch.
static func _front_spot(h: Node3D, hatch: Node3D) -> Array:
	var out := h.global_basis.z.normalized()
	var fallback := [hatch.global_position + out * 2.0, out]
	var side := String(h.scene_file_path).get_basename() + ".json"
	if not FileAccess.file_exists(side):
		return fallback
	var info = JSON.parse_string(FileAccess.get_file_as_string(side))
	if not (info is Dictionary) or not (info as Dictionary).has("roofs"):
		return fallback
	var hl := h.to_local(hatch.global_position)
	for r in info["roofs"]:
		var z := float(r[4])
		if absf(z - hl.y) > 0.3:
			continue  # the roof the hatch opens on
		var y0 := float(r[1]) + 0.7  # the front parapet (the kit's -y is Godot's +z, the house's front)
		var xs: Array = []
		var x := float(r[0]) + 1.0
		while x <= float(r[2]) - 1.0:
			var clear := true
			for o in r[6]:
				if x > float(o[0]) - 0.4 and x < float(o[2]) + 0.4 and y0 > float(o[1]) - 0.4 and y0 < float(o[3]) + 0.4:
					clear = false
			if clear:
				xs.append(x)
			x += 0.5
		if xs.is_empty():
			return fallback
		var pick: float = xs[absi(hash(String(h.name))) % xs.size()]
		return [h.to_global(Vector3(pick, z, -y0)), out]
	return fallback


## Who does what on which roof, and when (game minutes): pure, seeded by the houses' names.
static func plan(names: Array) -> Array:
	var out: Array = []
	var used := {}
	var order := DOINGS.duplicate()
	var mix := RandomNumberGenerator.new()
	mix.seed = hash(",".join(PackedStringArray(names.slice(0, HOUSES))))
	for i in range(order.size() - 1, 0, -1):  # which roof does what: the town's own shuffle
		var j := mix.randi_range(0, i)
		var t = order[i]
		order[i] = order[j]
		order[j] = t
	for k in mini(names.size(), HOUSES):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(String(names[k]) + ":roof")
		var doing: String = order[k]
		var keys: Array = (WHO[doing] as Array).filter(func(b): return not used.has(b))
		if keys.is_empty():
			continue
		var key: String = keys[rng.randi_range(0, keys.size() - 1)]
		used[key] = true
		var up := rng.randf_range(1008.0, 1016.0) if doing == "juniper" else rng.randf_range(1010.0, 1022.0)
		var down := rng.randf_range(1030.0, 1036.0) if doing == "carry" else rng.randf_range(1058.0, 1070.0)
		out.append({"house": String(names[k]), "doing": doing, "key": key, "up": up, "down": down})
	return out


## Where a roof person is at game minute `m`: "gone" before `up` and after `down`, else "there" (at the spot, doing it);
## the climbing and walking between are run in real time by `_process`.
static func where(p: Dictionary, m: float) -> String:
	return "there" if m >= float(p["up"]) and m < float(p["down"]) else "gone"


func build(root: Node, to_godot: Callable, households: Node = null) -> int:
	var v28: Vector3 = to_godot.call(V28.x, V28.y, 0.0)
	var found := roofs(root, v28, households)
	var names: Array = found.map(func(f): return String((f[0] as Node).name))
	var plans := plan(names)
	for p in plans:
		var f: Array = found[names.find(p["house"])]
		var hatch: Vector3 = (f[1] as Node3D).global_position
		var spot: Vector3 = f[3]
		var face: Vector3 = f[4]
		if p["doing"] == "juniper" and f[2] != null:  # beside the burner, facing it; not on the hatch, which is by it
			var b: Vector3 = (f[2] as Node3D).global_position
			var to_hatch := Vector3(hatch.x - b.x, 0.0, hatch.z - b.z)
			to_hatch = to_hatch.normalized() if to_hatch.length() > 0.1 else Vector3.BACK
			var aside := to_hatch.cross(Vector3.UP) * (1.0 if hash(String(p["house"])) % 2 == 0 else -1.0)
			spot = Vector3(b.x, hatch.y, b.z) + aside * 0.75
			face = -aside
		elif p["doing"] == "call":  # towards the next roof with someone on it
			var other: Vector3 = spot + face * 10.0
			for g in found:
				if g != f:
					other = (g[1] as Node3D).global_position
					break
			face = Vector3(other.x - spot.x, 0.0, other.z - spot.z).normalized()
		p["hatch"] = hatch
		p["spot"] = Vector3(spot.x, hatch.y, spot.z)
		p["face"] = face
		people.append(p)
	return people.size()


func _bodies() -> void:
	_built = true
	_info = JSON.parse_string(FileAccess.get_file_as_string(CLIPS)) if FileAccess.file_exists(CLIPS) else null
	_mat = ShaderMaterial.new()
	_mat.shader = PERSON
	for p in people:
		var path := "res://assets/generated/people/%s.glb" % p["key"]
		if not ResourceLoader.exists(path):
			continue
		var root: Node3D = (load(path) as PackedScene).instantiate()
		root.name = "Roof_" + String(p["key"])
		PersonLook.apply(root, _mat)
		var ap: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Walk_Female", "Walk_Carry", "Idle_A", "Idle_Subtle", "Idle_FoldArms", "Idle_Talking", "Interact", "Sitting_Idle", "Crouch_Idle"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		add_child(root)
		root.visible = false
		p["root"] = root
		p["ap"] = ap
		p["clip"] = ""
		p["phase"] = "gone"
		p["t"] = 0.0
		p["pos"] = p["hatch"]
		p["yaw"] = 0.0


## The clip a person plays while there: by what they do, and for the juniper by the minute (feeding it as it is lit).
static func acting_clip(doing: String, m: float) -> String:
	match doing:
		"juniper":
			return "Interact" if m < 1030.0 else "Idle_Subtle"
		"rosary":
			return "Sitting_Idle"
		"call":
			return "Idle_Talking"
		"watch":
			return "Idle_FoldArms"
		"carry":
			return "Interact"
	return "Idle_A"


func _process(dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var on: bool = TownSim.walkers_on and cam != null and not people.is_empty() and Vector2(cam.global_position.x - float(people[0]["hatch"].x), cam.global_position.z - float(people[0]["hatch"].z)).length() < SEEN
	if not on:
		for p in people:
			if p.has("root"):
				(p["root"] as Node3D).visible = false
		return
	if not _built:
		_bodies()
	var m := fposmod(WorldClock.minute, 1440.0)
	for p in people:
		if not p.has("root"):
			continue
		_step(p, m, dt, WorldClock.frozen)


func _step(p: Dictionary, m: float, dt: float, frozen: bool) -> void:
	var root: Node3D = p["root"]
	var want := where(p, m)
	var hatch: Vector3 = p["hatch"]
	var spot: Vector3 = p["spot"]
	if frozen or (want == "there" and p["phase"] == "gone" and m > float(p["up"]) + 1.0) or (want == "gone" and p["phase"] != "gone" and m > float(p["down"]) + 1.0):
		p["phase"] = "there" if want == "there" else "gone"  # a still, or the clock jumped: straight to where the minute has them
		p["pos"] = spot
	var ph: String = p["phase"]
	if ph == "gone" and want == "there":
		ph = "rise"
		p["t"] = 0.0
		p["pos"] = hatch
	elif ph == "there" and want == "gone":
		ph = "back"
	p["t"] = float(p["t"]) + dt
	var clip := "Idle_A"
	var pos: Vector3 = p["pos"]
	var yaw: float = p["yaw"]
	match ph:
		"rise", "sink":
			var k := clampf(float(p["t"]) / CLIMB, 0.0, 1.0)
			pos = hatch - Vector3(0.0, 1.5 * ((1.0 - k) if ph == "rise" else k), 0.0)
			if k >= 1.0:
				ph = "out" if ph == "rise" else "gone"
				p["t"] = 0.0
		"out", "back":
			var goal := spot if ph == "out" else hatch
			var to := goal - pos
			to.y = 0.0
			if to.length() < 0.05:
				pos = Vector3(goal.x, hatch.y, goal.z)
				ph = "there" if ph == "out" else "sink"
				p["t"] = 0.0
			else:
				pos += to.normalized() * minf(WALK * dt, to.length())
				yaw = atan2(to.x, to.z)
				clip = "Walk_Carry" if p["doing"] == "carry" and ph == "back" else ("Walk_Female" if WOMEN.has(String(p["key"])) else "Walk")
		"there":
			pos = spot
			var f: Vector3 = p["face"]
			yaw = atan2(f.x, f.z)
			clip = acting_clip(String(p["doing"]), m)
	p["phase"] = ph
	p["pos"] = pos
	p["yaw"] = yaw
	root.visible = ph != "gone"
	if ph == "gone":
		return
	root.global_position = pos
	root.rotation.y = yaw
	var ap: AnimationPlayer = p["ap"]
	if not ap.has_animation(clip):
		clip = "Idle_A"
	if String(p["clip"]) != clip:
		ap.play(clip, 0.3 if String(p["clip"]) != "" else 0.0)
		p["clip"] = clip
	if frozen:  # the stills: the pose from the animation clock
		ap.speed_scale = 0.0
		ap.seek(fposmod(WorldClock.anim_time + float(hash(String(p["key"])) % 97) * 0.1, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = 1.0
