extends Node3D
## The people of upper Shöl crossing the bridge over the Sky Stair (IMP-027; the bridge: tools/town/bridges.py BR-01, from
## H-SHL-061's roof to H-SHL-080's): a neighbour's visit, a child sent on an errand. Now and then
## through the day someone comes up through one roof's hatch, walks to the bridge's end, crosses it a little slower than on
## the ground, stops half way to look down at the pilgrims on the stair, crosses on and goes down through the other roof's
## hatch. Each crossing its own body of the generic townspeople's (characters/named.gd's clips). Only while the townspeople
## are out (TownSim's walkers), and only drawn near the bridge. `plan`, `deck_at` and `at_minute` are pure, for the tests
## and the stills.

const PERSON := preload("res://characters/person.gdshader")
const BRIDGES := "res://assets/generated/terrain/bridges.json"
const BRIDGE := "BR-01"
const ENDS := ["H-SHL-061", "H-SHL-080"]  ## the roofs at its a and b ends
const SEEN := 160.0  ## metres: drawn while the camera is this near the bridge
const WALK := 1.0  ## m/s on a roof
const DECK := 0.75  ## m/s on the planks
const CLIMB := 1.2  ## seconds up through a hatch, or down
const LOOK := 6.0  ## seconds half way across, looking down
const STEP := 0.6  ## metres off the deck's end on its roof, where the step up onto it is
## the day's crossings: [game minute, who, from which end (0: H-SHL-061's, 1: H-SHL-080's)]
const CROSSINGS := [[490.0, "girl", 0], [565.0, "stall_man", 1], [680.0, "porter_woman", 0], [790.0, "boy", 1],
		[870.0, "nomad_woman", 0], [925.0, "elder_man", 1], [985.0, "girl", 1], [1015.0, "boy", 0]]
const WOMEN := ["elder_woman", "stall_woman", "porter_woman", "nomad_woman", "kitchen_woman", "girl"]

var a := Vector3.ZERO  ## the deck's ends (Godot) and its sag
var b := Vector3.ZERO
var sag := 0.0
var hatches: Array = []  ## [H-SHL-061's, H-SHL-080's] (Godot)
var people: Array = []  ## each: {start, key, from, root, ap, clip, phase, t, pos, yaw}
var _mat: ShaderMaterial
var _built := false


## The crossings as people: each {start (game minute), key (its body), from (its end)}.
static func plan() -> Array:
	return CROSSINGS.map(func(c: Array) -> Dictionary: return {"start": float(c[0]), "key": String(c[1]), "from": int(c[2])})


## The deck at `f` of the way from end a to end b: the line between them, sagging as a hanging rope does (the most at
## its middle).
static func deck_at(ea: Vector3, eb: Vector3, s: float, f: float) -> Vector3:
	return ea.lerp(eb, f) - Vector3(0.0, s * 4.0 * f * (1.0 - f), 0.0)


## Where a crossing is at game minute `m` in a still (the clock frozen): "gone" outside its few minutes, else on the deck
## half way across, looking down.
static func at_minute(p: Dictionary, m: float) -> String:
	return "look" if m >= float(p["start"]) and m < float(p["start"]) + 4.0 else "gone"


func build(root: Node, to_godot: Callable) -> int:
	if not FileAccess.file_exists(BRIDGES):
		return 0
	for br in JSON.parse_string(FileAccess.get_file_as_string(BRIDGES))["bridges"]:
		if String(br["id"]) == BRIDGE:
			a = to_godot.call(float(br["a"][0]), float(br["a"][1]), float(br["a"][2]))
			b = to_godot.call(float(br["b"][0]), float(br["b"][1]), float(br["b"][2]))
			sag = float(br["sag"])
	if a == b:
		return 0
	for e in ENDS:
		var h := root.get_node_or_null(e) as Node3D
		var s: Node3D = null if h == null else h.find_child("SOCK_HATCH_*", true, false) as Node3D
		if s == null:
			return 0
		hatches.append(s.global_position)
	people = plan()
	add_to_group("bridge_people")
	return people.size()


func _bodies() -> void:
	_built = true
	_mat = ShaderMaterial.new()
	_mat.shader = PERSON
	for p in people:
		var path := "res://assets/generated/people/%s.glb" % p["key"]
		if not ResourceLoader.exists(path):
			continue
		var root: Node3D = (load(path) as PackedScene).instantiate()
		root.name = "Bridge_%s_%d" % [String(p["key"]), int(p["start"])]
		PersonLook.apply(root, _mat)
		var ap: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Walk_Female", "Idle_A", "Idle_FoldArms"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		add_child(root)
		root.visible = false
		p["root"] = root
		p["ap"] = ap
		p["clip"] = ""
		p["phase"] = "gone"
		p["t"] = 0.0
		p["pos"] = Vector3.ZERO
		p["yaw"] = 0.0


