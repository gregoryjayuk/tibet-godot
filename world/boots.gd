extends Node
## Boots off in the halls, and the Gönkhang's rule (M3 sprint 6, step 2; plan chapter 04, 9 "Shoes": "crossing into
## MON-01, MON-04, MON-05, MON-09, MON-14 and any shrine room, the player's boots come off at the threshold (a 1 s
## animation) and go back on when leaving"; 3.1's boot row; 3.3's rule, chapter 02's D08). Crossing into one of HALLS'
## rooms (world/interiors.gd `room_at`), the player stoops a second, the coat heard (SND-602), and their boots stand by the
## door behind them (the kit's `boots_player_man` or `_woman`) while they go in stockinged and soft-footed
## (player/player.gd `boots_off`, player/steps.gd); leaving, they stoop again and the boots are on. At the Gönkhang's
## outer curtain its keeper stands from 06:00 to 23:00; the player as a woman is stopped there by the monastery's rule, an
## unseen bar across the doorway, the keeper's gesture and his courteous line (chapter 07's PB-T62, for a native speaker),
## and sees the room from the porch. Added by world/town.gd.

const HALLS := ["tsokchen_nave", "tsokchen_chapel", "tsokchen_gallery", "jampa_ground", "jampa_gallery", "gonkhang_room",
		"kangyur_room", "labrang_reception", "parkhang_chapel"]
const PAUSE := 1.0  ## seconds stooped at the threshold
const BEHIND := 0.65  ## metres behind the player, back towards the door, that the boots are set down
const KIT := "res://assets/generated/kit/types/%s_v1.glb"
const KEEPER_BODY := "res://assets/generated/people/tode_monk_c.glb"
const KEEPER_HOURS := [360.0, 1380.0]  ## 06:00-23:00 (chapter 04, 3.3: one of the two always present)
const KEEPER_AT := Vector3(1.15, 0.0, 1.0)  ## in the Gönkhang's door's frame (its DOOR socket: -z the way in): beside it, out on the porch
const BAR := Vector3(1.9, 2.6, 0.16)  ## the unseen bar across the doorway for a woman, centred 0.1 m out from the door's face
const STOP_NEAR := 2.2  ## metres out from the door within which the keeper turns her away
const LINE := "PB-T62"  ## the keeper's line (chapter 07)
const Subtitles := preload("res://ui/subtitles.gd")
const Barks := preload("res://world/barks.gd")

var off := false  ## the player's boots are off
var pair: Node3D  ## the player's boots, set down by the door
var keeper: Node3D
var keeper_ap: AnimationPlayer
var door: Node3D  ## the Gönkhang's DOOR socket
var bar: StaticBody3D
var turned_away := 0  ## the times the keeper turned the player away (the tests')
var _said_at := -1e9  ## when he last said it (msec)
var _interiors: Node


## Whether boots come off in the room with this id.
static func in_hall(room_id: String) -> bool:
	return room_id in HALLS


## Whether a point in the Gönkhang's door's frame (-z the way in) is before its curtain, near enough to be stopped.
static func at_the_curtain(local: Vector3) -> bool:
	return local.z > -0.3 and local.z < STOP_NEAR and absf(local.x) < 1.6 and absf(local.y) < 1.5


## Finds the Gönkhang's door, stands its keeper there and lays the bar. The keeper's count (0 or 1).
func build(root: Node) -> int:
	var g := root.find_child("MON-05", true, false) as Node3D
	if g == null:
		return 0
	door = g.find_child("SOCK_DOOR_1", true, false) as Node3D
	if door == null:
		return 0
	bar = StaticBody3D.new()
	bar.name = "WomensBar"
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = BAR
	cs.shape = box
	bar.add_child(cs)
	door.add_child(bar)
	bar.position = Vector3(0.0, BAR.y / 2.0, 0.1)
	bar.collision_layer = 0
	if ResourceLoader.exists(KEEPER_BODY):
		keeper = (load(KEEPER_BODY) as PackedScene).instantiate()
		keeper.name = "GonkhangKeeper"
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://characters/person.gdshader")
		PersonLook.apply(keeper, mat)
		door.add_child(keeper)
		keeper.position = KEEPER_AT
		keeper.rotation.y = deg_to_rad(-25.0)  # facing out, turned a little to the doorway
		keeper_ap = keeper.find_children("*", "AnimationPlayer", true, false)[0]
		if keeper_ap.has_animation("Idle_A"):
			keeper_ap.get_animation("Idle_A").loop_mode = Animation.LOOP_LINEAR
			keeper_ap.play("Idle_A")
	return 1 if keeper != null else 0


