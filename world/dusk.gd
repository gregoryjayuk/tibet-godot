extends Node3D
## The town's daily turns at dusk (plan chapter 08, V-28, "Evening on the roofs", 17:00-17:45; chapter 05, 7-9; M1
## sprint 4, step 6, first cut), added by world/town.gd once the town is built:
## - The sang, བསང: every roof burner (the kit's SANG sockets) sends up a thread of juniper smoke in the morning
##   (05:45-06:30) and the evening (17:00-17:45), each household lit a few minutes after the next; one MultiMesh of
##   stacked puffs (shaders/smoke.gdshader), lit only by the sky, one draw call.
## - The horns at 17:15 from the Tsokchen's roof are the sound schedule's now (data/sound.json, autoload/audio/sound.gd:
##   late by the sound's travel, and the ridge's echo); the juniper crackles on each burner while its thread burns
##   (SND-024, a loop of the sound director's: the nearest six are heard).
## - The ladders: from 17:40 the households draw up their ladders that stand on the ground (the notched logs and the
##   Rooftop Way's), one after another over ten minutes, and set them down again from 05:30. A ladder being drawn up
##   leaves the group "ladders", so no one climbs it; one within 30 m of the player waits until the player has gone,
##   so the player is never left on a roof (chapter 02, 5.1; the plan also has 20:00, with the mastiffs: chapter 05).

const Town := preload("res://world/town.gd")
const SMOKE := preload("res://shaders/smoke.gdshader")
const PUFFS := 24  ## overlapping puffs a thread (10 read as strings of beads)
const UP_AT := 17.0 * 60.0 + 40.0
const DOWN_AT := 5.0 * 60.0 + 30.0
const SPREAD := 10.0  ## game minutes over which the households draw their ladders up, or set them down
const WAIT_NEAR := 30.0  ## metres: a ladder this near the player is not drawn up
const MOVE_S := 6.0  ## real seconds a ladder takes to come up or go down
## burners lit on their own minute, the minutes after the morning's window opens (smoke.gdshader: 30 or more, a morning's
## alone, its window that much later): the Conch terrace's at 06:45, by Lama Orgyen Dorje for the first sun (M2 sprint 5)
const LATE := {"SHL-12": 60.0}

var smoke: MultiMeshInstance3D
var smoke_mat: ShaderMaterial
var burners := 0
var ladders: Array = []  ## one Dictionary per ladder drawn up at night
var _knock := 0.0  ## real seconds until a ladder's knock may be heard again
var sang_socks: Array = []  ## the SANG sockets, in the smoke's instance order
var _base: Array = []  ## each burner's instance data as built
var _boosts := {}  ## burner -> real seconds left of a thicker thread (juniper laid on it: world/roof_sang.gd)
var _last := -1.0  ## the last minute of the day seen


func _ready() -> void:
	add_to_group("dusk")  # juniper laid on a burner thickens its thread (world/roof_sang.gd)
	var root := get_parent()
	_build_smoke(root)
	var k := 0
	for l in get_tree().get_nodes_in_group("ladders"):
		if String((l as Node).get_meta("from", "")) != "ground":
			continue
		var node := l as Node3D
		var down := node.transform
		var top: Vector3 = node.get_meta("parapet")
		var way: Vector3 = node.get_meta("way")
		var u := (top - down.origin).normalized()
		# drawn up: turned to lie along its way over the roof, its foot just inside the parapet, a little under its top
		var up_basis := Basis(Quaternion(u, way.normalized())) * down.basis
		var up := Transform3D(up_basis, top + way.normalized() * 0.3 - Vector3(0.0, 0.35, 0.0))
		ladders.append({"node": node, "down": down, "up": up, "state": 0.0, "goal": 0.0, "order": k})
		k += 1
	for d in ladders:  # an order through the evening: a hash of each ladder's place, not the tree's order
		d["order"] = fposmod(sin((d["down"] as Transform3D).origin.x * 12.9898 + (d["down"] as Transform3D).origin.z * 78.233) * 43758.5453, 1.0)


## The minute of the day, local time.
static func day_minute() -> float:
	return fposmod(WorldClock.minute, 1440.0)


func _process(dt: float) -> void:
	var m := day_minute()
	if smoke_mat != null:
		smoke_mat.set_shader_parameter("minute", m)
	var cam := get_viewport().get_camera_3d()
	var eye: Vector3 = cam.global_position if cam != null else Vector3.ZERO
	if floorf(m) != floorf(_last):
		_juniper(m)
	_knock -= dt
	for d in ladders:
		var up_from := UP_AT + float(d["order"]) * SPREAD
		var down_from := DOWN_AT + float(d["order"]) * SPREAD
		var night := m >= up_from or m < down_from
		var node: Node3D = d["node"]
		if night and float(d["goal"]) == 0.0 and eye.distance_to(node.global_position) > WAIT_NEAR:
			d["goal"] = 1.0
			if node.is_in_group("ladders"):
				node.remove_from_group("ladders")  # no one takes a ladder that is going up
		elif not night and float(d["goal"]) == 1.0:
			d["goal"] = 0.0
		var s := move_toward(float(d["state"]), float(d["goal"]), dt / MOVE_S)
		if s != float(d["state"]):
			d["state"] = s
			var e := s * s * (3.0 - 2.0 * s)
			var down: Transform3D = d["down"]
			var up: Transform3D = d["up"]
			node.transform = Transform3D(down.basis.slerp(up.basis, e), down.origin.lerp(up.origin, e) + Vector3(0.0, sin(PI * e) * 0.8, 0.0))
			if s == 0.0 and not node.is_in_group("ladders"):
				node.add_to_group("ladders")  # set down again
			if (s == 0.0 or s == 1.0) and _knock <= 0.0 and is_instance_valid(AudioDirector):  # laid on the roof, or set down
				AudioDirector.play("SND-219.knock", node.global_position)
				_knock = 0.5  # one knock at a time: a start at night, or an hour jumped, moves them all at once
	for i in _boosts.keys():  # juniper laid on a burner: its thread thick and tall, easing back
		var left: float = float(_boosts[i]) - dt
		var b: Color = _base[i]
		var k := clampf(left / 8.0, 0.0, 1.0)
		smoke.multimesh.set_instance_custom_data(i, Color(b.r, b.g, b.b * (1.0 + 0.9 * k), b.a + 5.0 * k))
		if left <= 0.0:
			_boosts.erase(i)
		else:
			_boosts[i] = left
	_last = m


