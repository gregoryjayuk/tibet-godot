extends Node3D
## The Leat Fall SAM-11 (M2 sprint 11, step 4; plan chapter 02: "the Shöl leat falls into the slot"): the leat's water
## spouting from its culvert's lip in the slot's face (the kit's sam11_leat_outlet, placed by world/town.gd) and falling
## down the face to the slot's river, a horsetail (shaders/leat_fall.gdshader) along its path from data/samkha_rim.json
## (tools/town/samkha_rim.py: kept off the face), spreading from WIDTH_LIP to WIDTH_FOOT; and its spray where it strikes
## the river (shaders/fall_spray.gdshader, as the Conch Fall's). Added by tests/terrain/s3.gd with the rivers.

const Town := preload("res://world/town.gd")
const DATA := "res://data/samkha_rim.json"
const SHADER := preload("res://shaders/leat_fall.gdshader")
const SPRAY := preload("res://shaders/fall_spray.gdshader")
const WIDTH_LIP := 0.45  ## the leat's width at its lip (chapter 03, 9.1: the Shöl leat 0.4 m)
const WIDTH_FOOT := 2.6  ## spread out at its foot
const PUFFS := 24

var path := PackedVector3Array()  ## the water's line (Godot), from the lip to the foot
var drop := 0.0


## The fall's ribbon and spray; a line for the log.
func build(noise: Texture2D) -> String:
	if not FileAccess.file_exists(DATA):
		return "no data/samkha_rim.json (tools/py tools/town/samkha_rim.py)"
	var lf: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))["leat_fall"]
	for q in lf["path"]:
		path.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
	drop = float(lf["drop"])
	if path.size() < 2:
		return "no path"
	var total := 0.0
	var cum := PackedFloat32Array([0.0])
	for i in range(1, path.size()):
		total += path[i].distance_to(path[i - 1])
		cum.append(total)
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var across := Vector3(1.0, 0.0, 0.0)  # the face runs east-west: the ribbon across it
	for i in path.size():
		var t := cum[i] / total
		var half := lerpf(WIDTH_LIP, WIDTH_FOOT, sqrt(t)) / 2.0
		v.append(path[i] - across * half)
		v.append(path[i] + across * half)
		uv.append(Vector2(0.0, t))
		uv.append(Vector2(1.0, t))
		if i > 0:
			var b := 2 * (i - 1)
			idx.append_array([b, b + 1, b + 3, b, b + 3, b + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("noise_tex", noise)
	mat.set_shader_parameter("drop", drop)
	var water := MeshInstance3D.new()
	water.name = "LeatFallWater"
	water.mesh = mesh
	water.material_override = mat
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
	_spray(noise)
	return "the Leat Fall: %.0f m of water down %.0f m of the slot's face" % [total, drop]


## The spray where it strikes the river: PUFFS quads, the node's x downstream (the slot runs west).
func _spray(noise: Texture2D) -> void:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	for k in PUFFS:
		var b := v.size()
		for c in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
			v.append(Vector3(c.x - 0.5, c.y - 0.5, float(k) / PUFFS))
			uv.append(c)
		idx.append_array([b, b + 1, b + 2, b, b + 2, b + 3])
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-4.0, -2.0, -6.0), Vector3(20.0, drop * 0.5 + 8.0, 12.0))
	var mat := ShaderMaterial.new()
	mat.shader = SPRAY
	mat.set_shader_parameter("noise_tex", noise)
	mat.set_shader_parameter("width", 2.4)
	mat.set_shader_parameter("drop", minf(drop, 12.0))  # a thin fall: its spray low, not a sheet's
	mat.set_shader_parameter("strength", 0.55)
	var spray := MeshInstance3D.new()
	spray.name = "LeatFallSpray"
	spray.mesh = mesh
	spray.material_override = mat
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var downstream := Vector3(-1.0, 0.0, 0.0)
	spray.transform = Transform3D(Basis(downstream, Vector3.UP, downstream.cross(Vector3.UP)), path[path.size() - 1])
	add_child(spray)
