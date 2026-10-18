extends Node3D
## CV-02's whole herd (plan chapter 06, 8.4: "72 yak at about 3 m apart make a string 220 m long"; chapter 12's M2: "all
## 72 yak of CV-02 down the Caravan Ramp"; M2 sprint 9, step 2): the 62 that do not go up to Dechen-tsang (world/
## caravan.gd has the ten), 3 m behind the ten's last in file along the cliff gallery, through the nose's cutting and
## under the Gate Chorten, then spreading four abreast on the road (three on the eight chortens' southern branch), past
## the south pavilion's toll and down the Caravan Ramp two abreast (tools/town/caravan_ground.py's `path`), round its
## five switchbacks onto the Caravan Ground, each to its spot in a block by the tea-case windbreaks (`cv02_block`). There
## (step 3; chapter 06, 8.6: "yak halted by the windbreak stacks ... driven to the hay piles ... they eat, then lie down in
## twos and threes") each is unloaded where it stands, one after another, then walks to a place round the hay (`animals`
## `cv02_hay`), eats and lies down there, or to its place in a group of two or three lying round the hollow (`cv02_lie`);
## a yak lying is the unladen yak at rest sunk into the turf (no lying clip yet: ISS-162). Ten drovers walk at their
## flanks and tail, unload, then stand at the crew's fires till late; two mastiffs range at the head and sit by the block;
## small bells ring along the string (SND-402 at its head, middle and tail).
## Worked out once, as the ten are (a step of STEP real seconds at the clock's 6:1: each yak keeps its gap behind the one
## before it, the gap the road's breadth allows, at the pace of the stretch it is on; off the road at the camp's entry
## each walks on to its own spot), and looked up at the clock's minute, so a still is the same each time. Drawn as VAT
## MultiMeshes with shadows, near and far alike: the yak from ../tibet-blender people2/stand_ins.py `yak` (the ten's
## horns, hump, hair and load baked into the mesh), the drovers' and mastiffs' bodies as the crowd's.

const Town := preload("res://world/town.gd")
const GROUND := "res://data/caravan_ground.json"
const ARRIVAL := "res://data/arrival.json"
const N := 62
const GAP := 3.0  ## metres from one yak's middle to the next in file (chapter 06, 8.4)
const FILE_W := 1.6  ## metres of the road's breadth a yak abreast takes
const STEP := 1.0  ## real seconds a step of the working out
const SPEED := {"road": 0.75, "ramp": 0.65, "camp": 0.6}  ## m/s, the ten's paces (world/caravan.gd)
const WALK_RATE := 0.87  ## the yak's Walk clip's rate at the herd's pace (the ten's)
const BROAD := 1.5  ## the yak made broad (world/caravan.gd), the mastiffs too
const DROVER_WALK := 1.15  ## m/s the drovers' Walk clip plays at
## The road's breadth for the herd from a point on (the town grid), metres between its outer files' middles: in file on
## the gallery, through the nose's cutting and under the Gate Chorten; four abreast on the road past it, three on the
## eight chortens' southern branch, four again to the south pavilion; two abreast down the Caravan Ramp. Each change
## eased over BLEND metres.
const BREADTH := [[430.0, -250.0, 0.0], [160.0, -168.0, 4.8], [138.0, -156.5, 3.2], [52.0, -153.0, 4.8], [-118.0, -141.0, 1.6]]
const BLEND := 12.0
const SLOTS := [-0.375, 0.125, -0.125, 0.375]  ## each yak's place across the road's breadth, by i mod 4: neighbours apart
const DROVER_AT := [0, 7, 14, 21, 28, 35, 42, 49, 56, 61]  ## the yak each drover walks by (the first at the head, the last behind the tail)
const BELLS := [0, 31, 61]
const LIE_SINK := 0.55  ## metres a yak lying is sunk into the turf: its legs folded out of sight
const CAMP_PACE := 6.0  ## metres a game minute about the camp (0.6 m/s at the clock's 6:1)
const FIRES_AT := 25.0  ## minutes after the halt the drovers go to the fires
const FIRES_OUT := 1380.0  ## 23:00: they go into the tent

