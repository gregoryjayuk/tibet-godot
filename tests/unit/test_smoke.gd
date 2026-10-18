extends GutTest
## Smoke tests, headless (roadmap RT-05): the data files load, the quality tiers do the right sums, the clock freezes,
## the regression shot set parses, and the fonts have the glyphs they are there for.
## Run: Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit

const Vignette := preload("res://world/vignette.gd")


func test_palette_loads() -> void:
	var p = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette.json"))
	assert_eq(typeof(p), TYPE_DICTIONARY, "palette.json parses")
	assert_eq(p["n_slots"], 128.0, "128 palette slots available (64 until 25 Sep 2026)")
	assert_true(p["slots"].size() <= 128, "no more slots used than available")
	for i in p["slots"].size():
		assert_eq(int(p["slots"][i]["id"]), i, "slot ids run 0..n-1")
		assert_true(Color.html_is_valid(p["slots"][i]["c"]), "colour of slot " + p["slots"][i]["name"])
	for name in ["whitewash", "red_plaster", "gold", "black_paint", "terrain", "mountain", "skin"]:
		assert_true(p["materials"].has(name), "the draft's material " + name + " is still looked up by name")
	assert_eq(p["flags"].size(), 5, "5 flag colours")


func test_quality_tiers_are_complete() -> void:
	for tier in Quality.TIERS:
		var t: Dictionary = Quality.TIERS[tier]
		assert_true(t.has("fps") and t.has("mpx"), tier + " has fps and mpx")
	assert_almost_eq(float(Quality.TIERS["QT-BAL"]["mpx"]), 2.1, 0.001, "default is 1080p (Greg, 25 Sep 2026)")


func test_quality_scales_a_4k_viewport() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(3840, 2160)
	add_child_autofree(vp)
	var before := Quality.tier
	Quality.tier = "QT-BAL"
	Quality.fit_3d(vp)
	assert_almost_eq(vp.scaling_3d_scale, sqrt(2.1e6 / (3840.0 * 2160.0)), 0.001, "1080p worth of pixels on a 4K output")
	Quality.tier = "QT-NATIVE"
	Quality.fit_3d(vp)
	assert_eq(vp.scaling_3d_scale, 1.0, "native renders every pixel")
	Quality.tier = before


func test_world_clock_freezes() -> void:
	WorldClock.freeze(20.0)
	await wait_process_frames(3)
	assert_eq(WorldClock.anim_time, 20.0, "frozen time does not move")
	WorldClock.frozen = false


func test_shot_set_parses() -> void:
	var cfg = JSON.parse_string(FileAccess.get_file_as_string("res://tests/shots/draft/set.json"))
	assert_eq(typeof(cfg), TYPE_DICTIONARY)
	assert_eq(cfg["shots"].size(), 5, "five draft viewpoints")
	assert_eq(cfg["size"], [1600.0, 900.0], "JSON numbers arrive as floats")


func test_views_and_axes() -> void:
	assert_eq(Vignette.VIEWS.size(), 5)
	assert_eq(Vignette.b2g(Vector3(1, 2, 3)), Vector3(1, 3, -2), "Blender z-up to Godot y-up")


func test_fonts_have_their_scripts() -> void:
	var cases := {
		"res://assets/source/fonts/jomolhari/Jomolhari-Regular.ttf": [0x0F40, 0x0F90, 0x0F7C],  # ཀ, subjoined ka, vowel o
		"res://assets/source/fonts/noto-serif-tibetan/NotoSerifTibetan[wght].ttf": [0x0F40, 0x0F90, 0x0F7C],
		"res://assets/source/fonts/noto-serif-tc/NotoSerifTC-Regular.otf": [0x92C5, 0x838A, 0x8336],  # 鍋 莊 茶
		"res://assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf": [0x0041, 0x00E4, 0x0101],  # A ä ā
	}
	for path in cases:
		var f := FontFile.new()
		assert_eq(f.load_dynamic_font(path), OK, "loads " + path.get_file())
		for c in cases[path]:
			assert_true(f.has_char(c), "%s has U+%04X" % [path.get_file(), c])


## The game's Chinese face (Greg's pick, 25 Sep): face 2 of the collection, AR PL UKai TW.
func test_the_chinese_face() -> void:
	var f := FontFile.new()
	assert_eq(f.load_dynamic_font("res://assets/source/fonts/ar-pl-ukai/ukai.ttc"), OK, "loads ukai.ttc")
	assert_eq(f.get_face_count(), 4, "CN, HK, TW and TW MBE")
	f.set_face_index(0, 2)
	for c in [0x92C5, 0x838A, 0x8336, 0x5149, 0x7DD2]:  # 鍋 莊 茶 光 緒
		assert_true(f.has_char(c), "UKai TW has U+%04X" % c)
