extends Node3D
## Who is on the Serchu road (M2 sprint 12, step 6; plan chapter 02, D09: "by day 60-200 on the road: carriers,
## pilgrims, a caravan arriving, woodcutters ... by night about 55: the washers' camp, the millers' families"; chapter 08,
## V-01's approach: "through gold larch on the shaded south bank, past the gold washers' bark huts on the gravel bars and
## then the road mani wall"), added by world/town.gd with the people:
## - the day's travellers (TRIPS), each its way from its minute at a walker's pace: carriers down from Dartsedo with
##   tea and up again with wool or nothing, pilgrims down to the town's temples, tenants and monks to the monastery with
##   barley (down the road, off it down the path to the mills' footbridge, over the logs and up the Yak Road), the
##   woodcutters down from the foot of their paths with their wood. Down the road by data/serchu_road.json's `north_path`
##   and `path`, the mani wall on the right, on along the cliff gallery to the Gate Chorten (data/arrival.json); up it by
##   `path_up`. A carrier who rests props his load on the porters' rest SER-19's ledge (REST) for REST_MIN minutes;
## - the gold washers (twelve men and women, SER-12): 07:30-16:30 three at the troughs' heads (WASH), six crouched at the
##   water's edge with their pans (`washers`), three about the huts; their noon at the camp; from 16:30 round the three
##   huts' fires (FIRE: lit 17:00-22:00 and for the morning's tea 05:30-07:30, the crackle heard near), in at 21:30;
## - the four millers, 06:30-18:30 at their mills (data/serchu_mills.json), on the felt by the stones (MILLER) or at the
##   door (DOOR) by turns;
## - the three woodcutters, 08:30-14:50 by their trees in the Shade Wood above the road
##   (assets/generated/terrain/forest.json `cutters`), their axes heard (SND-216), then down the road with their wood.
## Everyone's place is worked out from the clock's minute, so a still is the same each time; drawn only while the camera
## is within SEEN of the road's middle. `trip_s`, `washer_doing`, `miller_doing`, `cutter_working`, `fire_lit` are
## pure, for the tests.

const Town := preload("res://world/town.gd")
const PERSON := preload("res://characters/person.gdshader")
const LAMP := preload("res://shaders/lamp_mm.gdshader")
const ROAD := "res://data/serchu_road.json"
const MILLS := "res://data/serchu_mills.json"
const ARRIVAL := "res://data/arrival.json"
const FOREST := "res://assets/generated/terrain/forest.json"
const SEEN := 820.0  ## metres from the road's middle within which they are drawn
const SPEED := 0.8  ## m/s along the way: 8 m a game minute at the clock's play rate
const PER_MIN := 10.0  ## real seconds a game minute at the play rate (autoload/world_clock.gd RATE_PLAY, 0.1 a second)
const REST_MIN := 8.0  ## game minutes a carrier props his load at the porters' rest
const CHORTEN_X := 172.0  ## a walker down the gallery goes on to the Gate Chorten's east mouth (x in the town grid)
const CHOP := "SND-216"
const CHOP_EVERY := 1.7  ## real seconds between a woodcutter's strokes
const CHOP_HEARD := 140.0
const CRACKLE := "SND-025"
const FIRE_C := Color("#FF9A4A")
const HEARD := 60.0
## the day's travellers: [game minute they set out, body, way ("down", "up", "monastery", "wood": down from the foot of
## the k-th woodcutter's path), load ("" none, "tea", "wool", "barley", "wood"), rests at the porters' rest]
const TRIPS := [[380.0, "porter", "down", "tea", true], [405.0, "porter_woman", "down", "tea", false],
		[425.0, "elder_woman", "down", "", false], [450.0, "porter", "up", "wool", false], [470.0, "monk", "monastery", "", false],
		[490.0, "porter", "down", "tea", true], [520.0, "nomad_woman", "down", "", false], [540.0, "villager_man", "monastery", "barley", false],
		[560.0, "porter_woman", "up", "", false], [585.0, "elder_man", "down", "", false], [605.0, "porter", "down", "tea", false],
		[630.0, "drover_b", "up", "", false], [660.0, "villager_woman", "monastery", "barley", false], [680.0, "porter", "up", "wool", true],
		[705.0, "elder_woman", "down", "", false], [730.0, "porter_woman", "down", "tea", true], [760.0, "monk", "up", "", false],
		[795.0, "porter", "down", "tea", false], [825.0, "townsman", "up", "", false], [850.0, "nomad_woman", "up", "", false],
		[870.0, "porter", "down", "tea", true], [900.0, "porter", "wood", "wood", false], [906.0, "villager_man", "wood", "wood", false],
		[912.0, "porter_woman", "wood", "wood", false], [940.0, "porter_woman", "up", "wool", false], [970.0, "elder_man", "down", "", false],
		[990.0, "porter", "up", "", false], [1020.0, "monk", "monastery", "", false]]
