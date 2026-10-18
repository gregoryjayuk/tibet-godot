extends SceneTree
## Dechen-tsang's four rooms as scenes (plan chapter 04, 4.3, 8.2 and 9; the game's sprint 7, step 1): each room's
## furnishings from the kit (tibet-blender kit/rooms.py, exported as dechen_<room>_v1.glb) with the room's own lights,
## at most three (chapter 04, 8.6), and the flames and coals drawn as cards (shaders/flame.gdshader). The scenes'
## origin is the room's ROOM socket on the trading house: on the floor at the doorway's inner face, the room to -Z.
## interiors/room.gd drives the lights; world/interiors.gd streams the scenes in behind their doors (chapter 04, 9).
## Light recipes (chapter 04, 8.2): the counting rooms LR-09T (the window and the door, a brazier or a lamp), the guest
## room LR-07 (the door, a lamp at the back), the kitchen LR-04 (the stove's two mouths, the window); a poor family's
## one room LR-04, poor (chapter 04, 4.2: the fire, the smoke hole's day over it, the door's; its lamp lit only at dusk).
## Run headless (after the kit's export and an --import):
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/build/make_rooms.gd

const KIT := "res://assets/generated/kit/types/%s"
const OUT := "res://interiors/shl_04"
const HOUSES := "res://interiors/houses"  ## the town houses' kitchens (sprint 8, step 7)
const SAMKHA := "res://interiors/samkha"  ## Samkha Khar's court hall (M2 sprint 4, step 7)
const HEADMAN := "res://interiors/headman"  ## the headman's house, every floor (M2 sprint 7)
const TSOKCHEN := "res://interiors/tsokchen"  ## the Tsokchen's hall (M3 sprint 5)
const GONPA := "res://interiors/gonpa"  ## the monastery's other hero rooms (M3 sprint 5, steps 6-8)
const LAMP_MM := preload("res://shaders/lamp_mm.gdshader")
const MANY := 24  ## a room with more flames than this draws them as one MultiMesh (the Tsokchen's lamp bank)
const FLAME := preload("res://shaders/flame.gdshader")
const SHAFT := preload("res://shaders/shaft.gdshader")

