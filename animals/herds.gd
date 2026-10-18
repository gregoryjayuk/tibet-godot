extends Node3D
## Chapter 06's animals for spike S5 (roadmap RT-13): a grazing herd of 130 yak, a caravan ribbon of 72 in single
## file, 16 skeletal yak near the player and 300 birds in six flocks. The yak is Mesh2Motion's CC0 horse, scaled and
## coloured as a stand-in (people2/stand_ins.py), the bird its CC0 bird; both drawn as VAT MultiMeshes except the 16.
## Herds are data like TownSim's people: the herd wanders at a grazing pace and changes step every few seconds; the
## ribbon follows a path at a walking pace, one animal every 3 m; the birds circle on the GPU (characters/
## vat_orbit.gdshader), so after set-up they cost the main thread nothing. `last_us`: the script's cost a frame.

const YAK_SPEED := 1.36  ## the yak Walk clip's pace, from the bake (people2/stand_ins.py)
const PERSON := preload("res://characters/person.gdshader")
const ORBIT := preload("res://characters/vat_orbit.gdshader")

var yak: VatSet
var bird: VatSet
var herd_mmi: MultiMeshInstance3D
var ribbon_mmi: MultiMeshInstance3D
var bird_mmi: MultiMeshInstance3D
var herd_buf := PackedFloat32Array()
var ribbon_buf := PackedFloat32Array()
var bird_buf := PackedFloat32Array()
var herd_pos := PackedVector3Array()
var herd_yaw := PackedFloat32Array()
var herd_speed := PackedFloat32Array()
var herd_next := PackedFloat32Array()
var herd_clip: Array[Dictionary] = []
var herd_phase := PackedFloat32Array()
var path := PackedVector3Array()  ## the ribbon's path, as a polyline
var path_len := PackedFloat32Array()  ## the cumulative length at each point
var path_y := PackedFloat32Array()  ## the ground's height at each point (a path's points are close enough to lerp)
var skel: Array = []  ## the 16 skeletal yak: [node, AnimationPlayer, centre, radius, angle, speed]
var flocks: Array = []  ## [centre, radius, height, angular speed]
var ground: Callable  ## ground(x, z) -> y
var time := 0.0
var last_us := 0
var frame := 0
var rng := RandomNumberGenerator.new()


func setup(p_ground: Callable, meadow: Rect2, p_path: PackedVector3Array, skel_centre: Vector3, bounds: AABB) -> void:
	ground = p_ground
	rng.seed = 1906
	yak = VatSet.open("yak")
	bird = VatSet.open("bird")
	var clips := ["Idle", "Eating", "Walk"]
	herd_mmi = yak.multimesh(130, bounds)
	add_child(herd_mmi)
	herd_buf.resize(130 * VatSet.FLOATS)
	herd_pos.resize(130)
	herd_yaw.resize(130)
	herd_speed.resize(130)
	herd_next.resize(130)
	herd_phase.resize(130)
	for i in 130:
		var x := rng.randf_range(meadow.position.x, meadow.end.x)
		var z := rng.randf_range(meadow.position.y, meadow.end.y)
		herd_pos[i] = Vector3(x, ground.call(x, z), z)
		herd_yaw[i] = rng.randf() * TAU
		herd_clip.append(yak.clip(clips[rng.randi_range(0, 1)]))
		herd_next[i] = rng.randf() * 6.0
		herd_phase[i] = rng.randf() * 60.0
	ribbon_mmi = yak.multimesh(72, bounds)
	add_child(ribbon_mmi)
	ribbon_buf.resize(72 * VatSet.FLOATS)
	path = p_path
	path_len.resize(path.size())
	path_y.resize(path.size())
	for j in path.size():
		path_y[j] = ground.call(path[j].x, path[j].z)
		if j > 0:
			path_len[j] = path_len[j - 1] + path[j].distance_to(path[j - 1])
	bird.material.shader = ORBIT
	bird_mmi = bird.multimesh(300, bounds)
	add_child(bird_mmi)
	bird_buf.resize(300 * VatSet.FLOATS)
	for f in 6:
		flocks.append([Vector3(rng.randf_range(-150, 150), 0.0, rng.randf_range(-150, 150)), rng.randf_range(25.0, 60.0),
				rng.randf_range(40.0, 90.0), rng.randf_range(0.15, 0.3) * (1.0 if rng.randf() < 0.5 else -1.0)])
	_birds()
	var mat := ShaderMaterial.new()
	mat.shader = PERSON
	var scene: PackedScene = load("res://assets/generated/people/yak.glb")
	for j in 16:
		var p: Node3D = scene.instantiate()
		(p.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).material_override = mat
		var ap: AnimationPlayer = p.find_children("*", "AnimationPlayer", true, false)[0]
		ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		ap.play("Walk" if j % 2 == 0 else "Eating")
		add_child(p)
		skel.append([p, ap, skel_centre, rng.randf_range(4.0, 14.0), rng.randf() * TAU, 0.9 if j % 2 == 0 else 0.0])


