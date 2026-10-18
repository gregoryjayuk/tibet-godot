extends Node
## The controls (IMP-044; Greg's brief of 14 Oct 2026, docs/brief-movement-controls.md). Every key, mouse button and
## controller button the game reads is an input action from ACTIONS, bound to the keys and a PS4 controller alike:
## tools/build/make_input.gd writes the table into project.godot's [input], the map the game starts with
## (test_controls.gd checks that the two agree). The keys and the mouse as World of Warcraft has them, the controller
## GTA's way (player/player.gd). Kept here as well: which was used last, the keys or the controller (`pad`,
## `device_changed`), for the help line, the prompts (`say`) and the replies' labels; the right stick's turn of the camera,
## with its dead zone, its curve and a little acceleration (`look`); and which page is open (`pages`), so the player's own
## buttons wait while one is.

signal device_changed

const KEY := 0  ## [KEY, keycode]
const MOUSE := 1  ## [MOUSE, button]
const BUTTON := 2  ## [BUTTON, controller button]
const AXIS := 3  ## [AXIS, controller axis, -1 or 1]
## The actions: [their events, the dead zone]. The controller's buttons by the SDL layout's names, which Godot maps the
## DS4 to on macOS (its built-in "PS4 Controller", platform Mac OS X): A is the PS4's cross, B circle, X square, Y triangle,
## BACK share, START options; the touchpad is a button of its own.
const ACTIONS := {
	# moving: the keys (World of Warcraft's: W and S along the walker's way, A and D turn it, or step aside with the right
	# button held) and the left stick (GTA's: the way it is pushed, from the camera; a light tilt walks)
	"move_forward": [[[KEY, KEY_W], [KEY, KEY_UP]], 0.5],
	"move_back": [[[KEY, KEY_S], [KEY, KEY_DOWN]], 0.5],
	"move_left": [[[KEY, KEY_A], [KEY, KEY_LEFT]], 0.5],
	"move_right": [[[KEY, KEY_D], [KEY, KEY_RIGHT]], 0.5],
	"stick_forward": [[[AXIS, JOY_AXIS_LEFT_Y, -1.0]], 0.2],
	"stick_back": [[[AXIS, JOY_AXIS_LEFT_Y, 1.0]], 0.2],
	"stick_left": [[[AXIS, JOY_AXIS_LEFT_X, -1.0]], 0.2],
	"stick_right": [[[AXIS, JOY_AXIS_LEFT_X, 1.0]], 0.2],
	# the camera: the right stick (shaped by `look`), the mouse dragged with a button held (player/player.gd)
	"look_left": [[[AXIS, JOY_AXIS_RIGHT_X, -1.0]], 0.15],
	"look_right": [[[AXIS, JOY_AXIS_RIGHT_X, 1.0]], 0.15],
	"look_up": [[[AXIS, JOY_AXIS_RIGHT_Y, -1.0]], 0.15],
	"look_down": [[[AXIS, JOY_AXIS_RIGHT_Y, 1.0]], 0.15],
	"orbit": [[[MOUSE, MOUSE_BUTTON_LEFT]], 0.5],  # held and dragged: the camera round the walker (the fists up: a punch)
	"steer": [[[MOUSE, MOUSE_BUTTON_RIGHT]], 0.5],  # held: the walker turns to the camera's way (the fists up: the guard)
	"zoom_in": [[[MOUSE, MOUSE_BUTTON_WHEEL_UP]], 0.5],
	"zoom_out": [[[MOUSE, MOUSE_BUTTON_WHEEL_DOWN]], 0.5],
	# the pace (IMP-043): the jog by default, the sprint held, the walk toggled (on the controller, a light tilt)
	"sprint": [[[KEY, KEY_SHIFT], [BUTTON, JOY_BUTTON_A]], 0.5],
	"walk": [[[KEY, KEY_ALT]], 0.5],
	"jump": [[[KEY, KEY_SPACE], [BUTTON, JOY_BUTTON_X]], 0.5],  # with the guard up, a dodge
	"use": [[[KEY, KEY_E], [BUTTON, JOY_BUTTON_Y]], 0.5],  # talk, open, pour, lay juniper, take an offer
	"sit": [[[KEY, KEY_C], [BUTTON, JOY_BUTTON_B]], 0.5],  # sit down, stand up
	"enough": [[[KEY, KEY_R], [BUTTON, JOY_BUTTON_X]], 0.5],  # at tea: a palm over the bowl (world/tea.gd)
	# fighting (chapter 11, 13.8): on the controller always to hand; on the keys the fists go up on R, which takes the
	# mouse for the fight, and the sling comes out on G
	"strike": [[[BUTTON, JOY_BUTTON_RIGHT_SHOULDER]], 0.5],
	"guard": [[[BUTTON, JOY_BUTTON_LEFT_SHOULDER]], 0.5],
	"whirl": [[[AXIS, JOY_AXIS_TRIGGER_RIGHT, 1.0]], 0.35],  # held, the sling whirls; let go, it looses
	"fists": [[[KEY, KEY_R]], 0.5],
	"sling": [[[KEY, KEY_G]], 0.5],
	"back": [[[KEY, KEY_ESCAPE], [BUTTON, JOY_BUTTON_B]], 0.5],  # a page shut; on the keys the fists lowered, the mouse freed
	"view": [[[KEY, KEY_V], [BUTTON, JOY_BUTTON_RIGHT_STICK]], 0.5],  # first or third person
	"body": [[[KEY, KEY_B]], 0.5],  # the man or the woman
	# the pages: the ledger (autoload/story.gd), the codex (autoload/codex.gd), turned with the D-pad or Page Up and Down
	"ledger": [[[KEY, KEY_L], [BUTTON, JOY_BUTTON_TOUCHPAD], [BUTTON, JOY_BUTTON_BACK]], 0.5],
	"codex": [[[KEY, KEY_K], [BUTTON, JOY_BUTTON_START]], 0.5],
	"page_up": [[[KEY, KEY_PAGEUP], [BUTTON, JOY_BUTTON_DPAD_UP]], 0.5],
	"page_down": [[[KEY, KEY_PAGEDOWN], [BUTTON, JOY_BUTTON_DPAD_DOWN]], 0.5],
	# a conversation's answers (world/conversation.gd, world/message.gd): the number keys, the D-pad clockwise from the top
	"answer_1": [[[KEY, KEY_1], [BUTTON, JOY_BUTTON_DPAD_UP]], 0.5],
	"answer_2": [[[KEY, KEY_2], [BUTTON, JOY_BUTTON_DPAD_RIGHT]], 0.5],
	"answer_3": [[[KEY, KEY_3], [BUTTON, JOY_BUTTON_DPAD_DOWN]], 0.5],
	"answer_4": [[[KEY, KEY_4], [BUTTON, JOY_BUTTON_DPAD_LEFT]], 0.5],
	# the game's own: saves (autoload/save.gd), time (held: 60:1), the hours, and the keys for looking at it
	"quicksave": [[[KEY, KEY_F5]], 0.5],
	"quickload": [[[KEY, KEY_F9]], 0.5],
	"watch": [[[KEY, KEY_T]], 0.5],
	"hour_back": [[[KEY, KEY_BRACKETLEFT]], 0.5],
	"hour_on": [[[KEY, KEY_BRACKETRIGHT]], 0.5],
	"fly": [[[KEY, KEY_F]], 0.5],
	"fly_up": [[[KEY, KEY_E]], 0.5],
	"fly_down": [[[KEY, KEY_Q]], 0.5],
	"ink": [[[KEY, KEY_O]], 0.5],
	"framing": [[[KEY, KEY_H]], 0.5],
	"telemetry": [[[KEY, KEY_F3], [KEY, KEY_QUOTELEFT]], 0.5],
	"viewpoint_1": [[[KEY, KEY_1]], 0.5],
	"viewpoint_2": [[[KEY, KEY_2]], 0.5],
	"viewpoint_3": [[[KEY, KEY_3]], 0.5],
	"viewpoint_4": [[[KEY, KEY_4]], 0.5],
	"viewpoint_5": [[[KEY, KEY_5]], 0.5],
	"viewpoint_6": [[[KEY, KEY_6]], 0.5],
	"viewpoint_7": [[[KEY, KEY_7]], 0.5],
	"viewpoint_8": [[[KEY, KEY_8]], 0.5],
	"viewpoint_9": [[[KEY, KEY_9]], 0.5],
	"viewpoint_10": [[[KEY, KEY_0]], 0.5],
}
## The controller's buttons and axes as a PS4's are labelled.
const PAD_BUTTONS := {JOY_BUTTON_A: "✕", JOY_BUTTON_B: "○", JOY_BUTTON_X: "□", JOY_BUTTON_Y: "△", JOY_BUTTON_BACK: "Share",
	JOY_BUTTON_START: "Options", JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_LEFT_SHOULDER: "L1",
	JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_DPAD_UP: "↑", JOY_BUTTON_DPAD_DOWN: "↓", JOY_BUTTON_DPAD_LEFT: "←",
	JOY_BUTTON_DPAD_RIGHT: "→", JOY_BUTTON_TOUCHPAD: "touchpad"}
