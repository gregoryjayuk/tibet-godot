extends Node3D
## Who is there at Samkha (M2 sprint 4, step 6; plan chapters 05, 06 and 10), added by world/town.gd with the people:
## - Sherab, the Pönpo's toll steward (NPC-39): over the chain bridge from the castle at dawn, at his table in the south
##   pavilion SAM-04 from 06:30 counting the loads, back over the bridge with the day's tally at 16:45;
## - the castle's gatekeeper in the gate passage SAM-02: on his bench inside the leaves by day, at the gate from the dusk
##   horns until it is barred at 17:30 (world/castle_gate.gd), and there again to draw the bar at 05:30;
## - the Pönpo (NPC-03) on his roof by the tiled pavilion, 06:45-07:20 watching the road (V-18, 108 degrees) and
##   17:15-17:45 for the horns, turned to the monastery; between, 07:30-12:00, his court in the hall of twelve pillars
##   (step 7; chapter 04, 4.6): on his dais's cushions, the scribe at his low table, an elder on the rugs by the west
##   wall, the petitioners on their felts (a dispute over landing dues with Pharkha); since M2 sprint 11, step 5 the Shöl
##   headman Sönam Wangyal at his side (he walks up to the castle's steps: data/named_days.json), the parties on the
##   felts the day's walkers who bring the morning's cases (tools/town/roster.py CASES; TownSim.court), and on the great
##   court days, the 5th and 20th of the Tibetan month (data/calendar_1903.json's court_day; design), the hamlets'
##   headmen on the rugs by the west wall and the great cases' parties in at the ward's gate, waiting in the ward by the
##   steps, called up into the hall to wait along its east wall, and out again (GREAT_COURT, GREAT_WARD);
## - the castle's two mastiffs chained on its roof's south side by day, barking down at whoever is on the chain bridge
##   (SND-408, a stand-in until they are recorded), loosed in the ward from 20:00 to 06:00 (chapter 06, 5.1);
## - the day's crossings of the chain bridge (CROSSINGS: woodcutters going out and coming back loaded, a monk, a nomad
##   woman, a girl hurrying before the gate shuts), in the group "deck_walkers", so the deck sways under them
##   (world/chain_bridge.gd); since M2 sprint 11, step 5 the toll's traffic among them, porters with tea in from the road
##   and wool out to it, each stopping at Sherab's table while he counts the load (TOLL_MIN), and at 10:00 two of
##   Ngödrup's men over from the town to argue the Litang caravan's count with him (ARGUE; chapter 05, NPC-39).
## Everyone's place is worked out from the clock's minute (as the caravan's), so a still is the same each time; drawn
## only while the camera is within SEEN of the bridge. `plan`, `walker_s`, `toll_s`, `sherab_doing`, `ponpo_doing`,
## `gatekeeper_doing`, `dogs_where` and `great_court` are pure, for the tests.

const Town := preload("res://world/town.gd")
const PERSON := preload("res://characters/person.gdshader")
const SAMKHA := "res://data/samkha.json"
const DOG := "res://assets/generated/people/mastiff.glb"
const SEEN := 420.0  ## metres from the chain bridge's middle within which they are drawn
const SPEED := 0.8  ## m/s along the way: 8 m a game minute at the clock's play rate
const PER_MIN := 10.0  ## real seconds a game minute at the play rate (autoload/world_clock.gd RATE_PLAY, 0.1 a second)
const BARK := "SND-408"
const BARK_NEAR := 75.0  ## metres: a dog barks at a walker on the bridge this near
## the day's crossings: [game minute, body, "ns" north to south (out of the castle) or "sn", its load: "" none, "wood" a
## woodcutter's juniper and pine, "tea" bricks sewn in yak hide in from the road, "wool" a bale out to it]
const CROSSINGS := [[395.0, "porter", "sn", "tea"], [418.0, "porter_woman", "sn", "tea"], [460.0, "porter", "ns", ""],
		[478.0, "stall_man", "ns", "wool"], [552.0, "monk", "sn", ""], [585.0, "porter", "sn", "tea"],
		[631.0, "nomad_woman", "sn", ""], [668.0, "townsman_b", "ns", "wool"], [707.0, "porter_woman", "ns", "wool"],
		[745.0, "porter", "sn", "tea"], [796.0, "drover", "ns", ""], [850.0, "porter_woman", "ns", "wool"],
		[878.0, "townsman", "sn", ""], [912.0, "elder_man", "sn", ""], [925.0, "townswoman_b", "ns", ""],
		[955.0, "porter_woman", "sn", "tea"], [982.0, "porter", "sn", "wood"], [1021.0, "girl", "sn", ""]]
