extends RefCounted
## The palette texture (plan chapter 11, 7.2): n_slots x 4 texels (128 since 25 Sep 2026), RGBA16F, linear, from
## data/palette.json's slots.
## Row 0 base colour; row 1 paint, streaks, fibers, pattern; row 2 gloss, rim, soft, ramp family (chapter 09, 4.2,
## since art step A2); row 3 the night colour of a slot that glows after dusk (r, g, b: paper windows and lanterns, since
## kit step K3) and the metal (a: chapter 09's table in 4.4, since art step A4: 0 none, 1 gold, 2 gold leaf, 3 brass,
## 4 copper, 5 iron, 6 silver).
## Missing parameters take the draft shader's defaults, so a slot looks as its by-name material did.
## Used at start-up (`PaletteTex.install()` sets the g_palette shader global).

const DEFAULTS := {"paint": 0.07, "streaks": 0.0, "fibers": 0.0, "pattern": 0.0, "gloss": 0.0, "rim": 0.12, "soft": 0.1}
const METALS := {"gold": 1, "gold_leaf": 2, "brass": 3, "copper": 4, "iron": 5, "silver": 6}


static func build(palette: Dictionary) -> ImageTexture:
	var img := Image.create(int(palette["n_slots"]), 4, false, Image.FORMAT_RGBAH)
	img.fill(Color(0, 0, 0, 0))
	for s in palette["slots"]:
		var i := int(s["id"])
		var p := DEFAULTS.duplicate()
		for k in DEFAULTS:
			if s.has(k):
				p[k] = float(s[k])
		img.set_pixel(i, 0, Color(s["c"]).srgb_to_linear())
		img.set_pixel(i, 1, Color(p["paint"], p["streaks"], p["fibers"], p["pattern"]))
		img.set_pixel(i, 2, Color(p["gloss"], p["rim"], p["soft"], float(s.get("ramp", 0))))
		# Row 3: the night colour of a slot that glows after dusk (paper windows, lanterns; kit step K3), and the metal.
		var night := Color(s["night_emission"]).srgb_to_linear() if s.has("night_emission") else Color(0, 0, 0)
		img.set_pixel(i, 3, Color(night.r, night.g, night.b, float(METALS.get(s.get("metal", ""), 0))))
	return ImageTexture.create_from_image(img)


static func install(path := "res://data/palette.json") -> ImageTexture:
	var tex := build(JSON.parse_string(FileAccess.get_file_as_string(path)))
	RenderingServer.global_shader_parameter_set("g_palette", tex)
	return tex
