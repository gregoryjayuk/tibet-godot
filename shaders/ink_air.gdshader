// The ink pass (plan chapter 09, 8.2, 9.4 and 11.3; art step A5). One full-screen quad, one screen read: ink lines,
// distance painted in bands of hue, paper grain and a vignette. M1's look uses it; the draft keeps outline.gdshader,
// so the draft's reference shots stay its own.
// Lines: a nearer neighbour draws a silhouette on the farther pixel (full strength; wider against the sky); a crease
// in the normals draws an interior line (0.6); a change of line group draws a material line (0.4). Every surface
// shader writes its line group into ROUGHNESS at the bin centre (group + 0.5) / 16: 0 none (grass, flags, smoke,
// water, particles, clouds), 1 architecture, 2 terrain (creases only, beyond 25 m), 3 characters, 4 foliage
// (silhouettes only, at half strength), 5 gold, 6 interiors. The ink is the surface's own colour darkened and pulled
// towards lac or indigo, never darker than lamp black; lines thin with distance to a hairline at 35 % by 400 m and
// fade into the fog the Environment paints.
// The valley's mist (chapter 09, 9.3; IMP-021, Greg's inspiration of 7 Oct 2026): a layer under a lobed top at any
// distance, where the froxel fog cannot reach (60-90 m), from the depth of each pixel: lit gold where the sun reaches
// its top and blue in the ridges' shadow (the horizon map), lines and colour sinking into it with the depth of the
// pixel under its top. And the low sun's rays (1780): the sky's light streaked from the sun's place on the screen
// across whatever stands against it, in the haze. Both from world/day.gd; none in the draft street.
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float enabled = 1.0;  // the lines (O toggles them)
uniform float weight = 1.0;  // photo mode's ink weight, 0-1.5
uniform float air = 1.0;  // the depth colour ramp, grain and vignette; 0 for comparisons
uniform float fog_density = 0.00028;  // the Environment's depth fog density, so lines fade into the air it paints
uniform float mist_top = -10000.0;  // world y of the valley mist's top, its lobes about it (world/day.gd); far below: none
uniform float mist_density = 0.0;  // per metre in it
uniform float rays = 0.0;  // the low sun's rays, 0-1 (world/day.gd)

global uniform vec3 g_sky_fill;
global uniform float g_game_minute;
#include "res://shaders/inc/horizon.gdshaderinc"

global uniform vec3 g_lac_tint;
global uniform vec3 g_indigo_tint;
global uniform vec3 g_shade_tint;
global uniform vec3 g_sun_col;
global uniform vec3 g_sun_dir;

const vec3 LAMP_BLACK = vec3(0.0103, 0.0086, 0.0075);  // #1A1715
const vec3 MID_OCHRE = vec3(0.4793, 0.3916, 0.2542);  // #B8A88A, the middle band's warm grey-ochre (day)
const vec3 FAR_TINT = vec3(0.3036, 0.5157, 0.5297);  // P06 #9CCB98 and P02 #8FB0E0 mixed half and half, linear
const float SKY_DEPTH = 15000.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float lin_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	v.xyz /= v.w;
	return -v.z;
}

int group_of(float roughness) {
	return int(floor(clamp(roughness, 0.0, 0.999) * 16.0));
}

float luma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

