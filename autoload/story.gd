extends Node
## The story's state (M2 sprint 1, steps 2-4; plan chapter 11, 18.2; chapter 14, 7): the conversations' flags; the
## people's memory of the player (who has met him, what each knows of him and when they learned it, favours and debts,
## and what passes on through a household: a thing one person saw, told to the others a while later); the player's
## ledger (missions in his own words with the person, the place and the hour; debts; the words he has learned); and his
## purse (rupees, Chinese cash, tea bricks: chapter 01, 7). One block of the save ("story"). "Standing is people, not a
## meter" (chapter 14, 7): there is no score here, only who knows what.

signal changed  ## something in the ledger or the memory changed (the ledger's page redraws)

var save_key := "story"
var flags := {}  ## name -> true
var people := {}  ## who (a TownSim key) -> {met: minute, knows: {fact: minute}, favour: int, owes: rupees (he owes the player; less than 0, the player owes him)}
var passing: Array = []  ## told on later: {fact, to: [who], at: minute}
var ledger: Array = []  ## {id, kind: mission | debt | word | note, text, who, place, at: minute, done: bool}
var purse := {"rupees": 12.0, "cash": 300, "bricks": 2}  ## a tea house's junior on the road (design)
var page: CanvasLayer  ## the ledger's page (ui/ledger_page.gd), L

const Page := preload("res://ui/ledger_page.gd")
const LINES := "res://data/story_lines.json"
var _lines := {}


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ledger"):  # L, or the controller's touchpad (or Share)
		toggle_page()
		get_viewport().set_input_as_handled()
	elif page != null and page.visible and e.is_action_pressed("back"):  # Esc, or circle
		toggle_page(false)
		get_viewport().set_input_as_handled()
	elif page != null and page.visible and (e.is_action_pressed("page_up") or e.is_action_pressed("page_down")):
		page.call("scroll_by", -240.0 if e.is_action_pressed("page_up") else 240.0)
		get_viewport().set_input_as_handled()


## Opens or closes the ledger (`show` to set it), heard as the codex's book is (SND-609).
func toggle_page(show: Variant = null) -> void:
	if page == null:
		page = Page.new()
		page.visible = false  # made shut, so the first press opens it (it had shut a page just made: two presses)
		add_child(page)
	var was := page.visible
	page.visible = (not page.visible) if show == null else bool(show)
	Controls.open_page("ledger", page.visible)
	if page.visible:
		page.call("refresh")
	var ad := get_node_or_null("/root/AudioDirector")
	if ad != null and was != page.visible:
		ad.call("play_ui", "SND-609.open" if page.visible else "SND-609.close")


func _process(_dt: float) -> void:
	if passing.is_empty():
		return
	var m := WorldClock.minute
	for p in passing.duplicate():
		if m >= float(p["at"]):
			for who in p["to"]:
				tell(String(who), String(p["fact"]))
			passing.erase(p)


func flag(name: String) -> bool:
	return flags.has(name)


func set_flag(name: String, on := true) -> void:
	if on:
		flags[name] = true
	else:
		flags.erase(name)


func _person(who: String) -> Dictionary:
	if not people.has(who):
		people[who] = {"met": -1.0, "knows": {}, "favour": 0, "owes": 0.0}
	return people[who]


func met(who: String) -> bool:
	return people.has(who) and float(people[who]["met"]) >= 0.0


func meet(who: String) -> void:
	var p := _person(who)
	if float(p["met"]) < 0.0:
		p["met"] = WorldClock.minute
		changed.emit()


## Whether `who` knows `fact` (saw it, or was told).
func knows(who: String, fact: String) -> bool:
	return people.has(who) and (people[who]["knows"] as Dictionary).has(fact)


func tell(who: String, fact: String) -> void:
	var k: Dictionary = _person(who)["knows"]
	if not k.has(fact):
		k[fact] = WorldClock.minute
		changed.emit()


## `fact` told on to each of `to`, `after` game minutes from now (a household's talk; a rumour's way round the town).
func pass_on(fact: String, to: Array, after := 720.0) -> void:
	passing.append({"fact": fact, "to": to.duplicate(), "at": WorldClock.minute + after})


func favour(who: String, n: int) -> void:
	var p := _person(who)
	p["favour"] = int(p["favour"]) + n
	changed.emit()


## A debt: what `who` owes the player in rupees (negative: what the player owes).
func owe(who: String, rupees: float) -> void:
	var p := _person(who)
	p["owes"] = float(p["owes"]) + rupees
	changed.emit()


## A ledger entry (once by its id; written again, its text is the new one).
func write(id: String, kind: String, text: String, who := "", place := "") -> void:
	for e in ledger:
		if String(e["id"]) == id:
			e["text"] = text
			changed.emit()
			return
	ledger.append({"id": id, "kind": kind, "text": text, "who": who, "place": place, "at": WorldClock.minute, "done": false})
	changed.emit()


## One of the story's own lines not in a conversation (data/story_lines.json) by its id: {en, bo, zh, who, where}; the
## English alone until the line is written and checked in its script.
func line(id: String) -> Dictionary:
	if _lines.is_empty() and FileAccess.file_exists(LINES):
		for l in (JSON.parse_string(FileAccess.get_file_as_string(LINES)) as Dictionary).get("lines", []):
			_lines[String(l["id"])] = l
	return _lines.get(id, {"en": ""})


## A word learned: a phrasebook line by its id, in its script with its English (world/barks.gd `line`), never Wylie.
func learn(id: String, note := "") -> void:
	for e in ledger:
		if String(e["id"]) == id:
			return
	var l: Dictionary = (load("res://world/barks.gd") as GDScript).call("line", id)
	if String(l.get("script", "")) == "":
		return
	ledger.append({"id": id, "kind": "word", "text": String(l.get("english", "")) + ("" if note == "" else ": " + note),
			"script": String(l["script"]), "lang": String(l.get("lang", "bo")), "who": "", "place": "", "at": WorldClock.minute, "done": false})
	changed.emit()


func done(id: String) -> void:
	for e in ledger:
		if String(e["id"]) == id:
			e["done"] = true
			changed.emit()


func entry(id: String) -> Dictionary:
	for e in ledger:
		if String(e["id"]) == id:
			return e
	return {}


## Pay `amount` of rupees, cash or bricks; false if the purse has not enough.
func pay(kind: String, amount: float) -> bool:
	if float(purse.get(kind, 0)) < amount:
		return false
	purse[kind] = float(purse[kind]) - amount
	changed.emit()
	return true


func receive(kind: String, amount: float) -> void:
	purse[kind] = float(purse.get(kind, 0)) + amount
	changed.emit()


func save_state() -> Dictionary:
	return {"flags": flags.duplicate(), "people": people.duplicate(true), "passing": passing.duplicate(true),
			"ledger": ledger.duplicate(true), "purse": purse.duplicate()}


func load_state(d: Dictionary) -> void:
	flags = (d.get("flags", {}) as Dictionary).duplicate()
	people = (d.get("people", {}) as Dictionary).duplicate(true)
	passing = (d.get("passing", []) as Array).duplicate(true)
	ledger = (d.get("ledger", []) as Array).duplicate(true)
	purse = (d.get("purse", purse) as Dictionary).duplicate()
	changed.emit()


## A new game's story: nothing known, nothing written.
func reset() -> void:
	flags = {}
	people = {}
	passing = []
	ledger = []
	purse = {"rupees": 12.0, "cash": 300, "bricks": 2}
	changed.emit()
