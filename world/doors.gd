extends Node3D
## The room doors that open and shut (ISS-105, ISS-101): the leaves of the houses to enter and of Dechen-tsang's kitchen
## (the kit's sidecar `leaves`, marked by world/town.gd at their hinges in the group "door_leaves"), each hung from the
## kit's door_leaf types and scaled to its doorway, standing open as the kit had drawn them. E by a doorway swings its
## leaves shut, or open again, and the door is heard (SND-218). A shut door bars its doorway with a box of collision, and
## its threshold is no longer stepped over (its marker leaves the group "sills"). Whoever of the town comes to a shut door
## opens it again on their way (TownSim). Added by world/town.gd after the houses.

const Subtitles := preload("res://ui/subtitles.gd")
const LEAF := "res://assets/generated/kit/types/%s_v1.glb"
const LEAF_W := 0.495  ## the kit's door_leaf, as built: its width and height
const LEAF_H := 1.85
const REACH := 1.5  ## metres from a doorway's middle
const SWING_S := 0.7  ## seconds a door takes to swing
const WALKER := 1.1  ## metres from a shut door's middle at which one of the town opens it

var doors: Array = []  ## {house, mid, way_in, w, h, leaves: [[pivot, shut yaw, open yaw]], open, k, block, sill}
var save_key := "doors"  ## its block in a save (autoload/save.gd): the doors that stand shut
var _shown := ""  ## the prompt as last said
var _walkers_in := 0.0


## Pairs the town's leaf markers into doors and hangs their leaves. The count of doors.
func build(root: Node3D) -> int:
	add_to_group("doors")
	add_to_group("saved")
	var marks := root.get_tree().get_nodes_in_group("door_leaves")
	var used := {}
	for a in marks:
		if used.has(a):
			continue
		var group := [a]
		used[a] = true
		for b in marks:  # its doorway's other leaf: its hinge across the doorway, the same way in
			if not used.has(b) and (a as Node3D).global_position.distance_to((b as Node3D).global_position) < 1.6 \
					and absf(float(a.get_meta("open")) - float(b.get_meta("open"))) < 1.0 and a.get_parent() == b.get_parent():
				group.append(b)
				used[b] = true
		_door(group)
	return doors.size()


func _door(marks: Array) -> void:
	var house := (marks[0] as Node3D).get_parent() as Node3D
	var hy := house.global_rotation.y
	var mid := Vector3.ZERO
	var leaves := []
	var way_in := Vector3.ZERO
	var h := 0.0
	var w := 0.0
	for m in marks:
		var mk := m as Node3D
		var a_shut := deg_to_rad(float(mk.get_meta("shut")))
		var a_open := deg_to_rad(float(mk.get_meta("open")))
		var lw := float(mk.get_meta("w"))
		h = float(mk.get_meta("h"))
		w += lw
		var pivot := Node3D.new()
		pivot.name = "%s_%s" % [house.name, mk.name]
		add_child(pivot)
		pivot.global_position = mk.global_position
		pivot.global_rotation = Vector3(0.0, hy + a_open, 0.0)  # the kit's yaw from +x is Godot's about +y (x, -z)
		way_in = Vector3(cos(hy + a_open), 0.0, -sin(hy + a_open))
		mid += mk.global_position + Vector3(cos(hy + a_shut), 0.0, -sin(hy + a_shut)) * lw / 2.0
		var path := LEAF % String(mk.get_meta("type"))
		if ResourceLoader.exists(path):
			var leaf: Node3D = (load(path) as PackedScene).instantiate()
			leaf.scale = Vector3(lw / LEAF_W, h / LEAF_H, 1.0)
			# the ring and the straps on the outer face, the kit's -y (Godot +z): the leaf turned over where that faced in
			if (Basis(Vector3.UP, hy + a_shut) * Vector3(0.0, 0.0, 1.0)).dot(way_in) > 0.0:
				leaf.scale.z = -1.0
			pivot.add_child(leaf)
		leaves.append([pivot, hy + a_shut, hy + a_open])
	mid /= maxf(marks.size(), 1)
	# the shut door's bar: a box across the doorway where the leaves meet it
	var block := StaticBody3D.new()
	block.name = "DoorShut"
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w + 0.1, h, 0.12)
	cs.shape = box
	cs.disabled = true
	block.add_child(cs)
	add_child(block)
	block.global_transform = Transform3D(Basis.looking_at(way_in, Vector3.UP), mid + Vector3(0.0, h / 2.0, 0.0))
	var sill: Node = null
	for s in get_tree().get_nodes_in_group("sills"):
		if (s as Node3D).global_position.distance_to(mid) < 1.2:
			sill = s
	doors.append({"house": String(house.name), "mid": mid, "way_in": way_in, "w": w, "h": h, "leaves": leaves, "open": true, "k": 1.0,
			"block": cs, "sill": sill})


## A door's name in a save: its first leaf's pivot ("<house>_LEAF_<n>").
func door_id(i: int) -> String:
	return String((doors[i]["leaves"][0][0] as Node).name)


## The doors standing shut (every other stands open, as the kit drew it).
func save_state() -> Dictionary:
	var shut := []
	for i in doors.size():
		if not bool(doors[i]["open"]):
			shut.append(door_id(i))
	return {"shut": shut}


