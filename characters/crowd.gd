extends Node3D
## The crowd's tiers (plan chapter 05, 13; roadmap RT-13, spike S5): TownSim's agents drawn as hero (0-10 m, at most 8,
## skeletal, animated every frame), near (10-35 m, at most 32, skeletal, animated at 15 Hz, staggered) or VAT
## (everyone else, one MultiMesh per archetype, animated on the GPU). Promotions and demotions are capped at two a
## frame, nearest first, with 10% hysteresis, so crossing a boundary never costs more than two swaps.
## One animation clock per person, t = g_time * rate + phase, which both kinds of drawing evaluate: a person handed
## from one tier to the other is in the same pose (chapter 05, 13.2, "hand-over without a pop").
## `last_us` is the cost of the last update, for the spike's budget.
## With TownSim's walkers (M1 sprint 4, step 4): a walker indoors is not drawn, one standing plays the idle clip, and
## the walk clip's rate follows the walker's speed, its phase carried over each change so the stride does not jump.
## The named eight (TownSim.NAMED) are drawn by characters/named.gd, not here. Each skeletal figure's head can glance at
## the player (a LookAtModifier3D, off until characters/attention.gd turns it on: chapter 05, 9.6).

const HandWheel := preload("res://characters/hand_wheel.gd")
const HERO_R := 10.0
const NEAR_R := 35.0
const HYST := 1.1
const HERO_CAP := 8
const NEAR_CAP := 32
const MAX_SWAPS := 2
const KEEPER_FAR := 1.6  ## a stall's keeper queues for the skeletal tiers as though this many times as far
const NATURAL_SPEED := 0.76  ## the stand-ins' Walk clip's pace in m/s, measured from the bake's foot sweep (0.64 m a step)
const PERSON := preload("res://characters/person.gdshader")
const Attention := preload("res://characters/attention.gd")

var sim: Node  ## TownSim
var kinds: Array[String] = []
var sets: Array[VatSet] = []
var mmis: Array[MultiMeshInstance3D] = []
var bufs: Array[PackedFloat32Array] = []
var clip_walk: Array[Dictionary] = []
var clip_idle: Array[Dictionary] = []
var clips_of: Array[Dictionary] = []  ## per archetype: every clip its VAT has (a sitter's sits since M2 sprint 10, step 4)
const SITS := {3: "Sitting_Idle", 5: "Crouch_Idle", 6: "Sitting_Cross"}  ## TownSim's sitting states and their clips
var natural := PackedFloat32Array()  ## per archetype: its Walk clip's pace, m/s (the MPFB bodies' own, in their VAT info)
var slot := PackedInt32Array()  ## the agent's instance in its archetype's MultiMesh
var tier := PackedByteArray()  ## 0 VAT, 1 near, 2 hero
var tint := PackedFloat32Array()
var phase := PackedFloat32Array()  ## seconds into the walk at g_time 0
var rate := PackedFloat32Array()
var dist2 := PackedFloat32Array()
var node_of := {}  ## agent -> its skeletal node while drawn skeletal
var pools: Array = []  ## per archetype: free skeletal nodes
var person_mat: ShaderMaterial
var frame := 0
var last_us := 0
var swaps := 0
var counts := {"hero": 0, "near": 0, "vat": 0}
var forced := -1  ## the pop test: -1 normal; 0 or 1 draws every agent at that tier
var skeletal_nodes: Array[GeometryInstance3D] = []


