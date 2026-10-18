#!/usr/bin/env python3
"""The Serchu road's last kilometre, M2 sprint 12 on one page (chapter 12's M2: "the Serchu road's last kilometre (SER-01 to
SER-04)"; chapter 02, D09; chapter 08, V-01's approach): R-01 from the Serchu Zampa down the south bank to the cliff
gallery, the Zampa with its gateway chorten and the porters' rest, the mani wall on the road, the gold washings, the Shade
Wood, the north bank's mills on their leat with the footbridge and the Yak Road's foot, and the road's people with CV-02
over the Zampa.
Its stills (in a window, some fifteen minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=zampa_opening,serchu_road_zampa,zampa_side,herd_zampa,serchu_mani,caravan_mani,serchu_washings_close,washers_fires,forest_road,serchu_road_above,mills_from_road,mill_arch,footbridge_side,yak_road_above,serchu_road_across,barley_terraces
Run: tools/py tools/town/serchu_sheet.py   Writes tests/terrain/out/serchu_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_zampa_opening", "A new game's first sight: the Serchu Zampa's gateway chorten and the bridge (NEW=1 HOUR=14.42 AT=zampa)"),
         ("s3_serchu_road_zampa", "R-01 down from the Zampa along the south bank, 885 m at 11.3%"),
         ("s3_zampa_side", "The Zampa's cantilevers over the Serchu from the south road"),
         ("s3_herd_zampa", "11:12: CV-02's herd in file through the gateway chorten and over the deck"),
         ("s3_serchu_mani", "Down the road along the mani wall SER-15, the road either side of it"),
         ("s3_caravan_mani", "12:18: the caravan past the mani wall by its south side, from across the river"),
         ("s3_serchu_washings_close", "The gold washings SER-12: the huts and the troughs at the water's edge"),
         ("s3_washers_fires", "19:00: the washers round their huts' fires"),
         ("s3_forest_road", "The Shade Wood SER-16 above the road: larch, birch, spruce, fir, a maple"),
         ("s3_serchu_road_above", "From high on the bank: the road along it, the river, the north bank"),
         ("s3_mills_from_road", "Across the river: the footbridge, the mills on their leat's cascade, the Yak Road's zigzags"),
         ("s3_mill_arch", "SER-07's arch: its tail race, its wheel turning under the floor"),
         ("s3_footbridge_side", "The footbridge SER-11: two logs on their cribs over the Serchu"),
         ("s3_yak_road_above", "From high on the flank: the Yak Road's legs, the mills, the leat, the river and R-01"),
         ("s3_serchu_road_across", "From the north bank across the river: the road along the slope"),
         ("s3_barley_terraces", "The monastery's barley terraces SER-17 in stubble, hay on the benches")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The Serchu road's last kilometre (M2 sprint 12): the road from the Zampa, its things and its people, the north bank's mills.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "serchu_sheet.jpg")
    img.save(path, quality=86)
    print("serchu_sheet: %s" % path)


if __name__ == "__main__":
    main()
