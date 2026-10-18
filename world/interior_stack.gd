extends Node3D
## Spike S7, the interior lighting stack (plan chapter 11, S7; chapter 04, 8; the game's M3 sprint 5, step 3): a hero
## hall's light built up a layer at a time, each layer a still for Greg and a GPU cost in a timed turn. 1: the sky
## occlusion alone (the kit's baked occlusion in the vertex colours) with the room's own lights (LR-01: the lamp bank's
## two clusters, the well's day, the door's) and the shafts' cards (world/shafts.gd). 2: with a ReflectionProbe in
## interior mode over the hall, captured once (its ambient from what it sees, not the sky). 3: with VoxelGI baked over
## the hall, the well and the lantern. 4: with an AreaLight3D under each side of the lantern, where the engine has the
## class. 5: with the volumetric fog thickened in the hall and the sun's own shadow through the lantern's lattice, the
## shafts' cards off. Until Greg picks (chapter 11: within 6 ms of GPU inside), the game runs FALLBACK: probe and lamps.
## Built as a child of the hall's own node, in its glTF frame (the kit's x, z, -y).

const FALLBACK := 2  ## S7's fallback (chapter 11): probe and lamps only
## The Tsokchen's hall in its kit frame (tibet-blender kit/monastery.py tsokchen, interior): the nave, the well and the
## lantern over it; x0, x1, y0, y1, z0, z1
const HALL := {"MON-01": {"nave": [-12.3, 12.3, -15.3, 6.575, 0.0, 6.8], "all": [-12.3, 12.3, -15.3, 6.575, 0.0, 17.15],
		"lantern": [-3.8, 3.8, -12.1, 1.1, 13.5, 17.15]}}
const FOG_DENSITY := 0.035  ## stack 5: the hall's air, a metre (the valley's inside is a tenth of its own: world/interiors.gd)

var stack := FALLBACK
var house := ""
var _built := false
var _areas: Array = []  ## stack 4's area lights and their full energy: they stand for the lantern's daylight


## Takes the hall `h` (a node of the town) and the stack `which`, and joins it; false when the hall is not one of HALL.
func setup(h: Node3D, which: int) -> bool:
	if h == null or not HALL.has(String(h.name)):
		return false
	name = "S7"
	stack = which
	house = String(h.name)
	process_priority = 100  # (after world/interiors.gd, which thins the fog inside each frame)
	h.add_child(self)
	return true


static func _g(x: float, y: float, z: float) -> Vector3:  # the kit's frame into the hall node's (glTF's)
	return Vector3(x, z, -y)


func _box(key: String) -> AABB:
	var b: Array = HALL[house][key]
	var lo := _g(b[0], b[3], b[4])
	var hi := _g(b[1], b[2], b[5])
	return AABB(lo, hi - lo).abs()


func _layers() -> void:
	if stack >= 2:
		var p := ReflectionProbe.new()
		p.name = "Probe"
		var a := _box("all")
		p.position = a.get_center()
		p.size = a.size
		p.interior = true
		p.box_projection = true
		p.update_mode = ReflectionProbe.UPDATE_ONCE
		p.ambient_mode = ReflectionProbe.AMBIENT_ENVIRONMENT
		p.intensity = 1.0
		add_child(p)
	if stack >= 3:
		var gi := VoxelGI.new()
		gi.name = "VoxelGI"
		var a := _box("all")
		gi.position = a.get_center()
		gi.size = a.size + Vector3(1.0, 1.0, 1.0)
		gi.subdiv = VoxelGI.SUBDIV_128
		add_child(gi)
		gi.bake.call_deferred()
	if stack >= 4 and ClassDB.class_exists("AreaLight3D"):
		var l := _box("lantern")
		for side in [-1.0, 1.0]:  # under each long side of the lantern, facing down into the well
			var al: Light3D = ClassDB.instantiate("AreaLight3D")
			al.name = "Area_%s" % ("w" if side < 0.0 else "e")
			al.position = Vector3(l.get_center().x + side * l.size.x * 0.4, l.position.y + 0.2, l.get_center().z)
			al.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
			al.light_color = Color("#F3EBDD")
			al.light_energy = 2.5
			for prop in [["area_size", Vector2(1.2, l.size.z * 0.8)], ["area_range", 14.0], ["area_normalize_energy", false]]:
				if prop[0] in al:
					al.set(prop[0], prop[1])
			add_child(al)
			_areas.append([al, al.light_energy])
	if stack >= 5:
		var dn := get_tree().get_first_node_in_group("day")
		var env: Environment = dn.get("env") if dn != null else null
		var sun: DirectionalLight3D = dn.get("sun") if dn != null else null
		if env != null:
			env.volumetric_fog_enabled = true
		if sun != null:
			sun.shadow_enabled = true
			sun.light_volumetric_fog_energy = 4.0
		for sh in get_tree().get_nodes_in_group("shafts"):
			(sh as Node3D).visible = false


## The layers are built once the nave's furnishings have streamed in at its door (world/interiors.gd), so the probe
## and the VoxelGI capture the hall furnished; then stack 5 holds the hall's air thick while the camera is in it
## (world/interiors.gd thins the valley's fog to a tenth inside).
func _process(_dt: float) -> void:
	if not _built:
		var room := (get_parent() as Node3D).find_child("SOCK_ROOM_1", true, false) as Node3D
		if room == null or room.get_child_count() == 0:
			return
		_built = true
		_layers()
	# the area lights with the day beyond the lantern: full with the sun 30 degrees up, none before sunrise
	var alt := Calendar.sun_alt_az(WorldClock.minute).x
	for a in _areas:
		(a[0] as Light3D).light_energy = float(a[1]) * clampf(alt / 30.0, 0.0, 1.0)
	if stack < 2:
		set_process(false)
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var inside := _box("all").grow(0.5).has_point((get_parent() as Node3D).global_transform.affine_inverse() * cam.global_position)
	# the rooms' surfaces take a GI's light whole, not under their baked sky occlusion (shaders/stylized_static.gdshader),
	# while the camera is in the hall: no other room is seen from inside it
	RenderingServer.global_shader_parameter_set("g_gi_inside", 1.0 if inside else 0.0)
	if stack < 5:
		return
	var dn := get_tree().get_first_node_in_group("day")
	var env: Environment = dn.get("env") if dn != null else null
	if env == null:
		return
	if inside:
		env.volumetric_fog_density = FOG_DENSITY
		if not has_meta("said"):
			set_meta("said", true)
			print("s7: stack 5 inside: fog %s at %.3f, the sun's shadow %s, its fog energy %.1f" % [env.volumetric_fog_enabled, env.volumetric_fog_density, (dn.get("sun") as DirectionalLight3D).shadow_enabled if dn.get("sun") != null else false, (dn.get("sun") as DirectionalLight3D).light_volumetric_fog_energy if dn.get("sun") != null else 0.0])
