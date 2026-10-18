extends Node3D
## Who is there at Pema Ö Lhakhang and the Conch terrace at first sun (M2 sprint 5, step 5; plan chapter 05, NPC-09's day;
## chapter 08, V-02), added by world/town.gd with the people:
## - Lama Orgyen Dorje (NPC-09): on his seat in the hall from 06:00; at 06:38 down the aisle, out through the porch and
##   down the stair to the Conch terrace's burner, where he lays juniper at 06:45 (its smoke: world/dusk.gd LATE); at
##   06:50 to the lip, where he stands facing the pool and up the Serchu, doing nothing at all, until the first sun has
##   lain on the water (07:46 on the terrain: chapter 02, 2.8) and a while after; at 07:56 back up to his seat for the
##   08:00 service, sitting through it to 09:30;
## - two of Pema Ö's monks filling the altar's seven offering bowls 06:30-07:20, then on the rows' cushions, facing the
##   aisle, for the service, 07:40-09:30;
## - an old woman walking the kora corridor clockwise, the temple on her right, 06:20-08:40, the wheels turning under her
##   hand as she passes (the group "kora_walkers": world/kora_wheels.gd);
## - a dipper bobbing on a stone in the pool under the terrace's corner, 06:00-18:00.
## Each place is worked out from the clock's minute, so a still is the same each time; drawn only while the camera is
## within SEEN of the temple. `lama_doing`, `monks_doing` and `kora_s` are pure, for the tests.

const PERSON := preload("res://characters/person.gdshader")
const SEEN := 260.0  ## metres from the temple within which they are drawn
const SPEED := 0.75  ## the lama's pace, m/s
const KORA_SPEED := 0.55  ## the old woman's, round the corridor
const PER_MIN := 10.0  ## real seconds a game minute at the play rate (autoload/world_clock.gd)
const LAMA_SEAT := 360.0  ## 06:00: on his seat after his practice
const LAMA_OUT := 398.0  ## 06:38: from his seat down to the terrace
const LAMA_SANG := 410.0  ## 06:50: the juniper laid, to the lip
const LAMA_BACK := 476.0  ## 07:56: up to his seat for the service
const SERVICE_END := 570.0  ## 09:30
const MONKS_BOWLS := [390.0, 440.0]  ## 06:30-07:20 at the altar
const MONKS_SIT := [460.0, 570.0]  ## 07:40-09:30 on the rows
const KORA := [380.0, 520.0]  ## 06:20-08:40
const DIPPER := [360.0, 1080.0]
const LIP := Vector3(8.0, -7.6, 0.05)  ## the lama's place at the terrace's lip, in its frame (kit/confluence.py conch_terrace)
const LIP_BEARING := 113.0  ## facing the pool and up the Serchu, towards the first sun
const DIPPER_AT := Vector2(207.6, -96.9)  ## the town grid: a stone in the slot's head under the terrace's corner

var lama_way: PackedVector3Array  ## his seat to the burner's door (Godot, global)
var lama_cum: PackedFloat32Array
var kora_way: PackedVector3Array  ## the corridor's loop, clockwise, closed
var kora_cum: PackedFloat32Array
var places := {}  ## name -> Transform3D: "seat", "offer", "lip", "bowls_0", "bowls_1", "row_0", "row_1"
var people: Array = []  ## {key, kind, root, ap, clip}
var dipper: Node3D
var _dipper_y := 0.0
var _mat: ShaderMaterial
var _built := false
var _mid := Vector3.ZERO


## What the lama is doing at minute `m`: "away", "seat", "down" (walking to the burner), "sang", "to_lip", "lip", "up"
## (back to his seat), "service".
static func lama_doing(m: float, way_len: float) -> String:
	var down_end := LAMA_OUT + way_len / (SPEED * PER_MIN)
	var up_end := LAMA_BACK + (way_len + 3.5) / (SPEED * PER_MIN)
	if m < LAMA_SEAT or m >= SERVICE_END:
		return "away"
	if m < LAMA_OUT:
		return "seat"
	if m < down_end:
		return "down"
	if m < LAMA_SANG:
		return "sang"
	if m < LAMA_SANG + 3.5 / (SPEED * PER_MIN):
		return "to_lip"
	if m < LAMA_BACK:
		return "lip"
	if m < up_end:
		return "up"
	return "service"


## What the monks are doing at minute `m`: "away", "bowls", "sit".
static func monks_doing(m: float) -> String:
	if m >= MONKS_BOWLS[0] and m < MONKS_BOWLS[1]:
		return "bowls"
	if m >= MONKS_SIT[0] and m < MONKS_SIT[1]:
		return "sit"
	return "away"


