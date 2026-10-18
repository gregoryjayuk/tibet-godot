extends Node3D
## Dechen-tsang at night (plan chapter 04, 4.3's day: "22:00 Gate barred; mastiffs loose in Yard 1"; M2 sprint 8, step 4),
## added by world/town.gd under the house SHL-04 (its frame is this node's):
## - The gate: its two iron-strapped leaves (the kit's dechen_gate_leaf) stand open against the passage's walls by day,
##   hinged at the jambs' inner corners on the yard's side; at SHUT_AT they swing shut and the bar (dechen_gate_bar) is
##   dropped across them into its brackets, a box of collision in the gateway, until OPEN_AT. Never on the player in their
##   swing: the gate shuts on the player, never on them. From outside, E at the barred gate knocks: a servant draws the
##   bar and lets the player in, and bars it again once they are through (the house's own lodger, chapter 04's traveller).
## - The mastiffs: from SHUT_AT to OPEN_AT two loose in Yard 1 on their round of it; anyone within BARK_NEAR of one sets
##   it barking in bursts, turned to them (SND-408, the stand-in), the second answering the first.
## When the clock jumps (a load, a station's hour) the gate and the dogs stand at once as they stand at that hour.

const LEAF := "res://assets/generated/kit/types/dechen_gate_leaf_v1.glb"
const BAR := "res://assets/generated/kit/types/dechen_gate_bar_v1.glb"
const DOG := "res://assets/generated/people/mastiff.glb"
const PERSON := preload("res://characters/person.gdshader")
const Subtitles := preload("res://ui/subtitles.gd")
const SHUT_AT := 22.0 * 60.0
const OPEN_AT := 5.0 * 60.0
const SWING_S := 3.0  ## real seconds the leaves take to swing
const CLEAR := 2.4  ## metres from the gateway's middle the player must be before the leaves move
const HINGE_X := 1.6  ## the jambs' inner faces, either side of the gateway's middle (kit/trading.py: 3.2 m wide)
const HINGE_Z := 22.92  ## the gateway's inner face, the yard's side (Godot's z: the kit's -y)
const KNOCK_NEAR := 2.6  ## metres from the leaves' outer face the player knocks
const LET_IN := 4.0  ## game minutes the gate stands open after a knock
const BARK := "SND-408"
const BARK_NEAR := 9.0
## the dogs' round of Yard 1, in the kit's frame (x, y): its corners and its middle, clear of the darchen and the stacks
const ROUND := [Vector2(-9.0, -19.0), Vector2(5.0, -12.0), Vector2(10.0, -6.5), Vector2(-9.5, -6.5), Vector2(0.0, -15.5),
		Vector2(9.5, -18.5), Vector2(-3.0, -9.0)]

var leaves: Array = []  ## [pivot, its open yaw]
var bar: Node3D
var block: CollisionShape3D
var mid := Vector3(0.0, 1.0, HINGE_Z)  ## the gateway's middle, a metre up (this node's frame)
var state := 0.0  ## 0 open, 1 shut and barred
var goal := 0.0
var let_in_until := -1.0  ## the game minute a knock's opening lasts to
var knocks := 0  ## for the tests
var dogs: Array = []  ## {node, ap, clip, pos, at (its round's point), wait, burst, next}
var barking := 0  ## dogs barking now, for the tests and the stills
var _bar_shut := Transform3D.IDENTITY
var _bar_day := Transform3D.IDENTITY
var _last := -1.0


