extends Node3D
## The town's birds on the wing (plan chapter 06, 6.1, chapter 02's counts; M1 sprint 8, step 2: "choughs wheeling over
## the roofs and the rock ... each flock its own"; Greg, 27 Sep 2026: the town alive, nothing alike). Four kinds on the
## stand-in bird's VAT (people2/stand_ins.py), each one MultiMesh flown on the GPU by characters/vat_flock.gdshader:
## - red-billed choughs, 30: two flocks round the monastery's walls, one along the ritro cliff, and a party of three
##   that comes down over Shöl's roofs; buoyant, tumbling; out from their roost in the Tsokchen's eaves from 06:30, in
##   again by 18:40; calling, most in the afternoon wind (SND-414);
## - ravens, 10: five pairs, slow over the caravan ground, Hejie, Shöl, Tödé and the slope above, one a little behind
##   the other, from 06:00 to 19:00;
## - Himalayan griffons, 5: over the spur and the durtro shoulder on the midday thermals, slow circles, 20-40 s a turn,
##   never a wingbeat, from 10:30 to 16:00;
## - hill pigeons, 40: tight flocks wheeling fast over Tsongra, Hejie and Samkha, 15 m over the roofs, from 06:15 to
##   18:45 (chapter 02: pigeons in every district).
## Each flock is seeded by its name: its ring and how drawn out, its pace, direction and wander, and each bird's place
## in it. Its height is a cruising height: no bird goes lower than its kind's floor over the ground under it, so a flock
## rises with the slope over the higher roofs and the rock and comes down again over the low ground. `pos_at` is the
## shader's flight in GDScript, so a call comes from the bird that makes it.

const FLOCK := preload("res://characters/vat_flock.gdshader")
const Horizon := preload("res://world/horizon.gd")

## size: the stand-in's 3.3 m of wing scaled to the bird's; floor: metres over the ground it keeps (over the roofs);
## flap: the share of the time on the wing it beats; cycle: seconds of a flap-and-glide turn; rate: its wingbeat's pace;
## out: game minutes [first out, all out, first in, all in]; spread: how far round its ring a flock is strung (radians;
## 0: evenly all round, the griffons each on its own in a thermal); vary: each bird's radius, height (m) and bob (m)
const KINDS := {
	"chough": {"size": 0.25, "floor": 18.0, "colour": Color("#141318"), "flap": 0.55, "cycle": 3.5, "rate": 1.15, "out": [390.0, 410.0, 1090.0, 1120.0], "spread": 0.5, "vary": [0.15, 4.0, 2.0, 6.0]},
	"raven": {"size": 0.4, "floor": 22.0, "colour": Color("#121216"), "flap": 0.7, "cycle": 5.0, "rate": 0.85, "out": [360.0, 375.0, 1125.0, 1140.0], "spread": 0.12, "vary": [0.08, 2.0, 2.0, 5.0]},
	"griffon": {"size": 0.86, "floor": 90.0, "colour": Color("#9E8763"), "flap": 0.0, "cycle": 10.0, "rate": 0.5, "out": [630.0, 660.0, 930.0, 960.0], "spread": 0.0, "vary": [0.3, 60.0, 10.0, 30.0]},
	"pigeon": {"size": 0.2, "floor": 15.0, "colour": Color("#8C8F98"), "flap": 0.85, "cycle": 2.5, "rate": 1.6, "out": [375.0, 390.0, 1110.0, 1125.0], "spread": 0.35, "vary": [0.1, 3.0, 1.0, 3.0]},
}
## name: kind, birds, the ring's centre in the town grid (x east, y north, height), its radius (m), a turn's seconds,
## tumble (m, the choughs' dive), wander (m), and optionally [how drawn out (z/x), its long axis's bearing]; else each
## flock's ellipse and bearing are its seed's, as its direction and phase always are
const FLOCKS := {
	"gonpa_south": ["chough", 12, Vector3(560.0, 115.0, 3000.0), 55.0, 14.0, 18.0, 40.0],
	"gonpa_west": ["chough", 7, Vector3(465.0, 95.0, 2955.0), 35.0, 11.0, 14.0, 25.0],
	# along the ritro cliff, 90 m out from the Guru's cave (it faces 230 degrees), the ring laid along the face
	"ritro": ["chough", 8, Vector3(1011.0, 342.0, 3370.0), 40.0, 12.0, 20.0, 15.0, [0.4, 140.0]],
	# down over Tsongra and the lower roofs, rising over the upper ones
	"shol_roofs": ["chough", 3, Vector3(-15.0, 20.0, 2700.0), 45.0, 16.0, 10.0, 30.0],
	"ravens_camp": ["raven", 2, Vector3(-320.0, -220.0, 2650.0), 45.0, 26.0, 0.0, 30.0],
	"ravens_hejie": ["raven", 2, Vector3(-340.0, -60.0, 2640.0), 35.0, 22.0, 0.0, 25.0],
	"ravens_shol": ["raven", 2, Vector3(110.0, 160.0, 2800.0), 40.0, 24.0, 0.0, 35.0],
	"ravens_tode": ["raven", 2, Vector3(-160.0, 450.0, 2920.0), 50.0, 28.0, 0.0, 40.0],
	"ravens_slope": ["raven", 2, Vector3(20.0, 820.0, 3130.0), 60.0, 30.0, 0.0, 50.0],
	"griffons_spur": ["griffon", 3, Vector3(800.0, 220.0, 3260.0), 120.0, 30.0, 0.0, 60.0],
	"griffons_durtro": ["griffon", 2, Vector3(1140.0, -1000.0, 3400.0), 100.0, 26.0, 0.0, 50.0],
	"pigeons_tsongra": ["pigeon", 12, Vector3(-30.0, -10.0, 2688.0), 28.0, 9.0, 0.0, 20.0],
	"pigeons_hejie": ["pigeon", 18, Vector3(-330.0, -60.0, 2618.0), 35.0, 10.0, 0.0, 30.0],
	"pigeons_samkha": ["pigeon", 10, Vector3(-10.0, -100.0, 2650.0), 30.0, 8.0, 0.0, 25.0],
}
const CALL := "SND-414"
const HEARD := 450.0  ## metres: a flock further off does not call (its calls carry 400 m, data/sound.json)

