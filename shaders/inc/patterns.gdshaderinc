// Shared procedural patterns (the draft's seven: flagstones, yak-hair curtain, painted beams, mural, terrain,
// snowy peaks, gilded tiles; since kit step K3 the window lattices on paper, 8 a grid and 9 rings; since K5, 12 the
// poor house's thin wash over rubble; since K7, 13 small grey tiles laid cold; since K8, 14 the 品 eave's rafter ends;
// since the game's sprint 7, 15 floor boards and 16 square floor bricks; since M2 sprint 8, 17 silk brocade)
// and the noise
// helpers, used by stylized.gdshader and stylized_static.gdshader.
// Needs `noise_tex` declared by the including shader.

float tri(vec3 p, vec3 n, float s) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 1e-5);
	return texture(noise_tex, p.zy * s).r * w.x + texture(noise_tex, p.xz * s).r * w.y + texture(noise_tex, p.xy * s).r * w.z;
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec3 cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	vec2 id = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash21(i + g), hash21(i + g + 17.3)) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; id = i + g; }
			else if (d < d2) { d2 = d; }
		}
	}
	return vec3(d2 - d1, hash21(id), d1);
}

const vec3 LATTICE_WOOD = vec3(0.16, 0.055, 0.035);  // dark red-brown bars, the paper's lattice (chapter 03, 2.3)

// Kit step K3 (chapter 03, 2.3): a window's lattice drawn on its oiled paper instead of modelled, in the plane of the
// wall whatever way the building turns: 1 on a bar, 0 on paper, softened by a pixel. 8: a grid of 15 cm; 9: rings in
// 30 cm cells joined by bars, the round lattice of the better houses.
float lattice_bars(int pattern, vec3 wpos, vec3 wnrm) {
	if (pattern != 8 && pattern != 9) {
		return 0.0;
	}
	vec3 t = normalize(vec3(-wnrm.z, 0.0, wnrm.x) + vec3(1e-4, 0.0, 0.0));
	vec2 uv = vec2(dot(wpos, t), wpos.y);
	float px = max(fwidth(uv.x), fwidth(uv.y)) + 1e-4;
	if (pattern == 8) {
		vec2 g = abs(fract(uv / 0.15 + 0.5) - 0.5) * 0.15;  // metres to the nearest bar's centre
		float d = min(g.x, g.y);
		return 1.0 - smoothstep(0.009 - px, 0.009 + px, d);
	}
	vec2 f = (fract(uv / 0.3) - 0.5) * 0.3;  // metres from the cell's centre
	float ring = abs(length(f) - 0.095);
	float bar_h = abs(f.y) + step(abs(f.x), 0.095) * 1.0;  // the horizontal bar, outside the ring
	float bar_v = abs(f.x) + step(abs(f.y), 0.095) * 1.0;
	vec2 edge = abs(abs(f) - 0.15);  // the cell's frame
	float d = min(min(ring, min(bar_h, bar_v)), min(edge.x, edge.y));
	return 1.0 - smoothstep(0.008 - px, 0.008 + px, d);
}