## How far round the corridor the old woman is at minute `m` (metres from its start, a loop of `length`), or -1.
static func kora_s(m: float, length: float) -> float:
	if m < KORA[0] or m >= KORA[1]:
		return -1.0
	return fposmod((m - KORA[0]) * PER_MIN * KORA_SPEED, length)


static func _cum(p: PackedVector3Array) -> PackedFloat32Array:
	var c := PackedFloat32Array([0.0])
	for i in range(1, p.size()):
		c.append(c[i - 1] + p[i].distance_to(p[i - 1]))
	return c


static func _at(p: PackedVector3Array, c: PackedFloat32Array, s: float) -> Vector3:
	s = clampf(s, 0.0, c[c.size() - 1])
	for i in range(1, p.size()):
		if s <= c[i]:
			return p[i - 1].lerp(p[i], (s - c[i - 1]) / maxf(c[i] - c[i - 1], 0.0001))
	return p[p.size() - 1]


static func _dir_at(p: PackedVector3Array, c: PackedFloat32Array, s: float) -> Vector3:
	s = clampf(s, 0.0, c[c.size() - 1])
	for i in range(1, p.size()):
		if s <= c[i]:
			return p[i] - p[i - 1]
	return p[p.size() - 1] - p[p.size() - 2]


## The yaw that faces a bearing (degrees from north, clockwise): the town's y north is Godot's -z.
static func _bearing_yaw(b: float) -> float:
	var r := deg_to_rad(b)
	return atan2(sin(r), -cos(r))


static func _yaw(d: Vector3) -> float:
	return atan2(d.x, d.z) if Vector2(d.x, d.z).length() > 0.0001 else 0.0


## A point in a building's kit frame (x, y, z: its +y its back, z up) in the world.
static func _kit(node: Node3D, x: float, y: float, z: float) -> Vector3:
	return node.global_transform * Vector3(x, z, -y)


## Gathers the places from the temple (SHL-11) and the terrace (SHL-12). The count of who is there.
func build(root: Node3D) -> int:
	var temple := root.get_node_or_null("SHL-11") as Node3D
	var terrace := root.get_node_or_null("SHL-12") as Node3D
	if temple == null or terrace == null:
		return 0
	_mid = temple.global_position
	var into := temple.global_transform.basis * Vector3(0.0, 0.0, -1.0)  # the kit's +y: from the door towards the altar
	var aisle := temple.global_transform.basis * Vector3(1.0, 0.0, 0.0)  # its +x
	# the lama's seat (SOCK_SEAT_1, facing the door), the hips 0.4 m behind the sitting pose's root (Sitting_Cross)
	var seat := temple.find_child("SOCK_SEAT_1", true, false) as Node3D
	var seat_p := seat.global_position if seat != null else _kit(temple, 2.0, 4.6, 0.92)
	places["seat"] = Transform3D(Basis(Vector3.UP, _yaw(-into)), seat_p - into * 0.4)
	for q in [[2.0, 4.0, 0.0], [1.0, 3.6, 0.0], [0.0, 3.0, 0.0], [0.0, -2.0, 0.0], [0.0, -4.6, 0.0], [0.0, -7.6, 0.0],
			[0.0, -12.3, 0.0], [0.0, -28.5, -6.0]]:
		lama_way.append(_kit(temple, q[0], q[1], q[2]))
	for q in [[-2.0, 2.0], [5.0, -2.0]]:  # across the terrace to the burner
		lama_way.append(_kit(terrace, q[0], q[1], 0.05))
	var offer := terrace.find_child("SOCK_OFFER_1", true, false) as Node3D
	var offer_p := offer.global_position if offer != null else _kit(terrace, 11.0, -6.34, 0.05)
	lama_way.append(offer_p)
	lama_cum = _cum(lama_way)
	var burner := terrace.find_child("SOCK_SANG_1", true, false) as Node3D
	var to_burner := (burner.global_position - offer_p) if burner != null else Vector3(0.0, 0.0, -1.0)
	places["offer"] = Transform3D(Basis(Vector3.UP, _yaw(to_burner)), offer_p)
	places["lip"] = Transform3D(Basis(Vector3.UP, _bearing_yaw(LIP_BEARING)), _kit(terrace, LIP.x, LIP.y, LIP.z))
	# the monks at the bowls (SOCK_BOWLS_1), facing the altar; on the rows' cushions facing the aisle
	var bowls := temple.find_child("SOCK_BOWLS_1", true, false) as Node3D
	var bowls_p := bowls.global_position if bowls != null else _kit(temple, 0.0, 4.25, 0.0)
	for k in 2:
		places["bowls_%d" % k] = Transform3D(Basis(Vector3.UP, _yaw(into)), bowls_p + aisle * (-0.45 + 0.9 * k))
	places["row_0"] = Transform3D(Basis(Vector3.UP, _yaw(aisle)), _kit(temple, -1.1, 1.6, 0.34))
	places["row_1"] = Transform3D(Basis(Vector3.UP, _yaw(-aisle)), _kit(temple, 1.1, 0.0, 0.34))
	# the kora: in at the corridor's front left, round the back, out at the front right, across before the porch
	for q in [[-8.95, -7.9], [-8.95, 7.95], [8.95, 7.95], [8.95, -7.9], [-8.95, -7.9]]:
		kora_way.append(_kit(temple, q[0], q[1], 0.08))
	kora_cum = _cum(kora_way)
	people = [{"key": "lama_orgyen_dorje", "kind": "lama"}, {"key": "pema_monk", "kind": "monk_0"},
			{"key": "pema_monk_b", "kind": "monk_1"}, {"key": "elder_woman", "kind": "kora"}]
	return people.size() + 1


