extends CanvasLayer
## The player's replies in a conversation (plan chapter 11, 14.2; chapter 09, 15.3; M2 sprint 1, step 2): up to four,
## numbered, over the subtitles' strip, chosen with 1-4 (world/conversation.gd), or on the controller with the D-pad,
## clockwise from the top, each labelled with its arrow (autoload/controls.gd `answer_label`; IMP-044). English, the player's own words; the
## same dark band as the subtitles, so they read against whitewash in the sun.

const LATIN := preload("res://assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")

var shown: Array = []  ## the replies' texts now shown, in their order (the tests')
var _panel: PanelContainer
var _box: VBoxContainer


func _ready() -> void:
	add_to_group("replies")
	layer = 21
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel = PanelContainer.new()
	var band := StyleBoxFlat.new()
	band.bg_color = Color(0.06, 0.05, 0.04, 0.55)
	band.set_corner_radius_all(6)
	band.content_margin_left = 22.0
	band.content_margin_right = 22.0
	band.content_margin_top = 8.0
	band.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", band)
	_panel.anchor_left = 0.2
	_panel.anchor_right = 0.8
	_panel.anchor_top = 0.66
	_panel.anchor_bottom = 0.66
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_panel)
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_box)
	_panel.visible = false
	Controls.device_changed.connect(_relabel)


func show_replies(texts: Array) -> void:
	for c in _box.get_children():
		c.queue_free()
	shown = texts.duplicate()
	for k in texts.size():
		var l := Label.new()
		l.text = "%s   %s" % [Controls.answer_label(k), String(texts[k])]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_override("font", LATIN)
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
		l.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.05, 0.85))
		l.add_theme_constant_override("outline_size", 6)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_box.add_child(l)
	_panel.visible = not texts.is_empty()


## The device changed (the keys, the controller): the replies shown again with its labels.
func _relabel() -> void:
	if not shown.is_empty():
		show_replies(shown)


func hide_replies() -> void:
	show_replies([])