vec3 apply_pattern(int pattern, vec3 col, vec3 wpos, vec3 wnrm, float n2, float hz) {
	if (pattern == 1) {
		// Flagstones, varied and worn (chapter 09, 17: PC-13 nothing tiles, PC-14 "varied stones ... no uniform crazy
		// paving"; ISS-106, M1's reference still RS-2): the cells warped so no run of joints repeats, bigger slabs here
		// and cobbles there, each stone its own tone from grey slate to ochre, a tenth darker (relaid) and a few newer and
		// lighter; broad bands where feet have polished the stones and filled their joints with dust.
		vec2 q = wpos.xz;
		q += (vec2(texture(noise_tex, q * 0.021).r, texture(noise_tex, q * 0.021 + vec2(0.37, 0.53)).r) - 0.5) * 2.2;
		// bigger slabs in some patches, cobbles in others, a joint along the seam between them (ISS-140: a scale varying
		// through space and multiplying the town's coordinates squeezed the stones into contour bands far from its origin)
		float zone = texture(noise_tex, q * 0.013 + vec2(0.61, 0.29)).r;
		vec3 c = zone > 0.5 ? cells(q * 0.8) : cells(q * 1.25);
		c.x = min(c.x, abs(zone - 0.5) * 6.0);
		float h = c.y;
		vec3 tone = mix(vec3(0.94, 0.97, 1.03), vec3(1.06, 1.0, 0.9), fract(h * 7.13));
		float v = 0.84 + 0.3 * fract(h * 3.71);
		v *= h < 0.1 ? 0.8 : (h > 0.94 ? 1.12 : 1.0);
		col *= tone * v;
		float wear = smoothstep(0.45, 0.75, texture(noise_tex, wpos.xz * 0.008 + vec2(0.2, 0.7)).r);
		col *= 1.0 + 0.05 * wear;
		float joint = 1.0 - smoothstep(0.015, 0.05 + 0.03 * wear, c.x);
		col = mix(col, col * mix(0.72, 0.88, wear), joint);
	} else if (pattern == 2) {
		vec2 uv = vec2(hz, wpos.y) * 2.3;
		vec2 q = abs(fract(uv) - 0.5);
		float dm = q.x + q.y;
		float mark = max(step(0.31, dm) * step(dm, 0.38), step(dm, 0.08));
		col = mix(col, vec3(0.93, 0.91, 0.86), mark);
	} else if (pattern == 3) {
		float f = fract(hz * 2.2);
		vec3 pal = f < 0.2 ? vec3(0.72, 0.16, 0.10) : f < 0.4 ? vec3(0.16, 0.52, 0.30) : f < 0.6 ? vec3(0.17, 0.32, 0.68)
			: f < 0.8 ? vec3(0.93, 0.71, 0.22) : vec3(0.95, 0.93, 0.88);
		float line = step(fract(wpos.y * 9.0), 0.12);
		col = mix(pal, vec3(0.08), line * 0.7);
	} else if (pattern == 4) {
		vec2 uv = vec2(hz * 1.1, wpos.y * 0.95);
		vec2 f = fract(uv) - 0.5;
		float r = hash21(floor(uv));
		vec3 body = r < 0.3 ? vec3(0.75, 0.18, 0.12) : r < 0.55 ? vec3(0.18, 0.4, 0.66) : r < 0.8 ? vec3(0.9, 0.62, 0.2) : vec3(0.2, 0.55, 0.32);
		col = mix(vec3(0.10, 0.25, 0.23), vec3(0.14, 0.32, 0.27), n2);
		col = mix(col, vec3(0.95, 0.74, 0.3), step(length(f - vec2(0.0, 0.12)), 0.3));
		col = mix(col, vec3(0.78, 0.22, 0.16), step(length((f - vec2(0.0, -0.33)) * vec2(0.6, 2.2)), 0.2));
		col = mix(col, body, step(length((f - vec2(0.0, -0.08)) * vec2(1.0, 0.8)), 0.24));
		col = mix(col, vec3(0.95, 0.8, 0.6), step(length(f - vec2(0.0, 0.2)), 0.08));
	} else if (pattern == 5) {
		float flatness = smoothstep(0.78, 0.93, wnrm.y);
		float g = tri(wpos, wnrm, 0.02);
		vec3 grass = mix(vec3(0.24, 0.40, 0.13), vec3(0.50, 0.60, 0.22), smoothstep(0.35, 0.7, g));
		vec3 soil = mix(vec3(0.45, 0.35, 0.24), vec3(0.58, 0.47, 0.32), n2);
		vec3 rock = mix(vec3(0.38, 0.36, 0.36), vec3(0.52, 0.5, 0.48), n2);
		col = mix(rock, soil, smoothstep(0.55, 0.8, wnrm.y));
		col = mix(col, grass, flatness * smoothstep(0.3, 0.5, g));
	} else if (pattern == 6) {
		float m = tri(wpos, wnrm, 0.0009);
		col = mix(vec3(0.42, 0.44, 0.52), vec3(0.58, 0.6, 0.68), m);
		float snow = smoothstep(1150.0, 1350.0, wpos.y + (m - 0.5) * 600.0) * smoothstep(0.35, 0.6, wnrm.y);
		col = mix(col, vec3(0.94, 0.96, 1.0), snow);
	} else if (pattern == 7) {
		float sel = step(abs(wnrm.z), abs(wnrm.x));
		float c = mix(wpos.x, wpos.z, sel);
		float groove = pow(abs(sin(c * 21.0)), 0.6);
		col *= 0.78 + 0.26 * groove;
	} else if (pattern == 8 || pattern == 9) {
		col = mix(col, LATTICE_WOOD, lattice_bars(pattern, wpos, wnrm));
	} else if (pattern == 13) {
		// Kit step K7 (chapter 03, 9.1): small grey tiles laid "cold", one over three on the rafters. Channels run down the
		// slope 0.2 m apart, each a covering row with a rounded back over the pans; each row's tiles differ a little;
		// the courses show faintly, and lichen where the noise gathers. Like pattern 7 (the gilded roofs), in world space
		// along the building's axes.
		float sel = step(abs(wnrm.z), abs(wnrm.x));
		float c = mix(wpos.x, wpos.z, sel) / 0.2;
		float rowi = floor(c);
		float roll = sin(fract(c) * PI);
		col *= 0.64 + 0.44 * roll;
		col *= 0.93 + 0.14 * hash21(vec2(rowi, 7.7));
		col *= 0.94 + 0.06 * step(0.5, fract(wpos.y / 0.035 + hash21(vec2(rowi, 1.3))));
		col = mix(col, vec3(0.36, 0.40, 0.30), smoothstep(0.62, 0.8, n2) * 0.3);
	} else if (pattern == 14) {
		// Kit step K8 (chapter 03, 3.4): a tier of the 品 eave, its rafter ends white on red every 16 cm along the strip on
		// its outward faces ("an alternation that reads from 100 m"), red underneath.
		float end_ = step(fract(hz / 0.16), 0.5) * step(abs(wnrm.y), 0.5);
		col = mix(col, vec3(0.93, 0.91, 0.86), end_);
	} else if (pattern == 15 && wnrm.y > 0.7) {
		// Sprint 7 (chapter 04, 4.3): a room's floor of boards 18 cm wide along the world's z, their ends staggered 1.4-2.6 m
		// apart, each board its own tone and grain, the seams and the joints dark.
		float bx = wpos.x / 0.18;
		float bi = floor(bx);
		float len = mix(1.4, 2.6, hash21(vec2(bi, 3.7)));
		float bz = (wpos.z + hash21(vec2(bi, 9.1)) * 3.0) / len;
		col *= 0.84 + 0.26 * hash21(vec2(bi, floor(bz)));
		col *= 0.93 + 0.14 * texture(noise_tex, vec2(wpos.x * 2.5, wpos.z * 0.2)).r;
		float px = fwidth(wpos.x) + fwidth(wpos.z) + 1e-4;
		float ex = min(fract(bx), 1.0 - fract(bx)) * 0.18;  // metres to the nearest seam
		float ez = min(fract(bz), 1.0 - fract(bz)) * len;  // and to the board's end
		float seam = 1.0 - smoothstep(0.004 - px, 0.004 + px, min(ex, ez));
		col = mix(col, col * 0.4, seam);
	} else if (pattern == 16 && wnrm.y > 0.7) {
		// Sprint 7: square fired bricks, 方磚, 36 cm, each its own tone, in pale joints (a Chinese room's floor).
		vec2 q = wpos.xz / 0.36;
		col *= 0.9 + 0.18 * hash21(floor(q) + 0.5);
		col *= 0.95 + 0.1 * texture(noise_tex, wpos.xz * 0.7).r;
		vec2 e = min(fract(q), 1.0 - fract(q)) * 0.36;
		float px = fwidth(wpos.x) + fwidth(wpos.z) + 1e-4;
		float joint = 1.0 - smoothstep(0.006 - px, 0.006 + px, min(e.x, e.y));
		col = mix(col, vec3(0.6, 0.58, 0.54), joint * 0.75);
	} else if (pattern == 17) {
		// M2 sprint 8 (chapter 04, 4.3: Dolkar's "brocade walls"): silk brocade, gold roundels (團花) 11 cm across in
		// offset rows on the slot's field, a flower of eight round petals in each, a small gold flower between them, and
		// the weave's faint twill; in the surface's plane (a wall along it and up, a cushion's top in the world's x and z).
		vec3 t = normalize(vec3(-wnrm.z, 0.0, wnrm.x) + vec3(1e-4, 0.0, 0.0));
		vec2 uv = (abs(wnrm.y) > 0.7 ? wpos.xz : vec2(dot(wpos, t), wpos.y)) / 0.14;
		uv.x += 0.5 * mod(floor(uv.y), 2.0);
		vec2 f = fract(uv) - 0.5;
		float px = max(fwidth(uv.x), fwidth(uv.y)) + 1e-4;
		float r = length(f);
		float ring = 1.0 - smoothstep(0.03 - px, 0.03 + px, abs(r - 0.37));
		float petal = 0.5 + 0.5 * cos(atan(f.y, f.x) * 8.0);  // 1 on a petal's middle, 0 between two
		float flower = 1.0 - smoothstep(0.0 - px, 0.0 + px, r - (0.12 + 0.13 * sqrt(petal)));
		float heart = 1.0 - smoothstep(0.05 - px, 0.05 + px, r);
		flower *= 1.0 - (1.0 - smoothstep(0.075 - px, 0.075 + px, r)) * (1.0 - heart);  // a ring of the field round the heart
		float between = 1.0 - smoothstep(0.07 - px, 0.07 + px, length(abs(f) - 0.5));
		float gold = max(max(ring, flower), max(heart, between));
		col *= 0.93 + 0.07 * step(0.5, fract((uv.x + uv.y) * 14.0));
		col = mix(col, vec3(0.80, 0.58, 0.22), gold * 0.9);
	} else if (pattern == 18) {
		// M3 sprint 3, step 3 (chapter 03, 6.4: the Gönkhang's porch, "a wall painting on black ground"): nagthang, the
		// protectors drawn in fine gold line on the slot's black, a figure to a cell 0.8 m wide and 1.15 m high in the wall's
		// plane: its aura of dark red flame licking outward, its halo and head, its body and its lotus seat outlined, one in
		// four drawn in white; the ground's mottle.
		vec3 t = normalize(vec3(-wnrm.z, 0.0, wnrm.x) + vec3(1e-4, 0.0, 0.0));
		vec2 uv = vec2(dot(wpos, t) / 0.8, wpos.y / 1.15);
		vec2 f = fract(uv) - 0.5;
		float px = max(fwidth(uv.x), fwidth(uv.y)) * 1.5 + 1e-4;
		float r = hash21(floor(uv));
		vec2 e = (f - vec2(0.0, -0.02)) * vec2(1.0, 0.7);  // (the cell's aspect: the aura round the seated figure)
		float a = atan(e.y, e.x);
		float fr = 0.36 + 0.05 * max(sin(a * 11.0 + r * 6.28), 0.0) + 0.03 * sin(a * 29.0 + r * 3.1);  // the flames' tongues
		float aura = (1.0 - smoothstep(fr - px, fr + px, length(e))) * smoothstep(0.27 - px, 0.29 + px, length(e));
		float halo = abs(length(f - vec2(0.0, 0.2)) - 0.12);
		float head = abs(length(f - vec2(0.0, 0.2)) - 0.065);
		float body = abs(length((f - vec2(0.0, -0.05)) * vec2(1.0, 0.72)) - 0.15);
		float seat = abs(length((f - vec2(0.0, -0.3)) * vec2(0.85, 3.4)) - 0.19);
		float line = 1.0 - smoothstep(0.009 - px, 0.009 + px, min(min(halo, head), min(body, seat)));
		col *= 0.85 + 0.3 * n2;
		col = mix(col, vec3(0.30, 0.045, 0.025), aura * 0.9);
		col = mix(col, r < 0.75 ? vec3(0.78, 0.56, 0.2) : vec3(0.8, 0.78, 0.72), line);
	} else if (pattern == 19) {
		// M3 sprint 5 (chapter 04, 3.1: "the painted walls are glimpsed, not seen"): the great halls' murals inside, registers
		// of small seated figures 0.45 m apart, in rows 0.55 m high between painted borders every five rows, on the slot's
		// dark green ground, their colours dulled by the lamps' soot; read in the wall's own plane so a figure keeps its
		// shape on every wall.
		vec3 t = normalize(vec3(-wnrm.z, 0.0, wnrm.x) + vec3(1e-4, 0.0, 0.0));
		vec2 uv = vec2(dot(wpos, t) / 0.45, wpos.y / 0.55);
		vec2 f = fract(uv) - 0.5;
		float r = hash21(floor(uv));
		vec3 body = r < 0.3 ? vec3(0.62, 0.17, 0.11) : r < 0.55 ? vec3(0.16, 0.33, 0.52) : r < 0.8 ? vec3(0.72, 0.52, 0.2) : vec3(0.18, 0.44, 0.28);
		col = col * (0.85 + 0.3 * n2);
		col = mix(col, vec3(0.72, 0.56, 0.26), step(length(f - vec2(0.0, 0.12)), 0.3) * 0.75);  // the halo
		col = mix(col, vec3(0.6, 0.2, 0.14), step(length((f - vec2(0.0, -0.33)) * vec2(0.6, 2.2)), 0.2));  // the lotus seat
		col = mix(col, body, step(length((f - vec2(0.0, -0.08)) * vec2(1.0, 0.8)), 0.24));  // the robe
		col = mix(col, vec3(0.78, 0.62, 0.42), step(length(f - vec2(0.0, 0.2)), 0.08));  // the face
		float band = step(fract(wpos.y / 2.75), 0.06);  // a border every five rows
		col = mix(col, vec3(0.52, 0.16, 0.1), band);
		col *= 0.62;  // the lamps' soot
	} else if (pattern == 12) {
		// Kit step K5 (chapter 03, 3.1): the poor house's thin, patchy wash over rubble. Stones in rough courses show
		// where the wash has worn thin, their joints dark; where it holds, the wash's own colour.
		vec2 uv = vec2(hz * 2.6, wpos.y * 3.3);
		float row = floor(uv.y);
		vec3 c = cells(vec2(uv.x + hash21(vec2(row, 3.1)) * 5.0, uv.y));
		vec3 stone = vec3(0.27, 0.25, 0.22) * (0.75 + 0.5 * c.y);
		float held = smoothstep(0.38, 0.62, n2 + (c.y - 0.5) * 0.35);
		col = mix(stone, col, held);
		col = mix(col, col * 0.55, (1.0 - smoothstep(0.02, 0.07, c.x)) * (1.0 - held));
	}
	return col;
}
