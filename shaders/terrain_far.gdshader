// The mountain ring as a mesh (plan chapter 09, 13.4; chapter 11, 8.2 step 8): the same ground colour as the
// Terrain3D valley (inc/terrain_color.gdshaderinc) and the stylized light, so the two meet without a seam.
// First cut for spike S3: the ring to 15 km from the 30 m tiles; far.gdshader (haze bands, Karma Gadri strips, the
// ridge shadow) comes with art step A9.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 shade_color : source_color = vec3(0.36, 0.44, 0.70);
uniform float soft = 0.25;  // as terrain.gdshader, so the two meet
uniform float rim = 0.04;

#include "res://shaders/inc/light_stylized.gdshaderinc"
#include "res://shaders/inc/terrain_color.gdshaderinc"
#include "res://shaders/inc/horizon.gdshaderinc"

global uniform vec3 g_sun_dir;  // towards the sun (world/keyframes.gd)
global uniform float g_sun_alt;  // its altitude, degrees (world/day.gd)

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(wnrm);
	float snow = terrain_snow(wpos, n);
	ALBEDO = mix(terrain_color(wpos, n, length(wpos.xz - CAMERA_POSITION_WORLD.xz)), c_snow, snow);
	ROUGHNESS = 2.5 / 16.0;
	SPECULAR = 0.0;
	// The alpenglow's own light on the highest snow facing the low sun, so it carries through the valley's haze 12 km and
	// more (V-13a: Dungri Karpo "blushing while everyone below is in the dark"): gold, then pink in the last three degrees
	float low = smoothstep(-0.6, 1.0, g_sun_alt) * smoothstep(7.0, 2.5, g_sun_alt);
	float face = clamp(dot(n, normalize(g_sun_dir)), 0.0, 1.0);
	float top = smoothstep(4600.0, 5000.0, wpos.y + TERRAIN_DATUM);
	EMISSION = mix(vec3(1.0, 0.78, 0.50), vec3(0.97, 0.62, 0.58), smoothstep(3.5, 0.5, g_sun_alt)) * low * face * snow * top * 1.6;
}

void light() {
	vec3 d = vec3(0.0);
	vec3 s = vec3(0.0);
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, 0.0);  // art step A8: the terrain's shadow
	stylized_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, shade_color, soft, rim, 0.0, d, s);
	// The alpenglow (chapter 08, V-13a; chapter 02, 2.8): the low sun on the high snow, gold from 7 degrees, pink in its
	// last three (#F7B8A8 lit, the shade's blue the shadowed snow), after the valley has gone blue (M2 sprint 6, step 5)
	float glow = 0.0;
	float pink = 0.0;
	if (LIGHT_IS_DIRECTIONAL) {
		float e = degrees(asin(clamp((INV_VIEW_MATRIX * vec4(LIGHT, 0.0)).y, -1.0, 1.0)));
		float high = smoothstep(4300.0, 4800.0, wpos.y + TERRAIN_DATUM);
		glow = high * smoothstep(7.0, 3.0, e);
		pink = high * smoothstep(3.5, 0.5, e);
		// The highest summits keep the sun while it is up: the ring's 128 m map shades a sharp peak by itself (its texels'
		// eyes below the summit), which had put Dungri Karpo in shadow at 16:01 where its rays give 17:17
		float summit = smoothstep(4700.0, 5000.0, wpos.y + TERRAIN_DATUM);
		ridge = mix(ridge, smoothstep(-0.6, 0.2, e), summit);
	}
	vec3 tint = mix(vec3(1.0), mix(vec3(1.0, 0.86, 0.62), vec3(1.0, 0.70, 0.66), pink), glow) * (1.0 + 0.3 * glow);
	DIFFUSE_LIGHT += d * ridge * tint;
	SPECULAR_LIGHT += s * ridge;
}
