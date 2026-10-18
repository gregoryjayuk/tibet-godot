#!/usr/bin/env python3
"""Lanes and terraces for Greg (IMP-023; his note of 7 Oct 2026: the space round the houses "not a space you could
actually exist in", the stairs "placed there" where in his references they "belong there"): the town before and after,
its yards, its walls and its stairs.
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=lane_028_up,lane_031_up,lane_031_down,lane_011_up,yard_row9,yard_row8,lower_row,upper_row,upper_over,flight_yard_007,flight_yards_022,flight_mouth_015
   (the befores, from commit 3d1c147, are in tests/terrain/out/before_terraces/).
Run: tools/py tools/town/terraces_sheet.py   Writes tests/terrain/out/terraces_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
BEFORE = os.path.join(OUT, "before_terraces")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
BIG = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 26)
PAIRS = [("lane_031_down", "Down LN-031: the stair fills the lane wall to wall, parapets over the alleys"),
         ("upper_row", "The Rooftop Way's row: a level yard before every door, a parapet at its edge"),
         ("lower_row", "Lower Shöl: the yard before H-SHL-009, 015 and 023, a household's stair on it"),
         ("upper_over", "Over the upper town: each row on its terrace, the lanes' stairs between")]
AFTER = [("lane_028_up", "Up lane LN-028 between two log houses: rough stone, two flights and a landing"),
         ("lane_011_up", "Up lane LN-011 in lower Shöl, a slot between whitewashed walls"),
         ("yard_row8", "H-SHL-077's yard: room for a few people to stand and talk"),
         ("yard_row9", "H-SHL-074's yard, flagged, and row 9's beyond it"),
         ("flight_yard_007", "Steps up from lane LN-003 into H-SHL-007's yard (the house to enter)"),
         ("flight_yards_022", "Steps through the wall between two neighbours' yards, 1.7 m apart"),
         ("flight_mouth_015", "From the slope up into lane LN-015's mouth, through the yards' wall"),
         ("lane_031_up", "Up lane LN-031")]


def main():
    w, h, pad, cap = 900, 506, 10, 30
    cols = 2
    rows_b = len(PAIRS)
    rows_a = (len(AFTER) + cols - 1) // cols
    head = 60
    img = Image.new("RGB", (pad + cols * (w + pad), head + (rows_b + rows_a) * (h + cap + pad) + 50), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Lanes and terraces (IMP-023): before (left, 7 Oct) and after (right), then more of the after", font=BIG, fill=(40, 30, 25))
    y = head
    for name, label in PAIRS:
        for c, folder in enumerate((BEFORE, OUT)):
            x = pad + c * (w + pad)
            path = os.path.join(folder, "s3_%s.png" % name)
            if os.path.exists(path):
                img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
            d.text((x, y + h + 4), ("Before: " if c == 0 else "After: ") + (name if c == 0 else label), font=FONT, fill=(40, 30, 25))
        y += h + cap + pad
    d.text((pad, y + 8), "After", font=BIG, fill=(40, 30, 25))
    y += 50
    for i, (name, label) in enumerate(AFTER):
        x = pad + (i % cols) * (w + pad)
        yy = y + (i // cols) * (h + cap + pad)
        path = os.path.join(OUT, "s3_%s.png" % name)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, yy))
        d.text((x, yy + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "terraces_sheet.jpg")
    img.save(path, quality=86)
    print("terraces_sheet: %s %s" % (path, img.size))


if __name__ == "__main__":
    main()