## room: [recipe, eye's gain, lights]; a light: [kind, where (door, WINDOW_1, SMOKEHOLE_1, FIRE_n, FLAME_n), energy, range,
## colour]
const ROOMS := {
	"dechen_tibetan": ["LR-09T", 1.6, [["day", "door", 1.4, 9.0, "#F6EEE2"], ["day", "WINDOW_1", 1.1, 9.0, "#F3EBDD"], ["fire", "FIRE_1", 2.0, 9.0, "#FF8C4A"]]],
	"dechen_chinese": ["LR-09T", 1.6, [["day", "door", 1.4, 9.0, "#F6EEE2"], ["day", "WINDOW_1", 1.1, 9.0, "#F3EBDD"], ["flame", "FLAME_1", 0.7, 9.0, "#F4B24A"]]],
	"dechen_guest": ["LR-07", 1.4, [["day", "door", 1.5, 9.0, "#F6EEE2"], ["flame", "FLAME_1", 0.5, 9.0, "#F4B24A"]]],
	"dechen_kitchen": ["LR-04", 1.8, [["fire", "FIRE_1", 1.3, 9.0, "#FF8C4A"], ["fire", "FIRE_2", 1.3, 9.0, "#FF8C4A"], ["day", "WINDOW_1", 1.5, 9.0, "#F3EBDD"]]],
	# Yard 3 (M2 sprint 8, step 2; chapter 04, 4.3): the chapel LR-02, its line of nine butter lamps (the light at the middle
	# one), its gilt window and its door's day; Dolkar's reception room LR-09T, her two lattice windows on the garden and
	# the brazier's coals
	"dechen_chapel": ["LR-02", 1.9, [["flame", "FLAME_5", 1.0, 8.0, "#F4B24A"], ["day", "WINDOW_1", 1.2, 9.0, "#F3EBDD"], ["day", "door", 0.9, 8.0, "#F6EEE2"]]],
	"dechen_dolkar": ["LR-09T", 1.6, [["day", "WINDOW_1", 1.2, 9.0, "#F3EBDD"], ["day", "WINDOW_2", 1.1, 9.0, "#F3EBDD"], ["fire", "FIRE_1", 1.5, 8.0, "#FF8C4A"]]],
	# the town houses' kitchens (sprint 8, step 7; chapter 04, 6.2, LR-04): the stove's fire, the door's day and the
	# window's, three lights
	"house_kitchen_b2_in_v1": ["LR-04", 1.8, [["fire", "FIRE_1", 1.2, 8.0, "#FF8C4A"], ["day", "door", 1.3, 8.0, "#F6EEE2"], ["day", "WINDOW_1", 1.2, 8.0, "#F3EBDD"]]],
	"house_kitchen_b2_in_v2": ["LR-04", 1.8, [["fire", "FIRE_1", 1.2, 8.0, "#FF8C4A"], ["day", "door", 1.3, 8.0, "#F6EEE2"], ["day", "WINDOW_1", 1.2, 8.0, "#F3EBDD"]]],
	"house_kitchen_b2_in_v3": ["LR-04", 1.8, [["fire", "FIRE_1", 1.2, 8.0, "#FF8C4A"], ["day", "door", 1.3, 8.0, "#F6EEE2"], ["day", "WINDOW_1", 1.2, 8.0, "#F3EBDD"]]],
	# a poor family's one room on the west edge (chapter 04, 4.2; ISS-105): no window, the open fire, the smoke hole's
	# day straight down on it, the door's day while it stands open
	"house_room_e1_in_v1": ["LR-04", 1.25, [["fire", "FIRE_1", 0.9, 7.0, "#FF8C4A"], ["day", "SMOKEHOLE_1", 0.45, 7.0, "#F3EBDD"], ["day", "door", 0.8, 7.0, "#F6EEE2"]]],
	"house_room_e1_in_v2": ["LR-04", 1.25, [["fire", "FIRE_1", 0.9, 7.0, "#FF8C4A"], ["day", "SMOKEHOLE_1", 0.45, 7.0, "#F3EBDD"], ["day", "door", 0.8, 7.0, "#F6EEE2"]]],
	# the chang house's drinking room (chapter 04, 4.5; M2 sprint 2): the stove's fire under the pan, the door's day and
	# the window's
	"chang_room_b2_in_v1": ["LR-04", 1.7, [["fire", "FIRE_1", 1.3, 8.0, "#FF8C4A"], ["day", "door", 1.4, 8.0, "#F6EEE2"], ["flame", "FLAME_1", 0.8, 7.0, "#F4B24A"]]],
	"chang_room_b2_in_v2": ["LR-04", 1.7, [["fire", "FIRE_1", 1.3, 8.0, "#FF8C4A"], ["day", "door", 1.4, 8.0, "#F6EEE2"], ["flame", "FLAME_1", 0.8, 7.0, "#F4B24A"]]],
	"chang_room_b2_in_v3": ["LR-04", 1.7, [["fire", "FIRE_1", 1.3, 8.0, "#FF8C4A"], ["day", "door", 1.4, 8.0, "#F6EEE2"], ["flame", "FLAME_1", 0.8, 7.0, "#F4B24A"]]],
	"house_room_e1_in_v3": ["LR-04", 1.25, [["fire", "FIRE_1", 0.9, 7.0, "#FF8C4A"], ["day", "SMOKEHOLE_1", 0.45, 7.0, "#F3EBDD"], ["day", "door", 0.8, 7.0, "#F6EEE2"]]],
	# Samkha Khar's court hall (chapter 04, 4.6; M2 sprint 4, step 7; LR-09T): its two windows onto the ward behind the
	# dais and the brazier before it
	"sam01_court_hall": ["LR-09T", 1.6, [["day", "WINDOW_1", 1.4, 11.0, "#F3EBDD"], ["day", "WINDOW_2", 1.4, 11.0, "#F3EBDD"], ["fire", "FIRE_1", 1.5, 9.0, "#FF8C4A"]]],
	# the headman's house, every floor (chapter 04, 4.1; M2 sprint 7, step 3): at most three lights a floor, each floor's lit
	# only while the camera is on it (interiors/room.gd floor_band): the stable's door (LR-06, its slit's thread a sun
	# matter); the kitchen's stove and the smoke-hole's day (LR-04); the reception's south windows (LR-09T, its brazier's
	# coals drawn, not lit); the second floor's hatch over its hall, the shrine's butter lamps (LR-02) and the guest room's
	# bay; the roof room's window. The halls, the grain room and the bedrooms take what comes through their doors.
	"headman_stable": ["LR-06", 1.7, [["day", "door", 0.9, 9.0, "#F6EEE2"]]],
	"headman_hall1": ["LR-07", 1.5, []],
	"headman_kitchen": ["LR-04", 1.9, [["fire", "FIRE_1", 1.4, 9.0, "#FF8C4A"], ["day", "SMOKEHOLE_1", 0.6, 8.0, "#F3EBDD"]]],
	"headman_reception": ["LR-09T", 1.6, [["day", "WINDOW_1", 1.4, 9.0, "#F3EBDD"]]],
	"headman_grain": ["LR-06", 1.6, []],
	"headman_hall2": ["LR-07", 1.5, [["day", "SKY_1", 0.9, 8.0, "#F3EBDD"]]],
	"headman_shrine": ["LR-02", 2.0, [["flame", "FLAME_1", 0.8, 7.0, "#F4B24A"]]],
	"headman_guest": ["LR-07", 1.5, [["day", "WINDOW_1", 1.3, 8.0, "#F3EBDD"]]],
	"headman_bed1": ["LR-07", 1.6, []],
	"headman_bed2": ["LR-07", 1.6, []],
	"headman_roofroom": ["LR-07", 1.4, [["day", "WINDOW_1", 1.2, 7.0, "#F3EBDD"]]],
	# the Tsokchen's hall (chapter 04, 3.1; M3 sprint 5, step 2): the nave LR-01 (the lamp bank's two clusters either side of
	# the inner chapel's door, the well's day from the lantern, the door's), the inner chapel LR-02 (its lamps, its door),
	# the gallery lit by the well. Spike S7 tries the rest of the stack (chapter 11).
	"tsokchen_nave": ["LR-01", 1.7, [["flame", "FLAME_62", 1.7, 9.0, "#F4B24A"], ["flame", "FLAME_185", 1.7, 9.0, "#F4B24A"],
			["day", "SKY_1", 0.8, 12.5, "#F3EBDD"], ["day", "door", 0.6, 7.0, "#F6EEE2"]]],
	"tsokchen_chapel": ["LR-02", 1.8, [["flame", "FLAME_5", 1.4, 8.0, "#F4B24A"], ["day", "door", 0.35, 6.0, "#F6EEE2"]]],
	"tsokchen_gallery": ["LR-07", 1.6, []],
	# the Jampa Lhakhang (chapter 04, 3.2; LR-02 and V-30's shaft): the altar's lamps and the door below; above, the rail's
	# lamps lighting the face from below and the two O4 windows' day on it
	"jampa_ground": ["LR-02", 1.9, [["flame", "FLAME_100", 1.6, 9.0, "#F4B24A"], ["day", "door", 0.5, 7.0, "#F6EEE2"]]],
	"jampa_gallery": ["LR-02", 1.8, [["flame", "FLAME_11", 1.1, 6.0, "#F4B24A"], ["day", "WINDOW_1", 0.7, 9.0, "#F3EBDD"]]],
	# the Gönkhang (3.3; LR-03): two lamps, before Lhamo and before the conch; the darkest room in the game (the vent's pin
	# of sky is no light)
	"gonkhang_room": ["LR-03", 1.5, [["flame", "FLAME_1", 0.8, 6.0, "#F4B24A"], ["flame", "FLAME_2", 0.8, 5.0, "#F4B24A"]]],
	# the library (3.4; LR-02 and its south window); the Jakhang (3.5; LR-04): its fireboxes and its smoke lantern's day
	"kangyur_room": ["LR-02", 1.8, [["day", "WINDOW_1", 1.1, 8.0, "#F3EBDD"], ["flame", "FLAME_2", 1.0, 6.0, "#F4B24A"]]],
	"jakhang_room": ["LR-04", 1.7, [["fire", "FIRE_1", 1.2, 8.0, "#FF8C4A"], ["fire", "FIRE_2", 1.4, 9.0, "#FF8C4A"], ["fire", "FIRE_3", 1.1, 8.0, "#FF8C4A"]]],
	# a monk's house (3.7; LR-04 small): its store by the door's day, its cell by its stove and its window
	"monk_store": ["LR-04", 1.6, [["day", "door", 0.7, 5.0, "#F6EEE2"]]],
	"monk_cell": ["LR-04", 1.8, [["fire", "FIRE_1", 0.9, 5.0, "#FF8C4A"], ["day", "WINDOW_1", 0.8, 5.0, "#F3EBDD"]]],
	# the Labrang's reception (3.8; LR-09T): its paper windows, a brazier, the lamps on the throne's table
	"labrang_reception": ["LR-09T", 1.5, [["day", "WINDOW_1", 1.3, 10.0, "#F3EBDD"], ["fire", "FIRE_1", 1.0, 6.0, "#FF8C4A"], ["flame", "FLAME_1", 0.8, 6.0, "#F4B24A"]]],
	# the Parkhang (M3 sprint 5, step 8; chapter 04, 3.6): the printing room by its north windows' day, the block store by its
	# one far window's and the hatch's, the chapel by its one lamp
	"parkhang_printing": ["LR-12", 1.6, [["day", "WINDOW_1", 1.2, 10.0, "#F3EBDD"], ["day", "WINDOW_2", 1.2, 10.0, "#F3EBDD"], ["day", "WINDOW_3", 1.2, 10.0, "#F3EBDD"]]],
	"parkhang_blocks": ["LR-12", 1.5, [["day", "WINDOW_1", 1.0, 9.0, "#F3EBDD"], ["day", "door", 0.8, 6.0, "#F6EEE2"]]],
	"parkhang_chapel": ["LR-02", 1.8, [["flame", "FLAME_1", 0.9, 7.0, "#F4B24A"], ["day", "door", 0.6, 6.0, "#F6EEE2"]]],
}
## The headman's floors' bands (chapter 04, 4.1: at most three lights on a floor, five across the house): a room's lights
## burn while the camera stands from 0.4 m under its floor to 0.4 m under the next floor's, so no two floors burn at once
## (its floors at 0.06, 2.45, 5.15 and 8.21 m: tibet-blender kit/headman.py FLOORS)
const HEADMAN_BANDS := {"headman_stable": 1.99, "headman_hall1": 2.3, "headman_kitchen": 2.3, "headman_reception": 2.3,
		"headman_grain": 2.3, "headman_hall2": 2.66, "headman_shrine": 2.66, "headman_guest": 2.66, "headman_bed1": 2.66,
		"headman_bed2": 2.66, "headman_roofroom": 99.0}
