extends GutTest
## The halls' yak-hair curtains (M3 sprint 6, step 1; plan chapter 04, 3.1; world/curtains.gd): the kit's halls give
## their curtains to the game (their sidecars' `curtains`, tibet-blender kit/elements.py hang_curtain), each a kit type of
## its own size that exists; the push bends the cloth ahead of whoever comes through and lets it go once they are past.

const Curtains := preload("res://world/curtains.gd")
const SIDE := "res://assets/generated/kit/types/%s.json"
const KIT := "res://assets/generated/kit/types/%s_v1.glb"
## the carved halls with a curtain in a doorway: [kit type, how many]
const HALLS := [["mon01_tsokchen_in_v1", 1], ["mon04_maitreya_chapel_in_v1", 1], ["mon05_protector_chapel_in_v1", 2],
		["mon14_library_in_v1", 1], ["mon09_labrang_in_v1", 1]]


func test_the_halls_hang_theirs() -> void:
	for h in HALLS:
		if not FileAccess.file_exists(SIDE % h[0]):
			pending("no %s sidecar: the kit's export" % h[0])
			continue
		var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SIDE % h[0]))
		var cs: Array = side.get("curtains", [])
		assert_eq(cs.size(), int(h[1]), "%s's curtains" % h[0])
		for c in cs:
			assert_between(float(c[4]), 1.5, 2.8, "%s's curtain's width" % h[0])
			assert_between(float(c[5]), 2.5, 3.8, "and its height")
			assert_true(ResourceLoader.exists(KIT % String(c[6])), "its kit type %s" % c[6])


func test_the_push() -> void:
	assert_eq(Curtains.push_for(-2.0), 0.0, "far before it: nothing")
	assert_gt(Curtains.push_for(-0.5), 0.2, "half a metre before it the cloth already bends ahead")
	assert_gt(Curtains.push_for(0.2), Curtains.push_for(-0.2), "more as the walker comes through")
	assert_lte(Curtains.push_for(0.45), Curtains.MOST, "never more than its most")
	assert_eq(Curtains.push_for(Curtains.THROUGH + 0.01), 0.0, "let go once they are through")


## A curtain of the kit's sizes hung here, 2.6 m high, its way in -z, and the Curtains node over it.
func _hung() -> Array:
	var c := Node3D.new()
	c.set_meta("w", 1.76)
	c.set_meta("h", 2.6)
	c.add_to_group("curtains")
	var m := MeshInstance3D.new()
	m.mesh = BoxMesh.new()
	c.add_child(m)
	add_child_autofree(c)
	c.global_position = Vector3(0.0, 2.6, 0.0)  # its top's middle; its foot on the ground
	var cs := Curtains.new()
	add_child_autofree(cs)
	assert_eq(cs.build(self), 1, "the curtain taken")
	return [cs, c]


func test_a_walker_parts_it_and_it_falls_back() -> void:
	var keep := [TownSim.count, TownSim.pos, TownSim.state]
	var got := _hung()
	var cs: Node = got[0]
	TownSim.count = 1
	TownSim.pos = PackedVector3Array([Vector3(0.0, 0.0, 2.0)])  # 2 m outside, coming in along -z
	TownSim.state = PackedByteArray([0])
	var most := 0.0
	for k in 40:
		TownSim.pos[0] = Vector3(0.0, 0.0, 2.0 - 0.1 * k)
		cs.call("_process", 1.0 / 30.0)
		most = maxf(most, float(cs.get("curtains")[0]["bend"]))
	assert_gt(most, 0.8, "parted ahead of the walker as it came through")
	assert_eq(int(cs.get("thumps")), 1, "and fell back behind it once, its thump heard")
	for k in 90:  # gone on: it settles
		TownSim.pos[0] = Vector3(0.0, 0.0, -2.0 - 0.1 * k)
		cs.call("_process", 1.0 / 30.0)
	assert_almost_eq(float(cs.get("curtains")[0]["bend"]), 0.0, 0.01, "still again")
	TownSim.count = keep[0]
	TownSim.pos = keep[1]
	TownSim.state = keep[2]


func test_the_player_parts_it_from_inside_too() -> void:
	var keep := [TownSim.count]
	TownSim.count = 0
	var got := _hung()
	var cs: Node = got[0]
	var p := Node3D.new()
	p.add_to_group("player")
	add_child_autofree(p)
	var most := 0.0
	for k in 40:
		p.global_position = Vector3(0.3, 0.0, -2.0 + 0.1 * k)  # from inside out, along +z
		cs.call("_process", 1.0 / 30.0)
		most = maxf(most, float(cs.get("curtains")[0]["bend"]))
	assert_gt(most, 0.8, "parted going out as well as in")
	assert_eq(float(cs.get("curtains")[0]["side"]), -1.0, "towards the way out")
	TownSim.count = keep[0]
