extends Node3D
## Art step A1 (plan chapter 09, 16; roadmap 4.2): one wall. The kit's Type B town house (village_house) at noon on
## the default day, 28 October (the sun 47° up, due south), seen at 2, 20 and 50 m from its south front, with the
## weathering stack of chapter 09 (4.6) off (M0's look) and on. Done when pours, plinth, soot and edge wear read at
## 50 m and nothing looks tiled at 2 m. Shots to tests/look/out/; tools/look/a1_sheet.py pairs them for Greg.
## Run: tools/look/a1.sh

const Vignette := preload("res://world/vignette.gd")
const STATIC := preload("res://shaders/materials/stylized_static.tres")
const HOUSE := "res://assets/generated/kit/types/village_house_v1.glb"
const OUT := "res://tests/look/out"
const CANVAS := Vector2i(1920, 1080)
const DISTANCES := [2.0, 20.0, 50.0]

var cam: Camera3D
var jobs: Array = []
var current := {}
var front := Vector3.ZERO
var height := 8.0


func _ready() -> void:
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = CANVAS
	get_viewport().scaling_3d_scale = 1.0
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	WorldClock.freeze(20.0)
	var look := Vignette.new()
	look.look_only = true
	add_child(look)
	await look.build()
	for c in look.get_children():
		if c is DirectionalLight3D:
			# Noon on 28 October at 30° N: 90 - 30 - 13 (the sun's declination) = 47° up, due south (+Z is south).
			var el := deg_to_rad(47.0)
			var to_sun := Vector3(0.0, sin(el), cos(el))
			(c as DirectionalLight3D).look_at_from_position(to_sun * 100.0, Vector3.ZERO, Vector3.UP)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#9e8667")
	gm.roughness = 1.0
	ground.mesh.material = gm
	add_child(ground)
	var house: Node3D = (load(HOUSE) as PackedScene).instantiate()
	add_child(house)
	var box := AABB()
	for mi in house.find_children("*_L0", "MeshInstance3D", true, false):
		box = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).mesh.get_aabb()
	front = Vector3(box.get_center().x, 0.0, box.end.z)
	height = box.size.y
	cam = Camera3D.new()
	cam.fov = 68.0
	cam.far = 5000.0
	add_child(cam)
	cam.current = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for d in DISTANCES:
		for w in [0.0, 1.0]:
			jobs.append([d, w])
	_next()


func _next() -> void:
	if jobs.is_empty():
		print("a1: done in %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()
		return
	var j: Array = jobs.pop_front()
	var d: float = j[0]
	STATIC.set_shader_parameter("weathering", j[1])
	# Eye height at 2 m, looking at the lower wall; further off, the whole front, a little to one side.
	var eye := Vector3(front.x + d * 0.25, 1.6, front.z + d)
	var target := Vector3(front.x, 1.2 if d < 5.0 else height * 0.45, front.z)
	cam.global_position = eye
	cam.look_at(target, Vector3.UP)
	current = {"name": "a1_%02dm_%s" % [int(d), "after" if j[1] > 0.5 else "before"], "wait": 20}


func _process(_dt: float) -> void:
	if current.is_empty():
		return
	current["wait"] -= 1
	if current["wait"] > 0:
		return
	var path := ProjectSettings.globalize_path(OUT).path_join(current["name"] + ".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("a1: shot %s" % path)
	current = {}
	_next()
