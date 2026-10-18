extends Node3D
## Washing hung to dry (IMP-023 (1); Greg's 1775, 7 Oct 2026: "the character running through laundry of monk robes,
## it's really cool, and the way the fabric moves makes it amazing"). About a third of the households have a line out,
## each its own, seeded by its name: most across their yard, along the front a metre and a half out between two poles,
## 1.9 m up, where the walker going along the row goes through it; a few on the roof between its front corners. On it
## what the household washed this week: a monk's maroon robes and saffron shirt where a son is in the monastery, a
## chuba, shirts, a striped apron, a blanket, a cloth, each a piece of its own size and colour, a little faded; a shut
## house has none. The pieces sway slow and heavy on the wind and part round the walker who pushes through them
## (shaders/laundry_mm.gdshader, the player's place in g_player). A few MultiMeshes per 128 m cell, no collision. Added
## by world/town.gd after the households.

const SHADER := preload("res://shaders/laundry_mm.gdshader")
const GENERIC := "res://data/town_generic.json"
const CELL := 128.0
const OUT := 1.45  ## the line's distance out from the front: inside every yard's level ground (tools/terrain/pads.py)
const HIGH := 1.9
const WOOD := "#5F3E28"
const CORD := "#D8D2C4"
## A piece: [kind, width, length down, colours (hex), pattern (0 plain, 1 apron stripes, 2 blanket bands), weight]
const PIECES := [["robe", 1.25, 1.05, ["#4E1414", "#5A1717", "#461212"], 0, 0],  # a monk's zen, folded over the line
		["shirt_monk", 0.7, 0.62, ["#C8892A", "#D19A35"], 0, 0],
		["chuba", 1.0, 1.15, ["#4A3428", "#3A3A44", "#2E3A5C", "#5C4A36"], 0, 4],
		["shirt", 0.62, 0.6, ["#E8E4D8", "#D9D2C2", "#B9C3C9"], 0, 5],
		["apron", 0.5, 0.62, ["#000000"], 1, 2],  # a married woman's pangden: its stripes are the shader's
		["blanket", 1.4, 1.05, ["#8C2F23", "#3F4F35", "#8A7A5E", "#2C3E66"], 2, 2],
		["cloth", 0.55, 0.45, ["#CDB98E", "#E3DDCF", "#7E2C22"], 0, 3]]

var counts := {"lines": 0, "pieces": 0, "robes": 0, "roofs": 0}  ## for the tests and the log
var per_house := {}  ## house -> [kinds on its line]
var tops: Array = []  ## every piece's top on its line, as drawn (a headless test cannot read a MultiMesh back)
var _cells := {}
var _cloth: ArrayMesh


func build(root: Node3D, households: Node = null) -> Dictionary:
	_cloth = _cloth_mesh()
	var recs := {}
	if FileAccess.file_exists(GENERIC):
		for h in JSON.parse_string(FileAccess.get_file_as_string(GENERIC))["houses"]:
			recs[String(h["id"])] = h
	for h in root.get_children():
		var name := String(h.name)
		if not recs.has(name) or not h is Node3D:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(name + ":laundry")
		if rng.randf() > 0.34:
			continue
		if households != null and bool(households.call("is_shut", name)):
			continue
		var fp: Array = recs[name]["footprint"]
		var xf := (h as Node3D).global_transform
		var along := xf.basis.x.normalized()
		var front := xf.basis.z.normalized()  # the kit's front, -y in Blender, is +z here
		var corners := (h as Node3D).find_children("SOCK_CORNER_*", "Node3D", true, false)
		var on_roof := rng.randf() < 0.2 and corners.size() >= 2
		var a: Vector3
		var b: Vector3
		if on_roof:  # between the two front corners of its roof, inset, at the height of a person over the roof
			var fr := corners.duplicate()
			fr.sort_custom(func(p, q): return (p as Node3D).global_position.dot(front) > (q as Node3D).global_position.dot(front))
			var c0 := (fr[0] as Node3D).global_position
			var c1 := (fr[1] as Node3D).global_position
			var mid := (c0 + c1) * 0.5
			var inset := (xf.origin - mid)
			inset.y = 0.0
			inset = inset.normalized() * 1.2
			a = c0.lerp(c1, 0.15) + inset + Vector3(0.0, 1.5, 0.0)
			b = c0.lerp(c1, 0.85) + inset + Vector3(0.0, 1.5, 0.0)
			counts["roofs"] += 1
		else:  # along the yard, before the front
			var half := float(fp[0]) / 2.0
			var length := rng.randf_range(3.2, minf(6.0, float(fp[0]) + 1.0))
			var shift := rng.randf_range(-half * 0.4, half * 0.4)
			var base := xf.origin + front * (float(fp[1]) / 2.0 + OUT + rng.randf_range(-0.15, 0.25)) + along * shift
			a = base - along * length / 2.0 + Vector3(0.0, HIGH, 0.0)
			b = base + along * length / 2.0 + Vector3(0.0, HIGH, 0.0)
			for e in [a, b]:  # its two poles
				_add("pole", Transform3D(Basis().scaled(Vector3(0.07, (e as Vector3).y - xf.origin.y + 0.1, 0.07)), Vector3(e.x, (xf.origin.y + e.y) * 0.5, e.z)), _col(WOOD, rng.randf_range(-0.1, 0.1)))
		_line(name, a, b, rng)
	_commit()
	return counts


