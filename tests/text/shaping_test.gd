extends Node3D
## Spike S4, the Tibetan shaping test (plan chapter 11, 17.4). Each row of tests/text/strings.json is rendered by
## Godot five ways: a UI Label at three sizes; a Label3D with an MSDF font at 1 m and at 20 m; and the Pillow-baked
## texture (tools/text/bake_text.py) on a wall at 1 m and at 20 m. The 1 m and 20 m views show the text at the same
## angular size (about 46 px per em), so what differs is only how each route copes with distance. One screenshot per
## row and route goes to tests/text/out/godot/; tools/text/contact_sheet.py lays them side by side for Greg.
## Run: tools/text/run_s4.sh

const OUT := "res://tests/text/out/godot"
const CANVAS := Vector2i(1600, 900)
const ROUTES := ["ui", "msdf_1m", "msdf_20m", "baked_1m", "baked_20m"]
const EM_MAX := 0.16  ## the largest em, in metres per metre of distance (about 107 px at 1600 x 900, fov 68°)
const FRAME_W := 2.398  ## the frame's width in metres at 1 m (16:9, vertical fov 68°)
const WALL := Color("#e6ded0")  ## the palette's whitewash
const INK := Color("#1e1612")
const FONT_FILES := {
	"tibetan": "res://assets/source/fonts/jomolhari/Jomolhari-Regular.ttf",
	"chinese": "res://assets/source/fonts/ar-pl-ukai/ukai.ttc",  ## Kai: Noto Serif TC read "computer generated", and of three brush faces Greg picked UKai (25 Sep)
}
const FACES := {"chinese": 2}  ## ukai.ttc holds four faces, CN, HK, TW and TW MBE; the TW one

var rows: Array = []
var fonts := {}
var holder: Node3D
var layer: CanvasLayer
var queue: Array = []
var wait := -1


func _ready() -> void:
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = CANVAS
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	WorldClock.freeze(0.0)
	rows = JSON.parse_string(FileAccess.get_file_as_string("res://tests/text/strings.json"))["rows"]
	for script in FONT_FILES:
		fonts[script] = _font(FONT_FILES[script], FACES.get(script, 0), false)
		fonts[script + "_msdf"] = _font(FONT_FILES[script], FACES.get(script, 0), true)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#aebccd")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.8
	sun.rotation_degrees = Vector3(-35, -25, 0)
	add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 68.0
	cam.far = 200.0
	add_child(cam)
	cam.current = true
	holder = Node3D.new()
	add_child(holder)
	layer = CanvasLayer.new()
	add_child(layer)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for i in rows.size():
		for route in ROUTES:
			queue.append([i, route])
	_next()


func _font(path: String, face: int, msdf: bool) -> FontFile:
	var f := FontFile.new()
	f.load_dynamic_font(path)
	f.set_face_index(0, face)
	if msdf:
		f.multichannel_signed_distance_field = true
		f.msdf_pixel_range = 16
		f.msdf_size = 64
	return f


func _clear() -> void:
	for c in holder.get_children():
		c.queue_free()
	for c in layer.get_children():
		c.queue_free()


func _next() -> void:
	_clear()
	if queue.is_empty():
		print("s4: done, %d images in %s" % [rows.size() * ROUTES.size(), ProjectSettings.globalize_path(OUT)])
		get_tree().quit()
		return
	var job: Array = queue[0]
	var row: Dictionary = rows[job[0]]
	match job[1]:
		"ui":
			_ui(row)
		"msdf_1m":
			_label3d(row, 1.0)
		"msdf_20m":
			_label3d(row, 20.0)
		"baked_1m":
			_baked(row, 1.0)
		"baked_20m":
			_baked(row, 20.0)
	wait = 20  # frames for MSDF glyph generation, pipeline compiles and shaping caches


func _ui(row: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.color = WALL
	bg.size = Vector2(CANVAS)
	layer.add_child(bg)
	var y := 40.0
	for size0 in [40, 72, 120]:
		var font: Font = fonts[row["script"]]
		var size: int = size0
		if not row.has("wrap_em"):
			var w := font.get_string_size(row["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			if w > CANVAS.x - 80:
				size = int(size * (CANVAS.x - 80) / w)  # long strings shrink to fit the frame
		var l := Label.new()
		l.text = row["text"]
		l.add_theme_font_override("font", font)
		l.add_theme_font_size_override("font_size", size)
		l.add_theme_color_override("font_color", INK)
		l.position = Vector2(40, y)
		if row.has("wrap_em"):
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(minf(float(row["wrap_em"]) * size, CANVAS.x - 80), 0)
			l.size = Vector2(l.custom_minimum_size.x, 0)
		layer.add_child(l)
		y += size * (1.9 if not row.has("wrap_em") else 6.5)
		if row.has("wrap_em"):
			break  # one size is enough to judge the line breaks in a 30-em box


func _wall(dist: float) -> void:
	var q := MeshInstance3D.new()
	var m := QuadMesh.new()
	m.size = Vector2(3.2, 1.8) * dist
	q.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WALL
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q.material_override = mat
	q.position = Vector3(0, 0, -dist - 0.02 * dist)
	holder.add_child(q)


func _label3d(row: Dictionary, dist: float) -> void:
	_wall(dist)
	var l := Label3D.new()
	l.text = row["text"]
	l.font = fonts[row["script"] + "_msdf"]
	l.font_size = 64
	var w_px: float = float(row["wrap_em"]) * 64.0 if row.has("wrap_em") else l.font.get_string_size(row["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
	l.pixel_size = minf(0.8 * FRAME_W * dist / maxf(w_px, 1.0), EM_MAX * dist / 64.0)  # about 80% of the frame's width
	l.modulate = INK
	l.outline_size = 0
	l.double_sided = false
	l.shaded = false
	if row.has("wrap_em"):
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.width = float(row["wrap_em"]) * 64.0
	l.position = Vector3(0, 0, -dist)
	holder.add_child(l)


func _baked(row: Dictionary, dist: float) -> void:
	_wall(dist)
	var parts := [["res://tests/text/out/baked/%s_96.png" % row["id"], 0.0]]
	if row.has("vertical_bake"):
		parts[0][1] = -0.35 * dist
		parts.append(["res://tests/text/out/baked/%s_vertical.png" % row["id"], 0.9 * dist])
	for p in parts:
		var img := Image.load_from_file(ProjectSettings.globalize_path(p[0]))
		var tex := ImageTexture.create_from_image(img)
		var q := MeshInstance3D.new()
		var m := QuadMesh.new()
		var total_w := 0.0
		for part in parts:
			total_w += Image.load_from_file(ProjectSettings.globalize_path(part[0])).get_width()
		var metres_per_px := minf(0.8 * FRAME_W * dist / maxf(total_w, 1.0), EM_MAX * dist / 96.0)  # baked at 96 px per em
		m.size = Vector2(img.get_width(), img.get_height()) * metres_per_px
		q.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		q.material_override = mat
		q.position = Vector3(p[1], 0, -dist)
		holder.add_child(q)


func _process(_dt: float) -> void:
	if wait < 0:
		return
	wait -= 1
	if wait > 0:
		return
	var job: Array = queue.pop_front()
	var row: Dictionary = rows[job[0]]
	var path := ProjectSettings.globalize_path(OUT).path_join("%s_%s.png" % [row["id"], job[1]])
	get_viewport().get_texture().get_image().save_png(path)
	wait = -1
	_next()
