// A lamp's flame or a fire's glow, drawn as a card that faces the camera (plan chapter 04, 8.3-8.4; the game's
// sprint 7): no light of its own (the room's OmniLight3D is the light). kind 0: a butter or oil lamp's flame, a small
// teardrop of #F4B24A, steady but for a flicker of +/-8 % at 6-10 Hz; kind 1: coals or a fire's mouth, a low glow of
// #FF7A2F falling to #C24A1E with a slower breathing. Additive, so it only ever brightens; the glow picks up its core.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform int kind = 0;
uniform float strength = 1.0;
uniform float seed = 0.0;

void vertex() {
	// face the camera, keeping the card's size (its world scale)
	vec3 sx = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sx.x, INV_VIEW_MATRIX[1] * sx.y, INV_VIEW_MATRIX[2] * sx.z, MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;  // -1..1, y down
	float t = TIME + seed * 17.0;
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
	} else {
		float d = length(p * vec2(1.0, 1.6));
		a = 1.0 - smoothstep(0.1, 1.0, d);
		float breathe = 0.8 + 0.2 * sin(t * 1.3) * sin(t * 2.9 + 0.7);
		c = mix(vec3(0.76, 0.29, 0.12), vec3(1.0, 0.48, 0.18), 1.0 - smoothstep(0.0, 0.7, d)) * 1.6 * breathe;
	}
	ALBEDO = c * a * strength;
	ALPHA = 1.0;
}
