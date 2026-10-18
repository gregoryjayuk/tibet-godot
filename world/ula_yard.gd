extends Node3D
## The ula yard's day (M2 sprint 11, step 3; plan chapter 05, A-57: "feeding and counting borrowed animals for the ula",
## the headman's men, 07:30-09:00 and 15:30-17:00; chapter 06, 8.10 and ANI-02; chapter 07's 07:30), added by
## world/town.gd with the people, at the yard SAM-09 and the stables SAM-08 behind it (kit/samkha.py ula_yard, stables):
## - the animals owed for the resident's officers tied at its rings (the kit's TIE sockets), horses from Tödé, yak from
##   the hamlets, a few mules: the overnight ones from dawn, more brought in through the afternoon (TIED: kind and
##   minute), standing or eating, each its own coat; the yard never as full as the order;
## - the headman's men at the count (COUNT) at its hours, and the owners by their animals in the afternoon, arguing over
##   who owes how many;
## - the Pönpo's scribe at his bench with the tally in the afternoon (the court has him in the morning);
## - a soldier from the post watching from inside the gate in the afternoon;
## - the Pönpo's riding mule (ANI-02, a tall dark bay Kongpo mule) tied before the stable's west door by day.
## Each one's place from the clock's minute (so a still is the same each time); drawn while the camera is within SEEN.
## `shown` is pure, for the tests.

const PERSON := preload("res://characters/person.gdshader")
const FIGS := {"mule": "res://assets/generated/people/mule.glb", "pony": "res://assets/generated/people/pony.glb",
		"yak": "res://assets/generated/people/yak_free.glb"}
const SEEN := 260.0  ## metres from the yard within which they are drawn
const DAY := [300.0, 1260.0]  ## 05:00-21:00 tied in the yard (overnight they are in it too, but out of sight in the dark)
const COUNTS := [[450.0, 540.0], [930.0, 1020.0]]  ## the headman's men's count (A-57)
const AFTERNOON := [900.0, 1020.0]  ## the owners arguing; the scribe and the soldier from the count's start
## the animals at the yard's rings in order (its TIE sockets, along the front from the west end, the west end, the
## back's ends): [kind, from minute (0: there overnight), or "" for a ring left empty]
const TIED := [["pony", 0.0], ["", 0.0], ["yak", 0.0], ["yak", 0.0], ["", 0.0], ["pony", 935.0], ["mule", 0.0],
		["", 0.0], ["yak", 950.0], ["", 0.0], ["pony", 0.0], ["", 0.0], ["yak", 0.0], ["", 0.0], ["pony", 962.0],
		["yak", 0.0], ["", 0.0], ["mule", 978.0], ["yak", 0.0], ["", 0.0], ["pony", 990.0], ["", 0.0]]
const TINTS := [1.0, 0.82, 1.06, 0.93, 0.88, 1.1, 0.96, 0.85]
## the people: [body, place ("count:<n>", "tally", "gate", "owner:<tie>"), [[from, to], ...], clip]
const PEOPLE := [["townsman", "count:0", COUNTS, "Idle_Talking"], ["townsman_b", "count:1", COUNTS, "Idle_FoldArms"],
		["drover", "count:2", COUNTS, "Idle_A"], ["elder_man", "tally", [[930.0, 1020.0]], "Sitting_Cross"],
		["post_soldier", "gate", [[930.0, 1020.0]], "Idle_FoldArms"], ["drover_b", "owner:2", [[900.0, 1020.0]], "Idle_Talking"],
		["nomad_woman", "owner:12", [[905.0, 1015.0]], "Idle_Talking"], ["stall_man", "owner:10", [[915.0, 1010.0]], "Idle_A"]]
const MULE_DAY := [420.0, 1080.0]  ## 07:00-18:00 the Pönpo's mule tied before the stable door

var yard: Node3D
var stables: Node3D
var ties: Array = []  ## Transform3D of each ring's place, in the kit's order
var places := {}  ## "count:0", "tally", "gate", "mule" -> Transform3D
var beasts: Array = []  ## {kind, from, tie, root, ap}
var people: Array = []  ## {key, place, spans, clip, root, ap}
var _mat: ShaderMaterial
var _built := false