var yaks: Array = []  ## per yak: {knots: [Vector2(minute, s)], path: PackedVector3Array, cum, spot_face, slot, jitter}
var shared: PackedVector3Array  ## the herd's way to the camp's entry (Godot's coordinates)
var shared_cum: PackedFloat32Array
var breadth_s: Array = []  ## [s, breadth] along `shared`
var gallery := Vector2.ZERO  ## the cliff gallery along `shared`: on its planks, not on the terrain
var junction_s := 0.0  ## R-01's end by the south pavilion: the ten turn east here, the herd south
var ramp_end_s := 0.0  ## the ramp's run-out's end: the camp's ground from here
var start := 0.0  ## the minute the herd's lead sets out (the ten's start)
var halt_minute := 0.0  ## when the lead stands in its spot in the block (world/camp.gd's CV-02 things follow it)
var done_minute := 0.0  ## when the last stands in its spot
var ground: Callable  ## ground(x, z) -> y in Godot's frame, or none
var yak_vat: VatSet
var drover_vats: Array[VatSet] = []
var dog_vat: VatSet
var yak_mmi: MultiMeshInstance3D
var free_vat: VatSet  ## the yak unloaded (yak_free)
var free_mmi: MultiMeshInstance3D
var free_buf := PackedFloat32Array()
var fires: Array[Vector3] = []  ## CV-02's fires (its hearths, data/caravan_ground.json things)
var drover_mmis: Array[MultiMeshInstance3D] = []
var dog_mmi: MultiMeshInstance3D
var yak_buf := PackedFloat32Array()
var drover_bufs: Array[PackedFloat32Array] = []
var dog_buf := PackedFloat32Array()
var bells: Array[AudioStreamPlayer3D] = []
var last_pos := PackedVector3Array()  ## each yak's place this frame (the tests', the bells')
var last_shown := PackedByteArray()
var frame_q: Array = []  ## each yak's place_of this frame, for its drover, the mastiffs and the bells
var last_us := 0  ## the script's cost a frame


func setup(cv: Node, p_ground: Callable = Callable()) -> bool:
	ground = p_ground
	if cv == null or not FileAccess.file_exists(GROUND) or not ResourceLoader.exists(VatSet.DIR + "yak_laden_vat.glb"):
		push_warning("herd: no caravan, no caravan_ground.json or no yak_laden (../tibet-blender people2/stand_ins.py -- yak)")
		return false
	var cg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GROUND))
	var way: PackedVector3Array = cv.get("way")
	var way_cum: PackedFloat32Array = cv.get("way_cum")
	junction_s = float(cv.get("road_ramp_s"))
	start = float(cv.get("start"))
	# the shared way: the ten's road to R-01's end, then the Caravan Ramp's line and on to the camp's entry
	shared = PackedVector3Array()
	for k in way.size():
		if way_cum[k] < junction_s - 0.05:
			shared.append(way[k])
	shared.append(_at(way, way_cum, junction_s))
	var path: Array = cg["path"]
	for k in range(1, path.size()):
		var g := Town.to_godot(float(path[k][0]), float(path[k][1]), float(path[k][2]))
		if shared[shared.size() - 1].distance_to(g) > 0.05:
			shared.append(g)
	var ramp_end := shared.size() - 1
	var block: Dictionary = cg["cv02_block"]
	var e: Array = block["entry"]
	shared.append(Town.to_godot(float(e[0]), float(e[1]), float(e[2])))
	shared_cum = _cum(shared)
	ramp_end_s = shared_cum[ramp_end]
	var arr: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARRIVAL)) if FileAccess.file_exists(ARRIVAL) else {}
	if arr.has("gallery"):
		var ga: Array = arr["gallery"]["from"]
		var gb: Array = arr["gallery"]["to"]
		gallery = Vector2(_nearest_s(shared, shared_cum, Town.to_godot(ga[0], ga[1], ga[2])), _nearest_s(shared, shared_cum, Town.to_godot(gb[0], gb[1], gb[2])))
	for b in BREADTH:  # (the first from the way's start)
		breadth_s.append([_nearest_s(shared, shared_cum, Town.to_godot(b[0], b[1], 0.0)) if b != BREADTH[0] else 0.0, float(b[2])])
	breadth_s.sort_custom(func(a, b): return a[0] < b[0])
	var spots: Array = block["spots"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7202
	for i in N:
		var sp: Array = spots[i]
		var p := shared.duplicate()
		var g := Town.to_godot(float(sp[0]), float(sp[1]), 0.0)
		g.y = _ground_y(g, shared[shared.size() - 1].y, 40.0)
		p.append(g)
		yaks.append({"knots": [], "path": p, "cum": _cum(p), "face": deg_to_rad(180.0 - float(sp[2])), "slot": SLOTS[i % 4],
				"jit": Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.35, 0.35)), "yawj": rng.randf_range(-0.12, 0.12),
				"tint": rng.randf_range(0.82, 1.18), "eat": rng.randf() < 0.55, "phase": rng.randf() * 40.0})
	var ten: Array = cv.get("yaks")
	_work_out((ten[ten.size() - 1] as Dictionary)["knots"] if not ten.is_empty() else [])
	_after_halt(cg)
	_build()
	return true


