#!/usr/bin/env python3
"""The north bank at the Serchu's mills (M2 sprint 12, step 5; chapter 02, D09: SER-05 to SER-11, SER-17, SER-18) on one
page: the four mills on their leat's cascade, the two water prayer wheels, the footbridge and the path up the south bank
to R-01, the Yak Road's first legs over the leat and up the flank, the barley terraces, the leat's weir.
Its stills (in a window, a few minutes; at 14:00):
  RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=mills_from_road,mills_row,mill_arch,mill_inside,wheel_house,footbridge,footbridge_side,yak_road_above,barley_terraces,leat_intake
Run: tools/py tools/town/mills_sheet.py   Writes tests/terrain/out/mills_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_mills_from_road", "From R-01 across the Serchu: the footbridge, the mills on their leat, the flank above"),
         ("s3_mills_row", "Along the leat walk past the upper mill, the row going down the bank"),
         ("s3_mill_arch", "Before SER-07's arch: its tail race, its wheel turning under the floor"),
         ("s3_mill_inside", "SER-08's door: the millstones, the hopper over them, the sacks of barley"),
         ("s3_wheel_house", "The lower water prayer wheel SER-09.1, the leat out of it to its race"),
         ("s3_footbridge", "The footbridge SER-11 from the north bank, the path zigzagging up the south bank"),
         ("s3_footbridge_side", "Its two logs on their cribs over the Serchu, from downstream"),
         ("s3_yak_road_above", "From high on the flank: the Yak Road's legs, the mills, the leat, the river and R-01"),
         ("s3_barley_terraces", "The monastery's barley terraces in stubble, hay piled on the benches"),
         ("s3_leat_intake", "The leat's head: the weir out across the river, the sluice board")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The north bank at the Serchu's mills (M2 sprint 12, step 5): the leat's cascade, the mills, the wheels, the footbridge, the Yak Road's foot.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "mills_sheet.jpg")
    img.save(path, quality=88)
    print("mills_sheet: %s" % path)


if __name__ == "__main__":
    main()
