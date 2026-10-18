// Prayer flags: flutter in the wind (vertex colour red = how far from the cord), glow when backlit.
shader_type spatial;
render_mode cull_disabled;

global uniform float g_time; // animation time, set by the game each frame and frozen in screenshot mode (plan chapter 11, 7.3)

uniform float ink_codes = 0.0;  // 1 in M1's look: write the ink pass's line group (chapter 09, 8.2); 0 keeps the draft's roughness and sky reflections
uniform vec3 base_color : source_color = vec3(0.9);
uniform float wind = 1.0;

#include "res://shaders/inc/horizon.gdshaderinc"

varying float hang;
varying vec3 wpos;

void vertex() {
	hang = COLOR.r;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = g_time * 3.4;
	float w = sin(t + wp.x * 1.7 + wp.z * 1.3) * 0.6 + sin(t * 2.1 + wp.x * 3.3 - wp.z) * 0.4;
	vec3 d = vec3(0.13 * w, 0.035 * sin(t * 1.7 + wp.z * 2.1), 0.1 * cos(t * 1.3 + wp.z * 2.0)) * hang * wind;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(d, 0.0)).xyz;
	wpos = wp + d;
}

void fragment() {
	ALBEDO = base_color * (0.95 + 0.1 * hang);
	BACKLIGHT = base_color * 0.55;
	if (ink_codes > 0.5) {
		ROUGHNESS = 0.5 / 16.0;  // line group 0: no ink lines on flags (chapter 09, 8.2)
		SPECULAR = 0.0;  // the engine's sky reflections read roughness: off
	} else {
		ROUGHNESS = 0.85;
	}
}

void light() {
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);  // art step A8: the terrain's shadow
	float ndl = abs(dot(NORMAL, LIGHT));
	float lit = smoothstep(0.0, 0.2, ndl) * ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 * light_reach(LIGHT_IS_DIRECTIONAL, ATTENUATION) + 0.65 * lit) / PI * ridge;  // (ISS-164)
}
