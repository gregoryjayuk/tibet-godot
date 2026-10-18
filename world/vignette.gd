extends Node3D
## The draft vignette: an alley and the red chapel, from the Blender kit's export (assets/vignette.glb), assembled at
## start-up with the stylized look (shaders, sky, light, fog) and its life (smoke, dust, grass, walking monks).
## Split out of main.gd at M0 RT-03; the draft's habits that do not scale are listed in docs/ISSUES.md (ISS-002 to 006).
## Random draws happen only in populate(), grass first and monks second, so a fixed seed repeats every shot exactly.

const SUN_ELEV := 40.0
const SUN_AZIM := 215.0

## Viewpoints in Blender coordinates: [feet position, point looked at].
const VIEWS := [
	[Vector3(18.9, -13.0, 0.2), Vector3(19.3, 24.0, 7.2)],
	[Vector3(18.8, 5.0, 3.1), Vector3(19.4, 30.0, 9.0)],
	[Vector3(30.0, 1.6, 3.2), Vector3(26.0, 14.0, 8.0)],
	[Vector3(8.0, -14.0, 0.1), Vector3(0.0, 9.0, 8.0)],
	[Vector3(42.0, -30.0, 22.0), Vector3(22.0, 14.0, 6.0)],
]

const SHADER_STYLE := preload("res://shaders/stylized.gdshader")
const SHADER_FLAG := preload("res://shaders/flag.gdshader")
const SHADER_FOLIAGE := preload("res://shaders/foliage.gdshader")
const SHADER_GRASS := preload("res://shaders/grass.gdshader")
const SHADER_SKY := preload("res://shaders/sky.gdshader")
const MATERIAL_KEYS := ["paint", "streaks", "fibers", "gloss", "rim", "pattern"]
const PaletteTex := preload("res://tools/build/palette_tex.gd")
const Ramps := preload("res://tools/build/ramps.gd")  ## chapter 09's ramp atlas (art step A2)
## --kit: the vignette's buildings replaced by their kit exports (RT-09): node name in vignette.glb -> [kit type, scale]
const KIT_BUILDINGS := {"assembly_hall": ["assembly_hall", 1.0], "red_chapel": ["red_chapel", 1.0],
		"monks_quarters": ["monks_quarters", 1.0], "sangkhang": ["sangkhang", 1.0], "chorten_small": ["chorten", 0.62]}

var palette := {}  ## materials, flags and foliage from data/palette.json
var noise_tex: NoiseTexture2D
var cache := {}
var monks: Array = []
var use_kit := false  ## set before build(): swap the buildings for the kit exports
var look_only := false  ## set before build(): sky, light and fog only, no geometry (the kit gallery)


static func b2g(v: Vector3) -> Vector3:
	# Blender (x, y, z) with z up  ->  Godot (x, y, z) with y up
	return Vector3(v.x, v.z, -v.y)


## The look and the solid world: noise, sky and light, the geometry with its materials and collisions, smoke and dust.
func build() -> void:
	palette = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette.json"))
	noise_tex = NoiseTexture2D.new()
	noise_tex.width = 512
	noise_tex.height = 512
	noise_tex.seamless = true
	noise_tex.generate_mipmaps = true
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.012
	fn.fractal_octaves = 5
	noise_tex.noise = fn
	await noise_tex.changed
	_environment()
	if look_only:
		PaletteTex.install()
		Ramps.install()
		return
	var geometry: Node3D = load("res://assets/vignette.glb").instantiate()
	add_child(geometry)
	if use_kit:
		_swap_in_kit(geometry)
	stylize(geometry, true)
	_smoke(b2g(Vector3(33.5, 3.4, 6.3)))
	_dust()


## Grass and monks. Call after two physics frames, because the grass is placed by ray casts against the collisions.
func populate() -> void:
	_grass()
	_monks()


# ------------------------------------------------------------------ look
func _environment() -> void:
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = SHADER_SKY
	sky_mat.set_shader_parameter("noise_tex", noise_tex)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 0.92
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.02
	env.glow_hdr_threshold = 1.5
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.2
	env.ssil_enabled = true
	env.ssil_intensity = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.6, 0.72, 0.9)
	env.fog_density = 0.00028
	env.fog_aerial_perspective = 0.65
	env.fog_sky_affect = 0.25
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.003
	env.volumetric_fog_albedo = Color(0.92, 0.94, 1.0)
	env.volumetric_fog_length = 90.0
	env.volumetric_fog_anisotropy = 0.6
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.05
	env.adjustment_contrast = 1.06
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 2.1
	sun.shadow_enabled = true
	sun.shadow_blur = 1.4
	sun.directional_shadow_max_distance = 160.0
	sun.light_volumetric_fog_energy = 1.2
	add_child(sun)
	var el := deg_to_rad(SUN_ELEV)
	var az := deg_to_rad(SUN_AZIM)
	var d := b2g(Vector3(sin(az) * cos(el), cos(az) * cos(el), sin(el)))
	sun.look_at_from_position(d * 100.0, Vector3.ZERO, Vector3.UP)
	Quality.register_look(env, sun)  # the tiers switch fog, SSAO and shadows on these (RT-14)


