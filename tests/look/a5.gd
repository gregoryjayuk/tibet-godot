extends Node3D
## Art step A5 (plan chapter 09, 8.2, 9.4, 11.3 and 16): the ink pass, on the draft street rebuilt from the kit (the
## vignette's --kit mode) at its five viewpoints under keyframe K05 (09:00). Before is the draft's outline (dark lines
## fading out by 140 m); after is ink_air: lines coloured from their surface, silhouettes, creases and material lines,
## a hairline to 400 m fading into the fog, no lines on grass or flags, distance painted in bands of hue, paper grain
## and a vignette. Done when the lines hold to 400 m, the distance bands read and grass and flags carry no lines.
## Shots to tests/look/out/; tools/look/a5_sheet.py lays them out. Run: tools/look/a5.sh

const Vignette := preload("res://world/vignette.gd")
const Keyframes := preload("res://world/keyframes.gd")
const Ink := preload("res://world/ink.gd")
const OUT := "res://tests/look/out"
const CANVAS := Vector2i(1920, 1080)
const KEYS := ["K05"]
const VIEWS := [0, 1, 2, 3, 4]

var look: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var outline_q: MeshInstance3D
var ink_q: MeshInstance3D
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
	cam.fov = 68.0
	cam.far = 20000.0
	add_child(cam)
	cam.current = true
	Ink.attach(cam)
	ink_q = cam.get_node("Ink")
	outline_q = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2, 2)
	outline_q.mesh = qm
	outline_q.extra_cull_margin = 16384.0
	var om := ShaderMaterial.new()
	om.shader = preload("res://shaders/outline.gdshader")
	om.set_shader_parameter("enabled", 1.0)
	outline_q.material_override = om
	cam.add_child(outline_q)
	keys = Keyframes.load_all()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for k in KEYS:
		for v in VIEWS:
			for ink in [false, true]:
				jobs.append([k, v, ink])
	_next()


func _next() -> void:
	if jobs.is_empty():
		print("a5: done in %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()
		return
	var j: Array = jobs.pop_front()
	Keyframes.apply(j[0], sun, env, keys)
	ink_q.visible = j[2]
	outline_q.visible = not j[2]
	var v: Array = Vignette.VIEWS[j[1]]
	var feet: Vector3 = Vignette.b2g(v[0])
	cam.global_position = feet + Vector3(0, 1.6, 0)
	cam.look_at(Vignette.b2g(v[1]), Vector3.UP)
	current = {"name": "a5_%s_v%d_%s" % [j[0], j[1] + 1, "after" if j[2] else "before"], "wait": 30}


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
