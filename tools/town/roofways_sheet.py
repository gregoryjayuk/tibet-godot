#!/usr/bin/env python3
"""A way onto every roof for Greg (IMP-026; ISS-114): a few of tools/town/roof_ways.py's pieces, the planks from the upper
yards, a stair-ladder, a notched log and a tall ladder up a wall, with the count of roofs reached.
Stills: RETURN_FOCUS=0 STILLS=1 HOUR=15 tools/player/s15.sh route roofways
Run: tools/py tools/town/roofways_sheet.py   Writes tests/player/out/roofways_sheet.jpg.
"""
import glob
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT_F = os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")
WORDS = {"plank": "a plank from the yard above", "stair": "a stair-ladder up its front", "log": "a notched log up to its terrace",
         "wall": "a tall ladder up its wall, a run of roofs beyond"}


def main():
    shots = sorted(glob.glob(os.path.join(OUT, "s15_roofway_0*.png")))
    report = open(os.path.join(ROOT, "docs", "town", "roof-ways-report.md")).read()
    m = re.search(r"(\d+) of (\d+) roofs reached: (\d+) already", report)
    head = "A way onto every roof the town can reach (IMP-026): %s of %s roofs now, %s before" % (m.group(1), m.group(2), m.group(3)) if m else "A way onto every roof (IMP-026)"
    w, h, cap, pad = 600, 338, 30, 10
    f = ImageFont.truetype(FONT_F, 19)
    big = ImageFont.truetype(FONT_F, 24)
    cols = 3
    rows = (len(shots) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), head, font=big, fill=(40, 30, 25))
    for i, path in enumerate(shots):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        kind, deck = re.match(r"s15_roofway_\d+_([a-z]+)_(.*)\.png", os.path.basename(path)).groups()
        d.text((x, y + h + 4), "%s: %s" % (deck.upper().replace("_", ".", 1).replace("_", "."), WORDS.get(kind, kind)), font=f, fill=(40, 30, 25))
    path = os.path.join(OUT, "roofways_sheet.jpg")
    img.save(path, quality=86)
    print("roofways_sheet: %s" % path)


if __name__ == "__main__":
    main()
