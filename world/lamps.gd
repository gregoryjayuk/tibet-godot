extends Node3D
## The town's lamps at dusk (IMP-021 (3), after Greg's 1770: warm points of light against the blue; plan chapter 02's day:
## 17:00-17:45 "lamps lit on every altar", 17:45-21:00 "dice and a Gesar bard by the fire in Dechen-tsang's yard"),
## added by world/town.gd after the dusk (world/dusk.gd):
## - the Mani Lhakhang's seven butter lamps on its altar (the kit's FLAME sockets), lit one after another from 17:00 by
##   its keeper and out at 21:00 but the middle one, which burns all night; lit again for the morning, 05:30-07:00; a warm
##   light in the hall, so its open door glows;
## - the lamp in the niche halfway along the tunnel under three houses on the Sky Stair (SHL-16), never out;
## - an ember in every roof's sang burner while its juniper burns (world/dusk.gd's windows: 17:00-17:45, 05:45-06:30);
## - the fire in Dechen-tsang's front yard, 17:45-21:00, its light on the galleries; and at 21:00 a fire carried to its
##   guest yard for the bard, let die from 21:50 (chapter 04, 4.3; M2 sprint 8, step 4); and a paper lantern hung in its gateway
##   from dusk to dawn ("at night the bard's fire in Yard 2 and a lantern at the gate");
## - the lamp in the niche of Samkha Khar's gate passage (SAM-02), never out, and the four butter lamps before Thangtong
##   Gyalpo in the south pavilion (SAM-04), lit at 17:05 and out at 21:00, lit again for the morning (M2 sprint 4);
## - the nine butter lamps on Pema Ö Lhakhang's altar (SHL-11), before Guru Rinpoche, kept burning day and night, and a
##   warm light in its hall, so its door glows over the forecourt at dusk (M2 sprint 5, step 4).
## The flames are cards (shaders/lamp_mm.gdshader), a MultiMesh a kind; the light is three OmniLight3Ds (the hall, the
## tunnel, the fire), none casting shadows. The ritro's lamp waits: on the real ground no spot near the Guru's cave is
## seen from Tsongra or V-28 (ISS-120).

const LAMP := preload("res://shaders/lamp_mm.gdshader")
const FIRE_AT := Vector3(4.0, -9.0, 0.02)  ## in Dechen-tsang's frame (kit/trading.py): Yard 1, east of the way through it
const FIRE2_AT := Vector3(0.0, 10.0, 1.02)  ## and the bard's in the guest yard's middle, a metre up (M2 sprint 8)
const LAMP_C := Color("#F4B24A")
const FIRE_C := Color("#FF9A4A")

var hall: OmniLight3D
var tunnel: OmniLight3D
var fire: OmniLight3D
var fire2: OmniLight3D  ## the bard's fire in the guest yard
var gate_lamp: OmniLight3D  ## Dechen-tsang's lantern in its gateway
var gate_globe: MeshInstance3D
var passage: Array[OmniLight3D] = []  ## the lamps' lights in Samkha Khar's gate passage and its stair hall
var temple: OmniLight3D  ## Pema Ö's hall
var lamps: Array = []  ## [what, order, its MultiMesh, its instance, its seed]
var placed: Array = []  ## [what, position] (a MultiMesh reads back nothing headless: the tests read these)
var strength := {}  ## what -> the sum of its lamps' strengths now
var _burners: Array = []  ## world/dusk.gd's burners' instance data (y: the minutes after the window opens it is lit)
var _fire_k := 0.0
var _fire2_k := 0.0
var _last := -1.0


