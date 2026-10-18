extends Node3D
## A room's own light (plan chapter 04, 8.2-8.4; the game's sprint 7, step 1): the lights a room scene carries
## (tools/build/make_rooms.gd), at most three, driven here every frame. Daylight lights (meta kind "day": the doorway's,
## a window's) follow the day beyond them: the sun's strength while it reaches the door (the ridge's shadow takes it,
## world/horizon.gd), and the sky's, and the doorway's only as far as its door stands open (world/doors.gd; ISS-105); fires ("fire": a stove's mouths, a brazier) breathe slowly with a quicker ember
## flicker; flames ("flame": a lamp) flicker +/-8 % at 6-10 Hz. A kitchen's stove is heard while the room is in (SND-025, a
## loop of the sound director's at its first fire). `box` is the room in the scene's frame, `gain` the eye's
## adjustment inside it (chapter 04, 8.2's exposure targets, as a gain on the yard's exposure: world/interiors.gd).
## The node stands first among its scene's children, so the Streamer adds it last, after the lights (autoload/streamer.gd).

const Horizon := preload("res://world/horizon.gd")

@export var room_id := ""
@export var recipe := "LR-09T"
@export var gain := 2.5
@export var box := AABB()
@export var floor_band := Vector2(-1000.0, 1000.0)  ## the camera's height over the room's floor within which its lights burn (a house of floors: the headman's, M2 sprint 7)
@export var shadows := true  ## false: its furnishings cast no shadow (the Parkhang's block store, its 10,000 blocks seen only from inside: M3 sprint 5, step 8)

var lights: Array = []  ## [OmniLight3D, kind, base energy, phase]
var day: Node
var daylight := 1.0  ## 1 at noon in the sun, for the tests and the HUD
var _sun_at_door := 1.0
var _tick := 0
var _doors: Node  ## world/doors.gd, for a doorway's daylight (a room with no door of its own takes 1)
var _dusk_lamps: Array = []  ## flames lit only from dusk to bedtime (a poor house's lamp, chapter 04, 4.2)
var _music_on := false
var _shaft: MeshInstance3D  ## a smoke hole's shaft of day (shaders/shaft.gdshader), as bright as the day beyond
const DUSK := [1050.0, 1320.0]  ## game minutes: 17:30 to 22:00


func _ready() -> void:
	_reverb()
	_couplets()
	if not shadows:
		for mi in get_parent().find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	day = get_tree().get_first_node_in_group("day")
	for c in get_parent().get_children():
		if c is OmniLight3D:
			var l := c as OmniLight3D
			lights.append([l, String(l.get_meta("kind", "day")), l.light_energy, randf() * 100.0])
	for c in get_parent().get_children():
		if c is MeshInstance3D and c.has_meta("dusk"):
			_dusk_lamps.append(c)
		if c is MeshInstance3D and c.has_meta("shaft"):
			_shaft = c
	_update(0.0)
	_hearth(true)


func _exit_tree() -> void:
	_hearth(false)
	_music(false)


## The room's music while its hours last (meta "music": [sound, from, to (game minutes), where in the room]): the chang
## house's dranyen from 19:00 (SND-229, a stand-in until it is played and recorded).
func _music(on: bool) -> void:
	if not has_meta("music") or not is_instance_valid(AudioDirector) or AudioDirector.sound == null:
		return
	var key := "music_%d" % get_instance_id()
	if on == _music_on:
		return
	_music_on = on
	if on:
		var mu: Array = get_meta("music")
		AudioDirector.sound.loop_start(key, String(mu[0]), (get_parent() as Node3D).to_global(mu[3] as Vector3))
	else:
		AudioDirector.sound.loop_stop(key)


