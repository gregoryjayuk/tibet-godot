extends Node3D
## The third-person player (M1 sprint 2, step 4; plan chapter 11, 13.1): the kit street at 14:00 with the day's light
## and the ridge map, the player scripted through a few moments, one still each to tests/player/out/: standing, walking
## and jogging away from the camera, sprinting (IMP-043: the sprint's clip, the camera further back and wider), walking
## across it (the body turns, the camera does not), the woman, the camera against a wall, first person, and the two
## bodies from the front; last, the breath run out at the sprint (the vignette, the jog it falls back to) with the help
## line as a PS4 controller reads it. Run: tools/player/tp.sh

const Vignette := preload("res://world/vignette.gd")
const DayCycle := preload("res://world/day.gd")
const Horizon := preload("res://world/horizon.gd")
const PlayerScript := preload("res://player/player.gd")
const Hud := preload("res://ui/hud.gd")
const OUT := "res://tests/player/out"
const CANVAS := Vector2i(1920, 1080)
## [name, seconds to run it, strafe, forward (-1 ahead), the pace (false or 0 the walk, true or 1 the jog, 2 the sprint),
## yaw turn in radians at the start, woman, first person, a place to stand first (feet, Godot axes) or null, with the
## camera's yaw there]
const STEPS := [
	["idle", 1.5, 0.0, 0.0, false, 0.0, false, false, null, 0.0],
	["walk", 2.0, 0.0, -1.0, false, 0.0, false, false, null, 0.0],
	["turn_walk", 2.0, 0.0, -1.0, false, 1.3, false, false, null, 0.0],
	["run", 1.5, 0.0, -1.0, true, 0.0, false, false, Vector3(14.5, 0.05, 8.7), -1.31],  # up the open street, east
	["sprint", 1.6, 0.0, -1.0, 2, 0.0, false, false, null, 0.0],
	["towards_camera", 1.2, 0.0, 1.0, false, 0.0, false, false, null, 0.0],
	["woman_walk", 2.0, 0.0, -1.0, false, 0.0, true, false, Vector3(14.5, 0.05, 8.7), -1.31],
	["woman_run", 1.2, 0.0, -1.0, true, 0.0, true, false, null, 0.0],
	["woman_sprint", 1.4, 0.0, -1.0, 2, 0.0, true, false, null, 0.0],
	["woman_towards_camera", 1.5, 0.0, 1.0, false, 0.0, true, false, null, 0.0],
	["wall", 1.5, 0.0, 0.0, false, 0.0, true, false, "wall", PI],
	["first_person", 1.0, 0.0, 0.0, false, 0.0, true, true, null, 0.0],
	["woman_front", 1.2, 0.0, 0.0, false, "front", true, false, null, 0.0],
	["man_front", 1.2, 0.0, 0.0, false, "front", false, false, null, 0.0],
	["man_sits", 3.0, 0.0, 0.0, false, "front", false, false, "seat", 0.0],
	["winded_pad", 2.4, 0.0, -1.0, 2, 0.0, false, false, Vector3(14.5, 0.05, 8.7), -1.31],
]

var look: Node3D
var player: CharacterBody3D
var wall: Node3D
var i := -1
var t := 0.0


func _ready() -> void:
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = CANVAS
	get_viewport().scaling_3d_scale = 1.0
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
	player.scripted = true
	add_child(player)
	player.teleport(0)
	player.pitch = -0.12
	player.cam.current = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_next()


func _next() -> void:
	i += 1
	if i >= STEPS.size():
		print("tp: done in %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()
		return
	var s: Array = STEPS[i]
	t = 0.0
	if s[5] is String:  # face the body: the camera looks back along the way the body faces
		player.yaw = player.facing + PI
		if wall != null:
			wall.queue_free()
			wall = null
	else:
		player.yaw += s[5]
	if s[8] is String and s[8] == "seat":
		player.global_position = Vector3(16.0, 0.05, 11.0)
		player.velocity = Vector3.ZERO
		player.facing = PI  # facing south
		player.yaw = 0.0  # the camera in front, looking north at him
		player.reset_physics_interpolation()
		_bench_behind()
	elif s[8] is String:
		_wall_behind()
	elif s[8] != null:
		player.global_position = s[8]
		player.velocity = Vector3.ZERO
		player.yaw = s[9]
		player.reset_physics_interpolation()
	if player.woman != s[6]:
		player.woman = s[6]
		player._show_body()
	if player.view_first != s[7]:
		player.view_first = s[7]
		player._show_body()
	player.scripted_move = Vector3(s[2], float(s[4]), s[3])
	if s[0] == "winded_pad":  # the breath nearly spent: it runs out in the first moments of the sprint
		player.rest = 0  # up from the bench at once (Rest.NONE): the breath does not come back while standing up
		player.breath = 0.3
		Controls.pad = true
		var hud := Hud.new()
		hud.third_person = true
		hud.player = player
		add_child(hud)
	if s[0] == "man_sits":
		await get_tree().create_timer(0.3).timeout  # let the body land first
		player.sit()
		print("tp: sits on a %s, the seat %.2f m" % [player.rest_kind, player.seat_height])


## A stone bench, 0.45 m high, set a pace behind the player (the street has no ledge at seat height near the start:
## the chapel stairs rise 17 cm a pace), to sit on.
func _bench_behind() -> void:
	var fwd := Vector3(-sin(player.facing), 0.0, -cos(player.facing))
	var bench := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 0.45, 0.45)
	cs.shape = box
	bench.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#9a9186")
	mi.material_override = m
	bench.add_child(mi)
	add_child(bench)
	bench.global_transform = Transform3D(Basis(Vector3.UP, player.facing), player.global_position - fwd * 0.535 + Vector3(0, 0.225, 0))


## A grey wall, 6 m tall, set up 1 m behind the player across the camera's arm: the arm has to shorten to it.
func _wall_behind() -> void:
	var back := Basis(Vector3.UP, player.yaw) * Vector3(0, 0, 1.0)
	wall = StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8.0, 6.0, 0.4)
	cs.shape = box
	wall.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	wall.add_child(mi)
	add_child(wall)
	wall.global_transform = Transform3D(Basis(Vector3.UP, player.yaw), player.global_position + back * 1.2 + Vector3(0, 3.0, 0))


func _process(dt: float) -> void:
	if i < 0 or i >= STEPS.size():
		return
	t += dt
	var s: Array = STEPS[i]
	if t < s[1]:
		return
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT).path_join("tp_%d_%s.png" % [i + 1, s[0]]))
	var on_screen: Vector2 = player.cam.unproject_position(player.global_position + Vector3(0, 0.9, 0))
	print("tp: %s  at %.1f, %.1f, %.1f  speed %.2f  clip %s x%.2f  arm %.2f m  facing %.2f  body on screen %d, %d" % [s[0],
		player.global_position.x, player.global_position.y, player.global_position.z,
		Vector2(player.velocity.x, player.velocity.z).length(), player._clip,
		player.anim.speed_scale if player.anim != null else 0.0, player.arm_len, player.facing, on_screen.x, on_screen.y])
	_next()
