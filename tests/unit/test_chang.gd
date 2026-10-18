extends GutTest
## The chang house SHL-24 (M2 sprint 2; plan chapter 04, 4.5; chapter 14, 4.1): the gazetteer's building to enter is
## carved as its B2's seed says (tools/town/graph.py ENTER_TOWN keeps the same seed for its stair's foot), its first
## floor the drinking room (../tibet-blender kit/rooms.py chang_room): benches round three walls with their seats, the
## guest's bowl on a low table with the hostess's place before it, the stove's fire; the room's scene lit LR-04, the
## chang poured from the ladle with the story's own line, the dranyen heard from 19:00 while the muleteer who plays it is
## on his bench (SND-229); the talks overheard (data/talks/) where and when their speakers are in the room, every line
## said by the phrasebook's id or the story's own listed for Greg's check; and the room's people sit cross-legged.

const Town := preload("res://world/town.gd")
const Interiors := preload("res://world/interiors.gd")
const Barks := preload("res://world/barks.gd")
const VARIANTS := 3
const ROOM := "chang_room_b2_in_v2"


static func godot(p: Array) -> Vector3:
	return Vector3(float(p[0]), float(p[2]), -float(p[1]))  # the kit's frame (x, y, z up) -> Godot's (x, z, -y)


func _days() -> Dictionary:
	var days: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/generic_days.json")) as Dictionary)["people"]
	var named: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/named_days.json"))
	for k in named.get("people", {}):
		days[k] = named["people"][k]
	return days


func test_the_chang_house_is_shl_24_to_enter() -> void:
	var town: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json"))
	var found := false
	for b in town.get("buildings", []):
		if String(b["id"]) == "SHL-24":
			found = true
			assert_eq(Town.kit_file(b), "town_house_b2_in_v2", "SHL-24: its first floor carved, the seed graph.py's ENTER_TOWN takes (\"chang\", 2)")
	assert_true(found, "SHL-24 in the gazetteer")
	assert_eq(Interiors.ROOMS.get("SHL-24"), [ROOM], "and its room the drinking room of the same variant")
	var graph := FileAccess.get_file_as_string("res://tools/town/graph.py")
	assert_true(graph.contains("ENTER_TOWN = {\"SHL-24\": (\"chang\", 2)}"), "the graph's stair foot at the same house")


func test_the_drinking_room_has_its_benches_table_and_stove() -> void:
	for v in range(1, VARIANTS + 1):
		var t := "chang_room_b2_in_v%d" % v
		var path := "res://assets/generated/kit/types/%s.glb" % t
		if not ResourceLoader.exists(path):
			fail_test("%s not built" % t)
			continue
		var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path.get_basename() + ".json"))
		var r: Array = side["rooms"][0]
		var room := AABB(Vector3(float(r[0]), -0.25, -float(r[3])), Vector3(float(r[1]) - float(r[0]), float(r[5]) + 0.25, float(r[3]) - float(r[2])))
		var s: Dictionary = side["socket_pos"]
		var seats := s.keys().filter(func(k: String) -> bool: return k.begins_with("SOCK_SEAT_"))
		assert_gte(seats.size(), 18, "%s: benches round three walls, a seat to every 0.8 m" % t)
		for k in seats:
			var p := godot(s[k])
			assert_almost_eq(p.y, 0.36, 0.02, "%s: %s on a bench" % [t, k])
			assert_true(room.grow(0.01).has_point(p), "%s: %s in the room" % [t, k])
		for want in ["SOCK_BOWL_1", "SOCK_HOST_1", "SOCK_FIRE_1", "SOCK_SEAT_7"]:
			assert_true(s.has(want), "%s: %s" % [t, want])
		if not (s.has("SOCK_BOWL_1") and s.has("SOCK_HOST_1") and s.has("SOCK_FIRE_1")):
			continue
		var bowl := godot(s["SOCK_BOWL_1"])
		var host := godot(s["SOCK_HOST_1"])
		assert_almost_eq(bowl.y, 0.3, 0.02, "%s: the guest's bowl on a low table" % t)
		assert_almost_eq(host.y, 0.0, 0.01, "%s: the hostess on the floor" % t)
		assert_between(Vector2(host.x - bowl.x, host.z - bowl.z).length(), 0.35, 0.8, "%s: the hostess within a ladle's reach of the bowl" % t)
		var near := 9.0
		var guest := ""
		for k in seats:
			var p := godot(s[k])
			var d := Vector2(p.x - bowl.x, p.z - bowl.z).length()
			if d < near:
				near = d
				guest = k
		assert_lt(near, 0.75, "%s: a seat at the guest's bowl" % t)
		if guest != "":  # the back bench's (facing the room's front, the kit's -y): the hostess across the table from the guest
			assert_almost_eq(float(side["socket_yaw"][guest]), -90.0, 0.5, "%s: the guest's seat (%s) on the back bench" % [t, guest])
			assert_gt(godot(s[guest]).distance_to(host), 0.6, "%s: the hostess across the table" % t)
		assert_true(room.has_point(godot(s["SOCK_FIRE_1"])), "%s: the stove in the room" % t)
		var k: Node3D = (load(path) as PackedScene).instantiate()
		add_child_autofree(k)
		for m in k.find_children("*_L0", "MeshInstance3D", true, false):
			var box := (m as MeshInstance3D).transform * (m as MeshInstance3D).get_aabb()
			assert_true(room.grow(0.05).encloses(box), "%s: %s inside the room (%s in %s)" % [t, m.name, box, room])