## Whether one of TIED's animals is in the yard at minute `m` of the day.
static func shown(from: float, m: float) -> bool:
	return m >= DAY[0] and m < DAY[1] and (from <= 0.0 or m >= from)


static func _within(spans: Array, m: float) -> bool:
	for s in spans:
		if m >= float(s[0]) and m < float(s[1]):
			return true
	return false


static func _sockets(node: Node3D, prefix: String) -> Array:
	var found := node.find_children(prefix + "*", "Node3D", true, false)
	found.sort_custom(func(a, b): return int(String(a.name).get_slice("_", 2)) < int(String(b.name).get_slice("_", 2)))
	return found


## Gathers the yard's and the stables' places. The count of animals and people.
func build(root: Node3D) -> int:
	yard = root.get_node_or_null("SAM-09") as Node3D
	stables = root.get_node_or_null("SAM-08") as Node3D
	if yard == null:
		return 0
	for s in _sockets(yard, "SOCK_TIE_"):
		ties.append((s as Node3D).global_transform)
	var counts := _sockets(yard, "SOCK_COUNT_")
	for k in counts.size():
		places["count:%d" % k] = (counts[k] as Node3D).global_transform
	for key in ["TALLY", "GATE", "POST"]:
		var s := yard.find_child("SOCK_%s_1" % key, true, false) as Node3D
		if s != null:
			places[key.to_lower()] = s.global_transform
	if places.has("gate"):  # the soldier a few metres inside it, turned to watch the yard (the socket faces out)
		var g: Transform3D = places["gate"]
		places["gate"] = Transform3D(g.basis.rotated(Vector3.UP, PI), g.origin + g.basis.z * 3.0 - g.basis.x * 3.4)
	if stables != null:
		var s := stables.find_child("SOCK_MULE_1", true, false) as Node3D
		if s != null:
			places["mule"] = s.global_transform
	for k in mini(TIED.size(), ties.size()):
		if String(TIED[k][0]) != "":
			beasts.append({"kind": String(TIED[k][0]), "from": float(TIED[k][1]), "tie": k})
	if places.has("mule"):
		beasts.append({"kind": "mule", "from": MULE_DAY[0], "until": MULE_DAY[1], "ponpo": true})
	for p in PEOPLE:
		people.append({"key": String(p[0]), "place": String(p[1]), "spans": p[2], "clip": String(p[3])})
	add_to_group("ula_yard")
	return beasts.size() + people.size()


func _figures() -> void:
	_built = true
	_mat = ShaderMaterial.new()
	_mat.shader = PERSON
	for i in beasts.size():
		var b: Dictionary = beasts[i]
		var path: String = FIGS[String(b["kind"])]
		if not ResourceLoader.exists(path):
			continue
		var fig: Node3D = (load(path) as PackedScene).instantiate()
		var r := Node3D.new()
		r.name = "Ula_%s_%d" % [String(b["kind"]).capitalize(), i]
		add_child(r)
		r.add_child(fig)
		var ponpo := bool(b.get("ponpo", false))
		for mi in fig.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = _mat
			(mi as MeshInstance3D).set_instance_shader_parameter("tint", 0.62 if ponpo else TINTS[i % TINTS.size()])  # his dark bay
		var sk: Skeleton3D = fig.find_children("*", "Skeleton3D", true, false)[0]
		if String(b["kind"]) == "mule":  # a mule's long ears (bones the clips never move)
			for e in ["ear_1_r", "ear_1_l"]:
				var bi := sk.find_bone(e)
				if bi >= 0:
					sk.set_bone_pose_scale(bi, Vector3(1.25, 1.7, 1.25))
		if ponpo:  # tall: a Kongpo riding mule stands over the pack mules
			fig.scale = Vector3.ONE * 1.12
		var ap: AnimationPlayer = fig.find_children("*", "AnimationPlayer", true, false)[0]
		var clip := "Eating" if (i % 3 == 1 and ap.has_animation("Eating")) else "Idle"
		if not ap.has_animation(clip):  # whatever stand it has
			clip = _first(ap, ["Idle", "Idle_A", "Eating"])
		if clip != "":
			ap.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		b["root"] = r
		b["ap"] = ap
		b["clip"] = clip
		var t: Transform3D = places["mule"] if ponpo else ties[int(b["tie"])]
		var face := -t.basis.z  # the socket's way (its Blender +y), the figure built facing +z
		r.global_position = t.origin
		r.rotation.y = atan2(face.x, face.z)
		r.visible = false
	for p in people:
		var path := "res://assets/generated/people/%s.glb" % String(p["key"])
		if not ResourceLoader.exists(path):
			continue
		var r: Node3D = (load(path) as PackedScene).instantiate()
		r.name = "Ula_%s" % String(p["key"])
		PersonLook.apply(r, _mat)
		var ap: AnimationPlayer = r.find_children("*", "AnimationPlayer", true, false)[0]
		var clip := _first(ap, [String(p["clip"]), "Sitting_Idle" if String(p["clip"]).begins_with("Sitting") else "Idle_A", "Idle_A"])
		if clip != "":
			ap.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		add_child(r)
		var t: Transform3D = _place(String(p["place"]))
		var face := -t.basis.z
		r.global_position = t.origin
		r.rotation.y = atan2(face.x, face.z)
		r.visible = false
		p["root"] = r
		p["ap"] = ap
		p["clip_now"] = clip