var flocks: Dictionary = {}  ## name -> {kind, birds: [instance indices], centre (Godot space)}
var birds: Dictionary = {}  ## kind -> [[centre, c0, c1, c2], ...] in instance order, as the shader reads them
var mmis: Dictionary = {}  ## kind -> MultiMeshInstance3D
var _call_at: Dictionary = {}  ## chough flock -> seconds of anim time of its next call
var _burst: Dictionary = {}  ## chough flock -> calls left in its burst
var _dice := RandomNumberGenerator.new()  ## the calls' own, never the global stream (the seeded scenes draw from that)


## Builds the four MultiMeshes, one a kind. `to_godot` maps the town grid (x, y, height) to Godot space (world/town.gd's).
func build(to_godot: Callable) -> Dictionary:
	var vat := VatSet.open("bird")
	var per: Dictionary = {}
	for name in FLOCKS:
		var f: Array = FLOCKS[name]
		per[f[0]] = int(per.get(f[0], 0)) + int(f[1])
	for kind in KINDS:
		var k: Dictionary = KINDS[kind]
		var mat := ShaderMaterial.new()
		mat.shader = FLOCK
		mat.set_shader_parameter("vat", vat.texture)
		mat.set_shader_parameter("vat_fps", float(vat.info["fps"]))
		mat.set_shader_parameter("normal_row", float(vat.info["normal_row"]))
		var fl := vat.clip("Flap")
		var gl := vat.clip("Glide")
		mat.set_shader_parameter("flap_clip", Vector2(fl["row"], fl["frames"]))
		mat.set_shader_parameter("glide_clip", Vector2(gl["row"], gl["frames"]))
		mat.set_shader_parameter("size", float(k["size"]))
		mat.set_shader_parameter("floor_clear", float(k["floor"]))
		mat.set_shader_parameter("body_color", k["colour"])
		var mmi := vat.multimesh(int(per[kind]), AABB())
		mmi.name = "Birds_" + kind
		mmi.material_override = mat
		add_child(mmi)
		mmis[kind] = mmi
		birds[kind] = []
	# each flock's birds, then every kind's instances ordered so that its last ones are each flock's last: the day's
	# thinning (visible_instance_count) takes birds from every flock alike
	var order: Dictionary = {}
	for kind in KINDS:
		order[kind] = []
	for name in FLOCKS:
		var f: Array = FLOCKS[name]
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(name)
		var centre: Vector3 = to_godot.call(f[2].x, f[2].y, f[2].z)
		var radius: float = f[3]
		var w := TAU / float(f[4]) * (1.0 if rng.randf() < 0.5 else -1.0)
		var ratio := rng.randf_range(0.45, 0.9)
		var angle := rng.randf() * PI
		if f.size() > 7:  # its ellipse fixed: the long axis along a bearing (clockwise from north; Godot's -Z)
			ratio = float(f[7][0])
			angle = deg_to_rad(float(f[7][1])) - PI / 2.0
		var tumble: float = f[5]
		var wander: float = f[6]
		var wander_rate := rng.randf_range(0.015, 0.04) * (1.0 if rng.randf() < 0.5 else -1.0)
		var kd: Dictionary = KINDS[f[0]]
		var vary: Array = kd["vary"]
		var bob := rng.randf_range(float(vary[2]), float(vary[3]))
		var ph0 := rng.randf() * TAU
		var n: int = f[1]
		var spread: float = kd["spread"]
		flocks[name] = {"kind": f[0], "birds": [], "centre": centre}
		for i in n:
			# a flock, not a ring: the birds close in phase (a pair a length apart), each on its own radius and height;
			# or, spread 0, evenly round it, each at its own pace (griffons in a thermal)
			var at := (float(i) - float(n - 1) / 2.0) * (spread / maxf(float(n - 1), 1.0) if spread > 0.0 else TAU / float(n))
			var ph := ph0 + at + rng.randf_range(-0.05, 0.05)
			var r := radius * rng.randf_range(1.0 - float(vary[0]), 1.0 + float(vary[0]))
			var c := centre + Vector3(0.0, rng.randf_range(-float(vary[1]), float(vary[1])), 0.0)
			var c0 := Vector3(r, w * (1.0 if spread > 0.0 else rng.randf_range(0.85, 1.15)), ph)
			var c1 := Vector3(bob * rng.randf_range(0.7, 1.3), wander, wander_rate)
			var c2 := Vector3(ratio, angle, tumble * rng.randf_range(0.6, 1.2) if tumble > 0.0 else 0.0)
			(order[f[0]] as Array).append([float(i + 1) / float(n) + rng.randf() * 0.01, name, [c, c0, c1, c2], rng.randf_range(0.85, 1.15)])
	for kind in KINDS:
		var list: Array = order[kind]
		list.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
		var mm: MultiMesh = (mmis[kind] as MultiMeshInstance3D).multimesh
		var buf := PackedFloat32Array()
		buf.resize(list.size() * VatSet.FLOATS)
		var k: Dictionary = KINDS[kind]
		var lo := Vector3.INF
		var hi := -Vector3.INF
		for j in list.size():
			var e: Array = list[j]
			var p: Array = e[2]
			(birds[kind] as Array).append(p)
			(flocks[e[1]]["birds"] as Array).append(j)
			var o := j * VatSet.FLOATS
			var c: Vector3 = p[0]
			var c0: Vector3 = p[1]
			var c1: Vector3 = p[2]
			var c2: Vector3 = p[3]
			buf[o] = c0.x
			buf[o + 4] = c0.y
			buf[o + 8] = c0.z
			buf[o + 1] = c1.x
			buf[o + 5] = c1.y
			buf[o + 9] = c1.z
			buf[o + 2] = c2.x
			buf[o + 6] = c2.y
			buf[o + 10] = c2.z
			buf[o + 3] = c.x
			buf[o + 7] = c.y
			buf[o + 11] = c.z
			buf[o + 12] = 1.0
			buf[o + 13] = 1.0
			buf[o + 14] = 1.0
			buf[o + 15] = float(e[3])  # the body's shade
			buf[o + 16] = float(k["flap"])
			buf[o + 17] = float(k["cycle"]) * float(e[3])
			buf[o + 18] = float(j) * 3.7
			buf[o + 19] = float(k["rate"]) * float(e[3])
			var reach := c0.x * 1.3 + c1.y + 3.0
			lo = lo.min(c - Vector3(reach, c1.x + c2.z + 3.0, reach))
			hi = hi.max(c + Vector3(reach, c1.x + 3.0, reach))
			hi.y = maxf(hi.y, _highest(c, reach) + float(k["floor"]) + 6.0)  # risen with the slope under it
		mm.buffer = buf
		mm.custom_aabb = AABB(lo, hi - lo)
	for name in flocks:
		if flocks[name]["kind"] == "chough":
			_call_at[name] = _dice.randf_range(1.0, 6.0)
			_burst[name] = 0
	_day()
	return {"flocks": flocks.size(), "chough": (birds["chough"] as Array).size(), "raven": (birds["raven"] as Array).size(), "griffon": (birds["griffon"] as Array).size()}