## The kitchen's stove heard (SND-025) at its first fire, while the room is streamed in (an LR-04 room: a kitchen, a
## poor house's one room round its hearth).
func _hearth(on: bool) -> void:
	if recipe != "LR-04" or not is_instance_valid(AudioDirector) or AudioDirector.sound == null:
		return
	var key := "hearth_%d" % get_instance_id()
	if not on:
		AudioDirector.sound.loop_stop(key)
		return
	for e in lights:
		if String(e[1]) == "fire":
			AudioDirector.sound.loop_start(key, "SND-025", (e[0] as Node3D).global_position)
			return


func _process(dt: float) -> void:
	_update(dt)
	if _couplet_gloss != "":  # the couplets' gloss, the first time they are looked at from within 4 m
		var cam := get_viewport().get_camera_3d()
		if cam != null:
			var at := (get_parent() as Node3D).to_global(_couplet_at)
			var to := at - cam.global_position
			if to.length() < 4.0 and (-cam.global_transform.basis.z).dot(to.normalized()) > 0.95:
				var hud := get_tree().get_first_node_in_group("hud")
				if hud != null:
					hud.call("gloss", _couplet_gloss, "couplet_" + room_id)
				_couplet_gloss = ""


## The day beyond the room: the sun's part while it reaches the door, the sky's part, about 1.3 at noon, 0.7 as the
## light goes at 16:35, next to nothing at night.
func day_factor() -> float:
	if day == null or not (day.get("last") is Dictionary) or (day.get("last") as Dictionary).is_empty():
		return 1.0
	var v: Dictionary = day.get("last")
	var sun := float(v.get("energy", 2.0)) * float(v.get("visible", 1.0)) * _sun_at_door
	return sun * 0.4 + maxf(float(v.get("ambient", 0.36)) - 0.2, 0.0) * 2.5


func _update(_dt: float) -> void:
	_tick += 1
	if _tick % 30 == 1 and day != null and (day.get("last") as Dictionary).has("light_dir"):
		var to_light: Vector3 = (day.get("last") as Dictionary)["light_dir"]
		_sun_at_door = Horizon.light_at(global_position + Vector3(0, 1.5, 0), to_light) if float((day.get("last") as Dictionary).get("sun_alt", 0.0)) > 0.0 else 0.0
	daylight = day_factor()
	if _doors == null:
		_doors = get_tree().get_first_node_in_group("doors")
	var open_door := float(_doors.call("openness_near", global_position)) if _doors != null else 1.0
	var t := Time.get_ticks_msec() / 1000.0
	if has_meta("music") and _tick % 15 == 2:
		var mu: Array = get_meta("music")
		var mm := fposmod(WorldClock.minute, 1440.0)
		_music(mm >= float(mu[1]) and mm < float(mu[2]))
	if not _dusk_lamps.is_empty():
		var m := fposmod(WorldClock.minute, 1440.0)
		for f in _dusk_lamps:
			(f as Node3D).visible = m >= DUSK[0] and m < DUSK[1]
	if _shaft != null:
		(_shaft.material_override as ShaderMaterial).set_shader_parameter("strength", daylight)
		_shaft.visible = daylight > 0.02
	var on_floor := true
	if floor_band.x > -999.0:
		var cam := get_viewport().get_camera_3d()
		if cam != null:
			var cy := (get_parent() as Node3D).to_local(cam.global_position).y
			on_floor = cy >= floor_band.x and cy <= floor_band.y
	for e in lights:
		var l: OmniLight3D = e[0]
		var ph: float = e[3]
		if not on_floor:
			l.visible = false
			continue
		l.visible = true
		match String(e[1]):
			"day":
				var through := open_door if String(l.name).ends_with("_door") else 1.0  # the doorway's day, its door shut or open
				l.light_energy = float(e[2]) * daylight * through
				l.visible = daylight * through > 0.02
			"fire":
				l.light_energy = float(e[2]) * (0.85 + 0.1 * sin(t * 1.3 + ph) * sin(t * 2.9 + ph * 0.7) + 0.05 * sin(t * 11.0 + ph * 3.0))
			"flame":
				l.light_energy = float(e[2]) * (0.94 + 0.06 * sin(t * 8.1 + ph) * sin(t * 6.3 + ph * 1.7))
				if l.has_meta("dusk"):  # a lamp lit only from dusk to bedtime (the chang house's oil lamp)
					var dm := fposmod(WorldClock.minute, 1440.0)
					l.visible = dm >= DUSK[0] and dm < DUSK[1]


