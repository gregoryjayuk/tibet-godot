// Grass tufts: colour from root to tip, sway in gusts (UV.y = height along the blade).
shader_type spatial;
render_mode cull_disabled;

global uniform float g_time; // animation time, set by the game each frame and frozen in screenshot mode (plan chapter 11, 7.3)

uniform float ink_codes = 0.0;  // 1 in M1's look: write the ink pass's line group (chapter 09, 8.2); 0 keeps the draft's roughness and sky reflections
uniform vec3 root_color : source_color = vec3(0.22, 0.36, 0.12);
uniform vec3 tip_color : source_color = vec3(0.68, 0.74, 0.32);

#include "res://shaders/inc/horizon.gdshaderinc"

varying vec3 wpos;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float gust = sin(g_time * 1.6 + wp.x * 0.25 + wp.z * 0.2) * 0.5 + 0.5;
	float sway = (sin(g_time * 3.0 + wp.x * 1.3 + wp.z) * 0.08 + gust * 0.16) * UV.y * UV.y;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(sway, 0.0, sway * 0.5, 0.0)).xyz;
	wpos = wp;
}

void fragment() {
	ALBEDO = mix(root_color, tip_color, UV.y);
	if (ink_codes > 0.5) {
		ROUGHNESS = 0.5 / 16.0;  // line group 0: no ink lines on grass (chapter 09, 8.2)
		SPECULAR = 0.0;  // the engine's sky reflections read roughness: off
	} else {
		ROUGHNESS = 0.9;
	}
	BACKLIGHT = tip_color * 0.3 * UV.y;
}

void light() {
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, 0.3);  // art step A8: the terrain's shadow
	float lit = smoothstep(-0.2, 0.3, dot(NORMAL, LIGHT)) * ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR * (0.45 * light_reach(LIGHT_IS_DIRECTIONAL, ATTENUATION) + 0.55 * lit) / PI * ridge;  // (ISS-164)
}
