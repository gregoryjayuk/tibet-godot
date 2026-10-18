extends GutTest
## The Tsokchen's assemblies (M3 sprint 5, step 5; world/assembly.gd; plan chapter 04, 3.1): the nave's places from its
## kit (tibet-blender kit/tsokchen_rooms.py's SEAT sockets), each row's place facing across the aisle to its book-stand,
## the three thrones after them with the tulku's last at 1.2 m, and the hours they are filled.

const Assembly := preload("res://world/assembly.gd")
const SIDE := "res://assets/generated/kit/types/tsokchen_nave_v1.json"


func test_the_hours() -> void:
	assert_eq(Assembly.session_at(345.0), 0, "05:45: the dawn assembly")
	assert_eq(Assembly.session_at(670.0), 1, "11:10: the general tea")
	assert_eq(Assembly.session_at(1050.0), 2, "17:30: the evening recitation")
	assert_eq(Assembly.session_at(180.0), -1, "03:00: nobody")
	assert_eq(Assembly.session_at(1200.0), -1, "20:00: the doors shut")


func test_the_places() -> void:
	if not FileAccess.file_exists(SIDE):
		pending("no tsokchen_nave sidecar: the kit's export")
		return
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SIDE))
	var pos: Dictionary = side["socket_pos"]
	var yaws: Dictionary = side["socket_yaw"]
	var n := 0
	for k in pos:
		if String(k).begins_with("SOCK_SEAT_"):
			n += 1
	assert_between(n, 270, 292, "the sixteen rows' places and the three thrones (chapter 04: 288 in the rows)")
	var last: Array = pos["SOCK_SEAT_%d" % n]
	assert_almost_eq(float(last[2]), 1.2, 0.01, "the tulku's throne last, 1.2 m up")
	var wrong := 0
	for i in range(1, n - 2):
		var p: Array = pos["SOCK_SEAT_%d" % i]
		var facing_x := cos(deg_to_rad(float(yaws["SOCK_SEAT_%d" % i])))
		if float(p[0]) * facing_x >= 0.0:  # (a row's place faces across the aisle, towards x = 0)
			wrong += 1
	assert_eq(wrong, 0, "every row's place faces across the aisle")


func test_the_disciplinarians_round() -> void:
	var a = Assembly.new()
	a.set("_g_path", [Vector3(1.6, 0, 0), Vector3(0, 0, -0.5), Vector3(0, 0, -20.5), Vector3(0, 0, -0.5), Vector3(1.6, 0, 0)])
	var start := 330.0
	var w: Array = a.gekoe_at(start, start)
	assert_true(bool(w[2]), "a session begins with his walk")
	w = a.gekoe_at(start + 3.0, start)  # 13.5 m on: up the aisle
	assert_true(bool(w[2]) and absf((w[0] as Vector3).x) < 0.01 and (w[0] as Vector3).z < -5.0, "up the aisle between the rows")
	w = a.gekoe_at(start + 11.0, start)  # the round's 44 m walked by about 9.8 minutes
	assert_false(bool(w[2]), "then at his post by the door, arms folded")
	assert_almost_eq((w[0] as Vector3).x, 1.6, 0.01, "by the door's right")
	w = a.gekoe_at(start + Assembly.GEKOE_ROUND + 0.1, start)
	assert_true(bool(w[2]), "and round again")
	a.free()
