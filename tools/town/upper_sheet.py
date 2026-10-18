#!/usr/bin/env python3
"""The upper town's log houses, each its own form, for Greg (IMP-019, second cut; ../tibet-blender kit/timber.py and
tools/town/builder.py): nine variants of each log house where there were three, their windows drawn per house (how many
on each wall, flower, wide or plain), galleries and threshing on the new ones' roofs, and each household's colours.
Stills: RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=upper_row,upper_over,v28_dusk,slice_v14
Run: tools/py tools/town/upper_sheet.py   Writes tests/terrain/out/upper_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_upper_row", "Along the Rooftop Way's row: a fresh red house, a grey one long left, faded ones beyond"),
         ("s3_upper_over", "Over the upper town: galleries, grain drying on the roofs, the windows each house's own"),
         ("s3_v28_dusk", "From V-28 at 17:07: its neighbours' roofs and windows no longer the same three houses"),
         ("s3_slice_v14", "The top of the Sky Stair: the log houses of the lower rows of upper Shöl")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The upper town's log houses, each its own form (IMP-019): 34 kit variants for 55 houses where 12 were.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 56 + (i // 2) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "upper_sheet.jpg")
    img.save(path, quality=88)
    print("upper_sheet: %s" % path)


if __name__ == "__main__":
    main()
