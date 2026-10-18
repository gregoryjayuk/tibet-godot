#!/usr/bin/env python3
"""The hearths' smoke for Greg (sprint 8, step 2; world/hearths.gd): one view up the slope over the Sky Stair at three
hours of the same day: the morning fires, the midday meal (two houses in three), the evening meal with the sang.
Stills: TIMEOUT=400 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=hearths_close,hearths_noon,hearths_dusk
Run: tools/py tools/town/hearths_sheet.py   Writes tests/terrain/out/hearths_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_hearths_close", "07:40: the morning fires, every household's"),
         ("s3_hearths_noon", "12:15: the midday meal in two houses of three"),
         ("s3_hearths_dusk", "17:25: the evening meal's fires lit one by one, the sang on the roofs")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    img = Image.new("RGB", (pad + w + pad, 56 + len(SHOTS) * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The hearths' smoke (sprint 8, step 2): up the slope over the Sky Stair, one day.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        y = 56 + i * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (pad, y))
        d.text((pad, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "hearths_sheet.jpg")
    img.save(path, quality=88)
    print("hearths_sheet: %s" % path)


if __name__ == "__main__":
    main()
