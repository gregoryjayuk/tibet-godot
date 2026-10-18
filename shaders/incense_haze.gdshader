// The Tsokchen's incense haze (M3 sprint 6, step 3; plan chapter 08, V-26: "incense haze over the rows so the lantern's
// shafts show"; world/hall_day.gd): a thin density drifting slowly in a 3D noise over the rows, thinning to nothing at the
// volume's sides and under its top, so it has no edge. A fog shader: the valley's volumetric fog draws it, lit by the
// sky's ambient while the camera is in the hall (world/hall_day.gd INJECT): the hall's lamps add none to the fog (their
// light in its coarse grid showed as steps), and a fog volume's own EMISSION is stored too coarsely to give a faint warm
// glow (measured: 0.1 kept its red and lost its blue, 0.5 overflowed to white).
shader_type fog;

uniform float density : hint_range(0.0, 0.5) = 0.03;
uniform sampler3D noise_tex;
uniform vec3 drift = vec3(0.010, 0.003, 0.007);  // the noise's slow drift, per second
uniform vec3 tint : source_color = vec3(0.95, 0.82, 0.64);  // warm: the sky's blue ambient lights it

void fog() {
	float n = texture(noise_tex, UVW * vec3(1.6, 0.8, 1.6) + drift * TIME).r;
	float side = min(min(UVW.x, 1.0 - UVW.x), min(UVW.z, 1.0 - UVW.z));
	float edge = smoothstep(0.0, 0.12, side) * (1.0 - smoothstep(0.55, 1.0, UVW.y));
	DENSITY = density * (0.35 + 1.3 * n) * edge;
	ALBEDO = tint;
}
