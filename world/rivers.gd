extends Node3D
## The rivers' water (M2 sprint 5, step 2; ISS-144; plan chapter 02, 2.2; chapter 08, V-02): each river of
## data/rivers.json (tools/terrain/rivers.py, its line moved onto the built trough, its water fitted under its banks) laid
## as a ribbon on its water, wet stretch by wet stretch, ACROSS strips from its left bank to its right, drawn by
## shaders/water.gdshader: the Dungchu milky, the Serchu amber over its gravel, the two side by side down Samkha's slot
## for the first hundred metres below the confluence and then one, the Yalong green-grey; the current moving downstream at
## the speed its slope gives it, foam on its rapids, the Conch Fall a white sheet. Added with the terrain by
## tests/terrain/s3.gd; `ribbon` is pure, for the tests.

const Town := preload("res://world/town.gd")
const WATER_SHADER := preload("res://shaders/water.gdshader")
const SPRAY_SHADER := preload("res://shaders/fall_spray.gdshader")
const DATA := "res://data/rivers.json"
const ACROSS := 6  ## strips across a ribbon
const EDGE := 0.35  ## metres the ribbon's edges reach past the water's edges, under the banks
const GAP := 6  ## dry points (5 m apart) a stretch carries on through, under the ground
const CODE := {"dungchu": 0.0, "serchu": 1.0, "mixed": 2.0, "yalong": 3.0}
const PUFFS := 48  ## the Conch Fall's spray: puffs

var meshes: Array[MeshInstance3D] = []
var runs := 0  ## wet stretches drawn
var material: ShaderMaterial
var spray: MeshInstance3D  ## the Conch Fall's spray, at its foot
var pool: MeshInstance3D  ## the pool at the confluence
var fall_foot := -1  ## the slot's point at the fall's foot


## The stretches of a river to draw, from its points ([x, y, z, left width, right width, wet]...): from a wet point to the
## last wet one before a dry gap longer than GAP points (where the ground stands over the water the ribbon lies under it
## and is not seen; the water is never above its banks: tools/terrain/rivers.py), each [first, last], two points or more.
static func wet_runs(pts: Array) -> Array:
	var out := []
	var a := -1
	var last_wet := -1
	for i in pts.size():
		if int(pts[i][5]) >= 1:
			if a < 0:
				a = i
			elif i - last_wet - 1 > GAP:
				if last_wet - a >= 1:
					out.append([a, last_wet])
				a = i
			last_wet = i
	if a >= 0 and last_wet - a >= 1:
		out.append([a, last_wet])
	return out


