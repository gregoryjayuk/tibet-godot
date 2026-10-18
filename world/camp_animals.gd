extends Node3D
## The Caravan Ground's other beasts (M2 sprint 9, step 3; plan chapter 06, 8.6: "about 132 yak lying and chewing, 12
## Tibetan mules on the picket line and the hirer's 8 Chinese mules in his corral, 9 riding ponies, 5 mastiffs"): CV-01's
## 60 yak, the Litang monastery's wool caravan up from the river crossing by 11:00, eating at their hay by their stacks
## and tents and lying down in twos and threes through the afternoon; the twelve mules and nine ponies picketed by the
## near fore pastern along the rope from 17:00 till the morning, a mastiff tied at each end; the Hui hirer's eight Chinese
## mules in his corral all day. Their places are tools/town/caravan_ground.py's (data/caravan_ground.json `animals`);
## CV-02's own are world/herd.gd's. Drawn as VAT MultiMeshes with shadows; nothing moves but the clips, so the buffers
## are written again only when a beast's state changes. A yak lying is the unladen yak at rest sunk into the turf
## (no lying clip yet: ISS-162). Added by world/town.gd.

const DATA := "res://data/caravan_ground.json"
const Town := preload("res://world/town.gd")
const Herd := preload("res://world/herd.gd")
const CV01_FROM := 660.0  ## 11:00: CV-01 up from the river and unloaded (chapter 06's day)
const CV01_EAT := [670.0, 930.0]  ## at its hay, then lying where it ate
const CV01_LIE := 720.0  ## the rest lying from 12:00
const PICKET := [1010.0, 1740.0]  ## 16:50 to 05:00 the next morning (the herd's day from 04:00)
const LIE_SINK := 0.55

var beasts: Array = []  ## [kind, Vector3 (Godot), yaw, role, tint, phase]
var sets := {}  ## kind -> [VatSet, MultiMeshInstance3D, PackedFloat32Array, [indices into beasts]]
var _last := -1.0
var counts := {"yak": 0, "mule": 0, "pony": 0, "mastiff": 0}


func build(ground: Callable = Callable()) -> Dictionary:
	if not FileAccess.file_exists(DATA):
		return counts
	var an: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA)).get("animals", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = 6101
	var add := func(kind: String, q: Array, role: String) -> void:
		var p := Town.to_godot(float(q[0]), float(q[1]), float(q[2]))
		if ground.is_valid():
			var g = ground.call(p.x, p.z)
			if g != null and not is_nan(float(g)) and absf(float(g) - p.y) < 40.0:
				p.y = float(g)
		beasts.append([kind, p, deg_to_rad(180.0 - float(q[3])), role, rng.randf_range(0.8, 1.2), rng.randf() * 40.0])
	for q in an.get("cv01", []):
		add.call("yak_free", q, "cv01_" + String(q[4]))
	for q in an.get("picket", []):
		add.call(String(q[0]), [q[1], q[2], q[3], q[4]], "picket")
	for q in an.get("corral", []):
		add.call("mule", q, "corral")
	var bounds := AABB(beasts[0][1] if not beasts.is_empty() else Vector3.ZERO, Vector3.ZERO)
	for b in beasts:
		bounds = bounds.expand(b[1])
	bounds = bounds.grow(6.0)
	for k in beasts.size():
		var kind := String(beasts[k][0])
		if not sets.has(kind):
			if not ResourceLoader.exists(VatSet.DIR + kind + "_vat.glb"):
				continue
			var v := VatSet.open(kind)
			sets[kind] = [v, null, PackedFloat32Array(), []]
		(sets[kind][3] as Array).append(k)
	for kind in sets:
		var st: Array = sets[kind]
		var mmi: MultiMeshInstance3D = (st[0] as VatSet).multimesh((st[3] as Array).size(), bounds)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mmi)
		st[1] = mmi
		var buf := PackedFloat32Array()
		buf.resize((st[3] as Array).size() * VatSet.FLOATS)
		st[2] = buf  # (resized through a cast, the stored array had stayed empty)
		counts[kind.trim_suffix("_free")] = (st[3] as Array).size()
	_process(0.0)
	return counts


## What a beast with `role` does at minute m of the herd's day (from 04:00): "" not there, or its clip and whether it lies.
static func state_of(role: String, m: float, order: int) -> Array:
	match role:
		"cv01_eat":
			if m < CV01_FROM:
				return [""]
			return ["Eating", false] if m < CV01_EAT[1] + float(order % 7) * 8.0 else ["Idle", true]
		"cv01_lie":
			if m < CV01_FROM:
				return [""]
			return ["Idle", m >= CV01_LIE + float(order % 5) * 9.0]
		"cv01_stand":
			return [""] if m < CV01_FROM else (["Eating", false] if order % 2 == 0 else ["Idle", false])
		"picket":
			return ["Eating" if order % 3 == 0 else "Idle", false] if m >= PICKET[0] and m < PICKET[1] else [""]
		"corral":
			return ["Eating" if order % 2 == 0 else "Idle", false]
	return [""]


func _process(_dt: float) -> void:
	var m := Herd.day_minute(WorldClock.minute)
	if absf(m - _last) < 0.5:
		return
	_last = m
	for kind in sets:
		var st: Array = sets[kind]
		var v: VatSet = st[0]
		var buf: PackedFloat32Array = st[2]
		var idx: Array = st[3]
		for j in idx.size():
			var b: Array = beasts[idx[j]]
			var role := String(b[3])
			var sk := state_of(role, m, int(idx[j]))
			if String(sk[0]) == "":
				Herd.put_none(buf, j)
				continue
			var clip := String(sk[0]) if v.info["clips"].has(String(sk[0])) else "Idle"
			if kind == "mastiff":
				clip = "Sit"
			var lies: bool = sk.size() > 1 and bool(sk[1])
			var p: Vector3 = b[1] - Vector3(0.0, LIE_SINK if lies else 0.0, 0.0)
			Herd.put(buf, j, p, float(b[2]), 1.5 if kind == "yak_free" or kind == "mastiff" else 1.0, float(b[4]), v.clip(clip), float(b[5]), 0.35 if lies else 1.0)
		(st[1] as MultiMeshInstance3D).multimesh.buffer = buf
