#!/usr/bin/env python3
"""Hejie at a distance (M2 sprint 9, step 4; plan chapter 02, D03; chapter 03, 9) on one page: V-15 up River Street from
the Water Gate, the street towards the East Gate, the East Gate from outside, the Guandi temple, Hejie's roofs from
Shöl's west edge by day and at dusk with its windows lit, and the town from V-03 on Pharkha's bluff, V-04, Samkha's
chain bridge and the Landing (tools/town/hejie.py's ground, wall and houses; the kit's Hejie types, ../tibet-blender
kit/hejie.py; placed by world/town.gd).
Its stills (in a window, a few minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=hejie_v15,hejie_street,hejie_east_gate,hejie_temple,hejie_above,hejie_dusk,hejie_v03,hejie_v04,hejie_samkha,hejie_landing
Run: tools/py tools/town/hejie_sheet.py   Writes tests/terrain/out/hejie_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_hejie_v15", "16:30, V-15: up River Street from the Water Gate", 1.0),
         ("s3_hejie_street", "15:00: up River Street to the teahouse's bend", 1.0),
         ("s3_hejie_east_gate", "15:00: the East Gate from outside", 1.0),
         ("s3_hejie_temple", "15:30: the Guandi temple's courtyard and hall", 1.0),
         ("s3_hejie_above", "15:30: Hejie's grey roofs from Shöl's west edge", 1.0),
         ("s3_hejie_dusk", "18:20: Hejie at dusk, its windows lit", 1.1),
         ("s3_hejie_v03", "15:00, V-03: Hejie on its fan from Pharkha", 1.0),
         ("s3_hejie_v04", "16:10, V-04: Hejie at 264 from the Lhabab Chorten", 1.0),
         ("s3_hejie_samkha", "15:30: from the chain bridge at Samkha", 1.0),
         ("s3_hejie_landing", "15:00: from the Landing's beach", 1.0)]


def main():
    w, h, pad, cap = 576, 324, 8, 26
    cols = 5
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 50 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 12), "M2 sprint 9, step 4: Hejie at a distance, its wall and gates, River Street's shop-houses, the temple, its roofs by day and dusk.",
           font=FONT, fill=(40, 30, 25))
    for i, (name, label, bright) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 50 + (i // cols) * (h + cap + pad)
        path = os.path.join(TERRAIN, name + ".png")
        if not os.path.exists(path):
            d.text((x, y + h // 2), "missing: " + name, font=FONT, fill=(160, 40, 30))
            continue
        im = Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS)
        if bright != 1.0:
            im = ImageEnhance.Brightness(im).enhance(bright)
        img.paste(im, (x, y))
        d.text((x, y + h + 3), label, font=FONT, fill=(40, 30, 25))
    out = os.path.join(TERRAIN, "hejie_sheet.jpg")
    img.save(out, quality=88)
    print("hejie_sheet:", out)


if __name__ == "__main__":
    main()
