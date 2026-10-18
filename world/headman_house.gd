extends Node3D
## The headman's house's moments (plan chapter 04, 4.1: "Call to the dog; accept tea in the reception room and let it be
## refilled ...; sit on the lower bench, never the headman's; ... the chests (locked; a quest line); the roof ladder at
## night"; M2 sprint 7, step 5), added by world/town.gd with the house SHL-19:
## - The mastiff on its chain at its peg on the yard's east wall, south of the gate (the kit's DOG socket): a stranger in or before the
##   yard sets it barking in bursts, turned to them, until someone of the house holds it: E within reach is the player's
##   call, "Hold the dog!" (chapter 02, 5.1; CV-040, in English until it is written in its script), and the groom, if he
##   is about the stable or the yard, comes and holds it by the collar for a few minutes (CV-041), or a word from inside
##   quiets it. From 20:30 to 05:00 it is off its chain, going round the yard, and barks at whoever comes near the gate.
## - The headman's seat: on the bench at the head of the reception room no guest sits; C there is refused (the mistress's
##   "Please, the lower bench", CV-042, if she is in the room; else the narration) and the player stays standing.
## - The hatch: from 20:30 the household shuts the roof's hatch with its board and takes the notched log in (it leaves
##   the group "ladders"); from 05:00 it stands again. Never with the player on the roof or on the log.
## - Locked: the shrine room's three chests and the three stores behind the stable's partition: E by one says so (the
##   mistress keeps the keys).
## - The juniper: the mistress at the roof's burner at dawn and dusk lays juniper on it (world/dusk.gd boost).

const Subtitles := preload("res://ui/subtitles.gd")
const PERSON := preload("res://characters/person.gdshader")
const DOG := "res://assets/generated/people/mastiff.glb"
const BARK := "SND-408"  ## the mastiffs' bark (a stand-in until Greg's recordings: Samkha's)
const BARK_NEAR := 9.0  ## metres from the dog a stranger sets it off
const CALL_REACH := 12.0  ## metres from the dog a call is heard
const HELD_MIN := 5.0  ## game minutes the dog stays quiet after a call answered
const CHAIN := 2.2  ## metres of chain from its peg
const NIGHT := [1230.0, 300.0]  ## 20:30 to 05:00: the dog loose, the hatch shut
const LOCKED_REACH := 1.2
const GROOM := "headman_groom"
const MISTRESS := "yangchen_drolma"

var house: Node3D
var dog: Node3D
var dog_ap: AnimationPlayer
var dog_clip := ""
var peg := Vector3.ZERO  ## the chain's peg (global)
var yard: Array = []  ## the loose dog's round of the yard (global points)
var held_until := -1.0  ## game minutes
var holder := -1  ## the TownSim walker holding it, or -1
var barking := false  ## for the tests and the stills
var calls := 0
var _next_bark := 0.0
var _burst := 0
var _round := 0
var _round_t := 0.0
var _dog_pos := Vector3.ZERO
var locked: Array = []  ## [global position, what]
var bench := AABB()  ## the headman's bench in the house's frame (Godot axes)
var hatch_log: Node3D
var hatch_lid: StaticBody3D
var hatch_shut := false
var _laid := {}  ## the windows the mistress has laid juniper in
var refusals := 0  ## the headman's seat refused, for the tests


