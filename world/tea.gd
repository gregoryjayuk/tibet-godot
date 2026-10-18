extends Node3D
## Tea before talk, refilled after each sip (plan chapter 07, 7.2, the script of a visit; PB-T07, PB-T09, PB-T12; the
## game's sprint 7, step 4). On the Tibetan counting room's guest bench, sitting (C), the player is poured tea by whoever
## keeps the room this afternoon and stands within reach of the low table (the house's woman; Achak Dolkar herself if
## she does): before anything is said the bowl is filled to the brim, and she says "Please have tea". E, the first time:
## the libation (the forefinger of the right hand dipped and a little flicked towards the four quarters: Rockhill's form
## in 1903, not the ring finger's of later practice); after that each E is a sip, and she refills the bowl to the brim
## with "Please have tea" again. R: a palm over the bowl and "enough": she pours no more. Standing up, the player hears
## "Go slowly". The node stands at the room's BOWL_3 socket, on the guest's low table (tools/build/make_rooms.gd); the
## bowl is the kit's, the tea in it is drawn here. In the houses to enter (ISS-105) the same at their kitchens' BOWL,
## on the bench by the hearth: the grandmother pours at H-SHL-007, the mother at H-SHL-054, the man of the house at
## H-SHL-004, from where they sit; there the bowl is smaller and stands on the table, or on a stand in a richer house
## (metas "r" and "stand" from make_rooms.gd). The host holds the copper tea jug in her right hand while she serves
## (the kit's tea_pot; ISS-089); she comes to the guest's table and pours, her arm out over it, the jug tipped to the bowl.
## In a poor family's one room (H-SHL-142; chapter 04, 4.2) the guest sits cross-legged behind the log with the bowl on
## it, and the grandmother pours the tea, thin and with little butter, from the copper ladle, standing at the log's end
## (metas "thin", "vessel" and "host" from make_rooms.gd, the kit's HOST socket).

const Subtitles := preload("res://ui/subtitles.gd")
const Barks := preload("res://world/barks.gd")
const SERVERS := ["kitchen_woman", "achak_dolkar", "house_grandmother", "house_mother", "house_man", "poor_grandmother", "ama_yudron", "yudron_daughter",
		"yangchen_drolma"]  ## who pours: the first of them within reach (the headman's mistress from the head of her reception room, M2 sprint 7) of the table
const REACH := 1.6  ## metres from the bowl a server stands to pour
const NEAR := 1.3  ## metres from the bowl the seated player is
const SIP := 0.34  ## a sip takes this much of a full bowl
const POUR_S := 0.9
const REFILL_AFTER := 1.4  ## seconds after a sip before she refills
const R := 0.065  ## the bowl (kit/props.py bowl): its radius, on a stand 3 cm high (Dechen-tsang's; meta "r" and "stand" else)
const SEATED := 2  ## player/player.gd's Rest.SEATED
const TEA := Color(0.79, 0.65, 0.49)  ## butter tea, #C9A77E (chapter 07, 7.1)
const TEA_THIN := Color(0.6, 0.45, 0.31)  ## a poor house's, thin and with little butter: browner, #9A734F (chapter 04, 4.2)
const CHANG := Color(0.86, 0.81, 0.66)  ## hot barley chang, milky (chapter 04, 4.5; design)
const LADLE := "res://assets/generated/kit/types/tea_ladle_v1.glb"
const LADLE_HANDLE := Vector3(-0.4, 0.174, 0.0)  ## the ladle's grip from its bowl's foot (kit/props.py tea_ladle)
const LADLE_SPOUT := Vector3(0.05, 0.046, 0.0)  ## its lip
const POT := "res://assets/generated/kit/types/tea_pot_v1.glb"
const POT_HANDLE := Vector3(-0.074, 0.168, 0.0)  ## the jug's handle from its base (kit/props.py teapot, h 0.28: -0.8 r, 0.6 h)
const POT_SPOUT := Vector3(0.187, 0.244, 0.0)
const AT_TABLE := 0.5  ## metres from the bowl the host stands to pour, the jug within her arm's reach
const POUR_HIGH := 0.25  ## the spout's lip this high over the bowl's rim as she pours
const WALK_TO := 0.9  ## m/s, to the table and back  ## and its spout's lip (0.95 r out, 0.45 h up, then 0.55 h along its 40-degree lean)

