extends CanvasLayer
## The start-up help line, sized for the Retina screen (hiDPI is on), fading after twelve seconds, written for the keys
## and the mouse or for a PS4 controller, whichever was used last, and shown again when that changes (IMP-044,
## autoload/controls.gd); and, when the day
## runs (M1's look), the game time and the Tibetan date in the top right corner. A gloss: one line at the foot of the
## screen the first time a practice is met (chapter 07: "Few interactions, each with a gloss"; no score, no counter),
## called by whoever meets it through the group "hud".

var help: Label
var show_clock := false  ## set before adding: the day runs, so show the clock and its keys
var third_person := false  ## set before adding: the player is seen in third person (player/player.gd), with its keys
var player: Node  ## set before adding, to show the sling's aiming dot while the sling is out (spike S19)
var dot: ColorRect
var clock: Label
var gloss_label: Label
var _glossed := {}  ## each gloss once a session


func _ready() -> void:
	add_to_group("hud")
	var scale := DisplayServer.screen_get_scale()
	gloss_label = Label.new()
	gloss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gloss_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	gloss_label.offset_left = -520.0 * scale
	gloss_label.offset_right = 520.0 * scale
	gloss_label.offset_top = -64.0 * scale
	gloss_label.offset_bottom = -24.0 * scale
	gloss_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gloss_label.add_theme_font_size_override("font_size", int(17 * scale))
	gloss_label.add_theme_color_override("font_color", Color(1, 0.97, 0.9, 0.95))
	gloss_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	gloss_label.add_theme_constant_override("shadow_offset_x", 1)
	gloss_label.add_theme_constant_override("shadow_offset_y", 1)
	gloss_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gloss_label.modulate.a = 0.0
	add_child(gloss_label)
	help = Label.new()
	help.text = help_text()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.set_anchors_preset(Control.PRESET_TOP_WIDE)
	help.anchor_right = 0.7  # clear of the clock at the top right
	help.offset_left = 16.0 * scale
	help.offset_top = 12.0 * scale
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help.add_theme_font_size_override("font_size", int(16 * scale))
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	help.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	help.add_theme_constant_override("shadow_offset_x", 1)
	help.add_theme_constant_override("shadow_offset_y", 1)
	add_child(help)
	_fade_help()
	Controls.device_changed.connect(_on_device)
	if player != null:
		dot = ColorRect.new()
		dot.color = Color(1, 1, 1, 0.75)
		# a control stops the mouse by default, and the captured mouse sits at the screen's centre, under the dot: it
		# would swallow every click and motion (Greg, 25 Sep 2026, 21:09: "no way to then aim or whirl")
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.size = Vector2(5, 5) * scale
		dot.set_anchors_preset(Control.PRESET_CENTER)
		dot.position -= dot.size / 2
		dot.visible = false
		add_child(dot)
	if show_clock:
		clock = Label.new()
		clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		clock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		clock.offset_left = -420.0 * scale
		clock.offset_right = -16.0 * scale
		clock.offset_top = 12.0 * scale
		clock.add_theme_font_size_override("font_size", int(18 * scale))
		clock.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		clock.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		clock.add_theme_constant_override("shadow_offset_x", 1)
		clock.add_theme_constant_override("shadow_offset_y", 1)
		add_child(clock)


func _process(_dt: float) -> void:
	if dot != null:
		var f = player.get("fight")
		dot.visible = f != null and f.sling
	if clock != null:
		var t := Calendar.tibetan_date(WorldClock.minute)
		var walk: bool = player != null and bool(player.get("walking"))  # the walk toggled on (Option; the jog the default)
		clock.text = "%s  ·  Tibetan %d/%d%s%s" % [Calendar.clock(WorldClock.minute), t.get("month", 0), t.get("day", 0),
			"  ·  watching" if WorldClock.rate > WorldClock.RATE_PLAY else "", "  ·  walking" if walk else ""]


## The help line for the device used last: the keys and the mouse (World of Warcraft's), or the controller (GTA's).
func help_text() -> String:
	var t: String
	if Controls.pad:
		t = "Left stick: move (a light tilt walks) · right stick: look · ✕ held: sprint · □ jump · △ talk, use"
		if third_person:
			t += " · ○ sit or stand (time runs 60:1) · R1 punch · L1 guard (□ with it up: dodge) · R2 held: the sling whirls, let go to loose · R3 first or third person"
		t += " · touchpad: the ledger · Options: the codex"
		return t
	if third_person:
		t = "W S forward, back · A D turn (the right button held: step aside) · drag with the left button to look round, with the right to steer, both to walk on · the wheel: closer, further · Shift held: sprint · Option: walk · Space jump (with the guard up, dodge) · E talk, use · C sit (time runs 60:1) · V first or third person · B man or woman · R fists up (left punch, right guard) · G sling (hold left to whirl, let go to loose) · L ledger · K codex · Esc lowers them"
	else:
		t = "The mouse looks (Esc frees it; a button held looks again) · W A S D move · Shift held: sprint · Option: walk · Space jump"
	t += " · F fly (E/Q) · O ink lines · the number keys viewpoints"
	if show_clock:
		t += " · hold T: time runs 60:1 · [ ]: an hour back or on"
	return t


var _help_tween: Tween


func _on_device() -> void:
	help.text = help_text()
	_fade_help()


## The help line shown, then faded after twelve seconds.
func _fade_help() -> void:
	if _help_tween != null:
		_help_tween.kill()
	help.modulate.a = 1.0
	_help_tween = create_tween()
	_help_tween.tween_interval(12.0)
	_help_tween.tween_property(help, "modulate:a", 0.0, 2.0)


## Show `text` at the foot of the screen for eight seconds, the first time only (by `key`, or the text itself).
func gloss(text: String, key := "") -> void:
	var k := key if key != "" else text
	if _glossed.has(k):
		return
	_glossed[k] = true
	gloss_label.text = text
	var tw := create_tween()
	tw.tween_property(gloss_label, "modulate:a", 1.0, 0.6)
	tw.tween_interval(8.0)
	tw.tween_property(gloss_label, "modulate:a", 0.0, 1.5)