const OWN_LOAD := ["porter", "porter_woman"]  ## bodies with their own load on the back (people2/body.py props "load")
const TOLL_LOADS := ["tea", "wool"]  ## the loads Sherab counts at his table (20 cash a load: chapter 06, 8.4; design)
const TOLL_MIN := 1.5  ## game minutes at the table while he counts a load
## Ngödrup's men over from the town to argue the Litang caravan's count (chapter 05, NPC-39, 10:00): [set out, leave the
## table, body]
const ARGUE := [[594.0, 625.0, "drover"], [594.4, 625.0, "drover_b"]]
const WOMEN := ["nomad_woman", "porter_woman", "townswoman_b", "girl", "elder_woman", "stall_woman"]
const SHERAB_OUT := 381.0  ## 06:21: from the castle over the bridge to his table
const SHERAB_BACK := 1005.0  ## 16:45: the day's tally to the castle
const PONPO := [[405.0, 440.0, 108.0], [1035.0, 1065.0, 70.0]]  ## [from, to, bearing]: the road at dawn, the monastery's horns
const GATE_STAND := 1032.0  ## 17:12: the gatekeeper up from his bench to the gate
const GATE_IN := 1052.0  ## 17:32: the gate barred, he goes in
const GATE_OUT := 325.0  ## 05:25: at the gate to draw the bar
const DOGS_DAY := [360.0, 1200.0]  ## 06:00-20:00 on the roof, then loose in the ward
const COURT := [450.0, 720.0]  ## 07:30-12:00 (chapter 05's Pönpo; chapter 04 has 08:00-11:30: ISS-139)
## the court's people: [body, place, from, to] (the places in the castle's frame: kit/samkha.py court_hall's seats): the
## scribe, and the Shöl headman by the west wall while his walker is in the castle (data/named_days.json, castle_door)
const COURT_PEOPLE := [["elder_man", "court_scribe", 450.0, 720.0], ["sonam_wangyal", "court_elder", 452.0, 704.0]]
## the parties on the felts when the walkers are not out (TownSim.court gives the day's: tools/town/roster.py CASES)
const COURT_FELTS := [["drover_b", "court_pet_1", 455.0, 615.0], ["porter", "court_pet_2", 580.0, 715.0]]
## the great court on the 5th and 20th of the Tibetan month (chapter 07, 2: "the 5th and 20th ... kept for the great
## cases, with the hamlets' headmen present"; design): the hamlets' headmen on the rugs by the west wall
const GREAT_COURT := [["house_man", "court_headman_1", 455.0, 712.0], ["stall_man", "court_headman_2", 457.0, 712.0],
		["drover", "court_headman_3", 459.0, 712.0]]
## and the great cases' parties: in at the ward's gate, waiting in the ward by the steps (at [x, y] in the castle's frame,
## standing or sat on the ground), called up into the hall to wait along its east wall, out again and away by the gate:
## [body, in, called, out, spot, sat]
const GREAT_WARD := [["stall_woman", 425.0, 470.0, 540.0, [-7.2, 11.4], false], ["porter_woman", 440.0, 520.0, 600.0, [-8.6, 12.8], true],
		["elder_woman", 455.0, 560.0, 640.0, [-6.4, 13.9], false], ["drover_b", 470.0, 600.0, 680.0, [-9.9, 11.2], true],
		["nomad_woman", 500.0, 640.0, 712.0, [-4.7, 14.3], false]]
## the ward's ways in the castle's frame (kit/samkha.py castle: WARD_GATE in the east wall at y 13.5, the steps down from
## the passage's inner door, its foot at y 10.9): the gate's mouth, inside it, the steps' foot, their top
const WARD_GATE_MOUTH := Vector3(21.0, 13.5, 0.0)
const WARD_GATE_IN := Vector3(18.4, 13.4, 0.0)
const STEPS_FOOT := Vector3(0.0, 11.0, 0.0)
const STEPS_TOP := Vector3(0.0, 8.75, 1.5)

var way: PackedVector3Array  ## a crossing's way north to south: the passage, the deck, the pavilion, the road's end (Godot)
var cum: PackedFloat32Array
var deck_from := 0.0  ## the deck's ends along `way`
var deck_to := 0.0
var sherab_way: PackedVector3Array  ## from the passage to his seat's front edge
var sherab_cum: PackedFloat32Array
var way_toll: PackedVector3Array  ## a crossing with a load to count: by the table's front between the deck and the road
var cum_toll: PackedFloat32Array
var toll_at := 0.0  ## the table's front along `way_toll`
var argue_way: PackedVector3Array  ## Ngödrup's men's: from the passage over the deck to the table's front
var argue_cum: PackedFloat32Array
var _great_day := false  ## today the great court sits (the calendar's court_day)
var places := {}  ## name -> Transform3D (Godot, global): "seat_sherab", "seat_gate", "gate", "ponpo", "ponpo_door", "dog_0"...
var people: Array = []  ## {key, kind, root, ap, clip, ...}
var dogs: Array = []  ## {root, ap, clip, at, ward, next_bark, burst}
var sway: Node  ## the chain bridge's sway (world/chain_bridge.gd)
var _mat: ShaderMaterial
var _built := false
var _mid := Vector3.ZERO
var _south := Vector3(0.0, 0.0, 1.0)  ## the castle's south, its passage's way out (Godot)


