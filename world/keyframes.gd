extends RefCounted
## The day's light keyframes (plan chapter 09, 10.1; data/keyframes.json): apply one to a sun, an environment and the
## shader globals the lit shaders read (g_sun_dir, g_sun_col, g_shade_tint, g_lac_tint, g_indigo_tint, g_sky_fill,
## g_ground_bounce, g_ramp_row). Art step A2 uses single keys; since A7 blend() mixes them at any minute of the day and
## world/day.gd applies that every frame.

const PATH := "res://data/keyframes.json"


static func load_all() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH))


static func _lin(hex: String) -> Vector3:
	var c := Color(hex).srgb_to_linear()
	return Vector3(c.r, c.g, c.b)


## The direction towards the sun from its elevation and azimuth (clockwise from north; north is -Z, east +X).
static func sun_dir(elev_deg: float, az_deg: float) -> Vector3:
	var el := deg_to_rad(elev_deg)
	var az := deg_to_rad(az_deg)
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))


const COLOURS := ["sun_c", "zenith", "horizon", "shade", "fill", "bounce", "fog_c"]
const NUMBERS := ["energy", "ambient", "fog", "exposure", "ramp_row"]


## Every column of the day's light at a minute of the day (art step A7; chapter 09, 10.1: "the WorldClock interpolates
## every column between keyframes with a smoothstep"): the two keyframes round it, colours blended in linear light and
## returned as linear Colors. Across midnight K13 (00:30) follows K12 (20:30) and K01 (04:40) follows K13.
static func blend(data: Dictionary, minute: float) -> Dictionary:
	var ts: Array = []
	for k in data["keys"]:
		var hm: PackedStringArray = String(data["keys"][k]["time"]).split(":")
		ts.append([int(hm[0]) * 60 + int(hm[1]), k])
	ts.sort_custom(func(a, b): return a[0] < b[0])
	var m := fposmod(minute, 1440.0)
	var i := ts.size() - 1
	for j in ts.size():
		if ts[j][0] <= m:
			i = j
	var ta: float = ts[i][0]
	var tb: float = ts[(i + 1) % ts.size()][0]
	if m < ta:
		ta -= 1440.0
	if tb <= ta:
		tb += 1440.0
	var t := smoothstep(0.0, 1.0, (m - ta) / (tb - ta))
	var a: Dictionary = data["keys"][ts[i][1]]
	var b: Dictionary = data["keys"][ts[(i + 1) % ts.size()][1]]
	var out := {"from": ts[i][1], "to": ts[(i + 1) % ts.size()][1], "t": t}
	for c in COLOURS:
		out[c] = Color(a[c]).srgb_to_linear().lerp(Color(b[c]).srgb_to_linear(), t)
	for n in NUMBERS:
		out[n] = lerpf(float(a[n]), float(b[n]), t)
	return out


