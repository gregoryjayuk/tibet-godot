shader_type spatial;
// The Leat Fall's water (world/leat_fall.gd; M2 sprint 11, step 4; plan chapter 02, SAM-11): the Shöl leat thrown from
// its culvert's lip down the slot's face, a horsetail: a narrow rope of water at the lip spreading and breaking into
// streaks as it falls, the streaks running down at the water's speed (faster as it falls), white where it breaks, clearer
// grey-green where it is thick. The ribbon's v runs from the lip (0) to the foot (1), its u across. Lit as the falls'
// spray is: the sky's light, and the sun's where it clears the ridges (the horizon map), most looking towards the sun.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

global uniform float g_time;
global uniform vec3 g_sky_fill;
global uniform vec3 g_sun_col;
global uniform vec3 g_sun_dir;
uniform float drop = 43.0;  // metres from the lip to the foot
uniform sampler2D noise_tex : filter_linear, repeat_enable;

#include "res://shaders/inc/horizon.gdshaderinc"

varying vec3 v_col;
varying vec3 v_world;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world = w;
	vec3 to_eye = normalize(CAMERA_POSITION_WORLD - w);
	float lit = g_sun_dir.y > -0.02 ? horizon_light(w, g_sun_dir, -1000.0) : 0.0;
	float forward = pow(clamp(dot(-to_eye, normalize(g_sun_dir)), 0.0, 1.0), 4.0);
	v_col = g_sky_fill * 0.8 + vec3(0.14) + g_sun_col * lit * (0.3 + 0.9 * forward);
}

void fragment() {
	float v = UV.y;
	float u = UV.x * 2.0 - 1.0;
	// the water falls faster the further it has fallen: its streaks' phase runs with the square root of the drop
	float fall = sqrt(v * drop) * 0.35 - g_time * 1.6;
	float streak = texture(noise_tex, vec2(UV.x * 1.7 + v * 0.15, fall * 0.5)).r;
	float fine = texture(noise_tex, vec2(UV.x * 4.3 - 0.37, fall * 1.3 + 0.21)).r;
	float body = 1.0 - smoothstep(mix(0.55, 0.95, v), 1.0, abs(u));  // a rope at the lip, frayed edges below
	float broken = smoothstep(0.15, 0.8, v);  // white water where it has broken up
	float a = body * mix(0.85, 0.55, broken) * smoothstep(0.25 + 0.3 * broken, 0.75, streak * 0.7 + fine * 0.5);
	a *= smoothstep(0.0, 0.02, v) * (1.0 - smoothstep(0.96, 1.0, v));
	vec3 clear = vec3(0.55, 0.62, 0.6);  // the leat's water where it is thick, the rock showing through
	vec3 white = vec3(0.93, 0.95, 0.96);
	ALBEDO = min(v_col * mix(clear, white, clamp(broken * 0.7 + fine * 0.5, 0.0, 1.0)), vec3(1.4));
	ALPHA = clamp(a, 0.0, 0.9);
}
