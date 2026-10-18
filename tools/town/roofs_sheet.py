#!/usr/bin/env python3
"""The shut and the left houses' roofs for Greg (IMP-019; world/households.gd, shaders/stylized_static.gdshader): an earth
roof no one beats and mends grows grass, in patches, the more the longer its household has been gone; a lived-in roof
beside them for comparison.
Stills: RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=roof_H-SHL-077,roof_H-SHL-072,roof_H-SHL-058,roof_H-SHL-064,roof_H-SHL-079,roof_H-SHL-109
   (DOORS_LOG=1 marks each house (left) or (shut) in tests/out/last_run.log.)
Run: tools/py tools/town/roofs_sheet.py   Writes tests/terrain/out/roofs_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("H-SHL-077", "Left for good, on the Rooftop Way: grass over its roof, its flags bare poles"),
         ("H-SHL-072", "Left: grass, the log storey's red faded"),
         ("H-SHL-058", "Left"),
         ("H-SHL-064", "Shut, its household away since before Losar: a little grass"),
         ("H-SHL-079", "Lived in: its roof beaten and mended"),
         ("H-SHL-109", "Left")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The shut and the left houses' roofs (IMP-019): 17 of the 104 shut, 5 of them left for good.", font=FONT, fill=(40, 30, 25))
    for i, (house, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 56 + (i // 2) * (h + cap + pad)
        path = os.path.join(OUT, "s3_roof_%s.png" % house)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), "%s: %s" % (house, label), font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "roofs_sheet.jpg")
    img.save(path, quality=88)
    print("roofs_sheet: %s" % path)


if __name__ == "__main__":
    main()
