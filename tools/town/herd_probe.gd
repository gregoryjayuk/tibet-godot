extends SceneTree
## Where CV-02's herd is through its afternoon (world/herd.gd; M2 sprint 9, step 2): every ten game minutes from the ten's
## start, the herd's lead, middle and tail in the town grid, on which stretch, and how many are seen; for choosing the
## stills' places and hours, and for walking out to meet it.
## Run: /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/town/herd_probe.gd

const STREETS := "res://assets/generated/terrain/street_graph.json"

var _done := false


func _process(_dt: float) -> bool:  # the first frame: the autoloads in the tree (the world's scripts name them)
	if _done:
		return true
	_done = true
	var town: GDScript = load("res://world/town.gd")  # (loaded here, not preloaded: they name the autoloads)
	var Caravan: GDScript = load("res://world/caravan.gd")
	var Herd: GDScript = load("res://world/herd.gd")
	var Named: GDScript = load("res://characters/named.gd")
	var sim: Node = root.get_node("TownSim")
	sim.setup_walkers(STREETS, ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"] as Array[String])
	var named: Node3D = Named.new()
	root.add_child(named)
	named.setup(sim, null)
	var cv: Node3D = Caravan.new()
	root.add_child(cv)
	if not cv.setup(sim, null, JSON.parse_string(FileAccess.get_file_as_string(STREETS))):
		print("herd_probe: no caravan")
		quit(1)
		return true
	var herd: Node3D = Herd.new()
	root.add_child(herd)
	if not herd.setup(cv):
		print("herd_probe: no herd")
		quit(1)
		return true
	var start: float = herd.get("start")
	var junction: float = herd.get("junction_s")
	var ramp_end: float = herd.get("ramp_end_s")
	var gallery: Vector2 = herd.get("gallery")
	var where := func(s: float) -> String:
		if s < 0.0:
			return "beyond the gallery"
		if s < gallery.x:
			return "before the gallery"
		if s <= gallery.y:
			return "on the gallery"
		if s < junction:
			return "on the road"
		if s < ramp_end:
			return "on the ramp"
		return "in the camp"
	for k in range(0, 260, 10):
		var m := start + float(k)
		var line := "%02d:%02d" % [int(m) / 60, int(m) % 60]
		var seen := 0
		for i in int(Herd.get_script_constant_map()["N"]):
			if herd.place_of(i, m)[3]:
				seen += 1
		for i in [0, 31, 61]:
			var q: Array = herd.place_of(i, m)
			var s: float = Herd.call("_s_at", herd.get("yaks")[i]["knots"], m)
			var p: Vector3 = q[0]
			line += "  #%d %s%s" % [i, where.call(s), (" (%.0f, %.0f, %.0f)" % [p.x, -p.z, p.y + town.get("DATUM")]) if q[3] else ""]
		print("%s  %d seen%s" % [line, seen, ""])
	var wc: Node = root.get_node("WorldClock")
	var worst := 0
	for k in range(0, 240, 2):  # the script's cost a frame through the afternoon
		wc.set("minute", start + float(k))
		herd.call("update", Vector3.ZERO)
		worst = maxi(worst, int(herd.get("last_us")))
	print("herd_probe: set out %.1f, the lead halted %.1f, the last %.1f; the script's worst frame %.2f ms" % [start, float(herd.get("halt_minute")), float(herd.get("done_minute")), worst / 1000.0])
	quit(0)
	return true
