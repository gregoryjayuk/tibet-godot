shader_type spatial;
// The hearths' smoke (world/hearths.gd; M1 sprint 8, step 2; plan chapter 03, 14.4): each instance is one kitchen's
// thread, out of its window (a poor house's door) and up: its puffs (the mesh's quads, their place in the thread in
// VERTEX.z) leave the wall, lean out a metre and rise, growing, thin and blue-grey, lit only by the sky's colour as the
// sang's are (shaders/smoke.gdshader). Its hours are the household's own (world/hearths.gd draws them from its name): the morning fire from about
// six for the tea, the midday meal in two houses of three, the evening meal in all, and in a third of them a thin thread
// all day where the tea is kept warm. The morning's air carries it down the valley (west), the afternoon's up it (east).
// Instance transform: the kitchen socket's place, its basis's x the way out of the wall (horizontal).
// Instance data (world/hearths.gd draws each household's hours): x its phase, y its strength (negative: a thread kept
// all day as well), z its height (m), w the minute its morning fire goes out; colour, in days: r the morning fire lit,
// g the midday fire lit (0: none), b the evening fire lit, a the evening fire out.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, skip_vertex_transform, shadows_disabled;

global uniform vec3 g_sky_fill;
global uniform float g_sun_alt;
global uniform float g_time;
uniform float minute = 0.0;  // the clock: minutes of the day, local time (world/hearths.gd)
uniform float rise = 0.42;  // metres a second
uniform sampler2D noise_tex : filter_linear, repeat_enable;  // wisps: the puffs' edges broken (world/hearths.gd makes it)

varying float v_alpha;
varying float v_top;
varying vec2 v_seed;

float window(float m, float open, float close) {
	return smoothstep(open, open + 6.0, m) * (1.0 - smoothstep(close, close + 20.0, m));
}

// How much the household's fire smokes at minute m (world/hearths.gd `smoking`).
float hearth(float m, vec4 c, vec4 hours) {
	float morning = window(m, hours.r * 1440.0, c.w);
	float noon = hours.g > 0.0 ? window(m, hours.g * 1440.0, hours.g * 1440.0 + 95.0) : 0.0;
	float evening = window(m, hours.b * 1440.0, hours.a * 1440.0);
	float kept = c.y < 0.0 ? 0.3 * window(m, 480.0, 1050.0) : 0.0;
	return max(max(morning, noon), max(evening, kept)) * abs(c.y);
}

void vertex() {
	vec4 c = INSTANCE_CUSTOM;
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 outw = normalize(vec3(MODEL_MATRIX[0].x, 0.0, MODEL_MATRIX[0].z));
	float H = max(c.z, 1.0);
	float t = fract(g_time * rise / H + VERTEX.z + c.x);  // 0 at the window, 1 at the thread's top
	float h = t * H;
	float on = hearth(minute, c, COLOR);  // COLOR: the instance's colour (the mesh has none of its own)
	float up_valley = smoothstep(600.0, 720.0, minute);
	vec3 lean = mix(vec3(-0.02, 0.0, -0.004), vec3(0.02, 0.0, 0.004), up_valley);
	vec3 centre = origin + outw * (0.35 + 0.85 * smoothstep(0.0, 2.5, h)) + vec3(0.0, h, 0.0) + lean * h * h;
	centre.x += 0.16 * sin(g_time * 0.8 + c.x * 40.0 + h * 0.9) * t;  // a slow sway
	centre.z += 0.12 * cos(g_time * 0.6 + c.x * 23.0 + h * 0.7) * t;
	float size = mix(0.4, 3.2, sqrt(t));
	v_alpha = on * smoothstep(0.0, 0.04, t) * (1.0 - smoothstep(0.4, 1.0, t)) * mix(0.7, 0.22, t);
	v_top = UV.y;
	v_seed = vec2(c.x * 17.0 + VERTEX.z * 5.3, t * 0.7 + c.x * 3.1);
	vec4 cv = VIEW_MATRIX * vec4(centre, 1.0);  // the puff's middle in view space, the quad turned to the eye
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
	// wood and dung smoke, greyer and darker than juniper's: half the sky's colour, half a neutral grey, so a thread still
	// shows against the noon's sunlit sand as well as against the sky and the shadowed slopes
	float day = smoothstep(-6.0, 20.0, g_sun_alt);
	vec3 lit = mix(sky * 0.85 + vec3(0.07, 0.07, 0.08), vec3(0.36, 0.36, 0.38) * (0.35 + 0.65 * day), 0.55);
	vec3 shade = lit * 0.7;
	float dusk = mix(0.35, 1.0, smoothstep(-10.0, 4.0, g_sun_alt));  // after sunset the threads go grey with the sky
	ALBEDO = mix(shade, lit, smoothstep(0.9, 0.1, v_top)) * dusk;
	ALPHA = v_alpha * soft;
}
