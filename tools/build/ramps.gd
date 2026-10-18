extends RefCounted
## The ramp atlas (plan chapter 09, 4.2; art step A2): 256 x 32 texels, one row per ramp family and time set
## (family * 4 + set: day, golden, blue hour, night), built at start-up from data/ramps.json and installed as the
## g_ramps shader global. A lit shader looks up its light with x = N.L * 0.5 + 0.5 + the painted shadow bias.
## Each texel is the light's multiplier on that side of the form: its bands, and the warm band at the terminator.

const W := 256
const H := 32


static func _level(fam: Dictionary, st: Dictionary, ndl: float) -> float:
	var th: Array = fam["thresholds"]
	var lv: Array = fam["levels"]
	var soft: float = float(fam["soft"]) * float(st["soft"])
	var x := ndl
	if fam.get("wrap", false):
		x = pow(ndl * 0.5 + 0.5, 2.0)  # R5 foliage: wrapped light
	var v: float = lv[0]
	for k in th.size():
		var t := smoothstep(float(th[k]) - soft * 0.5, float(th[k]) + soft * 0.5, x)
		v = lerpf(v, float(lv[k + 1]), t)
	return maxf(v, float(st["floor"]))


static func build(path := "res://data/ramps.json") -> ImageTexture:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var img := Image.create(W, H, false, Image.FORMAT_RGBAH)
	img.fill(Color(1, 1, 1, 1))
	var fams: Array = spec["families"]
	var sets: Array = spec["sets"]
	for f in fams.size():
		var fam: Dictionary = fams[f]
		var band: Dictionary = fam["band"]
		for s in sets.size():
			var st: Dictionary = sets[s]
			var bc := Color(band["c"] if st["band_c"] == null else st["band_c"]).srgb_to_linear()
			var peak := maxf(bc.r, maxf(bc.g, bc.b))
			var tint := Color(bc.r / peak, bc.g / peak, bc.b / peak)  # the band tints without darkening
			var bw: float = float(band["width"]) * float(st["band_width"])
			var bs: float = float(band["strength"]) * float(st["band_strength"])
			var t0: float = float((fam["thresholds"] as Array)[0])
			for i in W:
				var ndl := (float(i) + 0.5) / W * 2.0 - 1.0
				var lv := _level(fam, st, ndl)
				var b := 0.0
				if bw > 0.0:
					b = (1.0 - smoothstep(0.0, bw, absf(ndl - (t0 + bw * 0.5)))) * bs
				var c := Color(lv, lv, lv).lerp(Color(lv * tint.r, lv * tint.g, lv * tint.b), clampf(b, 0.0, 1.0))
				# The band also lifts the terminator a little, so the edge between light and shade glows.
				c = c + Color(tint.r, tint.g, tint.b) * b * 0.25
				img.set_pixel(i, f * 4 + s, Color(c.r, c.g, c.b, 1.0))
	return ImageTexture.create_from_image(img)


static func install(path := "res://data/ramps.json") -> ImageTexture:
	var tex := build(path)
	RenderingServer.global_shader_parameter_set("g_ramps", tex)
	return tex