## Gathers the lamps from the town under `root` (SHL-08's and SHL-16's FLAME sockets, Dechen-tsang's frame) and the
## burners (world/dusk.gd's SANG sockets and their instance data, shared: juniper laid on one is seen). The counts.
func build(root: Node3D, burners: Array = [], base: Array = []) -> Dictionary:
	var fl: Array = []  # [what, order, where, size, seed]
	var em: Array = []
	var lhk := root.get_node_or_null("SHL-08") as Node3D
	if lhk != null:
		var socks := lhk.find_children("SOCK_FLAME_*", "Node3D", true, false)
		socks.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
		for k in socks.size():
			var p := (socks[k] as Node3D).global_position
			fl.append(["altar", k, p + Vector3(0.0, 0.03, 0.0), Vector2(0.035, 0.07), float(k)])
		var door := lhk.find_child("SOCK_DOOR_1", true, false) as Node3D
		if not socks.is_empty() and door != null:
			# the lamps' light filling the hall, set in its front half: the great wheel stands between the altar and the
			# door, and a light at the altar left the doorway black
			var into := lhk.global_position - door.global_position
			into.y = 0.0
			hall = _light("Hall", door.global_position + into.normalized() * 1.6 + Vector3(0.0, 1.8, 0.0), LAMP_C, 7.5)
	var tun := root.get_node_or_null("SHL-16") as Node3D
	if tun != null:
		for s in tun.find_children("SOCK_FLAME_*", "Node3D", true, false):
			var p := (s as Node3D).global_position
			fl.append(["tunnel", 0, p + Vector3(0.0, 0.03, 0.0), Vector2(0.035, 0.07), 9.0])
			tunnel = _light("Tunnel", p + tun.global_transform.basis.x.normalized() * 0.5 + Vector3(0.0, 0.3, 0.0), LAMP_C, 5.0)
	var castle := root.get_node_or_null("SAM-01") as Node3D
	if castle != null:  # the lamp in the gate passage's niche, in its west wall: its light into the passage
		for s in castle.find_children("SOCK_FLAME_*", "Node3D", true, false):
			var p := (s as Node3D).global_position
			fl.append(["passage", 0, p + Vector3(0.0, 0.03, 0.0), Vector2(0.035, 0.07), 11.0])
			passage.append(_light("Passage", p + castle.global_transform.basis.x.normalized() * 0.8 + Vector3(0.0, 0.4, 0.0), LAMP_C, 7.0))
	var pav := root.get_node_or_null("SAM-04") as Node3D
	if pav != null:  # the butter lamps on the shelf before Thangtong Gyalpo
		var ps := pav.find_children("SOCK_FLAME_*", "Node3D", true, false)
		ps.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
		for k in ps.size():
			fl.append(["shrine", k, (ps[k] as Node3D).global_position + Vector3(0.0, 0.03, 0.0), Vector2(0.03, 0.06), 20.0 + k])
	var pema := root.get_node_or_null("SHL-11") as Node3D
	if pema != null:  # Pema Ö's altar: its lamps, and their light filled into the hall's front half, towards the door
		var ts := pema.find_children("SOCK_FLAME_*", "Node3D", true, false)
		ts.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
		for k in ts.size():
			fl.append(["temple", k, (ts[k] as Node3D).global_position + Vector3(0.0, 0.03, 0.0), Vector2(0.035, 0.07), 30.0 + k])
		var tdoor := pema.find_child("SOCK_DOOR_1", true, false) as Node3D
		if not ts.is_empty() and tdoor != null:
			var into := pema.global_position - tdoor.global_position
			into.y = 0.0
			temple = _light("TempleHall", tdoor.global_position + into.normalized() * 5.5 + Vector3(0.0, 2.2, 0.0), LAMP_C, 9.0)
	_burners = base
	for i in burners.size():
		em.append(["ember", i, (burners[i] as Node3D).global_position + Vector3(0.0, 0.08, 0.0), Vector2(0.34, 0.24), float(i)])
	var dechen := root.get_node_or_null("SHL-04") as Node3D
	if dechen != null:
		var c := dechen.global_transform * Vector3(FIRE_AT.x, FIRE_AT.z, -FIRE_AT.y)
		em.append(["fire", 0, c + Vector3(0.0, 0.1, 0.0), Vector2(0.8, 0.45), 3.0])
		for k in 3:
			var h: float = [0.62, 0.5, 0.42][k]
			var off := Vector3(cos(k * 2.1) * 0.13, h * 0.42, sin(k * 2.1) * 0.13)
			fl.append(["fire", k + 1, c + off, Vector2(h * 0.5, h), 4.0 + k])
		fire = _light("Fire", c + Vector3(0.0, 0.9, 0.0), FIRE_C, 12.0)
		_hearth(c)
		var c2 := dechen.global_transform * Vector3(FIRE2_AT.x, FIRE2_AT.z, -FIRE2_AT.y)  # the bard's (M2 sprint 8)
		em.append(["fire2", 0, c2 + Vector3(0.0, 0.1, 0.0), Vector2(0.7, 0.4), 13.0])
		for k in 3:
			var h: float = [0.56, 0.46, 0.38][k]
			var off := Vector3(cos(k * 2.1 + 0.5) * 0.12, h * 0.42, sin(k * 2.1 + 0.5) * 0.12)
			fl.append(["fire2", k + 1, c2 + off, Vector2(h * 0.5, h), 14.0 + k])
		fire2 = _light("Fire2", c2 + Vector3(0.0, 0.9, 0.0), FIRE_C, 11.0)
		_hearth(c2)
		var gl := dechen.global_transform * Vector3(0.0, 3.05, 22.75)  # the lantern under the gateway's lintel, its yard side
		gate_lamp = _light("GateLantern", gl + Vector3(0.0, -0.3, 0.0), LAMP_C, 11.0)
		gate_globe = MeshInstance3D.new()
		gate_globe.name = "GateGlobe"
		var sm := SphereMesh.new()
		sm.radius = 0.17
		sm.height = 0.4
		sm.radial_segments = 12
		sm.rings = 6
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color("#E8C890")
		gm.emission_enabled = true
		gm.emission = Color("#F2B25C")
		gm.emission_energy_multiplier = 2.2
		sm.material = gm
		gate_globe.mesh = sm
		gate_globe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gate_globe.position = gl
		gate_globe.visible = false
		add_child(gate_globe)
	_mm("Flames", 0, fl)
	_mm("Embers", 1, em)
	_update(fposmod(WorldClock.minute, 1440.0))
	return {"altar": _count("altar"), "tunnel": _count("tunnel"), "embers": _count("ember"), "fire": _count("fire") > 0,
			"passage": _count("passage"), "shrine": _count("shrine"), "temple": _count("temple")}