## Juniper laid on the burner nearest `p` (within 3 m): its thread thicker and taller for `seconds`. True if one was.
## A burner its household has not lit yet is lit there and then, and burns on through the window (Greg's walk, 27 Sep
## 2026: laid before its household's minute, the juniper made no smoke: the thread's strength was multiplied, and nil).
func boost(p: Vector3, seconds := 25.0) -> bool:
	for i in sang_socks.size():
		if (sang_socks[i] as Node3D).global_position.distance_to(p) < 3.0:
			_boosts[i] = seconds
			var m := day_minute()
			var open := 17.0 * 60.0 if m >= 12.0 * 60.0 else 5.0 * 60.0 + 45.0  # the evening's window, or the morning's
			var b: Color = _base[i]
			if b.g > m - open - 4.0:  # its thread full now (smoke.gdshader's window rises over four minutes from its minute)
				b.g = m - open - 4.0
				_base[i] = b
				smoke.multimesh.set_instance_custom_data(i, b)
			return true
	return false


## Whether `n` stands in the building `id` (world/town.gd names each by its record's id).
static func _of(n: Node, id: String) -> bool:
	var p := n
	while p != null:
		if String(p.name) == id:
			return true
		p = p.get_parent()
	return false


## Whether the clock went past `at` (minutes of the day) between two frames, midnight included.
static func _passed(a: float, b: float, at: float) -> bool:
	if b >= a:
		return a < at and at <= b
	return at > a or at <= b


func _build_smoke(root: Node) -> void:
	var socks := root.find_children("SOCK_SANG_*", "Node3D", true, false)
	burners = socks.size()
	if burners == 0:
		return
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var col := PackedColorArray()
	var idx := PackedInt32Array()
	for k in PUFFS:
		var b := v.size()
		for c in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
			v.append(Vector3(c.x - 0.5, c.y - 0.5, 0.0))
			uv.append(c)
			col.append(Color(float(k) / PUFFS, 0.0, 0.0, 1.0))
		idx.append_array([b, b + 1, b + 2, b, b + 2, b + 3])
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_COLOR] = col
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-5.0, -1.0, -5.0), Vector3(10.0, 18.0, 10.0))  # the shader moves the puffs
	smoke_mat = ShaderMaterial.new()
	smoke_mat.shader = SMOKE
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.noise = noise
	smoke_mat.set_shader_parameter("noise_tex", tex)
	mesh.surface_set_material(0, smoke_mat)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = burners
	sang_socks = socks
	for i in burners:
		var p: Vector3 = (socks[i] as Node3D).global_position
		var h := fposmod(sin(p.x * 12.9898 + p.z * 78.233) * 43758.5453, 1.0)  # a repeatable spread per burner
		mm.set_instance_transform(i, Transform3D(Basis(), p))
		var data := Color(h, 8.0 * fposmod(h * 7.31, 1.0), 0.7 + 0.3 * fposmod(h * 3.17, 1.0), 9.0 + 5.0 * fposmod(h * 5.73, 1.0))
		for id in LATE:  # a burner lit on its own minute (smoke.gdshader: 30 or more, a morning's alone)
			if _of(socks[i] as Node, String(id)):
				data.g = float(LATE[id])
		mm.set_instance_custom_data(i, data)
		_base.append(data)
	smoke = MultiMeshInstance3D.new()
	smoke.name = "Sang"
	smoke.multimesh = mm
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(smoke)


## Each burner whose thread is burning (smoke.gdshader's windows, from its instance data) crackles with juniper, a loop
## of the sound director's (the nearest are heard); juniper laid on it (`boost`) makes it louder.
func _juniper(m: float) -> void:
	var sd: Node = AudioDirector.sound if is_instance_valid(AudioDirector) else null
	if sd == null:
		return
	for i in sang_socks.size():
		var c: Color = _base[i]
		var e := smoothstep(1020.0 + c.g, 1024.0 + c.g, m) * (1.0 - smoothstep(1065.0, 1080.0, m)) * (1.0 if c.g < 30.0 else 0.0)
		var late := c.g + 15.0 if c.g >= 30.0 else 0.0
		var a := smoothstep(345.0 + c.g, 349.0 + c.g, m) * (1.0 - smoothstep(390.0 + late, 405.0 + late, m))
		var key := "sang_%d" % i
		if maxf(e, a) > 0.3:
			sd.loop_start(key, "SND-024", (sang_socks[i] as Node3D).global_position, 4.0 if _boosts.has(i) else 0.0)
		else:
			sd.loop_stop(key)
