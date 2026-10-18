extends Node3D
## The Tsokchen's assemblies (plan chapter 04, 3.1's hours; chapter 08, V-26; the game's M3 sprint 5, step 5): the monks
## seated cross-legged in their rows on the nave's SEAT sockets (tibet-blender kit/tsokchen_rooms.py: the sixteen rows'
## 288 places facing across the aisle, and the three thrones), at the dawn assembly 05:30-07:00 (nearly all), the
## general tea 11:00-11:40 (fewer) and the evening recitation 17:15-18:15; the abbot and the chant leader on their thrones
## at the head of the rows, the tulku on his on good days (the calendar's: the full moon, the new moon, the eighth). Each a
## figure baked sitting (characters/vat_set.gd, its Sitting_Cross), one MultiMesh a body: four monks', and the two novices'
## at the door end's places; drawn only with the camera near the hall (no one sees them through its walls). No chant: the
## hall is heard by its cushions and cups until Greg's consent for sacred sound (chapter 10).
## The disciplinarian, the dge skos (M3 sprint 6, step 2; chapter 04, 3.1: "the boot row (remove boots or be stopped by
## the disciplinarian)"; chapter 08, V-26: "the disciplinarian walking the rows with his staff"): through each session he
## stands by the door's right, arms folded, his staff beside him, and every GEKOE_ROUND minutes walks up the aisle between
## the rows to the thrones and back at a slow, formal pace; where he is follows the clock, so a still finds him there again.

const SIDE := "res://assets/generated/kit/types/tsokchen_nave_v1.json"
const MONKS := ["tode_monk", "tode_monk_b", "tode_monk_c", "gallery_monk"]
const NOVICES := ["novice_c", "novice_d"]
const TULKU := "dungkar_tulku"  ## the fifth Dungkar Tulku's own body (people2/body.py; world/gorge_people.gd)
## [from, to (minutes of the day), the share of the rows' places filled]; the fourth only on the good days: the morning
## assembly 09:30-11:00 (M3 sprint 6, step 3; chapter 08, V-26, the full moon: about 270 monks, the tulku on his throne)
const SESSIONS := [[330.0, 420.0, 0.9], [660.0, 700.0, 0.45], [1035.0, 1095.0, 0.6], [570.0, 660.0, 0.95]]
const GOOD_SESSION := 3
const GENERAL := 1  ## the general tea, mang ja (chapter 04, 3.1): the player may sit at its guest's place (world/hall_tea.gd)
const GUEST_SEAT := 0  ## the place kept for a guest at the general tea: the nave's SEAT 1, the west row's door end by the aisle
const NEAR := 40.0  ## metres from the hall's middle within which they are drawn
const BACK := 0.4  ## the sitting pose's root this far before the hips (pema_o_people.gd)
const NOVICE_ROWS := 3.0  ## metres from the door end of the rows that the novices fill
const GOOD_DAYS := [8, 15, 30]  ## the Tibetan month's days the tulku sits the dawn assembly
const GEKOE := "res://assets/generated/people/labrang_attendant_b.glb"  ## the disciplinarian's body (people2/body.py)
const GEKOE_ROUND := 12.0  ## game minutes a round: his walk up the rows and back, then at his post by the door
const GEKOE_SPEED := 4.5  ## metres a game minute (0.45 m/s at the clock's 6:1: slow, formal)
## The boot row (chapter 04, 3.1): the monks' boots in pairs along the porch either side of the great door while they sit,
## more of them at the dawn assembly than at the tea; the kit's `boots_pair` in its six variants.
const BOOTS_KIT := "res://assets/generated/kit/types/boots_pair_v%d.glb"
const BOOT_ROWS := [[1.9, 8.2, 0.55], [1.9, 8.2, 1.05]]  ## [from, to: metres either side of the door, out from its face]
const BOOT_STEP := 0.42  ## metres between pairs along a row