func _count(what: String) -> int:
	return placed.filter(func(p: Array) -> bool: return p[0] == what).size()


## How lit `what` (its `order`th) is at `m` minutes of the day, 0 to 1; a burner's ember (`ember`) by its instance data
## `c` from world/dusk.gd (y: the minutes after the window opens it is lit; z: its strength), as its smoke.
static func lit(what: String, order: int, m: float, c := Color(0.0, 0.0, 1.0, 0.0)) -> float:
	match what:
		"altar":  # lit one after another from 17:00, out at 21:00 but the middle one, which burns till the morning's
			var on := 1020.0 + order * 0.6
			var eve := smoothstep(on, on + 0.3, m) * (1.0 if order == 3 else 1.0 - smoothstep(1260.0, 1261.0, m))
			var night := 1.0 if order == 3 and m < 420.0 else 0.0
			var morn := smoothstep(330.0 + order * 0.6, 330.3 + order * 0.6, m) * (1.0 - smoothstep(420.0, 421.0, m))
			return maxf(maxf(eve, night), morn)
		"tunnel", "passage", "temple":  # dark all day, or kept before the image: never out
			return 1.0
		"shrine":  # the pavilion's butter lamps: lit from 17:05 by the toll steward's boy, out at 21:00; and the morning's
			var eve := smoothstep(1025.0 + order * 0.5, 1025.3 + order * 0.5, m) * (1.0 - smoothstep(1260.0, 1261.0, m))
			var morn := smoothstep(330.0 + order * 0.5, 330.3 + order * 0.5, m) * (1.0 - smoothstep(420.0, 421.0, m))
			return maxf(eve, morn)
		"ember":  # as its smoke (shaders/smoke.gdshader): lit 30 minutes late or more, a morning's alone, closing as late
			var e := smoothstep(1020.0 + c.g, 1024.0 + c.g, m) * (1.0 - smoothstep(1065.0, 1080.0, m)) * (1.0 if c.g < 30.0 else 0.0)
			var late := c.g + 15.0 if c.g >= 30.0 else 0.0
			var a := smoothstep(345.0 + c.g, 349.0 + c.g, m) * (1.0 - smoothstep(390.0 + late, 405.0 + late, m))
			return maxf(e, a) * c.b
		"fire":
			return smoothstep(1065.0, 1072.0, m) * (1.0 - smoothstep(1250.0, 1262.0, m))
		"fire2":  # carried from the front yard's as it dies, for the bard from 21:00; let die from 21:50, before the gate's bar
			return smoothstep(1258.0, 1263.0, m) * (1.0 - smoothstep(1310.0, 1325.0, m))
		"lantern":  # Dechen-tsang's gate lantern: lit at 17:25, out at 06:00
			return 1.0 if m >= 1045.0 or m < 360.0 else 0.0
	return 0.0


