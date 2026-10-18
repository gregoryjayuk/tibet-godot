extends CanvasLayer
## The codex's page (plan chapter 11, 14.3; M1 sprint 7, step 7): the slice's nods (autoload/codex.gd SLICE), in Shöl,
## each found one with its nod, what the codex says and how true it is in words; the rest a line of dashes and its
## place, to be found. K opens and closes it.

const LATIN := preload("res://assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")

var _list: VBoxContainer
var _head: Label
var scroll: ScrollContainer


func _ready() -> void:
	layer = 30
	var panel := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.96, 0.93, 0.86, 0.96)  # paper
	bg.border_color = Color(0.45, 0.2, 0.12)
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(4)
	bg.content_margin_left = 36.0
	bg.content_margin_right = 36.0
	bg.content_margin_top = 24.0
	bg.content_margin_bottom = 24.0
	panel.add_theme_stylebox_override("panel", bg)
	panel.anchor_left = 0.14
	panel.anchor_right = 0.86
	panel.anchor_top = 0.07
	panel.anchor_bottom = 0.93
	add_child(panel)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)
	_head = _label(26, Color(0.35, 0.12, 0.08))
	_list.add_child(_head)

## Scrolled by `px` (the D-pad's up and down or Page Up and Down, through its book's keys), and by the right stick while
## open (IMP-044).
func scroll_by(px: float) -> void:
	if scroll != null:
		scroll.scroll_vertical += int(px)


func _process(dt: float) -> void:
	if visible and scroll != null:
		var v := Input.get_axis("look_up", "look_down")
		if v != 0.0:
			scroll.scroll_vertical += int(v * 1100.0 * dt)


func _label(size: int, colour: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", LATIN)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func refresh() -> void:
	for c in _list.get_children():
		if c != _head:
			c.queue_free()
	var got := 0
	for id in Codex.SLICE:
		got += 1 if Codex.found.has(id) else 0
	_head.text = "The codex  ·  Shöl, the slice's nods: %d of %d found" % [got, Codex.SLICE.size()]
	for id in Codex.SLICE:
		var e: Dictionary = Codex.entries.get(id, {})
		if e.is_empty():
			continue
		if Codex.found.has(id):
			var t := _label(22, Color(0.2, 0.12, 0.08))
			t.text = String(e["nod"])
			_list.add_child(t)
			var body := _label(18, Color(0.18, 0.15, 0.12))
			body.text = String(e["text"])
			_list.add_child(body)
			var tr := _label(15, Color(0.45, 0.3, 0.2))
			tr.text = "— %s" % Codex.truth_words(String(e["truth"]))
			_list.add_child(tr)
		else:
			var t := _label(20, Color(0.55, 0.5, 0.45))
			var pl := String(e["place"])
			t.text = "— — —   (to be found: %s)" % String(Codex.places.get(pl, pl)).get_slice(",", 0)
			_list.add_child(t)
