extends Node3D
## The Caravan Ground's things (M2 sprint 9, step 1; plan chapter 02, D02; chapter 06, 7.1 and 8.6): the windbreaks the
## caravans stack of their loads, the hay piles bought for their yak, the fodder yard GAR-13 and the dung-drying walls
## GAR-07, each a kit type (../tibet-blender kit/camp.py) where tools/town/caravan_ground.py stands it
## (data/caravan_ground.json `things`), shown from its minute until its last: CV-01's wool and hay from 11:00, CV-02's tea
## as its loads come off after its herd halts in its block (`after` minutes after `cv02_halt`, which world/herd.gd sets
## from its working out; DEFAULT_HALT without the herd) and its hay a quarter of an hour on; the rest all day. The game's
## day runs from 04:00 to 04:00, so what stands at dusk stands through the night. A thing not shown keeps no collision.
## Its hearths burn (M2 sprint 9, step 3; chapter 06, 8.6: "dung fires lit from the drying walls"): CV-01's from 16:40,
## CV-02's 25 minutes after its herd halts, out by 23:30, and the dawn's tea fires 05:20-07:20; flames and coals as the
## town's (shaders/lamp_mm.gdshader), a flickering light each, the crackle (SND-025) heard near. Added by world/town.gd.

const DATA := "res://data/caravan_ground.json"
const KIT := "res://assets/generated/kit/types/%s.glb"
const DAY_START := 240.0  ## 04:00: the day's turn
const DEFAULT_HALT := 975.0  ## 16:15: CV-02's herd halted in its block (world/herd.gd's working out at the clock's 6:1)
const LAMP := preload("res://shaders/lamp_mm.gdshader")
const FIRE_C := Color("#FF9A4A")
const CV01_FIRES := 1000.0  ## 16:40
const FIRES_AFTER := 25.0  ## CV-02's, minutes after its halt
const HEARD := 70.0  ## metres within which a fire's crackle is started

var things: Array = []  ## [node, from, until, shown, after] (minutes of the day; -1: no bound; after: minutes after cv02_halt, or -1)
var cv02_halt := DEFAULT_HALT
var counts := {"things": 0, "missing": 0, "fires": 0}
var fires: Array = []  ## [the hearth's thing index, its fire's place, of, light, [flame instances], the crackle's key, lit]
var flames: MultiMesh


func build(bounds := Rect2(-1350.0, -1100.0, 3650.0, 2200.0)) -> Dictionary:
	if not FileAccess.file_exists(DATA):
		return counts
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var town: GDScript = load("res://world/town.gd")
	var cache := {}
	for t in d.get("things", []):
		var at: Array = t["at"]
		if not bounds.has_point(Vector2(at[0], at[1])):
			continue
		var f := String(t["type"])
		if not cache.has(f):
			cache[f] = load(KIT % f) if ResourceLoader.exists(KIT % f) else null
		if cache[f] == null:
			counts["missing"] += 1
			push_warning("camp: no kit file %s (../tibet-blender export_types.py)" % f)
			continue
		var n: Node3D = (cache[f] as PackedScene).instantiate()
		n.name = "%s_%d" % [String(t["of"]).replace("-", "_"), things.size()]
		n.position = town.call("to_godot", float(at[0]), float(at[1]), float(at[2]))
		n.rotation.y = -deg_to_rad(float(t["facing"]) - 180.0)
		add_child(n)
		things.append([n, -1.0 if t["from"] == null else float(t["from"]), -1.0 if t["until"] == null else float(t["until"]), true,
				float(t.get("after", -1.0))])
		counts["things"] += 1
		if f.begins_with("camp_hearth"):
			fires.append([things.size() - 1, n.position + Vector3(0.0, 0.08, 0.0), String(t["of"]), null, [], "campfire_%d" % fires.size(), 0.0])
	_build_fires()
	_process(0.0)
	return counts