func _line(house: String, a: Vector3, b: Vector3, rng: RandomNumberGenerator) -> void:
	var d := b - a
	var L := d.length()
	var x := d / L
	var sag := 0.03 * L
	var monk := rng.randf() < 0.3  # a son in the monastery: his robes home to wash
	var kinds: Array = []
	var t := rng.randf_range(0.05, 0.3)
	while t < L - 0.3:
		var pick: Array = PIECES[0] if monk and rng.randf() < 0.45 else _pick(rng, monk)
		var w: float = float(pick[1]) * rng.randf_range(0.9, 1.1)
		if t + w > L - 0.1:
			break
		var mid := t + w / 2.0
		var f := mid / L
		var top := a + x * mid - Vector3(0.0, sag * 4.0 * f * (1.0 - f), 0.0)
		var face := x.cross(Vector3.UP).normalized()
		var hgt: float = float(pick[2]) * rng.randf_range(0.9, 1.1)
		var basis := Basis(x * w, Vector3.UP * hgt, face)
		var cols: Array = pick[3]
		var c := _col(String(cols[rng.randi_range(0, cols.size() - 1)]), rng.randf_range(-0.12, 0.08))
		c.a = float(pick[4]) + rng.randf() * 0.999
		_add("cloth", Transform3D(basis, top), c)
		tops.append(top)
		kinds.append(String(pick[0]))
		counts["pieces"] += 1
		counts["robes"] += int(pick[0] == "robe")
		t += w + rng.randf_range(0.04, 0.35)
	# the line itself, a cord sagging in two spans
	var m := a.lerp(b, 0.5) - Vector3(0.0, sag, 0.0)
	for seg in [[a, m], [m, b]]:
		var p0: Vector3 = seg[0]
		var p1: Vector3 = seg[1]
		var u := p1 - p0
		var side := u.cross(Vector3.UP).normalized()
		_add("cord", Transform3D(Basis(side * 0.012, u, u.normalized().cross(side).normalized() * 0.012), (p0 + p1) * 0.5), _col(CORD, -0.2))
	per_house[house] = kinds
	counts["lines"] += 1
	if OS.get_environment("LAUNDRY_LOG") != "":
		print("laundry: %s from (%.1f, %.1f, %.1f) to (%.1f, %.1f, %.1f): %s" % [house, a.x, -a.z, a.y + 2662.0, b.x, -b.z, b.y + 2662.0, ", ".join(PackedStringArray(kinds))])


func _pick(rng: RandomNumberGenerator, monk: bool) -> Array:
	var total := 0
	for p in PIECES:
		total += int(p[5]) + (2 if monk and p[0] == "shirt_monk" else 0)
	var r := rng.randi_range(1, total)
	for p in PIECES:
		r -= int(p[5]) + (2 if monk and p[0] == "shirt_monk" else 0)
		if r <= 0:
			return p
	return PIECES[3]


func _col(hexc: String, shade: float) -> Color:
	var c := Color(hexc).srgb_to_linear()
	c = c.lightened(shade) if shade > 0.0 else c.darkened(-shade)
	return Color(c.r, c.g, c.b, 0.0)


func _add(kind: String, xf: Transform3D, c: Color) -> void:
	var key := "%d|%d" % [floori(xf.origin.x / CELL), floori(xf.origin.z / CELL)]
	if not _cells.has(key):
		_cells[key] = {}
	var cell: Dictionary = _cells[key]
	if not cell.has(kind):
		cell[kind] = []
	(cell[kind] as Array).append([xf, c])


func _commit() -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 5
	cyl.rings = 1
	var meshes := {"cloth": _cloth, "cord": cyl, "pole": cyl}
	for key in _cells:
		for kind in _cells[key]:
			var list: Array = _cells[key][kind]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			mm.mesh = meshes[kind]
			mm.instance_count = list.size()
			for i in list.size():
				mm.set_instance_transform(i, list[i][0])
				mm.set_instance_custom_data(i, list[i][1])
			var mi := MultiMeshInstance3D.new()
			mi.name = "%s_%s" % [kind, String(key).replace("|", "_")]
			mi.multimesh = mm
			var mat := ShaderMaterial.new()
			mat.shader = SHADER
			mat.set_shader_parameter("cloth", 1.0 if kind == "cloth" else 0.0)
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if kind != "cord" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_end = 300.0
			add_child(mi)


## A hanging cloth: a 5 x 7 grid, 1 wide along x (-0.5..0.5) and 1 down -y from its top on the line; vertex colour red
## = how far down (0 pinned to the line, 1 the hem); UV across and down, for its pattern.
func _cloth_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nc := 5
	var nr := 7
	var v := []
	for r in nr:
		for c in nc:
			v.append(Vector3(-0.5 + c / float(nc - 1), -r / float(nr - 1), 0.0))
	for r in nr - 1:
		for c in nc - 1:
			var i := r * nc + c
			for q in [i, i + nc, i + 1, i + 1, i + nc, i + nc + 1]:
				var p: Vector3 = v[q]
				st.set_color(Color(-p.y, 0.0, 0.0))
				st.set_uv(Vector2(p.x + 0.5, -p.y))
				st.set_normal(Vector3.BACK)
				st.add_vertex(p)
	return st.commit()