enum S { AWAY, POURING, FULL, WAITING, ENOUGH }

var state := S.AWAY
var level := 0.0  ## the tea in the bowl, 0 empty to 1 brimful
var sips := 0
var refills := 0  ## pours after the first
var libation := false
var enough := false
var server := -1  ## the TownSim walker pouring, or -1
var _t := 0.0
var _from := 0.0
var _tea: MeshInstance3D
var _stream: MeshInstance3D
var _named: Node
var r := R  ## this bowl's radius and the height of its foot over the node (a stand's)
var pot: Node3D  ## the tea jug in the host's hand (the kit's tea_pot)
var _grip: Node3D  ## where her right hand goes: the jug's handle
var _pole: Node3D  ## where her elbow points: out to her right and a little back
var _ik: Node  ## her right arm reaching for the jug (a TwoBoneIK3D on her skeleton, while she serves)
var _host_at := Vector3.INF  ## where the host stands while she serves: stepped up from her seat to the guest's table
var _returning := -1  ## the host walking back to her seat after the guest has stood up
var stand := 0.03
var _vessel := POT  ## the jug, or a poor house's ladle (meta "vessel")
var _handle := POT_HANDLE
var _spout := POT_SPOUT
var _tip := -0.75  ## radians the vessel tips to pour
var _pour_high := POUR_HIGH  ## its lip over the bowl's rim as she pours (a ladle's close over it)
var pot_scale := 1.0  ## the vessel drawn this much bigger (the Tsokchen's big kettle: world/hall_tea.gd; its _handle and _spout scaled with it)


func _ready() -> void:
	add_to_group("tea")
	r = float(get_meta("r", R))
	stand = float(get_meta("stand", 0.03))
	if String(get_meta("vessel", "jug")) == "ladle":
		_vessel = LADLE
		_handle = LADLE_HANDLE
		_spout = LADLE_SPOUT
		_tip = -0.6
		_pour_high = 0.12
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = (CHANG if liquid() == "chang" else (TEA_THIN if bool(get_meta("thin", false)) else TEA)) * 0.85
	_tea = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.002
	disc.radial_segments = 16
	disc.material = m
	_tea.mesh = disc
	_tea.visible = false
	add_child(_tea)
	_stream = MeshInstance3D.new()
	var s := CylinderMesh.new()
	s.top_radius = 0.005
	s.bottom_radius = 0.004
	s.height = 0.24
	s.radial_segments = 6
	s.material = m
	_stream.mesh = s
	_stream.position = Vector3(0.0, stand + 0.72 * r + 0.12, 0.0)
	_stream.visible = false
	add_child(_stream)


func _process(dt: float) -> void:
	if _returning >= 0:
		_walk_back(dt)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var sitting := player != null and int(player.get("rest")) == SEATED and _flat(player.global_position) < NEAR
	if not sitting:
		if state != S.AWAY:
			if server >= 0:
				_say_line(String(get_meta("leave_line", "PB-T09")), 3.0)  # Go slowly: the host to one leaving
			_leave()
		return
	if state == S.AWAY:
		server = _server()
		if server < 0:
			return
		if _returning >= 0:  # sat down again while the host was going back: she comes from where she is
			if _returning != server and _named != null:
				(_named.get("overrides") as Dictionary).erase(_returning)
				_host_at = Vector3.INF
			_returning = -1
		_pour()
	_face_player(player)
	_t += dt
	if state == S.POURING and _named != null and not _at_table():  # she pours when she has come to the table (if she is drawn)
		_t = 0.0
	match state:
		S.POURING:
			level = lerpf(_from, 1.0, clampf(_t / POUR_S, 0.0, 1.0))
			if _t >= POUR_S:
				_stream.visible = false
				state = S.FULL
				_say_line(String(get_meta("pour_line", "PB-T07")), 3.0)  # Please have tea (the house's own word else), at every refill
		S.WAITING:
			if _t >= REFILL_AFTER and not enough:
				refills += 1
				_pour()
	_prompt()
	_draw_tea()


