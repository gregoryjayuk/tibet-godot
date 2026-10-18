extends Node3D
## The shafts of sun through the halls' windows (plan chapter 04, 8.5; the game's M3 sprint 5, step 4): for each opening
## of data/sun_tables.json (tools/town/sun_table.py: the Tsokchen's ten lantern windows) a box swept from the window along
## the sun's ray as far as the table's reach (to the floor, a wall or the gallery's floor), drawn by
## shaders/sun_shaft.gdshader, as strong as the table's share of the window lit at the game's day and minute, in the
## sun's colour at the hour times 0.6, with its dust: some sixty motes drifting in it, seen only where it is (chapter 04,
## 8.5). Added by world/town.gd; drawn only with the camera within NEAR of the opening.

const Town := preload("res://world/town.gd")
const DATA := "res://data/sun_tables.json"
const SHADER := preload("res://shaders/sun_shaft.gdshader")
const NEAR := 90.0  ## metres from an opening within which its shaft is drawn
const EVERY := 0.25  ## seconds between updates
const DEEP := 0.3  ## metres the box runs past the reach, so the depth test ends it on the surface

var _rows: Array = []  ## [key, MeshInstance3D, ShaderMaterial, centre (Godot), along (Godot, unit), w, h, lit, reach]
var _step := 7  ## days between the table's rows
var _per := 15.0  ## minutes between its samples
var _t := 0.0


func _ready() -> void:
	add_to_group("shafts")  # (spike S7's fifth stack hides them: world/interior_stack.gd)
	var f := FileAccess.open(DATA, FileAccess.READ)
	if f == null:
		push_warning("shafts: no %s (tools/town/sun_table.py)" % DATA)
		return
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	_step = int(d.get("day_step", 7))
	_per = 1440.0 / float(d.get("samples", 96))
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var ops: Dictionary = d.get("openings", {})
	for key in ops:
		var o: Dictionary = ops[key]
		var at: Array = o["at"]
		var b := deg_to_rad(float(o["out"]))
		var out := Vector3(sin(b), 0.0, -cos(b))  # (the bearing in Godot's frame: east +x, north -z)
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		var mi := MeshInstance3D.new()
		mi.name = String(key).replace(":", "_")
		mi.mesh = box
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 4.0
		mi.visible = false
		add_child(mi)
		mi.add_child(_motes())  # (in the shaft's own sheared frame: the motes stay inside it)
		_rows.append([key, mi, mat, Town.to_godot(float(at[0]), float(at[1]), float(at[2])), out.cross(Vector3.UP).normalized(),
				float(o["w"]), float(o["h"]), o["lit"], o["reach"]])
	set_process(not _rows.is_empty())


## The shaft's dust: motes in its box (the unit box of its sheared frame), drifting slowly, small additive points.
func _motes() -> GPUParticles3D:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.45, 0.45, 0.48)
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.02
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.4
	pm.turbulence_noise_speed_random = 0.2
	var q := QuadMesh.new()
	q.size = Vector2(0.012, 0.012)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(1.0, 0.9, 0.7, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	var gp := GPUParticles3D.new()
	gp.name = "Dust"
	gp.amount = 60
	gp.lifetime = 8.0
	gp.preprocess = 8.0
	gp.local_coords = true
	gp.process_material = pm
	gp.draw_pass_1 = q
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gp.visibility_aabb = AABB(Vector3(-0.6, -0.6, -0.6), Vector3(1.2, 1.2, 1.2))
	return gp


## The table's value at a game minute: between its two days and its two samples; `reach` the mean of the lit ones.
func at_minute(row: Array, minute: float) -> Vector2:
	var lit: Array = row[7]
	var reach: Array = row[8]
	var day := maxf(minute, 0.0) / 1440.0 / float(_step)
	var i0 := clampi(int(floorf(day)), 0, lit.size() - 1)
	var i1 := mini(i0 + 1, lit.size() - 1)
	var fd := clampf(day - float(i0), 0.0, 1.0)
	var s := fposmod(minute, 1440.0) / _per
	var n: int = (lit[0] as Array).size()
	var j0 := int(floorf(s)) % n
	var j1 := (j0 + 1) % n
	var fs := s - floorf(s)
	var v := 0.0
	var r := 0.0
	var rw := 0.0
	for k in [[i0, j0, (1.0 - fd) * (1.0 - fs)], [i0, j1, (1.0 - fd) * fs], [i1, j0, fd * (1.0 - fs)], [i1, j1, fd * fs]]:
		var a := float((lit[k[0]] as Array)[k[1]])
		v += a * float(k[2])
		if a > 0.0:
			r += float((reach[k[0]] as Array)[k[1]]) * float(k[2])
			rw += float(k[2])
	return Vector2(v, r / rw if rw > 0.0 else 0.0)


func _process(dt: float) -> void:
	_t -= dt
	if _t > 0.0:
		return
	_t = EVERY
	var cam := get_viewport().get_camera_3d()
	var minute := WorldClock.minute
	var s := Calendar.sun_direction(minute)
	var dn := get_tree().get_first_node_in_group("day")
	var sun: DirectionalLight3D = dn.get("sun") if dn != null else null
	var col := (sun.light_color if sun != null else Color(1.0, 0.92, 0.78)) * 0.6
	for row in _rows:
		var mi: MeshInstance3D = row[1]
		var c: Vector3 = row[3]
		var near := cam != null and cam.global_position.distance_to(c) < NEAR
		var tv := at_minute(row, minute) if near and s.y > 0.0 else Vector2.ZERO
		mi.visible = tv.x > 0.01 and tv.y > 0.0
		if not mi.visible:
			continue
		var ln := tv.y + DEEP
		var inn := -s * ln  # (from the window into the hall)
		var t := Transform3D(Basis(row[4] * float(row[5]), Vector3.UP * float(row[6]), inn), c + inn * 0.5)
		mi.global_transform = t
		var mat: ShaderMaterial = row[2]
		mat.set_shader_parameter("to_local", Projection(t.affine_inverse()))
		mat.set_shader_parameter("strength", tv.x)
		mat.set_shader_parameter("sun_dir", s)
		mat.set_shader_parameter("color", Vector3(col.r, col.g, col.b))
