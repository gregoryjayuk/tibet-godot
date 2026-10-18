extends Node3D
## The town's prayer flags (plan chapter 03, 2.5 and 14.3; chapter 02's chortens, darchen, flag spans and cairns; M1
## sprint 8, step 2, after Greg's walk, 27 Sep 2026: "when do we get the fluttering prayer flags ... one of the nice
## things when I first saw the street demo"; "don't make the flags or other things too uniform"; "would every single
## house have had them?"; and at 19:39: "I was expecting more flags to be anchored to the ground like in the street demo
## ... around the shrines ... and even in the mountains ... wouldn't some houses not have poles, wouldn't some attach to
## the windows or somewhere else and anchor on the floor, wouldn't there be some that are not anchored correctly and one
## end is just flying about"). Added by world/town.gd once the houses stand.
## Every house flies its flags its own way, seeded by its name, or not at all: a pole on the back of the roof with its
## bundle; two poles and a string between them; a juniper branch on a pier with a few flags stuck in; a string from the
## parapet down to a stake in the lane; one from an upper window across the lane to the house opposite; the devout
## several poles with strings to the ground; a string torn loose, its free end streaming; a house its people have left,
## bare poles and grey rags. Round every chorten strings run from its top down to the ground like a tent's; the darchen
## fly their printed banners with strings to the ground about them; the cairns on the heights are webs of flags. The
## flags are mostly eight months since Losar but still their colours, some new, a few rags. All of it is a few
## MultiMeshes per 128 m cell, the flutter in the vertex shader (shaders/flags_mm.gdshader).

const SHADER := preload("res://shaders/flags_mm.gdshader")
const Horizon := preload("res://world/horizon.gd")
const Households := preload("res://world/households.gd")
const CELL := 128.0
const ORDER := ["#2B4F9E", "#EFEBDD", "#B0302A", "#3E7F4E", "#E1AE2E"]  ## blue, white, red, green, yellow: sky, wind, fire, water, earth
const BLEACHED := "#CFC9BA"
const WOOD := "#5F3E28"
const JUNIPER := "#44713C"
const CORD := "#D8D2C4"
const STONE := "#9A9385"
const WIND := Vector3(0.8, 0.0, -0.6)  ## the afternoon's up-valley wind, roughly (the flags stream down it)
const GORGE := "res://data/gorge_stair.json"  ## the six strings across the gorge, RNG-06 (tools/town/gorge_stair.py `flags`)
const GORGE_SOUND := "SND-015"  ## the flag mass of the gorge's spans (a synthesised stand-in, tools/audio/synth.py `flag_mass`)
const POLE_OUT := 1.2  ## a cantilever bridge's corner poles past its deck's ends, and their tops over the deck (kit/infra.py)
const POLE_TOP := 3.9
const GORGE_POLE := 3.0  ## the planner's anchors stand this far over the ground (tools/town/gorge_stair.py FLAG_POLE)
## Each house's way, and its share (Greg: not the same everywhere, and not on every house)
const STYLES := [["none", 12], ["bundle", 20], ["pair", 11], ["juniper", 9], ["to_ground", 15], ["across", 12], ["devout", 8], ["torn", 8], ["left", 5]]
const SHRINES := ["SHL-17", "TOD-21", "RNG-12", "SER-20", "FER-07", "SER-01", "THG-08", "PHK-01", "SHL-14"]  ## chortens with strings round them, and the Lukhang spring's klu khang from its pole
const CAIRNS := {"DUR-01": [1120.0, -1000.0, 3165.0], "THG-04": [480.0, 700.0, 3002.0], "SER-14": [1000.0, -470.0, 2775.0]}  ## lhatse (chapter 02)

var counts := {"houses": 0, "poles": 0, "flags": 0, "lines": 0, "banners": 0, "shrines": 0, "cairns": 0}  ## for the tests and the log
var per_house := {}  ## house name -> [style, poles, flags], for the tests: no two alike
var _cells := {}  ## "cx|cz" -> {kind: [[Transform3D, Color]]}
var _flag_mesh: ArrayMesh
var _rects: Array = []  ## footprints in the town grid [cx, cy, half w, half d, rot], for ground anchors
var _ground_ok := false
var _root: Node3D
var _town: GDScript
var _wins: Array = []  ## [position, house] of every upper window, for strings across a lane
var _kept := {}  ## the houses someone lives in or the player enters: never left (world/households.gd)
var _households: Node  ## world/households.gd, built: its left houses' bare poles, its shut ones' flags unrenewed
var rustle: Array = []  ## where the flags are heard (SND-013): [position, weight], each string's middle, bundle and
## banner, merged by build() into clusters of about 10 m, each a looping rustle the AudioDirector voices when near
var gorge_rustle: Array = []  ## the gorge's spans' middles, each heard as SND-015
var _rustle_keys: Array = []