## Whether a world position is inside the room (for the eye's adjustment and the tests).
func holds(p: Vector3) -> bool:
	return box.has_point(global_transform.affine_inverse() * p)


## The room's reverb area (plan chapter 10, 9.1, 13.4; M1 sprint 8, step 1): its box on the audio layer, sending the
## sounds inside to its zone's bus (data/sound.json `room_zones`: the Tibetan room carpeted, the Chinese room lively
## timber, the guest room small, the kitchen 0.6 s), there while the room is streamed in.
func _reverb() -> void:
	var zid := String((AudioDirector.data.get("room_zones", {}) as Dictionary).get(room_id, ""))
	var z: Dictionary = (AudioDirector.data.get("zones", {}) as Dictionary).get(zid, {})
	if z.is_empty() or box.size == Vector3.ZERO:
		return
	var area := Area3D.new()
	area.name = "Reverb_" + zid
	area.collision_layer = 1 << 11
	area.collision_mask = 0
	area.monitoring = false
	area.reverb_bus_enabled = true
	area.reverb_bus_name = StringName(z["bus"])
	area.reverb_bus_amount = float(z["amount"])
	area.reverb_bus_uniformity = float(z["uniformity"])
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	cs.shape = shape
	cs.position = box.get_center()
	area.add_child(cs)
	get_parent().add_child.call_deferred(area)


## The room's couplets in their characters (data/couplets.json; Greg, 27 Sep 2026: "the couplet is not in real
## characters, why? We have a font"): at the kit's COUPLET sockets, the right-hand strip as you face the wall (上聯)
## first, one character under another in the subtitles' Chinese face, brush-black on the red paper; the first look at
## them brings their gloss (ui/hud.gd).
const CHINESE := preload("res://assets/source/fonts/ar-pl-ukai/ukai.ttc")
var _couplet_at := Vector3.ZERO
var _couplet_gloss := ""


func _couplets() -> void:
	var f := "res://data/couplets.json"
	if not FileAccess.file_exists(f):
		return
	var c: Dictionary = ((JSON.parse_string(FileAccess.get_file_as_string(f)) as Dictionary)["rooms"] as Dictionary).get(room_id, {})
	var socks := get_parent().find_children("SOCK_COUPLET_*", "Node3D", true, false)
	if c.is_empty() or socks.size() < 2:
		return
	var mid := Vector3.ZERO
	for s in socks:
		mid += (s as Node3D).position
	mid /= socks.size()
	var inward := box.get_center() - mid
	inward.y = 0.0
	inward = inward.normalized()
	var right := (-inward).cross(Vector3.UP)  # the viewer's right, facing the wall
	socks.sort_custom(func(a, b): return (a as Node3D).position.dot(right) > (b as Node3D).position.dot(right))
	var lines: Array = c["lines"]
	for k in mini(socks.size(), lines.size()):
		var l := Label3D.new()
		l.name = "Couplet_%d" % k
		l.text = "\n".join(Array(String(lines[k]).split("")))
		l.font = CHINESE
		l.font_size = 150
		l.pixel_size = 0.00105
		l.line_spacing = 14.0
		l.modulate = Color(0.07, 0.05, 0.04)
		l.outline_size = 0
		l.double_sided = false
		l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
		get_parent().add_child.call_deferred(l)
		l.position = (socks[k] as Node3D).position + inward * 0.003
		l.basis = Basis.looking_at(-inward, Vector3.UP)  # its front (+Z) to the room
	_couplet_at = mid
	_couplet_gloss = String(c.get("gloss", ""))
