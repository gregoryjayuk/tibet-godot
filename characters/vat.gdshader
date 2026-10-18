// Vertex-animation-texture crowds (plan chapter 05, 12 step 11 and 13; roadmap RT-13): every mid- and far-tier person,
// animal and bird is one MultiMesh instance whose vertices come from a baked texture (people2/stand_ins.py): rows of
// positions, then rows of normals, clip after clip, one column per vertex (its UV2.x). Frames are interpolated, so a
// 15 fps bake moves smoothly. Per instance, INSTANCE_CUSTOM = (first row of the clip, frames in it, the phase in frames
// at g_time 0, the rate). A skeletal person handed down to this tier keeps its animation clock: both evaluate
// frame = g_time * fps * rate + phase (characters/crowd.gd). The MultiMesh uses instance colours for the tint.
shader_type spatial;
render_mode cull_back;

global uniform float g_time;
uniform sampler2D vat : filter_nearest, repeat_disable;
uniform float vat_fps = 15.0;
uniform float normal_row = 72.0;
uniform vec3 shade_color : source_color = vec3(0.36, 0.44, 0.70);
uniform float soft = 0.1;
uniform float rim = 0.12;
uniform float line_group = 3.0;  // 3 characters; animals too

#include "res://shaders/inc/light_stylized.gdshaderinc"
#include "res://shaders/inc/vat.gdshaderinc"
#include "res://shaders/inc/horizon.gdshaderinc"

varying vec3 wpos;

void vertex() {
	vec3 p;
	vec3 n;
	vat_pose(vat, UV2.x, INSTANCE_CUSTOM, g_time, vat_fps, normal_row, p, n);
	VERTEX = p;
	NORMAL = n;
	wpos = (MODEL_MATRIX * vec4(p, 1.0)).xyz;
}

void fragment() {
	ALBEDO = COLOR.rgb;  // the vertex colour times the instance colour, which carries the person's tint
	ROUGHNESS = (line_group + 0.5) / 16.0;
	SPECULAR = 0.0;
}

void light() {
	vec3 d = vec3(0.0);
	vec3 s = vec3(0.0);
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);  // art step A8: the terrain's shadow
	stylized_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, shade_color, soft, rim, 0.0, d, s);
	DIFFUSE_LIGHT += d * ridge;
	SPECULAR_LIGHT += s * ridge;
}