## Apply a blend to the key light (its direction given, as a unit vector towards the light, and a visibility factor for
## a sun or moon near the horizon), the environment, the sky and the shader globals.
static func apply_blend(v: Dictionary, light_dir: Vector3, visible: float, sun: DirectionalLight3D, env: Environment,
		data: Dictionary) -> void:
	sun.look_at_from_position(light_dir * 100.0, Vector3.ZERO, Vector3.UP if absf(light_dir.y) < 0.99 else Vector3.FORWARD)
	var key_c: Color = v["sun_c"]
	sun.light_color = key_c.linear_to_srgb()
	sun.light_energy = float(v["energy"]) * visible
	var rs := RenderingServer
	var lin := func(c: Color) -> Vector3: return Vector3(c.r, c.g, c.b)
	rs.global_shader_parameter_set("g_sun_dir", light_dir)
	rs.global_shader_parameter_set("g_sun_col", lin.call(key_c) * float(v["energy"]) * visible)
	rs.global_shader_parameter_set("g_shade_tint", lin.call(v["shade"]))
	rs.global_shader_parameter_set("g_lac_tint", _lin(data["lac_tint"]))
	rs.global_shader_parameter_set("g_indigo_tint", _lin(data["indigo_tint"]))
	rs.global_shader_parameter_set("g_sky_fill", lin.call(v["fill"]))
	rs.global_shader_parameter_set("g_ground_bounce", lin.call(v["bounce"]))
	rs.global_shader_parameter_set("g_ramp_row", float(v["ramp_row"]))
	if env != null:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 0.3
		env.ambient_light_color = (v["fill"] as Color).linear_to_srgb()
		env.ambient_light_energy = float(v["ambient"]) * 2.0  # doubled, as apply() does (DECISIONS, A2)
		env.fog_light_color = (v["fog_c"] as Color).linear_to_srgb()
		env.fog_density = float(v["fog"])
		env.tonemap_exposure = float(v["exposure"])
		if env.sky != null and env.sky.sky_material is ShaderMaterial:
			var sky := env.sky.sky_material as ShaderMaterial
			var zen: Color = v["zenith"]
			var hor: Color = v["horizon"]
			sky.set_shader_parameter("zenith", zen.linear_to_srgb())
			sky.set_shader_parameter("horizon", hor.linear_to_srgb())
			sky.set_shader_parameter("ground", (v["fog_c"] as Color).linear_to_srgb())  # below the horizon: the far ground in haze
			# The draft's clouds are lit by day; at night they are darker than the sky round them, with a faint moonlit top.
			var day := clampf(float(v["energy"]) * visible / 1.5, 0.0, 1.0)
			var night_lit := zen.lerp(hor, 0.5) * 0.9
			var night_shade := zen * 0.55
			sky.set_shader_parameter("cloud_lit", night_lit.lerp(Color(1.0, 0.99, 0.96), day).linear_to_srgb())
			sky.set_shader_parameter("cloud_shade", night_shade.lerp(Color(0.68, 0.74, 0.86).srgb_to_linear(), day).linear_to_srgb())


static func apply(key: String, sun: DirectionalLight3D, env: Environment, all := {}) -> Dictionary:
	var data: Dictionary = all if not all.is_empty() else load_all()
	var k: Dictionary = data["keys"][key]
	var d := sun_dir(k["elev"], k["az"])
	sun.look_at_from_position(d * 100.0, Vector3.ZERO, Vector3.UP if absf(d.y) < 0.99 else Vector3.FORWARD)
	sun.light_color = Color(k["sun_c"])
	sun.light_energy = float(k["energy"])
	var rs := RenderingServer
	rs.global_shader_parameter_set("g_sun_dir", d)
	rs.global_shader_parameter_set("g_sun_col", _lin(k["sun_c"]) * float(k["energy"]))
	rs.global_shader_parameter_set("g_shade_tint", _lin(k["shade"]))
	rs.global_shader_parameter_set("g_lac_tint", _lin(data["lac_tint"]))
	rs.global_shader_parameter_set("g_indigo_tint", _lin(data["indigo_tint"]))
	rs.global_shader_parameter_set("g_sky_fill", _lin(k["fill"]))
	rs.global_shader_parameter_set("g_ground_bounce", _lin(k["bounce"]))
	rs.global_shader_parameter_set("g_ramp_row", float(k["ramp_row"]))
	if env != null:
		# Chapter 09 (4.5): the sky still tints the ambient, but the keyframe's fill is 70 % of it.
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 0.3
		env.ambient_light_color = Color(k["fill"])
		# Twice the table's energy: a first guess, so the shade keeps the draft's brightness now that the fill colour
		# makes up 70 % of the ambient; A7 tunes it against the whole day.
		env.ambient_light_energy = float(k["ambient"]) * 2.0
		env.fog_light_color = Color(k["fog_c"])
		env.tonemap_exposure = float(k["exposure"])
	return k
