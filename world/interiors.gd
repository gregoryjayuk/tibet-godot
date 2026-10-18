extends Node
## The rooms behind the town's doors (plan chapter 04, 9; chapter 11, 4.2; the game's sprint 7): each room's scene
## (interiors/, made by tools/build/make_rooms.gd) is handed to the Streamer at its house's ROOM socket, so it is
## requested at 40 m, added over three frames at 15 m and freed beyond 60 m, with no loading screen; the shells, the
## rooms' floors, walls and doorways, are the houses' own and always there. And the eye adjusts: while the camera is in a
## room its exposure rises to the room's gain over about 1.5 s, and falls back over 0.8 s outside (chapter 04, 9, as a
## ramp rather than the engine's auto-exposure: the same every time, for the stills, and no pumping at a bright door;
## DECISIONS). Added by world/town.gd when it places a house that has rooms.

## A house's rooms, in its ROOM sockets' order (tibet-blender kit/trading.py, rooms_plan); and the town houses to enter
## (sprint 8, step 7; Greg, 27 Sep 2026: "it would be cool if we could enter some of the houses"), each a free-standing
## three-storey B2 whose first floor is its kitchen (kit/houses.py town_house(interior=True)), the kitchen's variant its
## house's seed (world/town.gd kit_file places the house's): three households, three kitchens. And a poor family's one
## room on the west edge (chapter 04, 4.2; ISS-105), its poor house's variant its seed (kit/houses.py poor_house(interior=True)).
const ROOMS := {"SHL-04": ["dechen_tibetan", "dechen_chinese", "dechen_guest", "dechen_kitchen", "dechen_chapel", "dechen_dolkar"],  # Yard 3's two since M2 sprint 8
		"H-SHL-007": ["house_kitchen_b2_in_v1"], "H-SHL-054": ["house_kitchen_b2_in_v2"], "H-SHL-004": ["house_kitchen_b2_in_v3"],
		"H-SHL-142": ["house_room_e1_in_v2"],
		"SHL-24": ["chang_room_b2_in_v2"],  # the chang house's drinking room (chapter 04, 4.5; M2 sprint 2), its B2's seed 2
		"SAM-01": ["sam01_court_hall"],  # Samkha Khar's court hall (chapter 04, 4.6; M2 sprint 4, step 7)
		# the headman's house, every floor (chapter 04, 4.1; M2 sprint 7), in its ROOM sockets' order (tibet-blender
		# kit/headman.py ROOM_ORDER)
		"SHL-19": ["headman_stable", "headman_hall1", "headman_kitchen", "headman_reception", "headman_grain", "headman_hall2",
				"headman_shrine", "headman_guest", "headman_bed1", "headman_bed2", "headman_roofroom"],
		# the Tsokchen's hall (chapter 04, 3.1; M3 sprint 5, step 2): the nave at the great door, the inner chapel at its door,
		# the upper gallery round the well (tibet-blender kit/monastery.py tsokchen(interior=True), kit/tsokchen_rooms.py)
		"MON-01": ["tsokchen_nave", "tsokchen_chapel", "tsokchen_gallery"],
		# the monastery's other hero rooms (chapter 04, 3.2-3.5; M3 sprint 5, steps 6-8): the Jampa Lhakhang's ground floor
		# and gallery, the Gönkhang, the library's reading room, the Jakhang (kit/jampa_rooms.py, kit/gonkhang_room.py,
		# kit/rooms_gonpa.py)
		"MON-04": ["jampa_ground", "jampa_gallery"], "MON-05": ["gonkhang_room"], "MON-14": ["kangyur_room"], "MON-12": ["jakhang_room"],
		"H-MON-012": ["monk_store", "monk_cell"],  # a monk's house on the west face, its store and its cell (3.7; step 9)
		"MON-09": ["labrang_reception"],  # the Labrang's top storey, the tulku's reception (3.8; step 9)
		"RNG-10": ["parkhang_printing", "parkhang_blocks", "parkhang_chapel"]}  # the Parkhang's printing room, its block store over it and the chapel (3.6; step 8)
const SCENE := "res://interiors/shl_04/%s.tscn"
const HOUSE_SCENE := "res://interiors/houses/%s.tscn"
const SAMKHA_SCENE := "res://interiors/samkha/%s.tscn"
const HEADMAN_SCENE := "res://interiors/headman/%s.tscn"
const TSOKCHEN_SCENE := "res://interiors/tsokchen/%s.tscn"
const GONPA_SCENE := "res://interiors/gonpa/%s.tscn"
const GONPA_ROOMS := ["jampa_", "gonkhang_", "kangyur_", "jakhang_", "monk_", "labrang_", "parkhang_"]
const Message := preload("res://world/message.gd")
const RoofSang := preload("res://world/roof_sang.gd")
const Wardrobe := preload("res://world/wardrobe.gd")
const IN_S := 1.5  ## seconds to adapt going in
const OUT_S := 0.8  ## and coming out

var doors: Array = []  ## {id, socket (Node3D), path}
var gain := 1.0  ## the eye's current gain, for the tests and the HUD
var inside := ""  ## the room the camera is in, or ""
var frozen := false  ## hold the gain where it is
var instant := false  ## the stills: the gain goes to the room's at once (tests/terrain/s3.gd)
var _attrs: CameraAttributesPractical
var _span := 1.0  ## how far the last room's gain stood over the yard's: the ramp's size both ways
const SHADOW_IN := 40.0
var _shadow_back := 160.0  ## the distance the tiers had set, given back on the way out
var _warmed := false  ## the rooms' scenes drawn once behind the Streamer's curtain (chapter 11, 7.5), at the first frame
const FOG_IN := 0.1  ## the volumetric fog's density inside, as a share of the valley's
var _fog_back := 0.003
var _was_inside := false


