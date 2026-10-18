extends Node3D
## The castle gate passage's outer door (SAM-02; plan chapter 03, 5.1, and chapter 07's day: "17:30 The castle passage
## shuts at the dusk horns, closing the chain bridge ... Chains; a bar dropped into brackets"), added by world/town.gd
## under Samkha Khar (M2 sprint 4, step 4): its two leaves (the kit's sam02_gate_leaf) hung at the castle's GATE
## sockets, the east one mirrored so both outer faces look out, standing open against the passage's walls by day; at
## SHUT_AT they swing shut and the bar (sam02_gate_bar) is dropped into its brackets at the BAR socket, a box of
## collision across the passage: the chain bridge is closed until OPEN_AT, when the bar is drawn and the leaves swing
## open. They never move while the player stands in their swing: the gate is shut on the player, never on them. When
## the clock jumps (a load, a station's hour, a skip) the gate stands at once as it stands at that hour.

const LEAF := "res://assets/generated/kit/types/sam02_gate_leaf_v1.glb"
const BAR := "res://assets/generated/kit/types/sam02_gate_bar_v1.glb"
const SHUT_AT := 17.0 * 60.0 + 30.0
const OPEN_AT := 5.0 * 60.0 + 30.0  ## with the ladders set down (world/dusk.gd), Hejie's gates (chapter 07: 05:30)
const SWING_S := 3.0  ## real seconds the leaves take to swing
const CLEAR := 2.2  ## metres from the doorway's middle the player must be before the leaves move
const Barks := preload("res://world/barks.gd")
const Subtitles := preload("res://ui/subtitles.gd")
const ANSWER := "PB-T60"  ## the gatekeeper through the barred leaves: "The gate's already shut" (chapter 07)
const ASK_NEAR := 3.2  ## metres from the leaves' line outside, where the player is answered

var leaves: Array = []  ## [pivot, its open yaw]
var bar: Node3D
var block: CollisionShape3D
var mid := Vector3.ZERO  ## the doorway's middle, a metre up, in the castle's frame (this node's)
var state := 0.0  ## 0 open, 1 shut and barred
var goal := 0.0
var _bar_shut := Transform3D.IDENTITY
var _bar_day := Transform3D.IDENTITY
var _last := -1.0  ## the minute of the day last seen
var _answered := -1  ## the game day the gatekeeper last answered the player at the shut gate
var answers := 0  ## how many times he has (the tests')


## Hangs the leaves and the bar at `castle`'s sockets; false if the castle or the kit's pieces are missing.
func setup(castle: Node3D) -> bool:
	add_to_group("castle_gate")
	var socks := castle.find_children("SOCK_GATE_*", "Node3D", true, false)
	var bs := castle.find_child("SOCK_BAR_1", true, false) as Node3D
	if socks.size() < 2 or bs == null or not ResourceLoader.exists(LEAF) or not ResourceLoader.exists(BAR):
		return false
	var at := []
	for s in socks:
		at.append(_rel(s as Node3D, castle))
	at.sort_custom(func(a: Transform3D, b: Transform3D) -> bool: return a.origin.x < b.origin.x)
	for k in 2:
		var pivot := Node3D.new()
		pivot.name = "Leaf%d" % (k + 1)
		pivot.transform = at[k]
		add_child(pivot)
		var leaf: Node3D = (load(LEAF) as PackedScene).instantiate()
		if k == 1:
			leaf.scale = Vector3(-1.0, 1.0, 1.0)  # the east leaf: built along +x from its hinge, here along -x
		pivot.add_child(leaf)
		leaves.append([pivot, deg_to_rad(90.0) if k == 0 else deg_to_rad(-90.0)])  # open: both along the walls, inwards
	var b0 := _rel(bs, castle)
	_bar_shut = b0
	# by day the bar lies on the passage's floor along its west wall, inside the open leaf
	_bar_day = Transform3D(Basis(Vector3.UP, PI / 2.0), b0.origin + Vector3(-1.3, -1.07, -1.7))
	bar = (load(BAR) as PackedScene).instantiate()
	bar.name = "Bar"
	add_child(bar)
	var body := StaticBody3D.new()
	body.name = "Shut"
	add_child(body)
	block = CollisionShape3D.new()
	var box := BoxShape3D.new()
	var w := absf(at[1].origin.x - at[0].origin.x)
	box.size = Vector3(w, 2.7, 0.3)
	block.shape = box
	block.position = (at[0].origin + at[1].origin) / 2.0 + Vector3(0.0, 1.35, 0.0)
	block.disabled = true
	body.add_child(block)
	mid = (at[0].origin + at[1].origin) / 2.0 + Vector3(0.0, 1.0, 0.0)
	var m := fposmod(WorldClock.minute, 1440.0)
	goal = 1.0 if shut_at(m) else 0.0
	state = goal
	_last = m
	_pose()
	return true


