extends Node3D
## V-02, the Conch Eddy at first sun (M2 sprint 5, step 6; plan chapter 08, V-02; chapter 01, 5.1): the confluence's dawn,
## added by world/town.gd with the rivers:
## - the mist on the pool and the slot's head, lying on the water through the night and thinning over ten minutes from
##   the first sun on the water (07:46:42 on the terrain, through the horizon map's fine grid: docs/terrain/sun-report.md),
##   its top lifting a metre as it goes (a FogVolume, chapter 08's "0.01 in the pool basin");
## - the conch: a small white swirl of foam turning in the eddy where the white water meets the gold, there only in the
##   moment's window (07:40-08:15), the glint of the founding story (Geshe Jampa Rinchen's right-turning white conch, at
##   dawn in 1657); E by the lip looks, and a gloss says what it is: only foam, never a pickup. Looking logs the story's
##   flag "moment:V-02:conch".
## `mist_at` and `conch_shown` are pure, for the tests.

const Town := preload("res://world/town.gd")
const RIVERS := "res://data/rivers.json"
const FIRST_SUN := 466.7  ## 07:46:42, the first sun on the pool through the map (docs/terrain/sun-report.md)
const LIFT := 10.0  ## minutes the mist takes to go
const DENSE := 0.035  ## the mist's density on the water (chapter 08 has 0.01: too thin to read in the valley's froxels)
const WINDOW := [460.0, 495.0]  ## the conch's: 07:40-08:15
const CONCH := Vector2(212.0, -96.6)  ## the town grid: on the seam in the pool, where the Dungchu comes in beside the Serchu
const LOOK_FROM := 16.0  ## metres from the conch within which E looks at it
const GLOSS := "Only foam, turning in the eddy where the white water meets the gold. Here at dawn in 1657, the story says, Geshe Jampa Rinchen saw a right-turning white conch turning in the water, and the town began."

var mist: FogVolume
var conch: Node3D
var _mist_y := 0.0
var _pool_z := 2657.1


## The mist's density and its top's lift (m) at minute `m`: on the water from 21:00 to the first sun, thinning over LIFT.
static func mist_at(m: float) -> Vector2:
	if m >= 1260.0 or m < FIRST_SUN:
		var k := smoothstep(1260.0, 1380.0, m) if m >= 1260.0 else 1.0
		return Vector2(DENSE * k, 0.0)
	var l := smoothstep(FIRST_SUN, FIRST_SUN + LIFT, m)
	return Vector2(DENSE * (1.0 - l), l)


static func conch_shown(m: float) -> bool:
	return m >= WINDOW[0] and m < WINDOW[1]


func build() -> String:
	if FileAccess.file_exists(RIVERS):
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RIVERS))
		_pool_z = float((d.get("pool", {}) as Dictionary).get("z", _pool_z))
	# the mist: an ellipsoid over the pool and the slot's head below the terrace's lip
	mist = FogVolume.new()
	mist.name = "PoolMist"
	mist.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	mist.size = Vector3(52.0, 5.0, 26.0)
	var fm := FogMaterial.new()
	fm.density = DENSE
	fm.albedo = Color(0.93, 0.95, 0.97)
	fm.edge_fade = 0.6
	mist.material = fm
	add_child(mist)
	mist.global_position = Town.to_godot(203.0, -97.0, _pool_z + 1.6)
	_mist_y = mist.global_position.y
	# the conch's glint: a flat spiral of foam on the water, turning right-handed (clockwise seen from above)
	conch = Node3D.new()
	conch.name = "ConchGlint"
	add_child(conch)
	conch.global_position = Town.to_godot(CONCH.x, CONCH.y, _pool_z + 0.03)
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color(0.97, 0.97, 0.95)
	white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	white.vertex_color_use_as_albedo = true
	var spiral := ImmediateMesh.new()
	spiral.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, white)
	var turns := 2.6
	var n := 48
	for i in n + 1:
		var t := float(i) / n
		var a := -t * turns * TAU  # right-turning: clockwise from above (Godot's +y up, the town's north -z)
		var r := 0.04 + 0.26 * t
		var w := 0.012 + 0.05 * t
		for side in [-1.0, 1.0]:
			var rr: float = r + float(side) * w * 0.5
			spiral.surface_set_color(Color(1, 1, 1, 0.55 + 0.4 * (1.0 - t)))
			spiral.surface_add_vertex(Vector3(cos(a) * rr, 0.0, sin(a) * rr))
	spiral.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = spiral
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	conch.add_child(mi)
	conch.visible = false
	add_to_group("confluence_dawn")
	_process(0.0)
	return "the pool's mist, the conch's glint at (%.0f, %.0f)" % [CONCH.x, CONCH.y]


func _process(dt: float) -> void:
	var m := fposmod(WorldClock.minute, 1440.0)
	var ms := mist_at(m)
	if mist != null:
		(mist.material as FogMaterial).density = ms.x
		mist.visible = ms.x > 0.0005
		mist.global_position.y = _mist_y + ms.y
	if conch != null:
		conch.visible = conch_shown(m)
		if conch.visible:
			var t: float = WorldClock.anim_time if WorldClock.frozen else Time.get_ticks_msec() / 1000.0
			conch.rotation.y = -t * 0.9  # turning in the eddy, right-handed


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_action_pressed("use"):  # E, or the controller's triangle (autoload/controls.gd)
		return
	if conch == null or not conch.visible:
		return
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null or p.global_position.distance_to(conch.global_position) > LOOK_FROM:
		return
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.gloss(GLOSS, "conch_eddy")
	Story.set_flag("moment:V-02:conch")
	get_viewport().set_input_as_handled()