## The crossings as dictionaries: {start, key, dir, load}.
static func plan() -> Array:
	return CROSSINGS.map(func(c: Array) -> Dictionary: return {"start": float(c[0]), "key": String(c[1]), "dir": String(c[2]), "load": String(c[3])})


## Metres along its way a walker that set out at `start` has come at minute `m`, stopping `pause` minutes at `at` metres
## (a load counted at the toll table), or -1 before it sets out and after it has arrived (it is gone).
static func toll_s(start: float, m: float, length: float, at: float, pause: float) -> float:
	var s := (m - start) * PER_MIN * SPEED
	if s > at:
		s = maxf(at, s - pause * PER_MIN * SPEED)
	return s if s >= 0.0 and s <= length else -1.0


## Whether the great court sits on the day of game minute `minute` (the calendar's court_day: the 5th and 20th of the
## Tibetan month).
static func great_court(minute: float) -> bool:
	return Calendar.flags(minute).has("court_day")


## Metres along a way of `length` a walker that set out at `start` has come at minute `m`, or -1 before it sets out and
## after it has arrived (it is gone).
static func walker_s(start: float, m: float, length: float) -> float:
	var s := (m - start) * PER_MIN * SPEED
	return s if s >= 0.0 and s <= length else -1.0


## What Sherab is doing at minute `m`, his way's `length` long: "home", "out" (crossing to the table), "table", "back".
static func sherab_doing(m: float, length: float) -> String:
	var dur := length / (PER_MIN * SPEED)
	if m >= SHERAB_OUT and m < SHERAB_OUT + dur:
		return "out"
	if m >= SHERAB_OUT + dur and m < SHERAB_BACK:
		return "table"
	if m >= SHERAB_BACK and m < SHERAB_BACK + dur:
		return "back"
	return "home"


## Where the Pönpo is at minute `m`: "roof" (with its bearing), "court" or "in".
static func ponpo_doing(m: float) -> Array:
	for w in PONPO:
		if m >= float(w[0]) and m < float(w[1]):
			return ["roof", float(w[2])]
	if m >= float(COURT[0]) and m < float(COURT[1]):
		return ["court", 180.0]
	return ["in", 0.0]


## What the gatekeeper is doing at minute `m`: "bench", "gate" (by the leaves at dawn and from the horns), "in".
static func gatekeeper_doing(m: float) -> String:
	if m >= GATE_OUT and m < GATE_OUT + 8.0:
		return "gate"
	if m >= GATE_OUT + 8.0 and m < GATE_STAND:
		return "bench"
	if m >= GATE_STAND and m < GATE_IN:
		return "gate"
	return "in"


## Where the castle's dogs are at minute `m`: "roof" by day, "ward" by night.
static func dogs_where(m: float) -> String:
	return "roof" if m >= float(DOGS_DAY[0]) and m < float(DOGS_DAY[1]) else "ward"


static func _cum(p: PackedVector3Array) -> PackedFloat32Array:
	var c := PackedFloat32Array([0.0])
	for i in range(1, p.size()):
		c.append(c[i - 1] + p[i].distance_to(p[i - 1]))
	return c


static func _at(p: PackedVector3Array, c: PackedFloat32Array, s: float) -> Vector3:
	s = clampf(s, 0.0, c[c.size() - 1])
	for i in range(1, p.size()):
		if s <= c[i]:
			var f := (s - c[i - 1]) / maxf(c[i] - c[i - 1], 0.0001)
			return p[i - 1].lerp(p[i], f)
	return p[p.size() - 1]


## A socket's place and facing (its kit +y, Godot -z) as a Transform3D, from `node`'s scene.
static func _sock(node: Node3D, name: String) -> Transform3D:
	var s := node.find_child(name, true, false) as Node3D
	return s.global_transform if s != null else Transform3D()


