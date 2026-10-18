extends Node3D
## Spike S19, fists and the sling (plan chapter 11, 13.8; chapter 14, 3): the practice yard on the kit street at 14:00.
## The player (third person), a sparring partner (characters/sparring.gd), six pots on a low wall and a straw target.
## Modes (after --): --play, fight it yourself (tools/play.sh fight); without it, a scripted sequence with one still a
## moment to tests/player/out/ (tools/player/fight.sh): the face-off, a jab landing, the partner's jab landing, a jab
## seen from 10 m, a jab dodged, a knock-down, the sling whirling 15 m from the pots (and closer), the stone loosed,
## a pot falling.
## S19 passes when a fight reads at 10 m and the sling hits a pot at 15 m (chapter 11, 13.8). With --time, the same
## sequence in real time and without stills, reporting the frame intervals ("no dropped frames while fighting").

const Vignette := preload("res://world/vignette.gd")
const DayCycle := preload("res://world/day.gd")
const Horizon := preload("res://world/horizon.gd")
const PlayerScript := preload("res://player/player.gd")
const Sparring := preload("res://characters/sparring.gd")
const Target := preload("res://props/straw_target.gd")
const Hud := preload("res://ui/hud.gd")
const Ink := preload("res://world/ink.gd")
const OUT := "res://tests/player/out"
const CANVAS := Vector2i(1920, 1080)
const HOME := Vector3(18.9, 0.05, 13.0)
const WALL := Vector3(12.8, 0.0, 12.0)
const TARGET := Vector3(24.0, 0.0, 11.5)

var look: Node3D
var player: CharacterBody3D
var partner: CharacterBody3D
var play := false
var steps: Array = []
var shot := ""
var wait := 0.0
var total := 0
var view: Camera3D  ## a fixed camera for the shots the player's cannot frame: the fight from 10 m, the pots
var timing := false
var intervals := PackedFloat32Array()
var _last_us := 0


func _ready() -> void:
	play = "--play" in OS.get_cmdline_user_args()
	timing = "--time" in OS.get_cmdline_user_args()
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = CANVAS
	get_viewport().scaling_3d_scale = 1.0
	if not play:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		WorldClock.freeze(20.0)
	seed(1903)
	look = Vignette.new()
	look.use_kit = true
	add_child(look)
	await look.build()
	var day := DayCycle.new()
	for c in look.get_children():
		if c is DirectionalLight3D:
			day.sun = c
		elif c is WorldEnvironment:
			day.env = (c as WorldEnvironment).environment
	add_child(day)
	Horizon.load_globals(Horizon.STREET_PLACE)
	player = PlayerScript.new()
	player.views = Vignette.VIEWS
	player.ink_air = true
	player.third_person = true
	player.scripted = not play
	add_child(player)
	player.global_position = HOME
	player.yaw = 0.0
	player.facing = 0.0
	player.pitch = -0.15
	player.reset_physics_interpolation()
	player.cam.current = true
	partner = Sparring.new()
	partner.target = player
	add_child(partner)
	partner.global_position = HOME + Vector3(0.0, 0.0, -1.0)
	partner.facing = PI
	_pots()
	var t := StaticBody3D.new()
	t.set_script(Target)
	add_child(t)
	t.global_position = TARGET
	if play:
		partner.global_position = HOME + Vector3(0.0, 0.0, -2.4)  # a pace off: he waits a moment for you to square up
		partner.rest_until = Time.get_ticks_msec() / 1000.0 + 2.5
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--tier="):  # tools/play.sh's sharp and native, as in the other play modes
				Quality.tier = arg.substr(7)
				Quality.base_tier = Quality.tier
		Quality.track(get_viewport())
		var hud := Hud.new()
		hud.show_clock = true
		hud.third_person = true
		hud.player = player
		add_child(hud)
		print("fight: play. R the fists up (then left button punch, right guard; R or Esc lowers them), Space jump (with the guard up, dodge), G sling (hold left to whirl, let go to loose); on a controller R1 punch, L1 guard, R2 the sling.")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	partner.passive = true
	player.fight.debug = true
	partner.fight.debug = true
	steps = [
		["face_off", 2.0, func(): _face_off()],
		["jab", 0.0, func(): _jab()],
		["partner_jab", 0.0, func(): _partner_jab()],
		["far", 0.0, func(): _far()],
		["dodge", 0.0, func(): _dodge()],
		["knockdown", 0.0, func(): _knockdown()],
		["sling_whirl", 0.9, func(): _sling_start()],
		["whirl_close", 0.15, func(): _whirl_close()],
		["sling_loose", 0.28, func(): _own_view(); player.fight.release()],
		["pots", 0.6, func(): _view(WALL + Vector3(3.2, 1.7, 3.6), WALL + Vector3(0.0, 1.1, 0.25))],
	]
	total = steps.size()
	_next()


func _pots() -> void:
	var wall := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 1.1, 3.2)
	cs.shape = box
	cs.position.y = 0.55
	wall.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	mi.position.y = 0.55
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#e6ded0")
	mi.material_override = m
	wall.add_child(mi)
	add_child(wall)
	wall.global_position = WALL
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color("#95593f")
	for i in 6:
		var pot := RigidBody3D.new()
		pot.name = "Pot%d" % i
		pot.mass = 0.8
		var pc := CollisionShape3D.new()
		var ps := CylinderShape3D.new()
		ps.radius = 0.13
		ps.height = 0.3
		pc.shape = ps
		pot.add_child(pc)
		var pmesh := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.09
		cm.bottom_radius = 0.13
		cm.height = 0.3
		cm.radial_segments = 10
		pmesh.mesh = cm
		pmesh.material_override = pm
		pot.add_child(pmesh)
		add_child(pot)
		pot.global_position = WALL + Vector3(0.0, 1.26, -1.25 + i * 0.5)