const OWN_LOAD := ["porter", "porter_woman"]  ## bodies with their own load on the back (people2/body.py props "load")
const WOMEN := ["nomad_woman", "porter_woman", "villager_woman", "elder_woman", "girl", "stall_woman", "townswoman_b"]
const WASHERS := ["drover", "villager_woman", "porter", "nomad_woman", "drover_b", "porter_woman", "villager_man", "elder_woman",
		"townsman_b", "stall_woman", "elder_man", "girl"]  ## twelve, men and women (chapter 02: "12 washers")
const MILLERS := ["villager_man", "elder_man", "house_man", "villager_man"]
const CUTTERS := ["porter", "villager_man", "porter_woman"]  ## (the wood trips' three: the same bodies as TRIPS' "wood")
const WORK := [450.0, 990.0]  ## 07:30-16:30 the washers at work
const NOON := [720.0, 765.0]  ## 12:00-12:45 their noon at the camp
const ABED := [1290.0, 360.0]  ## 21:30-06:00 in the huts
const MILL_DAY := [390.0, 1110.0]  ## 06:30-18:30 the millers at their mills
const CUT_DAY := [510.0, 890.0]  ## 08:30-14:50 the woodcutters at their trees

var way_down: PackedVector3Array  ## from the north road's end over the Zampa, down R-01 and the gallery (Godot)
var cum_down: PackedFloat32Array
var way_up: PackedVector3Array  ## the gallery's west end up to the north road's end (the mani wall on its north side)
var cum_up: PackedFloat32Array
var way_mon: PackedVector3Array  ## down R-01 to the footbridge's path, down it, over the logs, up the Yak Road's legs
var cum_mon: PackedFloat32Array
var rest_s := -1.0  ## the porters' rest along way_down and way_up
var rest_up_s := -1.0
var rest_at := Transform3D()  ## its REST socket: where a load is propped
var wood_s: Array[float] = []  ## the woodcutters' paths' feet along way_down
var places := {}  ## "wash_<k>", "water_<k>", "fire_<k>", "door_<k>", "mill_<k>", "miller_door_<k>", "cut_<k>": Transform3D
var people: Array = []  ## {key, kind, root, ap, clip, ...}
var fires: Array = []  ## [place, light, lit]
var flames: MultiMesh
var embers: MultiMesh
var chops := 0  ## a woodcutter's strokes heard, for the tests
var _mat: ShaderMaterial
var _built := false
var _mid := Vector3.ZERO
var _chop_t := 0.0
var _heard := {}


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


