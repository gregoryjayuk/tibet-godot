// Stylized foliage: soft toon bands, warm lit / cool shaded greens, gentle sway that grows with height.
shader_type spatial;

global uniform float g_time; // animation time, set by the game each frame and frozen in screenshot mode (plan chapter 11, 7.3)

uniform float ink_codes = 0.0;  // 1 in M1's look: write the ink pass's line group (chapter 09, 8.2); 0 keeps the draft's roughness and sky reflections
uniform vec3 base_color : source_color = vec3(0.3, 0.55, 0.2);
uniform vec3 shade_color : source_color = vec3(0.22, 0.36, 0.42);
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;

#include "res://shaders/inc/horizon.gdshaderinc"
varying vec3 wpos;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float hgt = max(0.0, wp.y - MODEL_MATRIX[3].y) * 0.05;
	float t = g_time * 1.3;
	vec3 d = vec3(sin(t + wp.x * 0.3 + wp.z * 0.2), 0.0, cos(t * 0.8 + wp.z * 0.3)) * 0.12 * hgt;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(d, 0.0)).xyz;
	wpos = wp;
}

void fragment() {
	float n = texture(noise_tex, wpos.xz * 0.35 + wpos.y * 0.2).r;
	ALBEDO = base_color * (0.8 + 0.45 * n);
	if (ink_codes > 0.5) {
		ROUGHNESS = 4.5 / 16.0;  // line group 4, foliage: silhouettes only, at half strength (chapter 09, 8.2)
		SPECULAR = 0.0;  // the engine's sky reflections read roughness: off
	} else {
		ROUGHNESS = 0.9;
	}
}

void light() {
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);  // art step A8: the terrain's shadow
	float ndl = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float lit = ndl * ndl * mix(0.55, 1.0, ATTENUATION);
	DIFFUSE_LIGHT += LIGHT_COLOR * mix(shade_color * 0.7, vec3(1.0), lit) / PI * ridge * light_reach(LIGHT_IS_DIRECTIONAL, ATTENUATION);  // (ISS-164)
}