func _physics_process(_dt: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null or not bool(p.get("third_person")):
		return
	_boots(p)
	_rule(p)


## The boots: off crossing into a hall, on again leaving it, never on a ladder, seated or mid-step over a sill.
func _boots(p: Node3D) -> void:
	if _interiors == null:
		_interiors = get_tree().get_first_node_in_group("interiors")
		if _interiors == null:
			return
	var room: Node = _interiors.call("room_at", p.global_position + Vector3(0.0, 1.0, 0.0))
	var inside := room != null and in_hall(String(room.get("room_id")))
	# off entering a hall's room; on again only out under the sky (a hall's corridors and stairs are no room of the list:
	# the Tsokchen's Nangkor and its gallery stair had put them on and off again)
	var change := (inside and not off) or (off and not inside and _under_sky(p))
	if not change or int(p.get("rest")) != 0 or p.get("ladder") != null or not (p.get("over") as Dictionary).is_empty():
		return
	off = inside
	p.call("boots_off", off, PAUSE)
	print("boots: %s at %s, %s, %s" % ["off" if off else "on again", String(room.get("room_id")) if room != null else "the door",
			Calendar.clock(WorldClock.minute), str(p.global_position.snapped(Vector3(0.1, 0.1, 0.1)))])
	var ad := get_node_or_null("/root/AudioDirector")
	if ad != null:
		ad.call("play", "SND-602", p.global_position + Vector3(0.0, 0.4, 0.0))
	if off:
		_set_down(p)
	elif pair != null:
		pair.queue_free()
		pair = null


## Whether nothing roofs the player within 8 m overhead: out of the hall's shell (its porch keeps them off a step longer).
func _under_sky(p: Node3D) -> bool:
	var head := p.global_position + Vector3(0.0, 1.7, 0.0)
	var q := PhysicsRayQueryParameters3D.create(head, head + Vector3(0.0, 8.0, 0.0))
	q.exclude = [(p as CollisionObject3D).get_rid()]
	return p.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## The player's boots stood on the floor behind them, back towards the door they came in by.
func _set_down(p: Node3D) -> void:
	var kind := "boots_player_woman" if bool(p.get("woman")) else "boots_player_man"
	if not ResourceLoader.exists(KIT % kind):
		return
	var v := Vector3(p.get("velocity").x, 0.0, p.get("velocity").z)
	var back := -v.normalized() if v.length() > 0.2 else Vector3(sin(float(p.get("facing"))), 0.0, cos(float(p.get("facing"))))
	var at := p.global_position + back * BEHIND
	var hit := p.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3(0.0, 0.8, 0.0), at - Vector3(0.0, 1.0, 0.0)))
	if not hit.is_empty():
		at.y = (hit["position"] as Vector3).y
	pair = (load(KIT % kind) as PackedScene).instantiate()
	pair.name = "PlayersBoots"
	var host: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	host.add_child(pair)
	pair.global_position = at
	pair.rotation.y = atan2(-back.x, -back.z) + PI  # their toes to the room: put on again facing out
	pair.add_to_group("players_boots")


## The Gönkhang's rule: the bar across its doorway while the player is a woman; the keeper, at his hours, turns her away
## with his gesture and his line, once in a while.
func _rule(p: Node3D) -> void:
	if door == null:
		return
	var woman := bool(p.get("woman"))
	var m := fposmod(WorldClock.minute, 1440.0)
	var keeping := m >= KEEPER_HOURS[0] and m < KEEPER_HOURS[1]
	if keeper != null:
		keeper.visible = keeping
	bar.collision_layer = 1 if woman else 0
	if not woman or not keeping:
		return
	var local := door.to_local(p.global_position)
	if not at_the_curtain(local):
		return
	var now := Time.get_ticks_msec()
	if now - _said_at < 20000:
		return
	_said_at = now
	turned_away += 1
	if keeper_ap != null:
		for g in ["Interact", "Greeting", "Head_Nod"]:
			if keeper_ap.has_animation(g):
				keeper_ap.play(g, 0.2)
				keeper_ap.queue("Idle_A")
				break
	var l := Barks.line(LINE)
	if String(l.get("script", "")) == "":
		return
	var subs := get_tree().get_first_node_in_group("subtitles")
	if subs == null:
		subs = Subtitles.new()
		get_tree().root.add_child(subs)
	subs.call("say", String(l["script"]), String(l["english"]), 6.0)
