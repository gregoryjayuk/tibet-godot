extends GutTest
## The headman's house SHL-19, every floor (M2 sprint 7, step 1; plan chapter 04, 4.1): the kit's hero house
## (tibet-blender kit/headman.py) with its rooms carved floor by floor, a ROOM socket for each in the order
## world/interiors.gd streams their furnishings in, the two notched logs inside (up from the stable through the kitchen's
## trapdoor, up from the second floor's hall through the hatch), its doors' leaves and sills. The walk through every floor
## is `tools/player/s15.sh route headman`.

const SIDE := "res://assets/generated/kit/types/headman_house_v1.json"


func _side() -> Dictionary:
	if not FileAccess.file_exists(SIDE):
		return {}
	return JSON.parse_string(FileAccess.get_file_as_string(SIDE))


func test_every_floor_carved() -> void:
	var s := _side()
	if s.is_empty():
		pending("no headman_house sidecar: export it from ../tibet-blender")
		return
	var socks: Dictionary = s["socket_pos"]
	var rooms := 0
	for k in socks:
		if String(k).begins_with("SOCK_ROOM_"):
			rooms += 1
	assert_eq(rooms, 11, "the stable, the two halls, kitchen, reception, grain room, shrine, guest room, two bedrooms, the roof room")
	# each floor's rooms at its level: the stable on the ground, the first floor's over the outside stair's landing, the
	# second's, the roof room on the roof
	var levels := {1: 0.06, 2: 2.45, 3: 2.45, 4: 2.45, 5: 2.45, 6: 5.15, 7: 5.15, 8: 5.15, 9: 5.15, 10: 5.15, 11: 8.21}
	for k in levels:
		assert_almost_eq(float(socks["SOCK_ROOM_%d" % k][2]), float(levels[k]), 0.02, "room %d's floor" % k)
	assert_gt((s["rooms"] as Array).size(), 13, "the rooms carved, and the well, the trapdoor, the smoke-hole and the hatch")


func test_the_logs_inside() -> void:
	var s := _side()
	if s.is_empty():
		pending("no headman_house sidecar")
		return
	var socks: Dictionary = s["socket_pos"]
	for k in [1, 2]:
		assert_true(socks.has("SOCK_LOGFOOT_%d" % k) and socks.has("SOCK_LOGTOP_%d" % k), "log %d's foot and top" % k)
	var f1: Array = socks["SOCK_LOGFOOT_1"]
	var t1: Array = socks["SOCK_LOGTOP_1"]
	assert_almost_eq(float(t1[2]) - float(f1[2]), 2.39, 0.05, "up from the stable's floor to the kitchen's")
	assert_lt(float(t1[0]), float(f1[0]), "leaning west: the climber steps off into the kitchen beside the trap")
	var f2: Array = socks["SOCK_LOGFOOT_2"]
	var t2: Array = socks["SOCK_LOGTOP_2"]
	assert_almost_eq(float(t2[2]), 8.15, 0.02, "the hatch's log tops out at the roof's deck")
	assert_almost_eq(float(t2[2]) - float(f2[2]), 3.0, 0.05, "from the second floor's hall")
	var lean := rad_to_deg(atan2(float(t2[2]) - float(f2[2]), Vector2(float(t2[0]) - float(f2[0]), float(t2[1]) - float(f2[1])).length()))
	assert_almost_eq(lean, 67.0, 0.5, "at the town's logs' lean")


func test_doors_and_sills() -> void:
	var s := _side()
	if s.is_empty():
		pending("no headman_house sidecar")
		return
	assert_eq((s["leaves"] as Array).size(), 12, "the family's door and the stable's (two leaves each), the roof room's (two), six rooms'")
	var sills: Array = s["sills"]
	assert_eq(sills.size(), 5, "the family's door, the stable's, the reception's, the shrine's, the guest room's")
	var stable := false
	for q in sills:
		if absf(float(q[2])) < 0.01 and absf(float(q[5]) - 0.3) < 0.01:
			stable = true
	assert_true(stable, "the stable's door from the yard over its 30 cm sill (chapter 04)")
	var socks: Dictionary = s["socket_pos"]
	assert_almost_eq(float(socks["SOCK_DOOR_1"][2]), 2.45, 0.05, "the family's door at the top of the outside stair")
	assert_true(socks.has("SOCK_GATE_1") and socks.has("SOCK_DARCHEN_1"), "the yard's gate and darchen, as the slice has had them")
	assert_true(socks.has("SOCK_KITCHEN_1") and float(socks["SOCK_KITCHEN_1"][1]) > 4.0, "its smoke out of the kitchen's window on the north")
