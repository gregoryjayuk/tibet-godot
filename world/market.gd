extends Node3D
## Tsongra's market on the market day (M2 sprint 10, step 4; plan chapter 05, 8.2 and 7.2): its stalls on the square's
## two levels where tools/town/market.py stands them (data/market.json), each a kit type (../tibet-blender kit/houses.py
## `stall_ground`, SH-03, and `stall_trestle`, SH-04) facing into the square, set up for the morning and packed at noon
## (the market opens at 08:00 and packs up at solar noon, 11:43). A stall not set up keeps no collision. Their keepers
## and buyers are the day's drawn (tools/town/graph.py); the three fuel stalls SHL-29 stand all day (world/town.gd).
## Added by world/town.gd.

const DATA := "res://data/market.json"
const KIT := "res://assets/generated/kit/types/%s.glb"
const DAY_START := 240.0  ## 04:00: the day's turn

var stalls: Array = []  ## [node, shown]
var hours := Vector2(456.0, 726.0)  ## set up, packed (minutes of the day)
var counts := {"stalls": 0, "missing": 0}


func build() -> Dictionary:
	if not FileAccess.file_exists(DATA):
		return counts
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var h: Array = d.get("hours", [7.6, 12.1])
	hours = Vector2(float(h[0]) * 60.0, float(h[1]) * 60.0)
	var town: GDScript = load("res://world/town.gd")
	var cache := {}
	for s in d.get("stalls", []):
		var f := "%s_v%d" % [String(s["kit"]), int(s["seed"])]
		if not cache.has(f):
			cache[f] = load(KIT % f) if ResourceLoader.exists(KIT % f) else null
		if cache[f] == null:
			counts["missing"] += 1
			push_warning("market: no kit file %s (../tibet-blender export_types.py)" % f)
			continue
		var p: Array = s["pos"]
		var n: Node3D = (cache[f] as PackedScene).instantiate()
		n.name = String(s["id"]).replace("-", "_")
		n.position = town.call("to_godot", float(p[0]), float(p[1]), float(p[2]))
		n.rotation.y = -deg_to_rad(float(s["facing"]) - 180.0)
		n.set_meta("goods", String(s.get("goods", "")))
		add_child(n)
		stalls.append([n, true])
		counts["stalls"] += 1
	_process(0.0)
	return counts


## Whether the market's stalls stand at minute `m` of the day (set up `a`, packed `b`, minutes of the day).
static func set_up_at(a: float, b: float, m: float) -> bool:
	var mm := m + 1440.0 if m < DAY_START else m
	return mm >= a and mm < b


func _process(_dt: float) -> void:
	var on := set_up_at(hours.x, hours.y, fposmod(WorldClock.minute, 1440.0))
	for st in stalls:
		if bool(st[1]) == on:
			continue
		st[1] = on
		var n := st[0] as Node3D
		n.visible = on
		for cs in n.find_children("*", "CollisionShape3D", true, false):
			(cs as CollisionShape3D).set_deferred("disabled", not on)