## The afternoon after the halt, worked out from it: each unloaded where it stands one after another, then off to its
## place at the hay or in a lying group, walked straight; at the hay it eats, then lies down where it is.
func _after_halt(cg: Dictionary) -> void:
	var an: Dictionary = cg.get("animals", {})
	var hay: Array = an.get("cv02_hay", [])
	var lie: Array = an.get("cv02_lie", [])
	for t in cg.get("things", []):
		if String(t["of"]) == "CV-02" and String(t["type"]).begins_with("camp_hearth"):
			var a: Array = t["at"]
			fires.append(Town.to_godot(float(a[0]), float(a[1]), float(a[2])))
	for i in N:
		var y: Dictionary = yaks[i]
		var path: PackedVector3Array = y["path"]
		var spot := path[path.size() - 1]
		var arrive := float(y.get("arrive", done_minute))
		var unload := maxf(arrive + 1.0, halt_minute + 3.0 + 0.32 * i)
		var go := unload + 3.0 + float(i % 4)
		var eats := i < hay.size()
		var q: Array = hay[i] if eats else (lie[i - hay.size()] if i - hay.size() < lie.size() else [])
		var target := spot
		var face := float(y["face"])
		if not q.is_empty():
			target = Town.to_godot(float(q[0]), float(q[1]), float(q[2]))
			target.y = _ground_y(target, target.y, 40.0)
			face = deg_to_rad(180.0 - float(q[3]))
		var walk := Vector2(target.x - spot.x, target.z - spot.z).length() / CAMP_PACE
		y["unload"] = unload
		y["go"] = go
		y["there"] = go + walk
		y["target"] = target
		y["tface"] = face
		y["lie_at"] = go + walk + (45.0 + float(i % 6) * 6.0 if eats else 0.0)


## The road's breadth at s along the shared way, eased between its stretches.
func breadth_at(s: float) -> float:
	var w := 0.0
	for k in breadth_s.size():
		var b: Array = breadth_s[k]
		if s >= float(b[0]):
			var prev := float(breadth_s[k - 1][1]) if k > 0 else 0.0
			w = lerpf(prev, float(b[1]), clampf((s - float(b[0])) / BLEND, 0.0, 1.0))
	return w


## The gap a yak keeps behind the one before it where the road is `w` broad: GAP in file, less as they go abreast.
static func gap_for(w: float) -> float:
	return GAP / clampf(1.0 + w / FILE_W, 1.0, 4.0)


func _pace(s: float) -> float:
	if s < junction_s:
		return SPEED["road"]
	return SPEED["ramp"] if s < ramp_end_s else SPEED["camp"]


