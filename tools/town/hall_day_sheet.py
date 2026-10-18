#!/usr/bin/env python3
"""The Tsokchen's day and V-26 for Greg (M3 sprint 6, step 3; plan chapter 08, V-26; chapter 04, 3.1 and 3.8): the full-moon
assembly from the lay visitors' place inside the door, the tea pass down the rows, the incense haze and the lantern's
shaft, the sweepers, a lay visitor's prostrations, the great door shut at night, the tulku's audience in the Labrang.
Stills: RETURN_FOCUS=0 TIMEOUT=700 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=v26_door,v26_rows,v26_shafts,tsokchen_sweepers,tsokchen_pilgrim,tsokchen_shut,labrang_audience
Run: tools/py tools/town/hall_day_sheet.py   Writes tests/terrain/out/hall_day_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT_F = os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")
SHOTS = [("s3_v26_door.png", "V-26, 5 November (the 15th) at 10:15: the morning assembly from inside the door, the tulku on his throne"),
         ("s3_v26_shafts.png", "10:15: up the aisle into the incense haze, the lantern's shaft through it"),
         ("s3_v26_rows.png", "10:07: across the rows from the east aisle: a novice's kettle, the disciplinarian by the door"),
         ("s3_tsokchen_sweepers.png", "08:00: a sweeper down the aisle (the sacristan at the lamps beyond)"),
         ("s3_tsokchen_pilgrim.png", "12:00: a lay visitor's prostrations inside the door, before the Nangkor"),
         ("s3_tsokchen_shut.png", "20:00: the great door shut from 19:00, from the porch"),
         ("s3_labrang_audience.png", "11:03: the Labrang's reception: the tulku, his tutor, a petitioner kneeling")]


def main():
    w, h, cap, pad = 900, 506, 34, 10
    f = ImageFont.truetype(FONT_F, 20)
    big = ImageFont.truetype(FONT_F, 26)
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 60 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 16), "The Tsokchen's day and V-26, the full-moon assembly (M3 sprint 6, step 3)", font=big, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 60 + (i // 2) * (h + cap + pad)
        path = os.path.join(OUT, name)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 5), label, font=f, fill=(40, 30, 25))
    path = os.path.join(OUT, "hall_day_sheet.jpg")
    img.save(path, quality=86)
    print("hall_day_sheet: %s" % path)


if __name__ == "__main__":
    main()
