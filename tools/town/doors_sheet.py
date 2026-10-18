#!/usr/bin/env python3
"""The door dressing for Greg (IMP-019; world/door_dressing.gd, ../tibet-blender kit/dressing.py): six doors of the upper
town as their households dressed them, each 4.2 m before its door.
Stills: RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=door_H-SHL-079,door_H-SHL-061,door_H-SHL-088,door_H-SHL-064,door_H-SHL-067,door_H-SHL-068
   (DOORS_LOG=1 lists every door's things in tests/out/last_run.log.)
Run: tools/py tools/town/doors_sheet.py   Writes tests/terrain/out/doors_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("H-SHL-079", "A painted yak skull over the lintel, a thread cross, Losar's dots and swastika"),
         ("H-SHL-061", "A Bön household: its swastika turns left; a thread cross"),
         ("H-SHL-088", "A yak skull, mani stones at the step, a Bön household's marks"),
         ("H-SHL-064", "Shut, its household away: the door barred and padlocked; a thread cross, mani stones"),
         ("H-SHL-067", "A skull with cloth tied to its horns, Losar's marks"),
         ("H-SHL-068", "A thread cross, mani stones, Losar's marks")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Each household's door (IMP-019): 85 of the town's 104 doors dressed, each its own; the 19 shut ones barred.", font=FONT, fill=(40, 30, 25))
    for i, (house, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 56 + (i // 2) * (h + cap + pad)
        path = os.path.join(OUT, "s3_door_%s.png" % house)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").crop((240, 135, 1680, 945)).resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), "%s: %s" % (house, label), font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "doors_sheet.jpg")
    img.save(path, quality=88)
    print("doors_sheet: %s" % path)


if __name__ == "__main__":
    main()