const PAD_AXES := {JOY_AXIS_LEFT_X: "left stick", JOY_AXIS_LEFT_Y: "left stick", JOY_AXIS_RIGHT_X: "right stick",
	JOY_AXIS_RIGHT_Y: "right stick", JOY_AXIS_TRIGGER_LEFT: "L2", JOY_AXIS_TRIGGER_RIGHT: "R2"}
## The right stick's camera: radians a second at full tilt, the curve past the dead zone, and the acceleration: held
## over HOLD of full tilt for ACCEL_IN seconds, the turn grows by ACCEL (GTA's camera speeds up as the stick stays over).
const LOOK_YAW := 2.4
const LOOK_PITCH := 1.5
const LOOK_CURVE := 1.7
const HOLD := 0.92
const ACCEL := 0.6
const ACCEL_IN := 0.5
## The prompts' keys and what each is on the controller (ui/subtitles.gd `prompt` shows them through `say`).
const PROMPT_KEYS := {"E": "use", "C": "sit", "R": "enough"}

var pad := false  ## the controller was the last thing used (its labels on the help line and the prompts)
var pages := {}  ## the pages open now (the ledger, the codex, the wardrobe): name -> true
var _held := 0.0  ## seconds the right stick has stayed over HOLD


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pad = not Input.get_connected_joypads().is_empty()
	Input.joy_connection_changed.connect(_on_joy)