## Step by step from the ten's start: the herd's lead 3 m behind the ten's last while that one is on the shared road, each
## after it its gap behind the one before; past the camp's entry each walks on to its own spot.
func _work_out(ten_tail: Array) -> void:
	var s := PackedFloat32Array()
	var s0 := minf(-GAP * 10.0, (_s_at(ten_tail, start) if not ten_tail.is_empty() else 0.0) - GAP)
	for i in N:
		s.append(s0 - GAP * i)  # behind the ten's last, beyond the gallery's east end: out of sight
	var L := PackedFloat32Array()
	for y in yaks:
		var c: PackedFloat32Array = y["cum"]
		L.append(c[c.size() - 1])
	var shared_len := shared_cum[shared_cum.size() - 1]
	var t := 0.0
	var placed := 0
	halt_minute = -1.0
	while placed < N and t < 20000.0:
		var m := start + t * WorldClock.RATE_PLAY
		placed = 0
		for i in N:
			var nxt := minf(s[i] + _pace(maxf(s[i], 0.0)) * STEP, L[i])
			if i == 0:
				if not ten_tail.is_empty():
					var tail := _s_at(ten_tail, m)
					if tail < junction_s + 4.0:
						nxt = minf(nxt, tail - GAP)
			elif s[i - 1] < shared_len + 3.0 and s[i] < shared_len:  # in the queue until it is onto the camp
				nxt = minf(nxt, s[i - 1] - gap_for(breadth_at(clampf(s[i - 1], 0.0, shared_len))))
			nxt = maxf(nxt, s[i])
			var knots: Array = yaks[i]["knots"]
			if nxt != s[i] or knots.is_empty():
				knots.append(Vector2(m, nxt))
			s[i] = nxt
			if s[i] >= L[i] - 0.01:
				placed += 1
				if not yaks[i].has("arrive"):
					yaks[i]["arrive"] = m
				if i == 0 and halt_minute < 0.0:
					halt_minute = m
		t += STEP
	done_minute = start + t * WorldClock.RATE_PLAY


# ------------------------------------------------------------------ the figures
func _build() -> void:
	var bounds := AABB(shared[0], Vector3.ZERO)  # the herd's whole way and its block, grown by a margin (a MultiMesh is
	for q in shared:  # culled by this box: too small a one hid the herd on the gallery)
		bounds = bounds.expand(q)
	for y in yaks:
		var p: PackedVector3Array = y["path"]
		bounds = bounds.expand(p[p.size() - 1])
	bounds = bounds.grow(12.0)
	for p in fires:
		bounds = bounds.expand(p)
	yak_vat = VatSet.open("yak_laden")
	yak_mmi = yak_vat.multimesh(N, bounds)
	yak_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON  # near and far alike (no skinned tier)
	add_child(yak_mmi)
	yak_buf.resize(N * VatSet.FLOATS)
	if ResourceLoader.exists(VatSet.DIR + "yak_free_vat.glb"):
		free_vat = VatSet.open("yak_free")
		free_mmi = free_vat.multimesh(N, bounds)
		free_mmi.name = "yak_free_vat"
		free_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(free_mmi)
		free_buf.resize(N * VatSet.FLOATS)
	last_pos.resize(N)
	last_shown.resize(N)
	for n in ["drover", "drover_b"]:
		if ResourceLoader.exists(VatSet.DIR + n + "_vat.glb"):
			var v := VatSet.open(n)
			var mmi := v.multimesh(DROVER_AT.size() / 2, bounds)
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			add_child(mmi)
			drover_vats.append(v)
			drover_mmis.append(mmi)
			var b := PackedFloat32Array()
			b.resize(DROVER_AT.size() / 2 * VatSet.FLOATS)
			drover_bufs.append(b)
	if ResourceLoader.exists(VatSet.DIR + "mastiff_vat.glb"):
		dog_vat = VatSet.open("mastiff")
		dog_mmi = dog_vat.multimesh(2, bounds)
		dog_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(dog_mmi)
		dog_buf.resize(2 * VatSet.FLOATS)
	var ad := get_node_or_null("/root/AudioDirector")
	var st: AudioStream = ad.call("stream", "SND-402") if ad != null else null
	if st != null:
		for k in BELLS.size():
			var p := AudioStreamPlayer3D.new()
			p.name = "Bell%d" % k
			p.stream = st
			p.bus = &"Animals"
			p.unit_size = 3.0
			p.max_distance = 420.0
			p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
			p.volume_db = -4.0
			add_child(p)
			bells.append(p)


