extends GutTest
## The dawn and dusk horns' players on the Tsokchen's roof terrace (M3 sprint 6, step 5; plan chapter 08, V-05a;
## world/horns.gd): two HORN sockets on the hall's rear block by its west parapet, the players out at their hours, each
## horn from the mouth down onto the parapet's top ahead of him.

const Horns := preload("res://world/horns.gd")
const SIDE := "res://assets/generated/kit/types/mon01_tsokchen_in_v1.json"


func test_their_hours() -> void:
	assert_true(Horns.out_at(330.0), "05:30: the dawn call (SND-103)")
	assert_true(Horns.out_at(1035.0), "17:15: the dusk call (SND-104)")
	assert_false(Horns.out_at(300.0), "05:00: the conch alone")
	assert_false(Horns.out_at(720.0), "noon: the roof empty")


func test_the_horn_rests_on_the_parapet() -> void:
	var line := Horns.horn_line(Transform3D.IDENTITY)
	var mouth: Vector3 = line[0]
	var rest: Vector3 = line[1]
	assert_almost_eq(mouth.distance_to(rest), 3.0, 0.1, "a 3 m horn, its bell on the parapet")
	assert_lt(rest.y, mouth.y - 0.7, "its bell lower than his mouth, on the parapet's top")
	assert_lt(rest.z, mouth.z, "and ahead of him")


func test_the_two_places() -> void:
	if not FileAccess.file_exists(SIDE):
		pending("no mon01_tsokchen_in sidecar")
		return
	var socks: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(SIDE)) as Dictionary)["socket_pos"]
	assert_true(socks.has("SOCK_HORN_1") and socks.has("SOCK_HORN_2"), "two players' places on the roof terrace")
	if socks.has("SOCK_HORN_1") and socks.has("SOCK_ROOF_1"):
		assert_gt(float(socks["SOCK_HORN_1"][2]), float(socks["SOCK_ROOF_1"][2]) + 5.0, "on the rear block, over the main roof")


func test_lifted_for_the_call_and_lowered() -> void:
	assert_eq(Horns.lift_at(328.0), 0.0, "05:28: the mouthpiece at his waist")
	var mid := Horns.lift_at(329.85)
	assert_true(mid > 0.0 and mid < 1.0, "05:29:51: lifting")
	assert_eq(Horns.lift_at(331.0), 1.0, "05:31: blowing")
	assert_eq(Horns.lift_at(336.0), 0.0, "05:36: lowered again")
	assert_eq(Horns.lift_at(1036.0), 1.0, "17:16: the dusk call")


func test_between_the_calls_the_horn_still_lies_across_the_parapet() -> void:
	var line := Horns.horn_line(Transform3D.IDENTITY, 0.0)
	var a: Vector3 = line[0]
	var b: Vector3 = line[1]
	assert_almost_eq(a.distance_to(b), 3.0, 0.01, "the same 3 m horn")
	var way := (b - a).normalized()
	var to := Horns.SUPPORT - a
	assert_lt((to - way * to.dot(way)).length(), 0.01, "through the parapet's top")
	assert_gt(to.length(), 2.5, "its bell beyond it, towards the town")


func test_v05a_is_chapter_08s_record() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moments.json"))
	var v := {}
	for m in data["moments"]:
		if String(m.get("id", "")) == "V-05a":
			v = m
	assert_false(v.is_empty(), "V-05a is in data/moments.json")
	var Moments := preload("res://world/moments.gd")
	assert_true(Moments.window_open(v, 330.0), "05:30: the dawn call, on the roof terrace")
	assert_false(Moments.window_open(v, 450.0), "07:30: over")
	assert_eq(int((v["stations"][0]["facing"] as Array)[0]), 240, "facing 240 degrees over the town")
