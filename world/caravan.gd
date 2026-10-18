extends Node3D
## The caravan CV-02's ten yak for Dechen-tsang (plan chapter 06, 8.4-8.5; chapter 12, M1's acceptance 1; M1 sprint 6,
## step 5): since M2 sprint 3 by the Serchu road from SER-20 (data/arrival.json; chapter 06's beats worked back from the
## Yak Gate's at the clock's 6:1, ISS-137: on the cliff gallery about 13:10, under the Gate Chorten, past the eight
## chortens to the south pavilion's toll and down the south ramp, its lead's iron bell heard, SND-402), then
## over the lower bridge's deck from the slot's south side at 14:55, up Samkha's north ramp in file, through the
## Yak Gate at about 15:20 with the mastiff Sengé ranging ahead (he stops at the gate to look at the town), along
## Nétsang Lam to Dechen-tsang's gate, across Yard 1 and one at a time through the animal passage under the east range
## into Yard 0; their loads lifted onto the platform one yak after another from 15:45; back out through the passage from
## 16:40 and down the ramp to the camp by about 17:15. Their way is the street graph's (tools/town/graph.py's `caravan`:
## the deck, the ramp's route, the house's yard and passage, the ten places before the platform).
## Like TownSim, the whole afternoon is worked out once (a step of 0.25 s at the clock's 6:1: each yak keeps 3.2 m behind
## the one before, climbs the ramp at 0.65 m/s, and waits at the passage while another is in it) and looked up at the
## clock's minute, so it holds at any clock rate and a still is the same each time.
## The drovers are two of the slice's generic twelve (data/generic_days.json: indoors at the camp all day), drawn by
## characters/named.gd; while the caravan is out this places them (named.gd `overrides`): the one in the turban at the
## file's head, a hand on the lead's horns through the passage, the one in the felt hat at its tail; in Yard 0 by the
## platform. The yak are Mesh2Motion's horse (../tibet-blender/people2/stand_ins.py) made broad, with horns, a hump, a
## skirt of long hair and a bushy tail, each with its load of two rawhide tea cases on a pack saddle; the lead's collar
## carries the big iron bell, a red tassel between its horns and a small flag stands in its load (chapter 06, 7.4).

const Town := preload("res://world/town.gd")
const MuleString := preload("res://world/mule_string.gd")
const YAK := "res://assets/generated/people/yak.glb"
const DOG := "res://assets/generated/people/mastiff.glb"
const N := 10
const GAP := 3.2  ## metres from one yak's middle to the next
const STEP := 0.25  ## real seconds a step of the working out
const ARRIVE := 895.0  ## 14:55: the lead steps onto the deck at the slot's south side
const UNLOAD := 945.0  ## 15:45: the first load off; one every UNLOAD_EVERY game minutes after
const UNLOAD_EVERY := 4.5
const LEAVE := 1000.0  ## 16:40: the first yak out through the passage
const GATE_STOP := 20.0  ## real seconds Sengé stands at the Yak Gate, looking at the town
const YAK_WALK := 0.9  ## m/s the yak's Walk clip plays at (its stride at the stand-in's scale)
const DOG_WALK := 0.8
const SPEED := {"road": 0.75, "deck": 0.8, "ramp": 0.65, "lane": 0.8, "yard": 0.6, "passage": 0.45}
const BELL := "SND-402"  ## the lead's iron bell and the file's small bells (a stand-in, tools/audio/synth.py)
const BELL_HEARD := 420.0  ## metres: down the slot from the gallery's west end to the south ramp

var sim: Node  ## TownSim
var named: Node  ## characters/named.gd: the drovers' figures
var yaks: Array = []  ## per yak: {node, ap, clip, load, path (PackedVector3Array), cum, knots [(minute, s)...], out (the way back), ...}
var dog := {}
var drovers := [-1, -1]  ## TownSim's walkers for the two drovers
var platform_cases: Array[Node3D] = []
var way: PackedVector3Array  ## the arrival's way, shared by all ten to Yard 0's entry
var way_cum: PackedFloat32Array
var passage := Vector2.ZERO  ## the passage's two ends along `way`, metres
var gate_s := 0.0  ## the Yak Gate along `way`
var in_passage_most := 0  ## the most yak ever in the passage at once in the working out (the tests': one)
var done_minute := 0.0  ## when the last yak leaves the deck's south end, going home
var start := ARRIVE  ## when the lead sets out from the way's start (SER-20 with the arrival's road, the deck's end without)
var road_s := 0.0  ## the arrival's road along `way`: to the south ramp's legs, and to the deck
var road_ramp_s := 0.0