func _mat(name: String) -> Material:
	if cache.has(name):
		return cache[name]
	var m := ShaderMaterial.new()
	if palette["flags"].has(name):
		m.shader = SHADER_FLAG
		m.set_shader_parameter("base_color", Color(palette["flags"][name]))
	elif palette["foliage"].has(name):
		m.shader = SHADER_FOLIAGE
		m.set_shader_parameter("base_color", Color(palette["foliage"][name]))
		m.set_shader_parameter("noise_tex", noise_tex)
	else:
		var p: Dictionary = palette["materials"].get(name, {})
		m.shader = SHADER_STYLE
		m.set_shader_parameter("base_color", Color(p["c"]) if p.has("c") else Color(0.82, 0.8, 0.76))
		m.set_shader_parameter("noise_tex", noise_tex)
		for k in MATERIAL_KEYS:
			if p.has(k):
				# JSON numbers arrive as floats; the pattern uniform is an int.
				m.set_shader_parameter(k, int(p[k]) if k == "pattern" else float(p[k]))
	if use_kit:
		m.set_shader_parameter("ink_codes", 1.0)  # M1's look: line groups for the ink pass (art step A5)
	cache[name] = m
	return m


func _swap_in_kit(geometry: Node3D) -> void:
	PaletteTex.install()
	Ramps.install()
	for name in KIT_BUILDINGS:
		var old := geometry.find_child(name, true, false) as Node3D
		var path := "res://assets/generated/kit/types/%s_v1.glb" % KIT_BUILDINGS[name][0]
		if old == null or not ResourceLoader.exists(path):
			push_warning("kit: cannot swap %s (%s)" % [name, path])
			continue
		var kit: Node3D = load(path).instantiate()
		kit.name = name + "_kit"
		kit.transform = old.transform.scaled_local(Vector3.ONE * KIT_BUILDINGS[name][1])
		old.get_parent().add_child(kit)
		old.get_parent().remove_child(old)
		old.queue_free()


## Swap every imported material for its stylized one, by the material's name; add trimesh collisions if asked
## (not for flags, trees or the mountains). Kit meshes (_L0/_L1/_L2) already carry the palette shader and their own
## convex hulls, so they are left alone.
func stylize(root: Node, collide: bool) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if String(mi.name).ends_with("_L0") or String(mi.name).ends_with("_L1") or String(mi.name).ends_with("_L2"):
			continue
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			mi.set_surface_override_material(i, _mat(src.resource_name if src else ""))
		var lname := String(mi.name).to_lower()
		if lname.contains("mountain"):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if collide and not (lname.contains("flag") or lname.contains("tree") or lname.contains("mountain")):
			mi.create_trimesh_collision()


# ------------------------------------------------------------------ life
func _soft_disc() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