var seats: Array = []  ## [Godot position of the hips, facing (Godot, flat), is a throne's, metres from the rows' door end]
var _sets := {}  ## body -> [VatSet, MultiMeshInstance3D, buf, [seat index]]
var _mid := Vector3.ZERO
var _shown := -2  ## the session drawn, -1 none
var _t := 0.0
var gekoe: Node3D  ## the disciplinarian
var _g_ap: AnimationPlayer
var _g_staff: MeshInstance3D
var _g_path: Array = []  ## his round: by the door's right, the aisle's door end, up to the thrones, back, his post again
var _g_clip := ""
var boot_row: Array = []  ## the pairs set out on the porch, nearest the door first


## Reads the nave's places from its sidecar, in the hall's place in the town; the number of places.
func build(root: Node3D) -> int:
	var hall := root.get_node_or_null("MON-01") as Node3D
	var room := hall.find_child("SOCK_ROOM_1", true, false) as Node3D if hall != null else null
	if room == null or not FileAccess.file_exists(SIDE):
		return 0
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SIDE))
	var pos: Dictionary = side["socket_pos"]
	var yaws: Dictionary = side["socket_yaw"]
	var xf := room.global_transform
	var keys: Array = []
	for k in pos:
		if String(k).begins_with("SOCK_SEAT_"):
			keys.append(k)
	keys.sort_custom(func(a, b): return int(String(a).get_slice("_", 2)) < int(String(b).get_slice("_", 2)))
	var y_door := 1e9
	for k in keys:
		y_door = minf(y_door, float(pos[k][1]))
	for k in keys:
		var p: Array = pos[k]
		var a := deg_to_rad(float(yaws[k]))
		var f := (xf.basis * Vector3(cos(a), 0.0, -sin(a))).normalized()  # (the socket's +y, Blender's, in Godot)
		var throne := float(p[2]) > 0.5
		seats.append([xf * Vector3(float(p[0]), float(p[2]), -float(p[1])), f, throne, float(p[1]) - y_door])
	_mid = xf * Vector3(0.0, 3.0, -11.0)
	var y_head := -1e9
	for k in keys:
		if float(pos[k][2]) < 0.5:  # (the rows', not the thrones')
			y_head = maxf(y_head, float(pos[k][1]))
	_g_path = [xf * Vector3(1.6, 0.0, -(y_door - 0.6)), xf * Vector3(0.0, 0.0, -(y_door + 0.4)), xf * Vector3(0.0, 0.0, -(y_head + 0.3)),
			xf * Vector3(0.0, 0.0, -(y_door + 0.4)), xf * Vector3(1.6, 0.0, -(y_door - 0.6))]
	_gekoe_build()
	_boot_row_build(hall)
	var bounds := AABB(_mid - global_position - Vector3(16.0, 5.0, 16.0), Vector3(32.0, 10.0, 32.0))
	for i in seats.size():
		var body := _body(i)
		if not ResourceLoader.exists(VatSet.DIR + body + "_vat.glb"):
			continue
		if not _sets.has(body):
			var v := VatSet.open(body)
			if not v.info["clips"].has("Sitting_Cross"):
				continue
			_sets[body] = [v, null, PackedFloat32Array(), []]
		(_sets[body][3] as Array).append(i)
	for body in _sets:
		var st: Array = _sets[body]
		var mmi: MultiMeshInstance3D = (st[0] as VatSet).multimesh((st[3] as Array).size(), bounds)
		mmi.visible = false
		add_child(mmi)
		st[1] = mmi
		var buf := PackedFloat32Array()
		buf.resize((st[3] as Array).size() * VatSet.FLOATS)
		st[2] = buf
	return seats.size()


## Who sits at place i: the tulku, eleven, on his throne (the kit records it last); a novice at the rows' door end; else
## one of the four monks' bodies by the place's own hash.
func _body(i: int) -> String:
	if i == seats.size() - 1:
		return TULKU
	var s: Array = seats[i]
	if not bool(s[2]) and float(s[3]) < NOVICE_ROWS:
		return NOVICES[i % NOVICES.size()]
	return MONKS[(i * 7 + 3) % MONKS.size()]


