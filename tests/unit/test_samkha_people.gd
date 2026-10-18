extends GutTest
## Who is there at Samkha (M2 sprint 4, step 6; world/samkha_people.gd, world/mule_string.gd): the toll steward's day,
## the gatekeeper's, the Pönpo's two times on his roof, the mastiffs' roof and ward, the day's crossings of the chain
## bridge (walked at the clock's minute, gone before and after), CV-02's mules and ponies over the lower bridge at
## 15:16, the deck feeling whoever crosses it, and the gatekeeper's answer at the barred gate.

const SamkhaPeople := preload("res://world/samkha_people.gd")
const MuleString := preload("res://world/mule_string.gd")
const ChainBridge := preload("res://world/chain_bridge.gd")
const CastleGate := preload("res://world/castle_gate.gd")
const Barks := preload("res://world/barks.gd")
const PEOPLE := "res://assets/generated/people/%s.glb"


func test_their_bodies_are_built() -> void:
	for k in ["sherab_steward", "castle_gatekeeper", "ponpo_tsewang", "mastiff", "mule", "pony"]:
		assert_true(ResourceLoader.exists(PEOPLE % k), "%s's body (people2/body.py, stand_ins.py)" % k)
	for c in SamkhaPeople.plan():
		assert_true(ResourceLoader.exists(PEOPLE % String(c["key"])), "the crossing at %d's body, %s" % [int(c["start"]), c["key"]])
	if ResourceLoader.exists(PEOPLE % "mastiff"):
		var d: Node = (load(PEOPLE % "mastiff") as PackedScene).instantiate()
		var ap: AnimationPlayer = d.find_children("*", "AnimationPlayer", true, false)[0]
		assert_true(ap.has_animation("Bark") and ap.has_animation("Sit") and ap.has_animation("Idle Alert"), "the mastiff barks, sits and stands alert")
		d.free()


func test_sherab_keeps_the_toll_table() -> void:
	var L := 60.0
	assert_eq(SamkhaPeople.sherab_doing(6.0 * 60.0, L), "home", "at home before dawn")
	assert_eq(SamkhaPeople.sherab_doing(6.0 * 60.0 + 24.0, L), "out", "over the bridge at 06:24")
	assert_eq(SamkhaPeople.sherab_doing(10.0 * 60.0, L), "table", "at his table at 10:00")
	assert_eq(SamkhaPeople.sherab_doing(15.0 * 60.0 + 10.0, L), "table", "counting the Dartsedo caravan at 15:10")
	assert_eq(SamkhaPeople.sherab_doing(16.0 * 60.0 + 48.0, L), "back", "taking the tally back at 16:48")
	assert_eq(SamkhaPeople.sherab_doing(18.0 * 60.0, L), "home", "gone home by 18:00")


func test_the_ponpo_and_the_gatekeeper_and_the_dogs() -> void:
	assert_eq(SamkhaPeople.ponpo_doing(6.0 * 60.0 + 50.0), ["roof", 108.0], "the Pönpo on his roof at 06:50 watching the road")
	assert_eq(SamkhaPeople.ponpo_doing(9.0 * 60.0), ["court", 180.0], "holding court at 09:00 (step 7)")
	assert_eq(SamkhaPeople.ponpo_doing(12.5 * 60.0)[0], "in", "within at half past twelve")
	assert_eq(SamkhaPeople.ponpo_doing(17.0 * 60.0 + 20.0), ["roof", 70.0], "on the roof for the horns, turned to the monastery")
	assert_eq(SamkhaPeople.gatekeeper_doing(5.0 * 60.0 + 27.0), "gate", "at the gate to draw the bar")
	assert_eq(SamkhaPeople.gatekeeper_doing(12.0 * 60.0), "bench", "on his bench at noon")
	assert_eq(SamkhaPeople.gatekeeper_doing(17.0 * 60.0 + 20.0), "gate", "at the gate from the horns")
	assert_eq(SamkhaPeople.gatekeeper_doing(19.0 * 60.0), "in", "within at night")
	assert_eq(SamkhaPeople.dogs_where(12.0 * 60.0), "roof", "the mastiffs on the roof by day")
	assert_eq(SamkhaPeople.dogs_where(22.0 * 60.0), "ward", "loose in the ward at night")


