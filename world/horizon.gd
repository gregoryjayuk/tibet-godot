extends RefCounted
## The horizon map for the ridge shadow (art step A8; plan chapter 09, 10.2; chapter 11, 6.3): the three grids that
## tools/terrain/horizon.py bakes over the real ground (assets/generated/terrain/horizon_*.bin, float16) loaded as
## texture arrays into the shader globals that shaders/inc/horizon.gdshaderinc reads. `place` maps the scene into the
## map's frame: xyz is added to a world position (zero for the valley, whose world is the design's grid), and w = 1
## says the scene stands on its own flat ground at y = 0 (the draft street, set down at a point of the town), so a
## fragment's height above the ground is its own y. light_at() reads the map on the CPU as the shaders do, for code
## that needs to know whether a place is in the ridge's shadow (and for the unit test that holds the timing).

const DIR := "res://assets/generated/terrain/"
const GRIDS := ["fine", "core", "valley", "ring"]  ## the finest first: the confluence's, 2 m and 256 sectors (M2 sprint 5)
const EDGE := 0.025  ## degrees either side of the horizon, as the shader's HZ_EDGE
const SECTOR := 11.25

static var _grids := {}  ## name -> {images, x0, y1, res, cols, rows, eyes}: the loaded map, for light_at()
static var _place := Vector4.ZERO

## Tsongra (design 0, 0): where the draft street is set down, so the shadow takes it when chapter 02 says it takes
## Tsongra (16:10; the real ground gives 16:09, the shaped terrain 16:08: docs/terrain/sun-report.md; chapter 09's K08 is
## at 16:08 since 26 Sep 2026).
const STREET_PLACE := Vector4(0.0, 0.0, 0.0, 1.0)


## Loads the map and sets the globals; false (and every surface lit as before) when the bake is missing.
static func load_globals(place := Vector4.ZERO) -> bool:
	var meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "horizon.json")) if FileAccess.file_exists(DIR + "horizon.json") else null
	if meta == null:
		push_warning("horizon: %shorizon.json missing; run tools/py tools/terrain/horizon.py (the ridge shadow is off)" % DIR)
		return false
	var rs := RenderingServer
	for name in GRIDS:
		if not (meta["grids"] as Dictionary).has(name):  # a bake from before the fine grid
			rs.global_shader_parameter_set("g_horizon_%s_rect" % name, Vector4.ZERO)
			continue
		var g: Dictionary = meta["grids"][name]
		var w := int(g["cols"])
		var h := int(g["rows"])
		var bytes := FileAccess.get_file_as_bytes(DIR + String(g["file"]))
		var per := w * h * 8  # RGBA, half floats
		if bytes.size() != per * int(g["layers"]):
			push_warning("horizon: %s is %d bytes, expected %d; re-run the bake" % [g["file"], bytes.size(), per * int(g["layers"])])
			return false
		var images: Array[Image] = []
		for l in int(g["layers"]):
			images.append(Image.create_from_data(w, h, false, Image.FORMAT_RGBAH, bytes.slice(l * per, (l + 1) * per)))
		var tex := Texture2DArray.new()
		tex.create_from_images(images)
		var res := float(g["res"])
		rs.global_shader_parameter_set("g_horizon_" + name, tex)
		rs.global_shader_parameter_set("g_horizon_%s_rect" % name, Vector4(float(g["x0"]), float(g["y1"]), w * res, h * res))
		_grids[name] = {"images": images, "x0": float(g["x0"]), "y1": float(g["y1"]), "res": res, "cols": w, "rows": h,
			"eyes": g["eyes"], "sectors": int(g.get("sectors", 32))}
	rs.global_shader_parameter_set("g_horizon_place", place)
	_place = place
	return true


## Switches the ridge shadow off again (every surface lit as before).
static func clear() -> void:
	for name in GRIDS:
		RenderingServer.global_shader_parameter_set("g_horizon_%s_rect" % name, Vector4.ZERO)
	_grids.clear()


