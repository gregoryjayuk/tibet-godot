extends SceneTree
## Who of the town comes to the room doors (world/doors.gd; ISS-105), minute by minute from 5:00 to 21:00: for each door
## the minutes someone drawn (not indoors) is within its reach (world/doors.gd WALKER: one who comes that near opens a
## shut door), and the longest stay. A walker who stands by a door for long would open it as soon as the player shut it.
## Run: /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/town/doors_probe.gd

const STREETS := "res://assets/generated/terrain/street_graph.json"
const KINDS: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]

var _done := false


func _process(_dt: float) -> bool:  # the first frame: the autoloads in the tree (the world's scripts name them)
	if _done:
		return true
	_done = true
	var Town: GDScript = load("res://world/town.gd")
	var reach: float = (load("res://world/doors.gd") as GDScript).get_script_constant_map()["WALKER"]
	var ts: Node = root.get_node("TownSim")
	var wc: Node = root.get_node("WorldClock")
	wc.set("frozen", true)
	var town := Node3D.new()
	root.add_child(town)
	var at := []
	for b in JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json"))["buildings"]:
		if b["id"] == "SHL-04":
			at.append(Vector2(b["pos"][0], b["pos"][1]))
	for b in JSON.parse_string(FileAccess.get_file_as_string("res://data/town_generic.json"))["houses"]:
		if b["id"] in ["H-SHL-007", "H-SHL-054", "H-SHL-004"]:
			at.append(Vector2(b["pos"][0], b["pos"][1]))
	var box := Rect2(at[0], Vector2.ZERO)
	for p in at:
		box = box.expand(p)
	Town.call("place", town, box.grow(12.0))
	var doors := town.find_child("Doors", true, false)
	ts.call("setup_walkers", STREETS, KINDS)
	var ws: Array = JSON.parse_string(FileAccess.get_file_as_string(STREETS))["walkers"]
	var rows := []  # per door: [minutes, longest, run, who]
	for d in (doors.get("doors") as Array):
		rows.append([0, 0, 0, {}])
	for m in range(5 * 60, 21 * 60):
		wc.set("minute", 7.0 * 1440.0 + float(m))
		ts.call("step", 0.0, Vector3.ZERO)
		var n: int = ts.get("count")
		var pos: PackedVector3Array = ts.get("pos")
		var st: PackedByteArray = ts.get("state")
		var here := {}
		for i in n:
			if st[i] == 2:
				continue
			var k: int = doors.call("near", pos[i], reach)
			if k >= 0:
				here[k] = true
				rows[k][3][ws[i]["kind"]] = int(rows[k][3].get(ws[i]["kind"], 0)) + 1
		for k in rows.size():
			if here.has(k):
				rows[k][0] += 1
				rows[k][2] += 1
				rows[k][1] = maxi(rows[k][1], rows[k][2])
			else:
				rows[k][2] = 0
	for k in rows.size():
		var mid: Vector3 = (doors.get("doors") as Array)[k]["mid"]
		print("doors: %s at town (%.1f, %.1f): %d minutes with someone within %.1f m, the longest %d; %s" % [
				(doors.get("doors") as Array)[k]["house"], mid.x, -mid.z, rows[k][0], reach, rows[k][1], rows[k][3]])
	quit()
	return true