func _process(_dt: float) -> void:
	var m := fposmod(WorldClock.minute, 1440.0)
	if absf(m - _last) >= 0.1:
		_update(m)
	if fire != null and fire.visible:  # the fire's light flickers
		var t := Time.get_ticks_msec() / 1000.0
		fire.light_energy = 4.0 * _fire_k * (0.84 + 0.1 * sin(t * 7.3) + 0.06 * sin(t * 13.1 + 1.3))
	if fire2 != null and fire2.visible:
		var t2 := Time.get_ticks_msec() / 1000.0
		fire2.light_energy = 3.6 * _fire2_k * (0.84 + 0.1 * sin(t2 * 6.7 + 0.9) + 0.06 * sin(t2 * 12.3 + 2.1))


func _update(m: float) -> void:
	_last = m
	var on := {}
	for l in lamps:
		var what := String(l[0])
		var c := Color(0.0, 0.0, 1.0, 0.0)
		if what == "ember" and int(l[1]) < _burners.size():
			c = _burners[int(l[1])]
		var s := lit(what, int(l[1]), m, c)
		(l[2] as MultiMesh).set_instance_custom_data(int(l[3]), Color(s, float(l[4]), 0.0, 0.0))
		on[what] = float(on.get(what, 0.0)) + s
	strength = on
	if hall != null:
		var k := float(on.get("altar", 0.0)) / 7.0
		hall.visible = k > 0.01
		hall.light_energy = 3.2 * k
	if tunnel != null:
		tunnel.visible = true
		tunnel.light_energy = 0.7
	for pl in passage:
		pl.visible = true
		pl.light_energy = 0.6
	if temple != null:
		temple.visible = true
		temple.light_energy = 1.4
	_fire_k = float(on.get("fire", 0.0)) / 4.0  # its coals and three tongues
	if fire != null:
		fire.visible = _fire_k > 0.01
	_fire2_k = float(on.get("fire2", 0.0)) / 4.0
	if fire2 != null:
		fire2.visible = _fire2_k > 0.01
	if gate_lamp != null:
		var lk := lit("lantern", 0, m)
		gate_lamp.visible = lk > 0.5
		gate_lamp.light_energy = 1.5
		gate_globe.visible = lk > 0.5


func _mm(nm: String, kind: int, items: Array) -> void:
	if items.is_empty():
		return
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mat := ShaderMaterial.new()
	mat.shader = LAMP
	mat.set_shader_parameter("kind", kind)
	q.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = q
	mm.instance_count = items.size()
	for i in items.size():
		var it: Array = items[i]
		var sz: Vector2 = it[3]
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(sz.x, sz.y, 1.0)), it[2]))
		mm.set_instance_custom_data(i, Color(0.0, float(it[4]), 0.0, 0.0))
		lamps.append([String(it[0]), int(it[1]), mm, i, float(it[4])])
		placed.append([String(it[0]), it[2]])
	var mi := MultiMeshInstance3D.new()
	mi.name = nm
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _light(nm: String, at: Vector3, colour: Color, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = nm
	l.light_color = colour
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	l.light_specular = 0.2
	l.light_volumetric_fog_energy = 0.0  # the valley's haze grid showed a room's fire as orange steps (tools/build/make_rooms.gd)
	l.light_energy = 0.0
	l.visible = false
	l.position = at
	add_child(l)
	return l


## The yard's fireplace: a ring of ash and four charred ends of wood pushed in towards the middle, there day and night.
func _hearth(c: Vector3) -> void:
	var ash := MeshInstance3D.new()
	ash.name = "Hearth"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.55
	disc.bottom_radius = 0.6
	disc.height = 0.04
	disc.radial_segments = 14
	var am := StandardMaterial3D.new()
	am.albedo_color = Color("#2A2421")
	am.roughness = 1.0
	disc.material = am
	ash.mesh = disc
	ash.position = c + Vector3(0.0, 0.01, 0.0)
	add_child(ash)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#3B2C21")
	wood.roughness = 1.0
	for k in 4:
		var log := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.09, 0.08, 0.62)
		bm.material = wood
		log.mesh = bm
		var a := k * PI / 2.0 + 0.4
		log.transform = Transform3D(Basis(Vector3.UP, a), c + Vector3(sin(a) * 0.38, 0.05, cos(a) * 0.38))
		add_child(log)