## Each door as a save had it, swung at once (no sound, no swing).
func load_state(d: Dictionary) -> void:
	var shut: Array = d.get("shut", [])
	for i in doors.size():
		var on := not shut.has(door_id(i))
		if bool(doors[i]["open"]) != on:
			doors[i]["open"] = on
			(doors[i]["block"] as CollisionShape3D).set_deferred("disabled", on)
			var sill: Node = doors[i]["sill"]
			if sill != null:
				if on and not sill.is_in_group("sills"):
					sill.add_to_group("sills")
				elif not on and sill.is_in_group("sills"):
					sill.remove_from_group("sills")
		doors[i]["k"] = 1.0 if on else 0.0
		for l in doors[i]["leaves"]:
			(l[0] as Node3D).global_rotation.y = float(l[2]) if on else float(l[1])


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


## The door within `reach` of `p` (Godot), or -1.
func near(p: Vector3, reach := REACH) -> int:
	var best := -1
	var bd := reach
	for i in doors.size():
		var m: Vector3 = doors[i]["mid"]
		var d := Vector2(p.x - m.x, p.z - m.z).length()
		if d < bd and absf(p.y - m.y) < 1.4:
			bd = d
			best = i
	return best


## How open the door nearest `p` (within `reach`) stands, 0 shut to 1 open, eased with its swing; 1 with no door there.
## A room's daylight through its doorway goes with it (interiors/room.gd).
func openness_near(p: Vector3, reach := 2.0) -> float:
	var i := near(p, reach)
	return 1.0 if i < 0 else smoothstep(0.0, 1.0, float(doors[i]["k"]))


## How open door `i` stands, 0 shut to 1 open, eased with its swing.
func openness_of(i: int) -> float:
	return 1.0 if i < 0 or i >= doors.size() else smoothstep(0.0, 1.0, float(doors[i]["k"]))


## Whether `p` stands where door `i`'s leaves would shut on it: in its doorway, or inside within a leaf's sweep.
func in_doorway(i: int, p: Vector3) -> bool:
	var q: Vector3 = p - doors[i]["mid"]
	var w: Vector3 = doors[i]["way_in"]
	var t := q.dot(w)
	return t > -0.4 and t < 0.85 and absf(q.dot(Vector3(-w.z, 0.0, w.x))) < float(doors[i]["w"]) / 2.0 + 0.2 and absf(q.y) < 1.4


## Swings door `i` shut or open. False if it was already as asked.
func set_open(i: int, on: bool) -> bool:
	if i < 0 or i >= doors.size() or bool(doors[i]["open"]) == on:
		return false
	doors[i]["open"] = on
	(doors[i]["block"] as CollisionShape3D).set_deferred("disabled", on)
	var sill: Node = doors[i]["sill"]
	if sill != null:
		if on and not sill.is_in_group("sills"):
			sill.add_to_group("sills")
		elif not on and sill.is_in_group("sills"):
			sill.remove_from_group("sills")  # a shut door's threshold is not stepped over
	if is_instance_valid(AudioDirector):
		AudioDirector.play("SND-218.open" if on else "SND-218.close", doors[i]["mid"] + Vector3(0.0, 1.0, 0.0))
	return true


func _process(dt: float) -> void:
	for d in doors:
		var goal := 1.0 if bool(d["open"]) else 0.0
		if float(d["k"]) != goal:
			d["k"] = move_toward(float(d["k"]), goal, dt / SWING_S)
			var e := smoothstep(0.0, 1.0, float(d["k"]))
			for lf in d["leaves"]:
				(lf[0] as Node3D).global_rotation.y = lerp_angle(float(lf[1]), float(lf[2]), e)
	_walkers_in -= dt
	if _walkers_in <= 0.0:
		_walkers_in = 0.25
		_walkers()
	var p := _player()
	var t := ""
	var n := near(p.global_position) if p != null and int(p.get("rest")) == 0 else -1
	if n >= 0 and not bool(doors[n]["open"]):
		t = "E  open the door"
	elif n >= 0 and not in_doorway(n, p.global_position):
		t = "E  shut the door"
	if t != _shown:
		_shown = t
		_prompt(t)


## The town's people coming to a shut door open it (the households of the houses to enter go out and come home by them).
func _walkers() -> void:
	for i in doors.size():
		if bool(doors[i]["open"]):
			continue
		for a in TownSim.count:
			if int(TownSim.state[a]) != 2 and near(TownSim.pos[a], WALKER) == i:
				set_open(i, true)
				break


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_action_pressed("use"):  # E, or the controller's triangle (autoload/controls.gd)
		return
	var p := _player()
	if p == null or int(p.get("rest")) != 0:
		return
	var n := near(p.global_position)
	if n < 0 or (bool(doors[n]["open"]) and in_doorway(n, p.global_position)):  # never shut on the player
		return
	if set_open(n, not bool(doors[n]["open"])):
		get_viewport().set_input_as_handled()


func _prompt(t: String) -> void:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s == null and t != "":
		s = Subtitles.new()
		get_tree().root.add_child(s)
	if s != null:
		s.call("prompt", t)