func _on_joy(_device: int, connected: bool) -> void:
	_set_pad(connected or not Input.get_connected_joypads().is_empty())


func _input(e: InputEvent) -> void:
	if e is InputEventJoypadButton and e.pressed:
		_set_pad(true)
	elif e is InputEventJoypadMotion and absf((e as InputEventJoypadMotion).axis_value) > 0.4:
		_set_pad(true)
	elif (e is InputEventKey or e is InputEventMouseButton) and e.is_pressed():
		_set_pad(false)  # (the mouse moved alone does nothing in play, so it does not take the labels back)


func _set_pad(on: bool) -> void:
	if on == pad:
		return
	pad = on
	device_changed.emit()


## The left stick past its dead zone: x right, y back (as the keys' axes), its length 0 to 1.
func stick() -> Vector2:
	return Input.get_vector("stick_left", "stick_right", "stick_forward", "stick_back")


## The right stick's turn of the camera this frame, in radians: x the yaw's (right positive), y the pitch's (down
## positive), each past its dead zone, curved, and quickened while it stays over.
func look(dt: float) -> Vector2:
	var v := Vector2(Input.get_axis("look_left", "look_right"), Input.get_axis("look_up", "look_down"))
	if v == Vector2.ZERO:
		_held = 0.0
		return v
	_held = _held + dt if v.length() > HOLD else 0.0
	var k := 1.0 + ACCEL * smoothstep(0.0, ACCEL_IN, _held)
	return Vector2(signf(v.x) * pow(absf(v.x), LOOK_CURVE) * LOOK_YAW, signf(v.y) * pow(absf(v.y), LOOK_CURVE) * LOOK_PITCH) * k * dt


