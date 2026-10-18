extends Node3D
## The kit gallery (RT-09): the eight building types exported by ../tibet-blender/export_types.py, in a row under the
## vignette's sky and light, with the palette shader, as Greg's first look at the new pipeline. Stills of the row and
## of each building go to tests/kit/out/. Run: tools/kit/gallery.sh (SET=k5: kit step K5's houses and stalls, each
## variant's first seed and the B house's three, to tests/kit/out/k5/; SET=k8: kit step K8's log-storey houses, A1 to A4, to
## tests/kit/out/k8/)

const Vignette := preload("res://world/vignette.gd")
const TYPES := ["village_house", "red_chapel", "monks_quarters", "palace_tower", "assembly_hall", "chorten", "prayer_wheel_gallery", "sangkhang"]
const K5 := ["town_house_b1_v1", "town_house_b1_v2", "town_house_b1_v3", "town_house_b2_v1", "town_house_b3_v1", "town_house_b4_v1",
		"poor_house_e1_v1", "poor_house_e2_v1", "stall_sh03_v1", "stall_sh04_v1"]
const K8 := ["log_house_a1_v1", "log_house_a2_v1", "log_house_a3_v1", "log_house_a4_v1", "log_house_a4_v2"]
var files: Array = []  ## the files in the row: TYPES' first variants, or K5, or K8
const CANVAS := Vector2i(1600, 900)
var OUT := "res://tests/kit/out"
var force_lod := -1  ## --lod=1 or 2: show only that level, at every distance, to inspect it up close

var cam: Camera3D
var shots: Array = []  # [name, position, look_at]
var wait := -1


func _ready() -> void:
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = CANVAS
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	WorldClock.freeze(20.0)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lod="):
			force_lod = int(a.substr(6))
			OUT = "res://tests/kit/out/lod%d" % force_lod
		if a == "--set=k5":
			files = K5.duplicate()
			OUT = "res://tests/kit/out/k5"
		if a == "--set=k8":
			files = K8.duplicate()
			OUT = "res://tests/kit/out/k8"
	if files.is_empty():
		for t in TYPES:
			files.append(t + "_v1")
	var look := Vignette.new()
	look.look_only = true
	add_child(look)
	await look.build()
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 200)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#a39581")
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.far = 2000.0
	add_child(cam)
	cam.current = true
	var q := MeshInstance3D.new()  # the ink lines: the same screen-space quad the player's camera carries
	var qm := QuadMesh.new()
	qm.size = Vector2(2, 2)
	q.mesh = qm
	q.extra_cull_margin = 16384.0
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var om := ShaderMaterial.new()
	om.shader = preload("res://shaders/outline.gdshader")
	om.set_shader_parameter("enabled", 1.0)
	q.material_override = om
	cam.add_child(q)
	var x := 0.0
	var centres := []
	for t in files:
		var path := "res://assets/generated/kit/types/%s.glb" % t
		if not ResourceLoader.exists(path):
			push_warning("gallery: missing " + path)
			continue
		var b: Node3D = load(path).instantiate()
		add_child(b)
		if force_lod >= 0:
			for mi in b.find_children("*", "MeshInstance3D", true, false):
				for k in 3:
					if String(mi.name).ends_with("_L%d" % k):
						mi.visible = k == force_lod
						mi.visibility_range_begin = 0.0
						mi.visibility_range_end = 0.0
		var aabb := _aabb(b)
		x += aabb.size.x / 2.0 + 6.0
		b.position = Vector3(x - aabb.get_center().x, 0.0, -aabb.get_center().z)
		centres.append([t, Vector3(x, aabb.size.y / 2.0, 0.0), aabb.size])
		x += aabb.size.x / 2.0 + 6.0
	var mid := x / 2.0
	var back := maxf(95.0, x * 0.72)  # far enough for the whole row in a 50° (vertical) view at 16:9
	shots.append(["row", Vector3(mid, back * 0.33, back), Vector3(mid, 6.0, 0.0)])
	for c in centres:
		var s: Vector3 = c[2]
		var d := maxf(maxf(s.x, s.y) * 1.25, 9.0)
		shots.append([c[0], c[1] + Vector3(d * 0.35, d * 0.25, d), c[1]])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_next()


func _aabb(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*_L0", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _next() -> void:
	if shots.is_empty():
		print("gallery: done")
		get_tree().quit()
		return
	var s: Array = shots[0]
	cam.global_position = s[1]
	cam.look_at(s[2], Vector3.UP)
	wait = 45


func _process(_dt: float) -> void:
	if wait < 0:
		return
	wait -= 1
	if wait > 0:
		return
	var s: Array = shots.pop_front()
	var path := ProjectSettings.globalize_path(OUT).path_join("%s.png" % s[0])
	get_viewport().get_texture().get_image().save_png(path)
	print("gallery: ", path)
	wait = -1
	_next()