## Gathers the places from the castle (SAM-01), the pavilion (SAM-04) and data/samkha.json. The count of who is there.
func build(root: Node3D) -> int:
	var castle := root.get_node_or_null("SAM-01") as Node3D
	var pav := root.get_node_or_null("SAM-04") as Node3D
	if castle == null or pav == null or not FileAccess.file_exists(SAMKHA):
		return 0
	var sk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMKHA))
	var br: Dictionary = sk["bridge"]
	var bx := float(br["x"])
	var kit := func(x: float, y: float, z: float) -> Vector3: return castle.global_transform * Vector3(x, z, -y)  # the castle's frame
	var pk := func(x: float, y: float, z: float) -> Vector3: return pav.global_transform * Vector3(x, z, -y)  # the pavilion's
	var pts := PackedVector3Array([kit.call(0.0, -2.0, 1.5), kit.call(0.0, -8.6, 1.5)])
	for q in br["deck"]:
		pts.append(Town.to_godot(bx, float(q[0]), float(q[1])))
	deck_from = 0.0
	way = pts
	cum = _cum(way)
	deck_from = cum[2]
	deck_to = cum[cum.size() - 1]
	way.append(pk.call(0.3, 1.6, 0.04))  # into the pavilion, then out by its open east end to the road's end
	way.append(pk.call(5.6, 1.2, 0.04))
	way.append(Town.to_godot(-121.5, -141.5, 2655.1))
	cum = _cum(way)
	sherab_way = PackedVector3Array(pts)
	var seat := _sock(pav, "SOCK_SEAT_1")
	sherab_way.append(pk.call(-1.2, 1.4, 0.04))
	sherab_way.append(seat.origin)
	sherab_cum = _cum(sherab_way)
	places["seat_sherab"] = seat
	# the toll (M2 sprint 11, step 5): a load is counted before the table (kit/samkha.py south_pavilion: the table at
	# (-3.5, 0.2), 0.75 deep, his seat behind it facing the bridge), on the way between the deck and the road
	var front: Vector3 = pk.call(-3.5, 1.08, 0.04)
	way_toll = PackedVector3Array(pts)
	way_toll.append(front)
	toll_at = _cum(way_toll)[way_toll.size() - 1]
	way_toll.append(pk.call(5.6, 1.2, 0.04))
	way_toll.append(Town.to_godot(-121.5, -141.5, 2655.1))
	cum_toll = _cum(way_toll)
	argue_way = PackedVector3Array(pts)
	argue_way.append(front)
	argue_cum = _cum(argue_way)
	places["seat_gate"] = _sock(castle, "SOCK_SEAT_1")
	places["gate"] = Transform3D(Basis(), kit.call(0.95, -7.3, 1.5))
	places["house_door"] = Transform3D(Basis(), kit.call(1.1, -1.6, 1.5))
	var h := 18.7  # the castle's roof over its ward (kit/samkha.py: the plinth, five storeys, the crown)
	places["ponpo"] = Transform3D(Basis(), kit.call(5.6, 2.8, h))
	places["ponpo_door"] = Transform3D(Basis(), kit.call(-2.0, -1.3, h))
	places["dog_0"] = Transform3D(Basis(), kit.call(-4.6, -5.3, h))
	places["dog_1"] = Transform3D(Basis(), kit.call(3.8, -5.6, h))
	places["dog_ward_0"] = Transform3D(Basis(), kit.call(-14.0, 2.0, 0.0))
	places["dog_ward_1"] = Transform3D(Basis(), kit.call(15.0, -3.0, 0.0))
	# the court (step 7): each sitter's root, cross-legged (the clip's hips 0.4 m behind it), and the way it faces
	var face := func(b: float) -> Basis: return Basis(Vector3.UP, castle.global_rotation.y + deg_to_rad(180.0 - b))
	places["court_ponpo"] = Transform3D(face.call(180.0), kit.call(0.0, 5.15, 5.27))
	places["court_scribe"] = Transform3D(face.call(90.0), kit.call(-2.95, 1.6, 4.7))
	places["court_elder"] = Transform3D(face.call(90.0), kit.call(-6.1, 1.2, 4.7))
	places["court_pet_1"] = Transform3D(face.call(0.0), kit.call(-1.0, -2.6, 4.7))
	places["court_pet_2"] = Transform3D(face.call(0.0), kit.call(1.1, -2.45, 4.7))
	# the great court's (step 5): the hamlets' headmen on the west wall's rugs either side of the Shöl headman's place, and
	# the great cases' parties waiting their turn along the east wall, north of the stair's well, facing the court
	places["court_headman_1"] = Transform3D(face.call(90.0), kit.call(-6.1, -0.2, 4.7))
	places["court_headman_2"] = Transform3D(face.call(90.0), kit.call(-6.1, 2.35, 4.7))
	places["court_headman_3"] = Transform3D(face.call(90.0), kit.call(-6.1, 3.45, 4.7))
	for k in 4:
		places["court_east_%d" % k] = Transform3D(face.call(270.0), kit.call(6.0, 0.3 + 1.05 * k, 4.7))
	sway = root.get_node_or_null("SAM-03/Sway")
	_south = castle.global_transform.basis.z.normalized()  # the kit's -y
	_mid = _at(way, cum, (deck_from + deck_to) / 2.0)
	people = [{"key": "sherab_steward", "kind": "sherab"}, {"key": "castle_gatekeeper", "kind": "gate"},
			{"key": "ponpo_tsewang", "kind": "ponpo"}]
	for c in plan():
		var d: Dictionary = c
		d["kind"] = "cross"
		people.append(d)
	for c in COURT_PEOPLE:
		people.append({"key": String(c[0]), "kind": "court", "spot": String(c[1]), "from": float(c[2]), "to": float(c[3])})
	for c in GREAT_COURT:
		people.append({"key": String(c[0]), "kind": "great", "spot": String(c[1]), "from": float(c[2]), "to": float(c[3])})
	var kv := func(v: Vector3) -> Vector3: return kit.call(v.x, v.y, v.z)
	for k in GREAT_WARD.size():
		var c: Array = GREAT_WARD[k]
		var at: Vector3 = kit.call(float(c[4][0]), float(c[4][1]), 0.0)
		var ways := [PackedVector3Array([kv.call(WARD_GATE_MOUTH), kv.call(WARD_GATE_IN), at]),
				PackedVector3Array([at, kv.call(STEPS_FOOT), kv.call(STEPS_TOP)]),
				PackedVector3Array([kv.call(STEPS_TOP), kv.call(STEPS_FOOT), kv.call(WARD_GATE_IN), kv.call(WARD_GATE_MOUTH)])]
		people.append({"key": String(c[0]), "kind": "party", "in": float(c[1]), "called": float(c[2]), "out": float(c[3]),
				"at": at, "sat": bool(c[5]), "hall": "court_east_%d" % (k % 4), "ways": ways, "cums": ways.map(func(w): return _cum(w)),
				"face": _yaw(kv.call(STEPS_FOOT) - at)})
	for k in ARGUE.size():
		var c: Array = ARGUE[k]
		people.append({"key": String(c[2]), "kind": "argue", "start": float(c[0]), "until": float(c[1]),
				"off": Vector3.ZERO if k == 0 else (pk.call(-3.15, 1.95, 0.04) as Vector3) - (pk.call(-3.5, 1.08, 0.04) as Vector3)})
	add_to_group("samkha_people")
	return people.size() + 2