## Who casts sun shadows: the skeletal tiers always do in play (chapter 05, 13.2); the VAT tier is spike S5's question.
func set_shadows(skeletal: bool, vat: bool) -> void:
	for g in skeletal_nodes:
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if skeletal else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for m in mmis:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if vat else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func setup(p_sim: Node, p_kinds: Array[String], bounds: AABB, seed_value := 1903) -> void:
	sim = p_sim
	kinds = p_kinds
	person_mat = ShaderMaterial.new()
	person_mat.shader = PERSON
	var per_kind := PackedInt32Array()
	per_kind.resize(kinds.size())
	var n: int = sim.count
	slot.resize(n)
	tier.resize(n)
	tint.resize(n)
	phase.resize(n)
	rate.resize(n)
	dist2.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in n:
		var k: int = sim.kind[i]
		if k >= kinds.size():  # a named walker: characters/named.gd draws it
			tier[i] = 0
			continue
		slot[i] = per_kind[k]
		per_kind[k] += 1
		tint[i] = rng.randf_range(0.94, 1.06)
		tier[i] = 0
	for k in kinds.size():
		var v := VatSet.open(kinds[k])
		sets.append(v)
		clip_walk.append(v.clip("Walk"))
		clip_idle.append(v.clip("Idle_A"))
		var have := {}
		for c in (v.info["clips"] as Dictionary):
			have[String(c)] = v.clip(String(c))
		clips_of.append(have)
		natural.append(float(v.info.get("walk_speed", NATURAL_SPEED)))
		var mmi := v.multimesh(per_kind[k], bounds)
		add_child(mmi)
		mmis.append(mmi)
		var b := PackedFloat32Array()
		b.resize(per_kind[k] * VatSet.FLOATS)
		bufs.append(b)
		var pool := []
		var scene: PackedScene = load("res://assets/generated/people/%s.glb" % kinds[k])
		for j in mini(HERO_CAP + NEAR_CAP, per_kind[k]):  # no more skinned figures of a kind than it has walkers (the day's
			# drawn wear 34 figures, most of them a few each: 40 a kind had made 1,360; M2 sprint 10)
			var p: Node3D = scene.instantiate()
			var mi: MeshInstance3D = p.find_children("*", "MeshInstance3D", true, false)[0]
			PersonLook.apply(p, person_mat)  # the painted faces on the hero and near tiers (sprint 5, step 5)
			var sks := p.find_children("*", "Skeleton3D", true, false)
			if not sks.is_empty():
				p.set_meta("look", Attention.head_look(sks[0] as Skeleton3D))
			skeletal_nodes.append(mi)
			var ap: AnimationPlayer = p.find_children("*", "AnimationPlayer", true, false)[0]
			ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			p.visible = false
			p.process_mode = Node.PROCESS_MODE_DISABLED
			add_child(p)
			pool.append(p)
		pools.append(pool)
	for i in n:
		if sim.kind[i] >= kinds.size():
			continue
		phase[i] = rng.randf() * clip_walk[sim.kind[i]]["seconds"]
		rate[i] = sim.speed[i] / natural[sim.kind[i]]


func _anim_t(i: int, g: float) -> float:
	var c := _clip(i)
	if c != "Walk":
		return fposmod(g + phase[i], float(clips_of[sim.kind[i]][c]["seconds"]))
	var dur: float = clip_walk[sim.kind[i]]["seconds"]
	return fposmod(g * rate[i] + phase[i], dur)


## The clip a walker's state asks for: walking, standing, or sat as it sits where its figure has the sit baked
## (TownSim's chair, crouch and cross-legged states; else it stands).
func _clip(i: int) -> String:
	if not sim.walkers_on or sim.state[i] == 0:
		return "Walk"
	var sit := String(SITS.get(int(sim.state[i]), ""))
	return sit if sit != "" and clips_of[sim.kind[i]].has(sit) else "Idle_A"


func _promote(i: int, to: int, g: float) -> void:
	var k: int = sim.kind[i]
	if tier[i] == 0:
		var p: Node3D = pools[k].pop_back()
		p.visible = true
		p.process_mode = Node.PROCESS_MODE_INHERIT
		(p.find_children("*", "MeshInstance3D", true, false)[0] as GeometryInstance3D).set_instance_shader_parameter("tint", tint[i])
		var ap: AnimationPlayer = p.find_children("*", "AnimationPlayer", true, false)[0]
		var c := _clip(i)
		ap.play(c)
		ap.seek(_anim_t(i, g), true)
		if not p.has_meta("wheel"):  # a hand wheel's bone, if its archetype carries one (ISS-124)
			p.set_meta("wheel", HandWheel.of(p))
		node_of[i] = [p, ap, c, p.get_meta("wheel")]
	tier[i] = to


func _demote(i: int) -> void:
	var pa: Array = node_of[i]
	var p: Node3D = pa[0]
	(pa[1] as AnimationPlayer).stop()
	p.visible = false
	if not (pa[3] as Array).is_empty():
		HandWheel.whirr(p, Vector3.INF)  # (stopped)
	p.process_mode = Node.PROCESS_MODE_DISABLED
	pools[sim.kind[i]].append(p)
	node_of.erase(i)
	tier[i] = 0


## A candidate's place in the queue for the skeletal tiers: its distance squared, a market stall's keeper counted as
## KEEPER_FAR times as far (chapter 05, 13.1: the keepers, who hardly move, are the first moved down; M2 sprint 10).
func _rank(i: int) -> float:
	return dist2[i] * (KEEPER_FAR * KEEPER_FAR if sim.keeper.size() > i and sim.keeper[i] == 1 else 1.0)