func _smoke(pos: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.amount = 40
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.use_fixed_seed = true
	p.seed = 11
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 10.0
	pm.initial_velocity_min = 0.35
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3(0.14, 0.06, 0.05)
	pm.scale_min = 0.5
	pm.scale_max = 0.8
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.35))
	sc.add_point(Vector2(1.0, 1.0))
	var ct := CurveTexture.new()
	ct.curve = sc
	pm.scale_curve = ct
	var g := Gradient.new()
	g.set_color(0, Color(0.96, 0.96, 0.96, 0.5))
	g.set_color(1, Color(0.9, 0.92, 0.95, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(2.4, 2.4)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# M1's look lights its smoke and dust like everything else, so the day cycle dims them at night (art step A7); the
	# draft keeps them unshaded, as its reference shots have them.
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if use_kit else BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_disc()
	q.material = m
	p.draw_pass_1 = q
	add_child(p)
	p.global_position = pos


func _dust() -> void:
	var p := GPUParticles3D.new()
	p.amount = 160
	p.lifetime = 12.0
	p.preprocess = 12.0
	p.use_fixed_seed = true
	p.seed = 12
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(3.0, 4.0, 16.0)
	pm.direction = Vector3(0.3, 0.2, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.08
	pm.gravity = Vector3(0.0, 0.004, 0.0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.3
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.8, 0.0))
	g.add_point(0.3, Color(1.0, 0.95, 0.8, 0.7))
	g.set_color(g.get_point_count() - 1, Color(1.0, 0.95, 0.8, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.035)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	# M1's look lights its smoke and dust like everything else, so the day cycle dims them at night (art step A7); the
	# draft keeps them unshaded, as its reference shots have them.
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if use_kit else BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_disc()
	q.material = m
	p.draw_pass_1 = q
	add_child(p)
	p.global_position = b2g(Vector3(19.0, 8.0, 5.5))


func _blade_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 5:
		var a := k * TAU / 5.0 + randf() * 0.4
		var right := Vector3(cos(a), 0.0, sin(a))
		var lean := Vector3(-sin(a), 0.0, cos(a)) * randf_range(0.05, 0.15)
		var w := 0.035
		var h := randf_range(0.28, 0.5)
		var pts := [[-w, 0.0], [w, 0.0], [-w * 0.6, 0.5], [w * 0.6, 0.5], [0.0, 1.0]]
		var vs := []
		for pt in pts:
			vs.append(right * pt[0] + Vector3(0.0, h * pt[1], 0.0) + lean * pt[1] * pt[1])
		for tri in [[0, 1, 2], [1, 3, 2], [2, 3, 4]]:
			for idx in tri:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(0.5, pts[idx][1]))
				st.add_vertex(vs[idx])
	return st.commit()


func _ground_hit(p: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 40, 0), p - Vector3(0, 40, 0))
	return get_world_3d().direct_space_state.intersect_ray(q)


func _grass() -> void:
	# 14,000 ray casts at every start (ISS-003): replaced by build-time scatter in the full game.
	var xforms := []
	for i in 14000:
		var bx := randf_range(-60.0, 95.0)
		var by := randf_range(-45.0, 110.0)
		var hit := _ground_hit(b2g(Vector3(bx, by, 0.0)))
		if hit.is_empty():
			continue
		var owner_name := String(hit.collider.get_parent().name).to_lower()
		if not owner_name.contains("terrain") or hit.normal.y < 0.8:
			continue
		var t := Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3.ONE * randf_range(0.7, 1.4)), hit.position)
		xforms.append(t)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _blade_mesh()
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var gm := ShaderMaterial.new()
	gm.shader = SHADER_GRASS
	gm.set_shader_parameter("ink_codes", 1.0 if use_kit else 0.0)
	mmi.material_override = gm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _monks() -> void:
	var scene: PackedScene = load("res://assets/monk.glb")
	var ring := []
	for k in 12:
		var a := k * TAU / 12.0
		ring.append(Vector3(33.5 + 2.6 * cos(a), 3.4 + 2.6 * sin(a), 3.0))
	var paths := [
		[Vector3(19.6, -9, 0), Vector3(19.6, -5.8, 0), Vector3(19.6, 0.9, 3), Vector3(19.2, 20.5, 3), Vector3(19.2, 27.9, 7),
			Vector3(20.5, 31, 7)],
		[Vector3(18.6, 3, 3), Vector3(18.7, 19, 3)],
		[Vector3(2, -14, 0), Vector3(15, -14, 0), Vector3(15, -4, 0), Vector3(4, -6, 0)],
		ring,
		[Vector3(0.5, -3, 0), Vector3(0.5, 5.9, 1.5), Vector3(-3, 6.4, 1.5)],
		[Vector3(26, -2, 0), Vector3(12, -10, 0), Vector3(20, -16, 0)],
		[Vector3(19.4, 16, 3), Vector3(19.5, 1, 3), Vector3(19.5, -6, 0), Vector3(22, -12, 0)],
	]
	for i in paths.size():
		var m: Node3D = scene.instantiate()
		stylize(m, false)
		add_child(m)
		var pts := []
		for v in paths[i]:
			pts.append(b2g(v))
		m.global_position = pts[0]
		m.reset_physics_interpolation()
		monks.append({"node": m, "path": pts, "i": 1, "dir": 1, "speed": randf_range(0.8, 1.15),
				"phase": randf() * 6.0, "loop": i == 2 or i == 3})


func _physics_process(dt: float) -> void:
	# Each monk casts a ray every physics frame to follow the ground (ISS-004): TownSim replaces this in M0 RT-13.
	for mk in monks:
		var n: Node3D = mk["node"]
		var path: Array = mk["path"]
		var target: Vector3 = path[mk["i"]]
		var to := target - n.global_position
		to.y = 0.0
		if to.length() < 0.3:
			if mk["loop"]:
				mk["i"] = (mk["i"] + 1) % path.size()
			else:
				if mk["i"] + mk["dir"] >= path.size() or mk["i"] + mk["dir"] < 0:
					mk["dir"] = -mk["dir"]
				mk["i"] += mk["dir"]
			continue
		var p: Vector3 = n.global_position + to.normalized() * mk["speed"] * dt
		mk["phase"] += dt * mk["speed"] * 5.5
		var hit := _ground_hit(p)
		var gy: float = hit.position.y if not hit.is_empty() and abs(hit.position.y - p.y) < 1.5 else target.y
		n.global_position = Vector3(p.x, gy + abs(sin(mk["phase"])) * 0.035, p.z)
		n.rotation.y = lerp_angle(n.rotation.y, atan2(to.x, to.z), 0.15)
		n.rotation.z = sin(mk["phase"]) * 0.035
