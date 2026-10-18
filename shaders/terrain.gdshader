// The valley's ground on Terrain3D (plan chapter 11, 8.4; chapter 09, 7 and 13.4; roadmap RT-12, spike S3).
// Based on Terrain3D's minimum shader (addons/terrain_3d/extras/shaders/minimum.gdshader, MIT, copyright 2023-2026
// Cory Petkovsek, Roope Palmroos and contributors): its clipmap vertex code, holes and normals are kept as they are;
// the texturing is replaced by the town's look: colour by slope, aspect and altitude (inc/terrain_color.gdshaderinc,
// shared with the ring mesh) and the stylized light every lit shader uses. Since terrain pass 8 (sprint 3, step 6) the
// control map carries the ground's class (tools/terrain/control.py): wild ground keeps those rules; bare earth, barley
// and buckwheat stubble on their benches and stone flags are coloured here, blended between the four texels. Line group 2 (terrain) goes into ROUGHNESS
// for the ink pass (chapter 09, 16.4); SPECULAR is 0 so the sky's reflections stay off.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,skip_vertex_transform;

// Defined Constants
#define SKIP_PASS 0
#define VERTEX_PASS 1
#define FRAGMENT_PASS 2

#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
    #define fma(a, b, c) ((a) * (b) + (c))
    #define dFdxCoarse(a) dFdx(a)
    #define dFdyCoarse(a) dFdy(a)
#endif

// Private uniforms
// Commented uniforms aren't needed for this shader, but are available for your own needs.
uniform vec3 _camera_pos = vec3(0.f);
uniform float _mesh_size = 48.f;
uniform uint _background_mode = 1u; // NONE = 0, FLAT = 1, NOISE = 2
uniform uint _mouse_layer = 0x80000000u; // Layer 32
uniform float _vertex_spacing = 1.0;
uniform float _vertex_density = 1.0; // = 1/_vertex_spacing
uniform float _region_size = 1024.0;
uniform float _region_texel_size = 0.0009765625; // = 1/1024
uniform int _region_map_size = 32;
uniform int _region_map[1024];
//uniform vec2 _region_locations[1024];
//uniform float _texture_uv_scale_array[32];
//uniform float _texture_detile_array[32];
//uniform vec4 _texture_color_array[32];
uniform highp sampler2DArray _height_maps : repeat_disable;
uniform highp sampler2DArray _control_maps : repeat_disable;
//uniform highp sampler2DArray _color_maps : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
//uniform highp sampler2DArray _texture_array_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
//uniform highp sampler2DArray _texture_array_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;

// Public Uniforms
uniform bool flat_terrain_normals = false;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 shade_color : source_color = vec3(0.36, 0.44, 0.70);
uniform float soft = 0.25;  // ramp R6 says 0.12 (chapter 09, 5); 0.25 for the unsculpted 30 m relief in spike S3, whose smooth bumps turn into blue blobs on backlit slopes at 0.12
uniform float rim = 0.04;

#include "res://shaders/inc/light_stylized.gdshaderinc"
#include "res://shaders/inc/terrain_color.gdshaderinc"
#include "res://shaders/inc/horizon.gdshaderinc"

// Varyings & Types
// Some are required for editor functions
varying float v_vertex_xz_dist;
varying vec3 v_vertex;

////////////////////////
// Vertex
////////////////////////

// Takes in world space XZ (UV) coordinates & search depth (only applicable for background mode none)
// Returns ivec3 with:
// XY: (0 to _region_size - 1) coordinates within a region
// Z: layer index used for texturearrays, -1 if not in a region
ivec3 get_index_coord(const vec2 uv, const int search) {
	vec2 r_uv = round(uv);
	vec2 o_uv = mod(r_uv,_region_size);
	ivec2 pos;
	int bounds, layer_index = -1;
	for (int i = -1; i < clamp(search, SKIP_PASS, FRAGMENT_PASS); i++) {
		if ((layer_index == -1 && _background_mode == 0u ) || i < 0) {
			r_uv -= i == -1 ? vec2(0.0) : vec2(float(o_uv.x <= o_uv.y), float(o_uv.y <= o_uv.x));
			pos = ivec2(floor((r_uv) * _region_texel_size)) + (_region_map_size / 2);
			bounds = int(uint(pos.x | pos.y) < uint(_region_map_size));
			layer_index = (_region_map[ pos.y * _region_map_size + pos.x ] * bounds - 1);
		}
	}
	return ivec3(ivec2(mod(r_uv,_region_size)), layer_index);
}

