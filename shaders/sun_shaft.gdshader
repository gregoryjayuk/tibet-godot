// A shaft of sun through a window into a dark hall (plan chapter 04, 8.5; the game's M3 sprint 5, step 4): the window's
// rectangle swept along the sun's ray (world/shafts.gd gives the mesh, a unit box, and a sheared basis: its x the
// window's width, its y its height, its z the sun's way in times the shaft's reach), drawn by its back faces with no depth
// test, each pixel lit by how far its view ray runs inside the shaft before the hall's own surfaces stop it (the depth
// texture), so it reads the same from inside it, beside it and through a pillar's gap. Additive, its edges soft, smoke
// drifting through it, the end where it lands brightest; no light of its own (spike S7 tries a real one).
shader_type spatial;
render_mode unshaded, blend_add, cull_front, depth_draw_never, depth_test_disabled, shadows_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform mat4 to_local;  // the world into the shaft's box (the inverse of its transform, set with it)
uniform vec3 color = vec3(1.0, 0.92, 0.78);  // the sun's at the hour times 0.6 (chapter 04, 8.5)
uniform float strength = 0.0;  // the window's share lit (data/sun_tables.json)
uniform float density = 0.3;  // a metre of shaft's brightness
uniform float drift = 0.25;  // the smoke's rise, metres a second
uniform float patch_gain = 1.4;  // the patch of sun where it lands
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);  // towards the sun (world/shafts.gd): a surface's patch as it faces it

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

void fragment() {
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	vec3 scene = (INV_VIEW_MATRIX * vec4(v.xyz / v.w, 1.0)).xyz;  // the first surface behind this pixel
	vec3 cam = CAMERA_POSITION_WORLD;
	vec3 ro = (to_local * vec4(cam, 1.0)).xyz;
	vec3 rd = (to_local * vec4(scene - cam, 0.0)).xyz;  // t from 0 at the eye to 1 at that surface
	vec3 inv = 1.0 / rd;
	vec3 t0 = (vec3(-0.5) - ro) * inv;
	vec3 t1 = (vec3(0.5) - ro) * inv;
	vec3 tmin = min(t0, t1);
	vec3 tmax = max(t0, t1);
	float tn = max(max(max(tmin.x, tmin.y), tmin.z), 0.0);
	float tf = min(min(min(tmax.x, tmax.y), tmax.z), 1.0);
	float span = max(tf - tn, 0.0);
	if (span <= 0.0) {
		discard;
	}
	float metres = span * length(scene - cam);
	vec3 mid = ro + rd * (tn + tf) * 0.5;  // the middle of its run inside, in the box
	float edge = (1.0 - smoothstep(0.3, 0.5, abs(mid.x))) * (1.0 - smoothstep(0.3, 0.5, abs(mid.y)));
	vec3 w = cam + (scene - cam) * (tn + tf) * 0.5;
	float smoke = vnoise3(w * 0.9 + vec3(0.0, -TIME * drift, 0.0)) * 0.6 + vnoise3(w * 2.3 + vec3(5.0, -TIME * drift * 1.6, 2.0)) * 0.4;
	float a = (1.0 - exp(-metres * density)) * edge * mix(0.45, 1.0, smoothstep(0.2, 0.8, smoke));
	// where it falls on a surface inside it (the aisle's boards at noon, a pillar it crosses): the sun's patch
	vec3 sl = ro + rd;
	float on = step(abs(sl.x), 0.5) * step(abs(sl.y), 0.5) * step(abs(sl.z), 0.5);
	vec3 nrm = normalize(cross(dFdx(scene), dFdy(scene)));  // the surface's normal from the depth's derivatives
	nrm = dot(nrm, cam - scene) < 0.0 ? -nrm : nrm;
	float facing = smoothstep(0.05, 0.4, dot(nrm, sun_dir));  // (the floor's patch, a pillar's sunward face; none round its back)
	float lit = on * facing * (1.0 - smoothstep(0.3, 0.5, abs(sl.x))) * (1.0 - smoothstep(0.3, 0.5, abs(sl.y))) * patch_gain;
	ALBEDO = color * strength * (a + lit);
}
