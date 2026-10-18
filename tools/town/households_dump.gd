extends SceneTree
## Every town house's household as world/households.gd decides it (`decide`, seeded by the house's name: its upkeep,
## paint, lime and whether it is shut or left), written for tools/town/population.py (M2 sprint 10, step 1), so the
## population's households away are the houses the town draws shut. The houses are the builder's (data/town_generic.json)
## and Hejie's (data/hejie.json); the kept ones (every walker's home, the houses to enter) are read as the game reads them.
## Run: /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/town/households_dump.gd
## (tools/terrain/build.sh runs it after the street graph). Writes assets/generated/terrain/households.json.

const OUT := "res://assets/generated/terrain/households.json"

var _done := false


func _process(_dt: float) -> bool:  # the first frame: the autoloads in the tree (households.gd's kept() reads the graph)
	if _done:
		return true
	_done = true
	var Households: GDScript = load("res://world/households.gd")
	var keep: Dictionary = Households.call("kept")
	var names: Array[String] = []
	for f in ["res://data/town_generic.json", "res://data/hejie.json"]:
		if FileAccess.file_exists(f):
			for h in (JSON.parse_string(FileAccess.get_file_as_string(f)) as Dictionary).get("houses", []):
				names.append(String(h["id"]))
	var out := {}
	var shut := 0
	var left := 0
	for n in names:
		var d: Dictionary = Households.call("decide", n, keep)
		out[n] = {"shut": d["shut"], "left": d["left"], "upkeep": snappedf(float(d["upkeep"]), 0.001), "kept": keep.has(n)}
		shut += int(d["shut"])
		left += int(d["left"])
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "Every town house's household as world/households.gd decides it (tools/town/households_dump.gd), for tools/town/population.py.", "houses": out}, " "))
	f.close()
	print("households_dump: %d houses, %d shut, %d of them left -> %s" % [names.size(), shut, left, ProjectSettings.globalize_path(OUT)])
	quit(0)
	return true