## The birds, once: six flocks of fifty, each bird on its own ring, height and phase; the GPU flies them.
func _birds() -> void:
	var flap := bird.clip("Flap")
	var glide := bird.clip("Glide")
	for i in 300:
		var f: Array = flocks[i % 6]
		var o := i * VatSet.FLOATS
		var ctr: Vector3 = f[0]
		var c: Dictionary = flap if (i % 3) != 0 else glide
		bird_buf[o] = f[1] * (0.7 + 0.6 * float((i * 37) % 50) / 50.0)  # column 0: radius, angular speed, phase
		bird_buf[o + 4] = f[3]
		bird_buf[o + 8] = float(i) * 0.61
		bird_buf[o + 1] = 4.0  # column 1: the bob
		bird_buf[o + 3] = ctr.x  # origin: the ring's centre
		bird_buf[o + 7] = f[2]
		bird_buf[o + 11] = ctr.z
		for k in 4:
			bird_buf[o + 12 + k] = 1.0
		bird_buf[o + 16] = c["row"]
		bird_buf[o + 17] = c["frames"]
		bird_buf[o + 18] = float(i) * 1.3
		bird_buf[o + 19] = 1.0
	bird_mmi.multimesh.buffer = bird_buf


func update(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	time += dt
	frame += 1
	var g: float = WorldClock.anim_time
	var walk := yak.clip("Walk")
	# The herd: most graze in place; every few seconds one takes a few steps somewhere else. Only walkers and animals
	# that have just changed what they do are rewritten.
	for i in 130:
		var changed := frame == 1
		if time >= herd_next[i]:
			changed = true
			herd_next[i] = time + rng.randf_range(3.0, 9.0)
			if rng.randf() < 0.3:
				herd_speed[i] = 0.5
				herd_yaw[i] += rng.randf_range(-1.2, 1.2)
				herd_clip[i] = walk
			else:
				herd_speed[i] = 0.0
				herd_clip[i] = yak.clip("Eating" if rng.randf() < 0.6 else "Idle")
		if herd_speed[i] > 0.0:
			var p := herd_pos[i] + Vector3(sin(herd_yaw[i]), 0.0, cos(herd_yaw[i])) * herd_speed[i] * dt
			p.y = ground.call(p.x, p.z)
			herd_pos[i] = p
			changed = true
		if changed:
			var c: Dictionary = herd_clip[i]
			VatSet.put(herd_buf, i, herd_pos[i], herd_yaw[i], 1.0, 1.0 + (float(i % 7) - 3.0) * 0.02, c, herd_phase[i], herd_speed[i] / YAK_SPEED if herd_speed[i] > 0.0 else 1.0)
	herd_mmi.multimesh.buffer = herd_buf
	# The ribbon: one animal every 3 m along the path at 1 m/s, looping.
	var total := path_len[path.size() - 1]
	var seg := 0
	for i in 72:
		var s := fposmod(time * 1.0 - i * 3.0, total)
		while seg > 0 and path_len[seg] > s:
			seg -= 1
		while seg < path.size() - 2 and path_len[seg + 1] < s:
			seg += 1
		var a := path[seg]
		var b := path[seg + 1]
		var t := (s - path_len[seg]) / maxf(path_len[seg + 1] - path_len[seg], 0.001)
		var p := a.lerp(b, t)
		p.y = lerpf(path_y[seg], path_y[seg + 1], t)
		VatSet.put(ribbon_buf, i, p, atan2(b.x - a.x, b.z - a.z), 1.0, 1.0, walk, float(i) * 3.7, 1.0 / YAK_SPEED)
	ribbon_mmi.multimesh.buffer = ribbon_buf
	# The 16 skeletal yak, walking circles or grazing, animated at 15 Hz.
	for j in skel.size():
		var s: Array = skel[j]
		var p: Node3D = s[0]
		if s[5] > 0.0:
			s[4] += s[5] / s[3] * dt
			var ctr: Vector3 = s[2]
			var q := ctr + Vector3(cos(s[4]) * s[3], 0.0, sin(s[4]) * s[3])
			q.y = ground.call(q.x, q.z)
			p.position = q
			p.rotation.y = atan2(-sin(s[4]), cos(s[4]))
		else:
			var ctr: Vector3 = s[2]
			var q := ctr + Vector3(cos(s[4]) * s[3], 0.0, sin(s[4]) * s[3])
			q.y = ground.call(q.x, q.z)
			p.position = q
		if (frame + j) % 2 == 0:
			var ap: AnimationPlayer = s[1]
			var dur := ap.current_animation_length
			ap.seek(fposmod(g * (s[5] / YAK_SPEED if s[5] > 0.0 else 1.0) + j * 0.7, dur), true)
	last_us = Time.get_ticks_usec() - t0
