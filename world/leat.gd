extends Node3D
## The Serchu leat's water (M2 sprint 12, step 5; plan chapter 02, 6.1; data/serchu_mills.json, tools/town/serchu_mills.py):
## its stretches from the intake down the cascade, each mill's tail race out of its arch, the chutes from the leat's end
## down to the mills' wheels and the last wheel's race to the river, each a ribbon on its water (world/rivers.gd's
## `ribbon`, drawn by shaders/water.gdshader as the Serchu's amber: the leat slow at its 1%, the chutes and the race white
## where they fall) inside its channel (../tibet-blender export_serchu.py), its edges under the banks. Added with the
## rivers by tests/terrain/s3.gd (--off=rivers leaves it out). `ribbons` for the tests.

const Town := preload("res://world/town.gd")
const Rivers := preload("res://world/rivers.gd")
const WATER_SHADER := preload("res://shaders/water.gdshader")
const DATA := "res://data/serchu_mills.json"
const HALF := 0.3  ## the water's half-width in the channel (0.7 m between its banks)
const EDGE := 0.04
const CHUTE_HALF := 0.15  ## in a chute (0.38 m between its sides)
const RACE_HALF := 0.3
const SERCHU := 1.0  ## the water's code in the shader: the Serchu's amber
const DUNGCHU := 0.0  ## the Dungchu's milky blue (world/rivers.gd CODE)
const GORGE := "res://data/gorge_stair.json"
const TODE_LEAT := "res://data/tode_leat.json"  ## Tödé's leat TOD-10 (tools/town/tode_leat.py; M3 sprint 4, step 4)
const SAMPLE := 0.5  ## metres between a chute's points

var ribbons := 0


## The water's ribbons; a line for the log.
func build(noise: Texture2D) -> String:
	if not FileAccess.file_exists(DATA):
		return "leat: no data/serchu_mills.json (tools/py tools/town/serchu_mills.py)"
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter("noise_tex", noise)
	var lines := []  # [points (town), half-width, edge, the water's code]
	for st in d["leat"]:
		lines.append([st["pts"], RACE_HALF if st.get("race", false) else HALF, EDGE, SERCHU])
	if FileAccess.file_exists(GORGE):  # the gorge's water wheel's channel and race, the Dungchu's milky water (M3 sprint 2, step 4)
		for st in (JSON.parse_string(FileAccess.get_file_as_string(GORGE)) as Dictionary).get("leat", []):
			lines.append([st["pts"], RACE_HALF if st.get("race", false) else HALF, EDGE, DUNGCHU])
	var chutes: Array = (d["chutes"] as Array).duplicate()
	if FileAccess.file_exists(TODE_LEAT):  # Tödé's leat TOD-10, a mountain stream's water (M3 sprint 4, step 4): its stretches and chutes
		var tl: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TODE_LEAT))
		for st in tl.get("leat", []):
			lines.append([st["pts"], RACE_HALF if st.get("race", false) else HALF, EDGE, DUNGCHU])
		chutes += tl.get("chutes", [])
	for ch in chutes:
		var a: Array = ch["pts"][0]
		var b: Array = ch["pts"][1]
		var n := maxi(2, int(Vector2(float(b[0]) - float(a[0]), float(b[1]) - float(a[1])).length() / SAMPLE) + 1)
		var pts := []
		for k in n:
			var t := float(k) / float(n - 1)
			pts.append([lerpf(a[0], b[0], t), lerpf(a[1], b[1], t), lerpf(a[2], b[2], t) - 0.05])  # (in its trough, under its sides' tops)
		lines.append([pts, CHUTE_HALF, 0.02, SERCHU])
	var tris := 0
	for L in lines:
		var pts: Array = L[0]
		if pts.size() < 2:
			continue
		var at := PackedVector3Array()
		var wl := PackedFloat32Array()
		var wr := PackedFloat32Array()
		var code := PackedFloat32Array()
		var from_c := PackedFloat32Array()
		for q in pts:
			at.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
			wl.append(float(L[1]))
			wr.append(float(L[1]))
			code.append(float(L[3]))
			from_c.append(99999.0)
		var arrays := Rivers.ribbon(at, wl, wr, code, from_c, true, true, float(L[2]))
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 400.0
		add_child(mi)
		ribbons += 1
		tris += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return "leat: %d ribbons, %d triangles" % [ribbons, tris]
