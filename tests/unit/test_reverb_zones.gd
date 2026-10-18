extends GutTest
## The outdoors' reverb areas (M1 sprint 8, step 1; world/reverb_zones.gd; plan chapter 10, 9.3, 13.4): along the Sky
## Stair, placed as the town places it, every half metre at head height exactly one area (they never overlap: the
## engine takes the first it finds), the tunnel's stretch RZ-21, the gateway chorten's RZ-22, the rest the lane RZ-20;
## nothing high over the treads; Tsongra RZ-23.

const ReverbZones := preload("res://world/reverb_zones.gd")
const PLAN := "res://assets/generated/kit/types/sky_stair_v1.json"

var stair: Node3D
var zones: Node3D
var plan: Array = []


func before_each() -> void:
	var town: GDScript = load("res://world/town.gd")
	stair = Node3D.new()
	add_child_autofree(stair)
	stair.position = town.to_godot(0.0, 15.0, 2665.0)  # world/town.gd: the gazetteer's line, from (0, 15) at 2,665 m
	stair.rotation.y = -atan2(-20.0, 240.0)
	plan = (JSON.parse_string(FileAccess.get_file_as_string(PLAN)) as Dictionary)["plan"]
	var gate := Node3D.new()
	add_child_autofree(gate)
	gate.position = stair.transform * Vector3(0.0, _tread(10.0), -10.0)  # SHL-17 stands 10 m up the stair
	zones = ReverbZones.new()
	add_child_autofree(zones)
	zones.setup(stair, gate)


func _tread(s: float) -> float:
	for seg in plan:
		if s >= float(seg[1]) and s <= float(seg[2]):
			var f := (s - float(seg[1])) / maxf(float(seg[2]) - float(seg[1]), 0.001)
			return float(seg[3]) + f * (float(seg[4]) - float(seg[3])) if String(seg[0]) == "flight" else float(seg[3])
	return float(plan[plan.size() - 1][4])


## The zones at a point `up` metres over the treads, `s` metres up the stair.
func _at(s: float, up := 1.5) -> Array:
	var q := PhysicsPointQueryParameters3D.new()
	q.position = stair.transform * Vector3(0.0, _tread(s) + up, -s)
	q.collision_mask = 1 << 11
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var out: Array = []
	for h in zones.get_world_3d().direct_space_state.intersect_point(q, 8):
		out.append(String((h["collider"] as Node).name).get_slice("_", 0))
	return out


func test_one_zone_all_the_way_up() -> void:
	await wait_physics_frames(2)
	var length := float(plan[plan.size() - 1][2])
	var bad: Array = []
	var s := 0.27  # off the cuts (6.2, 13.8, 28.2, 62.2 and the flights' ends), where a point is on two faces
	while s < length - 0.3:
		var z := _at(s)
		var want := "RZ-21" if s > 28.2 and s < 62.2 else ("RZ-22" if absf(s - 10.0) < 3.8 else "RZ-20")
		if z.size() != 1 or z[0] != want:
			bad.append("%.1f m: %s" % [s, str(z)])
		s += 0.5
	assert_eq(bad, [], "one zone at every half metre, the right one")
	assert_eq(_at(45.0), ["RZ-21"], "in the tunnel")
	assert_eq(_at(10.0), ["RZ-22"], "under the gateway chorten")
	assert_eq(_at(100.0), ["RZ-20"], "the stone lane")
	assert_eq(_at(45.0, 6.0), [], "nothing high over the treads (the tunnel's houses)")


func test_tsongra() -> void:
	await wait_physics_frames(2)
	var town: GDScript = load("res://world/town.gd")
	var q := PhysicsPointQueryParameters3D.new()
	q.position = town.to_godot(-5.0, 2.0, 2663.5)
	q.collision_mask = 1 << 11
	q.collide_with_areas = true
	var hits := zones.get_world_3d().direct_space_state.intersect_point(q, 8)
	assert_eq(hits.size(), 1, "one zone on Tsongra")
	assert_eq(String((hits[0]["collider"] as Node).name).get_slice("_", 0), "RZ-23", "the square's")
