#!/usr/bin/env python3
"""Lay kit step K5's gallery stills (tests/kit/out/k5/, SET=k5 tools/kit/gallery.sh) on one sheet for Greg.
Run: tools/py tools/kit/k5_sheet.py   Writes tests/kit/out/k5/k5_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DIR = os.path.join(ROOT, "tests", "kit", "out", "k5")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 22)
CELLS = [("town_house_b1_v1", "B1, the shop house: the counter and its awning"), ("town_house_b2_v1", "B2, plain: the stair to the first-floor door"),
         ("town_house_b3_v1", "B3: the timber bay on the second floor"), ("town_house_b4_v1", "B4, the corner house: the passage below"),
         ("town_house_b1_v2", "B1, another seed: the ladder of windows"), ("poor_house_e1_v1", "E1, the poor house: stone through a thin wash"),
         ("poor_house_e2_v1", "E2: the lean-to room and its notched log"), ("stall_sh04_v1", "SH-04, the trestle stall; SH-03 below")]


def main():
    w, h, pad, cap, cols = 720, 405, 10, 34, 4
    rows = (len(CELLS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Kit step K5: lower Shöl's town houses (B1-B4), the poor house (E1, E2) and the stalls, in the game's look (plan chapter 03, 3.1, 3.3 and 4).", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(CELLS):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(DIR, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(DIR, "k5_sheet.jpg")
    img.save(path, quality=86)
    print("k5_sheet: " + path)


if __name__ == "__main__":
    main()
