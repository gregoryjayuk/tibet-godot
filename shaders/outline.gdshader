// Screen-space ink lines from depth and normal discontinuities: an illustrated look (think Sable).
// Drawn on a full-screen quad; fades with distance so the far hills stay clean.
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 line_color : source_color = vec3(0.16, 0.10, 0.08);
uniform float strength = 0.8;
uniform float enabled = 1.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float lin_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	v.xyz /= v.w;
	return -v.z;
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	float d0 = lin_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 n0 = texture(normal_tex, SCREEN_UV).xyz * 2.0 - 1.0;
	float dd = 0.0;
	float nd = 0.0;
	vec2 offs[4] = vec2[](vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0));
	for (int i = 0; i < 4; i++) {
		vec2 uv = SCREEN_UV + offs[i] * px * 1.2;
		float d = lin_depth(uv, INV_PROJECTION_MATRIX);
		dd = max(dd, (d0 - d) / max(d0, 0.001));
		vec3 n = texture(normal_tex, uv).xyz * 2.0 - 1.0;
		nd = max(nd, 1.0 - dot(n, n0));
	}
	float edge = max(smoothstep(0.03, 0.09, dd), smoothstep(0.35, 0.6, nd));
	edge *= 1.0 - smoothstep(45.0, 140.0, d0);
	vec3 col = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	ALBEDO = mix(col, line_color, edge * strength * enabled);
}