func _ready() -> void:
	add_to_group("interiors")  # found without searching the town (player/player.gd, characters/named.gd)
	var root := get_parent() as Node3D
	setup(root, root)


## Registers every ROOM socket of the houses under `root` that has a room scene; returns how many.
func setup(root: Node3D, world: Node3D) -> int:
	for house_id in ROOMS:
		var house := root.get_node_or_null(house_id) as Node3D
		if house == null:
			continue
		var names: Array = ROOMS[house_id]
		for k in names.size():
			var sock := house.find_child("SOCK_ROOM_%d" % (k + 1), true, false) as Node3D
			var path := scene_path(names[k])
			if sock == null or not ResourceLoader.exists(path):
				continue
			doors.append({"id": names[k], "socket": sock, "path": path})
	if doors.is_empty():
		return 0
	if get_node_or_null("Message") == null:  # the offers carried between Dechen-tsang's two counting rooms (step 5)
		var msg := Message.new()
		msg.name = "Message"
		add_child(msg)
	var dechen := root.get_node_or_null("SHL-04") as Node3D
	if dechen != null and get_node_or_null("RoofSang") == null:  # juniper on its roof burner at dusk (step 6)
		var rs := RoofSang.new()
		rs.name = "RoofSang"
		add_child(rs)
		rs.setup(dechen)
	if dechen != null and get_node_or_null("Wardrobe") == null:  # the chest in the guest room: the player's clothes (IMP-025)
		var wd := Wardrobe.new()
		wd.name = "Wardrobe"
		add_child(wd)
		wd.setup(dechen)
	if not Streamer.enabled:
		Streamer.setup(world, "")  # no cells here: the town is resident; the Streamer brings the rooms
	for d in doors:
		Streamer.add_interior((d["socket"] as Node3D).global_position, d["path"], d["socket"])
	return doors.size()


## A room's scene (tools/build/make_rooms.gd): Dechen-tsang's, or a town house's.
static func scene_path(room: String) -> String:
	if room.begins_with("sam01_"):
		return SAMKHA_SCENE % room
	if room.begins_with("headman_"):
		return HEADMAN_SCENE % room
	if room.begins_with("tsokchen_"):
		return TSOKCHEN_SCENE % room
	for pre in GONPA_ROOMS:
		if room.begins_with(pre):
			return GONPA_SCENE % room
	return (HOUSE_SCENE if room.begins_with("house_") or room.begins_with("chang_") else SCENE) % room


## The live room (interiors/room.gd) that holds a world position, or null.
func room_at(p: Vector3) -> Node:
	for r in live_rooms():
		if r.holds(p):
			return r
	return null


## The live room scripts (interiors/room.gd) of the rooms now in the tree.
func live_rooms() -> Array:
	var out := []
	for d in doors:
		for c in (d["socket"] as Node3D).get_children():
			var r := c.get_node_or_null("Room")
			if r != null:
				out.append(r)
	return out


func _process(dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or doors.is_empty():
		return
	if not _warmed:  # every pipeline a room needs compiled before play, so none compiles at a door (spike S6)
		_warmed = true
		var paths: Array[String] = []
		for d in doors:
			if not paths.has(String(d["path"])):
				paths.append(String(d["path"]))
		Streamer.warm_up(cam, paths)
	Streamer.focus = cam.global_position
	var target := 1.0
	inside = ""
	for r in live_rooms():
		if r.holds(cam.global_position):
			target = float(r.gain)
			inside = String(r.room_id)
			break
	# Chapter 04, 9: inside, the sun's shadow distance comes down to 40 m, so the door's slab of light is drawn sharp.
	var dn := get_tree().get_first_node_in_group("day")
	var sun: DirectionalLight3D = dn.get("sun") if dn != null else null
	var now_in := inside != ""
	# and the valley's haze thins to a room's air (its coarse cells, lit by the sun beyond a wall, showed as blocks)
	var env: Environment = dn.get("env") if dn != null else null
	if env != null:
		if now_in and not _was_inside:
			_fog_back = env.volumetric_fog_density
		if now_in:
			env.volumetric_fog_density = _fog_back * FOG_IN
		elif _was_inside:
			env.volumetric_fog_density = _fog_back
	if sun != null:
		if now_in and not _was_inside:
			_shadow_back = sun.directional_shadow_max_distance
		if now_in:
			sun.directional_shadow_max_distance = SHADOW_IN
		elif _was_inside:
			sun.directional_shadow_max_distance = _shadow_back
	_was_inside = now_in
	if instant:
		gain = target
	elif not frozen:
		if target > 1.0:
			_span = target - 1.0
		gain = move_toward(gain, target, _span / (IN_S if target > gain else OUT_S) * dt)
	set_gain(cam, gain)


## The camera's exposure multiplier, over the day's own (the keyframes' tonemap exposure).
func set_gain(cam: Camera3D, g: float) -> void:
	if _attrs == null:
		_attrs = cam.attributes as CameraAttributesPractical if cam.attributes is CameraAttributesPractical else CameraAttributesPractical.new()
	if cam.attributes != _attrs:
		cam.attributes = _attrs
	_attrs.exposure_multiplier = g
	gain = g
