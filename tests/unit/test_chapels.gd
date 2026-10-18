extends GutTest
## Dungkar Gönpa whole, step 3 (M3 sprint 3; tools/town/monastery.py LEVEL, FORECOURT; ../tibet-blender kit/monastery.py
## lhakhang; world/gonkhang.gd): the Jampa Lhakhang MON-04, the reliquary chapel MON-15 and the Gönkhang MON-05 whole, at
## levels that bring their doors to the slope before them; the Maitreya's two windows on its face, the chapels' ground
## floors dark, the Gönkhang closed but for two small windows above; its drum heard through the rite and at night.

const Gonkhang := preload("res://world/gonkhang.gd")
const MONASTERY := "res://data/monastery.json"
const SIDE := "res://assets/generated/kit/types/%s.json"
const KIT := "res://assets/generated/kit/types/%s.glb"


func _json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))


## The kit's windows: [x, y, z] of each WIN socket (the opening's middle, the kit's frame: front -y, floor at z 0).
func _wins(kit: String) -> Array:
	var out: Array = []
	var pos: Dictionary = _json(SIDE % kit)["socket_pos"]
	for k in pos:
		if String(k).begins_with("SOCK_WIN_"):
			out.append(pos[k])
	return out


func test_the_chapels_whole() -> void:
	if not FileAccess.file_exists(MONASTERY):
		pending("no data/monastery.json")
		return
	var pads: Dictionary = _json(MONASTERY)["pads"]
	for spec in [["MON-04", "mon04_maitreya_chapel_in_v1", 2945.0, 1.0], ["MON-15", "mon15_reliquary_chapel_v1", 2962.0, 0.5], ["MON-05", "mon05_protector_chapel_in_v1", 2930.0, 0.0]]:
		var pd: Dictionary = pads[spec[0]]
		assert_eq(String(pd["kit"]), spec[1], "%s its own kit" % spec[0])
		assert_true(ResourceLoader.exists(KIT % spec[1]), "%s exported and imported" % spec[1])
		assert_almost_eq(float(pd["level"]), float(spec[2]), 0.01, "%s's floor near the ground before its door" % spec[0])
		assert_almost_eq(float(pd.get("yard", 0.0)), float(spec[3]), 0.01, "%s's landing levelled with it" % spec[0])


func test_the_maitreyas_face() -> void:
	if not FileAccess.file_exists(SIDE % "mon04_maitreya_chapel_v1"):
		pending("no mon04_maitreya_chapel_v1 (export_types.py)")
		return
	var on_face := 0
	for w in _wins("mon04_maitreya_chapel_v1"):
		assert_gt(float(w[2]), 4.5, "no window in its dark ground floor (%s)" % [w])
		if float(w[1]) < -5.5 and absf(float(w[0])) < 2.0 and float(w[2]) > 5.5 and float(w[2]) < 7.9:
			on_face += 1
	assert_eq(on_face, 2, "two O4 windows high on the south face, centred on the Maitreya's face (chapter 03, 6.3)")
	var used: String = JSON.stringify(_json(SIDE % "mon04_maitreya_chapel_v1")["slots_used"])
	assert_true(used.contains("gold_tiles"), "its gilded roof")


func test_the_gonkhang_closed() -> void:
	if not FileAccess.file_exists(SIDE % "mon05_protector_chapel_v1"):
		pending("no mon05_protector_chapel_v1 (export_types.py)")
		return
	var wins := _wins("mon05_protector_chapel_v1")
	assert_eq(wins.size(), 2, "two small windows, the mask store's (chapter 03, 6.4)")
	for w in wins:
		assert_gt(float(w[2]), 3.8, "none on its ground floor")
		assert_lt(float(w[1]), -3.5, "on its front")
	var used: String = JSON.stringify(_json(SIDE % "mon05_protector_chapel_v1")["slots_used"])
	assert_true(used.contains("mural_black"), "its porch painted on black ground")
	assert_true(used.contains("yak_curtain"), "its black yak-hair curtain and banners")
	for w in _wins("mon15_reliquary_chapel_v1"):
		assert_gt(float(w[2]), 4.8 + 1.5, "the reliquary chapel's few windows high in its upper storey")


func test_the_drum() -> void:
	assert_eq(Gonkhang.level(990.0), 0.0, "16:30, the protector rite: the drum full at the door")
	assert_eq(Gonkhang.level(1200.0), INF, "20:00 silent")
	assert_eq(Gonkhang.level(1300.0), Gonkhang.NIGHT_DB, "21:40 the night's drum, quieter")
	assert_eq(Gonkhang.level(200.0), Gonkhang.NIGHT_DB, "03:20 still")
	assert_eq(Gonkhang.level(300.0), INF, "05:00 silent: the day's services elsewhere")
	assert_eq(Gonkhang.level(720.0), INF, "noon silent")
