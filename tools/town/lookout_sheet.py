#!/usr/bin/env python3
"""The garden lane and the Gorge Rim Lookout (M2 sprint 6, step 4; plan chapter 02, SHL-32 and SHL-33; chapter 08, V-13a:
"up through the walled gardens of upper Shöl along a lane between garden walls 2.5 m high, which hides everything; the
terrace opens on the gorge rim"): the lane's foot at H-SHL-095's yard, the lane between its walls, the orchards from
above, the lane's end opening on the terrace, the terrace facing the notch, the old woman's juniper at dusk.
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=lookout_ramp,lookout_lane,gardens_above,lookout_arrive,lookout_terrace,lookout_dusk
Run: tools/py tools/town/lookout_sheet.py   Writes tests/terrain/out/lookout_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_lookout_ramp", "The lane's foot at H-SHL-095's yard, up the shoulder between its walls"),
         ("s3_lookout_lane", "Along the contour between the garden walls, 2.5 m high: the orchards' crowns over them"),
         ("s3_gardens_above", "The lane and its twelve walled plots of walnut, apple and pear from the slope above"),
         ("s3_lookout_arrive", "The lane's end: the terrace opens on the gorge's rim"),
         ("s3_lookout_terrace", "V-13a's place at the parapet, facing 040, the burner and the pole"),
         ("s3_lookout_dusk", "17:06: the old woman of upper Shöl's juniper on the burner")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The garden lane and the Gorge Rim Lookout (M2 sprint 6, step 4): upper Shöl's walled orchards, the terrace on the rim.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "lookout_sheet.jpg")
    img.save(path, quality=88)
    print("lookout_sheet: %s" % path)


if __name__ == "__main__":
    main()
