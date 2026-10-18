// The town's birds on the wing (world/birds.gd; M1 sprint 8, step 2; plan chapter 06, 6.1): the stand-in bird's VAT
// (people2/stand_ins.py) flown with no script, as characters/vat_orbit.gdshader flies spike S5's, but each flock its
// own: a ring drawn out to an ellipse and turned, its centre wandering, each bird's bob, and now and then a tumble (the
// choughs' dive), never lower than `floor_clear` over the ground under it (the horizon map's ground: a flock follows the
// slope up over the higher roofs and the rock); the bird faces along its path, noses down in a dive and banks into its
// turns; it flaps or glides by turns, and glides in a dive. Instance data, not a transform (skip_vertex_transform):
//   origin = the flock's centre (x, height, z);
//   column 0 = (radius, angular speed in rad/s (its sign the direction), phase);
//   column 1 = (bob, wander radius, wander rate in rad/s);
//   column 2 = (ellipse ratio z/x, ellipse angle, tumble depth in m);
//   custom = (flapping share of the time 0-1, flap-glide cycle in s, phase in frames, rate);
//   colour's alpha = the body's shade (each bird a little lighter or darker; the rgb stays 1: Godot multiplies the
//   instance colour into the vertex colour, the stand-in's own near-black, which body_color replaces).
// world/birds.gd `pos_at` is this file's `flight` in GDScript (the calls come from the bird itself): keep them alike.
shader_type spatial;
render_mode cull_disabled, skip_vertex_transform;

global uniform float g_time;
uniform sampler2D vat : filter_nearest, repeat_disable;
uniform float vat_fps = 30.0;
uniform float normal_row = 36.0;
uniform vec2 flap_clip = vec2(0.0, 18.0);  // first row, frames
uniform vec2 glide_clip = vec2(18.0, 18.0);
uniform float size = 1.0;  // the stand-in is 3.3 m across the wings
uniform float floor_clear = 18.0;  // metres over the ground no bird of the kind goes below
uniform vec3 body_color : source_color = vec3(0.09, 0.086, 0.1);
uniform vec3 shade_color : source_color = vec3(0.36, 0.44, 0.70);
uniform float soft = 0.1;
uniform float rim = 0.12;

#include "res://shaders/inc/light_stylized.gdshaderinc"
#include "res://shaders/inc/vat.gdshaderinc"
#include "res://shaders/inc/horizon.gdshaderinc"

varying vec3 wpos;
varying vec3 tint;

// The ground's height under a world position, from the horizon map (world/horizon.gd `ground_at`); far below where
// there is no map.
float hz_ground(vec3 pos) {
	vec3 p = pos + g_horizon_place.xyz;
	vec2 xy = vec2(p.x, -p.z);
	vec2 uv;
	if (hz_inside(xy, g_horizon_core_rect, uv)) {
		return texture(g_horizon_core, vec3(uv, HZ_GROUND_FULL)).r - g_horizon_place.y;
	} else if (hz_inside(xy, g_horizon_valley_rect, uv)) {
		return texture(g_horizon_valley, vec3(uv, HZ_GROUND_FULL)).r - g_horizon_place.y;
	} else if (hz_inside(xy, g_horizon_ring_rect, uv)) {
		return texture(g_horizon_ring, vec3(uv, 8.0)).r - g_horizon_place.y;
	}
	return -1e6;
}

vec3 flight(float t, vec3 centre, vec3 c0, vec3 c1, vec3 c2) {
	float ang = t * c0.y + c0.z;
	float wp = c1.z * t + centre.x * 0.013 + centre.z * 0.007;  // the flock's own wander: every bird of it alike
	vec3 c = centre + vec3(cos(wp), 0.0, sin(wp * 0.7 + 1.3)) * c1.y;
	float ex = cos(ang) * c0.x;
	float ez = sin(ang) * c0.x * c2.x;
	float ca = cos(c2.y);
	float sa = sin(c2.y);
	float dive = c2.z * pow(max(0.0, sin(t * 0.37 + c0.z * 5.0)), 24.0);
	vec3 q = c + vec3(ex * ca - ez * sa, sin(ang * 2.0 + c0.z) * c1.x - dive, ex * sa + ez * ca);
	float lo = hz_ground(q) + floor_clear;
	float k = 10.0;  // a soft floor: the bird rises over the ground's rise, no kink in its path
	float hh = max(k - abs(q.y - lo), 0.0) / k;
	q.y = max(q.y, lo) + hh * hh * k * 0.25;
	return q;
}

void vertex() {
	vec3 centre = MODEL_MATRIX[3].xyz;
	vec3 c0 = MODEL_MATRIX[0].xyz;
	vec3 c1 = MODEL_MATRIX[1].xyz;
	vec3 c2 = MODEL_MATRIX[2].xyz;
	float h = 0.12;
	vec3 a = flight(g_time - h, centre, c0, c1, c2);
	vec3 b = flight(g_time, centre, c0, c1, c2);
	vec3 d = flight(g_time + h, centre, c0, c1, c2);
	vec3 v = (d - a) / (2.0 * h);
	vec3 f = normalize(v + vec3(0.0, 0.0, 1e-4));
	vec3 r = normalize(cross(vec3(0.0, 1.0, 0.0), f));
	vec3 u = cross(f, r);
	float lat = dot((d - 2.0 * b + a) / (h * h), r);  // the turn's pull: a coordinated bank, tan(roll) = a / g
	float roll = clamp(atan(lat / 9.8), -0.9, 0.9);
	vec3 r2 = r * cos(roll) - u * sin(roll);
	vec3 u2 = u * cos(roll) + r * sin(roll);
	mat3 rot = mat3(r2, u2, f);
	bool diving = v.y < -3.0;
	bool flapping = !diving && fract(g_time / max(INSTANCE_CUSTOM.y, 0.1) + c0.z * 0.37) < INSTANCE_CUSTOM.x;
	vec2 clip = flapping ? flap_clip : glide_clip;
	vec3 p;
	vec3 n;
	vat_pose(vat, UV2.x, vec4(clip, INSTANCE_CUSTOM.z, INSTANCE_CUSTOM.w), g_time, vat_fps, normal_row, p, n);
	wpos = b + rot * (p * size);
	tint = body_color * COLOR.a;
	VERTEX = (VIEW_MATRIX * vec4(wpos, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(rot * n, 0.0)).xyz);
}

void fragment() {
	ALBEDO = tint;
	ROUGHNESS = 3.5 / 16.0;
	SPECULAR = 0.0;
}

void light() {
	vec3 d = vec3(0.0);
	vec3 s = vec3(0.0);
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);  // art step A8: the terrain's shadow
	stylized_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, shade_color, soft, rim, 0.0, d, s);
	DIFFUSE_LIGHT += d * ridge;
	SPECULAR_LIGHT += s * ridge;
}
