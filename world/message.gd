extends Node
## Carrying a message between Dechen-tsang's two counting rooms (plan chapter 04, 4.3: "the player can carry messages
## between the rooms, and learn that nobody opens a price first"; CX-052, three in a room; the game's sprint 7, step 5).
## Tibetan sellers and Chinese buyers did not deal face to face: the hostess carried the offers. This afternoon Achak
## Dolkar rides out to meet the caravan at 14:40 and leaves the deal's last offers to her guest: the Litang agent's price
## goes across the yard to Yang Shouren in the Chinese room and his answer comes back, three times, never spoken aloud
## but pressed with the fingers inside the sleeve (CX-048), until Yang says "Agreed!". Each step: stand by the one whose
## turn it is and press E. The lines are the phrasebook's (chapter 07, 8.5-8.6: PB-T10, PB-T16, PB-T31, PB-C02, PB-C03,
## PB-C04) with their English; what the hands say is told. Added by world/interiors.gd with Dechen-tsang's rooms.
## In the story (M2 sprint 1, step 6; chapter 14, 4.1, mission 3, "No one opens a price"), the offers are carried only
## once Achak Dolkar has asked it (the ledger's m3_price, written when the letter is given: the next afternoon), and at
## Yang Shouren's first answer the player chooses: press the agent's price into his sleeve as it was given, or speak it
## aloud to have it over with. A price spoken costs the house a little: Yang will not go above it, and Dolkar hears.
## Without a story begun (M1's slice, its acceptance walk) the offers are there every afternoon, as before.

const Subtitles := preload("res://ui/subtitles.gd")
const Replies := preload("res://ui/replies.gd")
const CHOICE_AT := 1  ## the step at which the player chooses how to give the agent's price: Yang's first answer
const SPOKEN := "Yang Shouren's eyebrows rise. The price is out in the room, and he will not go above it now; the agent's hands go still in your sleeve."
const SPOKEN_END := "A deal is made, lower than it might have been: a price was named aloud. The house stands guarantor all the same."
const Barks := preload("res://world/barks.gd")
const AGENT := "ngodrup_dedpon"
const BUYER := "yang_shouren"
const HOST := "achak_dolkar"
const NEAR := 1.7  ## metres from the one whose turn it is
const FROM := 14.0 * 60.0 + 30.0  ## the afternoon's minutes when the offers can be carried (the agent leaves at 16:05)
const UNTIL := 16.0 * 60.0

## [whose turn, the line said (a phrasebook id, world/barks.gd `line`; "" none), what the hands and the player do]
const STEPS := [
	[AGENT, "", "The agent from Litang takes your right hand inside his long sleeve and presses his price into it: three fingers, then two crossed. Not a word is said."],
	[BUYER, "PB-C02", "Yang Shouren feels the agent's price in your sleeve, shakes his head, and presses back a lower one."],  # Too dear. Come down a bit.
	[AGENT, "PB-T16", "The agent will come down, but not so far: his fingers in your sleeve again."],  # No.
	[BUYER, "PB-C04", "Yang comes up a little. Neither will name a price first; each waits for the other's hand."],  # That won't do.
	[AGENT, "PB-T31", "The agent presses the same fingers twice: his last word."],  # That's fine, it will do.
	[BUYER, "PB-C03", "A deal is made as deals are made here: three in a room, buyer, seller and host, and nobody opened a price first. The house stands guarantor, for its two to four per cent."],  # Agreed!
]

var stage := -1  ## -1 not begun; 0..STEPS.size() - 1 the next step's index; STEPS.size() done
var done := false
var choosing := false  ## the replies shown at Yang's first answer: 1 in the sleeve, 2 aloud
var spoken := false  ## the player named the agent's price aloud
var _named: Node
var _told := false


func _process(_dt: float) -> void:
	if done or not TownSim.walkers_on or not offered():
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var m := fposmod(WorldClock.minute, 1440.0)
	if stage < 0:
		if m < FROM or m > UNTIL or not _near(player, AGENT, 3.5):
			return
		stage = 0
		var host := _who(HOST)
		if host >= 0 and _dist(player, host) < 5.0:
			_say_line("PB-T10", 3.0)  # Stay slowly: said by the one leaving
			_narrate_later("Achak Dolkar must ride out to meet the caravan. She asks you to carry the last offers between her two rooms.", 1.2)
		else:
			_narrate("Achak Dolkar has ridden out to meet the caravan, leaving word that you would carry the last offers between her two rooms.")
	if stage >= STEPS.size():
		return
	if choosing:  # the replies on screen: their keys, not the next step's
		_prompt("1-2  answer")
		return
	var whose: String = STEPS[stage][0]
	var at := _near(player, whose, NEAR)
	_prompt("E  take the agent's offer" if at and whose == AGENT and stage == 0 else
			("E  give %s the offer" % ("the agent" if whose == AGENT else "Yang Shouren") if at else
			 ("Carry the offer across the yard to Yang Shouren, in the Chinese room" if whose == BUYER else "Take Yang Shouren's answer back to the agent, in the Tibetan room")))


## Whether the offers can be carried now: always without a story; in one, once Dolkar has asked it and until it is done.
func offered() -> bool:
	if not Story.flag("story"):
		return true
	var e := Story.entry("m3_price")
	return not e.is_empty() and not bool(e.get("done", false))


