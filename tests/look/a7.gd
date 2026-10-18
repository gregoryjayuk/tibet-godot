extends Node3D
## Art step A7 (plan chapter 09, 10.1 and 16): the whole day. The draft street from the kit, with M1's look and the ink
## pass, lit by the day cycle (world/day.gd: the keyframes blended at the clock's minute, the sun and moon from the
## Calendar) at thirteen moments of the default day, 28 October 1903, from 04:30 to 01:00 the next morning, from the
## street (viewpoint 1) and from above (viewpoint 5). Shots to tests/look/out/; tools/look/a7_sheet.py lays them out.
## Run: tools/look/a7.sh. Debug switches after --: --only=HHMM (one moment), --no-aerial, --no-fog, --no-vfog, --no-air,
## --aim=moon or --aim=up (turn the camera to the moon, or up at the sky south of the zenith)
## (the ink pass's depth ramp, grain and vignette), to find what lifts or tints a frame.

const Vignette := preload("res://world/vignette.gd")
const Ink := preload("res://world/ink.gd")
const DayCycle := preload("res://world/day.gd")
const Horizon := preload("res://world/horizon.gd")
const OUT := "res://tests/look/out"
const CANVAS := Vector2i(1920, 1080)
const DAY := 7  ## 28 October is game day 7
## [hh, mm, day offset]: the keyframes' moments and the two ends of the sequence (K03, K04, K08 and K09 on the
## terrain's sun since 26 Sep 2026: 07:22, 07:39, 16:08, 16:35; they were 06:38, 07:02, 16:10, 16:40)
const TIMES := [[4, 30, 0], [5, 30, 0], [7, 22, 0], [7, 39, 0], [9, 0, 0], [11, 43, 0], [14, 0, 0], [16, 8, 0],
	[16, 35, 0], [17, 15, 0], [17, 42, 0], [20, 30, 0], [1, 0, 1]]
const VIEWS := [0, 4]

var tag := "a7"  ## the shots' prefix; tests/look/a8.gd reuses this test with its own moments
var times: Array = TIMES
var look: Node3D
var cam: Camera3D
var day: DayCycle
var jobs: Array = []
var current := {}
var last_hash := 0  ## the previous capture's, to catch a window that stopped being redrawn (ISS-012)


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
	day = DayCycle.new()
	for c in look.get_children():
		if c is DirectionalLight3D:
			day.sun = c
		elif c is WorldEnvironment:
			day.env = (c as WorldEnvironment).environment
	add_child(day)
	Horizon.load_globals(Horizon.STREET_PLACE)  # the ridge shadow, as the game has it (art step A8)
	cam = Camera3D.new()
	cam.fov = 68.0
	cam.far = 20000.0
	add_child(cam)
	cam.current = true
	var ink := Ink.attach(cam)
	var args := OS.get_cmdline_user_args()
	var only := ""
	for a in args:
		if a.begins_with("--only="):
			only = a.substr(7)
	if "--no-air" in args:
		ink.set_shader_parameter("air", 0.0)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_before_jobs()
	for v in VIEWS:
		for t in times:
			if only == "" or "%02d%02d" % [t[0], t[1]] == only:
				jobs.append([v, t])
	_next()


## For a test built on this one: set-up after the scene and before the shots.
func _before_jobs() -> void:
	pass


func _next() -> void:
	if jobs.is_empty():
		print("%s: done in %s" % [tag, ProjectSettings.globalize_path(OUT)])
		get_tree().quit()
		return
	var j: Array = jobs.pop_front()
	var t: Array = j[1]
	var minute: float = (DAY + t[2]) * 1440.0 + t[0] * 60 + t[1]
	WorldClock.freeze(20.0, minute)
	day.update(minute)
	var args := OS.get_cmdline_user_args()
	if "--no-aerial" in args:
		day.env.fog_aerial_perspective = 0.0
	if "--no-fog" in args:
		day.env.fog_enabled = false
	if "--no-vfog" in args:
		day.env.volumetric_fog_enabled = false
	var v: Array = Vignette.VIEWS[j[0]]
	var feet: Vector3 = Vignette.b2g(v[0])
	cam.global_position = feet + Vector3(0, 1.6, 0)
	cam.look_at(Vignette.b2g(v[1]), Vector3.UP)
	for a in args:
		if a == "--aim=moon":
			cam.look_at(cam.global_position + Calendar.moon_direction(minute) * 100.0, Vector3.UP)
		elif a == "--aim=up":
			cam.look_at(cam.global_position + Vector3(0.0, 1.0, 0.45) * 100.0, Vector3.UP)
	current = {"name": "%s_v%d_%02d%02d" % [tag, j[0] + 1, t[0], t[1]], "wait": 40}
	print("%s: %s  %s  sun %.1f deg, blend %s-%s %.2f, key energy %.2f" % [tag, current["name"], Calendar.clock(minute),
		day.last["sun_alt"], day.last["from"], day.last["to"], day.last["t"], day.sun.light_energy])


func _process(_dt: float) -> void:
	if current.is_empty():
		return
	current["wait"] -= 1
	if current["wait"] > 0:
		return
	var img := get_viewport().get_texture().get_image()
	var h := hash(img.get_data())
	if h == last_hash and current.get("retries", 0) < 10:
		current["retries"] = current.get("retries", 0) + 1
		current["wait"] = 30  # the same picture again: the window was not redrawn; wait for it
		return
	last_hash = h
	img.save_png(ProjectSettings.globalize_path(OUT).path_join(current["name"] + ".png"))
	current = {}
	_next()
