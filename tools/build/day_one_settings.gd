extends SceneTree
## RT-02 (plan chapter 11, 2.1 and 7.3): the day-one project settings and the game's one list of shader globals.
## Run headless: Godot --headless --path . -s tools/build/day_one_settings.gd
## Idempotent: running it again rewrites the same values.

const GLOBALS := {
	"g_time": ["float", 0.0], "g_game_minute": ["float", 0.0],
	"g_sun_dir": ["vec3", Vector3(0, 1, 0)], "g_moon_dir": ["vec3", Vector3(0, -1, 0)],
	"g_sun_alt": ["float", 40.0], "g_sun_az": ["float", 215.0], "g_moon_phase": ["float", 0.5], "g_lst": ["float", 0.0],
	"g_wind": ["vec4", Vector4(1, 0, 1, 0)],
	"g_wetness": ["float", 0.0], "g_snow": ["float", 0.0], "g_cloud_base": ["float", 4000.0], "g_rain": ["float", 0.0],
	"g_draught": ["float", 0.0],
	"g_horizon_core": ["sampler2DArray", ""], "g_horizon_valley": ["sampler2DArray", ""],
	"g_horizon_ring": ["sampler2DArray", ""], "g_horizon_core_rect": ["vec4", Vector4.ZERO],
	"g_horizon_valley_rect": ["vec4", Vector4.ZERO], "g_horizon_ring_rect": ["vec4", Vector4.ZERO],
	"g_horizon_place": ["vec4", Vector4.ZERO],
	"g_palette": ["sampler2D", ""], "g_noise": ["sampler2D", ""],
	"g_sun_col": ["vec3", Vector3(1.0, 0.93, 0.8)], "g_shade_tint": ["vec3", Vector3(0.36, 0.44, 0.70)],
	"g_lac_tint": ["vec3", Vector3(1, 1, 1)], "g_indigo_tint": ["vec3", Vector3(1, 1, 1)],
	"g_sky_fill": ["vec3", Vector3(0.5, 0.6, 0.8)], "g_ground_bounce": ["vec3", Vector3(0.5, 0.45, 0.4)],
	"g_ramp_row": ["float", 0.0], "g_snow_line": ["float", 99999.0], "g_night_glow": ["float", 0.0],
	"g_player": ["vec3", Vector3(0, -10000, 0)],  # the walker's feet, for what the walker pushes through (shaders/laundry_mm.gdshader)
	"g_ramps": ["sampler2D", ""], "g_gust_tex": ["sampler2D", ""], "g_gusts": ["sampler2D", ""],
}

func _init() -> void:
	var s := {
		"physics/3d/physics_engine": "Jolt Physics",
		"display/window/dpi/allow_hidpi": true,
		"physics/common/physics_ticks_per_second": 30,
		"physics/common/physics_interpolation": true,
		"rendering/occlusion_culling/use_occlusion_culling": true,
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality": 2,
		"application/run/max_fps": 30,
	}
	for k in s:
		ProjectSettings.set_setting(k, s[k])
	for name in GLOBALS:
		ProjectSettings.set_setting("shader_globals/" + name, {"type": GLOBALS[name][0], "value": GLOBALS[name][1]})
	var err := ProjectSettings.save()
	print("day_one_settings: saved project.godot, error=", err, ", globals=", GLOBALS.size())
	quit(err)