func _unhandled_input(e: InputEvent) -> void:
	if choosing and (e.is_action_pressed("answer_1") or e.is_action_pressed("answer_2")):  # 1 or 2, the D-pad's up or right
		choose(e.is_action_pressed("answer_2"))
		get_viewport().set_input_as_handled()
		return
	if stage < 0 or done or choosing or not e.is_action_pressed("use"):
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and int(player.get("rest")) == 0 and interact():
		get_viewport().set_input_as_handled()


## E by the one whose turn it is: the next step. True if one was taken.
func interact() -> bool:
	if stage < 0 or stage >= STEPS.size():
		return false
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var st: Array = STEPS[stage]
	if player == null or not _near(player, String(st[0]), NEAR):
		return false
	var who := _who(String(st[0]))
	_face(who, player)
	if stage == CHOICE_AT and Story.flag("story"):  # how the agent's price goes to Yang: the player's choice
		choosing = true
		_prompt("1-2  answer")
		_rep().call("show_replies", ["Press the agent's price into his sleeve, as it was given you.", "Tell him the agent's price aloud, to have it over with."])
		return true
	if String(st[1]) != "":
		_say_line(String(st[1]), 3.2)
		_narrate_later(String(st[2]), 3.3)
	else:
		_narrate(String(st[2]))
	if stage == 0:
		Codex.find("CX-048")  # the price pressed with the fingers inside the sleeve (autoload/codex.gd)
	stage += 1
	if stage >= STEPS.size():
		_finish()
	return true


## The player's choice at Yang's first answer: in the sleeve (the custom) or aloud (`aloud`).
func choose(aloud: bool) -> void:
	choosing = false
	_rep().call("hide_replies")
	spoken = aloud
	var st: Array = STEPS[stage]
	if aloud:
		_say_line(String(st[1]), 3.2)
		_narrate_later(SPOKEN, 3.3)
		Story.tell(BUYER, "price_spoken")
		Story.tell(AGENT, "price_spoken")
	else:
		_say_line(String(st[1]), 3.2)
		_narrate_later(String(st[2]), 3.3)
	stage += 1


func _finish() -> void:
	done = true
	_prompt("")
	Codex.find("CX-052")  # three in a room
	if not Story.flag("story"):
		return
	if spoken:  # the last narration says so; the house got less, and its hostess hears of it
		_narrate_later(SPOKEN_END, 6.6)
		Story.pass_on("price_spoken", [HOST], 60.0)
		Story.write("m3_told", "note", "The agent's tea went to Yang Shouren lower than it might have: I named the price aloud.", HOST, "Dechen-tsang's counting rooms")
	else:
		Story.pass_on("deal_in_the_sleeve", [HOST], 60.0)
		Story.write("m3_told", "note", "Carried the offers in the sleeve between the agent and Yang Shouren, and the deal was made. No price was spoken.", HOST, "Dechen-tsang's counting rooms")
	Story.done("m3_price")
	Story.set_flag("m3_done")


func _who(key: String) -> int:
	for i in TownSim.count:
		if String(TownSim.key[i]) == key:
			return i
	return -1


func _dist(player: Node3D, i: int) -> float:
	var p: Vector3 = TownSim.pos[i]
	return Vector2(p.x - player.global_position.x, p.z - player.global_position.z).length() + absf(p.y - player.global_position.y) * 0.5


## Whether the player stands within `reach` of the one called `key`, who is there (not walking, not away).
func _near(player: Node3D, key: String, reach: float) -> bool:
	var i := _who(key)
	return i >= 0 and int(TownSim.state[i]) != 0 and int(TownSim.state[i]) != 2 and _dist(player, i) < reach


## The one spoken to turns to the player for a few seconds (characters/named.gd's overrides); one seated keeps his way
## (a sitter turns about his feet, and Yang would swing through his writing table): his head turns (the attention).
func _face(i: int, player: Node3D) -> void:
	if i < 0 or TownSim.seated(i):
		return
	if _named == null:
		_named = get_tree().get_first_node_in_group("named")
		if _named == null:
			return
	var p: Vector3 = TownSim.pos[i]
	var to := player.global_position - p
	var ov: Dictionary = _named.get("overrides")
	ov[i] = {"pos": p, "yaw": atan2(to.x, to.z), "state": int(TownSim.state[i]), "speed": 0.0}
	await get_tree().create_timer(6.0).timeout
	if is_inside_tree():
		ov.erase(i)


func _subs() -> Node:
	var s := get_tree().get_first_node_in_group("subtitles")
	if s == null:
		s = Subtitles.new()
		get_tree().root.add_child(s)
	return s


## A phrasebook line, as checked (world/barks.gd `line`), in its script with the English under it.
func _say_line(id: String, seconds: float) -> void:
	var l := Barks.line(id)
	_subs().call("say_zh" if String(l["lang"]) == "zh" else "say", String(l["script"]), String(l["english"]), seconds)


func _narrate(english: String) -> void:
	_subs().call("narrate", english, 5.5)


func _narrate_later(english: String, after: float) -> void:
	await get_tree().create_timer(after).timeout
	if is_inside_tree():
		_narrate(english)


func _prompt(t: String) -> void:
	_subs().call("prompt", t)


func _rep() -> Node:
	var r := get_tree().get_first_node_in_group("replies")
	if r == null:
		r = Replies.new()
		get_tree().root.add_child(r)
	return r