func build(root: Node3D, households: Node = null) -> Dictionary:
	_root = root
	_households = households
	_town = load("res://world/town.gd")
	_flag_mesh = _flag()
	_footprints()
	_ground_ok = not is_nan(Horizon.ground_at(0.0, 0.0)) or Horizon.load_globals()
	_kept = Households.kept()
	var houses := {}  ## house node -> {PIER, CORNER, WIN: [Node3D]}
	for kind in ["PIER", "CORNER", "WIN"]:
		for m in root.find_children("SOCK_%s_*" % kind, "Node3D", true, false):
			var h := _house_of(m as Node3D, root)
			if h == null or not String(h.name).begins_with("H-"):
				continue  # the town's houses; the halls, the chortens and the compounds have their own
			if not houses.has(h):
				houses[h] = {"PIER": [], "CORNER": [], "WIN": []}
			(houses[h][kind] as Array).append(m)
			if kind == "WIN" and (m as Node3D).global_position.y - h.global_position.y > 3.0:
				_wins.append([(m as Node3D).global_position, h])
	var keys := houses.keys()
	keys.sort_custom(func(a, b): return String(a.name) < String(b.name))
	for h in keys:
		_house(h as Node3D, houses[h])
	for id in SHRINES:
		var n := root.get_node_or_null(id) as Node3D
		if n != null:
			_shrine(n, id)
	var masts := root.find_children("SOCK_MAST_*", "Node3D", true, false)
	masts.sort_custom(func(a, b): return String((a as Node).get_path()) < String((b as Node).get_path()))
	for m in masts:
		_darchen(m as Node3D)
	for id in CAIRNS:
		var at: Array = CAIRNS[id]
		var moved: Dictionary = _town.call("serchu_places")
		if moved.has(id):  # SER-14 beside the Serchu road where its cairn stands, not on the gazetteer's point, which the road
			# now runs over (tools/terrain/serchu_road.py; M2 sprint 12, step 3)
			at = [float(moved[id]["at"][0]), float(moved[id]["at"][1]), float(moved[id]["level"])]
		_cairn(id, at)
	for b in root.get_tree().get_nodes_in_group("bridges"):
		_bridge(b as Node3D)
	if FileAccess.file_exists(GORGE):
		for sp in (JSON.parse_string(FileAccess.get_file_as_string(GORGE)) as Dictionary).get("flags", []):
			_gorge_span(sp)
	_commit()
	_heard()
	return counts


## The flags heard: their rustle points merged into clusters (a house's poles and strings, a banner and its web), each a
## loop of SND-013 that the AudioDirector voices when the player is near, louder where more flags fly.
func _heard() -> void:
	var merged: Array = []  ## [position (weighted mean), weight]
	for r in rustle:
		var p: Vector3 = r[0]
		var w: float = r[1]
		var hit := false
		for c in merged:
			if (c[0] as Vector3).distance_to(p) < 10.0:
				c[0] = ((c[0] as Vector3) * float(c[1]) + p * w) / (float(c[1]) + w)
				c[1] = float(c[1]) + w
				hit = true
				break
		if not hit:
			merged.append([p, w])
	rustle = merged
	var sd: Node = AudioDirector.sound if is_instance_valid(AudioDirector) else null
	if sd == null:
		return
	for k in rustle.size():
		var key := "flags_%d_%d" % [get_instance_id(), k]
		var db := -6.0 + 6.0 * log(maxf(float(rustle[k][1]), 1.0) / 8.0) / log(10.0)  # 8 flags -6 dB, 80 flags 0 dB
		sd.call("loop_start", key, "SND-013", rustle[k][0], clampf(db, -8.0, 0.0))
		_rustle_keys.append(key)
	for k in gorge_rustle.size():  # the gorge's spans, each a mass of flags snapping as one over the gorge
		var key := "gorge_flags_%d_%d" % [get_instance_id(), k]
		sd.call("loop_start", key, GORGE_SOUND, gorge_rustle[k], 0.0)
		_rustle_keys.append(key)


