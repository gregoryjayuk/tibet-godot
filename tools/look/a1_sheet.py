#!/usr/bin/env python3
"""Pair art step A1's shots for Greg: before (M0's look) and after (the weathering stack), at 2, 20 and 50 m.
Run with the project's Python: tools/py tools/look/a1_sheet.py   Writes tests/look/out/a1_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "look", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 24)


def main():
    w, h, pad, cap = 960, 540, 12, 40
    rows = [(2, "2 m"), (20, "20 m"), (50, "50 m")]
    sheet = Image.new("RGB", (2 * w + 3 * pad, 60 + len(rows) * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 14), "Art step A1: the Type B house at noon. Left, M0's look; right, the weathering stack (chapter 09, 4.6).", font=FONT, fill=(40, 30, 25))
    for r, (dist, label) in enumerate(rows):
        for c, state in enumerate(("before", "after")):
            im = Image.open(os.path.join(OUT, "a1_%02dm_%s.png" % (dist, state))).convert("RGB").resize((w, h), Image.LANCZOS)
            x, y = pad + c * (w + pad), 60 + r * (h + cap + pad)
            sheet.paste(im, (x, y))
            d.text((x, y + h + 6), "%s, %s" % (label, "before" if state == "before" else "after"), font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "a1_sheet.jpg")
    sheet.save(path, quality=88)
    print("a1_sheet: " + path)


if __name__ == "__main__":
    main()
