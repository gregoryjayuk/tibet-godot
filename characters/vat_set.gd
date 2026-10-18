class_name VatSet
extends RefCounted
## One baked VAT figure (people2/stand_ins.py in ../tibet-blender): its texture from <name>_vat.bin (RGBA half floats,
## loaded as raw data so no importer can compress it), its static mesh from <name>_vat.glb and its clips; and the
## MultiMeshInstance3D that draws many of it (characters/vat.gdshader). Instance data per figure: a transform, a
## colour (the tint) and custom data (first row, frames, phase in frames, rate) -- 20 floats in the buffer.

const DIR := "res://assets/generated/people/"
const SHADER := preload("res://characters/vat.gdshader")
const FLOATS := 20

var name := ""
var info := {}
var texture: ImageTexture
var mesh: Mesh
var material: ShaderMaterial


static var _cache := {}  ## name -> VatSet: one texture and one mesh a figure, however many draw it (the crowd, the herd, the camp)


static func open(n: String) -> VatSet:
	if _cache.has(n):
		return _cache[n]
	var v := VatSet.new()
	v.name = n
	v.info = JSON.parse_string(FileAccess.get_file_as_string(DIR + n + "_vat.json"))
	var bytes := FileAccess.get_file_as_bytes(DIR + n + "_vat.bin")
	var img := Image.create_from_data(int(v.info["width"]), int(v.info["height"]), false, Image.FORMAT_RGBAH, bytes)
	v.texture = ImageTexture.create_from_image(img)
	var scene: Node = (load(DIR + n + "_vat.glb") as PackedScene).instantiate()
	v.mesh = (scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	scene.free()
	v.material = ShaderMaterial.new()
	v.material.shader = SHADER
	v.material.set_shader_parameter("vat", v.texture)
	v.material.set_shader_parameter("vat_fps", float(v.info["fps"]))
	v.material.set_shader_parameter("normal_row", float(v.info["normal_row"]))
	_cache[n] = v
	return v


## The clip's first row and frame count, its length in seconds, and the fps of the bake.
func clip(c: String) -> Dictionary:
	var d: Dictionary = info["clips"][c]
	return {"row": float(d["row"]), "frames": float(d["frames"]), "seconds": float(d["seconds"]), "fps": float(info["fps"])}


func multimesh(count: int, bounds: AABB) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = count
	mm.custom_aabb = bounds  # instances move every frame; a fixed box spares the engine recomputing one
	var mmi := MultiMeshInstance3D.new()
	mmi.name = name + "_vat"
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # mid and far tiers: a blob decal later (chapter 05, 13.2)
	# Written every rendered frame, not per physics tick, so physics interpolation has nothing to do (and warned).
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return mmi


## Write one instance into a MultiMesh buffer: a yaw and a position, the tint, and the clip's animation state.
static func put(buf: PackedFloat32Array, i: int, p: Vector3, yaw_angle: float, scale: float, tint: float, c: Dictionary, phase_frames: float, rate: float) -> void:
	var o := i * FLOATS
	var cs := cos(yaw_angle) * scale
	var sn := sin(yaw_angle) * scale
	buf[o] = cs
	buf[o + 1] = 0.0
	buf[o + 2] = sn
	buf[o + 3] = p.x
	buf[o + 4] = 0.0
	buf[o + 5] = scale
	buf[o + 6] = 0.0
	buf[o + 7] = p.y
	buf[o + 8] = -sn
	buf[o + 9] = 0.0
	buf[o + 10] = cs
	buf[o + 11] = p.z
	buf[o + 12] = tint
	buf[o + 13] = tint
	buf[o + 14] = tint
	buf[o + 15] = 1.0
	buf[o + 16] = c["row"]
	buf[o + 17] = c["frames"]
	buf[o + 18] = phase_frames
	buf[o + 19] = rate


## Hide an instance: a zero basis draws nothing.
static func hide(buf: PackedFloat32Array, i: int) -> void:
	var o := i * FLOATS
	for k in 12:
		buf[o + k] = 0.0