## Hangs the leaves and the bar and brings the dogs; false if the kit's pieces are missing.
func setup() -> bool:
	add_to_group("dechen_night")
	if not ResourceLoader.exists(LEAF) or not ResourceLoader.exists(BAR):
		return false
	for k in 2:
		var pivot := Node3D.new()
		pivot.name = "Leaf%d" % (k + 1)
		pivot.position = Vector3(-HINGE_X if k == 0 else HINGE_X, 0.0, HINGE_Z)
		add_child(pivot)
		var leaf: Node3D = (load(LEAF) as PackedScene).instantiate()
		if k == 1:
			leaf.scale = Vector3(-1.0, 1.0, 1.0)  # the east leaf: built along +x from its hinge, here along -x
		pivot.add_child(leaf)
		leaves.append([pivot, deg_to_rad(90.0) if k == 0 else deg_to_rad(-90.0)])  # open: along the passage's walls, into the yard
	_bar_shut = Transform3D(Basis.IDENTITY, Vector3(0.0, 1.7, HINGE_Z - 0.16))
	_bar_day = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(-2.3, 0.09, HINGE_Z - 2.4))  # on the flags by the west leaf
	bar = (load(BAR) as PackedScene).instantiate()
	bar.name = "Bar"
	add_child(bar)
	var body := StaticBody3D.new()
	body.name = "Shut"
	add_child(body)
	block = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0 * HINGE_X, 3.6, 0.3)
	block.shape = box
	block.position = Vector3(0.0, 1.8, HINGE_Z - 0.06)
	block.disabled = true
	body.add_child(block)
	var m := fposmod(WorldClock.minute, 1440.0)
	goal = 1.0 if shut_at(m) else 0.0
	state = goal
	_last = m
	_pose()
	_dogs()
	return true


## Whether the gate stands shut at `m` minutes of the day (and the dogs are loose).
static func shut_at(m: float) -> bool:
	return m >= SHUT_AT or m < OPEN_AT


func is_shut() -> bool:
	return goal > 0.5


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _process(dt: float) -> void:
	if leaves.is_empty():
		return
	var m := fposmod(WorldClock.minute, 1440.0)
	var jumped := _last >= 0.0 and absf(fposmod(m - _last + 720.0, 1440.0) - 720.0) > 2.0
	_last = m
	var want := 1.0 if shut_at(m) and not _letting_in() else 0.0
	if want != goal:
		var pl := _player()
		if pl == null or pl.global_position.distance_to(to_global(mid)) > CLEAR:
			goal = want
			if jumped:
				state = goal
				_pose()
			elif is_instance_valid(AudioDirector):
				AudioDirector.play("SND-218.close" if goal > 0.5 else "SND-218.open", to_global(mid))
	var s := move_toward(state, goal, dt / SWING_S)
	if s != state:
		var was := state
		state = s
		_pose()
		if s == 1.0 and was < 1.0 and is_instance_valid(AudioDirector):
			AudioDirector.play("SND-219.knock", to_global(mid))  # the bar dropped into its brackets
	_walk_dogs(dt, m, jumped)


func _letting_in() -> bool:
	return let_in_until >= 0.0 and WorldClock.minute < let_in_until


func _pose() -> void:
	var swing := clampf(state / 0.8, 0.0, 1.0)  # the leaves first, then the bar
	var e := swing * swing * (3.0 - 2.0 * swing)
	for l in leaves:
		(l[0] as Node3D).rotation.y = lerpf(float(l[1]), 0.0, e)
	var b := clampf((state - 0.8) / 0.2, 0.0, 1.0)
	bar.transform = _bar_day.interpolate_with(_bar_shut, b)
	block.set_deferred("disabled", state < 0.5)


## E at the barred gate from outside: the knock, and a servant lets the player in.
func _unhandled_input(e: InputEvent) -> void:
	if not e.is_action_pressed("use"):  # E, or the controller's triangle (autoload/controls.gd)
		return
	var pl := _player()
	if pl != null and knock(pl.global_position):
		get_viewport().set_input_as_handled()


## The player knocking at `at` (global): true if heard (the gate shut, `at` before its leaves outside).
func knock(at: Vector3) -> bool:
	if goal < 0.5 or _letting_in():
		return false
	var local := to_local(at)
	if local.z < HINGE_Z or local.z > HINGE_Z + 1.2 + KNOCK_NEAR or absf(local.x) > 2.4:
		return false
	knocks += 1
	let_in_until = WorldClock.minute + LET_IN
	if is_instance_valid(AudioDirector):
		AudioDirector.play("SND-219.knock", to_global(mid + Vector3(0.0, 0.0, 0.2)))
	var subs := get_tree().get_first_node_in_group("subtitles")
	if subs == null:
		subs = Subtitles.new()
		get_tree().root.add_child(subs)
	subs.call("narrate", "You knock. A servant draws the bar and lets you in.", 4.0)
	return true


