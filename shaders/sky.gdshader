// Painted sky: deep high-altitude blue, pale horizon, soft sun glow, slowly drifting stylized clouds.
shader_type sky;

global uniform float g_time; // animation time, set by the game each frame and frozen in screenshot mode (plan chapter 11, 7.3)

uniform vec3 zenith : source_color = vec3(0.12, 0.33, 0.78);
uniform vec3 horizon : source_color = vec3(0.70, 0.83, 0.95);
uniform vec3 ground : source_color = vec3(0.55, 0.52, 0.48);
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.99, 0.96);
uniform vec3 cloud_shade : source_color = vec3(0.68, 0.74, 0.86);
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;

// Art step A6, the night (chapter 09, 9.1): on only when the day cycle drives the sky (M1's look; world/day.gd), so the
// draft's sky is unchanged. The stars of the Yale Bright Star Catalogue, turning with the sidereal time; the moon's disc
// where the Calendar puts it, lit on the side that faces the true sun; the Milky Way when the moon is down.
uniform float night_sky = 0.0;
uniform float latitude = 29.973;
uniform sampler2D star_cells : filter_nearest;  // world/stars.gd: 1440 x 720 cells of 0.25 deg, a star each
global uniform float g_lst;  // local sidereal time, degrees
global uniform float g_sun_alt;  // the true sun, degrees
global uniform float g_sun_az;
global uniform vec3 g_moon_dir;
global uniform float g_moon_phase;  // the moon's illuminated fraction

// Right ascension and declination (degrees) of a world direction (east +x, up +y, north -z), at the site's latitude
// and the sidereal time: sin(dec) = d.N cos(lat) + d.U sin(lat); the hour angle from the meridian's equator point.
vec2 equatorial(vec3 d) {
	float phi = radians(latitude);
	float sdec = -d.z * cos(phi) + d.y * sin(phi);
	float hour = atan(-d.x, d.y * cos(phi) + d.z * sin(phi));
	return vec2(mod(g_lst - degrees(hour), 360.0), degrees(asin(clamp(sdec, -1.0, 1.0))));
}

vec3 eq_vec(float ra, float dec) {
	float a = radians(ra);
	float b = radians(dec);
	return vec3(cos(b) * cos(a), cos(b) * sin(a), sin(b));
}

vec3 star_colour(float t) {  // B-V from blue-white through white and yellow to orange
	vec3 c = mix(vec3(0.72, 0.8, 1.0), vec3(1.0, 0.98, 0.94), smoothstep(0.0, 0.3, t));
	return mix(c, vec3(1.0, 0.78, 0.52), smoothstep(0.35, 0.8, t));
}

vec3 stars(vec3 d, float vis) {
	vec2 rd = equatorial(d);
	vec3 v = eq_vec(rd.x, rd.y);
	ivec2 c = ivec2(int(floor(rd.x / 0.25)), int(floor((rd.y + 90.0) / 0.25)));
	vec3 acc = vec3(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			ivec2 k = ivec2((c.x + i + 1440) % 1440, clamp(c.y + j, 0, 719));
			vec4 t = texelFetch(star_cells, k, 0);
			if (t.b <= 0.0) {
				continue;
			}
			float sra = (float(k.x) + t.r) * 0.25;
			float sdec = (float(k.y) + t.g) * 0.25 - 90.0;
			vec3 s = eq_vec(sra, sdec);
			float dist = degrees(sqrt(max(2.0 * (1.0 - dot(v, s)), 0.0)));  // angular distance, degrees
			float sigma = 0.03 + 0.035 * t.b;
			float twinkle = 0.85 + 0.15 * sin(g_time * (3.0 + 5.0 * fract(sra * 7.3)) + sdec * 11.0);
			float i_star = exp(-pow(dist / sigma, 2.0)) * (0.25 + 1.6 * t.b * t.b) * twinkle;
			if (t.b > 0.8) {  // the brightest get a four-point glint
				float dx = abs(mod(rd.x - sra + 180.0, 360.0) - 180.0) * cos(radians(sdec));
				float dy = abs(rd.y - sdec);
				i_star += (exp(-dx / 0.35) * exp(-pow(dy / 0.012, 2.0)) + exp(-dy / 0.35) * exp(-pow(dx / 0.012, 2.0))) * 0.5 * (t.b - 0.8) * 5.0;
			}
			acc += star_colour(t.a) * i_star;
		}
	}
	return acc * vis;
}

