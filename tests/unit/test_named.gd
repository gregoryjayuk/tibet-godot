extends GutTest
## The named eight (M1 sprint 6, step 3; chapter 05, 4.2 and 9.6): TownSim walks a named walker onto its seat, faces it
## the seat's way and sits it for the span of its stop; the real days (tools/town/graph.py from data/named_days.json)
## put each of the eight where chapter 05 has them; the attention budget never turns more than two heads at once, and
## only near, facing heads; Nyima falls in behind a new player at Tsongra, keeps a few metres back on the player's own
## trail, scatters when the player turns on him, and walks back to his place when it is over. Since sprint 6, step 4
## the twelve generic walk beside the eight (data/generic_days.json).

const Town := preload("res://world/town.gd")
const Attention := preload("res://characters/attention.gd")
const Named := preload("res://characters/named.gd")
const PATH := "user://test_named_streets.json"
const STREETS := "res://assets/generated/terrain/street_graph.json"
const CROWD: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]

var keep := {}


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen, "rate": WorldClock.rate}
	WorldClock.frozen = true


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]
	WorldClock.rate = keep["rate"]


func _at(m: float) -> void:
	WorldClock.minute = 7.0 * 1440.0 + m
	TownSim.step(0.0, Vector3.ZERO)


## A made-up town: home at x = -20, a place at x = 0 (tsongra) with a seat 3 m north of it, 0.4 m up, facing south.
func _streets(day: Array, kind := "nyima_boy") -> void:
	var data := {"pace": 1.1, "up": 0.75, "down": 0.5, "rate": 0.1,
		"anchors": {"home": [-20.0, 0.0, 2662.0], "tsongra": [0.0, 0.0, 2662.0]},
		"walkers": [{"kind": kind, "named": true, "pace": 1.0, "up": 0.8, "down": 0.5, "home": "home", "day": day}],
		"routes": {
			"home>tsongra": {"p": [-20.0, 0.0, 2662.0, -10.0, 0.0, 2662.0, 0.0, 0.0, 2662.0], "k": [0, 0], "n": [0, 0]},
			"tsongra>home": {"p": [0.0, 0.0, 2662.0, -10.0, 0.0, 2662.0, -20.0, 0.0, 2662.0], "k": [0, 0], "n": [0, 0]}}}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	TownSim.setup_walkers(PATH, CROWD)


func test_a_seat() -> void:
	var seat := {"name": "test", "at": [0.0, 3.0, 2662.4], "face": [0.0, -1.0], "pose": "chair"}
	_streets([["home", 0, 600, "inside", 0, null], ["tsongra", 620, 640, "sit", 0, seat], ["home", 700, 1440, "inside", 0, null]])
	assert_eq(int(TownSim.kind[0]), TownSim.NAMED, "not one of the crowd's kinds: drawn by characters/named.gd")
	assert_eq(String(TownSim.key[0]), "nyima_boy", "its key kept")
	assert_eq(TownSim.slipped, 0, "on time")
	_at(619.9)  # 20 m at 1 m/s and 3.03 m to the seat (0.4 m up: Tobler), about 2.4 game minutes before 10:20
	assert_eq(int(TownSim.state[0]), 0, "walking onto its seat")
	_at(625.0)
	assert_eq(int(TownSim.state[0]), 3, "sitting")
	assert_almost_eq(TownSim.pos[0].distance_to(Town.to_godot(0.0, 3.0, 2662.4)), 0.0, 0.01, "on its seat")
	assert_almost_eq(float(TownSim.yaw[0]), 0.0, 0.001, "facing south: the town grid's -y is Godot's +z")
	var span: Vector2 = TownSim.rest_span(0)
	assert_almost_eq(span.x, 620.0, 0.05, "sat down on arriving")
	assert_between(span.y, 690.0, 700.0, "gets up when it must leave to be home by 11:40, not at 10:40")
	assert_eq(String(TownSim.stop_now(0)[0]), "tsongra", "its stop")
	_at(699.9)
	assert_eq(int(TownSim.state[0]), 0, "walking home")


