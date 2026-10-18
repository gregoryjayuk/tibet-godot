// Stylized static surfaces from the kit (plan chapter 11, 7.1-7.2). The palette slot in UV2.x picks the colour and
// shader parameters from the palette texture, so a building is one opaque surface (plus gloss and alpha later)
// instead of one per material. Lighting and patterns are the draft's, shared through shaders/inc/.
shader_type spatial;

// 128 x 4 (the slot count, from palette.json), RGBA16F, linear: row 0 base colour; row 1 paint, streaks, fibers, pattern; row 2 gloss, rim, soft, spare;
// row 3 the snow and wet response (unused yet). Built from data/palette.json by tools/build/palette_tex.gd.
global uniform sampler2D g_palette : filter_nearest;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 shade_color : source_color = vec3(0.36, 0.44, 0.70);
uniform float sky_occlusion = 0.0;  // how much COLOR.r (baked sky occlusion) darkens: 0 until chapter 09's art pass
uniform float weathering = 1.0;  // art step A1: chapter 09's weathering stack (4.6); 0 draws M0's look, for comparisons
uniform float metals = 1.0;  // art step A4: chapter 09's painted metals (4.4); 0 draws the single highlight of before, for comparisons
instance uniform float variant = 0.5;  // per building, from its seed: a small tone shift (0.5 = none); chapter 11, 7.2
// Each household its own (world/households.gd; IMP-019): x its upkeep (1 limed and painted this year, as the kit draws
// it; lower, the wash worn thin to the earth plaster and the log storeys' oxblood faded, then gone to grey timber), y its
// woodwork's paint (0 as the kit drew it, 1-5 the red, blue and green swapped round), z its lime's warmth (0 cool, 1
// creamy; 0.5 none), w 1 while it is shut, the household away: its paper windows behind closed shutters, no lamp.
instance uniform vec4 household = vec4(1.0, 0.0, 0.5, 0.0);
// A rope bridge (world/town.gd; IMP-027): how far its deck gives under the walker, metres (0 on everything else), and its
// two ends in the world's x, z: nothing gives at an end, where it is tied to its posts. Below 0: a hall's curtain, its
// height (world/curtains.gd), `sway` its push.
instance uniform float give = 0.0;
instance uniform vec4 give_ends = vec4(0.0);
// The chain bridge's sway (world/chain_bridge.gd; M2 sprint 4): x sideways and y up, metres at its middle, in its first
// mode (nothing at its ends, where give_ends are), from the footfalls of whoever is on it.
instance uniform vec4 sway = vec4(0.0);
const int PAINT_SLOT[3] = {14, 19, 18};  // wood_red, paint_blue, paint_green
const int PAINT_PERM[18] = {0, 1, 2, 1, 0, 2, 2, 1, 0, 0, 2, 1, 1, 2, 0, 2, 0, 1};

#include "res://shaders/inc/patterns.gdshaderinc"
#include "res://shaders/inc/light_stylized.gdshaderinc"
#include "res://shaders/inc/ramp.gdshaderinc"
#include "res://shaders/inc/horizon.gdshaderinc"

global uniform vec3 g_sky_fill;
global uniform float g_gi_inside;  // spike S7 (M3 sprint 5, step 3): 1 while a hall's GI (a probe, VoxelGI) lights its inside (world/interior_stack.gd)
global uniform vec3 g_ground_bounce;
global uniform vec3 g_sun_col;
global uniform float g_night_glow;  // lamps lit behind the paper windows, from dusk to bedtime and before dawn (world/day.gd)
global uniform float g_game_minute;  // the game's clock (world/day.gd): a household's own lamp hours (ISS-039)
global uniform float g_sun_alt;
global uniform float g_snow_line;  // the weather's snow line, design metres (world/day.gd; IMP-021): 99999 none
global uniform float g_snow;  // and how much lies on the town's tops under it, 0 to 1
global uniform vec3 g_player;  // the walker's feet (player/player.gd): a rope bridge gives under them

