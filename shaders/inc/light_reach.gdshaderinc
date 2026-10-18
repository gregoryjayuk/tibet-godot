// How much of a light's unattenuated fill (a shadow side's bounce, a cloth's or a leaf's floor of light) a point takes:
// all of the sun's; a lamp's or a fire's only within its reach, fading over its last stretch (ISS-164). The clustered
// renderer runs light() for every pixel of the screen tiles a light's sphere touches, so a term not multiplied by
// ATTENUATION lit whole tiles: square patches round the camp's fires seen from afar. (No lamp casts a shadow, so its
// ATTENUATION is its falloff alone.) Included by light_stylized.gdshaderinc and horizon.gdshaderinc, once.
#ifndef LIGHT_REACH_INC
#define LIGHT_REACH_INC
float light_reach(bool directional, float attenuation) {
	return directional ? 1.0 : smoothstep(0.0, 0.05, attenuation);
}
#endif
