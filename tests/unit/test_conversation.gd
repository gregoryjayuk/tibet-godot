extends GutTest
## The conversation runner (M2 sprint 1, steps 2-4; plan chapter 11, 14.2): a person with a conversation at this hour
## can be talked to (E); its line is said, its replies offered as their conditions allow, a reply's effects reach the
## story (flags, what people know, the ledger), and the conversation ends; once its flag is set it is not offered again;
## the story's state goes into the save; the story's days count from Wednesday 28 October 1903.

const Conversation := preload("res://world/conversation.gd")
const PlayerScript := preload("res://player/player.gd")
const PATH := "user://test_conversation_streets.json"
const CROWD: Array[String] = ["townsman", "townswoman", "townsman_b", "townswoman_b", "monk"]
const TALK := {"id": "test", "who": "achak_dolkar", "if": [["not", "t_done"]], "start": "a",
	"nodes": {"a": {"say": "PB-T01", "replies": [
		{"en": "Give it here.", "do": [["flag", "t_done"], ["tell", "achak_dolkar", "letter"], ["witnesses", "seen", 8.0], ["write", "m_t", "note", "Gave it."]], "next": "b"},
		{"en": "Not yet.", "if": [["hour", 0, 24]], "next": "end"},
		{"en": "Never offered.", "if": [["flag", "nope"]], "next": "end"}]},
		"b": {"en": "Thank you.", "next": "end"}}}

var keep := {}
var runner: Node
var player: CharacterBody3D


func before_each() -> void:
	keep = {"minute": WorldClock.minute, "frozen": WorldClock.frozen, "story": Story.save_state()}
	WorldClock.frozen = true
	Story.reset()


func after_each() -> void:
	TownSim.walkers_on = false
	TownSim.running = false
	TownSim.count = 0
	WorldClock.minute = keep["minute"]
	WorldClock.frozen = keep["frozen"]
	Story.load_state(keep["story"])


## Dolkar standing at the made-up town's place (Godot's origin) from 10:00 to 15:00; the player 1.5 m south, facing her.
func _world() -> void:
	var data := {"pace": 1.1, "up": 0.75, "down": 0.5, "rate": 0.1,
		"anchors": {"home": [-20.0, 0.0, 2662.0], "tsongra": [0.0, 0.0, 2662.0]},
		"walkers": [{"kind": "achak_dolkar", "named": true, "pace": 1.0, "up": 0.8, "down": 0.5, "home": "home",
			"day": [["home", 0, 560, "inside", 0, null], ["tsongra", 600, 900, "stand", 0, {"name": "t", "at": [0.0, 0.0, 2662.0], "face": [0.0, -1.0], "pose": "stand"}], ["home", 960, 1440, "inside", 0, null]]}],
		"routes": {
			"home>tsongra": {"p": [-20.0, 0.0, 2662.0, 0.0, 0.0, 2662.0], "k": [0], "n": [0]},
			"tsongra>home": {"p": [0.0, 0.0, 2662.0, -20.0, 0.0, 2662.0], "k": [0], "n": [0]}}}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	TownSim.setup_walkers(PATH, CROWD)
	WorldClock.minute = Conversation.DAY1 + 700.0
	TownSim.step(0.0, Vector3.ZERO)
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 0.2, 20.0)
	cs.shape = box
	b.add_child(cs)
	add_child_autofree(b)
	b.global_position = TownSim.pos[0] + Vector3(0.0, -0.1, 0.0)
	player = PlayerScript.new()
	player.third_person = true
	add_child_autofree(player)
	player.global_position = TownSim.pos[0] + Vector3(0.0, 0.05, 1.5)
	player.facing = 0.0  # facing -Z, to her
	runner = Conversation.new()
	add_child_autofree(runner)
	runner.talks = [TALK.duplicate(true)]


func _key(k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	runner._unhandled_input(e)


func test_a_conversation_runs_and_changes_the_story() -> void:
	_world()
	await wait_physics_frames(4)
	assert_false(runner.candidate(player).is_empty(), "Dolkar can be talked to, 1.5 m off")
	_key(KEY_E)
	assert_false(runner.current.is_empty(), "E starts it")
	assert_true(bool(player.get("talking")), "the player stands while they talk")
	assert_true(Story.met("achak_dolkar"), "met")
	assert_eq(runner.said, ["a"], "her first line")
	var replies := get_tree().get_first_node_in_group("replies")
	assert_eq(replies.get("shown"), ["Give it here.", "Not yet."], "the replies their conditions allow")
	_key(KEY_1)
	assert_eq(runner.said, ["a", "b"], "the first reply's next line")
	assert_true(Story.flag("t_done"), "its flag")
	assert_true(Story.knows("achak_dolkar", "letter"), "what she knows now")
	assert_false(Story.entry("m_t").is_empty(), "written in the ledger")
	_key(KEY_E)
	assert_true(runner.current.is_empty(), "E after the last line ends it")
	assert_false(bool(player.get("talking")), "the player free again")
	assert_true(runner.candidate(player).is_empty(), "not offered again once its flag is set")


func test_the_story_is_saved() -> void:
	Story.set_flag("letter_given")
	Story.tell("yang_shouren", "letter_seen")
	Story.write("m1_letter", "mission", "Deliver the letter.")
	var d: Dictionary = JSON.parse_string(JSON.stringify(Save.snapshot()))
	Story.reset()
	Save.apply(d)
	assert_true(Story.flag("letter_given"), "its flags")
	assert_true(Story.knows("yang_shouren", "letter_seen"), "what people know")
	assert_eq(String(Story.entry("m1_letter").get("text", "")), "Deliver the letter.", "the ledger")


func test_word_passes_on() -> void:
	WorldClock.minute = 20000.0
	Story.pass_on("letter_seen", ["yang_shouren", "achak_dolkar"], 60.0)
	Story._process(0.0)
	assert_false(Story.knows("yang_shouren", "letter_seen"), "not yet")
	WorldClock.minute += 61.0
	Story._process(0.0)
	assert_true(Story.knows("yang_shouren", "letter_seen") and Story.knows("achak_dolkar", "letter_seen"), "told on, an hour later")


func test_the_story_s_days() -> void:
	assert_eq(Conversation.day_of(Conversation.DAY1), 1, "Wednesday 28 October 1903 is day 1")
	assert_eq(Conversation.day_of(Conversation.DAY1 + 1440.0 + 10.0), 2, "Thursday, day 2")
	assert_eq(Conversation.day_of(WorldClock.DEFAULT_MINUTE), 1, "the default day's 14:00 is on day 1")
