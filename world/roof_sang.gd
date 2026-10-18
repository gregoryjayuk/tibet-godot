extends Node
## Juniper on Dechen-tsang's roof burner at dusk (plan chapter 02, 8.3: Pratt saw the Dartsedo inn burn juniper on its roof
## "about five o'clock"; chapter 04, 4.3's day, 17:00 roof sang; CX-050, CX-070; the game's sprint 7, step 6). From 16:58
## to 17:45 the household (Achak Dolkar, the house's woman) stands at the burner on the master range's roof, where the
## Rooftop Way (R-06) begins; a player who has climbed up to it can lay juniper on it with them: E by the burner. The
## thread of smoke thickens and climbs with the town's (world/dusk.gd `boost`), and whoever of the household is by it
## says "The gods are victorious!" (PB-T43: said at a sang fire; its script from world/barks.gd `line`). Added by
## world/interiors.gd with the house.

const Subtitles := preload("res://ui/subtitles.gd")
const Barks := preload("res://world/barks.gd")
const FROM := 16.0 * 60.0 + 58.0
const UNTIL := 17.0 * 60.0 + 45.0
const REACH := 2.4  ## metres from the burner, on its roof
const HOUSEHOLD := ["achak_dolkar", "kitchen_woman"]

var burner: Node3D  ## Dechen-tsang's SOCK_SANG_1
var laid := 0  ## sprigs laid this session, for the tests and the codex
var _cool := 0.0
var _near := false


func setup(house: Node3D) -> void:
	burner = house.find_child("SOCK_SANG_1", true, false) as Node3D


func _process(dt: float) -> void:
	_cool -= dt
	var now := near()
	if now != _near:
		_near = now
		_prompt("E  lay juniper on the burner" if now else "")


## Whether the player stands by the burner in the evening's window.
func near() -> bool:
	if burner == null:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or int(player.get("rest")) != 0:
		return false
	var m := fposmod(WorldClock.minute, 1440.0)
	var d := player.global_position - burner.global_position
	return m >= FROM and m <= UNTIL and Vector2(d.x, d.z).length() < REACH and absf(d.y) < 1.8


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("use") and lay():  # E, or the controller's triangle
		get_viewport().set_input_as_handled()


## E by the burner: a sprig of juniper laid on it. True if it was.
func lay() -> bool:
	if not near() or _cool > 0.0:
		return false
	laid += 1
	_cool = 6.0
	Codex.find("CX-050")  # five o'clock smoke (autoload/codex.gd)
	var dusk := get_tree().get_first_node_in_group("dusk")
	if dusk != null and not bool(dusk.call("boost", burner.global_position)):
		push_warning("roof_sang: no burner of the dusk's by Dechen-tsang's SOCK_SANG_1: no smoke")
	if _household_by():
		var l := Barks.line("PB-T43")  # The gods are victorious! At a sang fire
		_subs().call("say", String(l["script"]), String(l["english"]), 3.5)
		_narrate_later("You lay a sprig of juniper on the burner. The smoke thickens and climbs with the town's.", 3.6)
	else:
		_subs().call("narrate", "You lay a sprig of juniper on the burner. The smoke thickens and climbs with the town's.", 5.0)
	return true


func _household_by() -> bool:
	if not TownSim.walkers_on:
		return false
	for i in TownSim.count:
		if String(TownSim.key[i]) in HOUSEHOLD and int(TownSim.state[i]) != 2 and (TownSim.pos[i] as Vector3).distance_to(burner.global_position) < 5.0:
			return true
	return false


func _subs() -> Node:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s == null:
		s = Subtitles.new()
		get_tree().root.add_child(s)
	return s


func _narrate_later(english: String, after: float) -> void:
	await get_tree().create_timer(after).timeout
	if is_inside_tree():
		_subs().call("narrate", english, 5.0)


func _prompt(t: String) -> void:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s != null or t != "":
		_subs().call("prompt", t)
