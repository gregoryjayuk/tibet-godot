extends Node3D
## The Serchu's mills and water prayer wheels at work (M2 sprint 12, step 5; plan chapter 02, SER-05 to SER-09, 6.1;
## data/serchu_mills.json, tools/town/serchu_mills.py): each house (../tibet-blender kit/serchu.py water_mill,
## water_wheel_house) where the planner put it, its turning part (mill_runner, water_wheel_drum) on its WHEEL or SHAFT
## socket, turning day and night while the leat runs (a mill's runner MILL_RATE turns a second, as its sound's clapper
## keeps time; a prayer wheel's drum WHEEL_RATE), within NEAR of the camera; each mill heard at its arch (SND-215: the
## chute's rush, the runner's grind, the clapper), each wheel house's water where it falls out (SND-009) and its bell
## struck once a turn (SND-130). Added by
## world/town.gd, which calls `house` for each. `turning`, `rings` for the tests.

const Town := preload("res://world/town.gd")
const MILL_RATE := 2.0  ## a mill's runner's turns a second (tools/audio/synth.py `mill`)
const WHEEL_RATE := 0.5  ## a prayer wheel's drum's
const MILL_SOUND := "SND-215"
const BELL_SOUND := "SND-130"
const SPOUT_SOUND := "SND-009"  ## a wheel house's water falling out of it (the spring's spout, as a stand-in)
const NEAR := 180.0  ## metres from the camera within which the parts turn and the bells ring

var turning: Array[Node3D] = []  ## each house's turning part
var rates: Array[float] = []
var turns: Array[float] = []  ## each part's turns so far (by the animation clock: frozen for stills)
var phases: Array[float] = []  ## each part's own start, a share of a turn
var rings := 0  ## the wheels' bells struck, for the tests
var _bells := {}  ## a wheel's turning index -> the node at its house's BELL socket
var _arches: Array[Node3D] = []  ## where each house is heard: a mill's TAIL socket, a wheel house's OUT
var _sounds: Array[String] = []
var _keys: Array[String] = []
var _heard := false


## One house from its record ({id, at, level, facing}) and kit file, its turning part on its socket; 1 if placed.
func house(rec: Dictionary, file: String, part: String, socket: String, wheel: bool) -> int:
	if not ResourceLoader.exists(file):
		return 0
	var h: Node3D = (load(file) as PackedScene).instantiate()
	h.name = String(rec["id"])
	h.position = Town.to_godot(float(rec["at"][0]), float(rec["at"][1]), float(rec["level"]))
	h.rotation.y = -deg_to_rad(float(rec["facing"]) - 180.0)
	add_child(h)
	var sock := h.find_child("SOCK_%s_1" % socket, true, false) as Node3D
	if sock != null and ResourceLoader.exists(part):
		var t: Node3D = (load(part) as PackedScene).instantiate()
		t.name = "%s_turning" % String(rec["id"])
		phases.append(fposmod(float(hash(String(rec["id"])) & 0xffff) / 65536.0, 1.0))
		sock.add_child(t)
		if wheel:
			var bell := h.find_child("SOCK_BELL_1", true, false) as Node3D
			if bell != null:
				_bells[turning.size()] = bell
		turning.append(t)
		rates.append(WHEEL_RATE if wheel else MILL_RATE)
		turns.append(-1.0)  # (not yet turned: no bell for the turns before it was first seen)
	var heard := h.find_child("SOCK_OUT_1" if wheel else "SOCK_TAIL_1", true, false) as Node3D
	if heard != null:  # a mill at its arch, a wheel house where its water falls out of it
		_arches.append(heard)
		_sounds.append(SPOUT_SOUND if wheel else MILL_SOUND)
	return 1


func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var eye := cam.global_position if cam != null else Vector3.ZERO
	if not _heard:  # the mills' loops once they stand in the world
		_heard = true
		var sd: Node = AudioDirector.sound if is_instance_valid(AudioDirector) else null
		if sd != null:
			for k in _arches.size():
				var key := "serchu_mill_%d" % k
				sd.call("loop_start", key, _sounds[k], _arches[k].global_position, 0.0)
				_keys.append(key)
	var now := WorldClock.anim_time if is_instance_valid(WorldClock) else 0.0
	for i in turning.size():
		var t := turning[i]
		if cam != null and t.global_position.distance_squared_to(eye) > NEAR * NEAR:
			continue
		var before := floorf(turns[i]) if turns[i] >= 0.0 else INF
		turns[i] = phases[i] + rates[i] * now
		t.rotation.y = -fposmod(turns[i], 1.0) * TAU  # sunwise, seen from above, as a prayer wheel turns
		if _bells.has(i) and floorf(turns[i]) > before:
			rings += 1
			if is_instance_valid(AudioDirector):
				AudioDirector.play(BELL_SOUND, (_bells[i] as Node3D).global_position)


func _exit_tree() -> void:
	var sd: Node = AudioDirector.sound if is_instance_valid(AudioDirector) else null
	if sd != null:
		for key in _keys:
			sd.call("loop_stop", key)
	_keys.clear()
