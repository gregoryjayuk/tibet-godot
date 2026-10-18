#!/usr/bin/env python3
"""V-28's dusk for Greg (sprint 4, step 6; plan chapter 08, V-28): the view from the Rooftop Way's last roof over Shöl at
17:07, every roof's sang burner sending up its thread of juniper smoke, and at 17:40, the half moon high over the town
(44.5 degrees up at 172, where the Calendar puts it), the first windows lit; and at 19:00, night.
Stills: RETURN_FOCUS=0 TIMEOUT=300 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=v28_dusk,v28_moon,v28_night
Run: tools/py tools/town/dusk_sheet.py   Writes tests/terrain/out/dusk_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_v28_dusk", "17:07: the sang, a thread of juniper smoke from every roof burner"),
         ("s3_v28_moon", "17:40: the half moon 44.5 degrees up at 172, over the town, in the blue hour"),
         ("s3_v28_night", "19:00: night since 18:35, the lamps in the windows")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    img = Image.new("RGB", (pad + len(SHOTS) * (w + pad), 56 + h + cap + pad), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "V-28, evening on the roofs (sprint 4, step 6): from the top of the Rooftop Way over Shöl, looking south.",
           font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + i * (w + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, 56))
        d.text((x, 56 + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "dusk_sheet.jpg")
    img.save(path, quality=88)
    print("dusk_sheet: %s" % path)


if __name__ == "__main__":
    main()
