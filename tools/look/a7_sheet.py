#!/usr/bin/env python3
"""Lay out art step A7's day for Greg: two sheets, the street (viewpoint 1) and from above (viewpoint 5), thirteen
moments of 28 October 1903 from 04:30 to 01:00 in reading order. Run: tools/py tools/look/a7_sheet.py
Writes tests/look/out/a7_street.jpg and a7_above.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "look", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 22)
TIMES = [("0430", "04:30, stars"), ("0530", "05:30, first light"), ("0722", "07:22, first sun on the gilded roofs"),
         ("0739", "07:39, Tsongra lit"), ("0900", "09:00, market"), ("1143", "11:43, solar noon"), ("1400", "14:00, dust"),
         ("1608", "16:08, the shadow takes Tsongra"), ("1635", "16:35, last sun on the roofs"), ("1715", "17:15, alpenglow"),
         ("1742", "17:42, end of twilight"), ("2030", "20:30, the half moon"), ("0100", "01:00, after moonset")]


def sheet(view, title, name):
    w, h, pad, cap, cols = 640, 360, 10, 34, 4
    rows = (len(TIMES) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), title, font=FONT, fill=(40, 30, 25))
    for i, (t, label) in enumerate(TIMES):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        im = Image.open(os.path.join(OUT, "a7_v%d_%s.png" % (view, t))).convert("RGB").resize((w, h), Image.LANCZOS)
        img.paste(im, (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, name)
    img.save(path, quality=86)
    print("a7_sheet: " + path)


if __name__ == "__main__":
    sheet(1, "Art step A7: the whole default day, 28 October 1903, on the draft street from the kit (M1's look, the ink pass).", "a7_street.jpg")
    sheet(5, "Art step A7: the whole default day from above (viewpoint 5).", "a7_above.jpg")
