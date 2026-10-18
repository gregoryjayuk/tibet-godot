extends GutTest
## Samkha Khar and the south pavilion (M2 sprint 4, steps 4 and 5; ../tibet-blender kit/samkha.py; plan chapter 03, 5.1):
## the castle on the slot's rim with the gate passage through its ground storey on the chain bridge's line, its floor on
## the level of the deck's end and five steps down into the ward; the gate's leaves shut and barred at the dusk horns
## (world/castle_gate.gd); the passage's lamp and the pavilion's butter lamps (world/lamps.gd); the pavilion's floor
## meeting the deck's south end; the places where world/town.gd puts them those of data/samkha.json.

const Town := preload("res://world/town.gd")
const CastleGate := preload("res://world/castle_gate.gd")
const Lamps := preload("res://world/lamps.gd")
const Interiors := preload("res://world/interiors.gd")
const CASTLE := "res://assets/generated/kit/types/sam01_castle_v1"
const PAVILION := "res://assets/generated/kit/types/sam04_pavilion_v1"


func _sk() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/samkha.json"))


func _side(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path + ".json"))


func test_the_town_places_them_where_the_ground_was_made_for_them() -> void:
	var sk := _sk()
	for pair in [["SAM-01", "castle"], ["SAM-04", "pavilion"]]:
		var nm: Array = Town.NAMED[pair[0]]
		var at: Dictionary = sk[pair[1]]
		assert_almost_eq(float(nm[2][0]), float(at["at"][0]), 0.01, "%s's x is samkha.json's" % pair[0])
		assert_almost_eq(float(nm[2][1]), float(at["at"][1]), 0.01, "%s's y is samkha.json's" % pair[0])
		assert_almost_eq(float(nm[1]), float(at["z"]), 0.01, "%s's level is samkha.json's" % pair[0])
		assert_almost_eq(float(nm[3]), float(at["facing"]), 0.01, "%s faces as samkha.json says" % pair[0])
	assert_almost_eq(float(sk["tower"]["y"][0]), float(sk["ward"]["y"][0]), 0.01, "the tower's south face on the ward's south edge, the rim")


func test_the_bridge_lands_in_the_passage_and_the_passage_runs_through() -> void:
	if not FileAccess.file_exists(CASTLE + ".json"):
		fail_test("the castle not exported (../tibet-blender export_types.py --types sam01_castle)")
		return
	var sk := _sk()
	var side := _side(CASTLE)
	var c: Array = sk["castle"]["at"]
	var pos: Dictionary = side["socket_pos"]
	var mouth: Array = pos["SOCK_PASSAGE_1"]
	# the kit's y is the town's y about the castle's origin (it faces 180: no turn)
	assert_almost_eq(float(c[0]) + float(mouth[0]), float(sk["bridge"]["x"]), 0.05, "the passage on the bridge's line")
	assert_lt(float(c[1]) + float(mouth[1]), float(sk["bridge"]["north"][0]), "the deck's end inside the passage's mouth")
	assert_almost_eq(float(sk["castle"]["z"]) + float(mouth[2]), float(sk["bridge"]["north"][1]), 0.02, "the passage's floor on the deck end's level")
	assert_almost_eq(float(sk["passage"]["z_from"]), float(sk["bridge"]["north"][1]), 0.02, "the ground under it made for that level")
	assert_almost_eq(float(sk["stair"]["z_to"]), float(sk["ward"]["z"]), 0.01, "its steps down to the ward's level")
	for k in ["SOCK_GATE_1", "SOCK_GATE_2", "SOCK_BAR_1", "SOCK_FLAME_1", "SOCK_PRAYER_WHEEL_1", "SOCK_LATRINE_1", "SOCK_PAVILION_1", "SOCK_WARD_GATE_1", "SOCK_DOOR_1"]:
		assert_true(pos.has(k), "the castle has its %s" % k)
	assert_lt(int(side["triangles"]["L0"]), 60001, "within chapter 11's 60,000")
	assert_gt(float(pos["SOCK_PRAYER_WHEEL_1"][1]), 7.0, "the prayer wheel at the inner door, the north end")


func test_the_castle_lets_the_walker_through() -> void:
	if not ResourceLoader.exists(CASTLE + ".glb"):
		fail_test("the castle not exported")
		return
	var g: Node3D = (load(CASTLE + ".glb") as PackedScene).instantiate()
	add_child_autofree(g)
	g.position = Vector3(0.0, -700.0, 0.0)
	await wait_physics_frames(2)
	var space := g.get_world_3d().direct_space_state
	var at := func(x: float, y: float, z: float) -> Vector3: return g.global_transform * Vector3(x, z, -y)  # the kit's frame
	for y in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at.call(0.0, y, 3.5), at.call(0.0, y, 0.5)))
		assert_false(hit.is_empty(), "the passage's floor underfoot at %.0f m" % y)
		if not hit.is_empty():
			assert_almost_eq((g.global_transform.affine_inverse() * (hit["position"] as Vector3)).y, 1.5, 0.05, "on the plinth's level")
	var through := space.intersect_ray(PhysicsRayQueryParameters3D.create(at.call(0.0, -12.0, 2.6), at.call(0.0, 12.0, 2.6)))
	assert_true(through.is_empty(), "nothing across the passage from end to end at head height")
	var wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(at.call(-6.0, -14.0, 3.0), at.call(-6.0, 14.0, 3.0)))
	assert_false(wall.is_empty(), "beside the passage the tower is solid")


