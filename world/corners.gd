extends Node3D
## The corners round the houses (IMP-023 (2); Greg's 1781, 7 Oct 2026: "an area around town: there should be places
## like this around all the buildings and all unique"): what a household keeps by its walls in its yard, each its own
## few, seeded by its name: split firewood stacked against the wall, dung cakes drying on it with a pile of dry ones,
## clay pots, sacks of barley, the carrying basket, the butter tea churn, juniper for the morning's sang, a book in its
## cloth on a block where a monk reads. Set against the front by its corners and against the sides' front halves, clear
## of the door, the outside stair and what else stands on the ground by the house (its kit type's sidecar, `ground`); a
## shut house keeps only its firewood and its pots, a left one nothing. The kit's small types (../tibet-blender
## kit/corners.py), built against a wall: x along it, out of it +z here (Blender's -y), on the ground at its foot. One
## MultiMesh a kind for the town, without shadows. Added by world/town.gd after the households.

const KIT := "res://assets/generated/kit/types/%s.glb"
const SIDE := "res://assets/generated/kit/types/%s.json"
const GENERIC := "res://data/town_generic.json"
const MONASTERY := "res://data/monastery.json"
const LANES := "res://data/town_lanes.json"
## [kind, weight in a lived-in house, kept by a shut one]
const KINDS := [["corner_firewood", 32, true], ["corner_dung", 22, false], ["corner_pots", 18, true], ["corner_sacks", 14, false],
		["corner_basket", 14, false], ["corner_churn", 9, false], ["corner_juniper", 14, false], ["corner_pecha", 4, false]]
## A monk's house's (M3 sprint 3, step 4; chapter 03, 6.9): [kind, weight]; one in a lived-in M2's yard, nothing in a
## shut one's ("no smoke, no fuel stack": its owner at an estate, in a village or in Lhasa)
const MONK_KINDS := [["corner_firewood", 30], ["corner_dung", 20], ["corner_pots", 14], ["corner_juniper", 12], ["corner_pecha", 10],
		["corner_churn", 8], ["corner_sacks", 6]]

var per_house := {}  ## house -> [kinds by its walls]
var placed := {}  ## file -> [Transform3D], as drawn (a headless test cannot read a MultiMesh back)
var counts := {"houses": 0, "things": 0}


func build(root: Node3D, households: Node = null) -> Dictionary:
	var recs := {}
	if FileAccess.file_exists(GENERIC):
		for h in JSON.parse_string(FileAccess.get_file_as_string(GENERIC))["houses"]:
			recs[String(h["id"])] = h
	if FileAccess.file_exists(MONASTERY):  # (its monks' houses, the M1 and M2: an M3's range has its gallery and stair-ladder)
		for h in JSON.parse_string(FileAccess.get_file_as_string(MONASTERY))["houses"]:
			if String(h.get("type", "")) in ["M1", "M2"]:
				recs[String(h["id"])] = h
	var town: GDScript = load("res://world/town.gd")
	var lanes: Array = JSON.parse_string(FileAccess.get_file_as_string(LANES))["lanes"] if FileAccess.file_exists(LANES) else []
	for h in root.get_children():
		var name := String(h.name)
		if not recs.has(name) or not h is Node3D:
			continue
		var rec: Dictionary = recs[name]
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(name + ":corners")
		var shut: bool = households != null and bool(households.call("is_shut", name))
		var left: bool = households != null and bool(households.call("is_left", name))
		var monk := name.begins_with("H-MON-")
		if left or (monk and shut):
			continue
		var w := float(rec["footprint"][0])
		var d := float(rec["footprint"][1])
		var blocked := _ground_boxes(String(town.call("kit_file", rec)))
		var door := (h as Node3D).find_child("SOCK_DOOR_1", true, false) as Node3D
		var door_x := (h as Node3D).to_local(door.global_position).x if door != null else 999.0
		# the spots: before the front by each corner, and the sides' front halves; [x, z, turn]
		var spots := [[-w / 2.0 + 0.7, d / 2.0, 0.0], [w / 2.0 - 0.7, d / 2.0, 0.0], [-w / 2.0 + 1.9, d / 2.0, 0.0], [w / 2.0 - 1.9, d / 2.0, 0.0]]
		var party := String(rec.get("party", ""))
		if party != "pl" and party != "pb":  # a side's front half, but a party wall's (west is the kit's left, -x)
			spots.append([-w / 2.0, d / 2.0 - 1.0, -PI / 2.0])
		if party != "pr" and party != "pb":
			spots.append([w / 2.0, d / 2.0 - 1.0, PI / 2.0])
		if monk:  # in an M2's walled yard against the house's side (its variant's: v2, v4 and v6 on its +x, as
			# tools/town/monastery.py lays them), its only level ground beyond a 0.3 m apron on the flank; an M1 has none
			if String(rec.get("type", "")) != "M2":
				continue
			var ys := 1.0 if int(rec.get("seed", 1)) % 2 == 0 else -1.0
			spots = [[ys * w / 2.0, d / 2.0 - 2.0, ys * PI / 2.0]]  # (its middle: the yard is 3.6 m deep inside its walls, which
			# are its kit's ground boxes)
		var n := (rng.randi_range(1, 2) if monk else rng.randi_range(1, 3)) if not shut else rng.randi_range(0, 1)
		var used := {}
		var things: Array = []
		for k in n:
			var kind := _pick_monk(rng) if monk else _pick(rng, shut)
			if kind == "" or used.has(kind):
				continue
			for tries in 6:
				var s: Array = spots[rng.randi_range(0, spots.size() - 1)]
				var key := "%.1f|%.1f" % [s[0], s[1]]
				if used.has(key):
					continue
				if float(s[2]) == 0.0 and absf(float(s[0]) - door_x) < 1.3:
					continue  # the door's way kept clear
				if _hits(blocked, float(s[0]), float(s[1]), float(s[2])):
					continue
				var wp := (h as Node3D).global_transform * (Vector3(float(s[0]), 0.0, float(s[1])) + Vector3(sin(float(s[2])), 0.0, cos(float(s[2]))) * 0.45)
				if _in_lane(lanes, wp.x, -wp.z):
					continue  # not on a lane's way, nor its stair
				used[key] = true
				used[kind] = true
				var file := "%s_v%d" % [kind, rng.randi_range(1, 3)]
				var local := Transform3D(Basis(Vector3.UP, float(s[2])), Vector3(float(s[0]), 0.0, float(s[1])))
				var list: Array = placed.get(file, [])
				list.append((h as Node3D).global_transform * local)
				placed[file] = list
				things.append(kind)
				break
		if not things.is_empty():
			per_house[name] = things
			if OS.get_environment("CORNERS_LOG") != "":
				var o := (h as Node3D).global_position
				print("corners: %s at (%.1f, %.1f, %.1f): %s" % [name, o.x, -o.z, o.y + 2662.0, ", ".join(PackedStringArray(things))])
			counts["houses"] += 1
			counts["things"] += things.size()
	for f in placed:
		_draw(String(f), placed[f])
	return counts