## Whether any page is open (the player's own buttons wait while one is).
func any_page() -> bool:
	return not pages.is_empty()


func open_page(page: String, on: bool) -> void:
	if on:
		pages[page] = true
	else:
		pages.erase(page)


## The action's binding on the device in use: "E" on the keys, "△" on the controller ("" if it has none there).
func label(action: String, on_pad := pad) -> String:
	for ev in (ACTIONS.get(action, [[]]) as Array)[0]:
		match int(ev[0]):
			BUTTON:
				if on_pad:
					return String(PAD_BUTTONS.get(int(ev[1]), "button %d" % int(ev[1])))
			AXIS:
				if on_pad:
					return String(PAD_AXES.get(int(ev[1]), "axis %d" % int(ev[1])))
			KEY:
				if not on_pad:
					return _key_name(int(ev[1]))
			MOUSE:
				if not on_pad:
					return ["", "left button", "right button", "middle button", "wheel", "wheel"][clampi(int(ev[1]), 0, 5)]
	return ""


static func _key_name(k: int) -> String:
	match k:
		KEY_ALT:
			return "Option" if OS.get_name() == "macOS" else "Alt"
		KEY_ESCAPE:
			return "Esc"
		KEY_SPACE:
			return "Space"
	return OS.get_keycode_string(k)


## The k-th reply's label (0 to 3): its number on the keys, the D-pad's arrow on the controller.
func answer_label(k: int) -> String:
	return label("answer_%d" % (k + 1)) if pad else str(k + 1)


## A prompt as the device in use reads it: on the controller "E  open the door" is "△  open the door", "1-2  answer" is
## "↑ →  answer"; on the keys it is as written.
func say(text: String) -> String:
	if not pad or text == "":
		return text
	var parts := text.split("  ")  # a key stands alone between double spaces: "E  sip        R  enough"
	for i in parts.size():
		var p := parts[i].strip_edges()
		if PROMPT_KEYS.has(p):
			parts[i] = parts[i].replace(p, label(String(PROMPT_KEYS[p])))
		elif p.length() == 3 and p.begins_with("1-") and p[2].is_valid_int():
			var arrows := []
			for k in clampi(int(p[2]), 1, 4):
				arrows.append(label("answer_%d" % (k + 1)))
			parts[i] = parts[i].replace(p, " ".join(arrows))
	return "  ".join(parts)


## The events of an action (tools/build/make_input.gd, test_controls.gd), for any device.
static func events_of(action: String) -> Array:
	var out := []
	for ev in (ACTIONS[action] as Array)[0]:
		var e: InputEvent
		match int(ev[0]):
			KEY:
				var k := InputEventKey.new()
				k.keycode = int(ev[1]) as Key
				e = k
			MOUSE:
				var m := InputEventMouseButton.new()
				m.button_index = int(ev[1]) as MouseButton
				e = m
			BUTTON:
				var b := InputEventJoypadButton.new()
				b.button_index = int(ev[1]) as JoyButton
				e = b
			AXIS:
				var a := InputEventJoypadMotion.new()
				a.axis = int(ev[1]) as JoyAxis
				a.axis_value = float(ev[2])
				e = a
		e.device = -1  # any keyboard, mouse or controller (InputMap's ALL_DEVICES)
		out.append(e)
	return out
