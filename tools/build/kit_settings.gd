extends SceneTree
## RT-09 (plan chapter 11, 19.3): the scene importer's project defaults for the kit, and the import plugin enabled.
## Idempotent. Run headless: Godot --headless --path . -s tools/build/kit_settings.gd

func _init() -> void:
	ProjectSettings.set_setting("importer_defaults/scene", {
		"nodes/use_node_type_suffixes": false,  # Godot would otherwise turn _COL and _OCC into its own collision and occluders
		"meshes/generate_lods": true,
		"meshes/create_shadow_meshes": true,
		"meshes/force_disable_compression": false,  # spike S2 flips this if the ramp shows compressed UVs moving ids
	})
	ProjectSettings.set_setting("editor_plugins/enabled", PackedStringArray(["res://addons/dungkardo_import/plugin.cfg"]))
	# The palette shader's material, with the draft's 512-texel seamless noise, saved once as a resource.
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_octaves = 5
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.generate_mipmaps = true
	tex.noise = noise
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/stylized_static.gdshader")
	mat.set_shader_parameter("noise_tex", tex)
	print("stylized_static.tres: ", ResourceSaver.save(mat, "res://shaders/materials/stylized_static.tres"))
	var err := ProjectSettings.save()
	print("kit_settings: saved, error=", err)
	quit(err)
