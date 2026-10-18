// The rivers' water (M2 sprint 5, step 2; plan chapter 02, 2.2; chapter 08, V-02; chapter 09's flat light): ribbons laid
// along each river's line by world/rivers.gd. UV.x runs across from the left bank (0) to the right (1) looking
// downstream, UV.y metres along the water's surface downstream (so a fall gets its height's worth). CUSTOM0: x the water
// (0 the Dungchu, 1 the Serchu, 2 the slot's two side by side, 3 the Yalong), y the slope (its drop a metre along), z the
// metres below the confluence (the slot's), w the flow's speed in metres a second. Opaque: milky glacier water, clear
// amber over golden gravel (drawn, not seen through), green-grey; lighter streaks moving downstream, foam on the
// rapids and the falls and along the banks, a soft sky at grazing angles, the sun's glint in the stylised light's band.
shader_type spatial;
render_mode cull_disabled;

uniform vec3 dungchu : source_color = vec3(0.624, 0.706, 0.737);  // #9FB4BC, glacier-milky (chapter 02, 2.2)
// the Serchu deeper than chapter 08's swatches (#B89A5A over #C9A24E), which match the valley's sand: drawn so the clear
// water tells from the dry gravel round it (docs/DECISIONS.md, 9 Oct 2026)
uniform vec3 serchu : source_color = vec3(0.58, 0.455, 0.235);  // #94743C, clear amber
uniform vec3 gravel : source_color = vec3(0.69, 0.54, 0.245);  // #B08A3E, the golden gravel under it
uniform vec3 yalong : source_color = vec3(0.373, 0.498, 0.478);  // #5F7F7A, green-grey
uniform vec3 foam_col : source_color = vec3(0.93, 0.94, 0.92);
uniform float mix_m = 100.0;  // metres below the confluence over which the two waters run side by side
uniform float fall_at = -1.0;  // metres below the confluence of the Conch Fall's foot on the slot (data/rivers.json), -1 none
uniform vec3 shade_color : source_color = vec3(0.36, 0.44, 0.70);
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
global uniform float g_time;
global uniform vec3 g_sky_fill;

#include "res://shaders/inc/light_stylized.gdshaderinc"
#include "res://shaders/inc/horizon.gdshaderinc"

varying vec4 c0;
varying vec3 wpos;
varying float soft_v;
varying float rim_v;
varying float gloss_v;

void vertex() {
	c0 = CUSTOM0;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float n2(vec2 p) {
	return texture(noise_tex, p).r;
}

void fragment() {
	float water = c0.x;
	float slope = c0.y;
	float from_c = c0.z;
	float speed = c0.w;
	float along = UV.y;
	float across = UV.x;
	// the water's own colour
	vec3 col;
	float clear = 0.0;  // how much of the water is the Serchu's clear amber: the sky lies on it and its middle is deeper
	if (water < 0.5) {
		col = dungchu;
	} else if (water < 1.5) {  // amber over gravel: the stones show through the shallows as a dappled warmth
		float st = n2(vec2(wpos.x, wpos.z) * 0.35);
		col = mix(serchu, gravel, 0.35 + 0.4 * smoothstep(0.45, 0.75, st));
		clear = 1.0;
	} else if (water < 2.5) {  // the slot: the Serchu along its left bank, the Dungchu along its right, a seam between
		// wandering in the current, one water by mix_m metres below the confluence
		float sep = 1.0 - smoothstep(0.35 * mix_m, mix_m, from_c);
		float seam = 0.5 + 0.12 * (n2(vec2(along * 0.02 - g_time * 0.01, 0.37)) - 0.5) * 2.0;
		float w = mix(0.5, 0.035, sep);
		float k = smoothstep(seam - w, seam + w, across);
		vec3 amber = mix(serchu, gravel, 0.3);
		col = mix(amber, dungchu, k);
		col = mix(col, mix(amber, dungchu, 0.62), 1.0 - sep);  // below, one milky-amber water
		col += vec3(0.05) * sep * (1.0 - smoothstep(0.0, 0.05, abs(across - seam)));  // the seam catching the light
		clear = (1.0 - k) * sep;
	} else {
		col = yalong;
	}
	// the current: long lighter streaks moving downstream, faster on the steeper water
	float t = g_time * speed;
	float streak = n2(vec2(across * 2.2 + 0.13 * sin(along * 0.07), (along - t) * 0.045));
	streak = smoothstep(0.62, 0.78, streak);
	col = mix(col, col * 1.12 + vec3(0.04), streak * 0.55);
	// foam: on the rapids (by the slope), the falls (white), and a frill along the banks
	float rough = n2(vec2(across * 3.0, (along - t * 1.3) * 0.18)) * 0.6 + n2(vec2(wpos.x, wpos.z) * 0.6 + vec2(0.0, -t * 0.2)) * 0.4;
	float rapids = smoothstep(0.08, 0.3, slope);
	// the fall's sheet: white, long falling streaks letting the water's colour through between them
	float sheet = n2(vec2(across * 7.0 + 0.4 * sin(along * 0.5), (along - t * 1.2) * 0.08));
	float fall = smoothstep(0.8, 2.0, slope) * (0.5 + 0.5 * smoothstep(0.38, 0.62, sheet));
	float bank = 1.0 - smoothstep(0.0, 0.06 + 0.04 * rough, min(across, 1.0 - across));
	// the pool of foam at the fall's foot, churning, breaking into patches over a dozen metres down the slot
	float below = from_c - fall_at;
	float pool = (fall_at > 0.0 && water > 1.5 && water < 2.5) ? step(-0.5, below) * (1.0 - smoothstep(1.0, 14.0, below)) : 0.0;
	float churn = n2(vec2(across * 2.5 + 0.3 * sin(g_time * 0.9 + along), (along - t * 0.6) * 0.3)) * 0.7 + rough * 0.3;
	float foam = clamp(rapids * smoothstep(0.66 - 0.12 * rapids, 0.82, rough) * 0.85 + fall + bank * smoothstep(0.4, 0.65, rough) * 0.7
			+ pool * smoothstep(0.58 - 0.22 * pool, 0.74, churn), 0.0, 1.0);
	col = mix(col, foam_col, foam);
	// the clear water deeper in its middle, the gravel darker under it
	col *= 1.0 - 0.22 * clear * (1.0 - abs(across * 2.0 - 1.0)) * (1.0 - foam);
	// a soft sky at grazing angles, most on the clear water: what tells it from the sand at a distance
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), mix(3.0, 2.0, clear));
	col = mix(col, g_sky_fill * 1.1 + col * 0.2, fres * mix(0.45, 0.85, clear) * (1.0 - foam));
	ALBEDO = col;
	ROUGHNESS = 0.6;
	SPECULAR = 0.0;
	soft_v = 0.35;
	rim_v = 0.0;
	gloss_v = 0.55 * (1.0 - foam);
}

void light() {
	vec3 d = vec3(0.0);
	vec3 s = vec3(0.0);
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);
	stylized_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, shade_color, soft_v, rim_v, gloss_v, d, s);
	DIFFUSE_LIGHT += d * ridge;
	SPECULAR_LIGHT += s * ridge;
}