## The parties on the hall's felts: the day's walkers who bring the morning's cases (TownSim.court: from the steps up to
## the hall, on the felt, down again), or COURT_FELTS when the walkers are not out.
static func court_parties() -> Array:
	var out: Array = []
	if TownSim.walkers_on:
		for i in TownSim.court:
			var c: Array = TownSim.court[i]
			out.append({"key": TownSim.key[i], "kind": "court", "spot": "court_pet_%d" % int(c[2]), "from": float(c[0]) + 1.5, "to": float(c[1]) - 1.5})
	if out.is_empty():
		for c in COURT_FELTS:
			out.append({"key": String(c[0]), "kind": "court", "spot": String(c[1]), "from": float(c[2]), "to": float(c[3])})
	return out


func _bodies() -> void:
	_built = true
	_mat = ShaderMaterial.new()
	_mat.shader = PERSON
	people.append_array(court_parties())
	for p in people:
		var path := "res://assets/generated/people/%s.glb" % p["key"]
		if not ResourceLoader.exists(path):
			continue
		var root: Node3D = (load(path) as PackedScene).instantiate()
		root.name = "Samkha_%s_%s" % [String(p["kind"]), String(p["key"])]
		PersonLook.apply(root, _mat)
		var ap: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Walk_Female", "Walk_Carry", "Idle_A", "Idle_FoldArms", "Sitting_Idle", "Idle_Subtle", "Sitting_Cross", "Idle_Talking"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		add_child(root)
		root.visible = false
		var load_kind := String(p.get("load", ""))
		if load_kind != "" and not OWN_LOAD.has(String(p["key"])):  # on the back: a woodcutter's juniper and pine sticks, tea
			# bricks sewn in yak hide, a wool bale (a porter's body carries its own: people2/body.py's load)
			var bale := MeshInstance3D.new()
			var bm := BoxMesh.new()
			var spec: Array = {"wood": [Vector3(0.55, 0.75, 0.32), "#6B5236", 1.3, -0.25], "tea": [Vector3(0.42, 0.9, 0.28), "#3A2B20", 1.25, -0.24],
					"wool": [Vector3(0.6, 0.6, 0.45), "#CFC4AE", 1.3, -0.3]}.get(load_kind, [Vector3(0.5, 0.6, 0.3), "#6B5236", 1.3, -0.25])
			bm.size = spec[0]
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(String(spec[1]))
			mat.roughness = 1.0
			bm.material = mat
			bale.mesh = bm
			bale.position = Vector3(0.0, float(spec[2]), float(spec[3]))
			root.add_child(bale)
		p["root"] = root
		p["ap"] = ap
		p["clip"] = ""
		if String(p["kind"]) == "cross":
			root.add_to_group("deck_walkers")
	if ResourceLoader.exists(DOG):
		for k in 2:
			var d: Node3D = (load(DOG) as PackedScene).instantiate()
			var droot := Node3D.new()
			droot.name = "SamkhaMastiff%d" % k
			add_child(droot)
			d.scale = Vector3(1.6, 1.15, 1.15)  # the fox made a mastiff: heavier, broader
			droot.add_child(d)
			var coat := StandardMaterial3D.new()
			coat.albedo_color = Color("#16110E" if k == 0 else "#2E1E16")  # one black, one black-brown
			coat.roughness = 1.0
			for mi in d.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = coat
			var dsk: Skeleton3D = d.find_children("*", "Skeleton3D", true, false)[0]
			for bs in [["Head", 1.14], ["Nose", 0.72], ["Tail_Mid.001", 0.5]]:  # a broad head, a blunt muzzle, a short tail
				var bi := dsk.find_bone(String(bs[0]))  # (bones the clips turn but never scale)
				if bi >= 0:
					dsk.set_bone_pose_scale(bi, Vector3.ONE * float(bs[1]))
			var dap: AnimationPlayer = d.find_children("*", "AnimationPlayer", true, false)[0]
			for n in ["Walk", "Idle", "Idle Alert", "Sit", "Bark"]:
				if dap.has_animation(n):
					dap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
			droot.visible = false
			dogs.append({"root": droot, "ap": dap, "clip": "", "next_bark": 0.0, "burst": 0})