## One VAT instance: a yaw, a position, the breadth along its own x, the tint, the clip's state.
static func put(buf: PackedFloat32Array, i: int, p: Vector3, yaw_angle: float, sx: float, tint: float, c: Dictionary, phase: float, rate: float) -> void:
	var o := i * VatSet.FLOATS
	var cs := cos(yaw_angle)
	var sn := sin(yaw_angle)
	buf[o] = cs * sx
	buf[o + 1] = 0.0
	buf[o + 2] = sn
	buf[o + 3] = p.x
	buf[o + 4] = 0.0
	buf[o + 5] = 1.0
	buf[o + 6] = 0.0
	buf[o + 7] = p.y
	buf[o + 8] = -sn * sx
	buf[o + 9] = 0.0
	buf[o + 10] = cs
	buf[o + 11] = p.z
	buf[o + 12] = tint
	buf[o + 13] = tint
	buf[o + 14] = tint
	buf[o + 15] = 1.0
	buf[o + 16] = c["row"]
	buf[o + 17] = c["frames"]
	buf[o + 18] = phase
	buf[o + 19] = rate


static func put_none(buf: PackedFloat32Array, i: int) -> void:
	var o := i * VatSet.FLOATS
	for k in 12:
		buf[o + k] = 0.0  # a zero basis: nothing drawn
	buf[o + 7] = -10000.0


## The minute of the herd's day: after midnight it is still the day that began at 04:00.
static func day_minute(m: float) -> float:
	var d := fposmod(m, 1440.0)
	return d + 1440.0 if d < 240.0 else d


## Where yak i stands at minute m: its place (Godot's frame), its heading, whether it walks, and whether it is seen.
func place_of(i: int, m: float) -> Array:
	var y: Dictionary = yaks[i]
	var knots: Array = y["knots"]
	var s := _s_at(knots, m)
	if s < 0.0 or m < start:
		return [Vector3.ZERO, 0.0, false, false, ""]
	var path: PackedVector3Array = y["path"]
	var cum: PackedFloat32Array = y["cum"]
	var L := cum[cum.size() - 1]
	var moving := _s_at(knots, m + 0.05) - s > 0.001
	var p := _at(path, cum, s)
	var shared_len := shared_cum[shared_cum.size() - 1]
	var d := _at(path, cum, minf(s + 0.8, L)) - _at(path, cum, maxf(s - 0.8, 0.0))
	var yaw := atan2(d.x, d.z) if Vector2(d.x, d.z).length() > 0.01 else float(y["face"])
	if s < shared_len:  # across the road's breadth by its place, a little off it
		var w := breadth_at(s)
		var side := Vector3(d.z, 0.0, -d.x).normalized() if Vector2(d.x, d.z).length() > 0.01 else Vector3.RIGHT
		var jit: Vector2 = y["jit"]
		p += side * (float(y["slot"]) * w + (jit.x if w > 0.4 else 0.0)) + Vector3(sin(yaw), 0.0, cos(yaw)) * (jit.y if w > 0.4 else 0.0)
		if w > 0.4 and s < junction_s:  # on the road, abreast: on its ground (the gallery's planks and the ramp's beds are the line's)
			p.y = _ground_y(p, p.y)
	else:  # on the camp's own ground
		p.y = _ground_y(p, p.y, 40.0)
	if s >= L - 0.05:
		yaw = float(y["face"])
		if y.has("unload") and m >= float(y["unload"]):  # unloaded; then off to the hay or to lie down
			var go := float(y["go"])
			var there := float(y["there"])
			var t: Vector3 = y["target"]
			if m < go:
				return [p, yaw + float(y["yawj"]), false, true, "free"]
			if m < there:
				var f := (m - go) / maxf(there - go, 1e-3)
				var w := p.lerp(t, f)
				w.y = _ground_y(w, lerpf(p.y, t.y, f), 40.0)
				return [w, atan2(t.x - p.x, t.z - p.z), true, true, "free"]
			if m < float(y["lie_at"]):
				return [t, float(y["tface"]), false, true, "eat"]
			return [t - Vector3(0.0, LIE_SINK, 0.0), float(y["tface"]), false, true, "lie"]
	return [p, yaw + float(y["yawj"]), moving, true, "laden"]


