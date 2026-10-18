// Stylized surface: painterly colour variation, soft two-tone light with cool tinted shadows, toon highlights,
// rim light, and a few procedural patterns (flagstones, yak curtain, painted beams, mural, terrain, mountains,
// gilded tiles), all in world space so the imported geometry needs no UVs.
shader_type spatial;

uniform float ink_codes = 0.0;  // 1 in M1's look: write the ink pass's line group (chapter 09, 8.2); 0 keeps the draft's roughness and sky reflections
uniform vec3 base_color : source_color = vec3(0.9);
uniform vec3 shade_color : source_color = vec3(0.36, 0.44, 0.70);
uniform float paint = 0.07;
uniform float streaks = 0.0;
uniform float fibers = 0.0;
uniform int pattern = 0;
uniform float gloss = 0.0;
uniform float rim = 0.12;
uniform float soft = 0.1;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;

#include "res://shaders/inc/horizon.gdshaderinc"
varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float tri(vec3 p, vec3 n, float s) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 1e-5);
	return texture(noise_tex, p.zy * s).r * w.x + texture(noise_tex, p.xz * s).r * w.y + texture(noise_tex, p.xy * s).r * w.z;
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec3 cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	vec2 id = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash21(i + g), hash21(i + g + 17.3)) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; id = i + g; }
			else if (d < d2) { d2 = d; }
		}
	}
	return vec3(d2 - d1, hash21(id), d1);
}

void fragment() {
	vec3 col = base_color;
	float n1 = tri(wpos, wnrm, 0.045);
	float n2 = tri(wpos, wnrm, 0.35);
	col *= 1.0 + (n1 - 0.5) * paint * 2.2 + (n2 - 0.5) * paint;
	float hz = wpos.x + wpos.z;
	if (streaks > 0.0) {
		float s = texture(noise_tex, vec2(hz * 0.55, wpos.y * 0.035)).r;
		col *= 1.0 - smoothstep(0.52, 0.78, s) * streaks;
	}
	if (fibers > 0.0) {
		float f = texture(noise_tex, vec2(hz * 4.0, wpos.y * 0.12)).r;
		col *= 1.0 + (f - 0.5) * fibers * 1.6;
	}
	if (pattern == 1) {
		vec3 c = cells(wpos.xz * 0.95);
		col *= 0.9 + 0.2 * c.y;
		col = mix(col, col * 0.72, 1.0 - smoothstep(0.015, 0.05, c.x));
	} else if (pattern == 2) {
		vec2 uv = vec2(hz, wpos.y) * 2.3;
		vec2 q = abs(fract(uv) - 0.5);
		float dm = q.x + q.y;
		float mark = max(step(0.31, dm) * step(dm, 0.38), step(dm, 0.08));
		col = mix(col, vec3(0.93, 0.91, 0.86), mark);
	} else if (pattern == 3) {
		float f = fract(hz * 2.2);
		vec3 pal = f < 0.2 ? vec3(0.72, 0.16, 0.10) : f < 0.4 ? vec3(0.16, 0.52, 0.30) : f < 0.6 ? vec3(0.17, 0.32, 0.68)
			: f < 0.8 ? vec3(0.93, 0.71, 0.22) : vec3(0.95, 0.93, 0.88);
		float line = step(fract(wpos.y * 9.0), 0.12);
		col = mix(pal, vec3(0.08), line * 0.7);
	} else if (pattern == 4) {
		vec2 uv = vec2(hz * 1.1, wpos.y * 0.95);
		vec2 f = fract(uv) - 0.5;
		float r = hash21(floor(uv));
		vec3 body = r < 0.3 ? vec3(0.75, 0.18, 0.12) : r < 0.55 ? vec3(0.18, 0.4, 0.66) : r < 0.8 ? vec3(0.9, 0.62, 0.2) : vec3(0.2, 0.55, 0.32);
		col = mix(vec3(0.10, 0.25, 0.23), vec3(0.14, 0.32, 0.27), n2);
		col = mix(col, vec3(0.95, 0.74, 0.3), step(length(f - vec2(0.0, 0.12)), 0.3));
		col = mix(col, vec3(0.78, 0.22, 0.16), step(length((f - vec2(0.0, -0.33)) * vec2(0.6, 2.2)), 0.2));
		col = mix(col, body, step(length((f - vec2(0.0, -0.08)) * vec2(1.0, 0.8)), 0.24));
		col = mix(col, vec3(0.95, 0.8, 0.6), step(length(f - vec2(0.0, 0.2)), 0.08));
	} else if (pattern == 5) {
		float flatness = smoothstep(0.78, 0.93, wnrm.y);
		float g = tri(wpos, wnrm, 0.02);
		vec3 grass = mix(vec3(0.24, 0.40, 0.13), vec3(0.50, 0.60, 0.22), smoothstep(0.35, 0.7, g));
		vec3 soil = mix(vec3(0.45, 0.35, 0.24), vec3(0.58, 0.47, 0.32), n2);
		vec3 rock = mix(vec3(0.38, 0.36, 0.36), vec3(0.52, 0.5, 0.48), n2);
		col = mix(rock, soil, smoothstep(0.55, 0.8, wnrm.y));
		col = mix(col, grass, flatness * smoothstep(0.3, 0.5, g));
	} else if (pattern == 6) {
		float m = tri(wpos, wnrm, 0.0009);
		col = mix(vec3(0.42, 0.44, 0.52), vec3(0.58, 0.6, 0.68), m);
		float snow = smoothstep(1150.0, 1350.0, wpos.y + (m - 0.5) * 600.0) * smoothstep(0.35, 0.6, wnrm.y);
		col = mix(col, vec3(0.94, 0.96, 1.0), snow);
	} else if (pattern == 7) {
		float sel = step(abs(wnrm.z), abs(wnrm.x));
		float c = mix(wpos.x, wpos.z, sel);
		float groove = pow(abs(sin(c * 21.0)), 0.6);
		col *= 0.78 + 0.26 * groove;
	}
	ALBEDO = col;
	if (ink_codes > 0.5) {
		ROUGHNESS = 1.5 / 16.0;  // line group 1, architecture, for the ink pass (chapter 09, 8.2)
		SPECULAR = 0.0;  // the engine's sky reflections read roughness: off
	} else {
		ROUGHNESS = 0.9;
	}
}

void light() {
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);  // art step A8: the terrain's shadow
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(0.0, soft, ndl) * ATTENUATION;
	vec3 direct = LIGHT_COLOR * lit;
	vec3 bounce = LIGHT_COLOR * shade_color * 0.16 * (1.0 - lit) * light_reach(LIGHT_IS_DIRECTIONAL, ATTENUATION);  // (ISS-164)
	float r = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0) * rim * lit;
	DIFFUSE_LIGHT += (direct + bounce + LIGHT_COLOR * r) / PI * ridge;
	if (gloss > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		float sp = pow(max(dot(NORMAL, h), 0.0), 48.0);
		SPECULAR_LIGHT += LIGHT_COLOR * smoothstep(0.3, 0.42, sp) * gloss * lit * 0.6 * ridge;
	}
}
