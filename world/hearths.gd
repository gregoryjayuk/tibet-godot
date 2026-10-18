extends Node3D
## The hearths' smoke (plan chapter 03, 14.4: KITCHEN, "the soot fan, and later the smoke"; M1 sprint 8, step 2: "hearth
## smoke at the cooking hours, house by house"): a thin blue-grey thread out of each kitchen's window (a poor house's
## door: "the smoke finds the door too") at the household's own hours: the morning fire from about six for the tea, the
## midday meal in two houses of three, the evening meal in all, a thin thread all day in a third of them where the tea
## is kept warm (shaders/hearth_smoke.gdshader). Each house seeded by its name: its hours, how strong, how high; none
## from a house left empty (world/flags.gd's "left") and none from a few cold hearths. One MultiMesh, added by
## world/town.gd after the flags. Kit types with no KITCHEN socket (the log houses, the village houses) have none yet.

const SHADER := preload("res://shaders/hearth_smoke.gdshader")
const PUFFS := 20  ## overlapping puffs a thread
const COLD := 0.06  ## the share of hearths with no smoke at all (the household away, cooking at a neighbour's)
const JAKHANG := "MON-12"  ## Dungkar Gönpa's kitchen (chapter 03, 6.7): smoke pours from its lantern at the morning and midday tea

var mat: ShaderMaterial
var smoke: MultiMeshInstance3D
var hearths: Array = []  ## [house name, its hours {morning, noon, evening, kept, strength}, its transform] of each thread, in instance order
var cold: Array = []  ## the houses whose hearth is cold, or left


## Builds the threads for every KITCHEN socket under `root` (the town); `flags` (world/flags.gd, built) for its left
## houses, `households` (world/households.gd, built) for its shut ones. Returns how many.
func build(root: Node, flags: Node = null, households: Node = null) -> int:
	var left := {}
	if flags != null:
		var per: Dictionary = flags.get("per_house")
		for h in per:
			if String((per[h] as Array)[0]) == "left":
				left[h] = true
	var socks := root.find_children("SOCK_KITCHEN_*", "Node3D", true, false)
	var xfs: Array = []
	var data: Array = []
	for s in socks:
		var house := _house(s as Node3D, root)
		if left.has(house) or (households != null and households.call("is_shut", house)):  # left, or shut (world/households.gd)
			cold.append(house)
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(house + ":hearth")
		if house != JAKHANG and rng.randf() < COLD:
			cold.append(house)
			continue
		var n := s as Node3D
		var out := n.global_basis.z
		out.y = 0.0
		out = out.normalized() if out.length() > 0.01 else Vector3.FORWARD
		var b := Basis(out, Vector3.UP, out.cross(Vector3.UP))
		xfs.append(Transform3D(b, n.global_position))
		# the household's hours (minutes of the day): the morning fire lit and out, the midday fire (two in three), the
		# evening fire lit and out, and in a third of the houses a thread all day
		var h := {"morning": [rng.randf_range(345.0, 395.0), rng.randf_range(475.0, 520.0)],
				"noon": rng.randf_range(655.0, 715.0) if rng.randf() < 0.65 else -1.0,
				"evening": [rng.randf_range(1035.0, 1095.0), rng.randf_range(1165.0, 1240.0)],
				"kept": rng.randf() < 0.35, "strength": rng.randf_range(0.5, 1.0)}
		var phase := rng.randf()
		var tall := rng.randf_range(9.0, 20.0)
		if house == JAKHANG:  # the assembly's tea from five, the midday tea for the whole house at eleven, no evening fire; heavy and tall
			h = {"morning": [300.0, 470.0], "noon": 660.0, "evening": [1020.0, 1020.0], "kept": false, "strength": 1.0}
			tall = 26.0
		data.append([Color(phase, float(h["strength"]) * (-1.0 if h["kept"] else 1.0), tall, float(h["morning"][1])),
				Color(float(h["morning"][0]) / 1440.0, maxf(float(h["noon"]), 0.0) / 1440.0, float(h["evening"][0]) / 1440.0, float(h["evening"][1]) / 1440.0)])
		hearths.append([house, h, xfs[xfs.size() - 1]])
	if xfs.is_empty():
		return 0
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.noise = noise
	mat.set_shader_parameter("noise_tex", tex)
	var mesh := _puffs()
	mesh.surface_set_material(0, mat)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.use_colors = true  # the hours; the puffs' mesh has no colours, so the shader's COLOR is the instance's alone
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_custom_data(i, data[i][0])
		mm.set_instance_color(i, data[i][1])
	smoke = MultiMeshInstance3D.new()
	smoke.name = "HearthSmoke"
	smoke.multimesh = mm
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(smoke)
	_process(0.0)
	return xfs.size()


## The thread's puffs: PUFFS quads, each quad's place in the thread in its vertices' z (the shader reads it).
static func _puffs() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	for k in PUFFS:
		var b := v.size()
		for c in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
			v.append(Vector3(c.x - 0.5, c.y - 0.5, float(k) / PUFFS))
			uv.append(c)
		idx.append_array([b, b + 1, b + 2, b, b + 2, b + 3])
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-8.0, -1.0, -8.0), Vector3(16.0, 20.0, 16.0))  # the shader moves the puffs
	return mesh


## The building a socket belongs to: its ancestor that is a child of the town's root (named by its record).
static func _house(n: Node3D, root: Node) -> String:
	var a: Node = n
	while a.get_parent() != null and a.get_parent() != root:
		a = a.get_parent()
	return String(a.name)


## How much hearth `i`'s fire smokes at minute `m` of the day, 0 to its strength: the shader's `hearth`.
func smoking(i: int, m: float) -> float:
	var h: Dictionary = hearths[i][1]
	var morning := _window(m, float(h["morning"][0]), float(h["morning"][1]))
	var noon := _window(m, float(h["noon"]), float(h["noon"]) + 95.0) if float(h["noon"]) > 0.0 else 0.0
	var evening := _window(m, float(h["evening"][0]), float(h["evening"][1]))
	var kept := 0.3 * _window(m, 480.0, 1050.0) if bool(h["kept"]) else 0.0
	return maxf(maxf(morning, noon), maxf(evening, kept)) * float(h["strength"])


static func _window(m: float, open: float, close: float) -> float:
	return smoothstep(open, open + 6.0, m) * (1.0 - smoothstep(close, close + 20.0, m))


func _process(_dt: float) -> void:
	if mat != null:
		mat.set_shader_parameter("minute", fposmod(WorldClock.minute, 1440.0))