## The shaders' reading on the CPU (shaders/inc/horizon.gdshaderinc): 1 where the light towards `to_light` clears the
## terrain's horizon at world position `pos`, 0 where a ridge hides it. `above`: the height over the ground if known,
## else below -100 to read it from the map. 1 when no map is loaded.
static func light_at(pos: Vector3, to_light: Vector3, above := -1000.0) -> float:
	var p := pos + Vector3(_place.x, _place.y, _place.z)
	if _place.w > 0.5 and above < -100.0:
		above = pos.y
	var l := to_light.normalized()
	var alt := rad_to_deg(asin(clampf(l.y, -1.0, 1.0)))
	var az := fposmod(rad_to_deg(atan2(l.x, -l.z)), 360.0)
	var g := _grid_at(Vector2(p.x, -p.z))
	if g.is_empty():
		return 1.0
	var uv := _uv(g, Vector2(p.x, -p.z))
	if above < -100.0:
		above = p.y - _sample(g, uv, g["images"].size() - 1, 0)
	var eyes: Array = g["eyes"]
	var i := 0
	var f := 0.0
	if eyes.size() > 1:
		i = 0 if above < eyes[1] else (1 if above < eyes[2] else (2 if above < eyes[3] else 3))
		f = (clampf(above, -2.0, 80.0) - float(eyes[i])) / (float(eyes[i + 1]) - float(eyes[i]))
	var ns := int(g.get("sectors", 32))
	var gr := ns / 4
	var fs := az / (360.0 / ns)
	var s0 := int(floorf(fs)) % ns
	var t := []
	for s in [s0, (s0 + 1) % ns]:
		var a := _sample(g, uv, i * gr + s / 4, s % 4)
		t.append(a if eyes.size() == 1 else lerpf(a, _sample(g, uv, (i + 1) * gr + s / 4, s % 4), f))
	var h := rad_to_deg(atan(lerpf(t[0], t[1], fs - floorf(fs))))
	return smoothstep(h - EDGE, h + EDGE, alt)


## The ground's Godot height at a design point (x east, y north), from the map; NAN where no grid covers it.
static func ground_at(x: float, y_north: float) -> float:
	var g := _grid_at(Vector2(x, y_north))
	return NAN if g.is_empty() else _sample(g, _uv(g, Vector2(x, y_north)), g["images"].size() - 1, 0)


static func _grid_at(xy: Vector2) -> Dictionary:
	for name in GRIDS:
		if not _grids.has(name):
			continue
		var uv := _uv(_grids[name], xy)
		if uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0:
			return _grids[name]
	return {}


static func _uv(g: Dictionary, xy: Vector2) -> Vector2:
	return Vector2((xy.x - g["x0"]) / (g["cols"] * g["res"]), (g["y1"] - xy.y) / (g["rows"] * g["res"]))


## Bilinear between texel centres, edges clamped, as the GPU filters: one channel of one layer.
static func _sample(g: Dictionary, uv: Vector2, layer: int, channel: int) -> float:
	var img: Image = g["images"][layer]
	var c := clampf(uv.x * g["cols"] - 0.5, 0.0, g["cols"] - 1.0)
	var r := clampf(uv.y * g["rows"] - 0.5, 0.0, g["rows"] - 1.0)
	var i := mini(int(r), g["rows"] - 2)
	var j := mini(int(c), g["cols"] - 2)
	var fr := r - i
	var fc := c - j
	var v00: float = img.get_pixel(j, i)[channel]
	var v01: float = img.get_pixel(j + 1, i)[channel]
	var v10: float = img.get_pixel(j, i + 1)[channel]
	var v11: float = img.get_pixel(j + 1, i + 1)[channel]
	return lerpf(lerpf(v00, v01, fc), lerpf(v10, v11, fc), fr)
