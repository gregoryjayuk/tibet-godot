extends Node
## The day's light (art step A7; plan chapter 09, 10.1; chapter 11, 6.1): every frame, the keyframes blended at
## WorldClock's minute, the key light pointed at the sun, or after dusk at the moon, from the Calendar. The sun's light
## fades out as it sets (its disc is gone by -2 deg), the moon takes over once the sun is 6 deg down and fades in as it
## rises, and with no moon a faint starlight falls from overhead. Behind the ridges the shaders cut the key light
## themselves, from the horizon map (art step A8; world/horizon.gd, shaders/inc/horizon.gdshaderinc).
## Also by day and night: the ink's weight (1.0 by day, 0.7 at night, so lamplit scenes are not over-drawn), the
## The valley's mist and the low sun's rays (IMP-021; chapter 09, 9.3): drawn by the ink pass (shaders/ink_air.gdshader)
## where the town stands on the valley (`mist`), its top and density by the minute (mist_at).
## glow threshold (1.3 by day, 0.9 at night, so lamps bloom), and the lamps behind the paper windows (g_night_glow,
## kit step K3): lit as the light goes (chapter 09's K09, 16:35 on the terrain since 26 Sep 2026, "windows begin"), out at bedtime about 21:30, lit
## again before dawn.

const Keyframes := preload("res://world/keyframes.gd")
const Stars := preload("res://world/stars.gd")
const Snowfall := preload("res://world/snowfall.gd")

var sun: DirectionalLight3D
var env: Environment
var data := {}
var last := {}  ## the last blend applied, for tests and the HUD
var fog_scale := 1.0  ## the keyframes' fog density is set for the town; the 15 km valley takes about a quarter
var mist := false  ## the valley's mist and the low sun's rays: on where the town stands on the valley (tests/terrain/s3.gd)
var mist_sea := false  ## the mist sea of chapter 08's V-22 (one dawn in four) instead of the river mist: s3's --mist=sea
## The weather's snow (IMP-021, item 4; s3's --snow=, tools/play.sh's SNOW): "" the season's own, fresh snow above about
## 4,300 m (chapter 01, 9.1); "dust" a dusting down to 3,500 m after a cold clear night, the skyline white from Tsongra;
## "v31" chapter 08's V-31, the afternoon of 7 November, snow falling down to the monastery (2,880 m) and the town wet
## under it; "town" the morning after a snowfall down into the valley, beyond the design's calendar (Greg's 1781): the
## roofs, copings and steps white, the lanes trodden; "falling" the same with the snow still coming down.
var snow := ""
const SNOW := {"": [4300.0, 0.0, false], "dust": [3500.0, 0.0, false], "v31": [2880.0, 0.0, true],
		"town": [2500.0, 0.85, false], "falling": [2500.0, 0.7, true]}  ## the snow line, the town's cover, falling
var snowfall: GPUParticles3D
const DATUM := 2662.0  ## world y 0's altitude (world/town.gd)


func _ready() -> void:
	add_to_group("day")  # the rooms' daylight reads `last` (interiors/room.gd)
	data = Keyframes.load_all()


## The night sky (art step A6) is part of the day: switched on in the sky's shader once, with the stars and latitude.
func _night_sky() -> void:
	if env == null or env.sky == null or not (env.sky.sky_material is ShaderMaterial):
		return
	var sky := env.sky.sky_material as ShaderMaterial
	if float(sky.get_shader_parameter("night_sky") if sky.get_shader_parameter("night_sky") != null else 0.0) > 0.5:
		return
	sky.set_shader_parameter("star_cells", Stars.texture())
	sky.set_shader_parameter("latitude", Calendar.lat)
	sky.set_shader_parameter("night_sky", 1.0)


## The valley's mist at a minute of the day (design; chapter 09, 9.3, and chapter 01, 9.3's river mist of clear dawns):
## a thin haze gathering in the valley's bottom from 17:15, its top rising from 2,575 m to 2,600 m by 21:00; through the
## small hours it thickens into the dawn's river mist, topped at 2,610 m, full from 04:00, lifting 15 m and thinning away
## from 07:00 to 08:30; none by day. The mist sea instead tops at 2,720 m, denser, and lifts from 07:30 to 09:30 (V-22:
## Tsongra and lower Shöl inside it, the upper town above). Returns its top's altitude and its density a metre.
static func mist_at(t: float, sea := false) -> Vector2:
	var top := 2720.0 if sea else 2610.0
	var dense := 0.03 if sea else 0.02
	var lift0 := 450.0 if sea else 420.0
	var lift1 := 570.0 if sea else 510.0
	if t >= 1035.0:
		var k := smoothstep(1035.0, 1260.0, t)
		return Vector2(lerpf(2575.0, 2600.0, k), lerpf(0.004, 0.010, k))
	if t < 240.0:
		var g := t / 240.0
		return Vector2(lerpf(2600.0, top, g), lerpf(0.010, dense, g))
	if t < lift0:
		return Vector2(top, dense)
	if t < lift1:
		var l := smoothstep(lift0, lift1, t)
		return Vector2(top + 15.0 * l, dense * (1.0 - l))
	return Vector2(top, 0.0)