## Finds the house and its things under `root` (the town). True if the house is there.
func build(root: Node3D) -> bool:
	house = root.get_node_or_null("SHL-19") as Node3D
	if house == null:
		return false
	add_to_group("named_placers")  # the groom by the dog (characters/named.gd calls place())
	add_to_group("seat_rules")  # the headman's seat refused (player/player.gd sit)
	var sock := house.find_child("SOCK_DOG_1", true, false) as Node3D
	if sock != null:
		peg = sock.global_position
		_dog_pos = peg + _h(Vector3(-0.5, 0.0, 0.0))
		for q in [Vector3(-1.0, -6.6, 0.0), Vector3(-3.6, -8.8, 0.0), Vector3(3.6, -9.8, 0.0), Vector3(4.6, -6.6, 0.0), Vector3(0.5, -8.4, 0.0)]:  # (the kit's x, y, z)
			yard.append(_hp(q))
		_dog()
	# the headman's bench (kit/headman_rooms.py: along the east wall, 1.9 x 0.7, 0.45 high) and the locked things
	bench = AABB(Vector3(4.42, 2.4, 1.95), Vector3(0.78, 0.6, 2.1))  # x 4.42-5.2, the floor 2.45, Godot z = -y: y -4.05..-1.95
	for q in [Vector3(-4.6, 0.15, 5.15), Vector3(-3.65, 0.15, 5.15), Vector3(-2.7, 0.15, 5.15)]:  # the shrine room's chests
		locked.append([_hp(q), "chest"])
	for q in [Vector3(-3.5, 0.95, 0.06), Vector3(-0.75, 0.95, 0.06), Vector3(1.65, 0.95, 0.06)]:  # the stores' doors
		locked.append([_hp(q), "store"])
	hatch_log = root.get_node_or_null("DOORLOG_SHL-19_2") as Node3D
	var hs := house.find_child("SOCK_HATCH_1", true, false) as Node3D
	if hs != null:
		hatch_lid = StaticBody3D.new()
		hatch_lid.name = "HeadmanHatchLid"
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.1, 0.06, 1.5)  # the board over the hatch (kit/headman.py HATCH: 1.0 x 1.4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#6B5236")
		mat.roughness = 1.0
		bm.material = mat
		mi.mesh = bm
		hatch_lid.add_child(mi)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(1.1, 0.12, 1.5)
		cs.shape = sh
		hatch_lid.add_child(cs)
		add_child(hatch_lid)
		hatch_lid.global_position = hs.global_position + Vector3(0.0, 0.03, 0.0)
		hatch_lid.global_rotation.y = house.global_rotation.y
		_set_lid(false)
	return true


## A point of the house's kit frame (Blender axes: x, y, z over the yard) in the world.
func _hp(q: Vector3) -> Vector3:
	return house.to_global(Vector3(q.x, q.z, -q.y))


## A direction of the house's frame (Godot axes) in the world.
func _h(v: Vector3) -> Vector3:
	return house.global_basis * v


func _dog() -> void:
	if not ResourceLoader.exists(DOG):
		return
	dog = Node3D.new()
	dog.name = "HeadmanMastiff"
	add_child(dog)
	var fig: Node3D = (load(DOG) as PackedScene).instantiate()
	fig.scale = Vector3(1.6, 1.15, 1.15)  # the fox made a mastiff: heavier, broader (as Samkha's)
	dog.add_child(fig)
	var mat := ShaderMaterial.new()
	mat.shader = PERSON
	for mi in fig.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat
		(mi as MeshInstance3D).set_instance_shader_parameter("tint", 0.8)
	var sk: Skeleton3D = fig.find_children("*", "Skeleton3D", true, false)[0]
	for bs in [["Head", 1.14], ["Nose", 0.72], ["Tail_Mid.001", 0.5]]:
		var bi := sk.find_bone(String(bs[0]))
		if bi >= 0:
			sk.set_bone_pose_scale(bi, Vector3.ONE * float(bs[1]))
	dog_ap = fig.find_children("*", "AnimationPlayer", true, false)[0]
	for n in ["Walk", "Idle", "Idle Alert", "Sit", "Bark"]:
		if dog_ap.has_animation(n):
			dog_ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	dog.global_position = _dog_pos


