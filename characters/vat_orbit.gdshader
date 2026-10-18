// Birds on the wing (roadmap RT-13, spike S5; chapter 06's 300 birds): VAT figures that circle without any script.
// Each instance's transform carries its orbit instead of a pose: the origin is the ring's centre, column 0 is (radius,
// angular speed in rad/s with its sign the direction, phase), column 1 is (the height of the bob, 0, 0). The shader
// places, turns and animates the bird from g_time, so 300 birds cost the main thread nothing after set-up
// (animals/herds.gd). skip_vertex_transform: the odd "transform" is never applied as one.
shader_type spatial;
render_mode cull_back, skip_vertex_transform;

global uniform float g_time;
uniform sampler2D vat : filter_nearest, repeat_disable;
uniform float vat_fps = 30.0;
uniform float normal_row = 36.0;
uniform vec3 shade_color : source_color = vec3(0.36, 0.44, 0.70);
uniform float soft = 0.1;
uniform float rim = 0.12;

#include "res://shaders/inc/light_stylized.gdshaderinc"
#include "res://shaders/inc/vat.gdshaderinc"
#include "res://shaders/inc/horizon.gdshaderinc"

varying vec3 wpos;

void vertex() {
	vec3 centre = MODEL_MATRIX[3].xyz;
	float r = MODEL_MATRIX[0].x;
	float w = MODEL_MATRIX[0].y;
	float ph = MODEL_MATRIX[0].z;
	float bob = MODEL_MATRIX[1].x;
	float ang = g_time * w + ph;
	vec3 off = vec3(cos(ang) * r, sin(ang * 2.0 + ph) * bob, sin(ang) * r);
	float yaw = atan(-sin(ang) * sign(w), cos(ang) * sign(w));
	mat3 rot = mat3(vec3(cos(yaw), 0.0, -sin(yaw)), vec3(0.0, 1.0, 0.0), vec3(sin(yaw), 0.0, cos(yaw)));
	vec3 p;
	vec3 n;
	vat_pose(vat, UV2.x, INSTANCE_CUSTOM, g_time, vat_fps, normal_row, p, n);
	wpos = centre + off + rot * p;
	VERTEX = (VIEW_MATRIX * vec4(wpos, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(rot * n, 0.0)).xyz);
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 3.5 / 16.0;
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
