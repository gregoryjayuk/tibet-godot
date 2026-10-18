#!/usr/bin/env python3
"""Lay out the Rooftop Way's stills for Greg (sprint 4, step 1): the third-person view as the walker meets each piece of
R-06, from Dechen-tsang's guest yard to V-28's roof, in reading order, each captioned with the piece and the roof or
lane it leads to (tools/town/rooftop.py's legs). Stills: STILLS=1 HOUR=14.0 tools/player/s15.sh route rooftop.
Run: tools/py tools/player/rooftop_sheet.py   Writes tests/player/out/rooftop_sheet.jpg.
"""
import glob
import json
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
WAY = os.path.join(ROOT, "assets", "generated", "terrain", "rooftop.json")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
KINDS = {"stair": "a stair-ladder", "log": "a notched log", "plank": "a plank bridge", "steps": "roof steps", "lane": "a lane's flight",
         "parapet": "over the parapets", "end": "V-28's roof, the end"}


def captions():
    """For each piece of the way in order: what it is and where it leads."""
    legs = json.load(open(WAY))["legs"]
    out = []
    for k, leg in enumerate(legs):
        if "by" not in leg:
            continue
        to = legs[k + 1]["on"] if k + 1 < len(legs) else ""
        where = "the ground" if to == "ground" else ("Dechen-tsang's roofs" if to.startswith("SHL-04") else "the roof of " + to.rsplit(".", 1)[0])
        out.append("%s, onto %s" % (KINDS.get(leg["by"], leg["by"]), where))
    return out


def main():
    stills = sorted(glob.glob(os.path.join(OUT, "rooftop_[0-9][0-9]_*.png")))
    caps = captions()
    w, h, pad, cap, cols = 640, 360, 10, 30, 4
    rows = (len(stills) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The Rooftop Way (R-06), sprint 4, step 1: the walker at each piece, Dechen-tsang's guest yard to V-28's roof, 14:00.",
           font=FONT, fill=(40, 30, 25))
    for i, path in enumerate(stills):
        n = int(re.search(r"rooftop_(\d+)_", path).group(1))
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        label = KINDS["end"] if path.endswith("_end.png") else (caps[n - 1] if 0 < n <= len(caps) else os.path.basename(path))
        d.text((x, y + h + 4), "%d. %s" % (n, label), font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "rooftop_sheet.jpg")
    img.save(path, quality=86)
    print("rooftop_sheet: %d stills -> %s" % (len(stills), path))


if __name__ == "__main__":
    main()
