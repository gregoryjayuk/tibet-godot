#!/usr/bin/env python3
"""The town houses' outside stairs for Greg (ISS-100, Greg's walk: "all alike"; IMP-019; ../tibet-blender kit/houses.py
town_house's stair forms): stone on its podium (the settled houses'), timber on stringers, stone walled with a whitewashed
parapet, a notched log up to a railed landing (the game climbs it: world/town.gd _door_log), or none, the door at the
ground. Each still 6.5 m before a door up its stair, 4.2 m before one on the ground.
Stills: RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=door_H-SHL-012,door_H-SHL-022,door_H-SHL-002,door_H-SHL-010,door_H-SHL-009,door_H-SHL-028
Run: tools/py tools/town/stairs_sheet.py   Writes tests/terrain/out/stairs_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("H-SHL-012", "Stone on its podium, along the wall (25 houses)"),
         ("H-SHL-022", "Timber on two stringers, to a landing on posts (2)"),
         ("H-SHL-002", "Stone, walled with a whitewashed parapet (6)"),
         ("H-SHL-010", "A notched log up to a railed landing; the player climbs it (7)"),
         ("H-SHL-009", "None: the door at the ground, in through the stable (6)"),
         ("H-SHL-028", "A shop house's log up to its landing, the shop below")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The town houses' outside stairs (ISS-100): five forms where there was one, spread over the town's 46 town houses.", font=FONT, fill=(40, 30, 25))
    for i, (house, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 56 + (i // 2) * (h + cap + pad)
        path = os.path.join(OUT, "s3_door_%s.png" % house)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), "%s: %s" % (house, label), font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "stairs_sheet.jpg")
    img.save(path, quality=88)
    print("stairs_sheet: %s" % path)


if __name__ == "__main__":
    main()