## Whether the gate stands shut at `m` minutes of the day.
static func shut_at(m: float) -> bool:
	return m >= SHUT_AT or m < OPEN_AT


## Whether the gate is shut now (barred, or swinging shut).
func is_shut() -> bool:
	return goal > 0.5


## `node`'s transform in `top`'s frame (the sockets lie deep in the castle's scene).
static func _rel(node: Node3D, top: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != top:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


func _process(dt: float) -> void:
	if leaves.is_empty():
		return
	var m := fposmod(WorldClock.minute, 1440.0)
	var jumped := _last >= 0.0 and absf(fposmod(m - _last + 720.0, 1440.0) - 720.0) > 2.0
	_last = m
	var want := 1.0 if shut_at(m) else 0.0
	if want != goal:
		var pl := get_tree().get_first_node_in_group("player") as Node3D
		if pl == null or pl.global_position.distance_to(to_global(mid)) > CLEAR:
			goal = want
			if jumped:
				state = goal
				_pose()
			elif is_instance_valid(AudioDirector):
				AudioDirector.play("SND-218.close" if goal > 0.5 else "SND-218.open", to_global(mid))
	if goal > 0.5 and state >= 1.0:
		_answer()
	var s := move_toward(state, goal, dt / SWING_S)
	if s != state:
		var was := state
		state = s
		_pose()
		if s == 1.0 and was < 1.0 and is_instance_valid(AudioDirector):
			AudioDirector.play("SND-219.knock", to_global(mid))  # the bar dropped into its brackets


func _pose() -> void:
	var swing := clampf(state / 0.8, 0.0, 1.0)  # the leaves first, then the bar
	var e := swing * swing * (3.0 - 2.0 * swing)
	for l in leaves:
		(l[0] as Node3D).rotation.y = lerpf(float(l[1]), 0.0, e)
	var b := clampf((state - 0.8) / 0.2, 0.0, 1.0)
	bar.transform = _bar_day.interpolate_with(_bar_shut, b)
	block.set_deferred("disabled", state < 0.5)


## The player come to the barred gate from outside, after the dusk horns: the gatekeeper answers through the leaves,
## once a night (chapter 07's PB-T60, from data/barks.json as the scenes' lines are).
func _answer() -> void:
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl == null:
		return
	var local := to_local(pl.global_position)
	var line_z := mid.z  # the leaves' line (the castle's frame: its south is +z)
	if local.z < line_z or local.z > line_z + ASK_NEAR or absf(local.x - mid.x) > 2.0:
		return
	var day := int(WorldClock.minute / 1440.0)
	if day == _answered:
		return
	var l := Barks.line(ANSWER)
	if String(l.get("script", "")) == "":
		return
	_answered = day
	answers += 1
	var subs := get_tree().get_first_node_in_group("subtitles")
	if subs == null:
		subs = Subtitles.new()
		get_tree().root.add_child(subs)
	subs.call("say", String(l["script"]), String(l["english"]), 3.5)