## The terrain's height under p, or `fallback` where there is none or it lies more than `trust` from it (beside a road
## on a fill or a cut, the slope is not where a yak walks).
func _ground_y(p: Vector3, fallback: float, trust := 6.0) -> float:
	if not ground.is_valid():
		return fallback
	var g = ground.call(p.x, p.z)
	return fallback if g == null or is_nan(float(g)) or absf(float(g) - fallback) > trust else float(g)


# ------------------------------------------------------------------ each frame
func update(_eye: Vector3) -> void:
	if yak_mmi == null:
		return
	var t0 := Time.get_ticks_usec()
	var m := day_minute(WorldClock.minute)
	var walk := yak_vat.clip("Walk")
	var idle := yak_vat.clip("Idle")
	var eat := yak_vat.clip("Eating")
	var any := false
	frame_q.resize(N)
	for i in N:
		var q := place_of(i, m)
		frame_q[i] = q
		last_shown[i] = 1 if q[3] else 0
		put_none(yak_buf, i)
		if free_mmi != null:
			put_none(free_buf, i)
		if not q[3]:
			continue
		any = true
		var y: Dictionary = yaks[i]
		var state := String(q[4])
		var laden := state == "laden" or free_mmi == null
		var c: Dictionary
		var rate := 1.0
		if q[2]:
			c = walk
			rate = WALK_RATE
		elif state == "eat" or (state == "laden" and bool(y["eat"]) and m > halt_minute + 2.0):
			c = eat
		else:
			c = idle
			rate = 0.35 if state == "lie" else 1.0  # at rest, chewing
		put(yak_buf if laden else free_buf, i, q[0], q[1], BROAD, float(y["tint"]), c, float(y["phase"]), rate)
		last_pos[i] = q[0]
	yak_mmi.multimesh.buffer = yak_buf
	if free_mmi != null:
		free_mmi.multimesh.buffer = free_buf
	_drovers(m)
	_dogs(m)
	_bells(m, any)
	last_us = Time.get_ticks_usec() - t0


func _drovers(m: float) -> void:
	if drover_vats.is_empty():
		return
	for j in DROVER_AT.size():
		var k := j % drover_vats.size()
		var slot := j / drover_vats.size()
		var v := drover_vats[k]
		var buf := drover_bufs[k]
		var a: int = DROVER_AT[j]
		var q: Array = frame_q[a]
		if not q[3]:
			put_none(buf, slot)
			continue
		var yaw: float = q[1]
		var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
		var side := Vector3(fwd.z, 0.0, -fwd.x) * (1.0 if j % 2 == 1 else -1.0)
		var s := _s_at(yaks[a]["knots"], m)
		var on_way := s < shared_cum[shared_cum.size() - 1]
		var w := breadth_at(s) if on_way else 0.0
		var p: Vector3 = q[0]
		if j == 0:  # at the head, ahead of the lead
			p += fwd * 2.6 + side * (w * 0.5 + 0.8 if w > 0.4 else 0.3)
		elif j == DROVER_AT.size() - 1:  # behind the tail, driving
			p -= fwd * 2.8
		elif w > 0.4:  # at the flank
			p += side * (w * 0.5 + 1.1)
		else:  # in file: between his yak and the next
			p -= fwd * 1.5
			p += side * 0.35
		if not on_way:  # at the block: standing by its side, facing it
			var sp: PackedVector3Array = yaks[a]["path"]
			p = sp[sp.size() - 1] + side * 2.4
			yaw = atan2(-side.x, -side.z)
			if not fires.is_empty() and m >= halt_minute + FIRES_AT:  # at the crew's fires till late, then in the tent
				if m >= FIRES_OUT:
					put_none(buf, slot)
					continue
				var c := fires[j % fires.size()]
				var a2 := float(j / fires.size()) * 2.3 + float(j) * 0.7
				p = c + Vector3(cos(a2), 0.0, sin(a2)) * 1.6
				yaw = atan2(c.x - p.x, c.z - p.z)
		if w > 0.4 or not on_way:
			p.y = _ground_y(p, p.y, 6.0 if on_way else 40.0)
		var walking: bool = q[2] and on_way
		put(buf, slot, p, yaw, 1.0, 1.0, v.clip("Walk" if walking else "Idle_A"), float(j) * 5.3, SPEED["road"] / DROVER_WALK if walking else 1.0)
	for k in drover_mmis.size():
		drover_mmis[k].multimesh.buffer = drover_bufs[k]