## A person's place: a count's, the tally's, the gate's, or an owner's beside his animal's ring (a metre to its side,
## turned to the yard's middle).
func _place(name: String) -> Transform3D:
	if name.begins_with("owner:"):
		var t: Transform3D = ties[clampi(int(name.get_slice(":", 1)), 0, ties.size() - 1)]
		var at := t.origin + t.basis.x * 1.1 - t.basis.z * 0.4
		var mid := yard.global_position
		var d := Vector3(mid.x - at.x, 0.0, mid.z - at.z).normalized()
		return Transform3D(Basis(Vector3.UP, atan2(-d.x, -d.z)), at)
	return places.get(name, Transform3D(Basis(), yard.global_position))


func _process(_dt: float) -> void:
	if yard == null:
		return
	var cam := get_viewport().get_camera_3d()
	var on: bool = cam != null and cam.global_position.distance_to(yard.global_position) < SEEN
	if not on:
		for b in beasts:
			if b.has("root"):
				(b["root"] as Node3D).visible = false
		for p in people:
			if p.has("root"):
				(p["root"] as Node3D).visible = false
		return
	if not _built:
		_figures()
	var m := fposmod(WorldClock.minute, 1440.0)
	var frozen: bool = WorldClock.frozen
	var g: float = WorldClock.anim_time
	for i in beasts.size():
		var b: Dictionary = beasts[i]
		if not b.has("root"):
			continue
		var vis := (m >= float(b["from"]) and m < float(b["until"])) if b.has("until") else shown(float(b["from"]), m)
		(b["root"] as Node3D).visible = vis
		if vis:
			_play(b["ap"], String(b["clip"]), frozen, g, i)
	for i in people.size():
		var p: Dictionary = people[i]
		if not p.has("root"):
			continue
		var vis := _within(p["spans"], m)
		(p["root"] as Node3D).visible = vis
		if vis:
			_play(p["ap"], String(p["clip_now"]), frozen, g, i + 7)


static func _first(ap: AnimationPlayer, want: Array) -> String:
	for c in want:
		if ap.has_animation(String(c)):
			return String(c)
	var all := ap.get_animation_list()
	return String(all[0]) if not all.is_empty() else ""


func _play(ap: AnimationPlayer, clip: String, frozen: bool, g: float, i: int) -> void:
	if not ap.has_animation(clip):
		return
	if ap.current_animation != clip:
		ap.play(clip)
	if frozen:  # the stills: the pose from the animation clock
		ap.speed_scale = 0.0
		ap.seek(fposmod(g + i * 0.53, ap.get_animation(clip).length), true)
	else:
		ap.speed_scale = 1.0
