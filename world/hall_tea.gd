extends "res://world/tea.gd"
## The general tea's seat in the Tsokchen (M3 sprint 6, step 4; plan chapter 04, 3.1: "A seat at the back of the left row
## during the general tea: the player may sit, is served, and learns to let the bowl be refilled and to leave a little in
## it when done"; the mang ja, 11:00-11:40, world/assembly.gd's session GENERAL). The guest's bowl stands on the book-stand
## before the west row's place at the rows' door end, by the aisle (the nave's SEAT 1, kept free at the general tea:
## world/assembly.gd GUEST_SEAT). Sitting (C) there while the tea is on, the novice who serves the back rows
## (world/hall_day.gd's `server`, standing in the aisle with the big kettle) comes and pours as world/tea.gd's hosts do: E
## the libation first, then a sip and he fills the bowl again; R a palm over the bowl. Nothing is said over the tea in the
## hall. Standing up with a little left in the bowl is a guest's thanks; drained, or covered at the first pour, the
## narration says how it is done. Made by world/hall_day.gd under the hall's ROOM 1 socket.

const Assembly := preload("res://world/assembly.gd")
const KETTLE := 1.6  ## the temple's big kettle: the kit's tea jug this much bigger
const LITTLE := 0.08  ## at least this much of a bowl left standing up: "a little"
const BOWL_COLOR := Color(0.36, 0.23, 0.13)  ## a turned wooden bowl, walnut (design)

var hall_day: Node  ## world/hall_day.gd: its `server` figure and `overrides`
var lesson := ""  ## the last visit's lesson: "left_a_little", "drained", "refused" (the route's)


func _ready() -> void:
	set_meta("pour_line", "")
	set_meta("leave_line", "")
	set_meta("enough_line", "")
	super()
	pot_scale = KETTLE
	_handle = POT_HANDLE * KETTLE
	_spout = POT_SPOUT * KETTLE
	_pour_high = 0.16
	_bowl()


## The guest's wooden bowl on the stand: open, its inside seen.
func _bowl() -> void:
	var b := MeshInstance3D.new()
	b.name = "GuestBowl"
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r * 0.62
	cm.height = r * 0.74
	cm.radial_segments = 16
	cm.cap_top = false
	var m := StandardMaterial3D.new()
	m.albedo_color = BOWL_COLOR
	m.roughness = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	cm.material = m
	b.mesh = cm
	b.position = Vector3(0.0, stand + r * 0.37, 0.0)
	add_child(b)


## The novice serving the back rows, while the general tea is on; else no one.
static func tea_on(minute: float) -> bool:
	return Assembly.session_at(fposmod(minute, 1440.0), Assembly.good_day(minute)) == Assembly.GENERAL


func _server() -> int:
	if hall_day == null or not (hall_day.get("figures") as Dictionary).has("server") or not tea_on(WorldClock.minute):
		return -1
	return 0


func _seat_of(_i: int) -> Vector3:
	return hall_day.call("server_spot")


func _host_valid(i: int) -> bool:
	return i == 0 and hall_day != null


func _hosts() -> Node:
	return hall_day


func _host_body() -> Node3D:
	return ((hall_day.get("figures") as Dictionary)["server"]).root


## The lesson of a visit, from what was left in the bowl standing up, the refills and whether the guest said enough.
static func lesson_of(left: float, refills: int, said_enough: bool) -> String:
	if said_enough and refills == 0:
		return "refused"
	if left < LITTLE:
		return "drained"
	return "left_a_little"


func _leave() -> void:
	if server >= 0 and libation:
		lesson = lesson_of(level, refills, enough)
		match lesson:
			"refused":
				_narrate("The novice waits a moment with the kettle, then moves on. A guest lets the bowl be filled again before covering it.")
			"drained":
				_narrate("The bowl is empty: the novice was already turning back with the kettle. A guest leaves a little in it when done.")
			_:
				_narrate("You leave a little in the bowl, and the novice moves on down the row.")
		print("hall tea: %s (%.2f of a bowl left, %d refills, enough %s)" % [lesson, level, refills, str(enough)])
	super()
	refills = 0
	sips = 0
	libation = false