// The line's colour: the surface darkened, reds and ochres pulled towards lac, blues and greens towards indigo
// (chapter 09, 8.2 step 3): a white wall draws a warm grey line, a red wall maroon, gold bronze.
vec3 ink_of(vec3 c) {
	vec3 hsv = rgb2hsv(c);
	vec3 dark = c * 0.3;
	float l = luma(dark);
	vec3 shifted = dark;
	if (hsv.y > 0.25) {
		if (hsv.x < 0.14 || hsv.x > 0.9) {
			shifted = mix(dark, g_lac_tint * l / max(luma(g_lac_tint), 1e-3), 0.6);
		} else if (hsv.x > 0.2 && hsv.x < 0.75) {
			shifted = mix(dark, g_indigo_tint * l / max(luma(g_indigo_tint), 1e-3), 0.6);
		}
	}
	return max(mix(c * 0.38, shifted, 0.5), LAMP_BLACK);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// The mist's top over (x, z): its height and two scales of lobes, drifting with the day's minutes.
float mist_height(vec2 xz) {
	vec2 drift = vec2(g_game_minute * 0.5, g_game_minute * 0.2);
	return mist_top + (vnoise((xz + drift * 0.3) / 520.0) - 0.5) * 60.0 + (vnoise((xz + drift) / 140.0) - 0.5) * 34.0
			+ (vnoise((xz - drift * 1.7) / 38.0) - 0.5) * 10.0;
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	vec3 col = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	float d0 = lin_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	// The mist: how far the ray from the eye to this pixel runs under the mist's top.
	float mist_a = 0.0;
	vec3 mist_c = vec3(0.0);
	if (mist_density > 0.0) {
		vec4 vp = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, texture(depth_tex, SCREEN_UV).r, 1.0);
		vp.xyz /= vp.w;
		vec3 eye = CAMERA_POSITION_WORLD;
		vec3 dir = normalize((INV_VIEW_MATRIX * vec4(vp.xyz, 0.0)).xyz);
		float len = d0 > SKY_DEPTH ? 20000.0 : length(vp.xyz);
		float h0 = mist_height(eye.xz);
		float depth_od = 0.0;  // the ray's optical depth under the top: thin at the top, full 25 m below it
		vec3 top_pt = eye;
		vec3 n_top = vec3(0.0, 1.0, 0.0);
		if (dir.y < -1e-4 && eye.y > h0) {
			// march the lobed top between the heights of its highest and lowest lobes, then close in on the crossing,
			// so a near crest hides the far sea and the top has its relief
			float t0 = max((eye.y - (mist_top + 55.0)) / -dir.y, 0.0);
			float t1 = min((eye.y - (mist_top - 55.0)) / -dir.y, len);
			float t_hit = -1.0;
			float tp = t0;
			for (int i = 1; i <= 12; i++) {
				float t = mix(t0, t1, float(i) / 12.0);
				vec3 q = eye + dir * t;
				if (q.y < mist_height(q.xz)) {
					float a = tp;
					float b = t;
					for (int j = 0; j < 4; j++) {
						float m = 0.5 * (a + b);
						vec3 qm = eye + dir * m;
						if (qm.y < mist_height(qm.xz)) {
							b = m;
						} else {
							a = m;
						}
					}
					t_hit = b;
					break;
				}
				tp = t;
			}
			if (t_hit >= 0.0) {
				top_pt = eye + dir * t_hit;
				float e = 12.0;
				n_top = normalize(vec3(mist_height(top_pt.xz - vec2(e, 0.0)) - mist_height(top_pt.xz + vec2(e, 0.0)), 2.0 * e,
						mist_height(top_pt.xz - vec2(0.0, e)) - mist_height(top_pt.xz + vec2(0.0, e))));
				float l_in = max(len - t_hit, 0.0);
				float l_full = 25.0 / -dir.y;  // how far along the ray the mist reaches its full density
				depth_od = l_in <= l_full ? l_in * l_in / (2.0 * l_full) : l_in - l_full * 0.5;
				depth_od *= 0.55 + 0.9 * vnoise(top_pt.xz / 300.0 + vec2(7.3, 1.9));  // thicker and thinner by patches
			}
		} else if (eye.y < h0) {  // in the mist: full round the eye, a horizon of white
			depth_od = dir.y > 1e-4 ? min(len, (h0 - eye.y) / dir.y) : len;
			depth_od *= clamp((h0 - eye.y) / 25.0, 0.25, 1.0);
		}
		mist_a = 1.0 - exp(-mist_density * depth_od);
		// lit gold where the sun clears the ridges at its top, blue in their shadow (and the moon's after dusk); each lobe
		// lit on its flank to the sun and shaded on the other, as a thangka's mist is
		float lit = horizon_light(top_pt, g_sun_dir, 2.0);
		float ndl = clamp(dot(n_top, g_sun_dir), 0.0, 1.0);
		mist_c = (g_sky_fill * (0.85 + 0.35 * n_top.y) + g_sun_col * lit * (0.2 + 0.85 * ndl)) * 0.9;
	}
	mist_c = max(mist_c, vec3(0.0));
	vec4 nr0 = texture(normal_tex, SCREEN_UV);
	vec3 n0 = nr0.xyz * 2.0 - 1.0;
	int g0 = group_of(nr0.w);
	bool sky0 = d0 > SKY_DEPTH;
	// 1. Width by depth: 1.6 px under 10 m, 1.2 px at 30 m, 1.0 px from 60 m on.
	float w = mix(1.6, 1.2, smoothstep(10.0, 30.0, d0));
	w = mix(w, 1.0, smoothstep(30.0, 60.0, d0));
	// 6. Stability: the thresholds rise with distance, so grazing ground does not fizz.
	float far_t = clamp(d0 / 300.0, 0.0, 1.0);
	float dth = mix(0.03, 0.06, far_t);
	vec2 nth = mix(vec2(0.35, 0.6), vec2(0.5, 0.75), far_t);
	float sil = 0.0;
	float inner = 0.0;
	float near_d = d0;
	vec2 near_uv = SCREEN_UV;
	vec2 offs[4] = vec2[](vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0));
	for (int i = 0; i < 4; i++) {
		// 2. Against the sky a silhouette is 1.2 times as wide, so buildings stand out on the skyline.
		vec2 uv = SCREEN_UV + offs[i] * px * w * (sky0 ? 1.2 : 1.0);
		float d = lin_depth(uv, INV_PROJECTION_MATRIX);
		vec4 nr = texture(normal_tex, uv);
		int g = group_of(nr.w);
		float jump = (d0 - d) / max(d0, 0.001);
		if (jump > dth * 0.5) {
			// A silhouette of the nearer surface, drawn on this farther pixel, if the nearer surface draws lines.
			if (g != 0) {
				float s = smoothstep(dth, dth * 3.0, jump) * (g == 4 ? 0.5 : 1.0);
				if (s > sil) {
					sil = s;
					near_d = d;
					near_uv = uv;
				}
			}
		} else if (abs(jump) < dth && !sky0 && g0 != 0 && g != 0) {
			// The same surface continues: creases (0.6) and changes of line group (0.4).
			bool crease_ok = g0 != 4 && g != 4 && (g0 != 2 || d0 > 25.0);
			if (crease_ok) {
				vec3 n = nr.xyz * 2.0 - 1.0;
				inner = max(inner, smoothstep(nth.x, nth.y, 1.0 - dot(n, n0)) * 0.6);
			}
			if (g != g0 && g0 != 2 && g != 2 && g0 != 4 && g != 4) {
				inner = max(inner, 0.4);
			}
		}
	}
	float line = max(sil, inner);
	// The line lives at the depth of the surface that draws it: the nearer one for a silhouette.
	float ld = sil >= inner ? near_d : d0;
	line *= mix(1.0, 0.35, smoothstep(60.0, 400.0, ld)) * (1.0 - smoothstep(400.0, 700.0, ld));
	line *= exp(-fog_density * ld);  // 5. lines fade into the air the fog paints
	line *= 1.0 - mist_a;  // and into the mist
	vec3 src = sil >= inner ? textureLod(screen_tex, near_uv, 0.0).rgb : col;
	col = mix(col, ink_of(src), clamp(line * weight * enabled, 0.0, 1.0));
	col = mix(col, mist_c, mist_a);
	// The low sun's rays: the share of the sky behind each step towards the sun's place on the screen.
	if (rays > 0.0) {
		vec4 sp = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(CAMERA_POSITION_WORLD + g_sun_dir * 5000.0, 1.0));
		vec2 suv = (sp.xy / max(sp.w, 1e-4)) * 0.5 + 0.5;
		// the rays stream where the sun is partly hidden, behind a ridge's edge: with the sun in open sky they would only
		// wash the frame, as the first stills of 7 Oct 2026 showed
		float hidden = 0.0;
		for (int k = 0; k < 6; k++) {
			float a = float(k) * 1.0472;
			vec2 q = suv + vec2(cos(a), sin(a)) * vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0) * 0.02;
			hidden += (q.x >= 0.0 && q.x <= 1.0 && q.y >= 0.0 && q.y <= 1.0 && lin_depth(q, INV_PROJECTION_MATRIX) < SKY_DEPTH) ? 1.0 / 6.0 : 0.0;
		}
		float streaming = max(smoothstep(0.1, 0.5, hidden), 0.35);
		if (sp.w > 0.0 && streaming > 0.0) {
			vec2 to_sun = suv - SCREEN_UV;
			float dist = length(to_sun * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0));
			if (dist < 1.3) {
				float jitter = hash(FRAGCOORD.xy) * 0.9;
				float acc = 0.0;
				float norm = 0.0;
				float decay = 1.0;
				for (int i = 0; i < 20; i++) {
					vec2 uv = SCREEN_UV + to_sun * ((float(i) + jitter) / 20.0);
					float in_frame = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
					// the sky's own light, so clouds against the sun cut it into streaks as ridges and roofs do
					float sky_l = step(SKY_DEPTH, lin_depth(uv, INV_PROJECTION_MATRIX)) * smoothstep(0.5, 1.3, luma(textureLod(screen_tex, uv, 0.0).rgb) / max(luma(g_sun_col), 0.2));
					acc += in_frame * sky_l * decay;
					norm += decay;
					decay *= 0.93;
				}
				float shafts = pow(acc / max(norm, 1e-3), 1.5);
				float haze = 0.35 + 0.65 * mist_a;  // the rays show in the air, most in the mist
				col += g_sun_col * shafts * rays * streaming * haze * (1.0 - smoothstep(0.0, 1.3, dist)) * 0.6 * (sky0 && mist_a <= 0.0 ? 0.6 : 1.0);
			}
		}
	}
	if (air > 0.5) {
		// Daylight from the key light's strength: after dusk g_sun_dir is the moon's, so its height would say "day".
		float day = smoothstep(0.12, 0.6, luma(g_sun_col));
		if (!sky0) {
			// 9.4: distance in bands of hue. Near (to 120 m) as painted; middle (120-700 m) 12 % towards warm grey-ochre,
			// contrast and saturation 85 %; far (0.7-5 km) 25 % towards malachite-grey, contrast 65 %, saturation 70 %.
			float t_mid = smoothstep(90.0, 150.0, d0);
			float t_far = smoothstep(600.0, 800.0, d0);
			float shift = mix(0.12 * t_mid, 0.25, t_far);
			float contrast = mix(mix(1.0, 0.85, t_mid), 0.65, t_far);
			float sat = mix(mix(1.0, 0.85, t_mid), 0.70, t_far);
			vec3 target = mix(MID_OCHRE, FAR_TINT, t_far) * clamp(luma(g_sun_col) * 0.5, 0.05, 1.0);
			// Contrast is compressed towards the band's own colour, which dims with the light: a fixed mid-grey pivot
			// lifted the whole distance towards grey at night (the far hill glowed at 20:30).
			float l = luma(col);
			float pivot = luma(target);
			float l2 = pivot + (l - pivot) * contrast;
			col *= l2 / max(l, 1e-4);
			col = mix(vec3(l2), col, sat);
			col = mix(col, target, shift);
		}
		// 11.1's night grade: desaturate to 0.6 except the warm hues of lamplight (20-50 deg), and roll the highlights off,
		// so moonlit whitewash and fresh lime read pale grey-blue, not paper white (Greg, after walking the day).
		float night = 1.0 - day;
		if (night > 0.0) {
			vec3 hsv = rgb2hsv(col);
			float warm = smoothstep(0.045, 0.065, hsv.x) * (1.0 - smoothstep(0.13, 0.15, hsv.x));
			float l = luma(col);
			col = mix(col, mix(vec3(l), col, 0.6), night * (1.0 - warm));
			col *= mix(1.0, 1.0 - 0.45 * smoothstep(0.15, 0.9, luma(col)), night * (1.0 - warm));
		}
		// 11.3: paper grain, +-1.5 % in value, fibres running across the sheet.
		vec2 fp = FRAGCOORD.xy;
		float grain = vnoise(fp * vec2(0.35, 1.3)) * 0.6 + hash(fp) * 0.4;
		col *= 1.0 + (grain - 0.5) * 0.03;
		// 11.3: an elliptical vignette, 12 % at the corners by day and 20 % at night, towards the shade tint, not black.
		float r = length((SCREEN_UV - 0.5) * 2.0) * 0.7071;
		float amount = smoothstep(0.45, 1.0, r) * mix(0.20, 0.12, day);
		vec3 tint = g_shade_tint / max(luma(g_shade_tint), 1e-3);
		col *= (1.0 - amount) * mix(vec3(1.0), tint, clamp(amount * 2.5, 0.0, 1.0) * 0.5);
		// PC-06, no pure black anywhere (chapter 09, 17): the darkest a lamp black of the shade's tint, about 4/255, so a
		// black-painted crown or a dark chuba in the evening's shade is not a hole in the frame (sprint 8, step 8)
		col = max(col, tint * 0.005);
	}
	ALBEDO = col;
}
