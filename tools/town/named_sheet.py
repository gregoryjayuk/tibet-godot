#!/usr/bin/env python3
"""Lay out the slice's named buildings for Greg (sprint 4, step 2; chapter 12, 4.2): the stills tests/terrain/s3.gd
takes from their stations (`--shots --town --only=...`, below), captioned, in reading order.
Stills: RETURN_FOCUS=0 TIMEOUT=300 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town
        --only=headman_gate,headman_above,saddler,turner,tailor,tsongra_basin,tsongra_darchen
Run: tools/py tools/town/named_sheet.py   Writes tests/terrain/out/named_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("headman_gate", "1. The headman's house (SHL-19): its gate, the valance"),
         ("headman_above", "2. The headman's house: its walled yard, its darchen"),
         ("saddler", "3. The saddler (SHL-22): the saddle on its trestle"),
         ("turner", "4. The bowl-turner (SHL-21): bowls, blanks in the rack"),
         ("tailor", "5. The tailor (SHL-25): bolts of cloth, his sill"),
         ("tsongra_basin", "6. Tsongra's basin (SHL-02) and its channel"),
         ("tsongra_darchen", "7. Tsongra's darchen (SHL-03), 12 m")]


def main():
    w, h, pad, cap, cols = 640, 360, 10, 30, 4
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The slice's named buildings (sprint 4, step 2), in the stills' fixed afternoon light.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, "s3_%s.png" % name)).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "named_sheet.jpg")
    img.save(path, quality=86)
    print("named_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
