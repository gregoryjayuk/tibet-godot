extends RefCounted
## The ink pass's full-screen quad (plan chapter 09, 8.2, 9.4 and 11.3; art step A5): shaders/ink_air.gdshader on a
## quad parented to a camera, drawn first among the transparents (render priority -128) so smoke, flames and
## particles draw over the ink. The screen-space roughness limiter goes off while it is used, or it would bend the line
## groups the surface shaders write into roughness. This is M1's look; the draft keeps shaders/outline.gdshader.

const SHADER := preload("res://shaders/ink_air.gdshader")


static func attach(cam: Camera3D) -> ShaderMaterial:
	var q := MeshInstance3D.new()
	q.name = "Ink"
	var qm := QuadMesh.new()
	qm.size = Vector2(2, 2)
	q.mesh = qm
	q.extra_cull_margin = 16384.0
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.render_priority = Material.RENDER_PRIORITY_MIN
	for k in ["enabled", "weight", "air"]:
		m.set_shader_parameter(k, 1.0)  # set explicitly: an unset parameter reads back as null (ISS-010)
	var density := 0.0
	if cam.is_inside_tree():
		for we in cam.get_tree().root.find_children("*", "WorldEnvironment", true, false):
			var env: Environment = (we as WorldEnvironment).environment
			if env != null and env.fog_enabled:
				density = env.fog_density
	m.set_shader_parameter("fog_density", density)
	q.material_override = m
	cam.add_child(q)
	RenderingServer.screen_space_roughness_limiter_set_active(false, 0.25, 0.18)
	return m
