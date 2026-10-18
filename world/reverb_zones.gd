extends Node3D
## The reverb areas of the slice's outdoors (plan chapter 10, 9.3, 13.4; M1 sprint 8, step 1), added by world/town.gd:
## volumes on the audio layer (12, which every voice of the AudioDirector listens to) that send the 3D sounds inside
## them to a reverb bus (data/sound.json `zones`). The Sky Stair's are prisms raked with it, flight by flight and
## landing by landing, with upright ends, 3 m high over its treads and as wide as its cheeks: the tunnel's stretch
## (SHL-16, RZ-21) and the gateway chorten's (SHL-17, RZ-22) their own, the rest the stone lane (RZ-20). Tsongra is one
## box (RZ-23), ending short of the stair's foot. None overlaps another (the engine takes the first area it finds at a sound, whatever its priority):
## a stretch is cut where its zone changes. The rooms raise their own as they stream in (interiors/room.gd).

const LAYER := 1 << 11
const PLAN := "res://assets/generated/kit/types/sky_stair_v1.json"
const TUNNEL := [28.2, 62.2]  ## metres up the stair: world/town.gd's SHL-16 (the kit's sky_tunnel: start, start + length)
const GATE_HALF := 3.8  ## the gateway chorten's passage either side of its middle, along the stair (its 6 m and portals)
const HIGH := 3.0  ## metres over the treads
const Town := preload("res://world/town.gd")

var boxes: Array = []  ## [zone, Area3D], for the tests


## The stair's zones in its frame (the kit's y along it is Godot's -z), and Tsongra's.
func setup(stair: Node3D, gate: Node3D) -> void:
	if stair != null and FileAccess.file_exists(PLAN):
		var plan: Array = (JSON.parse_string(FileAccess.get_file_as_string(PLAN)) as Dictionary).get("plan", [])
		var g := -1.0e9
		if gate != null:
			g = -(stair.transform.affine_inverse() * gate.position).z
		var cuts := [TUNNEL[0], TUNNEL[1], g - GATE_HALF, g + GATE_HALF]
		for seg in plan:
			var y0 := float(seg[1])
			var y1 := float(seg[2])
			var z0 := float(seg[3])
			var z1 := float(seg[4])
			var w := float(seg[6]) + 0.7
			var marks := [y0]
			for c in cuts:
				if float(c) > y0 + 0.05 and float(c) < y1 - 0.05:
					marks.append(float(c))
			marks.append(y1)
			marks.sort()
			for k in marks.size() - 1:
				var a := float(marks[k])
				var b := float(marks[k + 1])
				var mid := (a + b) / 2.0
				var zone := "RZ-21" if mid > TUNNEL[0] and mid < TUNNEL[1] else ("RZ-22" if absf(mid - g) < GATE_HALF else "RZ-20")
				var za := z0 + (a - y0) / maxf(y1 - y0, 0.001) * (z1 - z0)
				var zb := z0 + (b - y0) / maxf(y1 - y0, 0.001) * (z1 - z0)
				# a prism with upright ends, raked with the treads: the next stretch's end stands in the same plane, so
				# they meet with no overlap and no gap (a pitched box's ends leaned into its neighbours)
				var pts := PackedVector3Array()
				for q in [[a, za], [b, zb]]:
					for sx in [-1.0, 1.0]:
						pts.append(Vector3(sx * w / 2.0, float(q[1]) - 0.3, -float(q[0])))
						pts.append(Vector3(sx * w / 2.0, float(q[1]) + HIGH, -float(q[0])))
				_prism(zone, stair.transform, pts)
	var sq := Town.to_godot(0.0, 1.0, 2663.0)
	_box("RZ-23", Transform3D(Basis(), sq), Vector3(50.0, 14.0, 26.0))  # Tsongra: x -25..25, y -12..14 (the stair's foot is at 15)


## A passage's zone: a box of `size` (its width, height and length, along the node's own z) on the ground at `node`
## (the Gate Chorten's passage over R-01, RZ-22; M2 sprint 3).
func add_passage(zone: String, node: Node3D, size: Vector3) -> void:
	if node == null:
		return
	_box(zone, Transform3D(node.transform.basis, node.position + Vector3(0.0, size.y / 2.0, 0.0)), size)


func _box(zone: String, xf: Transform3D, size: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = size
	_area(zone, xf, box)


func _prism(zone: String, xf: Transform3D, pts: PackedVector3Array) -> void:
	var shape := ConvexPolygonShape3D.new()
	shape.points = pts
	_area(zone, xf, shape)


func _area(zone: String, xf: Transform3D, shape: Shape3D) -> void:
	var z: Dictionary = (AudioDirector.data.get("zones", {}) as Dictionary).get(zone, {})
	if z.is_empty():
		return
	var area := Area3D.new()
	area.name = "%s_%d" % [zone, boxes.size()]
	area.collision_layer = LAYER
	area.collision_mask = 0
	area.monitoring = false
	area.reverb_bus_enabled = true
	area.reverb_bus_name = StringName(z["bus"])
	area.reverb_bus_amount = float(z["amount"])
	area.reverb_bus_uniformity = float(z["uniformity"])
	var cs := CollisionShape3D.new()
	cs.shape = shape
	area.add_child(cs)
	add_child(area)
	area.global_transform = xf
	boxes.append([zone, area])
