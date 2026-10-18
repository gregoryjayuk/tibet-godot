extends Node3D
## The named eight of M1's slice (plan chapter 05, 4.2; chapter 12, 3.1; M1 sprint 6, step 3), and since step 4 its
## twelve generic people (data/generic_days.json), who sit, talk and crouch through their days as the eight do: TownSim's walkers of
## kind NAMED (tools/town/graph.py reads their days from data/named_days.json), each drawn as its own body
## (assets/generated/people/<key>.glb, ../tibet-blender/people2/body.py), always skeletal: its gait at the speed that
## keeps its feet planted (named_clips.json; the women walk with Walk_Female, a running Nyima with Run_Female),
## standing, talking, crouched, or sitting down on its seat, seated and getting up (Sitting_Enter as the sit begins and
## Sitting_Exit as it ends: TownSim's knots say when), turning to its seat's way over a moment.
## In play Nyima follows a new player for a while (chapter 05, 4.2: "16:00 follows the player if the player is new";
## 9.6: a child trails the player for 20-40 m and stares, and scatters when the player turns on him): while his day has
## him standing at Tsongra and the player walks past him within 12 m (going away from him), he falls in about 3 m behind
## on the player's own trail, so his feet go where the player's went, for 20-40 m of the player's walking, until the
## player has stood still for 8 s, or 45 s in all; then he stands and watches the player, and walks back along the trail
## to his place. Turned on within 5 m, he scatters 4 m back down the trail, waits, and comes on again. He follows again
## a minute after he is back.
## Their heads, and the crowd's hero tier's, glance at the player under the attention budget (characters/attention.gd).
## With the clock frozen (the stills) every pose is set from the animation clock, so a still is the same each time.

const Attention := preload("res://characters/attention.gd")
const HandWheel := preload("res://characters/hand_wheel.gd")
const PERSON := preload("res://characters/person.gdshader")
const CLIPS := "res://assets/generated/people/named_clips.json"
const WOMEN := ["achak_dolkar", "kalsang_drolma", "tsomo_nomad", "stall_woman", "porter_woman", "elder_woman", "girl",
		"nomad_woman", "cook", "kitchen_woman", "water_woman", "water_woman_b", "water_woman_c", "water_woman_d", "water_girl",
		"water_girl_b", "lookout_woman", "yangchen_drolma", "pema_wife", "headman_grandmother", "headman_steward",
		"headman_kitchen_girl"]
## Chapter 05, 9.6's interest: a child ×3, an elder ×1.5, a busy worker ×0.3 (Pasang at his carving, the porters under
## their loads, the stallholders at their trade)
const INTEREST := {"nyima_boy": 3.0, "boy": 3.0, "girl": 3.0, "sonam_wangyal": 1.5, "elder_man": 1.5, "elder_woman": 1.5,
		"pasang_carver": 0.3, "porter": 0.3, "porter_woman": 0.3, "stall_man": 0.3, "stall_woman": 0.3, "cook": 0.3, "kitchen_woman": 0.3}
const HIDE := 300.0  ## not drawn further off
const TURN := 3.0  ## rad/s: a figure come to a stop turns to its seat's way
const BLEND := 0.3
const RUN_OVER := 2.2  ## m/s: faster than this, a figure runs
const FOLLOW_NEAR := 12.0
const FOLLOW_BACK := 3.0
const FOLLOW_MAX := 45.0
const FOLLOW_BORED := 8.0  ## seconds of a player standing still before he loses interest
const FOLLOW_AGAIN := 60.0
const SCATTER := 4.0
const EYES := 1.55  ## the player's eyes over its feet, for the glances

var sim: Node  ## TownSim
var crowd: Node  ## its hero tier glances at the player too
var player: Node3D  ## in play: whom Nyima follows and the heads glance at (none in the stills)
var attention: Node
var people := {}  ## walker -> {key, root, ap, clip, yaw, indoor, meshes, walk: [clip, m/s], run: [clip, m/s], enter, exit, phase, look}
var _interiors: Node = null  ## world/interiors.gd, for who is in a room
var nyima := -1
var follow := {}  ## Nyima's following while it lasts: mode, along the trail, and what he shows (pos, yaw, speed, state)
var overrides := {}  ## walker -> {pos, yaw, speed, state[, clip]}: another controller places it (the caravan's drovers, world/caravan.gd; the tea's host, world/tea.gd, with the clip she pours in)
var follow_rest := 0.0
var follows := 0  ## times Nyima has fallen in behind the player (the tests')
var scatters := 0
var last_us := 0  ## the cost of the last update, for the walkers spike
var _trail := PackedVector3Array()  ## the player's way while Nyima follows: his place, then a point every 0.3 m
var _cum := PackedFloat32Array()  ## metres along the trail at each point
var _rng := RandomNumberGenerator.new()


