// The town's lamps and embers at dusk (world/lamps.gd; IMP-021 (3)), drawn as shaders/flame.gdshader draws a room's: cards
// that face the camera, one MultiMesh a kind. INSTANCE_CUSTOM: r its strength (0 while out: nothing drawn), g its seed.
// kind 0: a butter lamp's flame or a fire's tongue, a teardrop of #F4B24A with a flicker; 1: a burner's embers or a fire's
// coals, a low glow of #FF7A2F breathing; 2: a lamp seen from far off, a soft warm point kept `px` pixels across whatever
// its distance (for the monastery's and the ritro's, when they are seen: ISS-120). Additive and unshaded, so it only ever
// brightens.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform int kind = 0;
uniform float px = 3.0;  // kind 2: its size on the screen

varying float v_str;
varying float v_seed;

void vertex() {
	v_str = INSTANCE_CUSTOM.r;
	v_seed = INSTANCE_CUSTOM.g;
	vec3 sx = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	if (kind == 2) {  // a metre on the screen is 2 d / (P11 H) pixels' worth at distance d
		float d = length((VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz, 1.0)).xyz);
		sx = max(sx, vec3(px * 2.0 * d / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y)));
	}
	if (v_str <= 0.001) {
		sx = vec3(0.0);  // out
	}
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sx.x, INV_VIEW_MATRIX[1] * sx.y, INV_VIEW_MATRIX[2] * sx.z, MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;  // -1..1, y down
	float t = TIME + v_seed * 17.0;
	float a;
	vec3 c;
	if (kind == 0) {
		// a teardrop: round below, drawn to a point above; it sways a little
		p.x += sin(t * 7.3) * 0.06 * (1.0 - p.y) * 0.5;
		float up = clamp(-p.y, 0.0, 1.0);
		float w = mix(0.55, 0.08, up);
		float d = length(vec2(p.x / w, (p.y - 0.25) / (p.y > 0.25 ? 0.55 : 1.25)));
		a = 1.0 - smoothstep(0.55, 1.0, d);
		float core = 1.0 - smoothstep(0.0, 0.6, d);
		c = mix(vec3(1.0, 0.45, 0.12), vec3(1.0, 0.82, 0.45), core) * (2.4 + core * 2.0);
		a *= 0.92 + 0.08 * sin(t * 8.1) * sin(t * 6.3 + 1.7);
	} else if (kind == 1) {
		float d = length(p * vec2(1.0, 1.6));
		a = 1.0 - smoothstep(0.1, 1.0, d);
		float breathe = 0.75 + 0.25 * sin(t * 1.3) * sin(t * 2.9 + 0.7);
		c = mix(vec3(0.76, 0.29, 0.12), vec3(1.0, 0.48, 0.18), 1.0 - smoothstep(0.0, 0.7, d)) * 1.8 * breathe;
	} else {
		float d = length(p);
		a = pow(1.0 - smoothstep(0.0, 1.0, d), 2.0);
		c = mix(vec3(1.0, 0.55, 0.2), vec3(1.0, 0.86, 0.56), 1.0 - smoothstep(0.0, 0.35, d)) * 3.2 * (0.94 + 0.06 * sin(t * 2.3));
	}
	ALBEDO = c * a * v_str;
	ALPHA = 1.0;
}
