// The town's prayer flags, their cords and poles and the juniper at their feet, drawn as MultiMeshes (world/flags.gd;
// M1 sprint 8). The draft's flag shader (shaders/flag.gdshader) for instances: each flag flutters by how far it hangs
// from its tie (the mesh's vertex colour red: 0 at the cord or pole, 1 at the free edge), its own phase and strength;
// its colour, already faded by its age, is the instance's (INSTANCE_CUSTOM.rgb), its phase in INSTANCE_CUSTOM.a's
// fraction and, for a string torn loose at one end, how much its tie swings too in the whole part (0-3). The print (a
// lung-ta's rows of text round the wind horse) is faint, and only near.
// Poles, cords and juniper are the same shader with no hang: they stand still. Backlit cloth glows; the ridge's shadow
// falls on it (art step A8).
shader_type spatial;
render_mode cull_disabled;

global uniform float g_time;

uniform float wind = 1.0;
uniform float ink_codes = 1.0;  // M1's look: line group 0, no ink lines on flags (chapter 09, 8.2)
uniform float cloth = 1.0;  // 1 for flags (backlit, fluttering), 0 for poles, cords and juniper

#include "res://shaders/inc/horizon.gdshaderinc"

varying float hang;
varying vec3 wpos;
varying vec3 tint;

void vertex() {
	float sway = floor(INSTANCE_CUSTOM.a) / 3.0 * cloth;
	hang = COLOR.r * cloth;
	tint = INSTANCE_CUSTOM.rgb;
	float ph = fract(INSTANCE_CUSTOM.a) * 6.2831;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = g_time * (3.0 + 0.8 * fract(INSTANCE_CUSTOM.a * 7.3));
	float gust = 0.75 + 0.25 * sin(g_time * 0.37 + wp.x * 0.05 + ph);
	float w = sin(t + wp.x * 1.7 + wp.z * 1.3 + ph) * 0.6 + sin(t * 2.1 + wp.x * 3.3 - wp.z + ph * 1.7) * 0.4;
	// a little livelier than the draft's (Greg, 27 Sep 2026: the street demo's "fluttered a little more")
	vec3 d = vec3(0.17 * w, 0.045 * sin(t * 1.7 + wp.z * 2.1 + ph), 0.13 * cos(t * 1.3 + wp.z * 2.0 + ph)) * hang * wind * gust;
	d += vec3(0.3 * sin(g_time * 1.1 + ph), 0.12 * sin(g_time * 1.7 + ph * 2.0), 0.24 * cos(g_time * 0.9 + ph)) * sway * wind;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(d, 0.0)).xyz;
	wpos = wp + d;
}

void fragment() {
	vec3 c = tint * (0.95 + 0.1 * hang);
	if (cloth > 0.5) {  // the print: rows of text round a square for the wind horse, faint, fading out by 30 m
		float rows = step(0.55, fract(UV.y * 7.0 + 0.2)) * step(0.12, UV.x) * step(UV.x, 0.88) * step(0.1, UV.y) * step(UV.y, 0.92);
		float horse = step(abs(UV.x - 0.5), 0.2) * step(abs(UV.y - 0.5), 0.17);
		float ink = max(rows * 0.45, horse * 0.8) * (1.0 - smoothstep(10.0, 30.0, length(VERTEX)));
		c = mix(c, c * 0.45, ink * 0.35);
	}
	ALBEDO = c;
	BACKLIGHT = tint * 0.55 * cloth;
	if (ink_codes > 0.5) {
		ROUGHNESS = 0.5 / 16.0;  // line group 0
		SPECULAR = 0.0;
	} else {
		ROUGHNESS = 0.85;
	}
}

void light() {
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);
	float ndl = cloth > 0.5 ? abs(dot(NORMAL, LIGHT)) : max(dot(NORMAL, LIGHT), 0.0);
	float lit = smoothstep(0.0, 0.2, ndl) * ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 * light_reach(LIGHT_IS_DIRECTIONAL, ATTENUATION) + 0.65 * lit) / PI * ridge;  // (ISS-164)
}
