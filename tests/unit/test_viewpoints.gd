extends GutTest
## The slice's viewpoints (world/viewpoints.gd; IMP-021 (5), IMP-024): the frame set back from the sitter along its
## bearing, looking at its bearing and pitch; sitting at a seat drifts the camera out after a breath, standing brings it
## back; nowhere else does.

const Viewpoints := preload("res://world/viewpoints.gd")
const PlayerScript := preload("res://player/player.gd")
const Town := preload("res://world/town.gd")
const V := {"id": "T-1", "name": "A test", "seat": [0.0, 0.0, 0.0], "reach": 4.0, "bearing": 180.0, "pitch": -10.0, "fov": 50.0, "back": 3.0, "up": 2.0, "right": 1.0}


func test_the_frame() -> void:
	var f: Transform3D = Viewpoints.frame(V, Vector3(10.0, 5.0, 20.0))
	assert_almost_eq(f.origin, Vector3(10.0 - 1.0, 7.0, 20.0 - 3.0), Vector3.ONE * 0.001, "back north of a sitter looking south, up and to their right (west)")
	var look := -f.basis.z
	assert_gt(look.z, 0.9, "looking south")
	assert_almost_eq(look.y, sin(deg_to_rad(-10.0)), 0.001, "pitched down")


func test_sitting_drifts_out_and_back() -> void:
	var p := PlayerScript.new()
	p.third_person = true
	p.scripted = true
	add_child_autofree(p)
	var vp := Viewpoints.new()
	add_child_autofree(vp)
	vp.views = [V]
	p.global_position = Town.to_godot(1.0, 1.0, 2662.0)  # within reach of its seat
	for i in 30:  # standing: nothing
		vp._process(0.1)
	assert_eq(p.view_k, 0.0, "standing, no drift")
	p.rest = 2  # seated
	for i in 20:
		vp._process(0.1)
	assert_eq(p.view_k, 0.0, "a breath first")
	for i in 50:
		vp._process(0.1)
	assert_almost_eq(p.view_k, 1.0, 0.001, "out to its frame")
	p.rest = 0
	for i in 15:
		vp._process(0.1)
	assert_eq(p.view_k, 0.0, "stood up: back")
	p.global_position = Town.to_godot(30.0, 30.0, 2662.0)  # far from any seat
	p.rest = 2
	for i in 80:
		vp._process(0.1)
	assert_eq(p.view_k, 0.0, "sat elsewhere: nothing")
