extends SceneTree
## Where a house's sockets are (for stations and routes): places the town's records within 12 m of each id given, and
## prints each id's sockets of the kinds given in the town grid (x east, y north, height) with the way each faces
## (degrees clockwise from north, from the socket's +Z). Headless:
##   Godot --headless --path . --script tools/town/sockets_probe.gd -- H-SHL-007,H-SHL-054 ROOM,DOOR,KITCHEN

var _done := false


func _process(_dt: float) -> bool:  # the first frame: the placed houses are in the tree, their transforms resolved
	if _done:
		return true
	_done = true
	var args := OS.get_cmdline_user_args()
	var ids := String(args[0]).split(",") if args.size() > 0 else PackedStringArray()
	var kinds := String(args[1]).split(",") if args.size() > 1 else PackedStringArray(["ROOM", "DOOR"])
	var town: GDScript = load("res://world/town.gd")
	var generic: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/town_generic.json"))
	var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json"))
	var all: Array = (generic["houses"] as Array) + (t["buildings"] as Array)
	for id in ids:
		for b in all:
			if String(b.get("id", "")) != id or b.get("pos") == null:
				continue
			var pos: Array = b["pos"]
			var root := Node3D.new()
			get_root().add_child(root)
			town.call("place", root, Rect2(float(pos[0]) - 12.0, float(pos[1]) - 12.0, 24.0, 24.0))
			var h := root.get_node_or_null(NodePath("Town/" + id)) as Node3D
			if h == null:
				print("%s: not placed" % id)
				continue
			print("%s: %s" % [id, town.call("kit_file", b)])
			for k in kinds:
				for s in h.find_children("SOCK_%s_*" % k, "Node3D", true, false):
					var n := s as Node3D
					var g := n.global_position
					var z := n.global_basis.z
					var face := fposmod(rad_to_deg(atan2(z.x, -z.z)), 360.0)
					print("  %-16s %8.2f %8.2f %8.2f  facing %5.1f" % [n.name, g.x, -g.z, g.y + 2662.0, face])
			root.queue_free()
	return true
