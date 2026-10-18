// The VAT lookup (plan chapter 05, 12 step 11): the pose of one vertex from a baked texture (people2/stand_ins.py):
// rows of positions, then rows of normals, clip after clip; the vertex's column from its UV2.x. clip = (first row,
// frames, phase in frames at g 0, rate). Frames are interpolated, so a 15 fps bake moves smoothly.
// Shared by characters/vat.gdshader (posed by the instance transform) and characters/vat_orbit.gdshader (birds).

void vat_pose(sampler2D tex, float uvx, vec4 clip, float g, float fps, float nrow, out vec3 p, out vec3 n) {
	float frames = max(clip.y, 1.0);
	float t = g * fps * clip.w + clip.z;
	float f0 = mod(floor(t), frames);
	float f1 = mod(f0 + 1.0, frames);
	float a = fract(t);
	int x = int(uvx * float(textureSize(tex, 0).x));
	int r0 = int(clip.x + f0);
	int r1 = int(clip.x + f1);
	int nr = int(nrow);
	p = mix(texelFetch(tex, ivec2(x, r0), 0).xyz, texelFetch(tex, ivec2(x, r1), 0).xyz, a);
	n = normalize(mix(texelFetch(tex, ivec2(x, r0 + nr), 0).xyz, texelFetch(tex, ivec2(x, r1 + nr), 0).xyz, a));
}
