extends Node
## The player's steps and coat (plan chapter 10, SND-601, SND-602; M1 sprint 8, step 4; Greg, 27 Sep 2026: "sound
## effects like quiet footsteps and doors etc might be good"), a child of player/player.gd. A step every stride along
## the ground (0.72 m walking, 1.15 m jogging, 2.9 m sprinting, the Sprint clip's step; on a flight, every tread, every
## other at the sprint: IMP-043), each on the surface underfoot: wood on a
## ladder or a plank; in Dechen-tsang's rooms a rug (the Tibetan room, the guest room), bricks (the Chinese room) or
## beaten earth (the kitchen); earth on a roof or out in the valley; stone on a flight and in the town's lanes. On a
## ladder, a step every rung and now and then a creak. The coat rustles as the player sits, stands or takes a ladder.
## Kenney's CC0 sounds (tools/audio/fetch_kenney.sh), quiet, through the AudioDirector.

const WALK_STRIDE := 0.72
const RUN_STRIDE := 1.15
const SPRINT_STRIDE := 2.9
const RUNG := 0.35
const ROOM_FLOOR := {"dechen_tibetan": "rug", "dechen_guest": "rug", "dechen_chinese": "stone", "dechen_kitchen": "earth"}
const Horizon := preload("res://world/horizon.gd")

var player: CharacterBody3D
var steps: Array = []  ## [surface] of each step, for the tests
var _dist := 0.0
var _climb := 0.0
var _last := Vector3.INF
var _rest := 0
var _ladder := false
var _flight := false
var _dice := RandomNumberGenerator.new()  ## its own, never the global stream (the seeded scenes draw from that)


func _ready() -> void:
	player = get_parent() as CharacterBody3D


func _physics_process(_dt: float) -> void:
	if player == null:
		return
	var p := player.global_position
	if _last == Vector3.INF:
		_last = p
	var moved := p - _last
	_last = p
	var rest := int(player.get("rest"))
	var on_ladder: bool = player.get("ladder") != null
	if rest != _rest or on_ladder != _ladder:  # sitting, standing, taking a ladder: the coat
		if (rest != 0 and _rest == 0) or (rest == 0 and _rest != 0) or on_ladder:
			_play("SND-602")
		_rest = rest
		_ladder = on_ladder
	if on_ladder:
		_climb += absf(moved.y)
		if _climb >= RUNG:
			_climb = 0.0
			_step("wood")
			if _dice.randf() < 0.18:
				_play("SND-219.creak")
		return
	if not player.is_on_floor() or rest != 0:
		_dist = 0.0
		return
	var flat := Vector2(moved.x, moved.z).length()
	if flat > 1.0:  # a teleport, not a step
		return
	_dist += flat
	var st: Dictionary = player.get("stair") if player.get("stair") is Dictionary else {}
	var sp := Vector2(player.velocity.x, player.velocity.z).length()
	var two := String(player.get("gait")) == "sprint"  # two treads a stride at the sprint (player/player.gd STAIR_TWO)
	var stride := float(st["run"]) * (2.0 if two else 1.0) if not st.is_empty() else (SPRINT_STRIDE if sp > 5.75 else (RUN_STRIDE if sp > 3.0 else WALK_STRIDE))
	if _dist >= stride:
		_dist -= stride
		_step(surface())


## The surface underfoot: "wood", "rug", "earth" or "stone"; stockinged in a hall, the boots at its door, always soft
## ("rug": M3 sprint 6, step 2).
func surface() -> String:
	if bool(player.get("bare_feet")):
		return "rug"
	var p := player.global_position
	var itr := get_tree().get_first_node_in_group("interiors")
	var room: Node = itr.call("room_at", p + Vector3(0.0, 1.0, 0.0)) if itr != null else null
	if room != null:
		var rid := String(room.get("room_id"))
		return "earth" if rid.begins_with("house_kitchen") else String(ROOM_FLOOR.get(rid, "stone"))  # a house's kitchen: beaten earth
	var st = player.get("stair")
	if st is Dictionary and not (st as Dictionary).is_empty():
		return "stone"
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0.0, 0.4, 0.0), p - Vector3(0.0, 0.6, 0.0), 1, [player.get_rid()])
	var hit := player.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var n := String((hit["collider"] as Node).name).to_lower() + " " + String((hit["collider"] as Node).get_parent().name).to_lower()
		if n.contains("plank") or n.contains("ladder") or n.contains("gallery") or n.contains("bridge"):
			return "wood"
	var g := Horizon.ground_at(p.x, -p.z)
	if not is_nan(g) and p.y - g > 2.0:
		return "earth"  # a roof of beaten earth
	var town := 0.0
	var amb := get_node_or_null("/root/AudioDirector/Ambience")
	if amb != null:
		for d in ["shol", "tode", "hejie", "samkha", "gonpa"]:
			town = maxf(town, float(amb.call("weight", d, p)))
	return "stone" if town > 0.5 else "earth"


func _step(on: String) -> void:
	steps.append(on)
	_play("SND-601." + on)


func _play(id: String) -> void:
	var ad := get_node_or_null("/root/AudioDirector")
	if ad != null:
		ad.call("play", id, player.global_position + Vector3(0.0, 0.05, 0.0))