func test_the_crossings_walk_the_bridge_by_day() -> void:
	var L := 65.0
	var n := 0
	for c in SamkhaPeople.plan():
		var st := float(c["start"])
		assert_eq(SamkhaPeople.walker_s(st, st - 1.0, L), -1.0, "not yet out")
		assert_between(SamkhaPeople.walker_s(st, st + 4.0, L), 20.0, 45.0, "half way over four minutes on")
		assert_eq(SamkhaPeople.walker_s(st, st + 12.0, L), -1.0, "gone over")
		assert_lt(st + L / (SamkhaPeople.PER_MIN * SamkhaPeople.SPEED), CastleGate.SHUT_AT, "over before the gate shuts")
		if st >= 15.0 * 60.0 and st < 15.0 * 60.0 + 30.0:
			n += 1
	assert_gt(n, 0, "someone crosses at about 15:20, when the walker does (M2's acceptance 2)")


func test_the_mules_cross_the_lower_bridge_at_quarter_past_three() -> void:
	assert_almost_eq(MuleString.lead_s(MuleString.DECK_AT, 100.0), 100.0, 0.001, "the first mule on the lower deck at 15:16")
	assert_almost_eq(MuleString.lead_s(MuleString.DECK_AT + 2.0, 100.0), 114.0, 0.001, "14 m on two minutes later")
	assert_true(MuleString.shown(50.0, 40.0, 200.0), "in sight between the ramp and past the Yak Gate")
	assert_false(MuleString.shown(250.0, 40.0, 200.0), "gone into the town")
	assert_eq(MuleString.MULES + MuleString.PONIES, 9, "six pack mules and three ponies (chapter 06, 8.4)")


func test_the_deck_feels_the_crossings() -> void:
	var b := ChainBridge.new()
	add_child_autofree(b)
	b.p0 = Vector3(0.0, -500.0, 0.0)
	b.p1 = Vector3(0.0, -495.5, -48.0)
	b.length = 48.0
	var w := Node3D.new()
	add_child_autofree(w)
	w.add_to_group("deck_walkers")
	w.set_meta("walking", true)
	w.global_position = Vector3(0.0, -497.0, -24.0)
	b._physics_process(1.0 / 60.0)
	assert_eq(b.on_deck, 1, "a crossing on the deck is counted as a walker on it")
	w.global_position = Vector3(0.0, -497.0, 30.0)
	b._physics_process(1.0 / 60.0)
	assert_eq(b.on_deck, 0, "and not once off it")


func test_the_gatekeeper_answers_at_the_barred_gate() -> void:
	var l := Barks.line(CastleGate.ANSWER)
	assert_ne(String(l.get("script", "")), "", "PB-T60 in the slice's lines (tools/culture/barks.py)")
	assert_eq(String(l.get("english", "")), "The gate's already shut.", "its English")


func test_the_court_sits_cross_legged() -> void:
	for c in SamkhaPeople.COURT_PEOPLE + [["ponpo_tsewang", "", 0.0, 0.0]]:
		var path := PEOPLE % String(c[0])
		if not ResourceLoader.exists(path):
			fail_test("%s's body" % c[0])
			continue
		var n: Node = (load(path) as PackedScene).instantiate()
		var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
		assert_true(ap.has_animation("Sitting_Cross"), "%s sits cross-legged" % c[0])
		n.free()
	for c in SamkhaPeople.COURT_PEOPLE:
		assert_true(float(c[2]) >= SamkhaPeople.COURT[0] and float(c[3]) <= SamkhaPeople.COURT[1], "%s within the court's hours" % c[0])