func test_the_eight_at_their_places() -> void:
	if not FileAccess.file_exists(STREETS):
		pending("no street graph (tools/town/graph.py)")
		return
	TownSim.setup_walkers(STREETS, CROWD)
	var who := {}
	for i in TownSim.count:
		if TownSim.kind[i] == TownSim.NAMED and not who.has(String(TownSim.key[i])):  # a body's first walker: the slice's
			who[String(TownSim.key[i])] = i  # (H-SHL-142's family share the porters', the girl's and the boy's bodies: M2 sprint 6)
	assert_eq(who.size(), 58, "(since M2 sprint 10 with the two who wear a townswoman's figure, the ngakpa quarter's two women) the named eight, the twelve generic, Dechen-tsang's kitchen two, the three houses to enter's households, H-SHL-142's grandmother (ISS-105), the two novices (IMP-024), the chang house's six (Ama Yudrön, her daughter, Jiang Deshun, two soldiers, the bard; M2 sprint 2), the ngakpa quarter's two men, the Lukhang spring's six water carriers and the Lookout's old woman (M2 sprint 6), the headman's household of eight, his reader and a Hejie trader (M2 sprint 7), Dechen-tsang's lama, steward and pieman (M2 sprint 8; its servants, tea-sewers and dice players in others' bodies) walk, drawn by characters/named.gd, by their bodies")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STREETS))
	var anchors: Dictionary = data["anchors"]
	var near := func(i: int, place: String) -> float:
		var a: Array = anchors[place]
		return Vector2(TownSim.pos[i].x - float(a[0]), -TownSim.pos[i].z - float(a[1])).length()
	# chapter 05, 4.2 (at the clock's 6:1: data/named_days.json)
	_at(16.7 * 60.0)
	assert_eq(int(TownSim.state[who["sonam_wangyal"]]), 3, "Sönam sits on the talkers' steps at 16:42")
	assert_lt(near.call(who["sonam_wangyal"], "talkers"), 6.0, "by their foot")
	assert_eq(int(TownSim.state[who["achak_dolkar"]]), 4, "Dolkar talks in her gateway")
	assert_eq(int(TownSim.state[who["elder_man"]]), 3, "an old man sits beside Sönam (sprint 6, step 4)")
	assert_eq(int(TownSim.state[who["pasang_carver"]]), 0, "Pasang is walking round the barkor")
	_at(10.0 * 60.0)
	assert_eq(int(TownSim.state[who["pasang_carver"]]), 3, "Pasang sits carving at 10:00")
	assert_lt(near.call(who["pasang_carver"], "pitch"), 3.0, "at his pitch")
	assert_eq(int(TownSim.state[who["kalsang_drolma"]]), 4, "Kalsang at her family's stall")
	assert_eq(int(TownSim.state[who["tsomo_nomad"]]), 4, "Tsomo selling at Tsongra")
	assert_eq(int(TownSim.state[who["nomad_woman"]]), 4, "another nomad woman selling butter")
	assert_eq(int(TownSim.state[who["stall_woman"]]), 4, "Nyima's mother at her stall")
	assert_eq(int(TownSim.state[who["stall_man"]]), 4, "the east stall's keeper at his")
	_at(12.0 * 60.0)
	assert_eq(int(TownSim.state[who["nyima_boy"]]), 5, "Nyima crouched at knucklebones on the steps")
	assert_eq(int(TownSim.state[who["boy"]]), 5, "a boy of his band with him")
	assert_eq(int(TownSim.state[who["girl"]]), 5, "and a girl")
	_at(12.67 * 60.0)
	assert_eq(int(TownSim.state[who["stall_woman"]]), 2, "his mother home for her midday meal at 12:40")
	_at(14.0 * 60.0)
	assert_eq(int(TownSim.state[who["kalsang_drolma"]]), 1, "Kalsang spinning at her doorway")
	assert_lt(near.call(who["kalsang_drolma"], "H-SHL-078"), 0.1, "at her door")
	_at(16.2 * 60.0)
	assert_eq(int(TownSim.state[who["nyima_boy"]]), 1, "Nyima at Tsongra from 16:00, to follow the player")
	_at(2.0 * 60.0)
	for k in who:
		assert_eq(int(TownSim.state[who[k]]), 2, "%s indoors at 02:00" % k)


