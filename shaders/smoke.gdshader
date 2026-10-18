shader_type spatial;
// The sang's smoke (plan chapter 08, V-28; chapter 05, A-07 and A-08; M1 sprint 4, step 6): each instance of the
// MultiMesh is one roof burner's thread, PUFFS puffs (the mesh's quads, COLOR.r their place in the column) rising from
// its SANG socket and growing, leaning a little east with the evening air, lit only by the sky's colour (g_sky_fill):
// the side to the sky pale, the side away from it greyer. Out of the burner's window (the morning's 05:45-06:30, the
// evening's 17:00-17:45, each household a few minutes after the next: INSTANCE_CUSTOM.y) the thread thins away.
// Instance data: x its phase, y the minutes after the window opens that it is lit (30 or more: the morning's alone, its
// window that much later), z its strength, w its height (m).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, skip_vertex_transform, shadows_disabled;

global uniform vec3 g_sky_fill;
global uniform float g_sun_alt;
global uniform float g_time;
uniform float minute = 0.0;  // the clock: minutes of the day, local time (world/dusk.gd)
uniform vec3 lean = vec3(0.022, 0.0, 0.004);  // metres aside per metre squared of rise: east (+x), a touch south (+z)
uniform float rise = 0.55;  // metres a second
uniform sampler2D noise_tex : filter_linear, repeat_enable;  // wisps: the puffs' edges broken (world/dusk.gd makes it)

varying float v_alpha;
varying float v_top;
varying vec2 v_seed;

float window(float m, float open, float close, float late) {
	return smoothstep(open + late, open + late + 4.0, m) * (1.0 - smoothstep(close, close + 15.0, m));
}

void vertex() {
	vec4 c = INSTANCE_CUSTOM;
	float H = max(c.w, 1.0);
	float t = fract(g_time * rise / H + COLOR.r + c.x);  // 0 at the burner, 1 at the column's top
	float h = t * H;
	// a burner lit 30 minutes or more after the window opens is a morning's alone, its window shifted with it (the Conch
	// terrace's, lit by Lama Orgyen Dorje at 06:45 for the first sun: world/dusk.gd LATE)
	float late_close = c.y >= 30.0 ? c.y + 15.0 : 0.0;  // to 08:00 for one lit at 06:45, the first sun's minute in it
	float on = max(window(minute, 17.0 * 60.0, 17.0 * 60.0 + 45.0, c.y) * step(c.y, 30.0),
			window(minute, 5.0 * 60.0 + 45.0, 6.0 * 60.0 + 30.0 + late_close, c.y)) * c.z;
	vec3 centre = vec3(0.0, h, 0.0) + lean * h * h;
	centre.x += 0.18 * sin(g_time * 0.7 + c.x * 40.0 + h * 0.8) * t;  // a slow sway
	centre.z += 0.14 * cos(g_time * 0.5 + c.x * 23.0 + h * 0.6) * t;
	float size = mix(0.45, 2.8, sqrt(t));  // a thread at the burner, a soft column above
	v_alpha = on * smoothstep(0.0, 0.05, t) * (1.0 - smoothstep(0.4, 1.0, t)) * mix(0.34, 0.12, t);
	v_top = UV.y;
	v_seed = vec2(c.x * 17.0 + COLOR.r * 5.3, t * 0.7 + c.x * 3.1);
	vec4 cv = MODELVIEW_MATRIX * vec4(centre, 1.0);  // the puff's middle in view space, the quad turned to the eye
	cv.xy += (UV - vec2(0.5)) * vec2(1.0, -1.0) * size;
	VERTEX = cv.xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	float wisp = texture(noise_tex, UV * 0.55 + v_seed).r;
	float soft = pow(max(1.0 - r, 0.0), 1.4) * smoothstep(0.22, 0.72, wisp + 0.25 * (1.0 - r));
	vec3 sky = max(g_sky_fill, vec3(0.02));
	vec3 lit = sky * 1.35 + vec3(0.12);
	vec3 shade = sky * 0.62 + vec3(0.03);
	float dusk = mix(0.35, 1.0, smoothstep(-10.0, 4.0, g_sun_alt));  // after sunset the threads go grey with the sky
	ALBEDO = mix(shade, lit, smoothstep(0.9, 0.1, v_top)) * dusk;
	ALPHA = v_alpha * soft;
}
