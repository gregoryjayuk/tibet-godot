class_name PersonLook
## The person shader on a body, surface by surface (M1 sprint 5, step 4): the cloth's surfaces share one material (the
## vertex colour), and a surface the body build painted (its glTF material has a texture: the player's skin, eyes,
## brows and lashes) gets the person shader with that texture, or, for the alpha-cut cards of the brows and lashes,
## the two-sided cards shader. Replaces setting one material_override on the whole body, which dropped the paintings.

const PERSON := preload("res://characters/person.gdshader")
const CARDS := preload("res://characters/person_cards.gdshader")


## Every MeshInstance3D under `root`: `base` (a ShaderMaterial of the person shader) on its plain surfaces, a variant
## with the surface's own texture on its painted ones. Returns how many surfaces were painted.
static func apply(root: Node, base: ShaderMaterial) -> int:
	var painted := 0
	var made := {}
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		mi.material_override = null
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i) as BaseMaterial3D
			var tex: Texture2D = src.albedo_texture if src != null else null
			if tex == null:
				mi.set_surface_override_material(i, base)
				continue
			if not made.has(tex):
				var m := ShaderMaterial.new()
				m.shader = CARDS if src.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED else PERSON
				for p in ["shade_color", "soft", "rim"]:
					var v = base.get_shader_parameter(p)
					if v != null:
						m.set_shader_parameter(p, v)
				m.set_shader_parameter("albedo_tex", tex)
				made[tex] = m
			mi.set_surface_override_material(i, made[tex])
			painted += 1
	return painted