func setup(p_sim: Node, p_named: Node, streets: Dictionary) -> bool:
	sim = p_sim
	named = p_named
	var c = streets.get("caravan")
	if c == null or not ResourceLoader.exists(YAK):
		push_warning("caravan: no way in the street graph, or no yak (tools/town/graph.py; people2/stand_ins.py)")
		return false
	var routes: Dictionary = streets["routes"]
	var pts: Array = []
	var n_road := 0
	var n_ramp := 0
	for q in c.get("road", []):  # the arrival's road (M2 sprint 3), then the deck
		pts.append(q)
	n_road = pts.size()
	n_ramp = int(c.get("road_ramp", 0))
	for q in c["deck"]:
		pts.append(q)
	var up: Array = (routes[c["up"]] as Dictionary)["p"]
	for k in range(0, up.size(), 3):
		pts.append([up[k], up[k + 1], up[k + 2]])
	for q in c["inside"]:
		pts.append(q)
	way = PackedVector3Array()
	for q in pts:
		var g := Town.to_godot(float(q[0]), float(q[1]), float(q[2]))
		if way.is_empty() or way[way.size() - 1].distance_to(g) > 0.05:
			way.append(g)
	way_cum = _cum(way)
	if n_road > 0:  # the road's places along the way, found (the deck's first point is the road's last)
		road_s = _nearest_s(way, way_cum, Town.to_godot(float(pts[n_road - 1][0]), float(pts[n_road - 1][1]), float(pts[n_road - 1][2])))
		road_ramp_s = _nearest_s(way, way_cum, Town.to_godot(float(pts[n_ramp][0]), float(pts[n_ramp][1]), float(pts[n_ramp][2]))) if n_ramp > 0 and n_ramp < n_road else road_s
		# the lead sets out so that it is on the deck at ARRIVE, as before the road: the Yak Gate's times kept (ISS-137)
		start = ARRIVE - (road_ramp_s / SPEED["road"] + (road_s - road_ramp_s) / SPEED["ramp"]) * WorldClock.RATE_PLAY
	var inside: Array = c["inside"]
	var at_inside := func(k: int) -> float:  # an inside point's place along the way (found, not counted: the first is the route's end)
		var q: Array = inside[k]
		return _nearest_s(way, way_cum, Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
	var pa: Array = c["passage"]
	passage = Vector2(at_inside.call(int(pa[0])), at_inside.call(int(pa[1])))
	var yard_s: float = at_inside.call(0)  # Dechen-tsang's gate: the house's own ground from here
	var g_anchor: Array = streets["anchors"].get("yak_gate", [-55.0, -75.0, 2650.6])
	gate_s = _nearest_s(way, way_cum, Town.to_godot(float(g_anchor[0]), float(g_anchor[1]), float(g_anchor[2])))
	var seg_of := func(s: float) -> String:  # which stretch of the way: its pace
		if s < road_ramp_s:
			return "road"
		if s < road_s:
			return "ramp"
		if s < road_s + 15.0:
			return "deck"
		if s >= passage.x - 0.5 and s <= passage.y + 0.5:
			return "passage"
		if s > yard_s:
			return "yard"
		return "ramp" if s < gate_s else "lane"
	var spots: Array = c["spots"]
	# the arrival: each yak's way is the shared one and then to its own place
	for i in N:
		var sp: Array = spots[i]
		var path := way.duplicate()
		path.append(Town.to_godot(float(sp[0]), float(sp[1]), float(sp[2])))
		yaks.append({"path": path, "cum": _cum(path), "face": deg_to_rad(float(sp[3])), "knots": [], "back": [], "clip": ""})
	_work_out_arrival(seg_of)
	_work_out_leaving(streets, c)
	_build(c)
	var ms := MuleString.new()  # the pack mules and riding ponies after the yak, over the lower bridge at 15:16 (M2 sprint 4)
	ms.name = "MuleString"
	add_child(ms)
	if road_s > 0.0:
		ms.setup(way, way_cum, road_ramp_s, road_s, gate_s)
	for k in sim.count:
		if String(sim.key[k]) == "drover":
			drovers[0] = k
		elif String(sim.key[k]) == "drover_b":
			drovers[1] = k
	return true


static func _cum(p: PackedVector3Array) -> PackedFloat32Array:
	var out := PackedFloat32Array([0.0])
	for k in range(1, p.size()):
		out.append(out[k - 1] + p[k - 1].distance_to(p[k]))
	return out


static func _nearest_s(p: PackedVector3Array, cum: PackedFloat32Array, q: Vector3) -> float:
	var best := 0.0
	var bd := 1e9
	for k in p.size() - 1:
		var a := p[k]
		var d := p[k + 1] - a
		var f := clampf((q - a).dot(d) / maxf(d.length_squared(), 1e-6), 0.0, 1.0)
		var e := (a + d * f).distance_to(q)
		if e < bd:
			bd = e
			best = cum[k] + d.length() * f
	return best


static func _at(p: PackedVector3Array, cum: PackedFloat32Array, s: float) -> Vector3:
	if s <= 0.0:
		return p[0]
	for k in range(1, cum.size()):
		if s <= cum[k]:
			return p[k - 1].lerp(p[k], (s - cum[k - 1]) / maxf(cum[k] - cum[k - 1], 1e-5))
	return p[p.size() - 1]


## The arrival, step by step: the lead at its pace from ARRIVE; each after it 3.2 m behind the one before, all at the
## pace of the stretch they are on, none into the passage while another is in it; then each to its place.
func _work_out_arrival(seg_of: Callable) -> void:
	var s := PackedFloat32Array()
	for i in N:
		s.append(-GAP * i)  # still on the far side of the slot, out of sight
	var t := 0.0
	var arrived := 0
	while arrived < N and t < 3600.0:
		var inside := 0
		for i in N:
			if s[i] > passage.x - 0.3 and s[i] < passage.y + 1.2:
				inside += 1
		in_passage_most = maxi(in_passage_most, inside)
		arrived = 0
		for i in N:
			var y: Dictionary = yaks[i]
			var L: float = (y["cum"] as PackedFloat32Array)[(y["cum"] as PackedFloat32Array).size() - 1]
			var v: float = SPEED[seg_of.call(clampf(s[i], 0.0, way_cum[way_cum.size() - 1]))] if s[i] < way_cum[way_cum.size() - 1] else SPEED["yard"]
			var nxt := minf(s[i] + v * STEP, L)
			if i > 0:
				nxt = minf(nxt, s[i - 1] - GAP if s[i - 1] < way_cum[way_cum.size() - 1] else nxt)
			if s[i] <= passage.x - 0.3 and nxt > passage.x - 0.3:  # the passage: one at a time
				for j in N:
					if j != i and s[j] > passage.x - 0.3 and s[j] < passage.y + 1.2:
						nxt = minf(nxt, passage.x - 0.3)
			nxt = maxf(nxt, s[i])
			if nxt != s[i] or (y["knots"] as Array).is_empty():
				(y["knots"] as Array).append(Vector2(start + t * WorldClock.RATE_PLAY, nxt))
			s[i] = nxt
			if s[i] >= L - 0.01:
				arrived += 1
		t += STEP


## The way back: from 16:40, the yak nearest the passage first, each from its place back through the passage, across
## Yard 1, out of the gate, down the ramp and over the deck to the slot's south side, where it is out of sight.
func _work_out_leaving(streets: Dictionary, c: Dictionary) -> void:
	var down: Array = (streets["routes"][c["down"]] as Dictionary)["p"]
	var inside: Array = (c["inside"] as Array).duplicate()
	inside.reverse()
	var deck: Array = (c["deck"] as Array).duplicate()
	deck.reverse()
	var shared := PackedVector3Array()
	for q in inside:
		shared.append(Town.to_godot(float(q[0]), float(q[1]), float(q[2])))
	for k in range(0, down.size(), 3):
		var g := Town.to_godot(float(down[k]), float(down[k + 1]), float(down[k + 2]))
		if shared[shared.size() - 1].distance_to(g) > 0.05:
			shared.append(g)
	for q in deck:
		var g := Town.to_godot(float(q[0]), float(q[1]), float(q[2]))
		if shared[shared.size() - 1].distance_to(g) > 0.05:
			shared.append(g)
	var order: Array = range(N)
	order.reverse()  # the last to come in is nearest the passage
	var shared_cum := _cum(shared)
	var L := shared_cum[shared_cum.size() - 1]
	var ps := Vector2(_nearest_s(shared, shared_cum, shared[2]), _nearest_s(shared, shared_cum, shared[1]))  # the passage
	# each walks from its place to Yard 0's entry and then the shared way: `u` along the shared way (less than 0 still
	# in the yard), its own way's s = u + its walk to the entry, so one keeps its distance from the one before it
	var u := PackedFloat32Array()
	var off := PackedFloat32Array()
	var paths := []
	for r in N:
		var y: Dictionary = yaks[order[r]]
		var p := PackedVector3Array([(y["path"] as PackedVector3Array)[(y["path"] as PackedVector3Array).size() - 1]])
		p.append_array(shared)
		paths.append([p, _cum(p)])
		off.append(p[0].distance_to(p[1]))
		u.append(-off[r])
	var t := 0.0
	var gone := 0
	while gone < N and t < 3600.0:
		gone = 0
		for r in N:
			var y: Dictionary = yaks[order[r]]
			var v: float = SPEED["passage"] if u[r] > ps.x - 0.5 and u[r] < ps.y + 0.5 else SPEED["lane"]
			var nxt := minf(u[r] + v * STEP, L)
			if r > 0:
				nxt = minf(nxt, u[r - 1] - GAP if u[r - 1] < L else nxt)
			if u[r] <= ps.x - 0.3 and nxt > ps.x - 0.3:  # one at a time through the passage
				for q in N:
					if q != r and u[q] > ps.x - 0.3 and u[q] < ps.y + 1.2:
						nxt = minf(nxt, ps.x - 0.3)
			nxt = maxf(nxt, u[r])
			(y["back"] as Array).append(Vector2(LEAVE + t * WorldClock.RATE_PLAY, nxt + off[r]))
			u[r] = nxt
			if u[r] >= L - 0.01:
				gone += 1
		t += STEP
	done_minute = LEAVE + t * WorldClock.RATE_PLAY
	for r in N:
		var y: Dictionary = yaks[order[r]]
		y["back_path"] = paths[r][0]
		y["back_cum"] = paths[r][1]


## s along a knot list at game minute m (the knots' minutes rise; each knot is Vector2(minute, s)).
static func _s_at(knots: Array, m: float) -> float:
	if knots.is_empty():
		return 0.0
	if m <= (knots[0] as Vector2).x:
		return (knots[0] as Vector2).y
	var lo := 0
	var hi := knots.size() - 1
	if m >= (knots[hi] as Vector2).x:
		return (knots[hi] as Vector2).y
	while hi - lo > 1:  # bisect
		var mid := (lo + hi) / 2
		if (knots[mid] as Vector2).x <= m:
			lo = mid
		else:
			hi = mid
	var a: Vector2 = knots[lo]
	var b: Vector2 = knots[hi]
	return a.y + (b.y - a.y) * clampf((m - a.x) / maxf(b.x - a.x, 1e-6), 0.0, 1.0)


# ------------------------------------------------------------------ the figures
func _mat(hex: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 1.0
	return m


func _part(parent: Node3D, mesh: Mesh, mat: Material, at: Vector3, rot := Vector3.ZERO, scale_ := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.rotation = rot
	mi.scale = scale_
	parent.add_child(mi)
	return mi


## A holder that follows `bone`, in whose frame parts are placed in the model's own coordinates (its rest pose, as the
## glb's root has them: the rig carries its own scale).
func _on_bone(fig: Node3D, sk: Skeleton3D, bone: String) -> Node3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	sk.add_child(ba)
	var holder := Node3D.new()
	ba.add_child(holder)
	var rest := sk.get_bone_global_rest(sk.find_bone(bone))
	holder.transform = rest.affine_inverse() * _rel(fig, sk).affine_inverse()
	return holder


## The transform of `node` in `top`'s frame (the local transforms from top down to it).
static func _rel(top: Node3D, node: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != top:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


func _build(c: Dictionary) -> void:
	var scene: PackedScene = load(YAK)
	var hair := ["#2A221E", "#3A2A20", "#1C1714", "#2E2622", "#4A3A2E"]
	var hide_ := _mat("#8C7050")
	var lash := _mat("#3E3226")
	var wood := _mat("#6B4A2E")
	var horn := _mat("#D8CCB0")
	var red := _mat("#B3262A")
	var iron := _mat("#3A3A3C")
	for i in N:
		var y: Dictionary = yaks[i]
		var root := Node3D.new()
		root.name = "Yak%d" % i
		add_child(root)
		var fig: Node3D = scene.instantiate()
		fig.scale = Vector3(1.5, 1.0, 1.0)  # a yak is broad: the horse made wide
		root.add_child(fig)
		var sk: Skeleton3D = fig.find_children("*", "Skeleton3D", true, false)[0]
		var coat := _mat(hair[i % hair.size()])
		for mi in fig.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = coat
		var head := _on_bone(fig, sk, "head")
		for sx in [-1.0, 1.0]:  # the horns, out and up
			_part(head, _cone(0.045, 0.012, 0.32), horn, Vector3(sx * 0.1, 1.36, 0.8), Vector3(0.0, 0.0, -sx * 0.9))
		var back := _on_bone(fig, sk, "spine_4")
		_part(back, _sphere(0.26), coat, Vector3(0.0, 1.08, 0.36), Vector3.ZERO, Vector3(0.9, 0.55, 1.2))  # the hump
		var mid := _on_bone(fig, sk, "spine_2")
		for sx in [-1.0, 1.0]:  # the skirt of long hair along each flank
			_part(mid, _box(Vector3(0.05, 0.42, 1.25)), coat, Vector3(sx * 0.16, 0.6, 0.0))
		_part(mid, _box(Vector3(0.3, 0.36, 1.1)), coat, Vector3(0.0, 0.62, 0.0))  # the belly's hair between them
		var tail := _on_bone(fig, sk, "tail_2")
		_part(tail, _cone(0.08, 0.02, 0.6), coat, Vector3(0.0, 0.88, -0.85), Vector3(-1.3, 0.0, 0.0))
		# the load: a pack saddle and two rawhide tea cases, lashed
		var load := Node3D.new()
		mid.add_child(load)
		_part(load, _box(Vector3(0.3, 0.1, 0.55)), wood, Vector3(0.0, 1.02, 0.0))
		for sx in [-1.0, 1.0]:
			_part(load, _box(Vector3(0.24, 0.36, 0.62)), hide_, Vector3(sx * 0.26, 0.9, 0.0))
			_part(load, _box(Vector3(0.25, 0.04, 0.64)), lash, Vector3(sx * 0.26, 0.98, 0.0))
		if i == 0:  # the lead (ANI-03): the collar and its big iron bell, a red tassel, a flag in its load
			var neck := _on_bone(fig, sk, "spine_6")
			var collar := TorusMesh.new()
			collar.inner_radius = 0.13
			collar.outer_radius = 0.18
			_part(neck, collar, red, Vector3(0.0, 1.14, 0.64), Vector3(1.2, 0.0, 0.0))
			_part(neck, _cone(0.05, 0.09, 0.18), iron, Vector3(0.0, 0.93, 0.7))
			_part(head, _sphere(0.06), red, Vector3(0.0, 1.42, 0.82))
			_part(load, _cone(0.012, 0.012, 1.1), wood, Vector3(0.12, 1.5, -0.2))
			_part(load, _box(Vector3(0.01, 0.2, 0.28)), _mat("#3E6B8E"), Vector3(0.12, 1.9, -0.06))
		var ap: AnimationPlayer = fig.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Idle", "Eating"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		for g in fig.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.visible = false
		y["node"] = root
		y["ap"] = ap
		y["load"] = load
	if ResourceLoader.exists(DOG):  # Sengé, black, his red fringe collar
		var d: Node3D = (load(DOG) as PackedScene).instantiate()
		var droot := Node3D.new()
		droot.name = "Senge"
		add_child(droot)
		d.scale = Vector3(1.5, 1.0, 1.0)
		droot.add_child(d)
		var black := _mat("#16110E")  # the fox's own painting off: a black mastiff (ANI-04)
		for mi in d.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = black
		var dsk: Skeleton3D = d.find_children("*", "Skeleton3D", true, false)[0]
		var ring := TorusMesh.new()
		ring.inner_radius = 0.08
		ring.outer_radius = 0.12
		var nb := dsk.find_bone("Spine_4")
		if nb >= 0:
			var neck := _on_bone(d, dsk, "Spine_4")
			var rp := (_rel(d, dsk) * dsk.get_bone_global_rest(nb)).origin
			_part(neck, ring, red, rp + Vector3(0.0, 0.02, 0.05), Vector3(1.3, 0.0, 0.0))
		var dap: AnimationPlayer = d.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Run", "Idle", "Idle Alert", "Sit"]:
			if dap.has_animation(n):
				dap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		droot.visible = false
		dog = {"node": droot, "ap": dap, "clip": "", "stop": 0.0}
	# the platform in Yard 0 and the cases as they come off
	var pl: Array = c["platform"]
	var pp := Town.to_godot(float(pl[0]), float(pl[1]), float(pl[2]))
	var plat := _part(self, _box(Vector3(6.0, 0.45, 1.4)), wood, pp + Vector3(0.0, 0.225, 0.0))
	plat.name = "Platform"
	for k in N * 2:
		var cs := _part(self, _box(Vector3(0.62, 0.34, 0.38)), hide_, pp + Vector3(-2.5 + (k / 2 % 5) * 1.25 + (k % 2) * 0.0, 0.45 + 0.17 + (k % 2) * 0.35, 0.0 + (k / 10) * 0.42 - 0.2))
		cs.visible = false
		platform_cases.append(cs)


static func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 12
	m.rings = 6
	return m


static func _cone(r0: float, r1: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = r0
	m.top_radius = r1
	m.height = h
	m.radial_segments = 8
	return m


# ------------------------------------------------------------------ each frame
## The caravan at the clock's minute: each yak where its working out has it, in its clip; the loads off as the
## unloading goes; Sengé ahead of the lead; the drovers placed through named.gd.
func update(_eye: Vector3) -> void:
	var m := fposmod(WorldClock.minute, 1440.0)
	var frozen: bool = WorldClock.frozen
	var g: float = WorldClock.anim_time
	var lead_s := -1.0
	var lead_pos := Vector3.ZERO
	var lead_yaw := 0.0
	var last_pos := Vector3.ZERO
	var last_yaw := 0.0
	var out_now := m >= start and m < done_minute + 1.0
	var coming := m < LEAVE
	for i in N:
		var y: Dictionary = yaks[i]
		var root: Node3D = y["node"]
		var knots: Array = y["knots"] if coming else y["back"]
		var path: PackedVector3Array = y["path"] if coming else y["back_path"]
		var cum: PackedFloat32Array = y["cum"] if coming else y["back_cum"]
		var s := _s_at(knots, m)
		var shown := out_now and s >= 0.0  # on this side of the slot
		if not coming and s >= cum[cum.size() - 1] - 0.01:
			shown = false  # gone past the deck's end, to the camp
		root.visible = shown
		if i == 0 and not shown:
			_bell(root, false)
		if not shown:
			continue
		var p := _at(path, cum, s)
		var ahead := _at(path, cum, s + 0.6)
		var d := ahead - p
		var moving := _s_at(knots, m + 0.05) - s > 0.001
		var yaw_ := atan2(d.x, d.z) if Vector2(d.x, d.z).length() > 0.01 else root.rotation.y
		if coming and s >= cum[cum.size() - 1] - 0.05:
			yaw_ = float(y["face"])  # at its place, facing the platform
		root.position = p
		root.rotation.y = yaw_
		var clip := "Walk" if moving else ("Eating" if m > UNLOAD + UNLOAD_EVERY * i + 5.0 and coming else "Idle")
		_play(y, clip, 1.0 if not moving else SPEED["ramp"] / YAK_WALK * 1.2, frozen, g, i)
		(y["load"] as Node3D).visible = m < UNLOAD + UNLOAD_EVERY * i  # lifted off, onto the platform
		if i == 0:
			lead_s = s
			lead_pos = p
			lead_yaw = yaw_
			_bell(root, moving and not frozen)
		last_pos = p
		last_yaw = yaw_
	for k in platform_cases.size():
		var unloaded := int(floor((m - UNLOAD) / UNLOAD_EVERY)) + 1 if m >= UNLOAD else 0
		platform_cases[k].visible = m >= UNLOAD and m < LEAVE + 60.0 and k < mini(unloaded, N) * 2
	_place_dog(m, lead_s, lead_pos, lead_yaw, out_now, coming, frozen, g)
	_place_drovers(m, lead_pos, lead_yaw, last_pos, last_yaw, out_now, coming)


## The lead's iron bell and the file's small bells (SND-402, a stand-in): a player of their own on the lead, ringing while
## it walks, heard down the slot from the gallery to the bridge.
func _bell(root: Node3D, on: bool) -> void:
	var p := root.get_node_or_null("Bell") as AudioStreamPlayer3D
	if not on:
		if p != null and p.playing:
			p.stop()
		return
	if p == null:
		var ad := get_node_or_null("/root/AudioDirector")
		var st: AudioStream = ad.call("stream", BELL) if ad != null else null
		if st == null:
			return
		p = AudioStreamPlayer3D.new()
		p.name = "Bell"
		p.stream = st
		p.bus = &"Animals"
		p.unit_size = 4.0
		p.max_distance = BELL_HEARD
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.position = Vector3(0.0, 1.0, 0.9)  # at its neck
		root.add_child(p)
	if not p.playing:
		p.play(randf() * 9.0)


func _play(y: Dictionary, clip: String, speed: float, frozen: bool, g: float, i: int) -> void:
	var ap: AnimationPlayer = y["ap"]
	if not ap.has_animation(clip):
		clip = "Idle"
	if y["clip"] != clip:
		ap.play(clip, 0.0 if frozen or y["clip"] == "" else 0.3)
		y["clip"] = clip
	if frozen:
		ap.speed_scale = 0.0
		ap.seek(fposmod(g * speed + i * 0.37, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = speed


func _place_dog(m: float, lead_s: float, lead_pos: Vector3, lead_yaw: float, out_now: bool, coming: bool, frozen: bool, g: float) -> void:
	if dog.is_empty():
		return
	var root: Node3D = dog["node"]
	root.visible = out_now and lead_s >= 0.0 and lead_pos != Vector3.ZERO
	if not root.visible:
		return
	var clip := "Walk"
	var p := lead_pos
	var yaw_ := lead_yaw
	if coming:
		# ranging 8 m ahead of the lead on its way; at the Yak Gate he stops and looks at the town while the file comes up
		var s := lead_s + 8.0
		var at_gate := lead_s + 8.0 >= gate_s and lead_s + 8.0 - gate_s < 0.65 * GATE_STOP
		if at_gate:
			s = gate_s
			clip = "Idle Alert"
		s = minf(s, way_cum[way_cum.size() - 1] + 2.0)
		p = _at(way, way_cum, s)
		var d := _at(way, way_cum, s + 0.6) - p
		if Vector2(d.x, d.z).length() > 0.01:
			yaw_ = atan2(d.x, d.z)
		if at_gate:
			yaw_ += 0.9  # turned to the town
		if lead_s >= way_cum[way_cum.size() - 1] - 1.0:
			clip = "Sit"
	else:
		p = lead_pos + Vector3(sin(lead_yaw), 0.0, cos(lead_yaw)) * 6.0
	root.position = p
	root.rotation.y = yaw_
	var ap: AnimationPlayer = dog["ap"]
	if not ap.has_animation(clip):
		clip = "Idle"
	if dog["clip"] != clip:
		ap.play(clip, 0.0 if frozen else 0.3)
		dog["clip"] = clip
	if frozen:
		ap.speed_scale = 0.0
		ap.seek(fposmod(g, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = SPEED["ramp"] / DOG_WALK if clip == "Walk" else 1.0


func _place_drovers(m: float, lead_pos: Vector3, lead_yaw: float, last_pos: Vector3, last_yaw: float, out_now: bool, coming: bool) -> void:
	if named == null:
		return
	for k in 2:
		var w: int = drovers[k]
		if w < 0:
			continue
		if not out_now:
			named.overrides.erase(w)
			continue
		var fwd := Vector3(sin(lead_yaw if k == 0 else last_yaw), 0.0, cos(lead_yaw if k == 0 else last_yaw))
		var side := Vector3(fwd.z, 0.0, -fwd.x)
		var p: Vector3
		var yaw_: float
		var state := 0
		if k == 0:  # at the head, by the lead's horns
			p = lead_pos + fwd * 1.3 + side * 0.7
			yaw_ = lead_yaw
		else:  # at the tail, driving
			p = last_pos - fwd * 3.0 - side * 0.6
			yaw_ = last_yaw
		var yard: bool = coming and m > UNLOAD - 5.0
		if yard:  # in Yard 0 by the platform, at the unloading
			var pl := (get_node("Platform") as Node3D).position
			p = pl + Vector3(-1.2 + 2.4 * k, -0.225, 1.4)
			yaw_ = PI
			state = 4
		named.overrides[w] = {"pos": p, "yaw": yaw_, "speed": 0.0 if yard else SPEED["ramp"], "state": state}
