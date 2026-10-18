#!/usr/bin/env python3
"""The arrival by the Serchu road (M2 sprint 3; M2's acceptance 1): the road chorten, the cliff gallery and its rock,
the caravan in file on it, the Gate Chorten at the end of the cutting through the nose and the mandala under it, V-01's
reveal of the town, the caravan past the eight chortens and down the south ramp.
Stills: RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=arrival_ser20,arrival_v19,arrival_caravan_gallery,arrival_chorten_east,arrival_mandala,arrival_v01,arrival_caravan_row,arrival_caravan_ramp
Run: tools/py tools/town/arrival_sheet.py   Writes tests/terrain/out/arrival_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_arrival_ser20", "SER-20, the road chorten at the cliff gallery's east end"),
         ("s3_arrival_v19", "V-19 on the gallery: loose planks on beams in the rock, the old sockets above"),
         ("s3_arrival_caravan_gallery", "13:12: the caravan in file on the gallery, across the Golden Slot"),
         ("s3_arrival_chorten_east", "Out of the cutting through the nose: the Gate Chorten"),
         ("s3_arrival_mandala", "Under it, the mandala on its ceiling"),
         ("s3_arrival_v01", "V-01: out of the chorten, the town (14:52)"),
         ("s3_arrival_caravan_row", "13:42: the caravan past the eight chortens, birth to nirvana"),
         ("s3_arrival_caravan_ramp", "14:30: down Samkha's south ramp to the lower bridge")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The arrival by the Serchu road (M2 sprint 3): the cliff gallery, the Gate Chorten's reveal (V-01), the eight chortens, the caravan.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "arrival_sheet.jpg")
    img.save(path, quality=88)
    print("arrival_sheet: %s" % path)


if __name__ == "__main__":
    main()
