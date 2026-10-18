extends GutTest
## The headman's household on chapter 04's day (M2 sprint 7, step 4; plan chapter 04, 4.1): the mistress, Pema, the
## younger son, the grandmother, the elder grandchild, the steward, the groom and the kitchen girl at home in SHL-19, the
## reader from Dungkar Gönpa from ten to three, a Hejie trader at three, Sönam Wangyal among them at meals; each walked
## into the house's rooms by its own ground (tools/town/graph.py headman_way); the beasts in their stalls
## (interiors/beasts.gd).

const GRAPH := "res://assets/generated/terrain/street_graph.json"
const HOUSEHOLD := ["yangchen_drolma", "pema_wife", "younger_son", "headman_grandmother", "headman_grandchild",
		"headman_steward", "headman_groom", "headman_kitchen_girl"]


func _walkers() -> Dictionary:
	if not FileAccess.file_exists(GRAPH):
		return {}
	var out := {}
	for w in (JSON.parse_string(FileAccess.get_file_as_string(GRAPH)) as Dictionary)["walkers"]:
		out[String(w.get("who", ""))] = w
	return out


## The stop of walker w whose seat's name has `part`, at game minute m (or any if m < 0).
func _stop(w: Dictionary, part: String, m := -1.0) -> Array:
	for st in w["day"]:
		var seat = st[5]
		if seat is Dictionary and String(seat["name"]).contains(part) and (m < 0.0 or (float(st[1]) <= m and m <= float(st[2]))):
			return st
	return []


func test_the_household_at_home() -> void:
	var ws := _walkers()
	if ws.is_empty():
		pending("no street graph: tools/py tools/town/graph.py")
		return
	for who in HOUSEHOLD:
		assert_true(ws.has(who), "%s walks the town" % who)
		if ws.has(who):
			assert_eq(String(ws[who]["home"]), "headman", "%s lives in the headman's house" % who)
	# chapter 04's table: supper by the stove at 18:30, the family on the bench and the servants on the floor
	for who in ["sonam_wangyal", "yangchen_drolma", "younger_son", "headman_grandmother"]:
		if ws.has(who):
			var st := _stop(ws[who], "headman_kitchen:seat", 1110.0)
			assert_false(st.is_empty(), "%s on the kitchen's bench at supper" % who)
	for who in ["headman_steward", "headman_groom", "headman_kitchen_girl"]:
		if ws.has(who):
			var st := _stop(ws[who], "headman_kitchen:spot", 1110.0)
			assert_false(st.is_empty() or String(st[3]) != "cross", "%s on the floor at the other end at supper" % who)


func test_the_good_day_made_visible() -> void:
	var ws := _walkers()
	if ws.is_empty():
		pending("no street graph")
		return
	var reader := _stop(ws.get("tashi_phuntsok", {"day": []}), "headman_shrine:seat:1", 720.0)
	assert_false(reader.is_empty(), "the reader in the shrine room at noon (10:00-15:00)")
	var gm := _stop(ws.get("headman_grandmother", {"day": []}), "headman_shrine:seat:2", 840.0)
	assert_false(gm.is_empty(), "the grandmother by the shrine room's door with her rosary")
	var tea := 0
	for st in ws.get("headman_kitchen_girl", {"day": []})["day"]:
		if st[5] is Dictionary and String(st[5]["name"]).contains("headman_shrine"):
			tea += 1
	assert_gte(tea, 4, "the kitchen girl brings him tea through the day")
	var juniper := _stop(ws.get("yangchen_drolma", {"day": []}), "hroof:", 1040.0)
	assert_false(juniper.is_empty(), "the mistress at the roof's burner at 17:15")
	var trader := _stop(ws.get("hejie_trader", {"day": []}), "headman_reception:seat", 950.0)
	assert_false(trader.is_empty(), "the Hejie trader on a Han stool in the reception room at three")


func test_their_ways_in() -> void:
	var ws := _walkers()
	if ws.is_empty():
		pending("no street graph")
		return
	var st := _stop(ws.get("pema_wife", {"day": []}), "headman_roofroom", 960.0)
	assert_false(st.is_empty(), "Pema at her loom in the roof room")
	var via: Array = (st[5] as Dictionary)["via"]
	var hidden := 0
	var top := -INF
	for q in via:
		top = maxf(top, float(q[2]))
		if (q as Array).size() > 3 and String(q[3]) == "in":
			hidden += 1
	assert_eq(hidden, 1, "up the hatch's log out of sight")
	assert_gt(top - 2655.0, 8.0, "to the roof's height")


func test_the_beasts_in_their_stalls() -> void:
	var path := "res://interiors/headman/headman_stable.tscn"
	if not ResourceLoader.exists(path):
		pending("no stable scene")
		return
	var sc: Node3D = (load(path) as PackedScene).instantiate()
	add_child_autofree(sc)
	var b := sc.get_node("Beasts")
	await wait_frames(10)  # (they stand when the stalls are there: the Streamer adds a room over a few frames)
	var figs: Array = b.get("figures")
	assert_eq(figs.size(), 5, "two mules, the pony, the dzo and the cow (chapter 04)")
	for f in figs:
		var r: Node3D = f[0]
		var at: Vector3 = sc.to_local(r.global_position)
		assert_lt(-at.z, 1.5, "%s at a stall along the south wall" % r.name)