func _exit_tree() -> void:
	var sd: Node = AudioDirector.sound if is_instance_valid(AudioDirector) else null
	if sd != null:
		for key in _rustle_keys:
			sd.call("loop_stop", key)
	_rustle_keys.clear()


# --- the houses ----------------------------------------------------------------------------------------------------

func _house(h: Node3D, socks: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(h.name))
	counts["houses"] += 1
	var style := _pick(rng)
	if style == "left" and (_kept.has(String(h.name)) or _households != null):  # a walker's home or a house to enter is lived
		style = "bundle"  # in (IMP-019); with the households, who has left is theirs to say
	var shut := false
	if _households != null:
		shut = bool(_households.call("is_shut", String(h.name)))
		if bool(_households.call("is_left", String(h.name))):
			style = "left"
	var f0: int = counts["flags"]
	var p0: int = counts["poles"]
	var fresh := rng.randf()
	# still their colours: most eight months since Losar and a little faded, a tenth new, a tenth old rags; a shut house's
	# not renewed at Losar, its household away: old rags
	var age := 0.03 if fresh < 0.1 else (rng.randf_range(0.7, 0.9) if fresh > 0.9 else rng.randf_range(0.15, 0.45))
	if shut:
		age = maxf(age, 0.8)
	var piers: Array = (socks["PIER"] as Array).duplicate()
	piers.sort_custom(func(a, b): return (a as Node3D).global_position.z < (b as Node3D).global_position.z)  # the back first
	var corners: Array = socks["CORNER"]
	var wins: Array = (socks["WIN"] as Array).filter(func(w): return (w as Node3D).global_position.y - h.global_position.y > 3.0)
	var centre := h.global_position
	match style:
		"bundle", "pair", "devout":
			var n := 1 if style == "bundle" else (2 if style == "pair" else rng.randi_range(3, 4))
			var tops: Array = []
			for k in mini(n, piers.size()):
				var top := _pole((piers[k] as Node3D).global_position, rng, rng.randf() < 0.7)
				_bundle(top, rng.randi_range(6, 16), age, rng)
				tops.append(top)
			if tops.size() >= 2:
				_string(tops[0], tops[1], age, rng)
			if style == "devout" and tops.size() >= 3:
				_string(tops[1], tops[2], age, rng)
			for k in tops.size():  # down to the ground: the bundle's house often, the devout's always
				if style == "devout" or rng.randf() < 0.4:
					_to_ground(tops[k], centre, age, rng)
		"juniper":
			if not piers.is_empty():
				var base := (piers[0] as Node3D).global_position
				var s := rng.randf_range(0.35, 0.55)
				_add("juniper", Transform3D(Basis().scaled(Vector3(s, s * 0.9, s)), base + Vector3(0.0, s * 0.5, 0.0)), _col(JUNIPER, rng.randf_range(-0.1, 0.1)))
				_bundle(base + Vector3(0.0, s * 1.1, 0.0), rng.randi_range(3, 7), age, rng, 0.35)
		"to_ground":
			if not corners.is_empty():
				_to_ground((corners[rng.randi() % corners.size()] as Node3D).global_position + Vector3(0.0, 1.0, 0.0), centre, age, rng)
				if rng.randf() < 0.3:
					_to_ground((corners[rng.randi() % corners.size()] as Node3D).global_position + Vector3(0.0, 1.0, 0.0), centre, age, rng)
		"across":
			var from := centre
			if not wins.is_empty() and rng.randf() < 0.6:
				from = (wins[rng.randi() % wins.size()] as Node3D).global_position + Vector3(0.0, 0.8, 0.0)
			elif not corners.is_empty():
				from = (corners[rng.randi() % corners.size()] as Node3D).global_position + Vector3(0.0, 1.0, 0.0)
			_across(from, h, age, rng)
		"torn":
			if not corners.is_empty():
				_loose((corners[rng.randi() % corners.size()] as Node3D).global_position + Vector3(0.0, 1.0, 0.0), age, rng)
			if not piers.is_empty() and rng.randf() < 0.5:
				_pole((piers[0] as Node3D).global_position, rng, false)  # its bundle long gone
		"left":
			for k in mini(rng.randi_range(1, 2), piers.size()):
				var top := _pole((piers[k] as Node3D).global_position, rng, false)
				if rng.randf() < 0.5:
					_bundle(top, rng.randi_range(2, 5), 0.95, rng)
	per_house[String(h.name)] = [style, int(counts["poles"]) - p0, int(counts["flags"]) - f0]


