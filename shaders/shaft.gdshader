// The smoke hole's shaft of day falling through the smoke onto the hearth (plan chapter 04, 4.2: "the smoke-hole's shaft
// of daylight falling through smoke onto the hearth"; ISS-105): a card from the hole to the floor that turns about its
// length to face the camera, brightest under the hole and fading to the floor, its edges soft, the smoke drifting up
// through it. No light of its own (the room's spot under the hole is the light: tools/build/make_rooms.gd). Additive, so
// it only brightens; its strength follows the day beyond (interiors/room.gd).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float strength = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	// turn about the card's own up (its length) to face the camera, keeping its size
	vec3 up = normalize(MODEL_MATRIX[1].xyz);
	vec3 to_cam = CAMERA_POSITION_WORLD - MODEL_MATRIX[3].xyz;
	vec3 side = normalize(cross(up, to_cam));
	vec3 fwd = cross(side, up);
	mat4 m = mat4(vec4(side * length(MODEL_MATRIX[0].xyz), 0.0), vec4(up * length(MODEL_MATRIX[1].xyz), 0.0), vec4(fwd, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * m;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float x = UV.x * 2.0 - 1.0;
	float y = UV.y;  // 0 at the hole, 1 at the floor
	float edge = 1.0 - smoothstep(0.3, 1.0, abs(x));
	float fall = mix(1.0, 0.3, y) * smoothstep(0.0, 0.05, y) * (1.0 - smoothstep(0.8, 1.0, y));
	float t = TIME * 0.35;
	float smoke = vnoise(vec2(x * 2.2, y * 3.0 + t)) * 0.6 + vnoise(vec2(x * 5.0 + 3.0, y * 8.0 + t * 1.7)) * 0.4;
	float a = edge * fall * mix(0.35, 1.0, smoothstep(0.25, 0.8, smoke));
	ALBEDO = vec3(1.0, 0.95, 0.86) * a * strength * 0.22;
}
