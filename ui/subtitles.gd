extends CanvasLayer
## Speech and prompts on the screen (plan chapter 07, 8.1; the game's sprint 7, step 4): a line of Tibetan in its script
## (Jomolhari, spike S4's face) or of Chinese in its characters (AR PL UKai, Greg's pick), with the English gloss under
## it, never Wylie or pinyin (Greg, 25 Sep 2026); a narrator's line in English alone, in italics, for what the player
## does (the libation); and a small prompt at the foot of the screen for what the player can do now (E sip; on the
## controller its button, "△ sip": autoload/controls.gd `say`, redrawn when the device changes). A line
## stays its seconds and fades; a new line replaces it. Found by others in the group "subtitles"; `lines` keeps what was
## said, for the tests and the stills.

const TIBETAN := preload("res://assets/source/fonts/jomolhari/Jomolhari-Regular.ttf")
const CHINESE := preload("res://assets/source/fonts/ar-pl-ukai/ukai.ttc")
const LATIN := preload("res://assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")

var lines: Array = []  ## [script, english, kind] of everything said, in order
var _box: VBoxContainer
var _panel: PanelContainer
var _script: Label
var _gloss: Label
var _who: Label  ## the speaker's name over a line overheard (world/talks.gd), small
var _prompt: Label
var _prompt_said := ""  ## the prompt as written, with the keys' letters (shown through Controls.say)
var _notice: Label
var _left := 0.0
var _notice_left := 0.0
var quiet_notices := false  ## the stills (tests/terrain/s3.gd) take no codex notice over their frames: written, never shown


func _ready() -> void:
	add_to_group("subtitles")
	layer = 20
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# a dark band behind the lines, so they read against whitewash in the sun (the rooms' bright plaster made them faint)
	_panel = PanelContainer.new()
	var band := StyleBoxFlat.new()
	band.bg_color = Color(0.06, 0.05, 0.04, 0.55)
	band.set_corner_radius_all(6)
	band.content_margin_left = 24.0
	band.content_margin_right = 24.0
	band.content_margin_top = 8.0
	band.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", band)
	_panel.anchor_left = 0.12
	_panel.anchor_right = 0.88
	_panel.anchor_top = 0.76
	_panel.anchor_bottom = 0.76
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_panel)
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_box)
	_who = _label(LATIN, 17)
	_who.add_theme_color_override("font_color", Color(0.86, 0.74, 0.46))
	_who.visible = false
	_script = _label(TIBETAN, 40)
	_gloss = _label(LATIN, 24)
	_box.add_child(_who)
	_box.add_child(_script)
	_box.add_child(_gloss)
	_prompt = _label(LATIN, 18)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.anchor_left = 0.2
	_prompt.anchor_right = 0.8
	_prompt.anchor_top = 0.93
	_prompt.anchor_bottom = 0.97
	_prompt.modulate = Color(1, 1, 1, 0.8)
	root.add_child(_prompt)
	Controls.device_changed.connect(func() -> void: _prompt.text = Controls.say(_prompt_said))
	_notice = _label(LATIN, 20)  # the codex's "found" at the top right (autoload/codex.gd)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_notice.anchor_left = 0.55
	_notice.anchor_right = 0.97
	_notice.anchor_top = 0.04
	_notice.anchor_bottom = 0.09
	_notice.modulate.a = 0.0
	root.add_child(_notice)
	_panel.modulate.a = 0.0


func _label(font: Font, size: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.05, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A line of Tibetan speech: its script and its English gloss; `who` its speaker's name over it, when the line is
## overheard among others (world/talks.gd).
func say(tibetan: String, english: String, seconds := 3.5, who := "") -> void:
	_show(tibetan, TIBETAN, english, seconds, "bo")
	_who.text = who
	_who.visible = who != ""


## A line of Chinese speech: its characters and its English gloss.
func say_zh(chinese: String, english: String, seconds := 3.5, who := "") -> void:
	_show(chinese, CHINESE, english, seconds, "zh")
	_who.text = who
	_who.visible = who != ""


## What the player does, told in English alone.
func narrate(english: String, seconds := 4.0) -> void:
	_show("", TIBETAN, english, seconds, "narration")
	_who.visible = false
	_gloss.add_theme_font_size_override("font_size", 22)


func prompt(text: String) -> void:
	_prompt_said = text
	_prompt.text = Controls.say(text)


## A short line at the top right that fades: the codex's "found".
func notice(text: String, seconds := 4.0) -> void:
	lines.append(["", text, "notice"])
	if quiet_notices:
		return
	_notice.text = text
	_notice_left = seconds
	_notice.modulate.a = 1.0


func _show(script: String, font: Font, english: String, seconds: float, kind: String) -> void:
	lines.append([script, english, kind])
	_script.text = script
	_script.visible = script != ""
	_script.add_theme_font_override("font", font)
	_gloss.text = english if kind != "narration" else "— %s —" % english
	_gloss.add_theme_font_size_override("font_size", 24)
	_left = seconds
	_panel.modulate.a = 1.0


func _process(dt: float) -> void:
	if _notice_left > 0.0:
		_notice_left -= dt
		_notice.modulate.a = clampf(_notice_left / 0.8, 0.0, 1.0)
	if _left > 0.0:
		_left -= dt
		if _left < 0.6:
			_panel.modulate.a = clampf(_left / 0.6, 0.0, 1.0)
