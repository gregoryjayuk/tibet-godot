extends SceneTree
## Spike S6's test hall (roadmap RT-14; plan chapter 11, 4.2, "interiors"): a 12 x 16 m chapel, 7 m high, as two
## scenes. interiors/test/chapel_shell.tscn is the building, always resident: floor, walls, roof and a 2 x 3 m door in
## the south wall. interiors/test/chapel.tscn is what streams behind the door: 8 pillars, the altar with three images,
## 12 butter lamps each with its light, 60 cushions, 6 thangkas and a reverb zone. Both have their origin at the
## door's centre on the ground, facing south (+Z). Built from Godot's primitive meshes, so the scenes are small text
## files kept in git; the plan's "red chapel re-cut" (roadmap RT-14) waits for kit step K2's interiors.
## Run headless: /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/build/make_test_chapel.gd

const OUT := "res://interiors/test"
const W := 12.0
const D := 16.0
const H := 7.0
const T := 0.6


func _mat(hex: String, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.9
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(hex)
		m.emission_energy_multiplier = emit
	return m


func _box(parent: Node, name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var b := BoxMesh.new()
	b.size = size
	b.material = mat
	mi.mesh = b
	mi.position = pos
	parent.add_child(mi)
	return mi


func _save(root: Node, path: String) -> void:
	for d in root.find_children("*", "", true, false):
		d.owner = root
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, path)
	root.free()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var plaster := _mat("#7a2e22")
	var floor_mat := _mat("#4a3a2c")
	# The shell: the door is in the south wall at z = 0; the hall runs north to z = -D.
	var shell := Node3D.new()
	shell.name = "ChapelShell"
	_box(shell, "floor", Vector3(W + 2 * T, 0.2, D + 2 * T), Vector3(0, -0.1, -D / 2), floor_mat)
	_box(shell, "wall_n", Vector3(W + 2 * T, H, T), Vector3(0, H / 2, -D - T / 2), plaster)
	_box(shell, "wall_w", Vector3(T, H, D), Vector3(-W / 2 - T / 2, H / 2, -D / 2), plaster)
	_box(shell, "wall_e", Vector3(T, H, D), Vector3(W / 2 + T / 2, H / 2, -D / 2), plaster)
	var side := (W + 2 * T - 2.0) / 2.0
	_box(shell, "wall_s_w", Vector3(side, H, T), Vector3(-1.0 - side / 2, H / 2, T / 2), plaster)
	_box(shell, "wall_s_e", Vector3(side, H, T), Vector3(1.0 + side / 2, H / 2, T / 2), plaster)
	_box(shell, "lintel", Vector3(2.0, H - 3.0, T), Vector3(0, 3.0 + (H - 3.0) / 2, T / 2), plaster)
	_box(shell, "roof", Vector3(W + 2 * T + 0.6, 0.4, D + 2 * T + 0.6), Vector3(0, H + 0.2, -D / 2), plaster)
	var door := Marker3D.new()
	door.name = "SOCK_DOOR_0"
	shell.add_child(door)
	_save(shell, OUT + "/chapel_shell.tscn")
	# The dressing.
	var red := _mat("#9b2a1f")
	var gold := _mat("#c9a23a")
	var cushion := _mat("#6e1f1a")
	var flame := _mat("#ffb347", 4.0)
	var root := Node3D.new()
	root.name = "Chapel"
	for k in 8:
		var p := MeshInstance3D.new()
		p.name = "pillar_%d" % k
		var c := CylinderMesh.new()
		c.top_radius = 0.25
		c.bottom_radius = 0.28
		c.height = H - 0.2
		c.material = red
		p.mesh = c
		p.position = Vector3(-2.5 if k % 2 == 0 else 2.5, (H - 0.2) / 2, -3.0 - (k / 2) * 3.0)
		root.add_child(p)
	_box(root, "altar", Vector3(7.0, 1.2, 1.4), Vector3(0, 0.6, -D + 1.2), red)
	for k in 3:
		var s := MeshInstance3D.new()
		s.name = "image_%d" % k
		var c := CapsuleMesh.new()
		c.radius = 0.45 if k == 1 else 0.35
		c.height = 2.4 if k == 1 else 1.8
		c.material = gold
		s.mesh = c
		s.position = Vector3((k - 1) * 2.2, 1.2 + c.height / 2, -D + 1.2)
		root.add_child(s)
	for k in 12:
		var lamp := MeshInstance3D.new()
		lamp.name = "lamp_%d" % k
		var c := CylinderMesh.new()
		c.top_radius = 0.07
		c.bottom_radius = 0.05
		c.height = 0.12
		c.material = gold
		lamp.mesh = c
		var x := -3.0 + (k % 6) * 1.2
		var z := -D + 2.2 + (k / 6) * 0.5
		lamp.position = Vector3(x, 1.26, z)
		root.add_child(lamp)
		var f := MeshInstance3D.new()
		f.name = "flame_%d" % k
		var s := SphereMesh.new()
		s.radius = 0.03
		s.height = 0.08
		s.material = flame
		f.mesh = s
		f.position = Vector3(x, 1.36, z)
		root.add_child(f)
		var l := OmniLight3D.new()
		l.name = "lamp_light_%d" % k
		l.light_color = Color(1.0, 0.7, 0.35)
		l.light_energy = 1.2
		l.omni_range = 5.0
		l.position = Vector3(x, 1.45, z)
		root.add_child(l)
	var cm := BoxMesh.new()
	cm.size = Vector3(0.7, 0.15, 0.7)
	cm.material = cushion
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cm
	mm.instance_count = 60
	for k in 60:  # six rows of ten, five each side of the aisle
		var row := k / 10
		var col := k % 10
		var side_x := -1.6 - (col % 5) * 0.8 if col < 5 else 1.6 + (col % 5) * 0.8
		mm.set_instance_transform(k, Transform3D(Basis(), Vector3(side_x * 0.5, 0.075, -2.5 - row * 1.6)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "cushions"
	mmi.multimesh = mm
	root.add_child(mmi)
	var colours := ["#2e61c7", "#d53b25", "#2f9c4d", "#f3c23b", "#e68c1f", "#6e4a7a"]
	for k in 6:
		var q := MeshInstance3D.new()
		q.name = "thangka_%d" % k
		var qm := QuadMesh.new()
		qm.size = Vector2(1.4, 2.1)
		qm.material = _mat(colours[k])
		q.mesh = qm
		var west := k < 3
		q.position = Vector3(-W / 2 + 0.05 if west else W / 2 - 0.05, 3.2, -4.0 - (k % 3) * 4.0)
		q.rotation.y = PI / 2 if west else -PI / 2
		root.add_child(q)
	var zone := Area3D.new()
	zone.name = "reverb"
	zone.reverb_bus_enabled = true
	zone.reverb_bus_name = &"Hall"
	zone.reverb_bus_amount = 0.8
	zone.reverb_bus_uniformity = 0.3
	var zs := CollisionShape3D.new()
	var zb := BoxShape3D.new()
	zb.size = Vector3(W, H, D)
	zs.shape = zb
	zs.position = Vector3(0, H / 2, -D / 2)
	zone.add_child(zs)
	root.add_child(zone)
	var n := root.find_children("*", "", true, false).size()
	_save(root, OUT + "/chapel.tscn")
	print("make_test_chapel: shell and dressing (%d nodes) in %s" % [n, ProjectSettings.globalize_path(OUT)])
	quit()
