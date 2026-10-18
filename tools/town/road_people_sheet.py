#!/usr/bin/env python3
"""The Serchu road's people (M2 sprint 12, step 6; chapter 02, D09: "by day 60-200 on the road: carriers, pilgrims, a
caravan arriving, woodcutters ... by night about 55: the washers' camp, the millers' families"; chapter 08, V-01's
approach from the Serchu Zampa) on one page: a new game's first sight at the Zampa, CV-02's ten and its herd over the
Zampa and down the road past the mani wall, the carriers at the porters' rest, a pilgrim at the mani wall, the gold
washers at work and round their fires at dusk, a woodcutter at his tree, a miller at his door.
Its stills (in a window, some ten minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=zampa_opening,caravan_zampa,herd_zampa,road_rest,caravan_mani,road_pilgrim,washers_work,washers_fires,woodcutters,miller_door
Run: tools/py tools/town/road_people_sheet.py   Writes tests/terrain/out/road_people_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_zampa_opening", "14:25: a new game's first sight, the Zampa's gateway chorten and the bridge (NEW=1 HOUR=14.42 AT=zampa)"),
         ("s3_caravan_zampa", "11:00: CV-02's ten over the Zampa past the porters' rest, the herd behind on the north bank's road"),
         ("s3_herd_zampa", "11:12: the herd in file through the gateway chorten and over the deck"),
         ("s3_road_rest", "08:43: a carrier propping his tea on the porters' rest's ledge"),
         ("s3_caravan_mani", "12:18: the caravan down the road past the mani wall, from across the river"),
         ("s3_road_pilgrim", "08:55: a pilgrim at the mani wall"),
         ("s3_washers_work", "10:30: the gold washers at the troughs and at the water's edge with their pans"),
         ("s3_washers_fires", "19:00: the washers round their huts' fires"),
         ("s3_woodcutters", "11:00: a woodcutter at his larch above the road (his axe heard)"),
         ("s3_miller_door", "10:40: SER-07's miller at his door")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The Serchu road's people (M2 sprint 12, step 6): the caravan over the Zampa, carriers, pilgrims, washers, woodcutters, millers; a new game at the Zampa.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "road_people_sheet.jpg")
    img.save(path, quality=88)
    print("road_people_sheet: %s" % path)


if __name__ == "__main__":
    main()
