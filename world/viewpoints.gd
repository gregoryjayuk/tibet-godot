extends Node
## The slice's viewpoints (IMP-021 (5) and IMP-024, after Greg's 1780: "a peaceful moment"): sitting (C) at one, after a
## breath the camera drifts out to a frame composed in planes (the walker sitting in the foreground; the roofs and their
## smoke; the far range in its haze), the town's sounds settle under the wind and the water, and the place's name shows a
## while; standing (C again, or a step) brings it all back. data/viewpoints.json: each its seat in the town grid and its
## frame, set from where the walker sits. Added by world/town.gd; the player blends to the frame (player/player.gd
## `view_k`).

const Town := preload("res://world/town.gd")
const DATA := "res://data/viewpoints.json"
const SETTLE := {"Crowd": -9.0, "Voices": -6.0, "Foley": -6.0, "Animals": -5.0}  ## dB at the full drift
const WAIT := 2.5  ## seconds seated before the camera drifts out
const OUT_S := 4.0  ## seconds the drift out takes
const BACK_S := 1.2  ## and back
const CAPTION_S := 5.0

var views: Array = []
var current := {}  ## the viewpoint sat at, or {}
var k := 0.0  ## how far out, 0 to 1
var _seated_t := 0.0
var _caption_t := -1.0


func _ready() -> void:
	add_to_group("viewpoints")
	if FileAccess.file_exists(DATA):
		views = JSON.parse_string(FileAccess.get_file_as_string(DATA))["views"]


## The viewpoint whose seat `p` (Godot) is within reach of, or {}.
func near(p: Vector3) -> Dictionary:
	for v in views:
		var s: Array = v["seat"]
		var g := Town.to_godot(float(s[0]), float(s[1]), 0.0)
		if Vector2(p.x - g.x, p.z - g.z).length() < float(v.get("reach", 4.0)):
			return v
	return {}


## The frame of viewpoint `v` for a walker sitting at `at`: back from them along its bearing, up and to the right, short
## of anything between (the player's probe), looking at its bearing and pitch.
static func frame(v: Dictionary, at: Vector3, cast := Callable()) -> Transform3D:
	var b := deg_to_rad(float(v["bearing"]))
	var fwd := Vector3(sin(b), 0.0, -cos(b))
	var right := Vector3(cos(b), 0.0, sin(b))
	var pivot := at + Vector3(0.0, float(v.get("up", 1.4)), 0.0)
	var off := -fwd * float(v.get("back", 3.0)) + right * float(v.get("right", 0.0))
	if cast.is_valid():
		off *= maxf(0.25, float(cast.call(pivot, off)) - 0.05)
	return Transform3D(Basis.from_euler(Vector3(deg_to_rad(float(v["pitch"])), -b, 0.0)), pivot + off)


func _process(dt: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null:
		return
	var seated := int(p.get("rest")) == 2  # Rest.SEATED
	var v := near(p.global_position) if seated else {}
	if not v.is_empty():
		_seated_t += dt
		current = v
	else:
		_seated_t = 0.0
	var goal := 1.0 if not v.is_empty() and _seated_t >= WAIT else 0.0
	k = move_toward(k, goal, dt / (OUT_S if goal > k else BACK_S))
	if not current.is_empty():
		p.set("view_frame", frame(current, p.global_position, Callable(p, "_cast")))
		p.set("view_fov", float(current.get("fov", 50.0)))
	var e := k * k * (3.0 - 2.0 * k)
	p.set("view_k", e)
	for bus in SETTLE:  # the town's sounds settle: an offset of the AudioDirector's, added to any other (a moment's)
		AudioDirector.set_offset("viewpoints", bus, float(SETTLE[bus]) * e)
	if goal == 1.0 and k >= 1.0 and _caption_t < 0.0:  # the place's name, once it is reached
		_caption_t = CAPTION_S
		_prompt(String(current.get("name", "")))
	if _caption_t > 0.0:
		_caption_t -= dt
		if _caption_t <= 0.0 or goal == 0.0:
			_caption_t = 0.0
			_prompt("")
	if goal == 0.0 and k == 0.0:
		current = {}
		_caption_t = -1.0


func _prompt(t: String) -> void:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s != null:
		s.call("prompt", t)
