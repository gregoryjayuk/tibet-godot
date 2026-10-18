// The valley's ground colour: plan chapter 09 (the `terrain` row of 7; 13.2-13.4) with chapter 02's late-October
// covers (2.4). Grass under 25°, earth 25-40°, rock over 40°; sunny faces tawny with holly-oak scrub, shaded faces
// green-grey with forest (larch gold, birch yellow, a little maple red, spruce and fir dark) below the timber line;
// tawny above 3,600 m, scree above 4,300 m, snow above the snow line on slopes under 45°.
// One function for the Terrain3D shader (terrain.gdshader) and the ring mesh (terrain_far.gdshader), so the two meet
// without a seam. First cut, spike S3; art step A9 remakes it with fields, paths from the flow map and the ramp R6.
// Needs noise_tex, declared by the including shader. Colours are sRGB here; source_color makes them linear.

uniform vec3 c_grass_sun : source_color = vec3(0.71, 0.60, 0.38);
uniform vec3 c_scrub : source_color = vec3(0.243, 0.290, 0.204);  // holly-oak scrub #3E4A34
uniform vec3 c_grass_shade : source_color = vec3(0.55, 0.54, 0.40);
uniform vec3 c_conifer : source_color = vec3(0.19, 0.25, 0.18);
uniform vec3 c_larch : source_color = vec3(0.851, 0.643, 0.227);  // #D9A43A
uniform vec3 c_birch : source_color = vec3(0.890, 0.753, 0.290);  // #E3C04A
uniform vec3 c_maple : source_color = vec3(0.710, 0.216, 0.165);  // #B5372A
uniform vec3 c_earth : source_color = vec3(0.620, 0.525, 0.404);  // #9E8667, palette slot 39
uniform vec3 c_rock : source_color = vec3(0.435, 0.412, 0.380);   // #6F6961, palette slot 65
uniform vec3 c_alpine : source_color = vec3(0.71, 0.57, 0.35);
uniform vec3 c_scree : source_color = vec3(0.557, 0.541, 0.510);  // #8E8A82
uniform vec3 c_snow : source_color = vec3(0.95, 0.96, 0.98);
uniform float snow_line = 4300.0;  // fresh autumn snow (chapter 01, 9.1); the weather brings it lower through g_snow_line
uniform float timber_line = 4100.0;
global uniform float g_snow_line;  // the weather's snow line (world/day.gd; IMP-021): the lower of it and snow_line holds
global uniform float g_snow;  // and how much lies on the town's gentle ground under it, 0 to 1

const float TERRAIN_DATUM = 2662.0;  // Godot y = 0 is 2,662 m (chapter 11, 4.1)

// How much snow lies here (IMP-021, item 4; chapter 01, 9.3: after V-31's snowfall it lies "in the shade above that line
// for several days"): above the snow line on slopes under 45 degrees, the shaded faces holding it 150 m lower and the
// sunny ones losing it 120 m higher; under the line, the weather's cover on the gentle ground in wind-blown patches.
float terrain_snow(vec3 wpos, vec3 n) {
	float elev = wpos.y + TERRAIN_DATUM;
	float slope = degrees(acos(clamp(n.y, 0.0, 1.0)));
	float south = n.z / max(length(n.xz), 1e-4);
	float nb = texture(noise_tex, wpos.xz * 0.0005).r;
	float nm = texture(noise_tex, wpos.xz * 0.0015).r;
	float nf = texture(noise_tex, wpos.xz * 0.03).r;
	float line = min(snow_line, g_snow_line);
	float shade = smoothstep(-0.1, -0.6, south + (nb - 0.5) * 0.5) * smoothstep(8.0, 18.0, slope);
	float sunny = smoothstep(0.2, 0.7, south) * smoothstep(8.0, 20.0, slope);
	float e = elev + (nf - 0.5) * 80.0 + shade * 150.0 - sunny * 120.0;
	float lie = smoothstep(line - 60.0, line + 60.0, e);
	float cover = g_snow * smoothstep(0.3, 0.55, nm * 0.45 + nf * 0.55 + g_snow * 0.3 - sunny * 0.25);
	return max(lie, cover) * (1.0 - smoothstep(40.0, 47.0, slope));
}

vec3 terrain_color(vec3 wpos, vec3 n, float dist) {
	float elev = wpos.y + TERRAIN_DATUM;
	float slope = degrees(acos(clamp(n.y, 0.0, 1.0)));
	float south = n.z / max(length(n.xz), 1e-4);  // +1 on a face turned south (north is -Z), -1 turned north
	float nb = texture(noise_tex, wpos.xz * 0.0005).r;  // broad, about 300 m: bands
	float nm = texture(noise_tex, wpos.xz * 0.0015).r;  // middle, about 110 m: patches of scrub and wood
	float nf = texture(noise_tex, wpos.xz * 0.03).r;    // fine, about 5 m: paint and the mix of trees
	float nd = texture(noise_tex, wpos.xz * 0.23).r;    // near, under a metre: only within 60 m
	float e = elev + (nb - 0.5) * 220.0;
	float s = slope + (nm - 0.5) * 12.0;
	float shaded_face = smoothstep(-0.1, -0.6, south + (nb - 0.5) * 0.5) * smoothstep(8.0, 18.0, slope);
	// Coverage follows the 110 m noise only: the 5 m noise in a threshold turns to leopard spots at 100-500 m.
	vec3 sunny = mix(c_grass_sun, c_scrub, 0.6 * smoothstep(0.5, 0.72, nm) * (1.0 - smoothstep(3300.0, 3700.0, e)));
	float forest = smoothstep(0.36, 0.5, nm) * smoothstep(12.0, 20.0, slope) * (1.0 - smoothstep(timber_line - 150.0, timber_line + 50.0, e));
	vec3 trees = mix(c_conifer, c_larch, smoothstep(0.45, 0.52, nf));
	trees = mix(trees, c_birch, smoothstep(0.62, 0.68, nf) * step(e, 3500.0));
	trees = mix(trees, c_maple, smoothstep(0.78, 0.82, nf) * step(e, 3200.0));
	// Tree by tree only near: beyond 80-300 m the 5 m mix turns to leopard spots, so it fades to the wood's average.
	vec3 wood = mix(mix(c_conifer, c_larch, 0.45), c_birch, 0.12 * step(e, 3500.0));
	trees = mix(trees, wood, smoothstep(80.0, 300.0, dist));
	vec3 col = mix(sunny, mix(c_grass_shade, trees, forest), shaded_face);
	float wooded = forest * shaded_face;
	col = mix(col, c_alpine, smoothstep(3550.0, 3700.0, e) * (1.0 - wooded));
	col = mix(col, c_earth, smoothstep(24.0, 30.0, s) * (1.0 - wooded * 0.7));
	col = mix(col, c_rock, smoothstep(38.0, 44.0, s));
	col = mix(col, c_scree, smoothstep(4250.0, 4350.0, e) * (1.0 - smoothstep(38.0, 44.0, s)));
	float near = 1.0 - smoothstep(30.0, 60.0, dist);
	return col * (0.9 + 0.2 * nf) * (1.0 + (nd - 0.5) * 0.22 * near);
}