func update(cam: Vector3) -> void:
	var t0 := Time.get_ticks_usec()
	var g: float = WorldClock.anim_time
	frame += 1
	var n: int = sim.count
	# 1. Who should be skeletal: the nearest, within the radii (10% further for those already there), up to the caps.
	var cand := []
	var near_lim := NEAR_R * HYST
	var walkers: bool = sim.walkers_on
	for i in n:
		if sim.kind[i] >= kinds.size():
			continue
		var d: float = (sim.pos[i] as Vector3).distance_squared_to(cam)
		dist2[i] = d
		if walkers and sim.state[i] == 0:  # the walk's rate from its speed, its phase carried over the change
			var r := clampf(float(sim.cur_speed[i]) / natural[sim.kind[i]], 0.4, 2.2)
			if absf(r - rate[i]) > 0.02:
				phase[i] = fposmod(phase[i] + g * (rate[i] - r), float(clip_walk[sim.kind[i]]["seconds"]))
				rate[i] = r
		if d < near_lim * near_lim and not (walkers and sim.state[i] == 2):
			cand.append(i)
	cand.sort_custom(func(a, b): return _rank(a) < _rank(b))
	var want := {}
	var nh := 0
	var nn := 0
	for i in cand:
		var d := sqrt(dist2[i])
		var w := 0
		if forced >= 0:
			w = forced
		elif d < HERO_R * (HYST if tier[i] == 2 else 1.0) and nh < HERO_CAP:
			w = 2
			nh += 1
		elif d < NEAR_R * (HYST if tier[i] >= 1 else 1.0) and nn < NEAR_CAP:
			w = 1
			nn += 1
		if w != tier[i]:
			want[i] = w
	# 2. Everyone skeletal who is no longer a candidate goes back to VAT.
	for i in node_of.keys():
		if not cand.has(i):
			want[i] = 0
	# 3. At most two swaps, nearest first.
	var changes: Array = want.keys()
	changes.sort_custom(func(a, b): return dist2[a] < dist2[b])
	swaps = 0
	for i in changes:
		if swaps >= MAX_SWAPS and forced < 0:
			break
		var w: int = want[i]
		if w == 0:
			_demote(i)
		else:
			_promote(i, w, g)
		swaps += 1
	# 4. Draw: skeletal nodes follow their agent, heroes animate every frame, near people every other frame;
	#    everyone else goes into the MultiMesh buffers.
	counts = {"hero": 0, "near": 0, "vat": 0}
	for i in n:
		var k: int = sim.kind[i]
		if k >= kinds.size():
			continue
		if walkers and sim.state[i] == 2:  # indoors
			VatSet.hide(bufs[k], slot[i])
			if tier[i] > 0:  # out of sight at once; handed back to the pool within a frame or two
				(node_of[i][0] as Node3D).visible = false
			continue
		if tier[i] == 0:
			var vc := _clip(i)
			if vc != "Walk":
				var cd: Dictionary = clips_of[k][vc]
				VatSet.put(bufs[k], slot[i], sim.pos[i], sim.yaw[i], 1.0, tint[i], cd, phase[i] * cd["fps"], 1.0)
			else:
				VatSet.put(bufs[k], slot[i], sim.pos[i], sim.yaw[i], 1.0, tint[i], clip_walk[k], phase[i] * clip_walk[k]["fps"], rate[i])
			counts["vat"] += 1
		else:
			VatSet.hide(bufs[k], slot[i])
			var pa: Array = node_of[i]
			var p: Node3D = pa[0]
			p.visible = true  # back out of a door before its demotion came
			p.position = sim.pos[i]
			p.rotation.y = sim.yaw[i]
			var c := _clip(i)
			if c != String(pa[2]):  # set off or come to a stop: the other clip
				(pa[1] as AnimationPlayer).play(c)
				pa[2] = c
			if tier[i] == 2 or (frame + i) % 2 == 0:
				(pa[1] as AnimationPlayer).seek(_anim_t(i, g), true)
				if not (pa[3] as Array).is_empty():  # a hand wheel turning, and heard near (ISS-124)
					HandWheel.spin(pa[3], g, phase[i])
					HandWheel.whirr(p, cam)
			counts["hero" if tier[i] == 2 else "near"] += 1
	for k in kinds.size():
		mmis[k].multimesh.buffer = bufs[k]
	last_us = Time.get_ticks_usec() - t0


## The hero tier's people, for the attention budget (characters/attention.gd): [id, figure, head look, interest].
func lookers() -> Array:
	var out := []
	for i in node_of:
		var p: Node3D = node_of[i][0]
		if tier[i] == 2 and p.visible and p.has_meta("look"):
			out.append(["crowd%d" % i, p, p.get_meta("look"), 1.0])
	return out