func _process(dt: float) -> void:
	if way.is_empty():
		return
	var cam := get_viewport().get_camera_3d()
	var on: bool = cam != null and Vector2(cam.global_position.x - _mid.x, cam.global_position.z - _mid.z).length() < SEEN
	if not on:
		for p in people:
			if p.has("root"):
				(p["root"] as Node3D).visible = false
		for d in dogs:
			(d["root"] as Node3D).visible = false
		return
	if not _built:
		_bodies()
	var m := fposmod(WorldClock.minute, 1440.0)
	_great_day = great_court(WorldClock.minute)
	var frozen: bool = WorldClock.frozen
	var g: float = WorldClock.anim_time
	var on_deck: Array = []  # positions of whoever is on the chain bridge now, for the dogs
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl != null and _on_bridge(pl.global_position) >= 0.0:
		on_deck.append(pl.global_position)
	for i in people.size():
		var p: Dictionary = people[i]
		if not p.has("root"):
			continue
		var r: Array = _where(p, m)  # [shown, position, yaw, clip, walking]
		var root: Node3D = p["root"]
		root.visible = bool(r[0])
		root.set_meta("walking", bool(r[4]))
		if not bool(r[0]):
			continue
		var pos: Vector3 = r[1]
		var t := _on_bridge(pos)
		if t >= 0.0:
			on_deck.append(pos)
			if sway != null:  # the walker rides the deck's sway
				var a: Vector2 = sway.get("a")
				var side: Vector3 = sway.get("side")
				pos += (side * a.x + Vector3.UP * a.y) * sin(PI * t)
		root.global_position = pos
		root.rotation.y = float(r[2])
		_play(p, String(r[3]), frozen, g, i)
	_dogs(m, dt, frozen, g, on_deck)


## The chain bridge's `t` (0 at its north end, 1 at its south) at `p` if `p` is on its deck, else -1.
func _on_bridge(p: Vector3) -> float:
	if sway != null and sway.has_method("_walker_on"):
		return float(sway.call("_walker_on", p))
	return -1.0