func _unhandled_input(e: InputEvent) -> void:
	if state == S.AWAY or not e.is_pressed() or e.is_echo():
		return
	if e.is_action_pressed("use"):  # E, or the controller's triangle
		sip()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("enough"):  # R, or the controller's square
		no_more()
		get_viewport().set_input_as_handled()


## E: the libation first, then a sip.
func sip() -> void:
	if state == S.AWAY or state == S.POURING:
		return
	if not libation:
		libation = true
		_narrate("You dip the forefinger of your right hand in the %s and flick a little towards the four quarters." % liquid())
		return
	if level < 0.05:
		return
	level = maxf(level - SIP, 0.0)
	sips += 1
	_draw_tea()
	if state != S.ENOUGH:
		state = S.WAITING
		_t = 0.0


## R: a palm over the bowl, and "enough".
func no_more() -> void:
	if state == S.AWAY or enough:
		return
	enough = true
	state = S.ENOUGH
	_stream.visible = false
	_say_line(String(get_meta("enough_line", "PB-T12")), 3.0)  # No more, thank you: the guest, a hand over the bowl
	_narrate_after("You cover the bowl with your palm.")


func _pour() -> void:
	state = S.POURING
	_t = 0.0
	_from = level
	_stream.visible = true
	var ad := get_node_or_null("/root/AudioDirector")
	var v: Node = ad.call("play", "SND-604.tea", global_position + Vector3(0.0, 0.1, 0.0)) if ad != null else null
	if v is AudioStreamPlayer3D:  # the pour's note rises as the bowl fills: a refill starts higher (sprint 8, step 4)
		(v as AudioStreamPlayer3D).pitch_scale *= 1.0 + 0.35 * _from


func _leave() -> void:
	state = S.AWAY
	_drop_pot()
	if server >= 0 and _named != null and _host_at != Vector3.INF:
		_returning = server  # she walks back to her seat (_walk_back)
	elif server >= 0 and _named != null:
		(_named.get("overrides") as Dictionary).erase(server)
	server = -1
	enough = false
	_stream.visible = false
	_prompt_text("")


## The first of SERVERS standing (not walking) within reach of the bowl, or -1.
func _server() -> int:
	if not TownSim.walkers_on:
		return -1
	for who in SERVERS:
		for i in TownSim.count:
			if String(TownSim.key[i]) == who and int(TownSim.state[i]) != 0 and int(TownSim.state[i]) != 2 \
					and _flat(TownSim.pos[i]) < float(get_meta("reach", REACH)):  # (a room's own reach: the headman's 3.4 m)
				return i
	return -1


## The server turned to the player while she serves (characters/named.gd's overrides).
func _face_player(player: Node3D) -> void:
	if server < 0:
		return
	if _named == null:
		_named = _hosts()
		if _named == null:
			return
	var seat: Vector3 = _seat_of(server)
	if _host_at == Vector3.INF:
		_host_at = seat
	var stand_at := _table_spot(seat)
	var step := Vector3(stand_at.x - _host_at.x, 0.0, stand_at.z - _host_at.z)
	var moving := step.length() > 0.03
	if moving:
		_host_at += step.normalized() * minf(step.length(), WALK_TO * get_process_delta_time())
	_host_at.y = seat.y
	var to := player.global_position - _host_at
	var o := {"pos": _host_at, "yaw": atan2(step.x, step.z) if moving else atan2(to.x, to.z), "state": 0 if moving else (4 if state == S.POURING else 1),
			"speed": WALK_TO if moving else 0.0}
	if not moving:  # her right arm the jug's (_hold_pot); crouched to serve a guest sitting on the floor (a poor house)
		o["clip"] = "Crouch_Idle" if _low() else "Idle_A"
	(_named.get("overrides") as Dictionary)[server] = o
	_hold_pot()


