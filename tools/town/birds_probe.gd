extends SceneTree
## Where the town's birds fly (world/birds.gd): each flock's centre in the town grid, its lowest bird over the ground
## in two minutes of flight, and where its first bird is at the stills' frozen 20 s (to aim a station at it).
## Run: Godot --headless --path . --script tools/town/birds_probe.gd

func _initialize() -> void:
	var horizon: GDScript = load("res://world/horizon.gd")
	horizon.call("load_globals")
	var town: GDScript = load("res://world/town.gd")
	var birds: Node3D = (load("res://world/birds.gd") as GDScript).new()
	root.add_child(birds)
	birds.set_process(false)
	birds.call("build", func(x: float, y: float, z: float) -> Vector3: return town.call("to_godot", x, y, z))
	var flocks: Dictionary = birds.get("flocks")
	for name in flocks:
		var kind: String = flocks[name]["kind"]
		var idx: Array = flocks[name]["birds"]
		var low := INF
		for j in idx:
			for k in 240:
				var p: Vector3 = birds.call("pos_at", kind, int(j), 1000.0 + float(k) * 0.5)
				var g: float = horizon.call("ground_at", p.x, -p.z)
				if not is_nan(g):
					low = minf(low, p.y - g)
		var c: Vector3 = flocks[name]["centre"]
		var p20: Vector3 = birds.call("pos_at", kind, int(idx[0]), 20.0)
		print("%-16s %-7s %2d  centre %7.1f %7.1f h %6.1f  lowest %5.1f m over the ground  bird 0 at 20 s: %7.1f %7.1f h %6.1f" % [name, kind, idx.size(), c.x, -c.z, c.y + 2662.0, low, p20.x, -p20.z, p20.y + 2662.0])
	quit()