## The session at a minute of the day: its index, or -1; the good days' morning assembly only on a good day.
static func session_at(m: float, good := false) -> int:
	for k in SESSIONS.size():
		if k == GOOD_SESSION and not good:
			continue
		if m >= float(SESSIONS[k][0]) and m < float(SESSIONS[k][1]):
			return k
	return -1


## Whether the game's day at `minute` is a good day (the Tibetan month's 8th, 15th or 30th).
static func good_day(minute: float) -> bool:
	return GOOD_DAYS.has(int(Calendar.tibetan_date(minute).get("day", 0)))


## Whether place i is taken in session k: the rows by a hash against the session's share; the abbot's and the chant
## leader's thrones always, the tulku's at the dawn assembly on a good day; the guest's place free at the general tea.
func taken(i: int, k: int, good_day: bool) -> bool:
	if i == GUEST_SEAT and k == GENERAL:
		return false
	var s: Array = seats[i]
	if bool(s[2]):
		return i != seats.size() - 1 or ((k == 0 or k == GOOD_SESSION) and good_day)  # (the kit records the tulku's throne last)
	return fposmod(sin(float(i) * 12.9898 + float(k) * 78.233) * 43758.5453, 1.0) < float(SESSIONS[k][2])


## The boot row on the porch: pairs either side of the great door (its DOOR socket: -z the way in), nearest first.
func _boot_row_build(hall: Node3D) -> void:
	var door := hall.find_child("SOCK_DOOR_1", true, false) as Node3D
	if door == null or not ResourceLoader.exists(BOOTS_KIT % 1):
		return
	var spots: Array = []
	for r in BOOT_ROWS:
		var x := float(r[0])
		while x <= float(r[1]):
			for sx in [-1.0, 1.0]:
				spots.append([x, Vector3(sx * x, 0.0, float(r[2]))])
			x += BOOT_STEP
	spots.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	var k := 0
	for sp in spots:
		k += 1
		var pair: Node3D = (load(BOOTS_KIT % (1 + (k * 5) % 6)) as PackedScene).instantiate()
		pair.name = "Boots_%d" % k
		door.add_child(pair)
		pair.position = sp[1] as Vector3 + Vector3(0.0, 0.0, 0.0)
		pair.rotation.y = PI + deg_to_rad(fposmod(float(k) * 37.0, 24.0) - 12.0)  # toes to the door, none quite straight
		pair.visible = false
		boot_row.append(pair)


## The disciplinarian's body and his staff, hidden until a session.
func _gekoe_build() -> void:
	if not ResourceLoader.exists(GEKOE):
		return
	gekoe = (load(GEKOE) as PackedScene).instantiate()
	gekoe.name = "Disciplinarian"
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://characters/person.gdshader")
	PersonLook.apply(gekoe, mat)
	gekoe.top_level = true
	add_child(gekoe)
	gekoe.visible = false
	_g_ap = gekoe.find_children("*", "AnimationPlayer", true, false)[0]
	for n in ["Idle_FoldArms", "Walk_Formal", "Walk"]:
		if _g_ap.has_animation(n):
			_g_ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	_g_staff = MeshInstance3D.new()  # his staff of office, iron-shod, a head taller than he is
	var cm := CylinderMesh.new()
	cm.top_radius = 0.016
	cm.bottom_radius = 0.02
	cm.height = 1.95
	cm.radial_segments = 6
	_g_staff.mesh = cm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.18, 0.11, 0.07)
	sm.roughness = 0.8
	_g_staff.material_override = sm
	_g_staff.top_level = true
	_g_staff.visible = false
	add_child(_g_staff)