func _process(dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var mid := (a + b) / 2.0
	var on: bool = TownSim.walkers_on and cam != null and not people.is_empty() and Vector2(cam.global_position.x - mid.x, cam.global_position.z - mid.z).length() < SEEN
	if not on:
		for p in people:
			if p.has("root"):
				(p["root"] as Node3D).visible = false
		return
	if not _built:
		_bodies()
	var m := fposmod(WorldClock.minute, 1440.0)
	for p in people:
		if p.has("root"):
			_step(p, m, dt)


## One crossing, a frame on: up through its hatch, to the deck's end, across it (a stop half way), to the other hatch and
## down; in a still (the clock frozen), half way across looking down while its minutes last.
func _step(p: Dictionary, m: float, dt: float) -> void:
	var root: Node3D = p["root"]
	var e0 := a if int(p["from"]) == 0 else b
	var e1 := b if int(p["from"]) == 0 else a
	var along := Vector3(e1.x - e0.x, 0.0, e1.z - e0.z).normalized()
	var h0: Vector3 = hatches[int(p["from"])]
	var h1: Vector3 = hatches[1 - int(p["from"])]
	var on0 := Vector3(e0.x, h0.y, e0.z) - along * STEP  # the roofs before the step up onto the deck and after it down
	var on1 := Vector3(e1.x, h1.y, e1.z) + along * STEP
	var ph: String = p["phase"]
	var pos: Vector3 = p["pos"]
	var yaw: float = p["yaw"]
	var clip := "Idle_A"
	if WorldClock.frozen:
		ph = at_minute(p, m)
		if ph == "look":
			pos = deck_at(a, b, sag, 0.5)
			var down := along.cross(Vector3.UP)  # square to the bridge, the side the stair falls away on (south)
			down = down if down.z > 0.0 else -down
			yaw = atan2(down.x, down.z)
			clip = "Idle_FoldArms"
	else:
		if ph == "gone" and m >= float(p["start"]) and m < float(p["start"]) + 1.0:
			ph = "rise"
			p["t"] = 0.0
			pos = h0
		p["t"] = float(p["t"]) + dt
		match ph:
			"rise", "sink":
				var hatch := h0 if ph == "rise" else h1
				var k := clampf(float(p["t"]) / CLIMB, 0.0, 1.0)
				pos = hatch - Vector3(0.0, 1.5 * ((1.0 - k) if ph == "rise" else k), 0.0)
				if k >= 1.0:
					ph = "to_deck" if ph == "rise" else "gone"
					p["t"] = 0.0
			"to_deck", "off":
				var goal := on0 if ph == "to_deck" else h1
				var to := goal - pos
				to.y = 0.0
				if to.length() < 0.05:
					pos = Vector3(goal.x, goal.y, goal.z)
					ph = "deck" if ph == "to_deck" else "sink"
					p["t"] = 0.0
				else:
					pos += to.normalized() * minf(WALK * dt, to.length())
					yaw = atan2(to.x, to.z)
					clip = "Walk_Female" if WOMEN.has(String(p["key"])) else "Walk"
			"deck":  # up off the roof, the planks a little slower than the roof, a stop half way, down onto the other roof
				var span := e0.distance_to(e1)
				var d := float(p.get("d", 0.0))
				var looking := false
				if d >= STEP + span / 2.0 and float(p.get("look_t", 0.0)) < LOOK:
					p["look_t"] = float(p.get("look_t", 0.0)) + dt
					looking = true
				else:
					d = minf(d + (DECK if d > STEP and d < STEP + span else WALK) * dt, 2.0 * STEP + span)
				p["d"] = d
				pos = _path(p, d, span, on0, on1)
				if looking:
					var down := along.cross(Vector3.UP)  # square to the bridge, the side the stair falls away on (south)
					down = down if down.z > 0.0 else -down
					yaw = atan2(down.x, down.z)
					clip = "Idle_FoldArms"
				else:
					yaw = atan2(along.x, along.z)
					clip = "Walk_Female" if WOMEN.has(String(p["key"])) else "Walk"
				if d >= 2.0 * STEP + span:
					ph = "off"
					p["t"] = 0.0
					p.erase("d")
					p.erase("look_t")
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
	if WorldClock.frozen:  # the stills: the pose from the animation clock
		ap.speed_scale = 0.0
		ap.seek(fposmod(WorldClock.anim_time + float(hash(String(p["key"])) % 97) * 0.1, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = 1.0


## A crossing `d` metres along its way from its roof's step to the other's: up the step onto the deck's end, along the
## sagging deck, down the step onto the other roof.
func _path(p: Dictionary, d: float, span: float, on0: Vector3, on1: Vector3) -> Vector3:
	var from_a := int(p["from"]) == 0
	if d <= STEP:
		return on0.lerp(deck_at(a, b, sag, 0.0 if from_a else 1.0), d / STEP)
	if d >= STEP + span:
		return deck_at(a, b, sag, 1.0 if from_a else 0.0).lerp(on1, clampf((d - STEP - span) / STEP, 0.0, 1.0))
	var f := (d - STEP) / span
	return deck_at(a, b, sag, f if from_a else 1.0 - f)
