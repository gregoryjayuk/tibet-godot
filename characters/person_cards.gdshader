// The cards of a painted face (the brows and lashes; M1 sprint 5, step 4): person.gdshader's colour and light on
// both sides of a card, cut where the painting's alpha falls under a half (the glTF material's MASK).
shader_type spatial;
render_mode cull_disabled;

uniform vec3 shade_color : source_color = vec3(0.36, 0.44, 0.70);
uniform float soft = 0.1;
uniform float rim = 0.12;
uniform sampler2D albedo_tex : source_color, hint_default_white, filter_linear_mipmap;
instance uniform float tint = 1.0;

#include "res://shaders/inc/light_stylized.gdshaderinc"
#include "res://shaders/inc/horizon.gdshaderinc"

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 t = texture(albedo_tex, UV);
	ALBEDO = COLOR.rgb * tint * t.rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 3.5 / 16.0;
	SPECULAR = 0.0;
}

void light() {
	vec3 d = vec3(0.0);
	vec3 s = vec3(0.0);
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);
	stylized_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, shade_color, soft, rim, 0.0, d, s);
	DIFFUSE_LIGHT += d * ridge;
	SPECULAR_LIGHT += s * ridge;
}
