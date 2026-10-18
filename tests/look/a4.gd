extends Node3D
## Art step A4 (plan chapter 09, 4.4 and 16): painted gold. The gilded roofs of the draft street's kit buildings, up
## close and from the street, under keyframes K05 (09:00) and K08 (16:10, golden). Before is M1's look with the single
## highlight that read as orange plastic; after, the metal shows the sky and the ground it reflects, with a broad band
## and a hot core. Done when the roofs read as metal. Shots to tests/look/out/; tools/look/a4_sheet.py lays them out.
## Run: tools/look/a4.sh

const Vignette := preload("res://world/vignette.gd")
const Keyframes := preload("res://world/keyframes.gd")
const STATIC := preload("res://shaders/materials/stylized_static.tres")
const OUT := "res://tests/look/out"
const CANVAS := Vector2i(1920, 1080)
const KEYS := ["K05", "K08"]
## [building, camera offset from the top of its bounds (x east, y up, z south), look-at offset from the same point]
const VIEWS := [["red_chapel_kit", Vector3(7.0, -11.0, 24.0), Vector3(0.0, -1.5, 0.0)],
	["red_chapel_kit", Vector3(-9.0, 1.5, 9.0), Vector3(0.0, -1.0, 0.0)],
	["assembly_hall_kit", Vector3(4.0, 0.5, 16.0), Vector3(0.0, -1.5, 3.0)]]

var look: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var jobs: Array = []
var current := {}
var keys := {}
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
	for c in look.get_children():
		if c is DirectionalLight3D:
			sun = c
		elif c is WorldEnvironment:
			env = (c as WorldEnvironment).environment
	cam = Camera3D.new()
	cam.fov = 60.0
	cam.far = 20000.0
	add_child(cam)
	cam.current = true
	keys = Keyframes.load_all()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for k in KEYS:
		for v in VIEWS.size():
			for m in [0.0, 1.0]:
				jobs.append([k, v, m])
	_next()


## The top centre of a kit building's full-detail mesh, in world space.
func _top(building: String) -> Vector3:
	var b := look.find_child(building, true, false) as Node3D
	for n in b.find_children("*_L0", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var box := mi.global_transform * mi.get_aabb()
		return Vector3(box.get_center().x, box.end.y, box.get_center().z)
	return b.global_position


func _next() -> void:
	if jobs.is_empty():
		STATIC.set_shader_parameter("metals", 1.0)
		print("a4: done in %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()
		return
	var j: Array = jobs.pop_front()
	Keyframes.apply(j[0], sun, env, keys)
	STATIC.set_shader_parameter("metals", j[2])
	var v: Array = VIEWS[j[1]]
	var top := _top(v[0])
	cam.global_position = top + v[1]
	cam.look_at(top + v[2], Vector3.UP)
	current = {"name": "a4_%s_v%d_%s" % [j[0], j[1] + 1, "after" if j[2] > 0.5 else "before"], "wait": 30}


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
	if h == last_hash:
		push_warning("a4: %s is the previous picture: the window was not redrawn (ISS-012)" % current["name"])
	last_hash = h
	img.save_png(ProjectSettings.globalize_path(OUT).path_join(current["name"] + ".png"))
	current = {}
	_next()
