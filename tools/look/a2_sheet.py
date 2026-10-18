#!/usr/bin/env python3
"""Lay out art step A2's shots for Greg: rows are viewpoints under K05 (09:00) and K08 (16:10); columns are M0's light
and M1's. Run with the project's Python: tools/py tools/look/a2_sheet.py   Writes tests/look/out/a2_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "look", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 24)
KEYS = {"K05": "09:00 (K05)", "K08": "16:10, golden (K08)"}


def main():
    w, h, pad, cap = 960, 540, 12, 40
    rows = [(k, v) for k in KEYS for v in (1, 2, 3)]
    sheet = Image.new("RGB", (2 * w + 3 * pad, 60 + len(rows) * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 14), "Art step A2: the draft street from the kit. Left, M0's light; right, M1's (ramps, crimson and indigo shade, warm fill, weathering).", font=FONT, fill=(40, 30, 25))
    for r, (k, v) in enumerate(rows):
        for c, state in enumerate(("before", "after")):
            im = Image.open(os.path.join(OUT, "a2_%s_v%d_%s.png" % (k, v, state))).convert("RGB").resize((w, h), Image.LANCZOS)
            x, y = pad + c * (w + pad), 60 + r * (h + cap + pad)
            sheet.paste(im, (x, y))
            d.text((x, y + h + 6), "View %d, %s, %s" % (v, KEYS[k], "M0" if state == "before" else "M1"), font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "a2_sheet.jpg")
    sheet.save(path, quality=86)
    print("a2_sheet: " + path)


if __name__ == "__main__":
    main()
