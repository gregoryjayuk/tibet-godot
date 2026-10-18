extends GPUParticles3D
## Snow falling round the camera (IMP-021, item 4; chapter 08's V-31, the afternoon of 7 November): flakes in a box
## 44 m across and 22 m high over whichever camera is drawing, falling at about a metre a second and drifting on the wind
## up the gorge, lit by the day (`light`, from world/day.gd). Added by world/day.gd while its weather has snow falling.

var mat: StandardMaterial3D


func _ready() -> void:
	name = "Snowfall"
	amount = 22000
	lifetime = 28.0
	preprocess = 28.0
	local_coords = false
	visibility_aabb = AABB(Vector3(-45.0, -45.0, -45.0), Vector3(90.0, 90.0, 90.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(22.0, 11.0, 22.0)
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 18.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.2
	pm.gravity = Vector3(0.3, -0.35, -0.15)  # the wind up the gorge (north is -Z)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.2
	pm.turbulence_noise_scale = 5.0
	pm.turbulence_influence_min = 0.04
	pm.turbulence_influence_max = 0.12
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.93, 0.95, 1.0, 0.95)
	var g := Gradient.new()  # a soft round flake
	g.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 32
	tex.height = 32
	mat.albedo_texture = tex
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA  # none blots the lens: faded in from 0.6 m to 2 m
	mat.distance_fade_min_distance = 0.6
	mat.distance_fade_max_distance = 2.0
	q.material = mat
	draw_pass_1 = q
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## The flakes as bright as the day lets them be (k: 1 by day, about 0.2 at night).
func light(k: float) -> void:
	if mat != null:
		mat.albedo_color = Color(0.93 * k, 0.95 * k, 1.0 * k, 0.95)


func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		global_position = cam.global_position + Vector3(0.0, 6.0, 0.0)
