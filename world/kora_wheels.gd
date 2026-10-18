extends Node3D
## Pema Ö Lhakhang's kora corridor (M2 sprint 5, step 4; plan chapter 03, 9: "a kora corridor of 36 wheels round three
## sides under a lean-to roof on posts"): the kit's `kora_wheel` hung at each of the temple's WHEEL sockets, turned
## clockwise seen from above by a hand passing it (the player, or any walker in the group "kora_walkers": step 5's old
## woman), SPIN turns a second while the hand is on it, slowing to rest over SLOW seconds (chapter 03, 9: "each wheel
## spins when touched and slows over 4 s"), its pin squeaking as it starts (SND-128). Added by world/town.gd under SHL-11.
## `sense` -1 turns them anticlockwise: the Bön chapel TOD-02's (M3 sprint 4, step 6; chapter 03, 3.2: "prayer-wheel niches
## by the door set to turn anticlockwise").

const WHEEL_SCENE := "res://assets/generated/kit/types/kora_wheel_v1.glb"
const REACH := 0.85  ## metres, flat, from a wheel's axis at which a passing hand turns it
const SPIN := 0.8  ## turns a second under a hand
const SLOW := 4.0  ## seconds from SPIN to rest
const SQUEAK := "SND-128"  ## a wall wheel set turning (a stand-in, synthesised)

var sense := 1.0  ## 1 clockwise seen from above, -1 anticlockwise (the Bön)
var wheels: Array[Node3D] = []
var speed := PackedFloat32Array()  ## turns a second, each wheel


## Hangs a wheel at each of `temple`'s WHEEL sockets; returns how many.
func setup(temple: Node3D) -> int:
	if not ResourceLoader.exists(WHEEL_SCENE):
		return 0
	var scene: PackedScene = load(WHEEL_SCENE)
	var socks := temple.find_children("SOCK_WHEEL_*", "Node3D", true, false)
	socks.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
	for s in socks:
		var w := scene.instantiate() as Node3D
		w.name = "Wheel_%d" % wheels.size()
		add_child(w)
		w.global_transform = (s as Node3D).global_transform
		wheels.append(w)
	speed.resize(wheels.size())
	return wheels.size()


## The hands near wheel `i` now: whether any walker (the player, the group "kora_walkers") is within REACH of it, flat,
## and not above or below it by more than a storey.
func touched(i: int) -> bool:
	var at := wheels[i].global_position
	var hands: Array = get_tree().get_nodes_in_group("kora_walkers")
	hands.append_array(get_tree().get_nodes_in_group("player"))
	for h in hands:
		if not h is Node3D:
			continue
		var p := (h as Node3D).global_position
		if absf(p.y - at.y) < 2.0 and Vector2(p.x - at.x, p.z - at.z).length() < REACH:
			return true
	return false


func _process(dt: float) -> void:
	for i in wheels.size():
		var was := speed[i]
		speed[i] = SPIN if touched(i) else maxf(0.0, speed[i] - SPIN * dt / SLOW)
		if speed[i] >= SPIN and was < 0.3 * SPIN and is_instance_valid(AudioDirector):
			AudioDirector.play(SQUEAK, wheels[i].global_position)  # its pin squeaks as it is set turning
		if speed[i] > 0.0:
			wheels[i].rotate_y(-TAU * speed[i] * dt * sense)