## Where `p` is at minute `m`: [shown, position, yaw, clip, walking].
func _where(p: Dictionary, m: float) -> Array:
	match String(p["kind"]):
		"cross":
			var toll := TOLL_LOADS.has(String(p["load"]))  # a load to count: by the table, and a stop there
			var w: PackedVector3Array = way_toll if toll else way
			var c: PackedFloat32Array = cum_toll if toll else cum
			var L := c[c.size() - 1]
			var ns := String(p["dir"]) == "ns"
			var at := toll_at if ns else L - toll_at
			var s := toll_s(float(p["start"]), m, L, at, TOLL_MIN if toll else 0.0)
			if s < 0.0:
				return [false, Vector3.ZERO, 0.0, "", false]
			var counted := toll and is_equal_approx(s, at) and (m - float(p["start"])) * PER_MIN * SPEED > at
			if not ns:
				s = L - s
			var q := _at(w, c, s)
			if counted:  # stood before the table, facing Sherab, while he counts the load
				return [true, q, _yaw((places["seat_sherab"] as Transform3D).origin - q), "Idle_A", false]
			var ahead := _at(w, c, s + (0.5 if ns else -0.5))
			return [true, q, _yaw(ahead - q), _walk(p), true]
		"argue":  # over the bridge to the table, the count argued, back over it
			var L := argue_cum[argue_cum.size() - 1]
			var off: Vector3 = p["off"]
			var dur := L / (PER_MIN * SPEED)
			var st := float(p["start"])
			var until := float(p["until"])
			if m < st or m >= until + dur:
				return [false, Vector3.ZERO, 0.0, "", false]
			if m >= st + dur and m < until:
				var q := argue_way[argue_way.size() - 1] + off
				return [true, q, _yaw((places["seat_sherab"] as Transform3D).origin - q), "Idle_Talking", false]
			var out := m < st + dur
			var s := (m - st) * PER_MIN * SPEED if out else L - (m - until) * PER_MIN * SPEED
			var q := _at(argue_way, argue_cum, s) + off * clampf(s / L, 0.0, 1.0)
			var ahead := _at(argue_way, argue_cum, s + (0.5 if out else -0.5)) + off * clampf((s + (0.5 if out else -0.5)) / L, 0.0, 1.0)
			return [true, q, _yaw(ahead - q), "Walk", true]
		"great":  # the hamlets' headmen, on a great court's day
			if not _great_day or m < float(p["from"]) or m >= float(p["to"]):
				return [false, Vector3.ZERO, 0.0, "", false]
			var t: Transform3D = places[String(p["spot"])]
			return [true, t.origin, t.basis.get_euler().y, "Sitting_Cross", false]
		"party":  # a great case's party: in at the ward's gate, waiting, up into the hall, out by the gate
			if not _great_day:
				return [false, Vector3.ZERO, 0.0, "", false]
			var ways: Array = p["ways"]
			var cums: Array = p["cums"]
			var legs := [[float(p["in"]), 0], [float(p["called"]), 1], [float(p["out"]), 2]]
			for lg in legs:
				var c: PackedFloat32Array = cums[int(lg[1])]
				var s := walker_s(float(lg[0]), m, c[c.size() - 1])
				if s >= 0.0:
					var w: PackedVector3Array = ways[int(lg[1])]
					var q := _at(w, c, s)
					return [true, q, _yaw(_at(w, c, s + 0.5) - q), _walk(p), true]
			var c_in: PackedFloat32Array = cums[0]
			var c_up: PackedFloat32Array = cums[1]
			var waiting_from := float(p["in"]) + c_in[c_in.size() - 1] / (PER_MIN * SPEED)
			var hall_from := float(p["called"]) + c_up[c_up.size() - 1] / (PER_MIN * SPEED)
			if m >= waiting_from and m < float(p["called"]):
				return [true, p["at"], float(p["face"]), "Sitting_Cross" if bool(p["sat"]) else "Idle_A", false]
			if m >= hall_from and m < float(p["out"]):
				var t: Transform3D = places[String(p["hall"])]
				return [true, t.origin, t.basis.get_euler().y, "Sitting_Cross", false]
			return [false, Vector3.ZERO, 0.0, "", false]
		"sherab":
			var L := sherab_cum[sherab_cum.size() - 1]
			var seat: Transform3D = places["seat_sherab"]
			match sherab_doing(m, L):
				"out", "back":
					var s := walker_s(SHERAB_OUT if m < 720.0 else SHERAB_BACK, m, L)
					if m >= 720.0:
						s = L - s
					var q := _at(sherab_way, sherab_cum, s)
					var ahead := _at(sherab_way, sherab_cum, s + (0.5 if m < 720.0 else -0.5))
					return [true, q, _yaw(ahead - q), "Walk", true]
				"table":
					return [true, seat.origin, _yaw(-seat.basis.z), "Sitting_Idle", false]
			return [false, Vector3.ZERO, 0.0, "", false]
		"gate":
			var seat: Transform3D = places["seat_gate"]
			match gatekeeper_doing(m):
				"bench":
					return [true, seat.origin, _yaw(-seat.basis.z), "Sitting_Idle", false]
				"gate":
					return [true, (places["gate"] as Transform3D).origin, _yaw(_south), "Idle_FoldArms", false]
			return [false, Vector3.ZERO, 0.0, "", false]
		"court":
			if m < float(p["from"]) or m >= float(p["to"]):
				return [false, Vector3.ZERO, 0.0, "", false]
			var t: Transform3D = places[String(p["spot"])]
			return [true, t.origin, t.basis.get_euler().y, "Sitting_Cross", false]
		"ponpo":
			var w := ponpo_doing(m)
			if String(w[0]) == "court":
				var t: Transform3D = places["court_ponpo"]
				return [true, t.origin, t.basis.get_euler().y, "Sitting_Cross", false]
			if String(w[0]) != "roof":
				return [false, Vector3.ZERO, 0.0, "", false]
			var spot: Vector3 = (places["ponpo"] as Transform3D).origin
			var door: Vector3 = (places["ponpo_door"] as Transform3D).origin
			var from := 0.0
			var to := 0.0
			for wd in PONPO:
				if m >= float(wd[0]) and m < float(wd[1]):
					from = float(wd[0])
					to = float(wd[1])
			var walk_min := door.distance_to(spot) / (PER_MIN * SPEED)
			if m < from + walk_min:  # out of the pavilion's door to his place by the parapet
				var q := door.lerp(spot, (m - from) / walk_min)
				return [true, q, _yaw(spot - door), "Walk", true]
			if m > to - walk_min:
				var q := spot.lerp(door, (m - (to - walk_min)) / walk_min)
				return [true, q, _yaw(door - spot), "Walk", true]
			return [true, spot, _bearing_yaw(float(w[1])), "Idle_FoldArms", false]
	return [false, Vector3.ZERO, 0.0, "", false]