func _face(to: Vector3, side := 0.0) -> void:
	var d := to - player.global_position
	player.facing = atan2(-d.x, -d.z)
	player.yaw = player.facing + side  # `side` swings the camera round to see both fighters


func _face_off() -> void:
	partner.passive = false
	_face(partner.global_position, -1.1)


func _jab() -> void:
	partner.passive = true
	partner.fight.guard = false
	player.fight.action = ""
	player.fight.cooldown = 0.0
	_face(partner.global_position, -1.1)
	player.fight.strike()
	wait = float(player.fight.hit_at) + 0.04


func _partner_jab() -> void:
	player.fight.guard = false
	player.fight.action = ""
	partner.fight.action = ""  # still reeling from the jab
	partner.fight._then = ""
	_face(partner.global_position, 1.2)
	partner.fight.cooldown = 0.0
	partner.fight.strike()
	wait = float(partner.fight.hit_at) + 0.05


func _view(from: Vector3, at: Vector3, fov := 0.0) -> void:
	if view == null:
		view = Camera3D.new()
		add_child(view)
		Ink.attach(view)
	view.fov = fov if fov > 0.0 else player.cam.fov
	view.global_position = from
	view.look_at(at)
	view.current = true
	player.cam.get_node("Ink").visible = false  # the ink is a full-screen quad: one camera's at a time


func _own_view() -> void:
	player.cam.current = true
	player.cam.get_node("Ink").visible = true


func _far() -> void:
	partner.fight.action = ""
	partner.fight._then = ""
	partner.fight.guard = false
	player.fight.action = ""
	player.fight.cooldown = 0.0
	_face(partner.global_position)
	var mid := (player.global_position + partner.global_position) / 2.0
	var across := Vector3(cos(player.facing), 0.0, -sin(player.facing))  # at right angles to the line between them
	_view(mid + across * 10.0 + Vector3(0.0, 1.9, 0.0), mid + Vector3(0.0, 1.1, 0.0))
	player.fight.strike()
	wait = float(player.fight.hit_at) + 0.04


func _dodge() -> void:
	_own_view()
	partner.fight.action = ""
	partner.fight._then = ""
	player.fight.action = ""
	player.fight.cooldown = 0.0
	_face(partner.global_position, 1.2)
	partner.fight.dodge("back")
	player.fight.strike()
	wait = float(player.fight.hit_at) + 0.04


func _knockdown() -> void:
	partner.passive = true
	partner.fight.guard = false
	partner.fight.balance = 1
	partner.fight._last_blow = partner.fight.now()  # or the balance creeps back before the blow lands
	partner.fight.action = ""
	player.fight.cooldown = 0.0
	player.fight.action = ""
	player.fight._next_left = false  # the right jab, the longer reach
	_face(partner.global_position, 1.1)
	player.fight.strike()
	wait = float(player.fight.hit_at) + 0.3


func _sling_start() -> void:
	partner.passive = true
	partner.fight.action = ""
	partner.fight._then = ""
	partner.global_position = WALL + Vector3(2.4, 0.0, -2.6)  # out of the line of fire, watching
	var to := player.global_position - partner.global_position
	partner.facing = atan2(-to.x, -to.z)
	player.fight.action = ""
	player.fight.sling = true
	player.global_position = WALL + Vector3(15.0, 0.05, 1.0)  # 15 m from the pots
	var aim := WALL + Vector3(0.0, 1.35, 0.25)
	_face(aim, -0.5)
	player.pitch = -0.2
	player.fight.aim_point = aim
	player.fight.start_whirl()


## The whirl from above the right shoulder, where its slant shows.
func _whirl_close() -> void:
	var fwd := Vector3(-sin(player.facing), 0.0, -cos(player.facing))
	var right := Vector3(cos(player.facing), 0.0, -sin(player.facing))
	var hand: Vector3 = player.fight.hand_position("r")
	_view(player.global_position + right * 2.0 + fwd * 1.4 + Vector3(0.0, 2.4, 0.0), hand + Vector3(0.0, -0.1, 0.0), 38.0)


func _next() -> void:
	if steps.is_empty():
		if timing:
			var sorted := intervals.duplicate()
			sorted.sort()
			var over := 0
			for ms in intervals:
				over += 1 if ms > 50.0 else 0
			print("fight: timing %d frames, median %.1f ms, 99th %.1f ms, max %.1f ms, over 50 ms: %d" % [sorted.size(),
				sorted[sorted.size() / 2], sorted[int(sorted.size() * 0.99)], sorted[-1], over])
		print("fight: done in %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()
		return
	var s: Array = steps.pop_front()
	shot = s[0]
	wait = s[1]
	(s[2] as Callable).call()


func _process(dt: float) -> void:
	if play or shot == "":
		return
	if timing:
		var now := Time.get_ticks_usec()
		if _last_us > 0:
			intervals.append((now - _last_us) / 1000.0)
			if (now - _last_us) > 50000:
				print("fight: a %.0f ms frame in %s, frame %d" % [(now - _last_us) / 1000.0, shot, intervals.size()])
		_last_us = now
	if player.fight.sling and shot == "sling_loose" and wait > 0.0:
		player.fight.aim_point = WALL + Vector3(0.0, 1.35, 0.25)
	wait -= dt
	if wait > 0.0:
		return
	if not timing:
		var img := get_viewport().get_texture().get_image()
		var n := total - steps.size()
		img.save_png(ProjectSettings.globalize_path(OUT).path_join("fight_%d_%s.png" % [n, shot]))
	print("fight: %s  player %s  partner %s (balance %d)" % [shot, player.fight.action, partner.fight.action, partner.fight.balance])
	shot = ""
	_next()