## Where the host stands to serve: on her side of the guest's table, AT_TABLE from the bowl (or where she is, nearer);
## where the room says (meta "host": a poor house's log's end).
func _table_spot(seat: Vector3) -> Vector3:
	if has_meta("host"):
		var h: Vector3 = global_transform * (get_meta("host") as Vector3)
		return Vector3(h.x, seat.y, h.z)
	var away := Vector3(seat.x - global_position.x, 0.0, seat.z - global_position.z)
	return Vector3(global_position.x, seat.y, global_position.z) + (away.normalized() * AT_TABLE if away.length() > AT_TABLE else away)


## Whether the guest's bowl stands low, on a poor house's log (0.24 m) rather than a low table (0.3 m): the host crouches
## to serve a guest sitting on the floor.
func _low() -> bool:
	return _host_at != Vector3.INF and global_position.y - _host_at.y < 0.27


func _at_table() -> bool:
	if server < 0 or _host_at == Vector3.INF:
		return false
	var spot := _table_spot(_seat_of(server))
	return Vector2(spot.x - _host_at.x, spot.z - _host_at.z).length() < 0.05


## After the guest has stood up: the host back to her seat, then her day has her again.
func _walk_back(dt: float) -> void:
	if _named == null or not _host_valid(_returning):
		_returning = -1
		return
	var seat: Vector3 = _seat_of(_returning)
	var step := Vector3(seat.x - _host_at.x, 0.0, seat.z - _host_at.z)
	if step.length() < 0.05:
		(_named.get("overrides") as Dictionary).erase(_returning)
		_returning = -1
		_host_at = Vector3.INF
		return
	_host_at += step.normalized() * minf(step.length(), WALK_TO * dt)
	_host_at.y = seat.y
	(_named.get("overrides") as Dictionary)[_returning] = {"pos": _host_at, "yaw": atan2(step.x, step.z), "state": 0, "speed": WALK_TO}


## The jug in the host's right hand: at her right side while she serves, out from her robe, its spout forward; over the
## bowl and tipped while she pours, the tea running from its spout into the bowl. Her right arm reaches for its handle (a
## TwoBoneIK3D on her skeleton from the upper arm to the hand, its elbow bent out to her side; while she serves).
func _hold_pot() -> void:
	var body := _host_body()
	var sk := body.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D if body != null and body.visible else null
	if sk == null or sk.find_bone("hand_r") < 0 or not ResourceLoader.exists(_vessel):
		_drop_pot()
		return
	if pot == null:
		pot = (load(_vessel) as PackedScene).instantiate()
		pot.name = "TeaPot"
		add_child(pot)
		_grip = Node3D.new()
		_grip.name = "TeaGrip"
		add_child(_grip)
		_pole = Node3D.new()
		_pole.name = "TeaElbow"
		add_child(_pole)
	var face := Vector3(sin(body.rotation.y), 0.0, cos(body.rotation.y))  # she faces +Z turned by her yaw
	var right := face.cross(Vector3.UP)
	var b: Basis
	var at: Vector3
	var pouring := state == S.POURING and _at_table()
	if pouring:
		var to_bowl := Vector3(global_position.x - _host_at.x, 0.0, global_position.z - _host_at.z).normalized()
		b = Basis(Vector3.UP, atan2(-to_bowl.z, to_bowl.x)) * Basis(Vector3(0.0, 0.0, 1.0), _tip)  # spout (+x) to the bowl, tipped
		at = global_position + Vector3(0.0, stand + 0.72 * r + _pour_high, 0.0) - b * _spout
	else:
		b = Basis(Vector3.UP, atan2(-face.z, face.x))  # the spout forward
		at = _host_at + face * 0.22 + right * 0.2 + Vector3(0.0, 0.55 if _low() else 0.85, 0.0) - b * _handle
	pot.global_transform = Transform3D(b, at)
	pot.scale = Vector3.ONE * pot_scale
	pot.visible = true
	_grip.global_position = at + b * _handle
	_pole.global_position = _host_at + right * 0.6 - face * 0.3 + Vector3(0.0, 0.6 if _low() else 0.9, 0.0)
	if _ik == null or not is_instance_valid(_ik) or _ik.get_parent() != sk:
		_drop_ik()
		var ik := TwoBoneIK3D.new()
		ik.name = "TeaIK"
		ik.set_setting_count(1)
		ik.set_root_bone_name(0, "upperarm_r")
		ik.set_middle_bone_name(0, "lowerarm_r")
		ik.set_end_bone_name(0, "hand_r")
		ik.set_mutable_bone_axes(true)  # (without it the solve leaves the arm as the clip has it)
		sk.add_child(ik)
		ik.set_target_node(0, ik.get_path_to(_grip))
		ik.set_pole_node(0, ik.get_path_to(_pole))
		_ik = ik
	_stream.visible = pouring
	if pouring:  # the tea from the spout's lip down into the bowl
		var lip: Vector3 = at + b * _spout
		var into := global_position + Vector3(0.0, stand + r * (0.2 + 0.5 * level), 0.0)
		var run := lip - into
		var up := run.normalized()
		var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
		_stream.global_transform = Transform3D(Basis(side, up * (run.length() / 0.24), side.cross(up)), (lip + into) / 2.0)  # its 0.24 m mesh stretched