## Where the disciplinarian is at `minute` of a session that began at `from`: [position, facing (Godot, flat), walking].
func gekoe_at(minute: float, from: float) -> Array:
	var segs: Array = []
	var total := 0.0
	for i in _g_path.size() - 1:
		var l := (_g_path[i + 1] as Vector3).distance_to(_g_path[i])
		segs.append(l)
		total += l
	var walked := fposmod(minute - from, GEKOE_ROUND) * GEKOE_SPEED
	if total <= 0.0 or walked >= total:  # at his post, facing the rows
		var into: Vector3 = (_g_path[2] as Vector3) - (_g_path[1] as Vector3)
		return [_g_path[0], into.normalized(), false]
	for i in segs.size():
		if walked <= float(segs[i]) or i == segs.size() - 1:
			var a: Vector3 = _g_path[i]
			var b: Vector3 = _g_path[i + 1]
			var d := (b - a).normalized() if float(segs[i]) > 0.01 else Vector3.FORWARD
			return [a.lerp(b, clampf(walked / maxf(float(segs[i]), 0.01), 0.0, 1.0)), d, true]
		walked -= float(segs[i])
	return [_g_path[0], Vector3.FORWARD, false]


## The disciplinarian placed for the frame (k the session, -1 none).
func _gekoe_place(k: int) -> void:
	if gekoe == null:
		return
	gekoe.visible = k >= 0
	_g_staff.visible = k >= 0
	if k < 0:
		return
	var w := gekoe_at(fposmod(WorldClock.minute, 1440.0), float(SESSIONS[k][0]))
	var at: Vector3 = w[0]
	var f: Vector3 = w[1]
	gekoe.global_transform = Transform3D(Basis(Vector3.UP, atan2(f.x, f.z)), at)  # (the rig faces +Z)
	var right := Vector3(f.z, 0.0, -f.x)
	_g_staff.global_position = at - right * 0.3 + Vector3(0.0, 0.97, 0.0)
	var clip := "Walk_Formal" if bool(w[2]) and _g_ap.has_animation("Walk_Formal") else ("Idle_FoldArms" if _g_ap.has_animation("Idle_FoldArms") else "Idle_A")
	if clip != _g_clip:
		_g_ap.play(clip, 0.3)
		_g_clip = clip
	if clip == "Walk_Formal":  # at his pace: Walk_Formal's stride taken as the body's Walk's, 0.735 m/s (named_clips.json:
		_g_ap.speed_scale = (GEKOE_SPEED / 10.0) / 0.735  # its own measured 0, an in-place clip); 10 s a game minute
	else:
		_g_ap.speed_scale = 1.0


func _process(dt: float) -> void:
	_gekoe_place(_shown)
	_t -= dt
	if _t > 0.0:
		return
	_t = 0.5
	var cam := get_viewport().get_camera_3d()
	var minute := fposmod(WorldClock.minute, 1440.0)
	var good_now := good_day(WorldClock.minute)
	var k := session_at(minute, good_now) if cam != null and cam.global_position.distance_to(_mid) < NEAR else -1
	if k == _shown:
		return
	_shown = k
	var share := float(SESSIONS[k][2]) if k >= 0 else 0.0
	for j in boot_row.size():  # the boot row: as many pairs as the session has monks, nearest the door first
		(boot_row[j] as Node3D).visible = j < int(round(boot_row.size() * share))
	var good := good_now
	for body in _sets:
		var st: Array = _sets[body]
		var mmi: MultiMeshInstance3D = st[1]
		mmi.visible = k >= 0
		if k < 0:
			continue
		var v: VatSet = st[0]
		var c := v.clip("Sitting_Cross")
		var buf: PackedFloat32Array = st[2]
		var idx: Array = st[3]
		for j in idx.size():
			var i: int = idx[j]
			if not taken(i, k, good):
				VatSet.hide(buf, j)
				continue
			var s: Array = seats[i]
			var f: Vector3 = s[1]
			var p: Vector3 = s[0] + f * BACK - global_position
			VatSet.put(buf, j, p, atan2(f.x, f.z), 1.0, 0.92 + 0.08 * fposmod(float(i) * 0.618, 1.0), c, float(i * 13 % int(c["frames"])), 1.0)
		mmi.multimesh.buffer = buf
