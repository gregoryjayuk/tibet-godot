extends Node
## The codex (plan chapter 11, 14.3; chapter 07, 9; M1 sprint 7, step 7): chapter 07's 145 cultural nods
## (data/codex.json, from tools/culture/codex.py), each found by looking at it, going into it, doing it or being there
## when it happens (world/codex_sites.gd; world/message.gd, world/roof_sang.gd). Finding one says so for a moment at
## the screen's top right; K opens the book: the slice's entries (chapter 12's list for M1), each found one with what
## the codex says and how true it is in words, never a bare letter (chapter 01, 11: the codex stays honest).

signal found_entry(id: String)

const DATA := "res://data/codex.json"
## Chapter 12's M1 list: the nods sited in the slice.
const SLICE := ["CX-047", "CX-048", "CX-049", "CX-050", "CX-051", "CX-052", "CX-053", "CX-057", "CX-058", "CX-063",
		"CX-064", "CX-070", "CX-071"]
const Page := preload("res://ui/codex_page.gd")
const Subtitles := preload("res://ui/subtitles.gd")

var entries := {}  ## id -> {id, district, place, nod, text, truth}
var truth := {}  ## letter -> words
var places := {}  ## a gazetteer ID -> its English name (data/town.json), for the page's hints
var found := {}  ## id -> the game minute it was found
var order: Array = []  ## ids in the order found
var save_key := "codex"  ## its block in a save (autoload/save.gd)
var page: CanvasLayer


func _ready() -> void:
	if not FileAccess.file_exists(DATA):
		push_warning("codex: no %s (tools/culture/codex.py)" % DATA)
		return
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	truth = d["truth"]
	for e in d["entries"]:
		entries[String(e["id"])] = e
	if FileAccess.file_exists("res://data/town.json"):
		for b in (JSON.parse_string(FileAccess.get_file_as_string("res://data/town.json")) as Dictionary).get("buildings", []):
			places[String(b.get("id", ""))] = String(b.get("name_en", ""))


## Mark an entry found; true the first time. Its nod is shown for a moment (ui/subtitles.gd `notice`).
func find(id: String) -> bool:
	if not entries.has(id) or found.has(id):
		return false
	found[id] = WorldClock.minute
	var ad := get_node_or_null("/root/AudioDirector")
	if ad != null:  # a page turned as the entry is written (sprint 8, step 4)
		ad.call("play_ui", "SND-609.page")
	order.append(id)
	_subs().call("notice", "Codex  ·  %s" % String(entries[id]["nod"]))
	found_entry.emit(id)
	if page != null and page.visible:
		page.call("refresh")
	return true


## How true an entry is, in words (chapter 11, 14.3): a pair is the kind attested (or general), the placing the game's.
func truth_words(t: String) -> String:
	var parts := t.split("/")
	if parts.size() == 2:
		return "%s; %s" % [String(truth.get(parts[0], parts[0])), "placed here by the game" if parts[1] == "I" else "the detail general practice"]
	return String(truth.get(t, t))


func save_state() -> Dictionary:
	return {"found": found.duplicate(), "order": order.duplicate()}


func load_state(d: Dictionary) -> void:
	found = (d.get("found", {}) as Dictionary).duplicate()
	order = (d.get("order", []) as Array).duplicate()


func reset() -> void:
	found.clear()
	order.clear()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("codex"):  # K, or the controller's Options
		toggle_page()
		get_viewport().set_input_as_handled()
	elif page != null and page.visible and e.is_action_pressed("back"):  # Esc, or circle
		toggle_page(false)
		get_viewport().set_input_as_handled()
	elif page != null and page.visible and (e.is_action_pressed("page_up") or e.is_action_pressed("page_down")):
		page.call("scroll_by", -240.0 if e.is_action_pressed("page_up") else 240.0)
		get_viewport().set_input_as_handled()


func toggle_page(show: Variant = null) -> void:
	if page == null:
		page = Page.new()
		page.visible = false  # made shut, so the first press opens it (it had shut a page just made: two presses)
		add_child(page)
	var was := page.visible
	page.visible = (not page.visible) if show == null else bool(show)
	Controls.open_page("codex", page.visible)
	if page.visible:
		page.call("refresh")
	var ad := get_node_or_null("/root/AudioDirector")
	if ad != null and was != page.visible:  # the book opened or shut (sprint 8, step 4)
		ad.call("play_ui", "SND-609.open" if page.visible else "SND-609.close")


func _subs() -> Node:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s == null:
		s = Subtitles.new()
		get_tree().root.add_child(s)
	return s
