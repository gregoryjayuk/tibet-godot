extends SceneTree
## The townspeople standing on top of one another (ISS-094, Greg's walk, 27 Sep 2026): the street graph's walkers
## (assets/generated/terrain/street_graph.json) on their days, minute by minute from 5:00 to 21:00, and every pair of
## them drawn (not indoors) within 0.6 m of each other, with the places and states they were in.
## Run: /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/town/overlaps.gd

const STREETS := "res://assets/generated/terrain/street_graph.json"
const KINDS: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]
const NEAR := 0.6


func _initialize() -> void:
	await process_frame
	var ts: Node = root.get_node("TownSim")
	var wc: Node = root.get_node("WorldClock")
	wc.set("frozen", true)
	ts.call("setup_walkers", STREETS, KINDS)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STREETS))
	var ws: Array = data["walkers"]
	var pairs := {}  # "a|b" -> [first minute, last minute, frames, where]
	for m in range(5 * 60, 21 * 60):
		wc.set("minute", 7.0 * 1440.0 + float(m))
		ts.call("step", 0.0, Vector3.ZERO)
		var n: int = ts.get("count")
		var pos: PackedVector3Array = ts.get("pos")
		var st: PackedByteArray = ts.get("state")
		for i in n:
			if st[i] == 2:
				continue
			for j in range(i + 1, n):
				if st[j] == 2:
					continue
				var a := pos[i]
				var b := pos[j]
				if Vector2(a.x - b.x, a.z - b.z).length() < NEAR and absf(a.y - b.y) < 1.5:
					var k := "%d|%d" % [i, j]
					if not pairs.has(k):
						pairs[k] = [m, m, 0, "%s (%s) & %s (%s) at town (%.1f, %.1f), states %d/%d" % [ws[i]["kind"], _stop(ws[i], m), ws[j]["kind"], _stop(ws[j], m), a.x, -a.z, st[i], st[j]]]
					pairs[k][1] = m
					pairs[k][2] = int(pairs[k][2]) + 1
	print("overlaps: %d pairs of walkers within %.1f m of each other at some minute, 5:00-21:00" % [pairs.size(), NEAR])
	var rows := pairs.values()
	rows.sort_custom(func(x, y): return int(x[2]) > int(y[2]))
	for r in rows:
		print("  %3d min, %s-%s: %s" % [r[2], _hm(r[0]), _hm(r[1]), r[3]])
	quit()


func _stop(w: Dictionary, m: int) -> String:
	var here := ""
	for s in w["day"]:
		if float(s[1]) <= m:
			here = "%s %s%s" % [s[0], s[3], (" " + String(s[5]["name"])) if s.size() > 5 and s[5] is Dictionary else ""]
	return here


func _hm(m: int) -> String:
	return "%d:%02d" % [m / 60, m % 60]