## The highest ground within `reach` of `c` (the horizon map), or far below.
func _highest(c: Vector3, reach: float) -> float:
	var top := -1e6
	for k in 32:
		for f in [0.0, 0.5, 1.0]:
			var a := TAU * float(k) / 32.0
			var g := Horizon.ground_at(c.x + cos(a) * reach * float(f), -(c.z + sin(a) * reach * float(f)))
			if not is_nan(g):
				top = maxf(top, g)
	return top


## Where bird `i` of `kind` is at animation time `t`: the shader's `flight`.
func pos_at(kind: String, i: int, t: float) -> Vector3:
	var p: Array = (birds[kind] as Array)[i]
	var centre: Vector3 = p[0]
	var c0: Vector3 = p[1]
	var c1: Vector3 = p[2]
	var c2: Vector3 = p[3]
	var ang := t * c0.y + c0.z
	var wp := c1.z * t + centre.x * 0.013 + centre.z * 0.007
	var c := centre + Vector3(cos(wp), 0.0, sin(wp * 0.7 + 1.3)) * c1.y
	var ex := cos(ang) * c0.x
	var ez := sin(ang) * c0.x * c2.x
	var ca := cos(c2.y)
	var sa := sin(c2.y)
	var dive := c2.z * pow(maxf(0.0, sin(t * 0.37 + c0.z * 5.0)), 24.0)
	var q := c + Vector3(ex * ca - ez * sa, sin(ang * 2.0 + c0.z) * c1.x - dive, ex * sa + ez * ca)
	var g := Horizon.ground_at(q.x, -q.z)
	if not is_nan(g):
		var lo: float = g + float(KINDS[kind]["floor"])
		var hh := maxf(10.0 - absf(q.y - lo), 0.0) / 10.0
		q.y = maxf(q.y, lo) + hh * hh * 10.0 * 0.25
	return q


