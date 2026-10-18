extends Node3D
## The door dressing (IMP-019; chapter 03, 2.3 and 14: "each household's door dressing: mani stones, thread crosses, a
## yak skull; the Bön left-turning swastika"; Greg, 27 Sep 2026: "the houses already have way too many uniform
## features"). Each town house's own at its door, drawn by its name: a yak skull on a peg over the lintel (three in ten;
## painted with the mantra's bands, or cloth tied to its horns), a thread cross beside the door (one in four), mani
## stones leaning at a door on the ground (one in three), Losar's white marks round the door and a swastika by it (half
## the lived-in houses, chalked on a leaf; turning left in a Bön household, one in twelve; none on a door that stands
## open, a house to enter's); and a shut house's door barred and padlocked
## (world/households.gd), no Losar marks on a house shut since before Losar; a monk's house nothing but, shut, its bar and
## padlock (M3 sprint 3, step 4). The kit's small types (../tibet-blender
## kit/dressing.py), each placed in its door's DOOR socket's frame (x along the wall, y up it, z out of it; the frame
## leans with the battered wall, so up it is along its face); drawn as one MultiMesh a kind for the town, without
## shadows. Added by world/town.gd after the households.

const KIT := "res://assets/generated/kit/types/%s.glb"
const Interiors := preload("res://world/interiors.gd")
const SKULLS := ["door_skull_v1", "door_skull_v2", "door_skull_painted_v1", "door_skull_painted_v1", "door_skull_cloth_v1"]
const CROSSES := ["door_threadcross_v1", "door_threadcross_v2", "door_threadcross_v3"]
const MANI := ["door_mani_v1", "door_mani_v2", "door_mani_v3", "door_mani_v4"]

var per_house := {}  ## house name -> [the files at its door]
var placed := {}  ## file -> [Transform3D], as drawn (a headless test cannot read a MultiMesh back)


## Dresses the door of every town house under `root` (the town); `households` (world/households.gd, built) for the shut
## ones. Returns {doors, dressed, barred, items}.
func build(root: Node, households: Node = null) -> Dictionary:
	var doors := 0
	var dressed := 0
	var barred := 0
	for h in root.get_children():
		var name := String(h.name)
		if not name.begins_with("H-") or name.begins_with("H-HEJ-") or not h is Node3D:
			continue  # (Hejie's Han doors are not dressed as a Tibetan household's: IMP-042)
		var monk := name.begins_with("H-MON-")  # a monk's house: no household's things at its door, but a shut one's bar and
		# padlock on its hasp, its owner at an estate, in a village or in Lhasa (M3 sprint 3, step 4; chapter 03, 6.9)
		var socks := h.find_children("SOCK_DOOR_*", "Node3D", true, false)
		if socks.is_empty():
			continue
		socks.sort_custom(func(a, b): return String(a.name) < String(b.name))
		var door := socks[0] as Node3D
		doors += 1
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(name + ":door")
		var shut: bool = households != null and bool(households.call("is_shut", name))
		var on_ground := (h as Node3D).to_local(door.global_position).y < 0.6
		var items: Array = []
		var side := 1.0 if rng.randf() < 0.5 else -1.0  # the side of the door the cross and the stones go
		if not monk:
			if rng.randf() < 0.3:
				items.append([SKULLS[rng.randi_range(0, SKULLS.size() - 1)], Vector3(0.0, 2.6, 0.0)])
			if rng.randf() < 0.25:
				items.append([CROSSES[rng.randi_range(0, CROSSES.size() - 1)], Vector3(side * 1.25, 1.75, 0.0)])
			if on_ground and rng.randf() < 0.35:  # the stones' row runs along +x from its first: to the door's right, or ending left of it
				items.append([MANI[rng.randi_range(0, MANI.size() - 1)], Vector3(0.8 if side > 0 else -2.0, 0.0, 0.0)])
			var bon := rng.randf() < 1.0 / 12.0
			if not shut and rng.randf() < 0.5 and not Interiors.ROOMS.has(name):  # (a house to enter's leaves stand open)
				items.append(["door_marks_l_v1" if bon else "door_marks_r_v1", Vector3.ZERO])
		if shut:
			items.append(["door_bar_v1", Vector3.ZERO])
			barred += 1
		per_house[name] = items.map(func(it): return String(it[0]))
		if OS.get_environment("DOORS_LOG") != "":
			var left: bool = households != null and bool(households.call("is_left", name))
			print("door dressing: %s%s%s: %s" % [name, " (left)" if left else (" (shut)" if shut else ""), "" if on_ground else " (up its stair)", ", ".join(PackedStringArray(per_house[name]))])
		if not items.is_empty():
			dressed += 1
		for it in items:
			var list: Array = placed.get(it[0], [])
			list.append(door.global_transform * Transform3D(Basis(), it[1] as Vector3))
			placed[it[0]] = list
	var n := 0
	for f in placed:
		n += (placed[f] as Array).size()
		_draw(String(f), placed[f])
	return {"doors": doors, "dressed": dressed, "barred": barred, "items": n}


## One MultiMesh for every instance of a kind, from its kit type's L0 mesh.
func _draw(file: String, list: Array) -> void:
	if not ResourceLoader.exists(KIT % file):
		push_warning("door dressing: %s not built (../tibet-blender export_types.py)" % file)
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
	add_child(mi)
