// Skinned people and animals on the hero and near tiers (plan chapter 05, 13; chapter 11, 7.1): the albedo is the
// vertex colour the bodies carry (people2/body.py, stand_ins.py) times an optional texture (albedo_tex, white when
// unset): the player's face, hands and eyes are painted (M1 sprint 5, step 4; characters/person_look.gd gives each
// surface its own), the cloth is vertex colour. Lit by the stylized light every lit shader shares. Line group 3
// (characters) goes into ROUGHNESS for the ink pass (chapter 09, 16.4). The VAT tiers use vat.gdshader with the same
// colour and light, so a hand-over does not pop. Back faces are culled: every garment face must face out.
shader_type spatial;
render_mode cull_back;

uniform sampler2D albedo_tex : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;

uniform vec3 shade_color : source_color = vec3(0.36, 0.44, 0.70);
uniform float soft = 0.1;
uniform float rim = 0.12;
instance uniform float tint = 1.0;  // a small tone shift per person (0.94-1.06), the same number the VAT tier gets as its instance colour
instance uniform float indoor = 0.0;  // 1 in a room (sprint 7): no sky's ambient, and the sun gives only what reaches through a door
// 1 with the boots off in a hall (M3 sprint 6, step 2; world/boots.gd): the boots, marked by their vertex colour's alpha of
// 0.5 (people2/garments.py), drawn as the dark felt stockings worn under them
instance uniform float bare = 0.0;
const vec3 STOCKINGS = vec3(0.042, 0.033, 0.025);  // undyed dark wool, #3A332C

#include "res://shaders/inc/light_stylized.gdshaderinc"
#include "res://shaders/inc/horizon.gdshaderinc"

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 cloth = (bare > 0.5 && COLOR.a < 0.75) ? STOCKINGS : COLOR.rgb;
	ALBEDO = cloth * tint * texture(albedo_tex, UV).rgb;
	ROUGHNESS = 3.5 / 16.0;
	SPECULAR = 0.0;
	AO = 1.0 - 0.92 * indoor;  // a room hides the sky, as the kit's baked occlusion does for its walls
	AO_LIGHT_AFFECT = 0.0;
}

void light() {
	vec3 d = vec3(0.0);
	vec3 s = vec3(0.0);
	float ridge = horizon_light_view(wpos, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, -1000.0);  // art step A8: the terrain's shadow
	// indoors the sun's shade fill (the sky's stand-in) and its rim go; a room's own lights keep theirs
	float sky = LIGHT_IS_DIRECTIONAL ? 1.0 - indoor : 1.0;
	stylized_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, shade_color * sky, soft, rim * sky, 0.0, d, s);
	DIFFUSE_LIGHT += d * ridge;
	SPECULAR_LIGHT += s * ridge;
}