## How many of a kind are out at `minute` of the day: all by day, none by night, one by one between.
static func out_count(kind: String, n: int, minute: float) -> int:
	var o: Array = KINDS[kind]["out"]
	var m := fposmod(minute, 1440.0)
	var f := clampf((m - float(o[0])) / maxf(float(o[1]) - float(o[0]), 1.0), 0.0, 1.0) * clampf((float(o[3]) - m) / maxf(float(o[3]) - float(o[2]), 1.0), 0.0, 1.0)
	return int(round(f * float(n)))


func _day() -> void:
	for kind in mmis:
		var mm: MultiMesh = (mmis[kind] as MultiMeshInstance3D).multimesh
		var n := out_count(kind, mm.instance_count, WorldClock.minute)
		if mm.visible_instance_count != n:
			mm.visible_instance_count = n
		(mmis[kind] as MultiMeshInstance3D).visible = n > 0


func _process(_dt: float) -> void:
	if mmis.is_empty():
		return
	_day()
	var t := WorldClock.anim_time
	var m := fposmod(WorldClock.minute, 1440.0)
	var windy := m >= 840.0 and m <= 1020.0  # "loudest in the afternoon wind" (chapter 06, 6.4)
	var out: int = (mmis["chough"] as MultiMeshInstance3D).multimesh.visible_instance_count
	var ear: Vector3 = AudioDirector.sound.call("listener") if is_instance_valid(AudioDirector) else Vector3.ZERO
	for name in _call_at:
		if t < float(_call_at[name]):
			continue
		if (flocks[name]["centre"] as Vector3).distance_to(ear) > HEARD:  # too far to be heard: no voice spent on it
			_call_at[name] = t + 5.0
			continue
		var idx: Array = flocks[name]["birds"]
		var here: Array = idx.filter(func(j): return int(j) < out)
		if here.is_empty():
			_call_at[name] = t + 20.0
			continue
		if int(_burst[name]) <= 0:
			_burst[name] = _dice.randi_range(1, 3)
		_burst[name] = int(_burst[name]) - 1
		var j: int = here[_dice.randi() % here.size()]
		if is_instance_valid(AudioDirector):
			AudioDirector.play(CALL, pos_at("chough", j, t))
		_call_at[name] = t + (_dice.randf_range(0.25, 0.7) if int(_burst[name]) > 0 else _dice.randf_range(6.0, 18.0) * (0.6 if windy else 1.0))