void vertex() {
	// Get vertex of flat plane in world coordinates and set world UV
	v_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Camera distance to vertex on flat plane
	v_vertex_xz_dist = length(v_vertex.xz - _camera_pos.xz);

	// Geomorph vertex, set end and start for linear height interpolate
	float scale = MODEL_MATRIX[0][0];
	float vertex_lerp = smoothstep(0.55, 0.95, (v_vertex_xz_dist / scale - _mesh_size - 4.0) / (_mesh_size - 2.0));
	vec2 v_fract = fract(VERTEX.xz * 0.5) * 2.0;
	// For LOD0 morph from a regular grid to an alternating grid to align with LOD1+
	vec2 shift = (scale < _vertex_spacing + 1e-6) ? // LOD0 or not
		// Shift from regular to symetric
		mix(v_fract, vec2(v_fract.x, -v_fract.y),
			round(fract(round(mod(v_vertex.z * _vertex_density, 4.0)) *
			round(mod(v_vertex.x * _vertex_density, 4.0)) * 0.25))
			) :
		// Symetric shift
		v_fract * round((fract(v_vertex.xz * 0.25 / scale) - 0.5) * 4.0);
	vec2 start_pos = v_vertex.xz * _vertex_density;
	vec2 end_pos = (v_vertex.xz - shift * scale) * _vertex_density;
	v_vertex.xz -= shift * scale * vertex_lerp;

	// UV coordinates in world space. Values are 0 to _region_size within regions
	UV = v_vertex.xz * _vertex_density;

	// UV coordinates in region space + texel offset. Values are 0 to 1 within regions
	UV2 = fma(UV, vec2(_region_texel_size), vec2(0.5 * _region_texel_size));

	// Discard vertices for Holes. 1 lookup
	ivec3 v_region = get_index_coord(start_pos, VERTEX_PASS);
	uint control = floatBitsToUint(texelFetch(_control_maps, v_region, 0)).r;
	bool hole = bool(control >>2u & 0x1u);

	// Show holes to all cameras except mouse camera (on exactly 1 layer)
	if ( !(CAMERA_VISIBLE_LAYERS == _mouse_layer) &&
			(hole || (_background_mode == 0u && v_region.z < 0))) {
		v_vertex.x = 0. / 0.;
	} else {
		// Interpolate Geomorph Start & End, set height. 2 Lookups.
		ivec3 uv_a = get_index_coord(start_pos, VERTEX_PASS);
		ivec3 uv_b = get_index_coord(end_pos, VERTEX_PASS);
		float h = mix(texelFetch(_height_maps, uv_a, 0).r, texelFetch(_height_maps, uv_b, 0).r, vertex_lerp);
		v_vertex.y = h;
	}

	// Convert model space to view space w/ skip_vertex_transform render mode
	VERTEX = (VIEW_MATRIX * vec4(v_vertex, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
	TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}

////////////////////////
// Fragment
////////////////////////

#include "res://shaders/inc/patterns.gdshaderinc"

uniform vec3 c_barley : source_color = vec3(0.784, 0.682, 0.447);  // barley stubble #C8AE72
uniform vec3 c_buckwheat : source_color = vec3(0.608, 0.227, 0.180);  // red buckwheat stubble #9B3A2E (chapter 02, 2.4)
uniform vec3 c_flag : source_color = vec3(0.639, 0.584, 0.506);  // flagstones #A39581, palette slot 10
uniform vec3 c_trodden : source_color = vec3(0.70, 0.61, 0.48);

// A class's colour (terrain pass 8): 0 wild (the rules' colour, passed in), 1 bare earth, 2 barley and 3 buckwheat
// stubble on benches 2.4 m high along the contour with an earth riser at each, 5 stone flags, 6 Tödé's fields: strips
// three benches deep and about 35 m wide, their edges wandering, a third of them buckwheat, chosen here pixel by pixel.
vec3 ground_color(uint id, vec3 wild, vec3 wpos, float dist) {
	if (id == 6u) {
		float elev = wpos.y + TERRAIN_DATUM;
		float band = floor((elev + (texture(noise_tex, wpos.xz * 0.008).r - 0.5) * 1.5) / 7.2);
		float col_ = floor((wpos.x + (texture(noise_tex, wpos.xz * 0.011 + 0.3).r - 0.5) * 8.0) / 35.0 + 0.37 * band);
		id = hash21(vec2(col_, band) * 0.173) < 0.35 ? 3u : 2u;
	}
	if (id == 1u) {
		float nt = texture(noise_tex, wpos.xz * 0.05).r;
		return mix(c_earth, c_trodden, smoothstep(0.35, 0.75, nt)) * (0.92 + 0.16 * texture(noise_tex, wpos.xz * 0.4).r);
	}
	if (id == 2u || id == 3u) {
		float elev = wpos.y + TERRAIN_DATUM;
		float wob = (texture(noise_tex, wpos.xz * 0.012).r - 0.5) * 2.0;
		float b = fract((elev + wob) / 2.4);
		vec3 stub = (id == 2u ? c_barley : c_buckwheat) * (0.86 + 0.28 * texture(noise_tex, wpos.xz * 0.02).r);
		float riser = 1.0 - smoothstep(0.02, 0.13, b);
		float rows = step(0.5, fract(elev / 0.09)) * (1.0 - smoothstep(20.0, 45.0, dist));
		return mix(stub * (0.95 + 0.08 * rows), c_earth * 0.85, riser * 0.8);
	}
	if (id == 5u) {
		// The paved ground (Tsongra's square), varied and worn as the kit's flagstones (shaders/inc/patterns.gdshaderinc
		// pattern 1; chapter 09, 17, PC-13 and PC-14; ISS-106): warped cells, slabs and cobbles, slate to ochre, relaid and
		// new stones, broad polished bands with dust in their joints.
		vec2 q = wpos.xz;
		q += (vec2(texture(noise_tex, q * 0.021).r, texture(noise_tex, q * 0.021 + vec2(0.37, 0.53)).r) - 0.5) * 2.2;
		// slabs in some patches, cobbles in others, a joint along their seam (ISS-140: a scale varying through space and
		// multiplying the town's coordinates squeezed the stones into contour bands away from its origin)
		float zone = texture(noise_tex, q * 0.013 + vec2(0.61, 0.29)).r;
		vec3 c = zone > 0.5 ? cells(q * 1.05) : cells(q * 1.6);
		c.x = min(c.x, abs(zone - 0.5) * 6.0);
		float h = c.y;
		vec3 tone = mix(vec3(0.94, 0.97, 1.03), vec3(1.06, 1.0, 0.9), fract(h * 7.13));
		float v = 0.82 + 0.32 * fract(h * 3.71);
		v *= h < 0.1 ? 0.8 : (h > 0.94 ? 1.12 : 1.0);
		vec3 stone = c_flag * tone * v;
		float wear = smoothstep(0.45, 0.75, texture(noise_tex, wpos.xz * 0.008 + vec2(0.2, 0.7)).r);
		stone *= 1.0 + 0.05 * wear;
		return mix(stone * mix(0.6, 0.82, wear), stone, smoothstep(0.02, 0.07 + 0.03 * wear, c.x));
	}
	return wild;
}

void fragment() {
	// Recover UVs
	vec2 uv = UV;
	//vec2 uv2 = UV2;

	// Lookup offsets, ID and blend weight
	const vec3 offsets = vec3(0, 1, 2);
	vec2 index_id = floor(uv);
	vec2 weight = fract(uv);
	vec2 invert = 1.0 - weight;
	vec4 weights = vec4(
		invert.x * weight.y, // 0
		weight.x * weight.y, // 1
		weight.x * invert.y, // 2
		invert.x * invert.y  // 3
	);

	vec3 base_ddx = dFdxCoarse(v_vertex);
	vec3 base_ddy = dFdyCoarse(v_vertex);
	//vec4 base_derivatives = vec4(base_ddx.xz, base_ddy.xz);
	// Calculate the effective mipmap for regionspace, and if less than 0,
	// skip all extra lookups required for bilinear blend.
	float region_mip = log2(max(length(base_ddx.xz), length(base_ddy.xz)) * _vertex_density);
	bool bilerp = region_mip < 0.0;

	ivec3 index[4];
	// control map lookups, used for some normal lookups as well
	index[0] = get_index_coord(index_id + offsets.xy, FRAGMENT_PASS);
	index[1] = get_index_coord(index_id + offsets.yy, FRAGMENT_PASS);
	index[2] = get_index_coord(index_id + offsets.yx, FRAGMENT_PASS);
	index[3] = get_index_coord(index_id + offsets.xx, FRAGMENT_PASS);

	// Terrain normals
	vec3 index_normal[4];
	float h[4];
	// allows additional derivatives, eg world noise, brush previews etc
	float u = 0.0;
	float v = 0.0;

	// Re-use index[] for the first lookups, skipping some math. 3 lookups
	h[3] = texelFetch(_height_maps, index[3], 0).r; // 0 (0,0)
	h[2] = texelFetch(_height_maps, index[2], 0).r; // 1 (1,0)
	h[0] = texelFetch(_height_maps, index[0], 0).r; // 2 (0,1)
	index_normal[3] = normalize(vec3(h[3] - h[2] + u, _vertex_spacing, h[3] - h[0] + v));

	// Set flat world normal - overriden if bilerp is true
	vec3 w_normal = index_normal[3];

	// Branching smooth normals must be done seperatley for correct normals at all 4 index ids
	if (bilerp) {
		// 5 lookups
		// Fetch the additional required height values for smooth normals
		h[1] = texelFetch(_height_maps, index[1], 0).r; // 3 (1,1)
		float h_4 = texelFetch(_height_maps, get_index_coord(index_id + offsets.yz, FRAGMENT_PASS), 0).r; // 4 (1,2)
		float h_5 = texelFetch(_height_maps, get_index_coord(index_id + offsets.zy, FRAGMENT_PASS), 0).r; // 5 (2,1)
		float h_6 = texelFetch(_height_maps, get_index_coord(index_id + offsets.zx, FRAGMENT_PASS), 0).r; // 6 (2,0)
		float h_7 = texelFetch(_height_maps, get_index_coord(index_id + offsets.xz, FRAGMENT_PASS), 0).r; // 7 (0,2)

		// Calculate the normal for the remaining index ids.
		index_normal[0] = normalize(vec3(h[0] - h[1] + u, _vertex_spacing, h[0] - h_7 + v));
		index_normal[1] = normalize(vec3(h[1] - h_5 + u, _vertex_spacing, h[1] - h_4 + v));
		index_normal[2] = normalize(vec3(h[2] - h_6 + u, _vertex_spacing, h[2] - h[1] + v));

		// Set interpolated world normal
		w_normal =
			index_normal[0] * weights[0] +
			index_normal[1] * weights[1] +
			index_normal[2] * weights[2] +
			index_normal[3] * weights[3] ;
	}

	// Apply terrain normals
	vec3 w_tangent = normalize(cross(w_normal, vec3(0.0, 0.0, 1.0)));
	vec3 w_binormal = normalize(cross(w_normal, w_tangent));
	NORMAL = mat3(VIEW_MATRIX) * w_normal;
	TANGENT = mat3(VIEW_MATRIX) * w_tangent;
	BINORMAL = mat3(VIEW_MATRIX) * w_binormal;

	if (flat_terrain_normals) {
		NORMAL = normalize(cross(dFdyCoarse(VERTEX),dFdxCoarse(VERTEX)));
		TANGENT = normalize(cross(NORMAL, VIEW_MATRIX[2].xyz));
		BINORMAL = normalize(cross(NORMAL, TANGENT));
	}

	vec3 wild = terrain_color(v_vertex, flat_terrain_normals ? normalize(cross(dFdyCoarse(v_vertex), dFdxCoarse(v_vertex))) : w_normal, v_vertex_xz_dist);
	vec3 ground = vec3(0.0);
	float trod = 0.0;  // the town's own ground, walked: its snow trodden
	for (int k = 0; k < 4; k++) {  // the ground's class at the four texels round the fragment, blended as the heights are
		uint id = floatBitsToUint(texelFetch(_control_maps, index[k], 0).r) >> 27u & 0x1Fu;
		ground += weights[k] * ground_color(id, wild, v_vertex, v_vertex_xz_dist);
		trod += weights[k] * ((id == 1u || id == 5u) ? 1.0 : 0.0);
	}
	vec3 sn_n = flat_terrain_normals ? normalize(cross(dFdyCoarse(v_vertex), dFdxCoarse(v_vertex))) : w_normal;
	float snow = terrain_snow(v_vertex, sn_n);
	snow *= 1.0 - trod * 0.55 * smoothstep(0.3, 0.7, texture(noise_tex, v_vertex.xz * 0.35).r);  // the lanes' and yards' snow trodden to the earth in places
	ALBEDO = mix(ground, c_snow, snow);
	ROUGHNESS = 2.5 / 16.0;  // line group 2: terrain, creases only
	SPECULAR = 0.0;
}

void light() {
	vec3 d = vec3(0.0);
	vec3 s = vec3(0.0);
	float ridge = horizon_light_view(v_vertex, LIGHT, INV_VIEW_MATRIX, LIGHT_IS_DIRECTIONAL, 0.0);  // art step A8: the terrain's shadow
	stylized_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, LIGHT_IS_DIRECTIONAL, shade_color, soft, rim, 0.0, d, s);
	DIFFUSE_LIGHT += d * ridge;
	SPECULAR_LIGHT += s * ridge;
}
