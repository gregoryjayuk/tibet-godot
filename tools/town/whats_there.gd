extends SceneTree
## What stands in a box of the town (ISS-095's hunt, 27 Sep 2026): the town built as the valley builds it (world/town.gd),
## and every mesh whose bounds reach into the box, with its node path, its mesh and its triangles.
## Run: /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/town/whats_there.gd -- x0 y0 z0 x1 y1 z1
## (the town grid: x east, y north, z metres above sea level)

var Town: GDScript  ## world/town.gd, loaded once the autoloads are up: preloaded, a --script run compiles the town's
## scripts before them and cannot find the autoloads they name


func _initialize() -> void:
	await process_frame
	Town = load("res://world/town.gd")
	var a := OS.get_cmdline_user_args()
	var lo: Vector3 = Town.to_godot(float(a[0]), float(a[1]), float(a[2]))
	var hi: Vector3 = Town.to_godot(float(a[3]), float(a[4]), float(a[5]))
	var box := AABB(lo.min(hi), (hi - lo).abs())
	var town := Node3D.new()
	town.name = "Town"
	root.add_child(town)
	Town.place(town)
	await process_frame
	var found := 0
	for n in town.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var bb := g.global_transform * g.get_aabb()
		if not bb.intersects(box):
			continue
		found += 1
		var what := ""
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var m := (g as MeshInstance3D).mesh
			what = "%s, %d surfaces, range %.0f-%.0f m" % [m.resource_path.get_file() if m.resource_path != "" else m.resource_name, m.get_surface_count(), g.visibility_range_begin, g.visibility_range_end]
		elif g is MultiMeshInstance3D:
			what = "multimesh of %d" % (g as MultiMeshInstance3D).multimesh.instance_count
		print("there: %s (%s) %s" % [town.get_path_to(g), g.get_class(), what])
	print("there: %d geometries reach into the box" % found)
	quit()
