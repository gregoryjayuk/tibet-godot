extends RefCounted
## The stars for the sky shader (art step A6): data/stars.json (tools/sky/stars.py, the Yale Bright Star Catalogue to
## V 5.5, equinox B1900) laid into a grid of 0.25 deg cells of right ascension and declination, 1440 x 720 RGBA8: each
## cell holds its brightest star as its place within the cell (r, g), its brightness (b, from the magnitude) and its
## colour (a, from B-V). The sky shader looks at the cells round each pixel and draws the stars as points, so they stay
## sharp at any screen size and turn with the sidereal time. A few faint stars that share a cell with a brighter one
## are left out (the tool reports how many).

const CELL := 0.25  ## degrees
const W := 1440
const H := 720


static func texture(path := "res://data/stars.json") -> ImageTexture:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var taken := 0
	for s in data["stars"]:  # brightest first, so a cell keeps its brightest star
		var ra: float = s[0]
		var dec: float = s[1]
		var x := int(floorf(ra / CELL)) % W
		var y := clampi(int(floorf((dec + 90.0) / CELL)), 0, H - 1)
		if img.get_pixel(x, y).b > 0.0:
			taken += 1
			continue
		var fx := ra / CELL - floorf(ra / CELL)
		var fy := (dec + 90.0) / CELL - floorf((dec + 90.0) / CELL)
		# Brightness from the magnitude: 1 for the brightest (V -1.5 and brighter), towards 0.1 at the limit, V 5.5.
		var b := clampf(pow(10.0, -0.4 * (float(s[2]) + 1.5)) , 0.0, 1.0)
		b = clampf(0.1 + 0.9 * pow(b, 0.35), 0.0, 1.0)
		var bv := clampf((float(s[3]) + 0.4) / 2.4, 0.0, 1.0)  # B-V -0.4 (blue) to 2.0 (red)
		img.set_pixel(x, y, Color(fx, fy, b, bv))
	if taken > 0:
		print("stars: %d faint stars share a cell with a brighter one and are left out" % taken)
	return ImageTexture.create_from_image(img)