## Each fire's coals and three tongues as cards in one MultiMesh, and its light.
func _build_fires() -> void:
	if fires.is_empty():
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
	flames.instance_count = fires.size() * 3
	var eq := QuadMesh.new()
	eq.size = Vector2.ONE
	var emat := ShaderMaterial.new()
	emat.shader = LAMP
	emat.set_shader_parameter("kind", 1)
	eq.material = emat
	var embers := MultiMesh.new()
	embers.transform_format = MultiMesh.TRANSFORM_3D
	embers.use_custom_data = true
	embers.mesh = eq
	embers.instance_count = fires.size()
	for k in fires.size():
		var c: Vector3 = fires[k][1]
		embers.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(0.7, 0.4, 1.0)), c + Vector3(0.0, 0.08, 0.0)))
		embers.set_instance_custom_data(k, Color(0.0, 30.0 + k, 0.0, 0.0))
		for j in 3:
			var h: float = [0.6, 0.48, 0.4][j]
			var off := Vector3(cos(j * 2.1 + k) * 0.12, h * 0.42, sin(j * 2.1 + k) * 0.12)
			flames.set_instance_transform(k * 3 + j, Transform3D(Basis.from_scale(Vector3(h * 0.5, h, 1.0)), c + off))
			flames.set_instance_custom_data(k * 3 + j, Color(0.0, 40.0 + k * 3 + j, 0.0, 0.0))
			(fires[k][4] as Array).append(k * 3 + j)
		var l := OmniLight3D.new()
		l.name = "CampFire%d" % k
		l.light_color = FIRE_C
		l.omni_range = 12.0
		l.omni_attenuation = 1.4
		l.shadow_enabled = false
		l.light_specular = 0.2
		l.light_volumetric_fog_energy = 0.0
		l.visible = false
		l.position = c + Vector3(0.0, 0.9, 0.0)
		add_child(l)
		fires[k][3] = l
	for pair in [["CampFlames", flames], ["CampEmbers", embers]]:
		var mi := MultiMeshInstance3D.new()
		mi.name = pair[0]
		mi.multimesh = pair[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	set_meta("embers", embers)
	counts["fires"] = fires.size()


## How lit a camp fire of `of`'s is at minute m of the day (0 to 1): the evening's from its caravan's hour, out by 23:30,
## and the dawn's tea fire.
static func fire_lit(of: String, m: float, halt: float) -> float:
	var on := CV01_FIRES if of == "CV-01" else halt + FIRES_AFTER
	var eve := smoothstep(on, on + 3.0, m) * (1.0 - smoothstep(1380.0, 1410.0, m))
	var dawn := smoothstep(320.0, 323.0, m) * (1.0 - smoothstep(440.0, 450.0, m))
	return maxf(eve, dawn)


## Whether a thing shown from `from` until `until` (minutes of the day, -1 for none) stands at minute `m` of the day.
static func shown_at(from: float, until: float, m: float) -> bool:
	var mm := m + 1440.0 if m < DAY_START else m
	var a := from + 1440.0 if from >= 0.0 and from < DAY_START else from
	var b := until + 1440.0 if until >= 0.0 and until < DAY_START else until
	return (a < 0.0 or mm >= a) and (b < 0.0 or mm < b)


func _process(_dt: float) -> void:
	var m := fposmod(WorldClock.minute, 1440.0)
	for th in things:
		var on := shown_at(cv02_halt + float(th[4]) if float(th[4]) >= 0.0 else float(th[1]), float(th[2]), m)
		if on == bool(th[3]):
			continue
		th[3] = on
		var n := th[0] as Node3D
		n.visible = on
		for cs in n.find_children("*", "CollisionShape3D", true, false):
			(cs as CollisionShape3D).set_deferred("disabled", not on)
	if fires.is_empty():
		return
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var embers: MultiMesh = get_meta("embers")
	var t := Time.get_ticks_msec() / 1000.0
	for k in fires.size():
		var f: Array = fires[k]
		var lit := fire_lit(String(f[2]), m, cv02_halt) if bool(things[int(f[0])][3]) else 0.0
		f[6] = lit
		embers.set_instance_custom_data(k, Color(lit, 30.0 + k, 0.0, 0.0))
		for i in f[4]:
			flames.set_instance_custom_data(int(i), Color(lit, 40.0 + float(i), 0.0, 0.0))
		var l: OmniLight3D = f[3]
		l.visible = lit > 0.01
		l.light_energy = 3.4 * lit * (0.84 + 0.1 * sin(t * 7.1 + k) + 0.06 * sin(t * 12.7 + 1.3 * k))
		var near := cam != null and cam.global_position.distance_to(f[1]) < HEARD
		var key := String(f[5])
		if is_instance_valid(AudioDirector) and AudioDirector.sound != null:
			if lit > 0.5 and near and not f.has("heard"):
				AudioDirector.sound.loop_start(key, "SND-025", f[1])
				f.append("heard")
			elif (lit <= 0.5 or not near) and f.has("heard"):
				AudioDirector.sound.loop_stop(key)
				f.erase("heard")