float milky_way(vec3 d) {
	vec2 rd = equatorial(d);
	float a = radians(rd.x - 192.85948);
	float dec = radians(rd.y);
	float dg = radians(27.12825);
	float b = degrees(asin(clamp(sin(dec) * sin(dg) + cos(dec) * cos(dg) * cos(a), -1.0, 1.0)));
	float l = 122.93192 - degrees(atan(cos(dec) * sin(a), sin(dec) * cos(dg) - cos(dec) * sin(dg) * cos(a)));
	float lc = mod(l + 180.0, 360.0) - 180.0;  // -180..180, the centre of the galaxy at 0
	float band = exp(-pow(b / 9.0, 2.0)) * (0.5 + 0.5 * exp(-pow(lc / 40.0, 2.0)));
	float clumps = texture(noise_tex, vec2(l / 60.0, b / 25.0)).r * 0.6 + texture(noise_tex, vec2(l / 17.0, b / 7.0)).r * 0.4;
	float rift = 1.0 - 0.6 * exp(-pow(b / 1.8, 2.0)) * smoothstep(-40.0, -10.0, lc) * (1.0 - smoothstep(50.0, 80.0, lc));
	return band * smoothstep(0.25, 0.75, clumps) * rift;
}

vec3 moon_disc(vec3 d, inout float cover) {
	vec3 m = normalize(g_moon_dir);
	float r = radians(0.45);  // about 1.7 times the true 0.26 deg, as painters draw it: the true size is 10 px at 1080p
	float cm = dot(d, m);
	if (cm < cos(r * 1.2) || m.y < -0.02) {
		return vec3(0.0);
	}
	vec3 q = (d - m * cm) / sin(r);
	float qq = dot(q, q);
	float edge = 1.0 - smoothstep(0.92, 1.0, qq);
	vec3 n = q - m * sqrt(max(1.0 - qq, 0.0));  // the sphere's surface facing us
	vec3 sun = vec3(cos(radians(g_sun_alt)) * sin(radians(g_sun_az)), sin(radians(g_sun_alt)), -cos(radians(g_sun_alt)) * cos(radians(g_sun_az)));
	float lit = smoothstep(-0.06, 0.06, dot(n, sun));
	float maria = texture(noise_tex, q.xy * 0.35 + vec2(0.31, 0.17)).r;
	vec3 albedo = vec3(0.93, 0.91, 0.84) * mix(0.72, 1.0, smoothstep(0.35, 0.65, maria));
	cover = edge;
	return albedo * (lit * 1.5 + 0.035) * edge;  // the dark side faintly by earthshine
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col = mix(horizon, zenith, pow(clamp(h, 0.0, 1.0), 0.5));
	if (h < 0.0) {
		col = mix(horizon, ground, clamp(-h * 5.0, 0.0, 1.0));
	}
	float sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
	float sun_up = night_sky > 0.5 ? smoothstep(-3.0, -1.0, g_sun_alt) : 1.0;  // at night LIGHT0 is the moon's light
	col += LIGHT0_COLOR * (pow(sd, 400.0) * 6.0 + pow(sd, 12.0) * 0.18) * sun_up;
	if (night_sky > 0.5 && !AT_CUBEMAP_PASS && h > -0.02) {
		float moon_up = smoothstep(-2.0, 4.0, degrees(asin(clamp(g_moon_dir.y, -1.0, 1.0))));
		float dark = smoothstep(-7.0, -14.0, g_sun_alt);  // stars come out through nautical twilight
		float wash = 1.0 - 0.45 * moon_up * g_moon_phase;  // moonlight hides the faint ones
		float horizon_fade = smoothstep(-0.01, 0.12, h);
		col += stars(d, dark * wash * horizon_fade);
		col += vec3(0.62, 0.67, 0.82) * milky_way(d) * 0.1 * dark * (1.0 - moon_up * smoothstep(0.15, 0.45, g_moon_phase)) * horizon_fade;
		float cover = 0.0;
		vec3 disc = moon_disc(d, cover);
		col = mix(col, disc, cover * moon_up);
		col += vec3(0.75, 0.82, 1.0) * pow(max(dot(d, normalize(g_moon_dir)), 0.0), 60.0) * 0.12 * g_moon_phase * moon_up;
	}
	if (h > 0.0 && !AT_CUBEMAP_PASS) {
		vec2 uv = d.xz / (h + 0.18) * 0.22 + vec2(g_time * 0.0025, g_time * 0.001);
		float c = texture(noise_tex, uv).r * 0.65 + texture(noise_tex, uv * 2.7).r * 0.35;
		float mask = smoothstep(0.5, 0.64, c) * smoothstep(0.02, 0.22, h);
		float top = texture(noise_tex, uv + LIGHT0_DIRECTION.xz * 0.01).r;
		vec3 cc = mix(cloud_shade, cloud_lit, smoothstep(0.45, 0.7, top));
		col = mix(col, cc, mask * 0.95);
	}
	COLOR = col;
}