func test_the_gate_shuts_at_the_dusk_horns() -> void:
	assert_false(CastleGate.shut_at(17.0 * 60.0 + 29.0), "open at 17:29")
	assert_true(CastleGate.shut_at(17.0 * 60.0 + 30.0), "shut at 17:30, the dusk horns")
	assert_true(CastleGate.shut_at(2.0 * 60.0), "shut in the night")
	assert_true(CastleGate.shut_at(5.0 * 60.0 + 29.0), "shut till 05:30")
	assert_false(CastleGate.shut_at(5.0 * 60.0 + 30.0), "open from 05:30")
	if not ResourceLoader.exists(CASTLE + ".glb"):
		return
	var keep := WorldClock.minute
	var g: Node3D = (load(CASTLE + ".glb") as PackedScene).instantiate()
	add_child_autofree(g)
	WorldClock.minute = 18.0 * 60.0
	var gate := CastleGate.new()
	g.add_child(gate)
	assert_true(gate.setup(g), "its leaves and bar hung at the castle's sockets")
	assert_eq(gate.leaves.size(), 2, "two leaves")
	assert_true(gate.is_shut(), "shut at 18:00")
	var l0 := (gate.leaves[0][0] as Node3D)
	var l1 := (gate.leaves[1][0] as Node3D)
	assert_almost_eq(l0.rotation.y, 0.0, 0.01, "the west leaf across the passage")
	assert_almost_eq(l1.rotation.y, 0.0, 0.01, "the east leaf across it")
	WorldClock.minute = 9.0 * 60.0
	await wait_frames(3)
	assert_false(gate.is_shut(), "the clock jumped to 09:00: open at once")
	assert_almost_eq(absf(l0.rotation.y), PI / 2.0, 0.01, "the west leaf back against its wall")
	WorldClock.minute = keep


func test_the_passage_lamp_never_out_and_the_shrine_at_dusk() -> void:
	assert_eq(Lamps.lit("passage", 0, 12.0 * 60.0), 1.0, "the passage's lamp at noon")
	assert_eq(Lamps.lit("passage", 0, 2.0 * 60.0), 1.0, "and at night")
	assert_eq(Lamps.lit("shrine", 2, 12.0 * 60.0), 0.0, "Thangtong Gyalpo's lamps out at noon")
	assert_eq(Lamps.lit("shrine", 2, 18.0 * 60.0), 1.0, "lit at 18:00")
	assert_eq(Lamps.lit("shrine", 2, 22.0 * 60.0), 0.0, "out after 21:00")


func test_the_pavilion_meets_the_deck() -> void:
	if not FileAccess.file_exists(PAVILION + ".json"):
		fail_test("the south pavilion not exported (--types sam04_pavilion)")
		return
	var sk := _sk()
	var side := _side(PAVILION)
	var b: Array = side["socket_pos"]["SOCK_BRIDGE_1"]
	var at: Array = sk["pavilion"]["at"]
	assert_almost_eq(float(at[0]) + float(b[0]), float(sk["bridge"]["x"]), 0.05, "the bridge leaves from its floor's middle")
	assert_almost_eq(float(at[1]) + float(b[1]), float(sk["bridge"]["south"][0]), 0.05, "its floor's north edge at the deck's south end")
	for k in ["SOCK_TABLE_1", "SOCK_STELE_1", "SOCK_FLAME_1", "SOCK_FLAME_4"]:
		assert_true((side["socket_pos"] as Dictionary).has(k), "the pavilion has its %s" % k)


func test_the_court_hall_is_carved_and_reached() -> void:  # step 7: up from the passage by the house's door and the stair
	if not ResourceLoader.exists(CASTLE + ".glb"):
		fail_test("the castle not exported")
		return
	var side := _side(CASTLE)
	assert_true((side["socket_pos"] as Dictionary).has("SOCK_ROOM_1"), "the court hall's ROOM socket, where it is streamed in")
	assert_eq((side["leaves"] as Array).size(), 2, "the house's door: two leaves for the game to hang")
	var g: Node3D = (load(CASTLE + ".glb") as PackedScene).instantiate()
	add_child_autofree(g)
	g.position = Vector3(0.0, -700.0, 0.0)
	await wait_physics_frames(2)
	var space := g.get_world_3d().direct_space_state
	var at := func(x: float, y: float, z: float) -> Vector3: return g.global_transform * Vector3(x, z, -y)
	var down := func(x: float, y: float, z0: float) -> float:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at.call(x, y, z0), at.call(x, y, z0 - 4.0)))
		return -1.0 if hit.is_empty() else (g.global_transform.affine_inverse() * (hit["position"] as Vector3)).y
	assert_almost_eq(down.call(-3.0, 2.3, 7.5), 4.7, 0.05, "the court hall's floor")
	assert_almost_eq(down.call(3.0, 4.6, 7.5), 4.7, 0.05, "and by its east windows' side")
	assert_almost_eq(down.call(3.0, -2.0, 4.2), 1.5, 0.05, "the stair hall's floor, on the passage's level")
	assert_between(down.call(5.6, -2.5, 4.6), 2.4, 3.4, "the stair half way up")
	var door := space.intersect_ray(PhysicsRayQueryParameters3D.create(at.call(0.5, -1.6, 2.5), at.call(3.0, -1.6, 2.5)))
	assert_true(door.is_empty(), "the house's door open from the passage into the stair hall")
	var over := space.intersect_ray(PhysicsRayQueryParameters3D.create(at.call(-5.0, 0.0, 6.0), at.call(5.0, 0.0, 6.0)))
	assert_true(over.is_empty() or (g.global_transform.affine_inverse() * (over["position"] as Vector3)).x > -4.6, "the hall open from side to side but for its pillars")
	assert_eq(Interiors.ROOMS.get("SAM-01", []), ["sam01_court_hall"], "the hall streamed in at the castle (world/interiors.gd)")
	assert_true(ResourceLoader.exists(Interiors.scene_path("sam01_court_hall")), "its scene (tools/build/make_rooms.gd)")
