extends Node
## The Sound director (plan chapter 10, 13.1, 13.3, 13.6, 13.8; M1 sprint 8, step 1), AudioDirector/Sound. Voices come
## from pools (data/sound.json `pools`: dialogue 4, ritual 4, near 12, animals 6, loops 6, river 3), each an
## AudioStreamPlayer3D that listens only to the reverb areas' layer (13.4); a full pool gives the voice farthest from the
## listener to the newcomer. A sound of a class that carries its delay (valley calls, rites heard far, long calls) and is
## more than 60 m away starts when its sound would arrive: cause + distance / c, c = 331.3 + 0.606 T (13.6); one flagged
## `echo` comes back off the western ridge later, 24 dB down and dull. The ritual schedule (4.1) fires at its minutes.
## Loops (`loop_start`): each keeps a virtual clock; the nearest in range get the loop pool's voices, and a loop given a
## voice again starts where it would have been, never from its beginning in the ear.

const ZONE_LAYER := 1 << 11  ## the audio_zone layer (12): the reverb areas alone
var Town: GDScript  ## world/town.gd, loaded at start, not preloaded: the town's scripts refer to this autoload
const NEAR_DELAY := 60.0  ## metres within which nothing is delayed

var listener_override: Node3D  ## the tests' listener; else the current camera
var played: Array = []  ## [clock, id, delay (s)] of every play, for the tests and the logs
var clock := 0.0  ## the game's seconds since the director came (its frames' time)
var _pools := {}  ## pool -> [AudioStreamPlayer3D]
var _started := {}  ## player -> clock at its start
var _queue: Array = []  ## [start (clock), id, position, variant, gain dB, cutoff Hz (0: the class's)]
var _loops := {}  ## key -> {id, pos, start (clock), gain, player}
var _last_minute := -1.0
var _tick := 0.0


func _data() -> Dictionary:
	return get_parent().get("data") if get_parent() != null else {}


func _ready() -> void:
	Town = load("res://world/town.gd")
	var pools: Dictionary = _data().get("pools", {})
	for pool in pools:
		var list: Array = []
		for k in int(pools[pool][0]):
			var p := AudioStreamPlayer3D.new()
			p.name = "%s_%d" % [pool, k]
			p.area_mask = ZONE_LAYER
			p.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
			add_child(p)
			list.append(p)
		_pools[pool] = list


func listener() -> Vector3:
	if listener_override != null:
		return listener_override.global_position
	var cam := get_viewport().get_camera_3d() if get_viewport() != null else null
	return cam.global_position if cam != null else Vector3.ZERO


## The speed of sound in the valley's air (13.6), m/s.
func speed() -> float:
	var d := _data()
	var k: Array = d.get("sound_speed_at_c", [331.3, 0.606])
	return float(k[0]) + float(k[1]) * float(d.get("air_c", 8.0))


func play(id: String, pos: Vector3, cause := -1.0, variant := -1, gain_db := 0.0, cutoff := 0.0) -> AudioStreamPlayer3D:
	var rec: Dictionary = (_data().get("sounds", {}) as Dictionary).get(id, {})
	if rec.is_empty():
		push_warning("Sound: no record %s" % id)
		return null
	var cls: Dictionary = (_data().get("classes", {}) as Dictionary).get(String(rec.get("class", "near_foley")), {})
	var at := cause if cause >= 0.0 else clock
	var ear := listener()
	var d := ear.distance_to(pos)
	if bool(rec.get("echo", false)) and cutoff == 0.0:
		_echo(id, pos, at, variant)
	if bool(cls.get("delay", false)) and d > NEAR_DELAY:
		var t0 := at + d / speed()
		_queue.append([t0, id, pos, variant, gain_db, cutoff])
		played.append([clock, id, t0 - clock])
		return null
	played.append([clock, id, 0.0])
	return _start(id, rec, cls, pos, variant, gain_db, cutoff, 0.0)


## The ridge's echo (13.6): heard from the reflector's way, (source to ridge + ridge to ear) / c after the cause, 24 dB
## down and low-passed; played 250 m off along that way so the 3D pan points at the ridge.
func _echo(id: String, pos: Vector3, at: float, variant: int) -> void:
	var e: Dictionary = _data().get("echo", {})
	if e.is_empty():
		return
	var a: Array = e["at"]
	var refl: Vector3 = Town.to_godot(float(a[0]), float(a[1]), float(a[2]))
	var ear := listener()
	var t0: float = at + (pos.distance_to(refl) + refl.distance_to(ear)) / speed()
	var along: Vector3 = ear + (refl - ear).normalized() * 250.0
	_queue.append([t0, id, along, variant, float(e.get("db", -24.0)), float(e.get("cutoff", 800.0))])
	played.append([clock, id + " echo", t0 - clock])  # (a sound run lists it with its delay: V-05a's, M3 sprint 6, step 5)