varying vec3 wpos;
varying vec3 rest_v;  // the world position before a curtain's or a bridge's bend: the paint, the patterns and the grain stay on the cloth
varying vec3 wnrm;
varying float slot_v;
varying vec4 wear;  // CUSTOM0 from the kit (chapter 09, 4.6): soot, moss, grime, polish
varying vec4 site;  // CUSTOM1: metres below the parapet, metres above the building's ground, building hash, age class
varying float m1_v;  // 1 where M1's look applies (the kit's channels are present and weathering is on)
varying float bias_v;  // the painted shadow bias, COLOR.b, for light() (chapter 09, 4.2)
varying float fam_v;  // the slot's ramp family
varying float sky_v;  // baked sky occlusion, COLOR.r
varying float indoor_v;  // COLOR.a: 1 on a room's surfaces and furnishings (the game's sprint 7; tibet-blender core.ROOMS)
varying float paper_v;  // 1 on a window's oiled paper, both faces: a room's lights glow through it (M2 sprint 8)
varying float gloss_v;
varying float rim_v;
varying float soft_v;
varying float metal_v;  // chapter 09's metal (4.4; art step A4): 0 none, 1 gold, 2 gold leaf, 3 brass, 4 copper, 5 iron, 6 silver

void vertex() {
	vec3 rest = VERTEX;
	if (give < 0.0) {  // a hall's yak-hair curtain (world/curtains.gd; M3 sprint 6): `give` its height below 0, `sway` the push
		// (x along it, the side it goes to: +1 the model's -z, metres at its foot, the spread either side); hung from its
		// batten at the origin, nothing moves there and most at its foot, round where it is pushed
		float depth = clamp(-VERTEX.y / max(-give, 0.1), 0.0, 1.0);
		float g = exp(-pow((VERTEX.x - sway.x) / max(sway.w, 0.2), 2.0));
		float b = sway.z * pow(depth, 1.4);
		VERTEX.z -= sway.y * b * g;
		VERTEX.y += 0.22 * abs(b) * g * depth;  // its foot lifts as it swings
		VERTEX.x += sign(VERTEX.x - sway.x) * 0.25 * abs(b) * g * (1.0 - g);  // and parts round the push
	} else if (give > 0.0 || sway.x != 0.0 || sway.y != 0.0) {  // a rope bridge, or the chain bridge: free between its ends
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec2 ab = give_ends.zw - give_ends.xy;
		float t = clamp(dot(wp.xz - give_ends.xy, ab) / max(dot(ab, ab), 1e-4), 0.0, 1.0);
		if (give > 0.0) {  // its deck, ropes and stakes dip under the walker and sway a little
			float free = clamp(min(t, 1.0 - t) * length(ab) / 2.0, 0.0, 1.0);  // nothing at its ends, all 2 m in
			vec2 d = wp.xz - g_player.xz;
			float under = exp(-dot(d, d) / 4.5) * (1.0 - smoothstep(2.0, 3.0, abs(wp.y - g_player.y)));
			VERTEX.y -= give * free * under;
			VERTEX.x += 0.018 * free * sin(TIME * 1.7 + t * 2.1);  // its own sway, across it (the kit's x)
		}
		float mode = sin(3.14159265 * t);  // the chain bridge's first mode
		VERTEX.x += sway.x * mode;
		VERTEX.y += sway.y * mode;
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	rest_v = (MODEL_MATRIX * vec4(rest, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	slot_v = UV2.x;  // constant across a face, so no flat qualifier is needed
	wear = CUSTOM0;  // CUSTOM0-3 exist only in vertex() (chapter 09, 4.1)
	site = CUSTOM1;
}

// Chapter 09's colours for the weathering stack, linear.
const vec3 C_FRESH = vec3(0.855, 0.807, 0.701);  // #EEE8DA, lime inside a pour
const vec3 C_AGED = vec3(0.672, 0.604, 0.479);  // #D6CCB8, between pours and low down
const vec3 C_STONE = vec3(0.271, 0.238, 0.198);  // #8E867B, galetted rubble showing through
const vec3 C_STONE2 = vec3(0.323, 0.287, 0.238);  // #9A9286
const vec3 C_FLAKES = vec3(0.156, 0.144, 0.125);  // #6E6A63, the courses of flakes
const vec3 C_GRIME = vec3(0.195, 0.127, 0.065);  // #7A6448
const vec3 C_SOOT = vec3(0.013, 0.010, 0.009);  // #1E1A17
const vec3 C_MOSS = vec3(0.271, 0.323, 0.209);  // #8E9A7E
const vec3 C_LICHEN = vec3(0.571, 0.238, 0.042);  // #C7863A
const vec3 C_BAREWOOD = vec3(0.144, 0.102, 0.065);  // #6A5A48, painted timber worn to grey wood
// A household's upkeep (IMP-019): the earth plaster under a wash worn thin, oxblood faded, logs long unpainted.
const vec3 C_EARTH = vec3(0.351, 0.254, 0.150);  // #A08A6C
const vec3 C_FADED_RED = vec3(0.262, 0.069, 0.045);  // #8C4A3C
const vec3 C_OLDWOOD = vec3(0.147, 0.112, 0.084);  // #6B5E52
const vec3 C_DUSTY_BLACK = vec3(0.069, 0.058, 0.047);  // #4A443D, a crown's black strip gone to dust
const vec3 C_GRASS_DARK = vec3(0.133, 0.125, 0.041);  // #666339, a roof's grass at its roots
const vec3 C_GRASS_STRAW = vec3(0.301, 0.266, 0.105);  // #958D5B, and its dry tops in late October

// Chapter 09's metals (4.4), linear, indexed by the palette's metal id (row 3, alpha): what the metal reflects below the
// horizon, at it and towards the zenith, its broad toon band and its hot core (times the HDR factor). Iron is flat.
const vec3 M_BELOW[7] = {vec3(0.0), vec3(0.1946, 0.0844, 0.0144), vec3(0.1470, 0.0685, 0.0160), vec3(0.1119, 0.0578, 0.0176), vec3(0.0685, 0.0232, 0.0130), vec3(0.0), vec3(0.1022, 0.1022, 0.1170)};
const vec3 M_HORIZON[7] = {vec3(0.0), vec3(0.9216, 0.6795, 0.1946), vec3(0.8148, 0.6038, 0.2086), vec3(0.6939, 0.4851, 0.1746), vec3(0.5841, 0.2542, 0.1221), vec3(0.0), vec3(0.8469, 0.8469, 0.8714)};
const vec3 M_ABOVE[7] = {vec3(0.0), vec3(0.5841, 0.3515, 0.0685), vec3(0.5210, 0.3564, 0.1022), vec3(0.3763, 0.2542, 0.0844), vec3(0.2542, 0.1441, 0.1022), vec3(0.0), vec3(0.3916, 0.4342, 0.5271)};
const vec3 M_BROAD[7] = {vec3(0.0), vec3(0.8879, 0.5841, 0.1441), vec3(0.8308, 0.5972, 0.1878), vec3(0.6939, 0.4508, 0.1119), vec3(0.6308, 0.2542, 0.1119), vec3(0.1441, 0.1274, 0.1170), vec3(0.8070, 0.8070, 0.8388)};
const vec3 M_CORE[7] = {vec3(0.0), vec3(1.0000, 0.8963, 0.6308), vec3(1.0000, 0.8714, 0.5776), vec3(1.0000, 0.7913, 0.3916), vec3(1.0000, 0.6308, 0.3916), vec3(0.0), vec3(1.0000, 1.0000, 1.0000)};
const float M_CORE_HDR[7] = {0.0, 2.5, 1.6, 1.4, 1.2, 0.0, 1.3};

// Chapter 09 (4.6), steps 1-11 (wet and snow come with the weather): the colour of a surface already carries its
// light, age and form. Needs the kit's SITE and WEAR channels (tibet-blender export_types.py, weather_channels);
// surfaces without them keep M0's look.
vec3 weather(vec3 col, int slot, vec3 p, vec3 n, float curv, float sky, vec4 wr, vec4 st, vec3 cam, float up) {
	float hb = st.z;
	float height = st.x + st.y;  // the wall from its foot to its parapet
	float t_h = st.y / max(height, 0.01);  // 0 at the foot, 1 at the parapet
	bool lime = slot >= 1 && slot <= 3;  // whitewash, whitewash_clean, plaster_white
	bool timber = (slot >= 14 && slot <= 18) || slot == 36 || slot == 40 || slot == 41;
	bool walked = slot == 9 || slot == 10;  // stone_step, flagstones: feet keep their tops clean of moss
	bool wall = abs(n.y) < 0.5;
	vec2 along = normalize(vec2(-n.z, n.x) + vec2(1e-4));
	float u = dot(p.xz, along);  // the horizontal coordinate along this wall
	float n03 = tri(p, n, 0.53);
	float n15 = tri(p, n, 0.107);
	float n40 = tri(p, n, 0.04);
	// 1. The building's own tone (its hash), 2. light from above, 3. noise at 0.3, 1.5 and 4 m.
	col *= 1.0 + (hb - 0.5) * 0.06;
	col *= mix(0.92, 1.06, t_h);
	col *= 1.0 + (n03 - 0.5) * 0.08 + (n15 - 0.5) * 0.12 + (n40 - 0.5) * 0.14;
	if (lime && wall) {
		// 4. Whitewash pours: lobes from the parapet, 0.4-1.2 m wide and 1.5-6 m long, fresh inside, aged between
		//    and in the lower third; a little build-up where the wall turns a corner or meets an opening.
		float cell = floor(u / 0.9);
		float fu = u - (cell + 0.5) * 0.9;
		float half_w = mix(0.2, 0.6, hash21(vec2(cell, hb * 97.0)));
		float len_p = mix(1.5, 6.0, hash21(vec2(cell + 11.3, hb * 57.0)));
		float reach = sqrt(max(1.0 - st.x / len_p, 0.0));
		float inside = 1.0 - smoothstep(half_w * reach * 0.75, half_w * reach, abs(fu) + (n03 - 0.5) * 0.12);
		inside *= 1.0 - smoothstep(len_p * 0.85, len_p, st.x + (n15 - 0.5) * 0.6);
		float low = 1.0 - smoothstep(0.25, 0.4, t_h);
		// Stronger than the palette's two tones alone, so the pours read at 50 m (A1's test). The household's upkeep
		// (`up`, IMP-019): the pours as fresh as its last liming; a house long unlimed gone grey-yellow, its wash worn
		// thin in patches to the earth plaster, more so low down.
		col = mix(col, C_FRESH * 1.06, 0.7 * inside * mix(0.3, 1.0, up));
		col = mix(col, C_AGED * mix(vec3(0.86, 0.82, 0.72), vec3(0.94), up), (0.55 + 0.25 * low) * (1.0 - inside * up));
		float thin = (1.0 - up) * smoothstep(0.45, 0.8, n15 * 0.55 + n03 * 0.45 + (1.0 - t_h) * 0.2);
		col = mix(col, C_EARTH, 0.6 * thin);
		col *= 1.0 + 0.04 * smoothstep(0.55, 0.65, curv);
		// 5. Stone where the lime has worn: below 0.8 m and on convex corners, rubble in its courses of flakes.
		float worn = (1.0 - smoothstep(0.3, 0.85, st.y + (n15 - 0.5) * 0.6)) + smoothstep(0.54, 0.62, curv) * 0.7;
		float show = smoothstep(0.55, 0.62, worn * (0.55 + 0.9 * n03) + 0.3 * (1.0 - up));
		vec3 c = cells(vec2(u, p.y) * vec2(2.4, 3.2));
		vec3 stone = mix(C_STONE, C_STONE2, c.y);
		stone = mix(stone, C_FLAKES, 1.0 - smoothstep(0.03, 0.09, c.x));
		col = mix(col, stone, show);
	}
	if (timber) {
		col = mix(col, C_BAREWOOD, 0.6 * smoothstep(0.75 - 0.2 * (1.0 - up), 0.98, curv) * n03);  // paint lost on worn edges
	}
	// Metal takes no grime, splash or moss: gilding is renewed, brass is polished by hands (chapter 09, 4.4).
	float dirt = texelFetch(g_palette, ivec2(slot, 3), 0).a > 0.5 ? 0.0 : 1.0;
	// 6. Grime and splash: a ragged plinth band 0.5-1.0 m high, heavier by doors and along animal routes.
	float plinth = mix(0.5, 1.0, n15);
	float g = (1.0 - smoothstep(plinth - 0.2, plinth + 0.05, st.y)) * mix(0.3, 0.55, n03);
	g = max(g, wr.b * 0.55 * (1.0 - smoothstep(0.2, 2.2, st.y)) * (0.6 + 0.4 * n03) * (timber ? 0.25 : 1.0));  // doors themselves stay cleaner
	col = mix(col, C_GRIME, clamp(g, 0.0, 0.8) * dirt);
	// 7. Soot over the kitchen's windows.
	col = mix(col, C_SOOT, clamp(wr.r * (0.55 + 0.45 * n03), 0.0, 0.8));
	// 8. Moss and lichen: north faces (north is -Z) and the tops of copings, on stone rather than lime, in shade; never
	//    on a step's tread or the paving, which feet wear clean (Greg's walk, 27 Sep 2026: mossed like copings, the
	//    Sky Stair's treads went darker than its risers and from above the steps seemed to face the wrong way).
	float north = smoothstep(-0.3, -0.6, n.z);
	float cope = walked ? 0.0 : smoothstep(0.7, 0.9, n.y) * (1.0 - smoothstep(0.0, 0.8, st.x));
	float moss = wr.g * max(north, cope) * clamp(1.25 - sky, 0.0, 1.0) * clamp(st.w * 0.6, 0.3, 1.0) * dirt;
	moss *= smoothstep(0.42, 0.62, n15 + (n03 - 0.5) * 0.3);
	col = mix(col, C_MOSS, 0.7 * moss);
	col = mix(col, C_LICHEN, moss * step(0.9, hash21(floor(vec2(u, p.y) * 9.0))));
	// 9. Curvature: worn edges lighter, corners darker. Since kit step K2 (ISS-029) flat reads 0.5 and an edge counts
	//    by how much of its face it covers: an 8 cm beam's face reads about 0.75, its end 1.0; a big wall stays 0.5.
	col *= 1.0 + smoothstep(0.55, 0.95, curv) * 0.14 - (1.0 - smoothstep(0.1, 0.45, curv)) * 0.22;
	// 10. Polish where hands go.
	col *= 1.0 + wr.a * 0.15;
	// 11. Brush strokes within 15 m, vertical on walls, gone by 25 m.
	float near = 1.0 - smoothstep(15.0, 25.0, length(p - cam));
	float stroke = texture(noise_tex, wall ? vec2(u * 2.5, p.y * 0.18) : p.xz * vec2(2.5, 0.18)).r;
	col *= 1.0 + (stroke - 0.5) * 0.06 * near;
	return col;
}

// Snow on the tops (IMP-021, item 4; Greg's 1781): the roofs, copings, parapets, sills, ledges and treads that face the
// open sky, above the weather's snow line or under the town's cover, in drifts and patches; none under the eaves or in a
// gallery (the kit's baked sky occlusion); a step's tread or a paving's flag trodden through in the middle.
const vec3 C_SNOW = vec3(0.888, 0.905, 0.922);  // #F2F4F6, chapter 01's lit snow (its shade comes from the light)
float kit_snow(vec3 p, vec3 n, float sky, int slot) {
	if (g_snow <= 0.0 && p.y + 2662.0 < g_snow_line - 80.0) {
		return 0.0;  // the season's own: nothing in the town
	}
	float nf = tri(p, n, 0.35);
	float nc = tri(p, n, 0.06);
	float lie = smoothstep(g_snow_line - 40.0, g_snow_line + 40.0, p.y + 2662.0 + (nf - 0.5) * 60.0);
	float amount = max(lie, g_snow);
	float top = smoothstep(0.55, 0.85, n.y);
	float open = smoothstep(0.35, 0.75, sky);
	float patches = smoothstep(0.35, 0.6, nf * 0.6 + nc * 0.4 + amount * 0.45 - 0.2);
	float s = top * open * amount * patches;
	if (slot == 9 || slot == 10) {  // stone_step, flagstones: the feet's path
		s *= 0.45 + 0.55 * smoothstep(0.35, 0.65, nc);
	}
	return clamp(s, 0.0, 1.0);
}

void fragment() {
	int slot = clamp(int(floor(slot_v * 128.0)), 0, 127);  // UV2.x = (id + 0.5) / 128
	vec4 p0 = texelFetch(g_palette, ivec2(slot, 0), 0);
	vec4 p1 = texelFetch(g_palette, ivec2(slot, 1), 0);
	vec4 p2 = texelFetch(g_palette, ivec2(slot, 2), 0);
	vec3 col = p0.rgb;
	float paint = p1.r;
	float streaks = p1.g;
	float fibers = p1.b;
	int pattern = int(p1.a + 0.5);
	int scheme = int(household.y + 0.5);
	if (scheme > 0 && (slot == 14 || slot == 18 || slot == 19 || slot == 78)) {  // the household's paint on its woodwork, its
		int k = (slot == 14 || slot == 78) ? 0 : (slot == 19 ? 1 : 2);  // eave's rafter ends with its frames (both wood_red)
		col = texelFetch(g_palette, ivec2(PAINT_SLOT[PAINT_PERM[scheme * 3 + k]], 0), 0).rgb;
	}
	if (slot == 40 || slot == 77) {  // the log storeys (the upper town's comfortable households): oxblood renewed, faded
		// in the sun (77 is the kit's faded front already); gone to grey timber only on a house long left
		col = mix(slot == 40 ? C_FADED_RED : mix(col, C_OLDWOOD, 0.3), col, smoothstep(0.35, 0.85, household.x));
		col = mix(C_OLDWOOD, col, smoothstep(0.05, 0.3, household.x));
	} else if (slot == 14 || slot == 18 || slot == 19 || slot == 78) {  // the woodwork's paint, faded on a house kept poorly
		col = mix(col, C_BAREWOOD, 0.45 * (1.0 - smoothstep(0.3, 0.7, household.x)));
	}
	if (slot == 101 || slot == 102) {  // a town house's crown strip (ISS-109): black or maroon as its household paints it,
		// fresh where it was renewed this season, towards dust or brick as its upkeep falls but a band still while anyone
		// lives there, and on a shut or left house flaking off its parapet in patches
		bool maroon = scheme > 0 ? scheme % 3 == 2 : slot == 102;
		col = texelFetch(g_palette, ivec2(maroon ? 102 : 101, 0), 0).rgb;
		col = mix(maroon ? C_FADED_RED : C_DUSTY_BLACK, col, 0.35 + 0.65 * smoothstep(0.05, 0.75, household.x));
		col = mix(col, C_AGED, 0.85 * (1.0 - smoothstep(0.05, 0.3, household.x)) * smoothstep(0.5, 0.62, tri(wpos, wnrm, 0.4)));
	}
	if (slot == 11 && household.x < 0.45 && wnrm.y > 0.6) {  // an earth roof not beaten and mended grows grass in patches
		float grass = smoothstep(0.45, 0.15, household.x) * smoothstep(0.42, 0.62, tri(wpos, wnrm, 0.7));
		col = mix(col, mix(C_GRASS_DARK, C_GRASS_STRAW, tri(wpos, wnrm, 0.08)), 0.9 * grass);  // tufts, darker at the root
	}
	bool shut = household.w > 0.5 && (slot == 45 || slot == 68);
	if (shut) {  // closed shutters over the paper: boards, a line between each
		col = texelFetch(g_palette, ivec2(17, 0), 0).rgb * (0.9 + 0.1 * step(0.12, fract((wpos.x + wpos.z) * 6.0)));
		pattern = 0;
	}
	float n1 = tri(rest_v, wnrm, 0.045);
	float n2 = tri(rest_v, wnrm, 0.35);
	col *= 1.0 + (n1 - 0.5) * paint * 2.2 + (n2 - 0.5) * paint;
	float hz = rest_v.x + rest_v.z;
	bool weathered = weathering > 0.5 && site.x + site.y > 0.0;
	indoor_v = COLOR.a;
	paper_v = (slot == 45 || slot == 68) ? 1.0 : 0.0;
	if (streaks > 0.0 && !weathered) {  // the draft's streaks; the weathering stack's pours replace them
		float s = texture(noise_tex, vec2(hz * 0.55, rest_v.y * 0.035)).r;
		col *= 1.0 - smoothstep(0.52, 0.78, s) * streaks;
	}
	if (fibers > 0.0) {
		float f = texture(noise_tex, vec2(hz * 4.0, rest_v.y * 0.12)).r;
		col *= 1.0 + (f - 0.5) * fibers * 1.6;
	}
	col = apply_pattern(pattern, col, rest_v, wnrm, n2, hz);
	m1_v = 0.0;
	metal_v = 0.0;
	if (weathered) {
		// COLOR.r, the kit's baked sky occlusion (chapter 03, 14.3), usable since kit step K2 (ISS-029): walls 0.7-0.9,
		// open roofs about 0.9, galleries, reveals and courtyards low. COLOR.g, curvature: 0.5 flat.
		float sky_occ = COLOR.r;
		// Indoors (sprint 7) nothing weathers: no pours, no moss, no plinth grime; a room keeps its plaster's own tone.
		if (indoor_v < 0.5) {
			col = weather(col, slot, wpos, wnrm, COLOR.g, sky_occ, wear, site, CAMERA_POSITION_WORLD, household.x);
		}
		// Art step A2: the ramp's inputs for light(), the hemisphere fill (4.5) and the baked occlusion.
		m1_v = 1.0;
		bias_v = COLOR.b + 0.1 * (1.0 - smoothstep(0.0, 0.5, site.x));  // the top 0.5 m of a wall catches light earlier
		fam_v = p2.a;
		sky_v = sky_occ;
		EMISSION = col * mix(g_ground_bounce, g_sky_fill, wnrm.y * 0.5 + 0.5) * sky_occ * 0.15;
		AO = (indoor_v > 0.5 && g_gi_inside > 0.5) ? 1.0 : sky_occ;  // chapter 09 (4.5): covered passages and the backs of galleries go dark by day (a room's inside under a GI takes the GI's light whole: S7),
		AO_LIGHT_AFFECT = 0.15;  // but the sun still lights what it can reach
		// Art step A4, painted gold (chapter 09, 4.4): metal is seen as the sky and the ground it reflects. The world-space
		// reflection's height picks bronze below the horizon, the bright horizon band, and the zenith tinted by the sky;
		// it dims with the sun. The toon bands are in light().
		int metal = int(texelFetch(g_palette, ivec2(slot, 3), 0).a + 0.5);
		metal_v = metals > 0.5 ? float(metal) : 0.0;
		if (metal > 0 && metals > 0.5) {
			// A metal's diffuse is small: at full albedo the sunlit base washed the reflections out to a pale, even yellow
			// (A4's first stills), so the base keeps 45 % and what the metal reflects carries it (design, DECISIONS).
			col *= 0.45;
			EMISSION *= 0.45;  // the fill is diffuse light too
			vec3 r = (INV_VIEW_MATRIX * vec4(reflect(-VIEW, NORMAL), 0.0)).xyz;
			vec3 env = r.y < 0.0 ? mix(M_HORIZON[metal], M_BELOW[metal], smoothstep(0.0, 0.3, -r.y))
					: mix(M_HORIZON[metal], mix(M_ABOVE[metal], g_sky_fill, 0.2), smoothstep(0.03, 0.4, r.y));
			EMISSION += env * 0.35 * luma(g_sun_col) * mix(0.4, 1.0, sky_occ);
		}
	}
	vec3 open_col = col;  // before the sky's occlusion: what oiled paper glows with, however shut in its reveal or bay
	col *= mix(1.0, COLOR.r, sky_occlusion);
	// A paper window seen from inside glows with the day beyond it (oiled paper, chapter 04, 8.2's LR-09T key); the
	// window's light itself is the room's own (interiors/). Its glow is the paper's own colour, not darkened by the bake's
	// occlusion (a bay's paper, deep in its box of timber, baked near black: the headman's guest room, M2 sprint 7).
	if (indoor_v > 0.5 && slot == 45 && !shut) {
		EMISSION += open_col * (g_sky_fill * 1.6 + g_sun_col * 0.12);
	}
	col *= 1.0 + (variant - 0.5) * 0.08;
	if (slot >= 1 && slot <= 3 && indoor_v < 0.5) {  // the household's lime, cooler or creamier (its quarry, its earth)
		col *= 1.0 + (household.z - 0.5) * vec3(0.08, 0.01, -0.14);  // 0.5: as the kit draws it
	}
	if (indoor_v < 0.5 && (g_snow_line < 9000.0 || g_snow > 0.0)) {
		col = mix(col, C_SNOW, kit_snow(wpos, wnrm, COLOR.r, slot));
	}
	ALBEDO = col;
	// Kit step K3 (chapter 03, 2.3): oiled paper glows #F2B25C from inside after dusk; the lattice's bars stay dark.
	// The palette's row 3 carries a slot's night colour (paper, lanterns).
	vec3 night_c = texelFetch(g_palette, ivec2(slot, 3), 0).rgb;
	bool paper_inside = indoor_v > 0.5 && (slot == 45 || slot == 68);  // the room's side of the paper: lit by the room's own
	// lights, not glowing as though a lamp burned in the night outside it (ISS-136)
	if (dot(night_c, night_c) > 0.0 && !shut && !paper_inside) {
		float lamp = g_night_glow;
		if (any(notEqual(household, vec4(1.0, 0.0, 0.5, 0.0)))) {  // a town household's own lamps (ISS-039): lit at its own
			// minute of the evening and put out at its own bedtime, a few before dawn too; only on the storeys it lives in
			// (never the stable, the kitchen's floor nearly always, the rooms above more often in a house kept well); none in a
			// shut house; as bright as the dark is deep (the town's own lamps: g_night_glow, world/day.gd)
			float m = mod(g_game_minute, 1440.0);
			float hs = household.z * 61.7 + site.z * 13.3;  // the household's own dice: its warmth is drawn per house, the
			float h1 = hash21(vec2(hs, 11.0));  // kit's building hash per variant (up to four houses share one)
			float h2 = hash21(vec2(hs, 23.0));
			float h3 = hash21(vec2(hs, 31.0));
			float on = 975.0 + 75.0 * h1;  // 16:15-17:30
			float off = 1200.0 + 120.0 * h2;  // 20:00-22:00
			float time_lit = smoothstep(on, on + 4.0, m) * (1.0 - smoothstep(off, off + 4.0, m));
			float dawn = 285.0 + 40.0 * h3;  // 04:45-05:25, the early risers'
			time_lit = max(time_lit, step(h3, 0.45) * smoothstep(dawn, dawn + 4.0, m) * (1.0 - smoothstep(420.0, 440.0, m)));
			float storey = floor((site.y + 0.2) / 2.5);
			bool han = household.y < -0.5;  // Hejie's Han houses (world/households.gd HAN): they live on the ground floor, and
			// the lanterns by their doors and under their eaves are lit with the evening, whichever storey they hang on
			float lit_p = storey < 0.5 ? (han ? 0.85 : 0.0) : (storey < 1.5 ? 0.9 : mix(0.15, 0.6, household.x));
			if (han && slot == 56) {
				lit_p = 1.0;
			}
			float lit = step(hash21(vec2(hs * 1.7, storey * 7.0 + 3.0)), lit_p) * (1.0 - step(0.5, household.w));
			lamp = (1.0 - smoothstep(-4.0, 8.0, g_sun_alt)) * time_lit * lit;
		}
		if (lamp > 0.0) {
			EMISSION += night_c * lamp * (1.0 - lattice_bars(pattern, wpos, wnrm)) * 1.4;
		}
	}
	// The ink pass's line group (chapter 09, 8.2; art step A5), at its bin centre: 5 gold and bright metal, 1 architecture.
	int metal_code = int(texelFetch(g_palette, ivec2(slot, 3), 0).a + 0.5);
	ROUGHNESS = (metal_code > 0 && metal_code != 5 ? 5.5 : 1.5) / 16.0;
	SPECULAR = 0.0;  // the engine's sky reflections read roughness: off
	gloss_v = p2.r;
	rim_v = p2.g;
	soft_v = p2.b;
}

void light() {
	// A room's own lights (tools/build/make_rooms.gd: omni, no specular, no shadow) light the room's surfaces and its
	// windows' paper only: shadowless, they had lit the yards' walls through the masonry at night (M2 sprint 8). The
	// town's outdoor lamps (world/lamps.gd) keep a specular and light everything.
	float own = (!LIGHT_IS_DIRECTIONAL && SPECULAR_AMOUNT < 0.01 && indoor_v < 0.5 && paper_v < 0.5) ? 0.0 : 1.0;
	vec3 d = vec3(0.0);
	vec3 s = vec3(0.0);
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);  // art step A8: the terrain's shadow
	if (m1_v > 0.5) {
		// Chapter 09 (4.2-4.3): light through the slot's ramp, cast shadows push into its shadow band, and the shade
		// takes the colour the albedo's hue asks for.
		float x = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5 + (bias_v - 0.5) * 1.2, 0.0, 1.0);
		vec3 lit = ramp_lookup(int(fam_v + 0.5), x) * ATTENUATION;
		float lit_l = luma(lit);
		vec3 tint = shadow_tint(ALBEDO, sky_v);
		float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0) * rim_v * lit_l;
		// Indoors the sun gives only what it lights through a door or a window: its shade fill stands for the sky's
		// light, which a room does not see (sprint 7). The rooms' own lights keep their fill.
		float fill = (LIGHT_IS_DIRECTIONAL && indoor_v > 0.5) ? 0.0 : 1.0;
		d = (LIGHT_COLOR * lit + (LIGHT_COLOR * tint * 0.16 * (1.0 - lit_l) + LIGHT_COLOR * rim) * fill) / PI;
		if (metal_v > 0.5) {
			// Painted gold's two toon bands (chapter 09, 4.4): a broad band and a hot core, the core the one thing outdoors
			// that crosses the glow threshold by day. They replace the single highlight that read as orange plastic.
			int mi = int(metal_v + 0.5);
			float nh = max(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0);
			float core = smoothstep(0.6, 0.64, pow(nh, 160.0));
			float broad = smoothstep(0.35, 0.45, pow(nh, 24.0)) * (1.0 - core);
			s = LIGHT_COLOR * ATTENUATION * (M_BROAD[mi] * broad + M_CORE[mi] * M_CORE_HDR[mi] * core);
		} else if (gloss_v > 0.0) {
			vec3 h = normalize(LIGHT + VIEW);
			float sp = pow(max(dot(NORMAL, h), 0.0), 48.0);
			s = LIGHT_COLOR * smoothstep(0.3, 0.42, sp) * gloss_v * lit_l * 0.6;
		}
	} else {
		stylized_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, shade_color, soft_v, rim_v, gloss_v, d, s);
	}
	DIFFUSE_LIGHT += d * ridge * own;
	SPECULAR_LIGHT += s * ridge * own;
}