func _dogs(m: float) -> void:
	if dog_vat == null:
		return
	var q: Array = frame_q[0]
	for k in 2:
		if not q[3]:
			put_none(dog_buf, k)
			continue
		var yaw: float = q[1]
		var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
		var side := Vector3(fwd.z, 0.0, -fwd.x)
		var s := _s_at(yaks[0]["knots"], m)
		var on_way := s < shared_cum[shared_cum.size() - 1]
		var w := breadth_at(s) if on_way else 0.0
		var p: Vector3 = q[0] + fwd * (7.0 if k == 0 else 4.5) + side * ((0.25 if k == 0 else -0.25) * w)
		var clip := "Walk" if q[2] else "Sit"
		if not on_way:  # at the block's front corners, sat
			var yk: Dictionary = yaks[0] if k == 0 else yaks[7]
			var sp: PackedVector3Array = yk["path"]
			yaw = float(yk["face"])
			p = sp[sp.size() - 1] + Vector3(sin(yaw), 0.0, cos(yaw)) * 3.0
			clip = "Sit" if not q[2] else "Walk"
		if w > 0.4 or not on_way:
			p.y = _ground_y(p, p.y, 6.0 if on_way else 40.0)
		put(dog_buf, k, p, yaw, BROAD, 1.0, dog_vat.clip(clip), float(k) * 7.0, SPEED["road"] / 0.8 if clip == "Walk" else 1.0)
	dog_mmi.multimesh.buffer = dog_buf


func _bells(m: float, any: bool) -> void:
	for k in bells.size():
		var i: int = BELLS[k]
		var q: Array = frame_q[i]
		var on: bool = any and q[3] and q[2] and not WorldClock.frozen
		bells[k].position = q[0] + Vector3(0.0, 1.0, 0.0)
		if on and not bells[k].playing:
			bells[k].play(randf() * 9.0)
		elif not on and bells[k].playing:
			bells[k].stop()


# ------------------------------------------------------------------ along a polyline
static func _cum(p: PackedVector3Array) -> PackedFloat32Array:
	var out := PackedFloat32Array([0.0])
	for k in range(1, p.size()):
		out.append(out[k - 1] + p[k - 1].distance_to(p[k]))
	return out


static func _at(p: PackedVector3Array, cum: PackedFloat32Array, s: float) -> Vector3:
	if s <= 0.0:
		return p[0]
	var lo := 0
	var hi := cum.size() - 1
	if s >= cum[hi]:
		return p[hi]
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if cum[mid] <= s:
			lo = mid
		else:
			hi = mid
	return p[lo].lerp(p[hi], (s - cum[lo]) / maxf(cum[hi] - cum[lo], 1e-5))


static func _nearest_s(p: PackedVector3Array, cum: PackedFloat32Array, q: Vector3) -> float:
	var best := 0.0
	var bd := 1e9
	for k in p.size() - 1:
		var a := Vector2(p[k].x, p[k].z)
		var d := Vector2(p[k + 1].x, p[k + 1].z) - a
		var f := clampf((Vector2(q.x, q.z) - a).dot(d) / maxf(d.length_squared(), 1e-6), 0.0, 1.0)
		var e := (a + d * f).distance_to(Vector2(q.x, q.z))
		if e < bd:
			bd = e
			best = cum[k] + d.length() * f
	return best


## s along a knot list at minute m (Vector2(minute, s), the minutes rising).
static func _s_at(knots: Array, m: float) -> float:
	if knots.is_empty():
		return -1.0
	if m <= (knots[0] as Vector2).x:
		return (knots[0] as Vector2).y
	var lo := 0
	var hi := knots.size() - 1
	if m >= (knots[hi] as Vector2).x:
		return (knots[hi] as Vector2).y
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if (knots[mid] as Vector2).x <= m:
			lo = mid
		else:
			hi = mid
	var a: Vector2 = knots[lo]
	var b: Vector2 = knots[hi]
	return a.y + (b.y - a.y) * clampf((m - a.x) / maxf(b.x - a.x, 1e-6), 0.0, 1.0)