func _start(id: String, rec: Dictionary, cls: Dictionary, pos: Vector3, variant: int, gain_db: float, cutoff: float, offset: float) -> AudioStreamPlayer3D:
	var s: AudioStream = get_parent().call("stream", id, variant)
	if s == null:
		return null
	var p := _voice(String(cls.get("pool", "near")), pos)
	if p == null:
		return null
	p.stream = s
	p.bus = StringName(rec.get("bus", "World"))
	p.global_position = pos
	var vy: Vector2 = get_parent().call("vary", id)  # its spread this time (a caller may scale the pitch: world/tea.gd)
	p.volume_db = gain_db + float(rec.get("gain_db", 0.0)) + vy.y  # the call's own, and the echo's or a loop's
	p.pitch_scale = vy.x
	p.unit_size = float(cls.get("unit_size", 10.0))
	p.max_distance = float(cls.get("max_distance", 0.0))
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC if String(cls.get("model", "")) == "log" else AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	var fc: float = cutoff if cutoff > 0.0 else float(cls.get("cutoff", 5000.0))
	p.attenuation_filter_cutoff_hz = fc if fc > 0.0 else 20500.0
	p.attenuation_filter_db = float(cls.get("cutoff_db", -24.0)) if fc > 0.0 else 0.0
	p.max_polyphony = int(cls.get("polyphony", 1))
	p.emission_angle_enabled = rec.has("emission_deg")
	if rec.has("emission_deg"):
		p.emission_angle_degrees = float(rec["emission_deg"])
		p.emission_angle_filter_attenuation_db = -6.0
		p.rotation = Vector3(0.0, -deg_to_rad(float(rec.get("facing_deg", 0.0))), 0.0)  # its -Z to the bearing (north -Z, clockwise)
	p.play(offset)
	_started[p] = clock
	return p


## A free voice of the pool, or the one farthest from the listener (never a nearer one than the newcomer's).
func _voice(pool: String, pos: Vector3) -> AudioStreamPlayer3D:
	var list: Array = _pools.get(pool, [])
	var ear := listener()
	var far: AudioStreamPlayer3D = null
	for p in list:
		var q := p as AudioStreamPlayer3D
		if not q.playing:
			return q
		if far == null or q.global_position.distance_to(ear) > far.global_position.distance_to(ear):
			far = q
	if far != null and far.global_position.distance_to(ear) >= pos.distance_to(ear):
		for key in _loops:
			if _loops[key]["player"] == far:
				_loops[key]["player"] = null  # that loop goes virtual
		far.stop()
		return far
	return null


## A looping source at `pos` under `key` (juniper on a burner, a spring): it runs on its own clock whether heard or not.
func loop_start(key: String, id: String, pos: Vector3, gain_db := 0.0) -> void:
	if not _loops.has(key):
		_loops[key] = {"id": id, "pos": pos, "start": clock, "gain": gain_db, "player": null}
	else:
		_loops[key]["gain"] = gain_db


func loop_stop(key: String) -> void:
	if not _loops.has(key):
		return
	var p: AudioStreamPlayer3D = _loops[key]["player"]
	if p != null:
		p.stop()
	_loops.erase(key)


func loop_voiced(key: String) -> bool:
	return _loops.has(key) and _loops[key]["player"] != null


func _process(dt: float) -> void:
	clock += dt
	var m := fposmod(WorldClock.minute, 1440.0)
	# the clock running on fires the schedule; a jump (a station, a teleport, the clock set) does not: nothing on it
	# moves more than five game minutes between two frames
	if _last_minute >= 0.0 and m != _last_minute and fposmod(m - _last_minute, 1440.0) <= 5.0:
		for ev in _data().get("schedule", []):
			var hm := String(ev["time"]).split(":")
			if _passed(_last_minute, m, float(hm[0]) * 60.0 + float(hm[1])):
				var a: Array = _data()["places"][ev["at"]]
				play(String(ev["sound"]), Town.to_godot(float(a[0]), float(a[1]), float(a[2])), clock, int(ev.get("variant", -1)))
	_last_minute = m
	if not _queue.is_empty():
		var keep: Array = []
		for q in _queue:
			if clock >= float(q[0]):
				var rec: Dictionary = _data()["sounds"][q[1]]
				_start(String(q[1]), rec, _data()["classes"][String(rec.get("class", "near_foley"))], q[2], int(q[3]), float(q[4]), float(q[5]), 0.0)
			else:
				keep.append(q)
		_queue = keep
	_tick -= dt
	if _tick <= 0.0:
		_tick = 0.25
		_voice_loops()


## The nearest loops in range get the loop pool's voices, each resumed where its own clock has it (13.8).
func _voice_loops() -> void:
	if _loops.is_empty():
		return
	var ear := listener()
	var want: Array = []
	for key in _loops:
		var L: Dictionary = _loops[key]
		var cls: Dictionary = _data()["classes"][String(_data()["sounds"][L["id"]].get("class", "spot_loop"))]
		var d := (L["pos"] as Vector3).distance_to(ear)
		if d < float(cls.get("max_distance", 60.0)):
			want.append([d, key])
		elif L["player"] != null:
			(L["player"] as AudioStreamPlayer3D).stop()
			L["player"] = null
	want.sort()
	var n := (_pools.get("loops", []) as Array).size()
	for k in want.size():
		var key: String = want[k][1]
		var L: Dictionary = _loops[key]
		if k >= n:
			if L["player"] != null:
				(L["player"] as AudioStreamPlayer3D).stop()
				L["player"] = null
			continue
		if L["player"] == null:
			var rec: Dictionary = _data()["sounds"][L["id"]]
			var v: int = get_parent().call("pick", L["id"])  # the file measured is the file played
			var s: AudioStream = get_parent().call("stream", L["id"], v)
			var length := s.get_length() if s != null else 0.0
			var offset := fmod(clock - float(L["start"]), length) if length > 0.0 else 0.0
			L["player"] = _start(String(L["id"]), rec, _data()["classes"][String(rec.get("class", "spot_loop"))], L["pos"], v, float(L["gain"]), 0.0, offset)
		elif L["player"] != null:
			(L["player"] as AudioStreamPlayer3D).volume_db = float(L["gain"])


## Whether the clock went past `at` (minutes of the day) between two frames, midnight included.
static func _passed(a: float, b: float, at: float) -> bool:
	if b >= a:
		return a < at and at <= b
	return at > a or at <= b