## One wet stretch as a ribbon's arrays: points in Godot (`at`), each side's wet width (`wl`, `wr`, looking downstream),
## their codes and the metres each lies below the confluence (`from_c`). Vertices ACROSS+1 a point, from EDGE beyond the
## left edge to EDGE beyond the right; UV.x across from the left bank, UV.y metres along the water, CUSTOM0 (water, slope,
## from_c, speed). `open_start`, `open_end`: that end joins the pool at the confluence (wet 2), not tapered; `edge` how
## far the edges reach past the water's (a leat's channel: world/leat.gd).
static func ribbon(at: PackedVector3Array, wl: PackedFloat32Array, wr: PackedFloat32Array, code: PackedFloat32Array, from_c: PackedFloat32Array, open_start := false, open_end := false, edge := EDGE) -> Array:
	var n := at.size()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var custom := PackedFloat32Array()
	var idx := PackedInt32Array()
	var along := 0.0
	for i in n:
		if i > 0:
			along += at[i].distance_to(at[i - 1])
		var fwd := (at[mini(i + 1, n - 1)] - at[maxi(i - 1, 0)])
		var flat := Vector3(fwd.x, 0.0, fwd.z)
		var dir := flat.normalized() if flat.length() > 0.0001 else Vector3(0.0, 0.0, -1.0)
		var right := dir.cross(Vector3.UP).normalized()  # looking downstream
		var run := flat.length()
		var slope := absf(fwd.y) / maxf(run, 0.05)
		var speed := clampf(0.6 + slope * 9.0, 0.5, 4.5)
		var up := right.cross(fwd.normalized() if fwd.length() > 0.0001 else dir).normalized()  # tilted down a fall
		# a stretch's ends narrow into the ground, not cut square; but not where it joins the pool, under the pool's surface
		var taper := minf(1.0, float(mini(n if open_start else i, n if open_end else n - 1 - i) + 1) / 3.0)
		for k in ACROSS + 1:
			var u := float(k) / ACROSS
			verts.append(at[i] + right * lerpf(-(wl[i] + edge), wr[i] + edge, u) * taper)
			normals.append(up)
			uvs.append(Vector2(u, along))
			custom.append_array([code[i], slope, from_c[i], speed])
	for i in n - 1:
		for k in ACROSS:
			var a := i * (ACROSS + 1) + k
			var b := a + ACROSS + 1
			idx.append_array([a, b, a + 1, a + 1, b, b + 1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_CUSTOM0] = custom
	arrays[Mesh.ARRAY_INDEX] = idx
	return arrays


## Builds every river's wet stretches; returns a line for the log.
func build(noise: Texture2D) -> String:
	if not FileAccess.file_exists(DATA):
		return "no data/rivers.json (tools/terrain/rivers.py)"
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	material = ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter("noise_tex", noise)
	material.set_shader_parameter("mix_m", float(d.get("mix", 100.0)))
	var slot_len := 0.0  # the slot's length: the fan goes on counting below the confluence from its end
	var tris := 0
	for r in d["rivers"]:
		var pts: Array = r["pts"]
		var water: Array = r["water"]
		var name := String(r["name"])
		# the metres below the confluence: the slot's own; the fan's from the slot's end; the rest far
		var fc := PackedFloat32Array()
		fc.resize(pts.size())
		var acc := 0.0
		for i in pts.size():
			if i > 0:
				acc += Vector2(float(pts[i][0]) - float(pts[i - 1][0]), float(pts[i][1]) - float(pts[i - 1][1])).length()
			fc[i] = acc if name == "Samkha slot" else (slot_len + acc if name == "Dungchu fan" else 99999.0)
		if name == "Samkha slot":
			slot_len = acc
			var fall: Dictionary = d.get("fall", {})
			fall_foot = int(fall.get("foot", -1))
			var lip := int(fall.get("lip", -1))
			if fall_foot <= 0 or fall_foot >= pts.size():  # data from before the arc: the step itself
				fall_foot = foot(pts, float(fall.get("drop", 7.0)))
				lip = fall_foot - 1
			if fall_foot > 0:
				material.set_shader_parameter("fall_at", fc[fall_foot])
				if int(pts[fall_foot][5]) == 1:
					_spray(pts, fall_foot, noise, float(pts[lip][2]) - float(pts[fall_foot][2]))
		for run in wet_runs(pts):
			var at := PackedVector3Array()
			var wl := PackedFloat32Array()
			var wr := PackedFloat32Array()
			var code := PackedFloat32Array()
			var from_c := PackedFloat32Array()
			for i in range(int(run[0]), int(run[1]) + 1):
				var q: Array = pts[i]
				at.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
				wl.append(float(q[3]))
				wr.append(float(q[4]))
				code.append(float(CODE.get(String(water[i]), 0.0)))
				from_c.append(fc[i])
			var arrays := ribbon(at, wl, wr, code, from_c, int(pts[int(run[0])][5]) == 2, int(pts[int(run[1])][5]) == 2)
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {},
					Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
			var mi := MeshInstance3D.new()
			mi.name = "%s_%d" % [name.replace(" ", "_"), int(run[0])]
			mi.mesh = mesh
			mi.material_override = material
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
			meshes.append(mi)
			runs += 1
			tris += (at.size() - 1) * ACROSS * 2
	if d.has("pool"):
		_pool(d["pool"])
	add_to_group("rivers")
	return "%d wet stretches of %d rivers, %d triangles%s%s" % [runs, (d["rivers"] as Array).size(), tris, ", the pool at the confluence" if pool else "", ", the Conch Fall's spray" if spray else ""]


## The pool at the confluence (data/rivers.json "pool"; chapter 08, V-02): one surface at its water's level out to its
## rim, under the ground's edge, the rivers' ribbons joining it under its surface; drawn as the slot's head is (water
## code 2, below the confluence by nothing): the Serchu's amber left of the slot's axis looking downstream, the Dungchu's
## milk right of it, their seam carried up through the pool from the slot's head, the water slow.
func _pool(p: Dictionary) -> void:
	var c := Vector2(float(p["at"][0]), float(p["at"][1]))
	var ax := Vector2(float(p["axes"][0]), float(p["axes"][1])) * float(p.get("rim", 1.12))
	var z := float(p["z"])
	var axis := Vector2(float(p["axis"][0]), float(p["axis"][1])).normalized()
	var right := Vector2(axis.y, -axis.x)
	var from := Vector2(float(p["from"][0]), float(p["from"][1]))
	var wl := float(p["half"][0]) + EDGE
	var wr := float(p["half"][1]) + EDGE
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var custom := PackedFloat32Array()
	var idx := PackedInt32Array()
	var seg := 48
	var rings := 4
	for r in rings + 1:
		for k in (1 if r == 0 else seg):
			var a := TAU * k / seg
			var q := c + Vector2(cos(a) * ax.x, sin(a) * ax.y) * shore(p, a) * float(r) / rings
			var dq := q - from
			verts.append(Town.to_godot(q.x, q.y, z))
			normals.append(Vector3.UP)
			uvs.append(Vector2(clampf((dq.dot(right) + wl) / (wl + wr), 0.12, 0.88), dq.dot(axis)))
			custom.append_array([2.0, 0.0, 0.0, 0.4])
	for k in seg:  # clockwise seen from above: the front faces up
		idx.append_array([0, 1 + (k + 1) % seg, 1 + k])
	for r in range(1, rings):
		var a0 := 1 + (r - 1) * seg
		var b0 := 1 + r * seg
		for k in seg:
			var k1 := (k + 1) % seg
			idx.append_array([a0 + k, b0 + k1, b0 + k, a0 + k, a0 + k1, b0 + k1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_CUSTOM0] = custom
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	pool = MeshInstance3D.new()
	pool.name = "ConfluencePool"
	pool.mesh = mesh
	pool.material_override = material
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pool)
	meshes.append(pool)


## The pool's radius at angle `a` (from the east, in its axes' frame) as a share of its axes: its shore's wandering
## (data/rivers.json "pool" "shape", tools/terrain/rivers.py `shore`).
static func shore(p: Dictionary, a: float) -> float:
	var r := 1.0
	for h in p.get("shape", []):
		r += float(h[1]) * sin(float(h[0]) * a + float(h[2]))
	return r


## The point at the foot of a river's fall (its water `drop` or near it below the point before), or -1.
static func foot(pts: Array, drop: float) -> int:
	for i in range(1, pts.size()):
		if float(pts[i - 1][2]) - float(pts[i][2]) > 0.8 * drop:
			return i
	return -1


## The Conch Fall's spray (shaders/fall_spray.gdshader): PUFFS quads at the fall's foot, the node's x downstream.
func _spray(pts: Array, i: int, noise: Texture2D, drop: float) -> void:
	var q: Array = pts[i]
	var at := Town.to_godot(float(q[0]), float(q[1]), float(q[2]))
	var nxt: Array = pts[mini(i + 2, pts.size() - 1)]
	var dir := Town.to_godot(float(nxt[0]), float(nxt[1]), float(q[2])) - at
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3(-1.0, 0.0, 0.0)
	var width := float(q[3]) + float(q[4]) + 2.0 * EDGE
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
	mesh.custom_aabb = AABB(Vector3(-4.0, -2.0, -width / 2.0 - 4.0), Vector3(22.0, drop + 8.0, width + 8.0))  # the shader moves the puffs
	var mat := ShaderMaterial.new()
	mat.shader = SPRAY_SHADER
	mat.set_shader_parameter("noise_tex", noise)
	mat.set_shader_parameter("width", width)
	mat.set_shader_parameter("drop", drop)
	spray = MeshInstance3D.new()
	spray.name = "ConchFallSpray"
	spray.mesh = mesh
	spray.material_override = mat
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spray.transform = Transform3D(Basis(dir, Vector3.UP, dir.cross(Vector3.UP)), at)
	add_child(spray)
