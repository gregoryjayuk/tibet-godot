extends Node3D
## Art step A2 (plan chapter 09, 16): ramps, shadow bias, hue-dependent shadows and the hemisphere fill, on the draft's
## street rebuilt from the kit (the vignette's --kit mode), at the draft's viewpoints 1-3, under keyframes K05 (09:00)
## and K08 (16:10, golden). Before is M0's light, after is M1's, under the same sun and sky. Done when red walls
## shade crimson, reveals stay dark at every sun, and gallery undersides glow warm. Shots to tests/look/out/;
## tools/look/a2_sheet.py lays them out. Run: tools/look/a2.sh

const Vignette := preload("res://world/vignette.gd")
const Keyframes := preload("res://world/keyframes.gd")
const STATIC := preload("res://shaders/materials/stylized_static.tres")
const OUT := "res://tests/look/out"
const CANVAS := Vector2i(1920, 1080)
const KEYS := ["K05", "K08"]
const VIEWS := [0, 1, 2]

var look: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var jobs: Array = []
var current := {}
var keys := {}


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
	for c in look.get_children():
		if c is DirectionalLight3D:
			sun = c
		elif c is WorldEnvironment:
			env = (c as WorldEnvironment).environment
	cam = Camera3D.new()
	cam.fov = 68.0
	cam.far = 20000.0
	add_child(cam)
	cam.current = true
	keys = Keyframes.load_all()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for k in KEYS:
		for v in VIEWS:
			for w in [0.0, 1.0]:
				jobs.append([k, v, w])
	_next()


func _next() -> void:
	if jobs.is_empty():
		print("a2: done in %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()
		return
	var j: Array = jobs.pop_front()
	Keyframes.apply(j[0], sun, env, keys)
	STATIC.set_shader_parameter("weathering", j[2])
	var v: Array = Vignette.VIEWS[j[1]]
	var feet: Vector3 = Vignette.b2g(v[0])
	cam.global_position = feet + Vector3(0, 1.6, 0)
	cam.look_at(Vignette.b2g(v[1]), Vector3.UP)
	current = {"name": "a2_%s_v%d_%s" % [j[0], j[1] + 1, "after" if j[2] > 0.5 else "before"], "wait": 30}


func _process(_dt: float) -> void:
	if current.is_empty():
		return
	current["wait"] -= 1
	if current["wait"] > 0:
		return
	var path := ProjectSettings.globalize_path(OUT).path_join(current["name"] + ".png")
	get_viewport().get_texture().get_image().save_png(path)
	current = {}
	_next()