func setup(p_sim: Node, p_crowd: Node = null) -> void:
	add_to_group("named")  # the tea's host is turned to her guest through `overrides` (world/tea.gd)
	sim = p_sim
	crowd = p_crowd
	_rng.seed = 1903
	attention = Attention.new()
	attention.name = "Attention"
	add_child(attention)
	var info = JSON.parse_string(FileAccess.get_file_as_string(CLIPS)) if FileAccess.file_exists(CLIPS) else null
	var mat := ShaderMaterial.new()
	mat.shader = PERSON
	for i in sim.count:
		if sim.kind[i] != sim.NAMED:
			continue
		var k: String = sim.key[i]
		var path := "res://assets/generated/people/%s.glb" % k
		if not ResourceLoader.exists(path) or info == null or not (info["bodies"] as Dictionary).has(k):
			push_warning("named: no body for %s; run ../tibet-blender/people2/body.py" % k)
			continue
		var root: Node3D = (load(path) as PackedScene).instantiate()
		root.name = k
		PersonLook.apply(root, mat)
		var ap: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		var c: Dictionary = info["bodies"][k]
		var walk := "Walk_Female" if k in WOMEN and c.has("Walk_Female") else "Walk"
		var run := "Run_Female" if c.has("Run_Female") else walk
		for n in [walk, run, "Idle_A", "Idle_Talking", "Sitting_Idle", "Crouch_Idle", "Sitting_Cross"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		var sk: Skeleton3D = root.find_children("*", "Skeleton3D", true, false)[0]
		add_child(root)
		for g in root.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		people[i] = {"key": k, "root": root, "ap": ap, "clip": "", "yaw": float(sim.yaw[i]), "indoor": 0.0,
				"meshes": root.find_children("*", "MeshInstance3D", true, false),
				"walk": [walk, float(c[walk]["speed"])], "run": [run, float(c[run]["speed"])],
				"enter": float((c.get("Sitting_Enter", {}) as Dictionary).get("seconds", 1.6)),
				"exit": float((c.get("Sitting_Exit", {}) as Dictionary).get("seconds", 1.3)),
				"phase": _rng.randf() * 3.0, "look": Attention.head_look(sk)}
		if k == "nyima_boy":
			nyima = i


## One frame, after TownSim's step: each figure where its day has it, in the clip its state and speed call for.
func update(dt: float, eye: Vector3) -> void:
	var t0 := Time.get_ticks_usec()
	for c in get_tree().get_nodes_in_group("named_placers"):  # who places figures for a while, on this frame's minute
		c.call("place", self)  # (world/spring.gd: the water carriers in the Lukhang spring's yard)
	var frozen: bool = WorldClock.frozen
	var g: float = WorldClock.anim_time
	if nyima >= 0 and people.has(nyima) and player != null and not frozen:
		_follow(dt)
	var cands := []
	for i in people:
		var P: Dictionary = people[i]
		var root: Node3D = P["root"]
		var st: int = sim.state[i]
		var pos: Vector3 = sim.pos[i]
		var yaw: float = sim.yaw[i]
		var spd: float = sim.cur_speed[i]
		if i == nyima and not follow.is_empty():
			st = follow["state"]
			pos = follow["pos"]
			yaw = follow["yaw"]
			spd = follow["speed"]
		if overrides.has(i):
			var o: Dictionary = overrides[i]
			st = o["state"]
			pos = o["pos"]
			yaw = o["yaw"]
			spd = o["speed"]
		var shown := st != 2 and pos.distance_to(eye) < HIDE
		if root.visible != shown:
			root.visible = shown
			root.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED
			P["clip"] = ""
		if not P.has("wheel"):
			P["wheel"] = HandWheel.of(root)
		if not shown:
			if not (P["wheel"] as Array).is_empty():
				HandWheel.whirr(root, eye)  # (stopped: not drawn)
			continue
		root.position = pos
		_indoors(P, pos)
		P["yaw"] = yaw if st == 0 or frozen or P["clip"] == "" else _turn(float(P["yaw"]), yaw, TURN * dt)
		root.rotation.y = P["yaw"]
		var clip := "Idle_A"
		var at := -1.0  # a set point in the clip (sitting down, getting up), or -1 to loop it
		var speed := 1.0
		match st:
			0:
				var gait: Array = P["run"] if spd > minf(RUN_OVER, float(P["walk"][1]) * 2.3) else P["walk"]  # a child runs sooner
				clip = gait[0]
				speed = clampf(spd / maxf(float(gait[1]), 0.1), 0.3, 2.5)
			3:
				var span: Vector2 = sim.rest_span(i)
				var r: float = WorldClock.RATE_PLAY if frozen else maxf(WorldClock.rate, 0.0001)
				var since: float = (sim.day_minute - span.x) / r  # real seconds since it came to its seat
				var left: float = (span.y - sim.day_minute) / r
				clip = "Sitting_Idle"
				if since < float(P["enter"]):
					clip = "Sitting_Enter"
					at = since
				elif left < float(P["exit"]):
					clip = "Sitting_Exit"
					at = float(P["exit"]) - left
			4:
				clip = "Idle_Talking"
			5:
				clip = "Crouch_Idle"
			6:  # cross-legged on a Tibetan bench or the floor (ISS-088): its hips where the day's seat has them
				clip = "Sitting_Cross" if (P["ap"] as AnimationPlayer).has_animation("Sitting_Cross") else "Sitting_Idle"
		if overrides.has(i) and (overrides[i] as Dictionary).has("clip"):
			clip = String(overrides[i]["clip"])
		_play(P, clip, speed, at, frozen, g)
		if not (P["wheel"] as Array).is_empty():  # an elder's hand wheel turning, and heard near (ISS-124)
			HandWheel.spin(P["wheel"], g, float(P["phase"]))
			HandWheel.whirr(root, eye)
		var w: float = INTEREST.get(P["key"], 1.0) * (2.0 if i == nyima and not follow.is_empty() else 1.0)
		cands.append([P["key"], root, P["look"], w])
	if player != null and not frozen:
		if crowd != null and crowd.has_method("lookers"):
			cands.append_array(crowd.lookers())
		var v: Vector3 = player.get("velocity") if player is CharacterBody3D else Vector3.ZERO
		attention.update(dt, player.global_position + Vector3(0.0, EYES, 0.0), 2.0 if Vector2(v.x, v.z).length() > 3.0 else 1.0, cands)
	last_us = Time.get_ticks_usec() - t0


func _play(P: Dictionary, clip: String, speed: float, at: float, frozen: bool, g: float) -> void:
	var ap: AnimationPlayer = P["ap"]
	if not ap.has_animation(clip):
		clip = "Idle_A"
	if frozen:  # the stills: the pose from the animation clock alone
		if P["clip"] != clip:
			ap.play(clip)
			P["clip"] = clip
		ap.speed_scale = 0.0
		var length := ap.get_animation(clip).length
		ap.seek(at if at >= 0.0 else fposmod(g * speed + float(P["phase"]), length), true)
		return
	if P["clip"] != clip:
		ap.play(clip, BLEND if P["clip"] != "" else 0.0)
		if P["clip"] == "" or at >= 0.0:
			ap.seek(at if at >= 0.0 else fposmod(g + float(P["phase"]), ap.get_animation(clip).length), true)
		P["clip"] = clip
	ap.speed_scale = speed if at < 0.0 else 1.0


## In one of the town's rooms (world/interiors.gd), a figure is drawn as indoors: no sky's light, the sun only through
## the door (characters/person.gdshader's `indoor`; sprint 7, step 3).
func _indoors(P: Dictionary, pos: Vector3) -> void:
	if _interiors == null:
		_interiors = get_tree().get_first_node_in_group("interiors")
		if _interiors == null:
			return
	var v := 1.0 if _interiors.call("room_at", pos + Vector3(0.0, 1.0, 0.0)) != null else 0.0
	if v != float(P["indoor"]):
		P["indoor"] = v
		for mi in P["meshes"]:
			(mi as MeshInstance3D).set_instance_shader_parameter("indoor", v)


static func _turn(from: float, to: float, most: float) -> float:
	var d := wrapf(to - from, -PI, PI)
	return from + clampf(d, -most, most)


# ------------------------------------------------------------------ Nyima follows the player (chapter 05, 9.6)
func _follow(dt: float) -> void:
	var i := nyima
	var pp := player.global_position
	if follow.is_empty():
		follow_rest -= dt
		if follow_rest > 0.0 or sim.state[i] != 1:
			return
		var stop: Array = sim.stop_now(i)
		if String(stop[0]) != "tsongra" or float(stop[1]) > sim.day_minute or float(stop[2]) - sim.day_minute < 10.0:
			return
		var np: Vector3 = sim.pos[i]
		var from_him := Vector2(pp.x - np.x, pp.z - np.z)
		if from_him.length() > FOLLOW_NEAR or from_him.length() < 0.5 or absf(pp.y - np.y) > 2.5:
			return
		var pf := _forward()
		if Vector2(pf.x, pf.z).dot(from_him.normalized()) < 0.3:  # only once the player has walked past, going away
			return
		_trail = PackedVector3Array([np, pp])
		_cum = PackedFloat32Array([0.0, np.distance_to(pp)])
		follow = {"mode": "trail", "along": 0.0, "walked": 0.0, "limit": _rng.randf_range(20.0, 40.0), "t": 0.0,
				"still": 0.0, "wait": 0.0, "stop": stop, "pos": np, "yaw": float(sim.yaw[i]), "speed": 0.0, "state": 1}
		follows += 1
		return
	var last := _trail[_trail.size() - 1]
	var step := Vector2(pp.x - last.x, pp.z - last.z).length()
	if step >= 0.3:
		_trail.append(pp)
		_cum.append(_cum[_cum.size() - 1] + last.distance_to(pp))
		follow["walked"] += step
	var moved := Vector2(pp.x - float(follow.get("px", pp.x)), pp.z - float(follow.get("pz", pp.z))).length()
	follow["still"] = float(follow["still"]) + dt if moved < 0.2 * dt else 0.0
	follow["px"] = pp.x
	follow["pz"] = pp.z
	follow["t"] += dt
	var L := _cum[_cum.size() - 1] + Vector2(pp.x - _trail[_trail.size() - 1].x, pp.z - _trail[_trail.size() - 1].z).length()
	var along: float = follow["along"]
	var v := 0.0  # m/s along the trail, backwards if less than 0
	var me := _trail_at(along)
	var to_me := Vector2(me.x - pp.x, me.z - pp.z)
	match String(follow["mode"]):
		"trail":
			var gap := L - along
			v = clampf((gap - FOLLOW_BACK) * 1.5, 0.0, 5.0)
			if v < 0.15:
				v = 0.0
			var fwd := _forward()
			if to_me.length() < 5.0 and to_me.length() > 0.1 and absf(rad_to_deg(Vector2(fwd.x, fwd.z).angle_to(to_me))) < 35.0:
				follow["mode"] = "scatter"  # turned on: off he goes, back down the trail
				follow["until"] = maxf(0.0, along - SCATTER)
				scatters += 1
			elif float(follow["walked"]) >= float(follow["limit"]) or float(follow["t"]) > FOLLOW_MAX or float(follow["still"]) > FOLLOW_BORED or sim.stop_now(i) != follow["stop"]:
				follow["mode"] = "watch"
				follow["wait"] = 2.5
		"scatter":
			v = -3.0
			if along <= float(follow["until"]) + 0.05:
				follow["mode"] = "wait"
				follow["wait"] = 1.5
		"wait":
			follow["wait"] -= dt
			if float(follow["wait"]) <= 0.0:
				follow["mode"] = "trail"
		"watch":
			follow["wait"] -= dt
			if float(follow["wait"]) <= 0.0:
				follow["mode"] = "back"
		"back":
			v = -1.1
			if along <= 0.01:
				follow = {}
				follow_rest = FOLLOW_AGAIN
				return
	along = clampf(along + v * dt, 0.0, maxf(0.0, L - FOLLOW_BACK) if v > 0.0 else L)
	follow["along"] = along
	var p := _trail_at(along)
	follow["pos"] = p
	follow["speed"] = absf(v)
	follow["state"] = 0 if absf(v) > 0.01 else 1
	if absf(v) > 0.01:  # moving: he faces the way he goes, on or back down the trail
		var d := _trail_at(along + signf(v) * 0.3) - p
		if Vector2(d.x, d.z).length() > 0.01:
			follow["yaw"] = atan2(d.x, d.z)
	else:  # stopped: he faces the player and stares
		follow["yaw"] = atan2(pp.x - p.x, pp.z - p.z)


## The way the player faces: its body's yaw (player/player.gd), or the node's own -Z.
func _forward() -> Vector3:
	var f = player.get("facing")
	return Vector3(-sin(float(f)), 0.0, -cos(float(f))) if f != null else -player.global_transform.basis.z


func _trail_at(s: float) -> Vector3:
	if _trail.size() == 1 or s <= 0.0:
		return _trail[0]
	for k in range(1, _cum.size()):
		if s <= _cum[k]:
			var f := (s - _cum[k - 1]) / maxf(_cum[k] - _cum[k - 1], 0.0001)
			return _trail[k - 1].lerp(_trail[k], f)
	return _trail[_trail.size() - 1]
