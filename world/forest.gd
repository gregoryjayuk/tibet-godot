extends Node3D
## The Shade Wood SER-16 (M2 sprint 12, step 4; plan chapter 11, 5.2: trees in three levels of detail, baked, never at
## start-up): the trees tools/town/forest.py scattered (assets/generated/terrain/forest.json), drawn as MultiMeshes by
## 256 m cell and by kind and variant (the kit's forest_* types, ../tibet-blender kit/forest.py), each cell's at three
## levels: its L0 near, L1 to MID, its L2 beyond, each shown over its own range from the cell's middle; the near casting
## shadows. Added by world/town.gd. `cells` for the tests and the log.

const Town := preload("res://world/town.gd")
const DATA := "res://assets/generated/terrain/forest.json"
const KIT := "res://assets/generated/kit/types/%s.glb"
const CELL := 256.0  ## (128 m cells had cost 315 draw calls with the whole wood in view; these 112)
const NEAR := 190.0  ## metres from a cell's middle within which its trees are drawn at L0 (half its diagonal and more)
const MID := 480.0  ## and at L1 within this; L2 beyond

var cells := 0
var trees := 0
var _meshes := {}  ## "kind_vN" -> [L0, L1, L2]


## Builds the wood; the count of trees drawn.
func build() -> int:
	if not FileAccess.file_exists(DATA):
		push_warning("forest: no %s (tools/py tools/town/forest.py)" % DATA)
		return 0
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var groups := {}  # "cx|cy" -> {"kind_vN": [Transform3D]}
	for t in data["trees"]:
		var key := "forest_%s_v%d" % [String(t[0]), int(t[1])]
		if not _load(key):
			continue
		var cx := int(floor(float(t[2]) / CELL))
		var cy := int(floor(float(t[3]) / CELL))
		var ck := "%d|%d" % [cx, cy]
		if not groups.has(ck):
			groups[ck] = {}
		if not (groups[ck] as Dictionary).has(key):
			groups[ck][key] = []
		var basis := Basis(Vector3.UP, deg_to_rad(float(t[5]))).scaled(Vector3.ONE * float(t[6]))
		(groups[ck][key] as Array).append(Transform3D(basis, Town.to_godot(float(t[2]), float(t[3]), float(t[4]))))
		trees += 1
	for ck in groups:
		var parts := String(ck).split("|")
		var mid := Town.to_godot((int(parts[0]) + 0.5) * CELL, (int(parts[1]) + 0.5) * CELL, 0.0)
		var cell := Node3D.new()
		cell.name = "cell_%s_%s" % [parts[0], parts[1]]
		add_child(cell)
		var ys: Array = []
		for key in groups[ck]:
			for tf in groups[ck][key]:
				ys.append((tf as Transform3D).origin.y)
		mid.y = ys.reduce(func(a, b): return a + b) / float(ys.size())
		cell.position = mid
		for key in groups[ck]:
			var list: Array = groups[ck][key]
			for lod in 3:
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = _meshes[key][lod]
				mm.instance_count = list.size()
				for i in list.size():
					var tf: Transform3D = list[i]
					mm.set_instance_transform(i, Transform3D(tf.basis, tf.origin - mid))
				var mi := MultiMeshInstance3D.new()
				mi.name = "%s_L%d" % [key, lod]
				mi.multimesh = mm
				mi.visibility_range_begin = [0.0, NEAR, MID][lod]
				mi.visibility_range_end = [NEAR, MID, 0.0][lod]
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if lod < 2 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				cell.add_child(mi)
		cells += 1
	return trees


## A kind and variant's three meshes from its kit type (its L0, L1 and L2), once.
func _load(key: String) -> bool:
	if _meshes.has(key):
		return _meshes[key] != null
	_meshes[key] = null
	if not ResourceLoader.exists(KIT % (key)):
		push_warning("forest: %s not built (../tibet-blender export_types.py)" % key)
		return false
	var scene: Node = (load(KIT % key) as PackedScene).instantiate()
	var lods := [null, null, null]
	for m in scene.find_children("*", "MeshInstance3D", true, false):
		var n := String(m.name)
		for lod in 3:
			if n.ends_with("_L%d" % lod):
				lods[lod] = (m as MeshInstance3D).mesh
	scene.free()
	if lods[0] == null:
		return false
	for lod in [1, 2]:
		if lods[lod] == null:
			lods[lod] = lods[lod - 1]
	_meshes[key] = lods
	return true
