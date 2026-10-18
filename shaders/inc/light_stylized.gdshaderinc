// The stylized two-tone light (the draft's): soft band, cool tinted bounce in shadow, rim, stepped specular.
// Shared by every lit shader so buildings, terrain, people and water agree (plan chapter 11, 7.1).
// The including shader provides: shade_color (vec3), and the varyings or uniforms soft_v, rim_v, gloss_v.

#include "res://shaders/inc/light_reach.gdshaderinc"

void stylized_light(vec3 normal, vec3 light_dir, vec3 view, vec3 light_color, float attenuation, bool directional,
		vec3 shade, float soft_, float rim_, float gloss_, inout vec3 diffuse, inout vec3 specular) {
	float ndl = dot(normal, light_dir);
	float lit = smoothstep(0.0, soft_, ndl) * attenuation;
	vec3 direct = light_color * lit;
	vec3 bounce = light_color * shade * 0.16 * (1.0 - lit) * light_reach(directional, attenuation);  // (ISS-164)
	float r = pow(1.0 - clamp(dot(normal, view), 0.0, 1.0), 4.0) * rim_ * lit;
	diffuse += (direct + bounce + light_color * r) / PI;
	if (gloss_ > 0.0) {
		vec3 h = normalize(light_dir + view);
		float sp = pow(max(dot(normal, h), 0.0), 48.0);
		specular += light_color * smoothstep(0.3, 0.42, sp) * gloss_ * lit * 0.6;
	}
}
