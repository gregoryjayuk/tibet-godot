#!/usr/bin/env python3
"""The town houses to enter for Greg (sprint 8, step 7; world/interiors.gd, ../tibet-blender kit/houses.py
town_house(interior=True) and kit/rooms.py house_kitchen): H-SHL-007's door open at the top of its outside stair, and
its kitchen, and the other two households' kitchens, each furnished its own way, each household at home (ISS-105: the
grandmother at 007's hearth, the mother by 054's stove, the man on 004's bench); H-SHL-007's again at 18:00.
Stills: TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=house_007_door,house_007_in,house_054_in,house_004_in,house_007_dusk
Run: tools/py tools/town/houses_sheet.py   Writes tests/terrain/out/houses_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_house_007_door", "H-SHL-007 at 15:00: its door open at the top of the outside stair, the stove's fire inside"),
         ("s3_house_007_in", "Its kitchen: the grandmother on the bench; the clay stove, the churn, two pillars"),
         ("s3_house_054_in", "H-SHL-054's, by the Mani Lhakhang: the mother on the bench by the stove"),
         ("s3_house_004_in", "H-SHL-004's, east of the Sky Stair: the man of the house on the bench; the shrine shelf"),
         ("s3_house_007_dusk", "H-SHL-007's at 18:00: the fire, the last of the day, the grandmother still at the hearth")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Houses to enter (sprint 8, step 7): up the outside stair, over the sill, into the kitchen; each household at home.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "houses_sheet.jpg")
    img.save(path, quality=88)
    print("houses_sheet: %s" % path)


if __name__ == "__main__":
    main()
