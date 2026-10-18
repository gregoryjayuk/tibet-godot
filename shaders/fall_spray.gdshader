shader_type spatial;
// The Conch Fall's spray (world/rivers.gd; M2 sprint 5, step 3; plan chapter 02, SAM-13; chapter 08, V-02): puffs of
// mist thrown up where the falling sheet strikes the pool at its foot, drifting down Samkha's slot with the water and
// rising a little, growing and thinning. Each quad of the mesh is one puff (its seed in its vertices' z); the node stands
// at the fall's foot, its x downstream and its z across the water. Lit by the sky, and where the sun reaches it past the
// ridges (the horizon map) by the sun's own colour, most when the eye looks towards the sun through it: at the first sun
// up the Serchu a gold veil over the white water.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, skip_vertex_transform, shadows_disabled;

global uniform float g_time;
global uniform vec3 g_sky_fill;
global uniform vec3 g_sun_col;
global uniform vec3 g_sun_dir;
uniform float width = 6.0;  // the water's width at the foot, metres
uniform float drop = 7.75;  // the fall's height, metres
uniform float life = 4.0;  // seconds a puff lives
uniform float strength = 1.0;
uniform sampler2D noise_tex : filter_linear, repeat_enable;

#include "res://shaders/inc/horizon.gdshaderinc"

varying float v_alpha;
varying vec2 v_seed;
varying vec3 v_col;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

void vertex() {
	float k = VERTEX.z * 997.0;
	float s1 = hash(k + 0.31);
	float s2 = hash(k + 1.73);
	float s3 = hash(k + 4.09);
	float t = fract(g_time / (life * (0.8 + 0.4 * s3)) + s1);  // 0 born at the foot, 1 gone
	// born across the pool at the foot (some up the sheet's face), carried downstream and up, spreading
	vec3 local = vec3(
		0.3 + t * (3.0 + 6.0 * s2),
		0.2 + drop * 0.35 * s3 * (1.0 - t) + t * (1.2 + 2.6 * s1),
		(s2 - 0.5) * width * (0.8 + 0.5 * t));
	local.z += 0.6 * sin(g_time * 0.7 + k) * t;
	vec3 centre = (MODEL_MATRIX * vec4(local, 1.0)).xyz;
	float size = mix(0.9, 4.2, sqrt(t)) * (0.8 + 0.4 * s3);
	v_alpha = strength * smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.45, 1.0, t)) * mix(0.55, 0.18, t);
	v_seed = vec2(s1 * 5.0 + t * 0.4, s2 * 5.0);
	// the light on it: the sky's, and the sun's where the sun clears the ridges, strongest looking towards the sun
	vec3 to_eye = normalize(CAMERA_POSITION_WORLD - centre);
	float lit = g_sun_dir.y > -0.02 ? horizon_light(centre, g_sun_dir, -1000.0) : 0.0;
	float forward = pow(clamp(dot(-to_eye, normalize(g_sun_dir)), 0.0, 1.0), 4.0);
	v_col = g_sky_fill * 0.85 + vec3(0.12) + g_sun_col * lit * (0.25 + 1.1 * forward);
	vec4 cv = VIEW_MATRIX * vec4(centre, 1.0);  // the puff's middle in view space, the quad turned to the eye
	cv.xy += (UV - vec2(0.5)) * vec2(1.0, -1.0) * size;
	VERTEX = cv.xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	float wisp = texture(noise_tex, UV * 0.5 + v_seed).r;
	float soft = pow(max(1.0 - r, 0.0), 1.6) * smoothstep(0.25, 0.75, wisp + 0.3 * (1.0 - r));
	ALBEDO = min(v_col, vec3(1.4));
	ALPHA = clamp(v_alpha * soft, 0.0, 1.0);
}