func _pick(rng: RandomNumberGenerator, shut: bool) -> String:
	var total := 0
	for k in KINDS:
		if not shut or k[2]:
			total += int(k[1])
	var r := rng.randi_range(1, maxi(total, 1))
	for k in KINDS:
		if shut and not k[2]:
			continue
		r -= int(k[1])
		if r <= 0:
			return String(k[0])
	return ""


func _pick_monk(rng: RandomNumberGenerator) -> String:
	var total := 0
	for k in MONK_KINDS:
		total += int(k[1])
	var r := rng.randi_range(1, total)
	for k in MONK_KINDS:
		r -= int(k[1])
		if r <= 0:
			return String(k[0])
	return ""


## What stands on the ground by the house with a box of its own (its type's sidecar, `ground`: an outside stair, a pit),
## in the house's frame here (x, z), grown by a walker's room.
func _ground_boxes(file: String) -> Array:
	var out: Array = []
	if not FileAccess.file_exists(SIDE % file):
		return out
	var side = JSON.parse_string(FileAccess.get_file_as_string(SIDE % file))
	for g in side.get("ground", []):
		out.append(Rect2(Vector2(float(g[0]) - 0.6, -float(g[3]) - 0.6), Vector2(float(g[2]) - float(g[0]) + 1.2, float(g[3]) - float(g[1]) + 1.2)))
	return out


## Whether a thing at (x, z), its back to the wall turned by `turn`, stands in one of the boxes (its own ground about a
## metre and a half along the wall and under a metre out).
func _hits(boxes: Array, x: float, z: float, turn: float) -> bool:
	var along := Vector2(cos(turn), -sin(turn))
	var out := Vector2(sin(turn), cos(turn))
	var c := Vector2(x, z) + out * 0.45
	for b in boxes:
		for p in [c - along * 0.7, c + along * 0.7, c, c + out * 0.4]:
			if (b as Rect2).has_point(p):
				return true
	return false


## Whether (x, y) of the town grid lies in a lane's band (data/town_lanes.json), or within a metre of it.
func _in_lane(lanes: Array, x: float, y: float) -> bool:
	for ln in lanes:
		var f: Array = ln["from"]
		var d: Array = ln["dir"]
		var sl := (x - float(f[0])) * float(d[0]) + (y - float(f[1])) * float(d[1])
		var lat := -(x - float(f[0])) * float(d[1]) + (y - float(f[1])) * float(d[0])
		if sl >= -1.5 and sl <= float(ln["length"]) + 1.0 and absf(lat) <= float(ln["width"]) / 2.0 + 0.8:
			return true
	return false


## One MultiMesh for every instance of a kind, from its kit type's L0 mesh (as world/door_dressing.gd).
func _draw(file: String, list: Array) -> void:
	if not ResourceLoader.exists(KIT % file):
		push_warning("corners: %s not built (../tibet-blender export_types.py)" % file)
		return
	var scene: Node = (load(KIT % file) as PackedScene).instantiate()
	var mesh: Mesh = null
	for m in scene.find_children("*_L0", "MeshInstance3D", true, false):
		mesh = (m as MeshInstance3D).mesh
		break
	scene.free()
	if mesh == null:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = list.size()
	for i in list.size():
		mm.set_instance_transform(i, list[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = file
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 220.0
	add_child(mi)
