#!/usr/bin/env python3
"""Lay out art step A5's shots for Greg: rows are the draft street's five viewpoints under K05 (09:00); columns are the
draft's outline and ink_air. Run with the project's Python: tools/py tools/look/a5_sheet.py
Writes tests/look/out/a5_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "look", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 24)


def main():
    w, h, pad, cap = 960, 540, 12, 40
    rows = [("K05", v) for v in (1, 2, 3, 4, 5)]
    sheet = Image.new("RGB", (2 * w + 3 * pad, 60 + len(rows) * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 14), "Art step A5: the ink pass. Left, the draft's outline; right, ink_air (coloured lines to 400 m, distance in bands of hue, grain, vignette).", font=FONT, fill=(40, 30, 25))
    for r, (k, v) in enumerate(rows):
        for c, state in enumerate(("before", "after")):
            im = Image.open(os.path.join(OUT, "a5_%s_v%d_%s.png" % (k, v, state))).convert("RGB").resize((w, h), Image.LANCZOS)
            x, y = pad + c * (w + pad), 60 + r * (h + cap + pad)
            sheet.paste(im, (x, y))
            d.text((x, y + h + 6), "View %d, 09:00 (K05), %s" % (v, "the draft's outline" if state == "before" else "ink_air"), font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "a5_sheet.jpg")
    sheet.save(path, quality=86)
    print("a5_sheet: " + path)


if __name__ == "__main__":
    main()
