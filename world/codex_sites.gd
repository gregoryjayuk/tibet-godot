extends Node
## Where the slice's codex nods are found (plan chapter 11, 14.3: look at (a 1.5 s look within reach), enter, witness;
## chapter 07, 9; M1 sprint 7, step 7), added by world/town.gd once the town is built. The ones found by doing are
## found where they are done: CX-048 and CX-052 by the message (world/message.gd), CX-050 by juniper laid on
## Dechen-tsang's burner (world/roof_sang.gd).
## - look: the camera within reach of the thing and turned to it (within LOOK_DEG of the view's middle) for LOOK_S.
## - enter: the player within reach of the place.
## - roof: the player up on a roof while the town's juniper burns (17:00-17:45, 05:45-06:30).

const Horizon := preload("res://world/horizon.gd")
const LOOK_S := 1.5
const LOOK_DEG := 10.0
const EVERY := 0.1  ## seconds between checks

## [id, how, where, reach (m)]; where: a node under the town (its origin), a node's socket ("SHL-40:SOCK_STONE_1"), a
## point in a building's frame (Godot's axes: "SHL-04@16.8,0.5,14.67"), or a named walker ("walker:achak_dolkar")
const SITES := [
	["CX-047", "look", "SHL-29_1@0,0.9,0", 6.0],  # Tsongra's fuel stalls, the women's
	["CX-049", "look", "SHL-03@0,4.0,0", 16.0],  # Tsongra's darchen
	["CX-051", "enter", "SHL-04@16.8,0.5,14.67", 2.5],  # the animal passage under Dechen-tsang's east range
	["CX-053", "look", "walker:achak_dolkar", 5.0],  # Achak Dolkar herself
	["CX-057", "look", "SHL-27@0,0.6,0", 5.0],  # Pasang's stones, the syllables painted
	["CX-058", "look", "SHL-27@0,0.6,0", 5.0],  # and again: the small stones the beggars sell
	["CX-063", "enter", "SHL-16:SOCK_HOUSE_2@1.5,-3.5,0", 3.5],  # the east window in the tunnel, halfway up
	["CX-064", "enter", "SHL-17@0,1.0,0", 3.0],  # through the gateway chorten
	["CX-070", "roof", "", 0.0],  # up on a roof while the juniper burns
	["CX-071", "look", "SHL-40:SOCK_STONE_1", 5.0],  # the lifting stone before the talkers' steps
	["CX-103", "enter", "SER-01@0,1.0,0", 3.0],  # under the Gate Chorten on the way into town (M2 sprint 3)
	["CX-061", "look", "SHL-14:SOCK_NAGA_1", 6.0],  # the naga's niche over the Lukhang spring (M2 sprint 6, step 3)
	["CX-062", "look", "SHL-14:SOCK_WATER_1", 8.0],  # the spouts, where the women fill their barrels
	["CX-146", "look", "SHL-04@27.7,6.4,-19.5", 6.0],  # White Tara on Dechen-tsang's chapel altar, Dolkar's namesake (M2 sprint 8)
	["CX-093", "look", "MON-24@0,1.3,1.5", 5.0],  # the tsa-tsas stacked in the tsa-tsa house's window on the Gönkor (M3 sprint 7, step 1)
]

var town: Node3D
var _dwell := {}  ## id -> seconds looked at
var _t := 0.0


func _ready() -> void:
	town = get_parent() as Node3D


func _process(dt: float) -> void:
	_t += dt
	if _t < EVERY:
		return
	var step := _t
	_t = 0.0
	var cam := get_viewport().get_camera_3d()
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if cam == null:
		return
	for s in SITES:
		var id: String = s[0]
		if Codex.found.has(id):
			continue
		if id == "CX-058" and (not Codex.found.has("CX-057") or WorldClock.minute - float(Codex.found["CX-057"]) < 0.3):
			continue  # the pitch's second nod: a second look, a moment after the first
		match String(s[1]):
			"look":
				var at: Variant = where(String(s[2]))
				if at != null and looking(cam.global_transform, at, float(s[3])):
					_dwell[id] = float(_dwell.get(id, 0.0)) + step
					if float(_dwell[id]) >= LOOK_S:
						Codex.find(id)
				else:
					_dwell[id] = 0.0
			"enter":
				var at2: Variant = where(String(s[2]))
				if player != null and at2 != null and player.global_position.distance_to(at2) < float(s[3]):
					Codex.find(id)
			"roof":
				if player != null and _on_roof(player) and _juniper_burning():
					Codex.find(id)


## Whether a camera at `cam` is within `reach` of `p` and turned to it (the ray from the view's middle within LOOK_DEG).
static func looking(cam: Transform3D, p: Vector3, reach: float) -> bool:
	var to := p - cam.origin
	var d := to.length()
	if d > reach or d < 0.05:
		return false
	return (-cam.basis.z).normalized().dot(to / d) > cos(deg_to_rad(LOOK_DEG))


## A site's point in the world, or null if its node is not in the town.
func where(spec: String) -> Variant:
	if spec.begins_with("walker:"):
		var key := spec.substr(7)
		for i in TownSim.count:
			if String(TownSim.key[i]) == key and int(TownSim.state[i]) != 2:
				return (TownSim.pos[i] as Vector3) + Vector3(0.0, 1.45, 0.0)
		return null
	var off := Vector3.ZERO
	if spec.contains("@"):
		var v := spec.get_slice("@", 1).split(",")
		off = Vector3(float(v[0]), float(v[1]), float(v[2]))
		spec = spec.get_slice("@", 0)
	var n := town.find_child(spec.get_slice(":", 0), false, false) as Node3D if town != null else null
	if n == null:
		return null
	if spec.contains(":"):
		n = n.find_child(spec.get_slice(":", 1), true, false) as Node3D
		if n == null:
			return null
	return n.global_transform * off


func _on_roof(player: Node3D) -> bool:
	var g := Horizon.ground_at(player.global_position.x, -player.global_position.z)
	return not is_nan(g) and player.global_position.y - g > 3.0


static func _juniper_burning() -> bool:
	var m := fposmod(WorldClock.minute, 1440.0)
	return (m >= 17.0 * 60.0 and m <= 17.75 * 60.0) or (m >= 5.75 * 60.0 and m <= 6.5 * 60.0)