func _bodies() -> void:
	_built = true
	_mat = ShaderMaterial.new()
	_mat.shader = PERSON
	for p in people:
		var path := "res://assets/generated/people/%s.glb" % p["key"]
		if not ResourceLoader.exists(path):
			continue
		var root: Node3D = (load(path) as PackedScene).instantiate()
		root.name = "PemaO_%s" % String(p["kind"])
		PersonLook.apply(root, _mat)
		var ap: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ["Walk", "Walk_Female", "Idle_A", "Idle_FoldArms", "Sitting_Cross", "Sitting_Idle"]:
			if ap.has_animation(n):
				ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		add_child(root)
		root.visible = false
		p["root"] = root
		p["ap"] = ap
		p["clip"] = ""
	_dipper_build()


## The dipper (a white-throated dipper, Cinclus cinclus, at home on the valley's torrents): a dark brown body with a white
## bib, on a wet grey stone in the slot's head.
func _dipper_build() -> void:
	var base := _pool_point(DIPPER_AT)
	dipper = Node3D.new()
	dipper.name = "Dipper"
	add_child(dipper)
	dipper.global_position = base
	var stone := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.32
	sm.height = 0.36
	var sg := StandardMaterial3D.new()
	sg.albedo_color = Color("#5E5A54")
	sg.roughness = 0.9  # wet granite, dull
	sm.material = sg
	stone.mesh = sm
	stone.scale = Vector3(1.0, 0.7, 0.8)
	dipper.add_child(stone)
	var bird := Node3D.new()
	bird.name = "Bird"
	bird.position = Vector3(0.0, 0.17, 0.0)
	dipper.add_child(bird)
	_dipper_y = bird.position.y
	var brown := StandardMaterial3D.new()
	brown.albedo_color = Color("#3A2A22")
	brown.roughness = 0.8
	var white := StandardMaterial3D.new()
	white.albedo_color = Color("#ECE8E0")
	for part in [[Vector3(0.0, 0.07, 0.0), Vector3(0.075, 0.06, 0.1), brown], [Vector3(0.0, 0.12, 0.08), Vector3(0.04, 0.04, 0.045), brown],
			[Vector3(0.0, 0.085, 0.085), Vector3(0.045, 0.045, 0.03), white], [Vector3(0.0, 0.09, -0.12), Vector3(0.025, 0.012, 0.05), brown]]:
		var mi := MeshInstance3D.new()
		var m := SphereMesh.new()
		m.radius = 1.0
		m.height = 2.0
		m.radial_segments = 10
		m.rings = 5
		m.material = part[2]
		mi.mesh = m
		mi.position = part[0]
		mi.scale = part[1]
		bird.add_child(mi)
	for sx in [-1.0, 1.0]:  # its legs, short and pale
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.008, 0.03, 0.008)
		var lg := StandardMaterial3D.new()
		lg.albedo_color = Color("#8C7A6A")
		lm.material = lg
		leg.mesh = lm
		leg.position = Vector3(sx * 0.02, 0.012, 0.0)
		bird.add_child(leg)
	bird.rotation.y = _bearing_yaw(300.0)  # watching the water coming down out of the pool


## A town-grid point at the pool's water: the stone's middle (data/rivers.json "pool"'s level).
func _pool_point(p: Vector2) -> Vector3:
	var z := 2657.1
	if FileAccess.file_exists("res://data/rivers.json"):
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rivers.json"))
		z = float((d.get("pool", {}) as Dictionary).get("z", z))
	return preload("res://world/town.gd").to_godot(p.x, p.y, z + 0.05)


