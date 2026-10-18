#!/usr/bin/env python3
"""The town's windows at night for Greg (ISS-039; shaders/stylized_static.gdshader): left, every paper window lit alike as
the town's lamps were (--off=households); right, each household's own lamps: lit at its own minute of the evening and put
out at its own bedtime, a few before dawn, only on the storeys it lives in (never the stable), none in a shut house.
Stills: TIMEOUT=700 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=v28_dusk,v28_night,v28_late,hearths_dusk
and the same again with --off=households.
Run: tools/py tools/town/night_windows_sheet.py   Writes tests/terrain/out/night_windows_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_hearths_dusk", "17:25 over lower Shöl: the kitchens' floors lit, the rooms above now and then, no stable"),
         ("s3_v28_dusk", "V-28 at 17:07, the lamps coming on house by house"),
         ("s3_v28_night", "19:00"),
         ("s3_v28_late", "21:00: each household's lamps out at its own bedtime")]


def main():
    w, h, pad, cap = 800, 450, 10, 30
    img = Image.new("RGB", (pad + 2 * (w + pad), 84 + len(SHOTS) * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The windows at night (ISS-039): left, every paper window lit alike; right, each household's own lamps,", font=FONT, fill=(40, 30, 25))
    d.text((pad, 42), "lit at its own minute, out at its own bedtime, on the storeys it lives in; none in a shut house.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        y = 84 + i * (h + cap + pad)
        for j, suffix in enumerate(("_off-households", "")):
            img.paste(Image.open(os.path.join(OUT, name + suffix + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (pad + j * (w + pad), y))
        d.text((pad, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "night_windows_sheet.jpg")
    img.save(path, quality=88)
    print("night_windows_sheet: %s" % path)


if __name__ == "__main__":
    main()
