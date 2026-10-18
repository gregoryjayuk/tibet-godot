// The ridge shadow (plan chapter 09, 10.2; chapter 11, 6.3; art step A8). A shadow map reaches 120-160 m; the western
// ridge that takes the town's sun at 16:10 is 4 km away. tools/terrain/horizon.py bakes the terrain's horizon over
// three grids (the core at 4 m, the valley map at 16 m, the ring to 15 km at 128 m): in 32 azimuth sectors, the
// tangent of the horizon's elevation seen from eyes 1, 4, 10, 20 and 40 m above the ground (the ring, bare terrain,
// keeps only the 1 m eye). world/horizon.gd loads the map into these globals. A fragment reads the two sectors either
// side of its light's azimuth (the sun, or the moon after dusk: the light's own direction), the chord between the two
// eyes either side of its own height above the ground, and loses the directional light where the light is below the
// horizon, through an edge of 0.05 deg: 3 m on a wall 3.5 km from the ridge, the drawn line that climbs the town roof
// by roof (chapter 09, 10.2). Until the map is loaded the rectangles are zero and every surface is lit as before, so
// the draft's reference shots do not move.

global uniform sampler2DArray g_horizon_core : filter_linear, repeat_disable;
global uniform sampler2DArray g_horizon_valley : filter_linear, repeat_disable;
global uniform sampler2DArray g_horizon_ring : filter_linear, repeat_disable;
global uniform sampler2DArray g_horizon_fine : filter_linear, repeat_disable;  // the confluence at 2 m and 256 sectors (M2 sprint 5)
global uniform vec4 g_horizon_core_rect;  // the grid's west edge x and north edge y in the design's frame, its width and height, metres
global uniform vec4 g_horizon_valley_rect;
global uniform vec4 g_horizon_ring_rect;
global uniform vec4 g_horizon_fine_rect;
global uniform vec4 g_horizon_place;  // xyz: added to a world position to reach the map's frame; w = 1: the scene's own ground is y = 0 (the draft street)

const float HZ_EDGE = 0.025;  // degrees either side of the horizon
const int HZ_SECTORS = 32;  // the core's, the valley's and the ring's sectors (11.25 degrees each)
const int HZ_FINE_SECTORS = 256;  // the fine grid's over the confluence, where the first sun comes up a narrow slot
const float HZ_EYES[5] = {1.0, 4.0, 10.0, 20.0, 40.0};
const float HZ_GROUND_FULL = 40.0;  // the ground's layer in a grid with five eyes; 8 in the ring's

float hz_channel(vec4 v, int c) {
	return c == 0 ? v.r : (c == 1 ? v.g : (c == 2 ? v.b : v.a));
}

// The horizon's tangent in sector s, on the chord between eye i and eye i + 1 (f along it); `knots` false for the ring;
// `groups` the grid's layers an eye (its sectors / 4).
float hz_sector(sampler2DArray t, vec2 uv, int s, int i, float f, bool knots, int groups) {
	int g = s / 4;
	int c = s - g * 4;
	float a = hz_channel(texture(t, vec3(uv, float(i * groups + g))), c);
	if (!knots) {
		return a;
	}
	float b = hz_channel(texture(t, vec3(uv, float((i + 1) * groups + g))), c);
	return mix(a, b, f);
}

// The horizon's elevation, degrees, at uv of one grid of `sectors` sectors, towards azimuth az, for a point `above`
// metres over the ground (read from the map's own ground where above < -100).
float hz_grid(sampler2DArray t, vec2 uv, float az, float above_in, float y, bool knots, int sectors) {
	int groups = sectors / 4;
	float above = above_in;
	if (above < -100.0) {
		above = y - texture(t, vec3(uv, float(knots ? groups * 5 : groups))).r;
	}
	int i = above < HZ_EYES[1] ? 0 : (above < HZ_EYES[2] ? 1 : (above < HZ_EYES[3] ? 2 : 3));
	float f = (clamp(above, -2.0, 80.0) - HZ_EYES[i]) / (HZ_EYES[i + 1] - HZ_EYES[i]);
	float fs = az / (360.0 / float(sectors));
	int s0 = int(floor(fs)) % sectors;
	int s1 = (s0 + 1) % sectors;
	float tan_h = mix(hz_sector(t, uv, s0, i, f, knots, groups), hz_sector(t, uv, s1, i, f, knots, groups), fract(fs));
	return degrees(atan(tan_h));
}

bool hz_inside(vec2 xy, vec4 rect, out vec2 uv) {
	uv = vec2((xy.x - rect.x) / rect.z, (rect.y - xy.y) / rect.w);
	return rect.z > 0.0 && uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;
}

// 1 where the light at world direction `to_light` clears the terrain's horizon at world position `pos`, 0 where a
// ridge hides it. `above`: the point's height over the ground if the caller knows it (the terrain passes 0), else
// anything below -100 to read it from the map.
float horizon_light(vec3 pos, vec3 to_light, float above_in) {
	if (g_horizon_ring_rect.z <= 0.0) {
		return 1.0;
	}
	vec3 p = pos + g_horizon_place.xyz;
	vec2 xy = vec2(p.x, -p.z);  // Godot -Z is the design's north
	float above = above_in;
	if (g_horizon_place.w > 0.5 && above < -100.0) {
		above = pos.y;
	}
	vec3 l = normalize(to_light);
	float alt = degrees(asin(clamp(l.y, -1.0, 1.0)));
	float az = mod(degrees(atan(l.x, -l.z)), 360.0);
	vec2 uv;
	float h;
	if (hz_inside(xy, g_horizon_fine_rect, uv)) {
		h = hz_grid(g_horizon_fine, uv, az, above, p.y, true, HZ_FINE_SECTORS);
	} else if (hz_inside(xy, g_horizon_core_rect, uv)) {
		h = hz_grid(g_horizon_core, uv, az, above, p.y, true, HZ_SECTORS);
	} else if (hz_inside(xy, g_horizon_valley_rect, uv)) {
		h = hz_grid(g_horizon_valley, uv, az, above, p.y, true, HZ_SECTORS);
	} else if (hz_inside(xy, g_horizon_ring_rect, uv)) {
		h = hz_grid(g_horizon_ring, uv, az, above, p.y, false, HZ_SECTORS);
	} else {
		return 1.0;
	}
	return smoothstep(h - HZ_EDGE, h + HZ_EDGE, alt);
}

// The same for a light() function: 1 for lights that are not directional; the view-space LIGHT turned into the world.
float horizon_light_view(vec3 pos, vec3 light_view, mat4 inv_view, bool directional, float above) {
	return directional ? horizon_light(pos, (inv_view * vec4(light_view, 0.0)).xyz, above) : 1.0;
}

// light_reach (ISS-164), for the light() functions that do not call stylized_light
#include "res://shaders/inc/light_reach.gdshaderinc"
