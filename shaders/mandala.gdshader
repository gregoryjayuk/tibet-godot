// The painted ring on the floor where the walker stands at the chest (world/wardrobe.gd; IMP-025, after Greg's 1771, a
// figure turning on a mandala): rings and petals in the five colours, faint, as if chalked on the boards, fading at the
// rim. Unshaded, a little transparent.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

const vec3 FIVE[5] = {vec3(0.024, 0.077, 0.330), vec3(0.85, 0.83, 0.77), vec3(0.43, 0.03, 0.02), vec3(0.05, 0.21, 0.08), vec3(0.75, 0.42, 0.03)};

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float petals = 0.5 + 0.5 * cos(a * 8.0);
	float band = floor(r * 5.0);
	float ring = smoothstep(0.02, 0.0, abs(fract(r * 5.0) - 0.5) - 0.44);
	float petal = step(r, 0.62) * step(0.28, r) * smoothstep(0.55, 0.6, petals * (1.0 - (r - 0.28) / 0.34));
	vec3 c = FIVE[int(clamp(band, 0.0, 4.0))];
	float alpha = max(ring * 0.55, petal * 0.35) * (1.0 - smoothstep(0.88, 1.0, r));
	ALBEDO = c;
	ALPHA = alpha;
}