# ------------------------------------------------------------------ the mastiffs loose in Yard 1
func _dogs() -> void:
	if not ResourceLoader.exists(DOG):
		return
	for k in 2:
		var dog := Node3D.new()
		dog.name = "Mastiff%d" % (k + 1)
		add_child(dog)
		var fig: Node3D = (load(DOG) as PackedScene).instantiate()
		fig.scale = Vector3(1.6, 1.15, 1.15) * (1.0 if k == 0 else 0.93)  # the fox made a mastiff (as Samkha's), the bitch smaller
		dog.add_child(fig)
		var mat := ShaderMaterial.new()
		mat.shader = PERSON
		for mi in fig.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = mat
			(mi as MeshInstance3D).set_instance_shader_parameter("tint", 0.8 if k == 0 else 0.62)
		var sk: Skeleton3D = fig.find_children("*", "Skeleton3D", true, false)[0]
		for bs in [["Head", 1.14], ["Nose", 0.72], ["Tail_Mid.001", 0.5]]:
			var bi := sk.find_bone(String(bs[0]))
			if bi >= 0:
				sk.set_bone_pose_scale(bi, Vector3.ONE * float(bs[1]))
		var ap: AnimationPlayer = fig.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Idle", "Idle Alert", "Sit", "Bark"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		var at := (k * 3) % ROUND.size()
		dogs.append({"node": dog, "ap": ap, "clip": "", "pos": _yard(ROUND[at]), "at": at, "wait": 0.0, "burst": 0, "next": 0.4 * k})
		dog.position = _yard(ROUND[at])
		dog.visible = shut_at(fposmod(WorldClock.minute, 1440.0))


## A point of Yard 1 (the kit's x, y) on its flags, in this node's frame.
func _yard(q: Vector2) -> Vector3:
	return Vector3(q.x, 0.06, -q.y)


func _walk_dogs(dt: float, m: float, jumped: bool) -> void:
	var loose := shut_at(m)
	var pl := _player()
	barking = 0
	for d in dogs:
		var dog: Node3D = d["node"]
		dog.visible = loose
		if not loose:
			continue
		var pos: Vector3 = d["pos"]
		var clip := "Idle"
		var yaw := dog.rotation.y
		var near := pl != null and pl.global_position.distance_to(to_global(pos)) < BARK_NEAR
		if near:  # turned to the stranger, barking in bursts
			var to := to_local(pl.global_position) - pos
			to.y = 0.0
			yaw = atan2(to.x, to.z)
			clip = "Bark" if int(d["burst"]) > 0 else "Idle Alert"
			d["next"] = float(d["next"]) - dt
			if float(d["next"]) <= 0.0:
				if int(d["burst"]) <= 0:
					d["burst"] = randi_range(3, 6)
				if is_instance_valid(AudioDirector):
					AudioDirector.play(BARK, to_global(pos + Vector3(0.0, 0.6, 0.0)))
				d["burst"] = int(d["burst"]) - 1
				d["next"] = randf_range(0.5, 0.95) if int(d["burst"]) > 0 else randf_range(2.0, 4.0)
			barking += 1
		else:  # its round, at a walk, a pause at each point
			d["burst"] = 0
			var goal_at := _yard(ROUND[int(d["at"])])
			var to := goal_at - pos
			to.y = 0.0
			if to.length() < 0.3 or jumped:
				d["wait"] = float(d["wait"]) + dt
				clip = "Idle"
				if float(d["wait"]) > 5.0:
					d["wait"] = 0.0
					d["at"] = (int(d["at"]) + 1) % ROUND.size()
			else:
				pos += to.normalized() * minf(to.length(), 1.0 * dt)
				yaw = atan2(to.x, to.z)
				clip = "Walk"
		d["pos"] = pos
		dog.position = pos
		dog.rotation.y = yaw
		var ap: AnimationPlayer = d["ap"]
		if ap.has_animation(clip) and String(d["clip"]) != clip:
			ap.play(clip, 0.25 if String(d["clip"]) != "" else 0.0)
			d["clip"] = clip
