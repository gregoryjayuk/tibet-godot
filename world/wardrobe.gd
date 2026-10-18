extends Node3D
## The chest in Dechen-tsang's guest room, the player's room (IMP-025; Greg's 1771, 7 Oct 2026: "a 'choose your player' or
## dress your player screen, perhaps this could be a screen that appears somewhere in the residence where we can change
## clothes"). E by the chest opens it: the clothes laid out on a page (ui/wardrobe_page.gd), the walker turning slowly
## on a painted ring on the floor, the camera still on the side of the room with most room (player/player.gd `dress`);
## W and S (or the up and down arrows) put on the next or the last, worn at once; A and D turn the walker; B shows the
## other of the two; E or Esc closes the chest in what is worn (Enter too until 14 Oct 2026). On the controller (IMP-044):
## the D-pad's up and down, the left stick turns, square the other, triangle or circle closes. Added by
## world/interiors.gd with the house.

const Page := preload("res://ui/wardrobe_page.gd")
const RING := preload("res://shaders/mandala.gdshader")
const Subtitles := preload("res://ui/subtitles.gd")
const REACH := 1.7  ## metres from the chest
## The chest in the guest room's frame (kit/rooms.py dechen_guest: under its butter lamp, SOCK_FLAME_1), here; the room is
## streamed in under its door's socket, SOCK_ROOM_3 (world/interiors.gd ROOMS)
const AT := Vector3(1.83, 0.0, -3.73)

var chest := Vector3.INF
var open := false
var page: CanvasLayer
var ring: MeshInstance3D
var _near := false


func setup(house: Node3D) -> void:
	add_to_group("wardrobe")
	Controls.device_changed.connect(_relabel)
	var sock := house.find_child("SOCK_ROOM_3", true, false) as Node3D
	if sock != null:
		chest = sock.global_transform * AT


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


## Whether the player stands by the chest, on their feet.
func near() -> bool:
	var p := _player()
	if p == null or chest == Vector3.INF or int(p.get("rest")) != 0:
		return false
	var d := p.global_position - chest
	return Vector2(d.x, d.z).length() < REACH and absf(d.y) < 1.2


func _process(_dt: float) -> void:
	var now := near() and not open
	if now != _near:
		_near = now
		_prompt("E  open the chest: your clothes" if now else "")


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo() or e is InputEventJoypadMotion:
		return
	if not open:
		if e.is_action_pressed("use") and open_chest():
			get_viewport().set_input_as_handled()
		return
	if e.is_action_pressed("move_forward") or e.is_action_pressed("page_up"):  # W, the up arrow, the D-pad's up
		step(-1)
	elif e.is_action_pressed("move_back") or e.is_action_pressed("page_down"):
		step(1)
	elif e.is_action_pressed("jump") and e is InputEventJoypadButton:  # the controller's square: the other of the two (B)
		var p := _player()
		if p != null:
			p.call("other_body")
	elif e.is_action_pressed("use") or e.is_action_pressed("back"):  # E, Esc; triangle, circle
		close_chest()
	else:
		return
	get_viewport().set_input_as_handled()


## E by the chest: opens it. True if it opened.
func open_chest() -> bool:
	var p := _player()
	if open or p == null or not near():
		return false
	open = true
	Controls.open_page("wardrobe", true)
	p.call("dress", true)
	_prompt("")
	if page == null:
		page = Page.new()
		add_child(page)
	page.visible = true
	_ring(p.global_position)
	shown()
	return true


## Puts on the next (1) or the last (-1) of what the one shown can wear.
func step(by: int) -> bool:
	var p := _player()
	if p == null or not open:
		return false
	var k := "woman" if bool(p.get("woman")) else "man"
	var n: int = (p.get("OUTFITS")[k] as Array).size()
	var i := posmod(int(p.get("outfit")[k]) + by, n)
	var done := bool(p.call("wear", i))
	shown()
	return done


## The page brought up to date with what is worn (also when B shows the other of the two).
func shown() -> void:
	var p := _player()
	if p == null or page == null:
		return
	var k := "woman" if bool(p.get("woman")) else "man"
	page.call("show_outfits", p.get("OUTFITS")[k], int(p.get("outfit")[k]), k)


## The device changed (the keys, the controller): the page's keys shown for it.
func _relabel() -> void:
	if open:
		shown()


func close_chest() -> void:
	var p := _player()
	open = false
	Controls.open_page("wardrobe", false)
	if p != null:
		p.call("dress", false)
	if page != null:
		page.visible = false
	if ring != null:
		ring.visible = false


func _ring(at: Vector3) -> void:
	if ring == null:
		ring = MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(2.2, 2.2)
		q.orientation = PlaneMesh.FACE_Y
		ring.mesh = q
		var m := ShaderMaterial.new()
		m.shader = RING
		ring.material_override = m
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
	ring.global_position = at + Vector3(0.0, 0.012, 0.0)
	ring.visible = true


func _prompt(t: String) -> void:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s == null and t != "":
		s = Subtitles.new()
		get_tree().root.add_child(s)
	if s != null:
		s.call("prompt", t)