func _process(_dt: float) -> void:
	if sun == null:
		return
	update(WorldClock.minute)


func update(minute: float) -> void:
	_night_sky()
	var v := Keyframes.blend(data, fposmod(minute, 1440.0))
	var sun_aa := Calendar.sun_alt_az(minute)
	var rs := RenderingServer
	rs.global_shader_parameter_set("g_sun_alt", sun_aa.x)
	rs.global_shader_parameter_set("g_sun_az", sun_aa.y)
	rs.global_shader_parameter_set("g_moon_dir", Calendar.moon_direction(minute))
	rs.global_shader_parameter_set("g_moon_phase", Calendar.moon_illumination(minute))
	rs.global_shader_parameter_set("g_lst", Calendar.lst(minute))
	rs.global_shader_parameter_set("g_game_minute", minute)
	var dir := Calendar.direction(sun_aa)
	var vis := smoothstep(-2.0, 1.0, sun_aa.x)
	var shadows := sun_aa.x > -2.0
	if sun_aa.x < -6.0:
		var moon_aa := Calendar.moon_alt_az(minute)
		if moon_aa.x > 0.0:
			dir = Calendar.direction(moon_aa)
			vis = smoothstep(0.0, 5.0, moon_aa.x)
			shadows = moon_aa.x > 30.0  # chapter 11, 6.1: the moon casts shadows only above 30 deg
		else:
			dir = Vector3(0.25, 1.0, 0.15).normalized()  # starlight: a faint fill from overhead
			vis = 1.0
			shadows = false
	Keyframes.apply_blend(v, dir, vis, sun, env, data)
	if env != null:
		env.fog_density *= fog_scale
	sun.shadow_enabled = shadows
	var day := smoothstep(-6.0, 6.0, sun_aa.x)
	if env != null:
		env.glow_hdr_threshold = lerpf(0.9, 1.3, day)
	var t := fposmod(minute, 1440.0)
	var lamps := smoothstep(960.0, 1020.0, t) * (1.0 - smoothstep(1260.0, 1320.0, t)) + smoothstep(285.0, 315.0, t) * (1.0 - smoothstep(390.0, 435.0, t))
	var glow := (1.0 - smoothstep(-4.0, 8.0, sun_aa.x)) * lamps
	RenderingServer.global_shader_parameter_set("g_night_glow", glow)
	v["night_glow"] = glow
	var mt := mist_at(t, mist_sea) if mist else Vector2(-10000.0, 0.0)
	# the rays from the time the sun is low enough to meet the ridges round the valley (they take it at 12-16 deg)
	var rays := smoothstep(32.0, 14.0, sun_aa.x) * smoothstep(-4.0, 0.5, sun_aa.x) if mist else 0.0
	for ink in get_tree().root.find_children("Ink", "MeshInstance3D", true, false):
		var m := (ink as MeshInstance3D).material_override as ShaderMaterial
		if m != null:
			m.set_shader_parameter("weight", lerpf(0.7, 1.0, day))
			m.set_shader_parameter("mist_top", mt.x - DATUM)
			m.set_shader_parameter("mist_density", mt.y)
			m.set_shader_parameter("rays", rays)
	var sn: Array = SNOW.get(snow, SNOW[""])
	rs.global_shader_parameter_set("g_snow_line", float(sn[0]))
	rs.global_shader_parameter_set("g_snow", float(sn[1]))
	if bool(sn[2]) and snowfall == null:
		snowfall = Snowfall.new()
		add_child(snowfall)
	if snowfall != null:
		snowfall.emitting = bool(sn[2])
		snowfall.call("light", lerpf(0.2, 1.0, day))
	if bool(sn[2]):  # while it snows the sky is overcast: the distance hazed, the sun's light thinned
		if env != null:
			env.fog_density *= 4.0
		sun.light_energy *= 0.55
	v["snow_line"] = sn[0]
	v["snow"] = sn[1]
	v["mist_top"] = mt.x
	v["mist_density"] = mt.y
	v["rays"] = rays
	v["sun_alt"] = sun_aa.x
	v["light_dir"] = dir
	v["visible"] = vis
	last = v