static func _nearest_s(p: PackedVector3Array, c: PackedFloat32Array, q: Vector3) -> float:
	var best := INF
	var out := 0.0
	for i in range(1, p.size()):
		var a := p[i - 1]
		var b := p[i]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t := clampf(Vector2(q.x - a.x, q.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var d := Vector2(a.x + ab.x * t - q.x, a.z + ab.y * t - q.z).length()
		if d < best:
			best = d
			out = c[i - 1] + (c[i] - c[i - 1]) * t
	return out


## How far along its way a traveller who set out at `start` is at minute `m` (from `s0`, at SPEED), resting `pause`
## minutes at `at` (-1: no rest); -1 before it sets out or after it has gone the way's `length`.
static func trip_s(start: float, m: float, length: float, s0 := 0.0, at := -1.0, pause := 0.0) -> float:
	if m < start:
		return -1.0
	var s := s0 + (m - start) * PER_MIN * SPEED
	if at >= 0.0 and s > at:
		var reach := start + (at - s0) / (PER_MIN * SPEED)  # the minute it reaches the rest
		s = at if m < reach + pause else s0 + (m - start - pause) * PER_MIN * SPEED
	return s if s <= length else -1.0


## What the k-th gold washer is doing at minute `m` of the day: "abed", "fire" (round the huts' fires: early and late),
## "noon" (at the camp at midday), "trough" (the first three), "water" (the next six), "camp" (the last three).
static func washer_doing(k: int, m: float) -> String:
	if m >= ABED[0] or m < ABED[1]:
		return "abed"
	if m < WORK[0] or m >= WORK[1]:
		return "fire"
	if m >= NOON[0] and m < NOON[1]:
		return "noon"
	return "trough" if k < 3 else ("water" if k < 9 else "camp")


## What a miller is doing at minute `m`: "away" outside his hours, else by turns "stones" (on the felt by them, the
## clapper and the flour to watch) and "door" (ten minutes an hour at his door), each mill's hour its own (`k`).
static func miller_doing(m: float, k: int) -> String:
	if m < MILL_DAY[0] or m >= MILL_DAY[1]:
		return "away"
	return "door" if fposmod(m + 13.0 * k, 60.0) >= 50.0 else "stones"


static func cutter_working(m: float) -> bool:
	return m >= CUT_DAY[0] and m < CUT_DAY[1]


## How lit the washers' fires are at minute `m` (0 to 1): the evening's 17:00-22:00, the morning's tea 05:30-07:30.
static func fire_lit(m: float) -> float:
	var eve := smoothstep(1020.0, 1023.0, m) * (1.0 - smoothstep(1310.0, 1325.0, m))
	var dawn := smoothstep(330.0, 333.0, m) * (1.0 - smoothstep(440.0, 450.0, m))
	return maxf(eve, dawn)


## Gathers the ways and the places from the data and the town's things (the porters' rest, the huts, the troughs, the
## mills). The count of who is there.
func build(root: Node3D) -> int:
	if not FileAccess.file_exists(ROAD) or not FileAccess.file_exists(ARRIVAL):
		return 0
	var sr: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROAD))
	var gw := func(q: Array) -> Vector3: return Town.to_godot(float(q[0]), float(q[1]), float(q[2]))
	var gallery: Array = []
	var aw: Array = (JSON.parse_string(FileAccess.get_file_as_string(ARRIVAL)) as Dictionary)["road_west"]
	for k in range(2, aw.size()):  # (from the gallery's east end, past SER-20 by its south side: the road's own `path`)
		if float(aw[k][0]) < CHORTEN_X:
			break
		gallery.append(aw[k])
	way_down = PackedVector3Array()
	var north: Array = (sr["north_path"] as Array).duplicate()
	north.reverse()
	for q in north + (sr["path"] as Array) + gallery:
		var g: Vector3 = gw.call(q)
		if way_down.is_empty() or way_down[way_down.size() - 1].distance_to(g) > 0.05:
			way_down.append(g)
	cum_down = _cum(way_down)
	way_up = PackedVector3Array()
	var back: Array = gallery.duplicate()
	back.reverse()
	for q in back + (sr["path_up"] as Array) + (sr["north_path"] as Array):
		var g: Vector3 = gw.call(q)
		if way_up.is_empty() or way_up[way_up.size() - 1].distance_to(g) > 0.05:
			way_up.append(g)
	cum_up = _cum(way_up)
	_mid = _at(way_down, cum_down, cum_down[cum_down.size() - 1] / 2.0)
	var rest := root.find_child("SER-19", true, false) as Node3D
	if rest != null:
		var rs := rest.find_child("SOCK_REST_1", true, false) as Node3D
		rest_at = rs.global_transform if rs != null else rest.global_transform
		rest_s = _nearest_s(way_down, cum_down, rest_at.origin)
		rest_up_s = _nearest_s(way_up, cum_up, rest_at.origin)
	# the monastery's way: down the road to the footbridge's path, down it, over the logs, up the Yak Road
	if FileAccess.file_exists(MILLS):
		var sm: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MILLS))
		var sp: Array = (sm["south_path"] as Array).duplicate()
		var top: Vector3 = gw.call(sp[sp.size() - 1])
		var head := _nearest_s(way_down, cum_down, top)
		way_mon = PackedVector3Array()
		for i in way_down.size():
			if cum_down[i] < head:
				way_mon.append(way_down[i])
		sp.reverse()
		var br: Dictionary = sm["bridge"]
		var th := deg_to_rad(float(br["facing"]))
		var reach := float(br["span"]) / 2.0 + 0.6
		var ends := [[float(br["at"][0]) - sin(th) * reach, float(br["at"][1]) - cos(th) * reach, float(br["deck"])],
				[float(br["at"][0]) + sin(th) * reach, float(br["at"][1]) + cos(th) * reach, float(br["deck"])]]
		var legs: Array = []
		for leg in sm["yak_road"]:
			legs += leg
		for q in sp + ends + legs:
			var g: Vector3 = gw.call(q)
			if way_mon.is_empty() or way_mon[way_mon.size() - 1].distance_to(g) > 0.05:
				way_mon.append(g)
		cum_mon = _cum(way_mon)
		var mills := root.find_child("Mills", true, false) as Node3D
		for k in (sm["mills"] as Array).size():
			var mn: Node3D = mills.find_child(String(sm["mills"][k]["id"]).validate_node_name(), false, false) if mills != null else null
			if mn == null:
				continue
			for pair in [["SOCK_MILLER_1", "mill_%d" % k], ["SOCK_DOOR_1", "miller_door_%d" % k]]:
				var so := mn.find_child(String(pair[0]), true, false) as Node3D
				if so != null:
					places[String(pair[1])] = so.global_transform
	# the washings: the troughs' heads, the water's edge, the huts' fires and doors
	for k in 3:
		var tr := root.find_child(("SER-12.t%d" % (k + 1)).validate_node_name(), true, false) as Node3D  # (a "." in a name is "_")
		var so := tr.find_child("SOCK_WASH_1", true, false) as Node3D if tr != null else null
		if so != null:
			places["wash_%d" % k] = so.global_transform
		var hut := root.find_child(("SER-12.%d" % (k + 1)).validate_node_name(), true, false) as Node3D
		if hut != null:
			for pair in [["SOCK_FIRE_1", "fire_%d" % k], ["SOCK_DOOR_1", "door_%d" % k]]:
				var so2 := hut.find_child(String(pair[0]), true, false) as Node3D
				if so2 != null:
					places[String(pair[1])] = so2.global_transform
	var spots: Array = sr.get("washers", [])
	for k in spots.size():
		var q: Array = spots[k]
		places["water_%d" % k] = Transform3D(Basis(Vector3.UP, _bearing_yaw(float(q[3]))), gw.call(q))
	# the woodcutters by their trees, and the feet of their paths on the road
	if FileAccess.file_exists(FOREST):
		var fo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FOREST))
		var cs: Array = fo.get("cutters", [])
		var ps: Array = fo.get("paths", [])
		for k in cs.size():
			places["cut_%d" % k] = Transform3D(Basis(Vector3.UP, _bearing_yaw(float(cs[k]["facing"]))), gw.call(cs[k]["at"]))
			if k < ps.size():
				var foot: Array = ps[k][ps[k].size() - 1]
				wood_s.append(_nearest_s(way_down, cum_down, Town.to_godot(float(foot[0]), float(foot[1]), 0.0)))
	people = []
	for t in TRIPS:
		people.append({"key": String(t[1]), "kind": "trip", "start": float(t[0]), "way": String(t[2]), "load": String(t[3]), "rest": bool(t[4])})
	var w_k := 0
	for t in people:  # the wood trips each from the foot of its woodcutter's path, in turn
		if String(t["way"]) == "wood":
			t["from_s"] = float(wood_s[w_k % maxi(wood_s.size(), 1)]) if not wood_s.is_empty() else 0.0
			w_k += 1
	for k in WASHERS.size():
		people.append({"key": String(WASHERS[k]), "kind": "washer", "k": k})
	for k in MILLERS.size():
		if places.has("mill_%d" % k):
			people.append({"key": String(MILLERS[k]), "kind": "miller", "k": k})
	for k in CUTTERS.size():
		if places.has("cut_%d" % k):
			people.append({"key": String(CUTTERS[k]), "kind": "cutter", "k": k})
	_fires()
	add_to_group("serchu_people")
	return people.size()


