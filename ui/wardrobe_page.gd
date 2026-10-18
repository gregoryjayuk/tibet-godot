extends CanvasLayer
## The chest's page (world/wardrobe.gd; IMP-025): the clothes the one shown can wear, the one worn marked, in words, and
## the keys. Paper, as the codex's page (ui/codex_page.gd), down the left of the screen so the walker turning stands
## clear on the right.

const LATIN := preload("res://assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")

var _list: VBoxContainer
var _head: Label


func _ready() -> void:
	layer = 30
	var panel := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.96, 0.93, 0.86, 0.94)  # paper
	bg.border_color = Color(0.45, 0.2, 0.12)
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(4)
	bg.content_margin_left = 28.0
	bg.content_margin_right = 28.0
	bg.content_margin_top = 20.0
	bg.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", bg)
	panel.anchor_left = 0.04
	panel.anchor_right = 0.36
	panel.anchor_top = 0.14
	panel.anchor_bottom = 0.44
	add_child(panel)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 12)
	panel.add_child(_list)
	_head = _label(28, Color(0.35, 0.12, 0.08))
	_list.add_child(_head)


func _label(size: int, colour: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", LATIN)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


## The outfits [name, file, words] of the man or the woman (`who`), the worn one `worn`.
func show_outfits(outfits: Array, worn: int, who: String) -> void:
	for c in _list.get_children():
		if c != _head:
			c.queue_free()
	_head.text = "The chest in the guest room"
	var sub := _label(19, Color(0.45, 0.3, 0.2))
	sub.text = "Your clothes, %s" % ("the woman's" if who == "woman" else "the man's")
	_list.add_child(sub)
	for i in outfits.size():
		var t := _label(23 if i == worn else 21, Color(0.2, 0.12, 0.08) if i == worn else Color(0.42, 0.36, 0.3))
		t.text = ("●  " if i == worn else "○  ") + String(outfits[i][2])
		_list.add_child(t)
	var keys := _label(17, Color(0.45, 0.3, 0.2))
	if Controls.pad:  # the controller's buttons when it was the last thing used (autoload/controls.gd)
		keys.text = "↑ ↓  the next, the last   ·   left stick  turn\n□  the other of you   ·   △  close the chest"
	else:
		keys.text = "W, S  the next, the last   ·   A, D  turn\nB  the other of you   ·   E  close the chest"
	_list.add_child(keys)