const NO_SHADOWS := ["parkhang_blocks"]  ## rooms whose furnishings cast no shadow: the Parkhang's 10,000 blocks, seen only from inside (chapter 04, 3.6)
const DUSK_LAMPS := ["house_room_e1_in", "chang_room", "dechen_dolkar"]  ## rooms whose lamp is lit only at dusk (4.2: butter too dear but on a good day; the chang house's oil lamp for the evening's drinkers; Dolkar's by her seat)


## A room's kit file (without its extension): Dechen-tsang's rooms are their types' first variants, a house's kitchen
## names its variant.
static func kit(room: String) -> String:
	return KIT % (room if room.begins_with("house_") or room.begins_with("chang_") else room + "_v1")


static func godot(p: Array) -> Vector3:
	return Vector3(float(p[0]), float(p[2]), -float(p[1]))  # Blender (x, y, z), z up -> Godot (x, z, -y)


func _card(parent: Node3D, name: String, at: Vector3, size: Vector2, kind: int, strength: float, seed: float, owner: Node) -> void:
	var mi := MeshInstance3D.new()
	mi.name = name
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = FLAME
	m.set_shader_parameter("kind", kind)
	m.set_shader_parameter("strength", strength)
	m.set_shader_parameter("seed", seed)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = at
	parent.add_child(mi)
	mi.owner = owner