func _pick(rng: RandomNumberGenerator) -> String:
	var total := 0
	for s in STYLES:
		total += int(s[1])
	var r := rng.randi_range(0, total - 1)
	for s in STYLES:
		r -= int(s[1])
		if r < 0:
			return String(s[0])
	return "none"


# --- the shrines, the darchen and the cairns ---------------------------------------------------------------------

## Strings from a chorten's top down to the ground all round it, like a tent's ropes.
func _shrine(n: Node3D, id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var top := _top_of(n)
	if top == Vector3.INF:
		return
	counts["shrines"] += 1
	var k := rng.randi_range(4, 8)
	var a0 := rng.randf() * TAU
	for i in k:
		var a := a0 + TAU * i / k + rng.randf_range(-0.25, 0.25)
		_to_ground(top - Vector3(0.0, rng.randf_range(0.2, 0.8), 0.0), top - Vector3(cos(a), 0.0, sin(a)), rng.randf_range(0.1, 0.5), rng, 7.0, 16.0)


## A darchen: its long printed banner in sections down the pole, and strings from its top to the ground about it.
func _darchen(m: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	var owner_ := _house_of(m, _root)
	rng.seed = hash((String(owner_.name) if owner_ != null else "") + String(m.name))
	counts["banners"] += 1
	var top := m.global_position
	var wind := WIND.normalized().rotated(Vector3.UP, rng.randf_range(-0.3, 0.3))
	var g := _ground(top)
	var great := not is_nan(g) and top.y - g > 13.0  # a monastery courtyard's great darchen (MON-02's 15 m): its banner as
	# long and wide as the pole carries (M3 sprint 3, step 2; at the town's 0.6 m it had read as a thread from below)
	var sections := rng.randi_range(7, 9) if great else rng.randi_range(4, 6)
	rustle.append([top - Vector3(0.0, 2.0, 0.0), float(sections) * 3.0])  # the banner's big cloth
	var z := 0.35
	var start := rng.randi_range(0, 4)
	var fly := rng.randf_range(1.0, 1.3) if great else rng.randf_range(0.55, 0.8)
	for k in sections:
		var tall := rng.randf_range(0.9, 1.3)
		_flag_at(top - Vector3(0.0, z, 0.0), Vector3.DOWN, wind, tall, fly, ORDER[(start + k) % 5], rng.randf_range(0.1, 0.4), rng)
		z += tall + 0.04
	if great:  # its banner alone: a string to the ground from its top would cross the ranges round its courtyard
		return
	for i in rng.randi_range(3, 6):
		var a := rng.randf() * TAU
		_to_ground(top - Vector3(0.0, 0.3, 0.0), top - Vector3(cos(a), 0.0, sin(a)), rng.randf_range(0.1, 0.5), rng, 8.0, 18.0)


## A lhatse on the heights: a cairn of stones, poles bound together in it, and a web of flags to the ground all round.
func _cairn(id: String, at: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var base: Vector3 = _town.to_godot(float(at[0]), float(at[1]), float(at[2]))
	var g := _ground(base)
	if not is_nan(g):
		base.y = g
	counts["cairns"] += 1
	for k in rng.randi_range(9, 16):  # the stones
		var s := rng.randf_range(0.25, 0.55)
		var off := Vector3(rng.randf_range(-0.9, 0.9), rng.randf_range(0.0, 1.0), rng.randf_range(-0.9, 0.9)) * (1.0 - float(k) / 20.0)
		_add("stone", Transform3D(Basis().scaled(Vector3(s, s * 0.7, s)), base + off + Vector3(0.0, s * 0.3, 0.0)), _col(STONE, rng.randf_range(-0.15, 0.1)), "far")
	var tops: Array = []
	for k in rng.randi_range(2, 4):
		tops.append(_pole(base + Vector3(rng.randf_range(-0.3, 0.3), 0.6, rng.randf_range(-0.3, 0.3)), rng, false, "far"))
	for t in tops:
		_bundle(t, rng.randi_range(8, 14), rng.randf_range(0.2, 0.8), rng, 1.0, "far")
	for i in rng.randi_range(8, 14):
		var a := rng.randf() * TAU
		_to_ground((tops[i % tops.size()] as Vector3) - Vector3(0.0, 0.2, 0.0), base - Vector3(cos(a), 0.0, sin(a)), rng.randf_range(0.1, 0.8), rng, 5.0, 12.0, "far")


# --- strings -------------------------------------------------------------------------------------------------------

## A string from `from` down to the ground away from `away_from`, `lo`-`hi` m out, on free ground (outside every
## footprint), falling 1.5-18 m; tied to a stake or a stone. Tries a few ways round before giving up.
func _to_ground(from: Vector3, away_from: Vector3, age: float, rng: RandomNumberGenerator, lo := 6.0, hi := 18.0, cell_kind := "") -> void:
	var out := Vector3(from.x - away_from.x, 0.0, from.z - away_from.z)
	if out.length() < 0.1:
		out = Vector3(1.0, 0.0, 0.0)
	out = out.normalized()
	for attempt in 6:
		var dir := out.rotated(Vector3.UP, rng.randf_range(-0.9, 0.9))
		var p := from + dir * rng.randf_range(lo, hi)
		var g := _ground(p)
		if is_nan(g) or _inside(p) or from.y - g < 1.5 or from.y - g > 18.0:
			continue
		p.y = g + 0.3
		if rng.randf() < 0.6:  # a stake, or a stone on the cord's end
			_add("pole", Transform3D(Basis().scaled(Vector3(0.05, 0.6, 0.05)), Vector3(p.x, g + 0.3, p.z)), _col(WOOD, rng.randf_range(-0.1, 0.1)), cell_kind)
		else:
			var s := rng.randf_range(0.18, 0.3)
			_add("stone", Transform3D(Basis().scaled(Vector3(s, s * 0.7, s)), Vector3(p.x, g + s * 0.3, p.z)), _col(STONE, rng.randf_range(-0.15, 0.1)), cell_kind)
			p.y = g + s * 0.5
		_string(from, p, age, rng, cell_kind)
		return


## A string from `from` across the lane to an upper window of another house 5-13 m off, within 3 m of its height; to
## the ground if there is none.
func _across(from: Vector3, own: Node3D, age: float, rng: RandomNumberGenerator) -> void:
	var cands: Array = []
	for w in _wins:
		if w[1] == own:
			continue
		var p: Vector3 = (w[0] as Vector3) + Vector3(0.0, 0.8, 0.0)
		var d := Vector2(p.x - from.x, p.z - from.z).length()
		if d >= 5.0 and d <= 13.0 and absf(p.y - from.y) <= 3.0:
			cands.append(p)
	if cands.is_empty():
		_to_ground(from, own.global_position, age, rng)
		return
	_string(from, cands[rng.randi() % cands.size()], age, rng)


## A string torn loose at one end: tied at `tie`, its free part drooping and streaming down the wind, swaying whole.
func _loose(tie: Vector3, age: float, rng: RandomNumberGenerator) -> void:
	counts["lines"] += 1
	var length := rng.randf_range(3.5, 8.0)
	var wind := WIND.normalized().rotated(Vector3.UP, rng.randf_range(-0.6, 0.6))
	var spacing := rng.randf_range(0.3, 0.42)
	var n := int(length / spacing)
	var w := rng.randf_range(0.24, 0.34)
	for k in n:
		var t := (k + 0.5) / n
		var p := tie + wind * length * t * 0.8 + Vector3.DOWN * length * 0.55 * pow(t, 1.6)
		var hang := (Vector3.DOWN * 0.6 + wind).normalized()
		_flag_at(p, wind.cross(Vector3.UP).normalized(), hang, w, w * rng.randf_range(1.1, 1.35), ORDER[k % 5], age, rng, t)


## One string between two points: its cord in a catenary, flags tied along it in the colours' order, some torn away.
func _string(a: Vector3, b: Vector3, age: float, rng: RandomNumberGenerator, cell_kind := "", sag_given := -1.0) -> void:
	counts["lines"] += 1
	var length := a.distance_to(b)
	var sag := sag_given if sag_given >= 0.0 else length * rng.randf_range(0.03, 0.08) * (1.0 + 0.5 * age)
	var spacing := rng.randf_range(0.28, 0.44)
	var n := maxi(3, int(length / spacing))
	var w := rng.randf_range(0.24, 0.38)
	var h := w * rng.randf_range(1.1, 1.35)
	var side := (b - a).normalized()
	var at := func(t: float) -> Vector3: return a.lerp(b, t) - Vector3(0.0, 4.0 * sag * t * (1.0 - t), 0.0)
	rustle.append([at.call(0.5), float(n)])
	var segs := maxi(4, int(length / 1.5))
	for k in segs:
		var p0: Vector3 = at.call(float(k) / segs)
		var p1: Vector3 = at.call(float(k + 1) / segs)
		var d := p1 - p0
		var up := d.normalized()
		_add("cord", Transform3D(Basis(_perp(up) * 0.014, d, up.cross(_perp(up)).normalized() * 0.014), (p0 + p1) * 0.5), _col(CORD, -0.3 * age), cell_kind)
	var gaps := age * rng.randf_range(0.05, 0.35)
	var start := rng.randi_range(0, 4)
	for k in n:
		if rng.randf() < gaps:
			continue  # torn away
		var t := (k + 0.5) / n
		var hang := (Vector3.DOWN + WIND.normalized() * rng.randf_range(0.1, 0.4)).normalized()
		_flag_at(at.call(t), side, hang, w, h * (1.0 - 0.35 * _shred(age, rng)), ORDER[(start + k) % 5], age, rng, 0.0, cell_kind)


## A string across the gorge (RNG-06, chapter 02: from Tödé's rim to the monastery's face, renewed at Losar; chapter 08,
## V-17): a pole at each end where the planner stood it, the string between their tops sagging as it found room, its
## flags eight months old; drawn at any distance (the far cell), heard as one with the others (SND-015).
func _gorge_span(sp: Dictionary) -> void:
	var a: Array = sp["a"]
	var b: Array = sp["b"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("gorge_%.1f_%.1f" % [float(a[0]), float(a[1])])
	var ta := _pole(_town.call("to_godot", float(a[0]), float(a[1]), float(a[2]) - GORGE_POLE), rng, false, "far")
	var tb := _pole(_town.call("to_godot", float(b[0]), float(b[1]), float(b[2]) - GORGE_POLE), rng, false, "far")
	var n0 := rustle.size()
	_string(ta, tb, rng.randf_range(0.25, 0.5), rng, "far", float(sp["sag"]))
	if rustle.size() > n0:  # (its rustle is the span's own sound, not the house flags')
		gorge_rustle.append(rustle[rustle.size() - 1][0])
		rustle.resize(n0)
	counts["gorge"] = int(counts.get("gorge", 0)) + 1


## A rope bridge's flags (IMP-027): a string tied along one of its hand ropes, sagging as the rope does, its flags
## hanging outside it, renewed lately: prayers for the crossing.
func _bridge(b: Node3D) -> void:
	var s1 := b.find_child("SOCK_BRIDGE_1", true, false) as Node3D
	var s2 := b.find_child("SOCK_BRIDGE_2", true, false) as Node3D
	if s1 == null or s2 == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(b.name))
	if b.has_meta("poles"):  # a cantilever bridge's tall pole at each corner (../tibet-blender kit/infra.py: `poles` out
		# from its middle, POLE_OUT past its deck's ends, POLE_TOP high): a string end to end along each side over the deck
		# and one across from corner to corner, renewed lately (chapter 03: "a tall pole at each corner for the flags strung
		# over it"; chapter 08, V-09: flags overhead)
		var off := float(b.get_meta("poles"))
		var along := (s2.global_position - s1.global_position).normalized()
		var across := b.global_transform.basis.x.normalized()
		var top := func(s: Vector3, out: float, sx: float) -> Vector3: return s + along * out + across * (sx * off) + Vector3(0.0, POLE_TOP, 0.0)
		var span := s1.global_position.distance_to(s2.global_position) + 2.0 * POLE_OUT
		for sx in [1.0, -1.0]:
			_string(top.call(s1.global_position, -POLE_OUT, sx), top.call(s2.global_position, POLE_OUT, sx), rng.randf_range(0.05, 0.3), rng, "", span * rng.randf_range(0.05, 0.07))
		var d := 1.0 if rng.randf() < 0.5 else -1.0
		_string(top.call(s1.global_position, -POLE_OUT, d), top.call(s2.global_position, POLE_OUT, -d), rng.randf_range(0.05, 0.3), rng, "", span * rng.randf_range(0.06, 0.08))
	if b.has_meta("hand") or not b.has_meta("poles"):
		var hand := float(b.get_meta("hand", 0.62))  # the hand rope's (or chain's) way out from the middle
		var out := b.global_transform.basis.x.normalized() * (hand if rng.randf() < 0.5 else -hand)
		var up := Vector3(0.0, 1.0, 0.0)
		_string(s1.global_position + out + up, s2.global_position + out + up, 0.15, rng, "", float(b.get_meta("sag", 0.5)))
	counts["bridges"] = int(counts.get("bridges", 0)) + 1


# --- poles and bundles ---------------------------------------------------------------------------------------------

## A pole on a pier: 1.8-3.2 m, leaning a little its own way; juniper at its foot or not. Returns its top.
func _pole(base: Vector3, rng: RandomNumberGenerator, juniper: bool, cell_kind := "") -> Vector3:
	counts["poles"] += 1
	var h := rng.randf_range(1.8, 3.2)
	var lean := Vector3(rng.randf_range(-0.09, 0.09), 1.0, rng.randf_range(-0.09, 0.09)).normalized()
	var r := rng.randf_range(0.035, 0.055)
	var up := lean * h
	_add("pole", Transform3D(Basis(_perp(lean) * r * 2.0, up, lean.cross(_perp(lean)).normalized() * r * 2.0), base + up * 0.5), _col(WOOD, rng.randf_range(-0.08, 0.08)), cell_kind)
	if juniper:
		var s := rng.randf_range(0.28, 0.5)
		_add("juniper", Transform3D(Basis().scaled(Vector3(s, s * rng.randf_range(0.6, 0.9), s)), base + Vector3(0.0, s * 0.35, 0.0)), _col(JUNIPER, rng.randf_range(-0.12, 0.08)), cell_kind)
	return base + up


## A bundle of long flags tied near a pole's top (or a branch's), streaming down the wind and falling away.
func _bundle(top: Vector3, n: int, age: float, rng: RandomNumberGenerator, scale := 1.0, cell_kind := "") -> void:
	rustle.append([top, float(n) * scale])
	var wind := WIND.normalized().rotated(Vector3.UP, rng.randf_range(-0.5, 0.5))
	for k in n:
		var a := wind.rotated(Vector3.UP, rng.randf_range(-0.9, 0.9))
		var tie := top - Vector3(0.0, rng.randf_range(0.02, 0.45) * scale, 0.0) + a * 0.04
		var hang := (a * rng.randf_range(0.35, 0.8) + Vector3.DOWN).normalized()
		var length := rng.randf_range(0.8, 1.8) * scale * (1.0 - 0.45 * _shred(age, rng))
		var width := rng.randf_range(0.2, 0.34) * maxf(scale, 0.6)
		var side := hang.cross(Vector3.UP).normalized() if absf(hang.y) < 0.99 else Vector3.RIGHT
		_flag_at(tie, side, hang, width, length, ORDER[k % 5], age, rng, 0.0, cell_kind)


# --- the pieces ----------------------------------------------------------------------------------------------------

## A flag tied along `side` at `tie`, hanging `length` along `hang`, `width` wide; its colour faded by `age` towards a
## paler version of itself; `sway` (0-1) moves its tie too, for a string loose at one end.
func _flag_at(tie: Vector3, side: Vector3, hang: Vector3, width: float, length: float, hexc: String, age: float, rng: RandomNumberGenerator, sway := 0.0, cell_kind := "") -> void:
	counts["flags"] += 1
	var x := side.normalized() * width
	var y := -hang.normalized() * length
	var z := x.cross(y).normalized()
	var f := clampf(age * rng.randf_range(0.8, 1.1), 0.0, 0.95)
	var c0 := Color(hexc)
	var c := Color.from_hsv(c0.h, c0.s * (1.0 - 0.5 * f), minf(1.0, c0.v * (1.0 + 0.3 * f)))
	if f > 0.8:
		c = c.lerp(Color(BLEACHED), (f - 0.8) * 4.0)
	var lc := c.srgb_to_linear()
	# INSTANCE_CUSTOM.a: its phase in the fraction; how much its tie sways (0-3) in the whole part
	_add("flag", Transform3D(Basis(x, y, z), tie), Color(lc.r, lc.g, lc.b, floorf(clampf(sway, 0.0, 1.0) * 3.0) + rng.randf() * 0.999), cell_kind)


func _shred(age: float, rng: RandomNumberGenerator) -> float:
	return clampf(age * age * rng.randf_range(0.5, 1.3), 0.0, 1.0)


func _perp(v: Vector3) -> Vector3:
	return v.cross(Vector3.FORWARD).normalized() if absf(v.dot(Vector3.FORWARD)) < 0.9 else v.cross(Vector3.RIGHT).normalized()


func _col(hexc: String, shade: float) -> Color:
	var c := Color(hexc).srgb_to_linear()
	c = c.lightened(shade) if shade > 0.0 else c.darkened(-shade)
	return Color(c.r, c.g, c.b, 0.0)


## The ground's height at `p` (Godot), NaN where unknown.
func _ground(p: Vector3) -> float:
	return Horizon.ground_at(p.x, -p.z) if _ground_ok else NAN


## Whether `p` (Godot) stands within a building's footprint, a metre's margin round it.
func _inside(p: Vector3) -> bool:
	var q := Vector2(p.x, -p.z)
	for r in _rects:
		var d := (q - Vector2(float(r[0]), float(r[1]))).rotated(-float(r[4]))
		if absf(d.x) < float(r[2]) + 1.0 and absf(d.y) < float(r[3]) + 1.0:
			return true
	return false


func _footprints() -> void:
	for f in ["res://data/town.json", "res://data/town_generic.json"]:
		if not FileAccess.file_exists(f):
			continue
		var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(f))
		for b in t.get("buildings", []) + t.get("houses", []):
			var p: Array = b.get("pos", [])
			var fp = b.get("footprint")
			if p.size() < 2 or not (fp is Array) or (fp as Array).size() < 2:
				continue
			var rot = b.get("rot_deg")
			_rects.append([float(p[0]), float(p[1]), float(fp[0]) / 2.0, float(fp[1]) / 2.0, deg_to_rad(float(rot) if rot != null else 0.0)])


## The top of a building's drawn bounds (its finial), or INF.
func _top_of(n: Node3D) -> Vector3:
	var best := Vector3.INF
	for mi in n.find_children("*_L0", "MeshInstance3D", true, false):
		var bb := (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		var t := bb.get_center() + Vector3(0.0, bb.size.y / 2.0, 0.0)
		if best == Vector3.INF or t.y > best.y:
			best = t
	return best


## The building a socket belongs to: the town root's child above it.
func _house_of(n: Node3D, root: Node3D) -> Node3D:
	var p: Node = n
	while p != null and p.get_parent() != root:
		p = p.get_parent()
	return p as Node3D


func _add(kind: String, xf: Transform3D, c: Color, cell_kind := "") -> void:
	var key := "far" if cell_kind == "far" else "%d|%d" % [floori(xf.origin.x / CELL), floori(xf.origin.z / CELL)]
	if not _cells.has(key):
		_cells[key] = {}
	var cell: Dictionary = _cells[key]
	if not cell.has(kind):
		cell[kind] = []
	(cell[kind] as Array).append([xf, c])


## The MultiMeshes: per cell, one each for the flags, cords, poles, juniper and stones; the heights' cairns in a cell of
## their own, drawn at any distance.
func _commit() -> void:
	var meshes := {"flag": _flag_mesh, "cord": _cyl(), "pole": _cyl(), "juniper": _ball(), "stone": _ball()}
	for key in _cells:
		for kind in _cells[key]:
			var list: Array = _cells[key][kind]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			mm.mesh = meshes[kind]
			mm.instance_count = list.size()
			for i in list.size():
				mm.set_instance_transform(i, list[i][0])
				mm.set_instance_custom_data(i, list[i][1])
			var mi := MultiMeshInstance3D.new()
			mi.name = "%s_%s" % [kind, String(key).replace("|", "_")]
			mi.multimesh = mm
			var mat := ShaderMaterial.new()
			mat.shader = SHADER
			mat.set_shader_parameter("cloth", 1.0 if kind == "flag" else 0.0)
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if kind in ["flag", "pole"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if key != "far":
				mi.visibility_range_end = 350.0 if kind in ["flag", "cord"] else 500.0
			add_child(mi)


## A flag: a 3 x 3 grid, 1 wide along x (-0.5..0.5) and hanging 1 down -y from its tie; vertex colour red = how far down;
## UV across (u) and down (v), for its print.
func _flag() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var v := []
	for r in 3:
		for c in 3:
			v.append(Vector3(-0.5 + c * 0.5, -r * 0.5, 0.0))
	for r in 2:
		for c in 2:
			var i := r * 3 + c
			for q in [i, i + 3, i + 1, i + 1, i + 3, i + 4]:
				var p: Vector3 = v[q]
				st.set_color(Color(-p.y, 0.0, 0.0))
				st.set_uv(Vector2(p.x + 0.5, -p.y))
				st.set_normal(Vector3.BACK)
				st.add_vertex(p)
	return st.commit()


func _cyl() -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.5
	m.bottom_radius = 0.5
	m.height = 1.0
	m.radial_segments = 5
	m.rings = 1
	return m


func _ball() -> Mesh:
	var m := SphereMesh.new()
	m.radius = 1.0
	m.height = 1.4
	m.radial_segments = 7
	m.rings = 4
	return m