func test_the_room_is_lit_poured_and_played() -> void:
	var lines: Dictionary = {}
	for l in (JSON.parse_string(FileAccess.get_file_as_string("res://data/story_lines.json")) as Dictionary)["lines"]:
		lines[String(l["id"])] = l
	var sound: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/sound.json")) as Dictionary)["sounds"]
	for v in range(1, VARIANTS + 1):
		var t := "chang_room_b2_in_v%d" % v
		var scene: Node3D = (load("res://interiors/houses/%s.tscn" % t) as PackedScene).instantiate()
		var r := scene.get_node("Room")
		assert_eq(String(r.get("recipe")), "LR-04", "%s: lit as a kitchen, by its stove" % t)
		var fires := 0
		var lights := 0
		for c in scene.get_children():
			if c is OmniLight3D:
				lights += 1
				if String(c.get_meta("kind", "")) == "fire":
					fires += 1
		assert_lte(lights, 3, "%s: at most three lights" % t)
		assert_eq(fires, 1, "%s: the stove's fire" % t)
		var tea := scene.find_child("Tea", true, false) as Node3D
		assert_not_null(tea, "%s: the guest's bowl" % t)
		if tea != null:
			assert_eq(String(tea.get_meta("liquid", "")), "chang", "%s: chang, not tea" % t)
			assert_eq(String(tea.get_meta("vessel", "")), "ladle", "%s: from the pan's ladle" % t)
			assert_true(lines.has(String(tea.get_meta("pour_line", ""))), "%s: Ama Yudrön's word as she pours, a story line" % t)
			assert_true(tea.has_meta("host"), "%s: where she stands to pour" % t)
		assert_true(r.has_meta("music"), "%s: the dranyen" % t)
		if r.has_meta("music"):
			var mu: Array = r.get_meta("music")
			assert_eq(String(mu[0]), "SND-229", "%s: SND-229" % t)
			assert_eq(float(mu[1]), 1140.0, "%s: from 19:00" % t)
			assert_lte(float(mu[2]), 1290.0, "%s: until its player leaves at 21:30" % t)
		scene.free()
	assert_true(sound.has("SND-229"), "the dranyen in the sound data")
	if sound.has("SND-229"):
		assert_true(bool(sound["SND-229"].get("loop", false)), "a loop")
		for f in sound["SND-229"]["files"]:
			assert_true(FileAccess.file_exists("res://audio/" + String(f)), "%s built (tools/audio/synth.py, process.py)" % String(f))
	var days := _days()
	var mule: Array = []
	for stop in days.get("muleteer", {}).get("day", []):
		if stop.size() > 5 and stop[5] is String and String(stop[5]) == "room:%s:seat:7" % ROOM:
			mule = stop
	assert_false(mule.is_empty(), "a muleteer on seat 7, who plays it")
	if not mule.is_empty():
		assert_lte(float(mule[1]), 1140.0, "on his bench by 19:00")
		assert_gte(float(mule[2]), 1285.0, "and still there when it stops")