## Where the serving host stands now (the routes look at the bowl and the host).
func host_point() -> Vector3:
	return _host_at if _host_at != Vector3.INF else (_seat_of(server) if server >= 0 else global_position)


## Where host `i` is when not serving (its seat, where it comes from and goes back to): a TownSim walker's place.
func _seat_of(i: int) -> Vector3:
	return TownSim.pos[i]


func _host_valid(i: int) -> bool:
	return i >= 0 and i < TownSim.count


## The node that draws the hosts and takes their `overrides` while they serve (characters/named.gd).
func _hosts() -> Node:
	return get_tree().get_first_node_in_group("named")


## The serving host's body (its root), for the jug in its right hand.
func _host_body() -> Node3D:
	var person: Dictionary = (_named.get("people") as Dictionary).get(server, {})
	return person.get("root")


func _drop_pot() -> void:
	if pot != null:
		pot.visible = false
	_drop_ik()


func _drop_ik() -> void:
	if _ik != null and is_instance_valid(_ik):
		_ik.queue_free()
	_ik = null


func _draw_tea() -> void:
	_tea.visible = level > 0.02
	var z := stand + r * (0.2 + 0.5 * level)
	var rr := 0.9 * r * clampf((z - stand - 0.2 * r) / (0.52 * r), 0.0, 1.0)
	_tea.position = Vector3(0.0, z, 0.0)
	_tea.scale = Vector3(maxf(rr, 0.001), 1.0, maxf(rr, 0.001))


func _flat(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()


func _prompt() -> void:
	match state:
		S.FULL, S.WAITING:
			_prompt_text("E  the libation first" if not libation else "E  sip        R  enough (a palm over the bowl)")
		S.ENOUGH:
			_prompt_text("E  sip        C  stand")
		_:
			_prompt_text("")


func _subs() -> Node:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s == null:
		s = Subtitles.new()
		get_tree().root.add_child(s)
	return s


## A phrasebook line, as checked (world/barks.gd `line`); or one of the story's own (CV-), English until it is checked.
func _say_line(id: String, seconds: float) -> void:
	if id == "":  # (a room where nothing is said over the tea: the Tsokchen's, world/hall_tea.gd)
		return
	if id.begins_with("CV-"):
		var c: Dictionary = Story.line(id)
		_subs().call("say", String(c.get("bo", "")), String(c.get("en", "")), seconds)
		return
	var l := Barks.line(id)
	_subs().call("say", String(l["script"]), String(l["english"]), seconds)


## What is poured: "tea", or "chang" in the chang house (meta "liquid").
func liquid() -> String:
	return String(get_meta("liquid", "tea"))


func _narrate(english: String) -> void:
	_subs().call("narrate", english, 4.0)


func _narrate_after(english: String) -> void:
	await get_tree().create_timer(1.6).timeout
	if is_inside_tree() and enough:
		_narrate(english)


func _prompt_text(t: String) -> void:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s != null or t != "":
		_subs().call("prompt", t)
