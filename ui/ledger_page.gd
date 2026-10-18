extends CanvasLayer
## The player's ledger (plan chapter 09, 15.3; chapter 14, 7; M2 sprint 1, step 4): a trader's book, brown ink on coarse
## paper (#E2D6BA), stitched along its top: the day; the errands in the player's own words, with the person, the place
## and the hour, the done ones struck through; who owes the house and whom the player owes; notes; the words learned; the
## purse. No marker, no map pin: the ledger says where in words. L opens and closes it (autoload/story.gd).

const LATIN := preload("res://assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")
const TIBETAN := preload("res://assets/source/fonts/jomolhari/Jomolhari-Regular.ttf")
const CHINESE := preload("res://assets/source/fonts/ar-pl-ukai/ukai.ttc")
const PAPER := Color(0.886, 0.839, 0.729, 0.97)  ## #E2D6BA
const INK := Color(0.29, 0.18, 0.1)
const FADED := Color(0.55, 0.47, 0.38)
const WEEK := ["Wednesday", "Thursday", "Friday", "Saturday", "Sunday", "Monday", "Tuesday"]  ## 21 October 1903 was a Wednesday

var _list: VBoxContainer
var lines: Array = []  ## the page's text, line by line (the tests')
var scroll: ScrollContainer


func _ready() -> void:
	layer = 30
	var panel := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = PAPER
	bg.border_color = Color(0.36, 0.24, 0.14)
	bg.set_border_width_all(2)
	bg.border_width_top = 10  # the stitched spine along its top
	bg.content_margin_left = 40.0
	bg.content_margin_right = 40.0
	bg.content_margin_top = 30.0
	bg.content_margin_bottom = 24.0
	panel.add_theme_stylebox_override("panel", bg)
	panel.anchor_left = 0.18
	panel.anchor_right = 0.82
	panel.anchor_top = 0.08
	panel.anchor_bottom = 0.92
	add_child(panel)
	var stitches := Label.new()  # the binding's thread over the spine
	stitches.text = "×   ×   ×   ×   ×   ×   ×   ×   ×   ×   ×   ×"
	stitches.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stitches.add_theme_font_override("font", LATIN)
	stitches.add_theme_font_size_override("font_size", 14)
	stitches.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
	stitches.anchor_left = 0.18
	stitches.anchor_right = 0.82
	stitches.anchor_top = 0.08
	stitches.offset_top = -9.0
	add_child(stitches)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

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


func _label(text: String, size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", LATIN)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(l)
	lines.append(text)
	return l


## A game minute as the ledger dates it: "Thursday 29 October 1903, 14:30".
static func date_of(minute: float) -> String:
	var d := int(floor(minute / 1440.0))
	var day := 21 + d
	var month := "October"
	if day > 31:
		day -= 31
		month = "November"
	return "%s %d %s 1903, %s" % [WEEK[posmod(d, 7)], day, month, Calendar.clock(minute)]


static func name_of(who: String) -> String:
	return " ".join(Array(who.split("_")).map(func(w: String) -> String: return w.capitalize()))


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	lines.clear()
	_label(date_of(WorldClock.minute), 24, INK)
	var kinds := {"mission": "Errands", "debt": "Debts", "note": "Notes", "word": "Words"}
	for k in kinds:
		var es := Story.ledger.filter(func(e: Dictionary) -> bool: return String(e["kind"]) == k)
		var owing := []
		if k == "debt":
			for who in Story.people:
				var o := float(Story.people[who]["owes"])
				if absf(o) > 0.001:
					owing.append("%s owes the house %.1f rupees" % [name_of(who), o] if o > 0.0 else "I owe %s %.1f rupees" % [name_of(who), -o])
		if es.is_empty() and owing.is_empty():
			continue
		_label(String(kinds[k]), 20, Color(0.45, 0.14, 0.1))
		for e in es:
			if e.has("script"):  # a word: its script, then its English (never Wylie or pinyin)
				var w := _label(String(e["script"]), 26, INK)
				w.add_theme_font_override("font", CHINESE if String(e.get("lang", "bo")) == "zh" else TIBETAN)
				_label("     " + String(e["text"]), 16, FADED)
				continue
			var done := bool(e.get("done", false))
			var where := ""
			if String(e.get("who", "")) != "" or String(e.get("place", "")) != "":
				where = "  (%s)" % ", ".join([name_of(String(e["who"])) if String(e["who"]) != "" else "", String(e["place"])].filter(func(s: String) -> bool: return s != ""))
			var l := _label(("✓  " if done else "·  ") + String(e["text"]) + where, 18, FADED if done else INK)
			if done:
				l.add_theme_color_override("font_color", FADED)
		for o in owing:
			_label("·  " + String(o), 18, INK)
	var p := Story.purse
	_label("In the purse: %s rupees, %d cash, %d bricks of tea" % [str(snappedf(float(p.get("rupees", 0)), 0.1)), int(p.get("cash", 0)), int(p.get("bricks", 0))], 16, FADED)