static func night(m: float) -> bool:
	return m >= NIGHT[0] or m < NIGHT[1]


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _process(dt: float) -> void:
	if house == null:
		return
	var m := fposmod(WorldClock.minute, 1440.0)
	var p := _player()
	_hatch(m, p)
	_juniper(m)
	if dog == null:
		return
	var loose := night(m)
	var pos := _dog_pos
	var target := Vector3.INF
	if p != null and p.global_position.distance_to(pos) < BARK_NEAR and m >= held_until:
		target = p.global_position
	var clip := "Sit"
	var yaw := dog.rotation.y
	if loose:  # its round of the yard, at a walk, a pause at each point
		var to: Vector3 = yard[_round] - pos
		to.y = 0.0
		if to.length() < 0.3:
			_round_t += dt
			clip = "Idle"
			if _round_t > 4.0:
				_round_t = 0.0
				_round = (_round + 1) % yard.size()
		else:
			pos += to.normalized() * minf(to.length(), 1.1 * dt)
			yaw = atan2(to.x, to.z)
			clip = "Walk"
	elif m < held_until:
		clip = "Sit"
	else:  # back to its place by the peg
		var home := peg + _h(Vector3(-0.5, 0.0, 0.0))
		pos = pos.lerp(home, minf(1.0, 2.0 * dt))
	if target != Vector3.INF:
		var to := target - pos
		to.y = 0.0
		yaw = atan2(to.x, to.z)
		if not loose:  # to the chain's length towards the stranger
			var reach := peg + to.normalized() * CHAIN
			pos = pos.lerp(Vector3(reach.x, pos.y, reach.z), minf(1.0, 3.0 * dt))
		clip = "Bark" if _burst > 0 else "Idle Alert"
		_next_bark -= dt
		if _next_bark <= 0.0:
			if _burst <= 0:
				_burst = randi_range(3, 6)
			if is_instance_valid(AudioDirector):
				AudioDirector.play(BARK, pos + Vector3(0.0, 0.6, 0.0))
			_burst -= 1
			_next_bark = randf_range(0.5, 0.95) if _burst > 0 else randf_range(2.0, 4.0)
		barking = true
	else:
		_burst = 0
		barking = false
	pos.y = peg.y
	_dog_pos = pos
	dog.global_position = pos
	dog.rotation.y = yaw
	if dog_ap != null and dog_ap.has_animation(clip) and dog_clip != clip:
		dog_ap.play(clip, 0.25 if dog_clip != "" else 0.0)
		dog_clip = clip


## E: the player's call to the house when the dog is barking, or a locked thing tried.
func _unhandled_input(e: InputEvent) -> void:
	if not e.is_action_pressed("use"):  # E, or the controller's triangle (autoload/controls.gd)
		return
	var p := _player()
	if p == null or int(p.get("rest")) != 0:
		return
	if call_to_house(p.global_position):
		get_viewport().set_input_as_handled()
		return
	for l in locked:
		if (l[0] as Vector3).distance_to(p.global_position) < LOCKED_REACH:
			_narrate("Locked. The mistress keeps the keys of the house's stores and chests.")
			get_viewport().set_input_as_handled()
			return


## The player's call from `at`: "Hold the dog!" if the dog is barking within reach; the groom comes to hold it if he is
## about the stable or the yard, else a word from inside quiets it. True if called.
func call_to_house(at: Vector3) -> bool:
	if dog == null or not barking or at.distance_to(_dog_pos) > CALL_REACH:
		return false
	calls += 1
	_say("CV-040", "Hold the dog!", "")
	var m := fposmod(WorldClock.minute, 1440.0)
	held_until = m + HELD_MIN
	holder = -1
	for i in TownSim.count:
		if String(TownSim.key[i]) == GROOM and int(TownSim.state[i]) != 2 and TownSim.pos[i].distance_to(peg) < 14.0:
			holder = i
	if holder >= 0:
		_say("CV-041", "He's held. Come in.", "the groom")
	barking = false
	_burst = 0
	return true