func test_the_dranyen_is_heard_in_its_hours() -> void:
	var scene: Node3D = (load("res://interiors/houses/%s.tscn" % ROOM) as PackedScene).instantiate()
	add_child_autofree(scene)
	scene.position = Vector3(0.0, -200.0, 0.0)
	var r := scene.get_node("Room")
	var was := WorldClock.minute
	var rate := WorldClock.rate
	WorldClock.rate = 0.0
	WorldClock.minute = 18.5 * 60.0
	await wait_process_frames(20)
	assert_false(bool(r.get("_music_on")), "silent at 18:30")
	WorldClock.minute = 19.25 * 60.0
	await wait_process_frames(20)
	assert_true(bool(r.get("_music_on")), "played at 19:15")
	WorldClock.minute = 21.6 * 60.0
	await wait_process_frames(20)
	assert_false(bool(r.get("_music_on")), "stopped when its player has gone")
	WorldClock.minute = was
	WorldClock.rate = rate


func test_the_talks_play_where_and_when_their_speakers_are() -> void:
	var days := _days()
	var check := FileAccess.get_file_as_string("res://docs/culture/conversation-lines-check.md")
	var rooms: Array = []
	for k in Interiors.ROOMS:
		rooms.append_array(Interiors.ROOMS[k])
	var dir := DirAccess.open("res://data/talks")
	assert_not_null(dir, "data/talks")
	if dir == null:
		return
	var n := 0
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		n += 1
		var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/talks/" + f))
		var id := String(t.get("id", f))
		var place := String(t.get("place", ""))
		assert_true(rooms.has(place), "%s: at a room to enter (%s)" % [id, place])
		assert_lt(float(t["from"]), float(t["to"]), "%s: its hours" % id)
		for who in t.get("needs", []):
			var best := 0.0
			for stop in days.get(String(who), {}).get("day", []):
				if stop.size() > 5 and stop[5] is String and String(stop[5]).begins_with("room:%s:" % place):
					best = maxf(best, minf(float(stop[2]), float(t["to"])) - maxf(float(stop[1]), float(t["from"])))
			assert_gte(best, 15.0, "%s: %s in the room for a quarter of an hour of its time" % [id, who])
		var ls: Array = t.get("lines", [])
		assert_gt(ls.size(), 0, "%s: its lines" % id)
		for l in ls:
			if l.has("narrate"):
				continue
			assert_true(String(l.get("who", "")) != "", "%s: who says it" % id)
			if l.has("say"):
				assert_ne(String(Barks.line(String(l["say"])).get("script", "")), "", "%s: %s in the phrasebook" % [id, l["say"]])
			else:
				assert_true(l.has("line") and l.has("en"), "%s: the story's own line, its English" % id)
				assert_true(check.contains("| %s |" % String(l.get("line", "?"))), "%s: %s listed for Greg's check" % [id, l.get("line", "?")])
		assert_true(t.has("once"), "%s: heard once" % id)
	assert_gte(n, 3, "the order, the soldiers, the bard")


func test_its_people_sit_cross_legged() -> void:
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/people/named_clips.json"))
	var days := _days()
	for k in ["ama_yudron", "yudron_daughter", "jiang_deshun", "post_soldier", "post_soldier_b", "drakpa_bard", "muleteer", "muleteer_b"]:
		assert_true(days.has(k), "%s: a day" % k)
		var body := String(days.get(k, {}).get("body", k))
		assert_true(info["bodies"].has(body), "%s: a body (%s)" % [k, body])
		if info["bodies"].has(body):
			assert_true((info["bodies"][body] as Dictionary).has("Sitting_Cross"), "%s: the cross-legged clip" % k)