## The yaw that faces a bearing (degrees from north, clockwise): the town's y north is Godot's -z.
static func _bearing_yaw(b: float) -> float:
	var r := deg_to_rad(b)
	return atan2(sin(r), -cos(r))


static func _yaw(d: Vector3) -> float:
	return atan2(d.x, d.z) if Vector2(d.x, d.z).length() > 0.0001 else 0.0


## The washers' three fires: coals and tongues as cards, a flickering light each (as world/camp.gd's).
func _fires() -> void:
	var at: Array = []
	for k in 3:
		if places.has("fire_%d" % k):
			at.append((places["fire_%d" % k] as Transform3D).origin)
	if at.is_empty():
		return
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mat := ShaderMaterial.new()
	mat.shader = LAMP
	mat.set_shader_parameter("kind", 0)
	q.material = mat
	flames = MultiMesh.new()
	flames.transform_format = MultiMesh.TRANSFORM_3D
	flames.use_custom_data = true
	flames.mesh = q
	flames.instance_count = at.size() * 3
	var eq := QuadMesh.new()
	eq.size = Vector2.ONE
	var emat := ShaderMaterial.new()
	emat.shader = LAMP
	emat.set_shader_parameter("kind", 1)
	eq.material = emat
	embers = MultiMesh.new()
	embers.transform_format = MultiMesh.TRANSFORM_3D
	embers.use_custom_data = true
	embers.mesh = eq
	embers.instance_count = at.size()
	for k in at.size():
		var c: Vector3 = at[k]
		embers.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(0.6, 0.35, 1.0)), c + Vector3(0.0, 0.06, 0.0)))
		for j in 3:
			var h: float = [0.55, 0.44, 0.36][j]
			var off := Vector3(cos(j * 2.1 + k) * 0.1, h * 0.42, sin(j * 2.1 + k) * 0.1)
			flames.set_instance_transform(k * 3 + j, Transform3D(Basis.from_scale(Vector3(h * 0.5, h, 1.0)), c + off))
		var l := OmniLight3D.new()
		l.name = "WashersFire%d" % k
		l.light_color = FIRE_C
		l.omni_range = 10.0
		l.omni_attenuation = 1.4
		l.shadow_enabled = false
		l.light_specular = 0.2
		l.visible = false
		add_child(l)
		l.global_position = c + Vector3(0.0, 0.8, 0.0)
		fires.append([c, l, 0.0])
	for pair in [["WashersFlames", flames], ["WashersEmbers", embers]]:
		var mi := MultiMeshInstance3D.new()
		mi.name = pair[0]
		mi.multimesh = pair[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


func _bodies() -> void:
	_built = true
	_mat = ShaderMaterial.new()
	_mat.shader = PERSON
	for p in people:
		var path := "res://assets/generated/people/%s.glb" % p["key"]
		if not ResourceLoader.exists(path):
			continue
		var root: Node3D = (load(path) as PackedScene).instantiate()
		root.name = "Serchu_%s_%s" % [String(p["kind"]), String(p["key"])]
		PersonLook.apply(root, _mat)
		var ap: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Walk_Female", "Walk_Carry", "Idle_A", "Idle_FoldArms", "Sitting_Idle", "Idle_Subtle", "Sitting_Cross",
				"Idle_Talking", "Crouch_Idle", "Interact"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		add_child(root)
		root.visible = false
		var load_kind := String(p.get("load", ""))
		if p["kind"] == "cutter":
			load_kind = ""
		if load_kind != "" and not OWN_LOAD.has(String(p["key"])):  # on the back: tea bricks in yak hide, a wool bale, a
			# sack of barley for the mills, a woodcutter's sticks (a porter's body carries its own: people2/body.py's load)
			var bale := MeshInstance3D.new()
			var bm := BoxMesh.new()
			var spec: Array = {"wood": [Vector3(0.55, 0.75, 0.32), "#6B5236", 1.3, -0.25], "tea": [Vector3(0.42, 0.9, 0.28), "#3A2B20", 1.25, -0.24],
					"wool": [Vector3(0.6, 0.6, 0.45), "#CFC4AE", 1.3, -0.3], "barley": [Vector3(0.45, 0.62, 0.3), "#B59A6A", 1.25, -0.26]}.get(load_kind, [Vector3(0.5, 0.6, 0.3), "#6B5236", 1.3, -0.25])
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


func _process(dt: float) -> void:
	if way_down.is_empty():
		return
	var cam := get_viewport().get_camera_3d()
	var eye := cam.global_position if cam != null else _mid
	var on: bool = cam != null and Vector2(eye.x - _mid.x, eye.z - _mid.z).length() < SEEN
	var m := fposmod(WorldClock.minute, 1440.0)
	_fire_tick(m, eye, on)
	if not on:
		for p in people:
			if p.has("root"):
				(p["root"] as Node3D).visible = false
		return
	if not _built:
		_bodies()
	var frozen: bool = WorldClock.frozen
	var g: float = WorldClock.anim_time
	var cutting: Array = []
	for i in people.size():
		var p: Dictionary = people[i]
		if not p.has("root"):
			continue
		var r: Array = _where(p, m)  # [shown, position, yaw, clip]
		var root: Node3D = p["root"]
		root.visible = bool(r[0])
		if not bool(r[0]):
			continue
		root.global_position = r[1]
		root.rotation.y = float(r[2])
		_play(p, String(r[3]), frozen, g, i)
		if String(p["kind"]) == "cutter":
			cutting.append(r[1])
	_chops(cutting, eye, dt, frozen)


## Where `p` is at minute `m`: [shown, position, yaw, clip].
func _where(p: Dictionary, m: float) -> Array:
	var none := [false, Vector3.ZERO, 0.0, ""]
	match String(p["kind"]):
		"trip":
			var way_name := String(p["way"])
			var w: PackedVector3Array = way_up if way_name == "up" else (way_mon if way_name == "monastery" else way_down)
			var c: PackedFloat32Array = cum_up if way_name == "up" else (cum_mon if way_name == "monastery" else cum_down)
			if w.size() < 2:
				return none
			var at := -1.0
			if bool(p["rest"]):
				at = rest_up_s if way_name == "up" else rest_s
			var s := trip_s(float(p["start"]), m, c[c.size() - 1], float(p.get("from_s", 0.0)), at, REST_MIN)
			if s < 0.0:
				return none
			if at >= 0.0 and is_equal_approx(s, at) and (m - float(p["start"])) * PER_MIN * SPEED > at - float(p.get("from_s", 0.0)):
				var q := rest_at.origin  # propped against the ledge, facing the road
				return [true, q, rest_at.basis.get_euler().y, "Idle_A"]
			var q := _at(w, c, s)
			var ahead := _at(w, c, s + 0.5)
			return [true, q, _yaw(ahead - q), _walk(p)]
		"washer":
			var k := int(p["k"])
			var doing := washer_doing(k, m)
			match doing:
				"abed":
					return none
				"trough":
					if not places.has("wash_%d" % k):
						return none
					var t: Transform3D = places["wash_%d" % k]
					return [true, t.origin, t.basis.get_euler().y, "Interact"]
				"water":
					if not places.has("water_%d" % (k - 3)):
						return none
					var t: Transform3D = places["water_%d" % (k - 3)]
					return [true, t.origin, t.basis.get_euler().y, "Crouch_Idle"]
				_:  # round a hut's fire (its morning and evening, its noon), or about the huts by day
					var f := k % 3
					if not places.has("fire_%d" % f):
						return none
					var c: Vector3 = (places["fire_%d" % f] as Transform3D).origin
					var slot := k / 3  # four round each fire
					var a := float(slot) * TAU / 4.0 + 0.6 * f
					var r := 1.35
					var q := c + Vector3(cos(a) * r, 0.0, sin(a) * r)
					var clip := "Sitting_Cross" if slot != 3 else ("Crouch_Idle" if doing == "fire" else "Idle_A")
					if doing == "camp":  # by day the camp's three: one at each hut, sat by its door
						var d: Vector3 = (places.get("door_%d" % f, places["fire_%d" % f]) as Transform3D).origin
						q = d + (c - d).normalized() * 0.5
						return [true, q, _yaw(c - q), "Sitting_Idle"]
					return [true, q, _yaw(c - q), clip]
		"miller":
			var k := int(p["k"])
			match miller_doing(m, k):
				"stones":
					var t: Transform3D = places["mill_%d" % k]
					return [true, t.origin, t.basis.get_euler().y, "Sitting_Cross"]
				"door":
					if not places.has("miller_door_%d" % k):
						return none
					var t: Transform3D = places["miller_door_%d" % k]
					return [true, t.origin, t.basis.get_euler().y + PI, "Idle_A"]  # (out of his door, looking out)
			return none
		"cutter":
			if not cutter_working(m):
				return none
			var t: Transform3D = places["cut_%d" % int(p["k"])]
			return [true, t.origin, t.basis.get_euler().y, "Interact"]
	return none


func _walk(p: Dictionary) -> String:
	if String(p.get("load", "")) != "":
		return "Walk_Carry"
	return "Walk_Female" if WOMEN.has(String(p["key"])) else "Walk"


func _play(p: Dictionary, clip: String, frozen: bool, g: float, i: int) -> void:
	var ap: AnimationPlayer = p["ap"]
	if not ap.has_animation(clip):
		clip = "Walk" if clip.begins_with("Walk") and ap.has_animation("Walk") else ("Sitting_Idle" if clip.begins_with("Sitting") and ap.has_animation("Sitting_Idle") else "Idle_A")
	if String(p["clip"]) != clip:
		ap.play(clip, 0.0 if frozen or String(p["clip"]) == "" else 0.3)
		p["clip"] = clip
	if frozen:  # the stills: the pose from the animation clock
		ap.speed_scale = 0.0
		ap.seek(fposmod(g + i * 0.41, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = 1.0


## The woodcutters' axes: a stroke from one of them every CHOP_EVERY seconds while the camera is near.
func _chops(cutting: Array, eye: Vector3, dt: float, frozen: bool) -> void:
	if cutting.is_empty() or frozen:
		return
	_chop_t += dt
	if _chop_t < CHOP_EVERY / float(cutting.size()):
		return
	_chop_t = 0.0
	var k := chops % cutting.size()
	var at: Vector3 = cutting[k]
	if at.distance_to(eye) < CHOP_HEARD and is_instance_valid(AudioDirector):
		AudioDirector.play(CHOP, at + Vector3(0.0, 1.2, 0.0))
		chops += 1


## The washers' fires: lit by the clock, flickering, their crackle heard near.
func _fire_tick(m: float, eye: Vector3, on: bool) -> void:
	if fires.is_empty():
		return
	var lit := fire_lit(m) if on else 0.0
	var t := Time.get_ticks_msec() / 1000.0
	for k in fires.size():
		var f: Array = fires[k]
		f[2] = lit
		embers.set_instance_custom_data(k, Color(lit, 30.0 + k, 0.0, 0.0))
		for j in 3:
			flames.set_instance_custom_data(k * 3 + j, Color(lit, 40.0 + float(k * 3 + j), 0.0, 0.0))
		var l: OmniLight3D = f[1]
		l.visible = lit > 0.01
		l.light_energy = 3.0 * lit * (0.84 + 0.1 * sin(t * 7.3 + k) + 0.06 * sin(t * 12.1 + 1.3 * k))
		var near: bool = (f[0] as Vector3).distance_to(eye) < HEARD
		var key := "washers_fire_%d" % k
		if is_instance_valid(AudioDirector) and AudioDirector.sound != null:
			if lit > 0.5 and near and not _heard.has(key):
				AudioDirector.sound.loop_start(key, CRACKLE, f[0])
				_heard[key] = true
			elif (lit <= 0.5 or not near) and _heard.has(key):
				AudioDirector.sound.loop_stop(key)
				_heard.erase(key)


func _exit_tree() -> void:
	if is_instance_valid(AudioDirector) and AudioDirector.sound != null:
		for key in _heard:
			AudioDirector.sound.loop_stop(key)
	_heard.clear()