## player/player.gd's sit asks: may the player sit at `at`, or at `back` (the sit's second probe, a bench further
## back)? Not on the headman's bench.
func may_sit(at: Vector3, back = null) -> bool:
	if house == null:
		return true
	var local := house.to_local(at)
	if not bench.grow(0.1).has_point(local) and (back == null or not bench.grow(0.1).has_point(house.to_local(back as Vector3))):
		return true
	var mistress_here := false
	for i in TownSim.count:
		if String(TownSim.key[i]) == MISTRESS and int(TownSim.state[i]) != 2 and house.to_local(TownSim.pos[i]).distance_to(local) < 4.0:
			mistress_here = true
	if mistress_here:
		_say("CV-042", "Please, sit on the lower bench.", "the mistress")
	else:
		_narrate("The headman's seat, at the head of the room: a guest sits on the lower bench.")
	refusals += 1
	return false


## characters/named.gd, before it draws: the groom by the dog while he holds it.
func place(named: Node) -> void:
	var ov: Dictionary = named.get("overrides")
	var m := fposmod(WorldClock.minute, 1440.0)
	for i in ov.keys():
		if (ov[i] as Dictionary).get("by", "") == "headman" and (i != holder or m >= held_until):
			ov.erase(i)
	if holder < 0 or m >= held_until or dog == null:
		return
	if ov.has(holder) and (ov[holder] as Dictionary).get("by", "") != "headman":
		return
	var side := _h(Vector3(0.6, 0.0, 0.0))
	var at := _dog_pos + side
	var to := _dog_pos - at
	ov[holder] = {"pos": at, "yaw": atan2(to.x, to.z), "speed": 0.0, "state": 5, "clip": "", "by": "headman"}


## The hatch shut from 20:30 to 05:00: its board on and the log taken in; never with the player on the roof or the log.
func _hatch(m: float, p: Node3D) -> void:
	var want := night(m)
	if want == hatch_shut:
		return
	if want and p != null:
		var local := house.to_local(p.global_position)
		if local.y > 7.5 or (p.get("ladder") != null and p.get("ladder") == hatch_log):
			return  # wait until the player is down
	_set_lid(want)


func _set_lid(shut: bool) -> void:
	hatch_shut = shut
	if hatch_lid != null:
		hatch_lid.visible = shut
		hatch_lid.process_mode = Node.PROCESS_MODE_INHERIT if shut else Node.PROCESS_MODE_DISABLED
		(hatch_lid.get_child(1) as CollisionShape3D).disabled = not shut
	if hatch_log != null:
		hatch_log.visible = not shut
		if shut:
			hatch_log.remove_from_group("ladders")
		else:
			hatch_log.add_to_group("ladders")


## The mistress at the roof's burner lays juniper on it, once a window (world/dusk.gd's boost).
func _juniper(m: float) -> void:
	var win := "dawn" if m < 720.0 else "dusk"
	if _laid.get(win, -1) == int(WorldClock.minute / 1440.0):
		return
	var burner := house.find_child("SOCK_SANG_1", true, false) as Node3D
	if burner == null:
		return
	for i in TownSim.count:
		if String(TownSim.key[i]) == MISTRESS and int(TownSim.state[i]) == 1 and TownSim.pos[i].distance_to(burner.global_position) < 2.0:
			var dusk := get_tree().get_first_node_in_group("dusk")
			if dusk != null and bool(dusk.call("boost", burner.global_position, 40.0)):
				_laid[win] = int(WorldClock.minute / 1440.0)


func _say(id: String, english: String, who: String) -> void:
	var l: Dictionary = Story.line(id) if is_instance_valid(Story) else {}
	var en := String(l.get("en", english)) if l.get("en", "") != "" else english
	var s := _subs()
	if s == null:
		return
	if String(l.get("bo", "")) != "":
		s.call("say", String(l["bo"]), en, 3.5, who)
	else:
		s.call("narrate", ("%s: \"%s\"" % [who, en]) if who != "" else "\"%s\"" % en, 3.5)


func _narrate(text: String) -> void:
	var s := _subs()
	if s != null:
		s.call("narrate", text, 4.0)


func _subs() -> Node:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s == null:
		s = Subtitles.new()
		get_tree().root.add_child(s)
	return s