static func _yaw(d: Vector3) -> float:
	return atan2(d.x, d.z) if Vector2(d.x, d.z).length() > 0.0001 else 0.0


## The yaw that faces a bearing (degrees from north, clockwise): the town's y north is Godot's -z.
static func _bearing_yaw(b: float) -> float:
	var r := deg_to_rad(b)
	return atan2(sin(r), -cos(r))


func _walk(p: Dictionary) -> String:
	if String(p.get("load", "")) != "":
		return "Walk_Carry"
	return "Walk_Female" if WOMEN.has(String(p["key"])) else "Walk"


func _play(p: Dictionary, clip: String, frozen: bool, g: float, i: int) -> void:
	var ap: AnimationPlayer = p["ap"]
	if not ap.has_animation(clip):
		clip = "Walk" if clip.begins_with("Walk") and ap.has_animation("Walk") else "Idle_A"
	if String(p["clip"]) != clip:
		ap.play(clip, 0.0 if frozen or String(p["clip"]) == "" else 0.3)
		p["clip"] = clip
	if frozen:  # the stills: the pose from the animation clock
		ap.speed_scale = 0.0
		ap.seek(fposmod(g + i * 0.41, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = 1.0


## The two mastiffs: on the roof by day, turned to whoever is on the bridge within BARK_NEAR and barking in bursts; in
## the ward at night.
func _dogs(m: float, dt: float, frozen: bool, g: float, on_deck: Array) -> void:
	var where := dogs_where(m)
	for k in dogs.size():
		var d: Dictionary = dogs[k]
		var root: Node3D = d["root"]
		root.visible = true
		var home: Transform3D = places["dog_%d" % k if where == "roof" else "dog_ward_%d" % k]
		var pos := home.origin
		var target := Vector3.INF
		if where == "roof":
			for q in on_deck:
				if (q as Vector3).distance_to(pos) < BARK_NEAR and (target == Vector3.INF or (q as Vector3).distance_to(pos) < target.distance_to(pos)):
					target = q
		var clip := "Sit" if where == "roof" else "Idle"
		var yaw := _yaw(_south) + (0.4 if k == 0 else -0.3)
		if target != Vector3.INF:
			var to := target - pos
			yaw = _yaw(to)
			pos += Vector3(to.x, 0.0, to.z).normalized() * 0.3  # up to the parapet's edge
			clip = "Bark" if int(d["burst"]) > 0 or frozen else "Idle Alert"
			if not frozen:
				d["next_bark"] = float(d["next_bark"]) - dt
				if float(d["next_bark"]) <= 0.0:
					if int(d["burst"]) <= 0:
						d["burst"] = randi_range(3, 6)  # a burst of barks, then a while alert
					if is_instance_valid(AudioDirector):
						AudioDirector.play(BARK, pos + Vector3(0.0, 0.6, 0.0))
					d["burst"] = int(d["burst"]) - 1
					d["next_bark"] = randf_range(0.55, 1.0) if int(d["burst"]) > 0 else randf_range(2.5, 5.0)
		else:
			d["burst"] = 0
		root.global_position = pos
		root.rotation.y = yaw
		var ap: AnimationPlayer = d["ap"]
		if not ap.has_animation(clip):
			clip = "Idle"
		if String(d["clip"]) != clip:
			ap.play(clip, 0.0 if frozen or String(d["clip"]) == "" else 0.25)
			d["clip"] = clip
		if frozen:
			ap.speed_scale = 0.0
			ap.seek(fposmod(g + k * 0.53, ap.get_animation(clip).length), true)
		else:
			ap.speed_scale = 1.0

