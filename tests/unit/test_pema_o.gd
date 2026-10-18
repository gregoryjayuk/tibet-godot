extends GutTest
## Pema Ö Lhakhang and the Conch terrace (M2 sprint 5, step 4; ../tibet-blender kit/confluence.py; plan chapter 03, 9;
## chapter 02, SHL-11 to SHL-13): the temple facing the confluence with its hall, its 36 kora wheels and its nine lamps,
## the stair from its forecourt down to the terrace on the terrace's level and the ground's bed for it, the terrace by
## the pool with its burner and V-02's place; the wheels turned under a hand and slowing (world/kora_wheels.gd); the lamps
## kept burning (world/lamps.gd).

const Town := preload("res://world/town.gd")
const KoraWheels := preload("res://world/kora_wheels.gd")
const Lamps := preload("res://world/lamps.gd")
const TEMPLE := "res://assets/generated/kit/types/sh11_pema_o_v1"
const TERRACE := "res://assets/generated/kit/types/sh12_conch_terrace_v1"


func _side(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path + ".json"))


func _count(pos: Dictionary, kind: String) -> int:
	return pos.keys().filter(func(k: String) -> bool: return k.begins_with("SOCK_%s_" % kind)).size()


func test_placed_facing_the_confluence() -> void:
	var nm: Array = Town.NAMED["SHL-11"]
	assert_eq(String(nm[0]), "sh11_pema_o_v1", "the temple's kit file")
	assert_almost_eq(float(nm[1]), 2670.0, 0.01, "its floor at chapter 02's 2,670 m")
	assert_almost_eq(float(nm[3]), 140.0, 0.01, "facing 140 degrees")
	var to_c := rad_to_deg(atan2(210.0 - 165.0, -95.0 + 55.0))  # the bearing from its middle to the confluence C
	assert_lt(absf(to_c - float(nm[3])), 10.0, "towards the confluence (%.0f degrees)" % to_c)
	var town: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json"))
	for b in town["buildings"]:
		if String(b["id"]) == "SHL-11":
			assert_almost_eq(float(b.get("rot_deg", 180.0)), 140.0, 0.01, "the gazetteer's facing (tools/town/gazetteer.py FACINGS), which the pads turn to")
	var tr: Array = Town.NAMED["SHL-12"]
	assert_almost_eq(float(tr[1]), 2664.0, 0.01, "the terrace at 2,664 m")
	assert_almost_eq(float(tr[2][0]), 190.0, 0.01, "the terrace where tools/terrain/pads.py MOVED put it")
	assert_almost_eq(float(tr[2][1]), -83.5, 0.01, "the terrace where tools/terrain/pads.py MOVED put it")


func test_the_temple_has_its_hall_wheels_lamps_and_stair() -> void:
	if not FileAccess.file_exists(TEMPLE + ".json"):
		fail_test("the temple not exported (../tibet-blender export_types.py --types sh11_pema_o)")
		return
	var side := _side(TEMPLE)
	var pos: Dictionary = side["socket_pos"]
	assert_eq(_count(pos, "WHEEL"), 36, "the 36 wheels of its kora corridor (chapter 03, 9)")
	assert_eq(_count(pos, "FLAME"), 9, "nine butter lamps on the altar")
	assert_eq(_count(pos, "KORA"), 4, "the kora's way round its three sides")
	assert_eq(_count(pos, "STAIR"), 2, "its stair's foot and head")
	for k in ["SOCK_DOOR_1", "SOCK_SEAT_1", "SOCK_BOWLS_1", "SOCK_VIEW_1"]:
		assert_true(pos.has(k), "the temple has its %s" % k)
	assert_lt(int(side["triangles"]["L0"]), int(side["budget"]["L0"]) + 1, "within its budget")
	# the stair: its foot 6 m under the floor, 28.1 m out along the front: on the Conch terrace's level, at its north edge
	var foot: Array = pos["SOCK_STAIR_1"]
	var head: Array = pos["SOCK_STAIR_2"]
	assert_almost_eq(float(foot[2]), -6.0, 0.01, "the stair's foot 6 m down")
	assert_almost_eq(float(head[2]), 0.0, 0.01, "its head on the forecourt, at the floor's level")
	var th := deg_to_rad(180.0 - 140.0)  # the kit's frame turned as world/town.gd turns it
	var fy := float(foot[1]) + 0.4  # the foot's riser line
	var fx := 165.0 - fy * sin(th)
	var fyw := -55.0 + fy * cos(th)
	assert_almost_eq(fx, 183.06, 0.1, "the stair lands on the terrace (x)")
	assert_almost_eq(fyw, -76.53, 0.1, "the stair lands on the terrace's north edge (y)")
	assert_almost_eq(2670.0 + float(foot[2]), float(Town.NAMED["SHL-12"][1]), 0.01, "on the terrace's level")


func test_the_terrace_has_its_burner_and_v02() -> void:
	if not FileAccess.file_exists(TERRACE + ".json"):
		fail_test("the terrace not exported (../tibet-blender export_types.py --types sh12_conch_terrace)")
		return
	var pos: Dictionary = _side(TERRACE)["socket_pos"]
	assert_eq(_count(pos, "SANG"), 1, "the sang burner's chimney, its smoke (world/dusk.gd smokes every SANG)")
	assert_true(pos.has("SOCK_OFFER_1"), "where the juniper is laid, before its door")
	assert_true(pos.has("SOCK_STAND_1"), "V-02's place at the lip")
	assert_true(pos.has("SOCK_SEAT_1"), "the bench")
	assert_lt(float(pos["SOCK_STAND_1"][1]), -6.0, "V-02's place at the south lip, over the pool and the slot's head")


func test_a_wheel_turns_under_a_hand_and_slows() -> void:
	var temple := Node3D.new()
	add_child_autofree(temple)
	for k in 3:
		var s := Node3D.new()
		s.name = "SOCK_WHEEL_%d" % (k + 1)
		s.position = Vector3(k * 2.0, 0.62, 0.0)
		temple.add_child(s)
	var kw := KoraWheels.new()
	temple.add_child(kw)
	if kw.setup(temple) == 0:
		fail_test("no kora_wheel_v1.glb (../tibet-blender export_types.py --types kora_wheel)")
		return
	assert_eq(kw.wheels.size(), 3, "a wheel at each socket")
	var hand := Node3D.new()
	hand.add_to_group("kora_walkers")
	add_child_autofree(hand)
	hand.global_position = Vector3(0.3, 0.0, 0.5)
	kw._process(0.1)
	assert_almost_eq(kw.speed[0], KoraWheels.SPIN, 0.001, "the wheel by the hand turns")
	assert_almost_eq(kw.speed[1], 0.0, 0.001, "the one 2 m on does not")
	var yaw := kw.wheels[0].rotation.y
	assert_ne(yaw, 0.0, "turned")
	assert_lt(yaw, 0.0, "clockwise seen from above")
	hand.global_position = Vector3(30.0, 0.0, 0.0)
	kw._process(KoraWheels.SLOW / 2.0)
	assert_almost_eq(kw.speed[0], KoraWheels.SPIN / 2.0, 0.001, "slowing once the hand has gone")
	kw._process(KoraWheels.SLOW)
	assert_eq(kw.speed[0], 0.0, "at rest after SLOW seconds")


func test_the_temple_lamps_are_never_out() -> void:
	for m in [0.0, 420.0, 720.0, 1050.0, 1380.0]:
		assert_eq(Lamps.lit("temple", 4, m), 1.0, "Pema Ö's lamps burn at %d" % int(m))