func test_the_attention_budget() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var att: Node = Attention.new()
	root.add_child(att)
	var eyes := Vector3(0.0, 1.55, 0.0)
	var cands := []
	for k in 8:  # six near and facing the player, one near but turned away, one 15 m off
		var fig := Node3D.new()
		root.add_child(fig)
		var sk := Skeleton3D.new()
		sk.add_bone("head")
		fig.add_child(sk)
		var r := 15.0 if k == 7 else 3.0 + k
		var a := k * TAU / 8.0
		fig.position = Vector3(sin(a), 0.0, cos(a)) * r
		fig.look_at(Vector3(0.0, 0.0, 0.0) if k != 6 else fig.position * 2.0, Vector3.UP, true)  # its +Z to the player
		cands.append(["f%d" % k, fig, Attention.head_look(sk), 3.0])
	var looked := {}
	for n in 1200:  # a minute at 20 frames a second
		att.update(0.05, eyes, 1.0, cands)
		for id in att.looking:
			looked[id] = true
	assert_lte(int(att.most_at_once), 2, "never more than two heads turned at once")
	assert_gt(int(att.looks), 4, "but some looks")
	assert_false(looked.has("f6"), "not one turned away from the player")
	assert_false(looked.has("f7"), "not one 15 m off")
	var mod: LookAtModifier3D = cands[0][2]
	assert_almost_eq(rad_to_deg(mod.primary_limit_angle), 140.0, 0.01, "±70 degrees of yaw")
	assert_almost_eq(rad_to_deg(mod.secondary_limit_angle), 60.0, 0.01, "±30 of pitch")


func test_nyima_follows() -> void:
	_streets([["home", 0, 900, "inside", 0, null], ["tsongra", 960, 1030, "stand", 0, null], ["home", 1045, 1440, "inside", 0, null]])
	var named: Node3D = Named.new()
	add_child_autofree(named)
	named.setup(TownSim, null)
	if named.nyima < 0:
		pending("no body for Nyima (../tibet-blender/people2/body.py)")
		return
	var player := Node3D.new()
	add_child_autofree(player)
	named.player = player
	_at(965.0)
	WorldClock.frozen = false  # the follow runs in play only; the clock is not advanced here (no frames pass)
	WorldClock.rate = WorldClock.RATE_PLAY
	var start: Vector3 = TownSim.pos[0]
	player.global_position = start + Vector3(8.0, 0.0, 0.0)
	player.rotation.y = -PI / 2.0  # facing +x, away from him
	named.update(0.05, player.global_position)
	assert_eq(int(named.follows), 1, "he falls in behind a player who passes within 12 m")
	var gaps := []
	for n in 400:  # 20 s east at 1.4 m/s
		player.global_position += Vector3(1.4 * 0.05, 0.0, 0.0)
		named.update(0.05, player.global_position)
		if n > 100 and String(named.follow.get("mode", "")) == "trail":
			gaps.append(player.global_position.distance_to(named.follow["pos"]))
	assert_gt(gaps.size(), 10, "trailing for a while")
	if not gaps.is_empty():
		gaps.sort()
		assert_between(float(gaps[gaps.size() / 2]), 2.5, 4.5, "about 3 m behind")
	for n in 1600:  # the player stands; he watches, and walks back to his place
		named.update(0.05, player.global_position)
	assert_true(named.follow.is_empty(), "the follow over")
	assert_eq(int(named.follows), 1, "not again within a minute")
	var fig: Node3D = named.people[0]["root"]
	assert_almost_eq(fig.position.distance_to(start), 0.0, 0.05, "back at his place")


func test_nyima_scatters() -> void:
	_streets([["home", 0, 900, "inside", 0, null], ["tsongra", 960, 1030, "stand", 0, null], ["home", 1045, 1440, "inside", 0, null]])
	var named: Node3D = Named.new()
	add_child_autofree(named)
	named.setup(TownSim, null)
	if named.nyima < 0:
		pending("no body for Nyima")
		return
	var player := Node3D.new()
	add_child_autofree(player)
	named.player = player
	_at(965.0)
	WorldClock.frozen = false
	WorldClock.rate = WorldClock.RATE_PLAY
	var start: Vector3 = TownSim.pos[0]
	player.global_position = start + Vector3(6.0, 0.0, 0.0)
	player.rotation.y = -PI / 2.0
	for n in 100:  # 5 s east at 1.2 m/s: he comes on behind
		player.global_position += Vector3(1.2 * 0.05, 0.0, 0.0)
		named.update(0.05, player.global_position)
	player.rotation.y = PI / 2.0  # turned on him (facing -x)
	named.update(0.05, player.global_position)
	assert_eq(int(named.scatters), 1, "he scatters when the player turns on him")
	var before: float = player.global_position.distance_to(named.follow["pos"])
	for n in 30:
		named.update(0.05, player.global_position)
	assert_gt(player.global_position.distance_to(named.follow["pos"]), before + 2.0, "back down the trail")
