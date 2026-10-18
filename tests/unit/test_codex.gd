extends GutTest
## The codex (M1 sprint 7, step 7; chapter 11, 14.3; chapter 07, 9): chapter 07's 146 entries loaded with their truth;
## an entry is found once; the truth is said in words, a pair as the kind and our placing; a look finds only what the
## camera is turned to, within reach; the slice's list has each of chapter 12's thirteen.

const Sites := preload("res://world/codex_sites.gd")


func after_each() -> void:
	Codex.reset()
	for s in get_tree().get_nodes_in_group("subtitles"):
		s.free()


func test_the_entries() -> void:
	assert_eq(Codex.entries.size(), 146, "chapter 07's 146 nods (CX-146, the chapel's White Tara, since M2 sprint 8)")
	for id in Codex.SLICE:
		assert_true(Codex.entries.has(id), "%s in the codex" % id)
	assert_eq(Codex.SLICE.size(), 13, "chapter 12's thirteen for M1")


func test_found_once_and_its_truth_in_words() -> void:
	assert_true(Codex.find("CX-050"), "found")
	assert_false(Codex.find("CX-050"), "only once")
	assert_eq(Codex.order, ["CX-050"], "in the order found")
	assert_eq(Codex.truth_words("A"), "attested in a period source", "A in words")
	assert_eq(Codex.truth_words("I"), "the game's invention", "I in words")
	assert_eq(Codex.truth_words("A/I"), "attested in a period source; placed here by the game", "a pair in words")
	assert_false(Codex.find("CX-999"), "no such entry")


func test_a_look_finds_what_the_camera_is_turned_to() -> void:
	var cam := Transform3D(Basis(), Vector3.ZERO)  # looking along -Z
	assert_true(Sites.looking(cam, Vector3(0.0, 0.0, -3.0), 5.0), "straight ahead, 3 m")
	assert_true(Sites.looking(cam, Vector3(0.3, 0.0, -3.0), 5.0), "a little aside")
	assert_false(Sites.looking(cam, Vector3(2.0, 0.0, -3.0), 5.0), "too far aside")
	assert_false(Sites.looking(cam, Vector3(0.0, 0.0, 3.0), 5.0), "behind")
	assert_false(Sites.looking(cam, Vector3(0.0, 0.0, -8.0), 5.0), "out of reach")