func _process(_dt: float) -> void:
	if lama_way.is_empty():
		return
	var cam := get_viewport().get_camera_3d()
	var on: bool = cam != null and cam.global_position.distance_to(_mid) < SEEN
	if not on:
		for p in people:
			if p.has("root"):
				(p["root"] as Node3D).visible = false
				(p["root"] as Node3D).remove_from_group("kora_walkers")
		if dipper != null:
			dipper.visible = false
		return
	if not _built:
		_bodies()
	var m := fposmod(WorldClock.minute, 1440.0)
	var frozen: bool = WorldClock.frozen
	var g: float = WorldClock.anim_time
	for i in people.size():
		var p: Dictionary = people[i]
		if not p.has("root"):
			continue
		var r := _where(String(p["kind"]), m)  # [shown, transform, clip]
		var root: Node3D = p["root"]
		root.visible = bool(r[0])
		if String(p["kind"]) == "kora":
			if bool(r[0]):
				root.add_to_group("kora_walkers")
			else:
				root.remove_from_group("kora_walkers")
		if not bool(r[0]):
			continue
		root.global_transform = r[1]
		_play(p, String(r[2]), frozen, g, i)
	if dipper != null:
		dipper.visible = m >= DIPPER[0] and m < DIPPER[1]
		var t := g if frozen else Time.get_ticks_msec() / 1000.0
		var bob := absf(sin(t * PI * 1.6))  # a dipper bobs on its stone, a dip and up, never still
		(dipper.get_node("Bird") as Node3D).position.y = _dipper_y - 0.018 * bob


## Where `kind` is at minute `m`: [shown, its transform, its clip].
func _where(kind: String, m: float) -> Array:
	var L := lama_cum[lama_cum.size() - 1]
	match kind:
		"lama":
			var d := lama_doing(m, L)
			match d:
				"seat", "service":
					return [true, places["seat"], "Sitting_Cross"]
				"down":
					return _walking(lama_way, lama_cum, (m - LAMA_OUT) * PER_MIN * SPEED, "Walk")
				"sang":
					return [true, places["offer"], "Idle_A"]
				"to_lip":
					var a: Transform3D = places["offer"]
					var b: Transform3D = places["lip"]
					var f := (m - LAMA_SANG) * PER_MIN * SPEED / 3.5
					return [true, Transform3D(Basis(Vector3.UP, _yaw(b.origin - a.origin)), a.origin.lerp(b.origin, clampf(f, 0.0, 1.0))), "Walk"]
				"lip":
					return [true, places["lip"], "Idle_A"]
				"up":
					var s := (m - LAMA_BACK) * PER_MIN * SPEED - 3.5  # from the lip to the burner's door, then the way back up
					if s < 0.0:
						var a: Transform3D = places["lip"]
						var b: Transform3D = places["offer"]
						return [true, Transform3D(Basis(Vector3.UP, _yaw(b.origin - a.origin)), a.origin.lerp(b.origin, 1.0 + s / 3.5)), "Walk"]
					var r := _walking(lama_way, lama_cum, L - s, "Walk")
					var t: Transform3D = r[1]
					r[1] = Transform3D(t.basis.rotated(Vector3.UP, PI), t.origin)  # walking it the other way
					return r
			return [false, Transform3D(), ""]
		"monk_0", "monk_1":
			var k := 0 if kind == "monk_0" else 1
			match monks_doing(m):
				"bowls":
					return [true, places["bowls_%d" % k], "Idle_A"]
				"sit":
					return [true, places["row_%d" % k], "Sitting_Cross"]
			return [false, Transform3D(), ""]
		"kora":
			var s := kora_s(m, kora_cum[kora_cum.size() - 1])
			if s < 0.0:
				return [false, Transform3D(), ""]
			return _walking(kora_way, kora_cum, s, "Walk_Female")
	return [false, Transform3D(), ""]


func _walking(way: PackedVector3Array, cum: PackedFloat32Array, s: float, clip: String) -> Array:
	var pos := _at(way, cum, s)
	return [true, Transform3D(Basis(Vector3.UP, _yaw(_dir_at(way, cum, s))), pos), clip]


func _play(p: Dictionary, clip: String, frozen: bool, g: float, i: int) -> void:
	var ap: AnimationPlayer = p["ap"]
	if not ap.has_animation(clip):
		clip = "Walk" if clip.begins_with("Walk") and ap.has_animation("Walk") else "Idle_A"
	if String(p["clip"]) != clip:
		ap.play(clip, 0.0 if frozen or String(p["clip"]) == "" else 0.3)
		p["clip"] = clip
	if frozen:  # the stills: the pose from the animation clock
		ap.speed_scale = 0.0
		ap.seek(fposmod(g + i * 0.37, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = 1.0
