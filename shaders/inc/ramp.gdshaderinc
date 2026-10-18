// Chapter 09's painted light for lit shaders (art step A2): the ramp atlas (4.2), looked up with
// x = N.L * 0.5 + 0.5 + the painted shadow bias, and the shadow colour chosen by the albedo's hue (4.3): neutrals take
// the day's shade tint, reds, maroons and ochres go towards lac (crimson), blues and greens towards indigo, and deep
// lanes warm up with light off the sunny wall opposite. The ramp atlas is built by tools/build/ramps.gd.

global uniform sampler2D g_ramps : filter_linear, repeat_disable;
global uniform float g_ramp_row;
global uniform vec3 g_shade_tint;
global uniform vec3 g_lac_tint;
global uniform vec3 g_indigo_tint;
global uniform vec3 g_sun_dir;

vec3 ramp_lookup(int family, float x) {
	float set = clamp(g_ramp_row, 0.0, 1.0) * 3.0;
	float s0 = floor(set);
	float s1 = min(s0 + 1.0, 3.0);
	vec3 a = textureLod(g_ramps, vec2(x, (float(family) * 4.0 + s0 + 0.5) / 32.0), 0.0).rgb;
	vec3 b = textureLod(g_ramps, vec2(x, (float(family) * 4.0 + s1 + 0.5) / 32.0), 0.0).rgb;
	return mix(a, b, set - s0);
}

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// Lac and indigo keep their hue at the brightness of the day's shade tint, so a red wall's shadow is as light as a
// white wall's, only crimson.
vec3 shadow_tint(vec3 albedo, float sky_occ) {
	vec3 hsv = rgb2hsv(albedo);
	// Saturation above 0.45, not chapter 09's 0.25: at 0.25 a whitewash plinth dirtied with brown grime counted as
	// ochre and shaded pink (A2's stills, 25 Sep 2026).
	float red = smoothstep(0.4, 0.5, hsv.y) * clamp(smoothstep(0.90, 0.95, hsv.x) + 1.0 - smoothstep(0.10, 0.15, hsv.x), 0.0, 1.0);
	float bg = step(0.2, hsv.y) * smoothstep(0.30, 0.38, hsv.x) * (1.0 - smoothstep(0.70, 0.78, hsv.x));
	float l = luma(g_shade_tint);
	vec3 lac = g_lac_tint * l / max(luma(g_lac_tint), 1e-3);
	vec3 ind = g_indigo_tint * l / max(luma(g_indigo_tint), 1e-3);
	vec3 t = mix(g_shade_tint, lac, red);
	t = mix(t, ind, bg);
	float lane = (1.0 - smoothstep(0.2, 0.4, sky_occ)) * smoothstep(0.35, 0.6, g_sun_dir.y);
	return mix(t, vec3(0.807, 0.686, 0.479), 0.25 * lane);  // #E8D8B8, sunlit whitewash across the lane
}
