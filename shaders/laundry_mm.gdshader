// Washing hung to dry (world/laundry.gd; IMP-023 (1), after Greg's 1775): each piece a hanging cloth, pinned along its
// top to the line (the mesh's vertex colour red, `hang`: 0 there, 1 at the hem), swaying slow and heavy on the wind,
// most at the hem, and pushed aside by the walker who goes through it (g_player, set by player/player.gd): within a
// metre of the walker each part of the cloth swings out of the way, away from the walker's body and a little up, so a
// line of robes parts round the player. Its colour, already its own, is the instance's (INSTANCE_CUSTOM.rgb); its
// pattern in INSTANCE_CUSTOM.a's whole part (0 plain, 1 an apron's stripes, 2 a blanket's bands), its phase in the
// fraction. Backlit cloth glows; the ridge's shadow falls on it (art step A8).
shader_type spatial;
render_mode cull_disabled;

global uniform float g_time;
global uniform vec3 g_player;  // the walker's feet, world space

uniform float wind = 1.0;
uniform float cloth = 1.0;  // 1 for the washing, 0 for its poles and line

#include "res://shaders/inc/horizon.gdshaderinc"

varying float hang;
varying vec3 wpos;
varying vec3 tint;
varying float pat;

const vec3 STRIPES[5] = {vec3(0.170, 0.081, 0.023), vec3(0.672, 0.087, 0.028), vec3(0.022, 0.172, 0.326), vec3(0.784, 0.473, 0.044), vec3(0.039, 0.233, 0.105)};

void vertex() {
	hang = COLOR.r * cloth;
	tint = INSTANCE_CUSTOM.rgb;
	pat = floor(INSTANCE_CUSTOM.a);
	float ph = fract(INSTANCE_CUSTOM.a) * 6.2831;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 face = normalize((MODEL_MATRIX * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
	float t = g_time * 1.3 + ph;
	float gust = 0.55 + 0.45 * sin(g_time * 0.29 + wp.x * 0.06 + ph);
	vec3 d = face * (0.16 * sin(t + wp.x * 0.8 + wp.z * 0.5) + 0.06 * sin(t * 2.4 + wp.y * 3.0)) * hang * hang * wind * gust;
	d += vec3(0.0, 0.015 * sin(t * 1.7), 0.0) * hang;
	// the walker going through: each part of the cloth within a metre of the walker's body swings away from it
	vec3 to = wp - (g_player + vec3(0.0, 0.95, 0.0));
	float dist = length(to.xz);
	float near = (1.0 - smoothstep(0.3, 1.0, dist)) * (1.0 - smoothstep(0.9, 1.5, abs(to.y)));
	vec3 away = vec3(to.x, 0.0, to.z) / max(dist, 0.05);
	d += (away * 0.6 + vec3(0.0, 0.22, 0.0)) * near * hang;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(d, 0.0)).xyz;
	wpos = wp + d;
}

void fragment() {
	vec3 c = tint;
	if (pat > 0.5 && pat < 1.5) {  // an apron's (pangden's) stripes, across
		c = STRIPES[int(mod(floor(UV.y * 14.0), 5.0))];
	} else if (pat > 1.5) {  // a blanket's bands
		c = mix(tint, tint * 0.55, step(0.5, fract(UV.y * 4.0 + 0.25)) * step(0.15, UV.y) * step(UV.y, 0.85));
	}
	c *= 0.93 + 0.12 * hang;
	ALBEDO = c;
	BACKLIGHT = c * 0.25 * cloth;
	ROUGHNESS = 0.5 / 16.0;  // line group 0: no ink lines on cloth (chapter 09, 8.2)
	SPECULAR = 0.0;
}

void light() {
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);
	float ndl = cloth > 0.5 ? abs(dot(NORMAL, LIGHT)) : max(dot(NORMAL, LIGHT), 0.0);
	float lit = smoothstep(0.0, 0.2, ndl) * ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 * light_reach(LIGHT_IS_DIRECTIONAL, ATTENUATION) + 0.65 * lit) / PI * ridge;  // (ISS-164)
}
