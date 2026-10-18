extends GutTest
## Juniper on Dechen-tsang's roof burner at dusk (M1 sprint 7, step 6; CX-050, CX-070): standing by the burner between
## 16:58 and 17:45, E lays a sprig on it; not before or after, not from across the roof, not twice in a breath.

const RoofSang := preload("res://world/roof_sang.gd")

var keep := {}
var rs: Node
var guest: Node3D
var burner: Node3D


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen}
	WorldClock.frozen = true
	var gs := GDScript.new()
	gs.source_code = "extends Node3D\nvar rest := 0\n"
	gs.reload()
	guest = Node3D.new()
	guest.set_script(gs)
	guest.add_to_group("player")
	add_child_autofree(guest)
	var house := Node3D.new()
	add_child_autofree(house)
	burner = Node3D.new()
	burner.name = "SOCK_SANG_1"
	house.add_child(burner)
	burner.position = Vector3(0.0, 10.0, 0.0)
	rs = RoofSang.new()
	add_child_autofree(rs)
	rs.setup(house)


func after_each() -> void:
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]
	for s in get_tree().get_nodes_in_group("subtitles"):
		s.free()


func test_juniper_at_dusk_by_the_burner() -> void:
	guest.position = Vector3(1.2, 10.0, 0.0)
	WorldClock.minute = 7.0 * 1440.0 + 16.0 * 60.0
	assert_false(rs.lay(), "16:00: not yet")
	WorldClock.minute = 7.0 * 1440.0 + 17.1 * 60.0
	assert_true(rs.lay(), "17:06, by the burner: a sprig laid")
	assert_false(rs.lay(), "and not again at once")
	assert_eq(int(rs.laid), 1, "one laid")
	guest.position = Vector3(6.0, 10.0, 0.0)
	rs.set("_cool", 0.0)
	assert_false(rs.lay(), "not from across the roof")
	guest.position = Vector3(1.2, 4.0, 0.0)
	assert_false(rs.lay(), "nor from the yard below")
	WorldClock.minute = 7.0 * 1440.0 + 18.0 * 60.0
	guest.position = Vector3(1.2, 10.0, 0.0)
	assert_false(rs.lay(), "18:00: the sang is over")