## A room's many flames as one MultiMesh of cards (shaders/lamp_mm.gdshader, kind 0, lit): [Godot position, a cauldron's]
## each, a cauldron's flame larger.
func _flames_mm(root: Node3D, flames: Array) -> void:
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mat := ShaderMaterial.new()
	mat.shader = LAMP_MM
	mat.set_shader_parameter("kind", 0)
	q.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = q
	mm.instance_count = flames.size()
	for i in flames.size():
		var big: bool = flames[i][1]
		var sz := Vector2(0.09, 0.18) if big else Vector2(0.035, 0.07)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(sz.x, sz.y, 1.0)), (flames[i][0] as Vector3) + Vector3(0.0, sz.y * 0.35, 0.0)))
		mm.set_instance_custom_data(i, Color(1.0, float(i) * 0.731, 0.0, 0.0))
	var mi := MultiMeshInstance3D.new()
	mi.name = "Flames"
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.owner = root


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(HOUSES))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAMKHA))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(HEADMAN))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TSOKCHEN))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GONPA))
	for room in ROOMS:
		var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(kit(room) + ".json"))
		var socks: Dictionary = side["socket_pos"]
		var b: Array = side["rooms"][0]  # x0, x1, y0, y1, z0, z1 in the kit's frame
		var recipe: Array = ROOMS[room]
		var root := Node3D.new()
		root.name = room
		# the room's own light, first among the children (autoload/streamer.gd adds them last to first)
		var rn := Node3D.new()
		rn.name = "Room"
		rn.set_script(load("res://interiors/room.gd"))
		root.add_child(rn)
		rn.owner = root
		rn.set("room_id", room)
		rn.set("recipe", recipe[0])
		rn.set("gain", recipe[1])
		if room == "dechen_dolkar" and socks.has("SOCK_CLOCK_1"):  # the one French clock she winds at dusk (data/named_days.json:
			# 17:26-17:30) ticks for an hour, 17:30-18:30 (chapter 04, 4.3; SND-239, a synthesised stand-in)
			rn.set_meta("music", ["SND-239", 1050.0, 1110.0, godot(socks["SOCK_CLOCK_1"])])
		if room.begins_with("chang_") and socks.has("SOCK_SEAT_7"):  # the dranyen from 19:00 until the muleteer on seat 7 goes at 21:25 (SND-229)
			rn.set_meta("music", ["SND-229", 1140.0, 1285.0, godot(socks["SOCK_SEAT_7"]) + Vector3(0.0, 0.6, 0.0)])
		rn.set("box", AABB(Vector3(b[0], b[4], -float(b[3])), Vector3(float(b[1]) - float(b[0]), float(b[5]) - float(b[4]), float(b[3]) - float(b[2]))))
		if HEADMAN_BANDS.has(room):  # a floor of a house of floors: its lights only while the camera is on it
			rn.set("floor_band", Vector2(-0.4, float(HEADMAN_BANDS[room])))
		if room in NO_SHADOWS:
			rn.set("shadows", false)
		var glb: PackedScene = load(kit(room) + ".glb")
		var inst := glb.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		inst.name = "Furnishings"
		root.add_child(inst)
		inst.owner = root
		if room == "headman_stable":  # its beasts at their stalls (M2 sprint 7, step 4; interiors/beasts.gd)
			var bn := Node3D.new()
			bn.name = "Beasts"
			bn.set_script(load("res://interiors/beasts.gd"))
			root.add_child(bn)
			bn.owner = root
		var n_lights := 0
		for l in recipe[2]:
			var at: Vector3
			if l[1] == "door":
				at = Vector3(0.0, 1.3, -0.6)
			elif socks.has("SOCK_" + l[1]):
				at = godot(socks["SOCK_" + l[1]])
				if String(l[1]).begins_with("WINDOW"):  # just inside, so the wall round the window takes its light: along the
					# socket's +y, into the room (a window on any of the room's walls)
					var yaw := deg_to_rad(float((side.get("socket_yaw", {}) as Dictionary).get("SOCK_" + l[1], 90.0)))
					at += Vector3(cos(yaw), 0.0, -sin(yaw)) * 0.45
				elif String(l[1]).begins_with("SKY"):  # a hatch's day: half a metre under the hole in the ceiling
					at += Vector3(0.0, -0.6, 0.0)
				elif String(l[1]).begins_with("SMOKEHOLE"):
					at.y = 0.9  # low over the fire under the hole, so its pool is the hearth's and the walls stay dark (a spot
					# under the hole cut its cone's edge on the walls in the light clusters' steps)
				elif String(l[1]).begins_with("FIRE"):
					at += Vector3(0.0, 0.12, 0.0)
				else:  # a flame's light a little out from the wall it stands against, so the wall is not burnt white
					var towards := Vector3((float(b[0]) + float(b[1])) / 2.0 - at.x, 0.0, -float(b[3]) / 2.0 - at.z)  # to the room's middle
					at += Vector3(0.0, 0.08, 0.0) + towards.normalized() * 0.3
			else:
				push_warning("make_rooms: %s has no socket %s" % [room, l[1]])
				continue
			var ol := OmniLight3D.new()
			ol.omni_range = float(l[3])
			# inverse-square, and a range past the walls: where a light's range ended inside a room, the renderer's light
			# clusters (32-pixel tiles) cut it off in steps
			ol.omni_attenuation = 2.0
			ol.name = "%s_%s" % [String(l[0]).capitalize(), String(l[1]).to_lower()]
			ol.light_color = Color(l[4])
			ol.light_energy = float(l[2])
			ol.shadow_enabled = false
			ol.light_specular = 0.0
			ol.light_volumetric_fog_energy = 0.0  # the valley's haze is not in a room: lit by a fire, its 64-cell grid showed as orange steps
			ol.set_meta("kind", l[0])
			if l[0] == "flame" and DUSK_LAMPS.any(func(d: String) -> bool: return room.begins_with(d)):
				ol.set_meta("dusk", true)  # interiors/room.gd: its light only while its flame burns
			ol.position = at
			root.add_child(ol)
			ol.owner = root
			n_lights += 1
		# the cards: every lamp's flame, every fire's coals or mouth; a room of many lamps draws them as one MultiMesh
		var flames: Array = []
		for s in socks:
			if String(s).begins_with("SOCK_FLAME") or String(s).begins_with("SOCK_CAULDRON"):
				flames.append([godot(socks[s]), String(s).begins_with("SOCK_CAULDRON")])
		var many := flames.size() > MANY
		if many:
			_flames_mm(root, flames)
		var k := 0
		for s in socks:
			var at := godot(socks[s])
			if many and (String(s).begins_with("SOCK_FLAME") or String(s).begins_with("SOCK_CAULDRON")):
				k += 1
				continue
			if String(s).begins_with("SOCK_FLAME"):
				_card(root, "Flame_%d" % k, at + Vector3(0.0, 0.025, 0.0), Vector2(0.035, 0.07), 0, 1.0, float(k), root)
				if DUSK_LAMPS.any(func(d: String) -> bool: return room.begins_with(d)):
					root.get_node("Flame_%d" % k).set_meta("dusk", true)  # interiors/room.gd lights it at dusk
			elif String(s).begins_with("SOCK_FIRE") and room.begins_with("house_room"):  # an open fire between three stones:
				# its embers, and flames licking up round the pot
				_card(root, "Coals_%d" % k, at, Vector2(0.36, 0.2), 1, 1.1, float(k), root)
				for f in 3:
					var a := TAU * f / 3.0 + 0.5
					_card(root, "Fire_%d_%d" % [k, f], at + Vector3(0.07 * cos(a), 0.08, 0.07 * sin(a)), Vector2(0.11, 0.2), 0, 0.7, float(k * 3 + f), root)
			elif String(s).begins_with("SOCK_FIRE"):
				var brazier: bool = room == "dechen_tibetan" or room == "dechen_dolkar"
				_card(root, "Coals_%d" % k, at + Vector3(0.0, 0.02 if brazier else 0.0, 0.0), Vector2(0.34, 0.2) if brazier else Vector2(0.3, 0.24), 1,
					  0.9 if brazier else 1.2, float(k), root)
			k += 1
		if socks.has("SOCK_SMOKEHOLE_1"):  # the shaft of day through the smoke under the hole (shaders/shaft.gdshader)
			var hole := godot(socks["SOCK_SMOKEHOLE_1"])
			var mi := MeshInstance3D.new()
			mi.name = "Shaft"
			var q := QuadMesh.new()
			q.size = Vector2(0.4, hole.y - 0.05)
			mi.mesh = q
			var sm := ShaderMaterial.new()
			sm.shader = SHAFT
			mi.material_override = sm
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.position = Vector3(hole.x, (hole.y + 0.05) / 2.0, hole.z)
			mi.set_meta("shaft", true)  # interiors/room.gd: its strength the day's
			root.add_child(mi)
			mi.owner = root
		var bowl := "SOCK_BOWL_3" if room == "dechen_tibetan" else ("SOCK_BOWL_1" if room.begins_with("house_") or room.begins_with("chang_") or room == "headman_reception" else "")
		if bowl != "" and socks.has(bowl):  # the guest's tea (world/tea.gd; sprint 7, step 4; the houses' kitchens, ISS-105)
			var tea := Node3D.new()
			tea.name = "Tea"
			tea.set_script(load("res://world/tea.gd"))
			tea.position = godot(socks[bowl])
			if room.begins_with("house_") or room.begins_with("chang_"):  # a plain bowl of 6 cm on the table (or the log), its BOWL at its foot (kit/rooms.py)
				tea.set_meta("r", 0.06)
				tea.set_meta("stand", 0.0)
			if room == "headman_reception":  # the guest's bowl on its stand on the lower bench's table; the mistress pours from
				tea.set_meta("reach", 3.4)  # the head of the room, the headman's bench (chapter 04, 4.1; M2 sprint 7, step 5)
			if room.begins_with("chang_"):  # the chang house: hot chang from the pan's ladle, Ama Yudrön's own word
				tea.set_meta("liquid", "chang")
				tea.set_meta("vessel", "ladle")
				tea.set_meta("pour_line", "CV-010")
				if socks.has("SOCK_HOST_1"):
					tea.set_meta("host", godot(socks["SOCK_HOST_1"]) - godot(socks[bowl]))
			if room.begins_with("house_room"):  # a poor house's tea: thin, little butter, from the copper ladle, poured by
				# whoever is home standing at the log's end (4.2; the kit's HOST socket)
				tea.set_meta("thin", true)
				tea.set_meta("vessel", "ladle")
				if socks.has("SOCK_HOST_1"):
					tea.set_meta("host", godot(socks["SOCK_HOST_1"]) - godot(socks[bowl]))  # from the bowl, the room's frame
			root.add_child(tea)
			tea.owner = root
		var ps := PackedScene.new()
		ps.pack(root)
		var path := "%s/%s.tscn" % [HOUSES if room.begins_with("house_") or room.begins_with("chang_") else (SAMKHA if room.begins_with("sam01_") else (HEADMAN if room.begins_with("headman_") else (TSOKCHEN if room.begins_with("tsokchen_") else (GONPA if room.begins_with("jampa_") or room.begins_with("gonkhang_") or room.begins_with("kangyur_") or room.begins_with("jakhang_") or room.begins_with("monk_") or room.begins_with("labrang_") or room.begins_with("parkhang_") else OUT)))), room]
		var err := ResourceSaver.save(ps, path)
		print("make_rooms: %s (%s, gain %.1f, %d lights) -> %s %s" % [room, recipe[0], recipe[1], n_lights, path, "ok" if err == OK else "error %d" % err])
		root.free()
	quit()
