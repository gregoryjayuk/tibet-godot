@tool
extends EditorScenePostImportPlugin
## Kit GLBs (res://assets/generated/kit/, recognised by their _L0 and _COL nodes) become game-ready scenes (plan chapter 11, 19.3; chapter 03, 14.2-14.8):
## - <type>_L0, _L1, _L2 meshes: visibility ranges 0-60 m (margin 5), 60-150 m (margin 5) and 150 m on with no end
##   (margin 8), each widened by the type's own reach (half its L0's bounds' diagonal): Godot measures a range from the
##   middle of the bounds, so the Sky Stair, 240 m long, drew its far level under the feet on its lower flights, the
##   steps squeezed into fins (ISS-095, Greg's walk, 27 Sep 2026); now a level holds within 60 m of any part. The cell
##   proxy hides L2 beyond 250 m through `visibility_parent` (chapter 11, 5.1); the palette shader on every surface
##   (kit_opaque, kit_gloss, kit_alpha);
## - <type>_COL: an empty whose children are convex hulls, one per part: a StaticBody3D with one
##   ConvexPolygonShape3D per hull (never trimesh on render meshes); a flight's ramp keeps its steps (the glTF extras
##   "stair": toe, the way up, rise, run and count, in Blender's frame) as the shape's `stair` metadata in Godot's:
##   {toe: Vector3, dir: Vector3, rise, run, n} (chapter 11, 13.2; sprint 3, step 3);
## - <type>_OCC: boxes inside the wall masses: an OccluderInstance3D;
## - SOCK_<KIND>_<n> empties: Marker3D nodes with `kind` and `n` in their metadata.
## Kit files are imported with node-type suffixes off (importer defaults in project.godot), so Godot's own
## -col/-occ rules never touch them.

const STATIC := preload("res://shaders/materials/stylized_static.tres")
const RANGES := {"_L0": Vector3(0.0, 60.0, 5.0), "_L1": Vector3(60.0, 150.0, 5.0), "_L2": Vector3(150.0, 0.0, 8.0)}  # begin, end (0 = none), margin


func _post_process(scene: Node) -> void:
	# A kit file is recognised by its content: an _L0 mesh and a _COL node (the plugin API gives no source path here).
	if scene.find_children("*_L0", "MeshInstance3D", true, false).is_empty() or scene.find_children("*_COL", "", true, false).is_empty():
		if scene.find_children("ramp_L0", "MeshInstance3D", true, false).is_empty():
			return
	var reach := 0.0  # half the full level's bounds' diagonal: the ranges are widened by it
	for l0 in scene.find_children("*_L0", "MeshInstance3D", true, false):
		reach = maxf(reach, (l0 as MeshInstance3D).get_aabb().size.length() / 2.0)
	var nodes := scene.find_children("*", "", true, false)
	for n in nodes:
		if not is_instance_valid(n):
			continue
		var name := String(n.name)
		if n is MeshInstance3D:
			for suffix in RANGES:
				if name.ends_with(suffix):
					var r: Vector3 = RANGES[suffix]
					_lod(n as MeshInstance3D, Vector3(r.x + reach if r.x > 0.0 else 0.0, r.y + reach if r.y > 0.0 else 0.0, r.z), suffix == "_L0")
		if name.ends_with("_COL") and not (n is MeshInstance3D):
			_collision(n, scene)
		elif name.ends_with("_OCC") and n is MeshInstance3D:
			_occluder(n as MeshInstance3D, scene)
		elif name.begins_with("SOCK_"):
			_socket(n, scene)


func _lod(mi: MeshInstance3D, r: Vector3, casts: bool) -> void:
	mi.visibility_range_begin = r.x
	mi.visibility_range_end = r.y
	mi.visibility_range_begin_margin = r.z if r.x > 0.0 else 0.0
	mi.visibility_range_end_margin = r.z if r.y > 0.0 else 0.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	if not casts:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON  # every level casts; the shadow distance limits it
	var mesh := mi.mesh
	if mesh == null:
		return
	for i in mesh.get_surface_count():
		mesh.surface_set_material(i, STATIC)


func _collision(holder: Node, scene: Node) -> void:
	var body := StaticBody3D.new()
	body.name = holder.name
	body.transform = (holder as Node3D).transform if holder is Node3D else Transform3D.IDENTITY
	for c in holder.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var shape := ConvexPolygonShape3D.new()
			var pts := PackedVector3Array()
			var arrays := (c as MeshInstance3D).mesh.surface_get_arrays(0)
			for v in arrays[Mesh.ARRAY_VERTEX]:
				pts.append((c as Node3D).transform * v)
			shape.points = pts
			var cs := CollisionShape3D.new()
			cs.name = c.name
			cs.shape = shape
			var ex = c.get_meta("extras", {})
			if ex is Dictionary and ex.has("stair"):
				var a: Array = ex["stair"]  # Blender's (x, y, z) is Godot's (x, z, -y)
				cs.set_meta("stair", {"toe": (c as Node3D).transform * Vector3(a[0], a[2], -a[1]), "dir": (c as Node3D).transform.basis * Vector3(a[3], 0.0, -a[4]),
						"rise": float(a[5]), "run": float(a[6]), "n": int(a[7])})
			body.add_child(cs)
	_replace(holder, body, scene)


func _occluder(mi: MeshInstance3D, scene: Node) -> void:
	var occ := OccluderInstance3D.new()
	occ.name = mi.name
	occ.transform = mi.transform
	var ao := ArrayOccluder3D.new()
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	for s in mi.mesh.get_surface_count():
		var a := mi.mesh.surface_get_arrays(s)
		var base := verts.size()
		verts.append_array(a[Mesh.ARRAY_VERTEX])
		var ii: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		if ii.is_empty():
			for k in (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
				idx.append(base + k)
		else:
			for k in ii:
				idx.append(base + k)
	ao.set_arrays(verts, idx)
	occ.occluder = ao
	_replace(mi, occ, scene)


func _socket(n: Node, scene: Node) -> void:
	var m := Marker3D.new()
	m.name = n.name
	if n is Node3D:
		m.transform = (n as Node3D).transform
	var parts := String(n.name).split("_")  # SOCK_<KIND>_<n>
	m.set_meta("kind", parts[1] if parts.size() > 2 else "")
	m.set_meta("n", int(parts[-1]) if parts.size() > 2 else 0)
	_replace(n, m, scene)


func _replace(old: Node, new: Node, scene: Node) -> void:
	# The old node leaves first: adding the new one beside it would make Godot rename it to avoid a duplicate name.
	var parent := old.get_parent()
	var idx := old.get_index()
	var keep := old.name
	parent.remove_child(old)
	new.name = keep
	parent.add_child(new)
	parent.move_child(new, idx)
	new.owner = scene
	for c in new.get_children():
		c.owner = scene
	old.queue_free()
