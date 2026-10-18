#!/usr/bin/env python3
"""Each household its own, before and after, for Greg (IMP-019; world/households.gd): the same stills with every house as
the kit draws it (s3's --off=households) and with its household's upkeep, paint, lime and shut or lived in; then, at
full size, the three places where the most changed, before beside after.
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=flags_roofs,slice_v14,hearths_dusk,tsongra_1600,v28_dusk,birds_close
   and the same with --off=households appended.
Run: tools/py tools/town/households_sheet.py   Writes tests/terrain/out/households_sheet.jpg.
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("tsongra_1600", "Tsongra at 16:00: each house's woodwork its own paint, its lime its own warmth and age"),
         ("slice_v14", "Down from V-14: the log storeys' oxblood fresh, faded, or on a house long left, grey timber"),
         ("hearths_dusk", "17:25: a shut house's shutters closed, no lamp, no smoke; the lime fresh, old or worn thin"),
         ("v28_dusk", "V-28 at 17:07: fewer roofs with people, fewer threads of smoke"),
         ("flags_roofs", "Over the roofs, looking south over Tsongra"),
         ("birds_close", "The upper town's white houses from the slope")]
CROP = (840, 400)


def load(name):
    return (Image.open(os.path.join(OUT, "s3_%s_off-households.png" % name)).convert("RGB"),
            Image.open(os.path.join(OUT, "s3_%s.png" % name)).convert("RGB"))


def busiest(before, after):
    """The CROP-sized window where the most changed, and how much (the mean of the change over 8 levels, in it)."""
    d = np.abs(np.asarray(after).astype(np.float64) - np.asarray(before).astype(np.float64)).max(axis=2)
    m = (d > 8).astype(np.float64)
    ii = np.pad(m.cumsum(0).cumsum(1), ((1, 0), (1, 0)))
    w, h = CROP
    best = (0.0, 0, 0)
    for y in range(0, m.shape[0] - h + 1, 20):
        for x in range(0, m.shape[1] - w + 1, 20):
            s = ii[y + h, x + w] - ii[y, x + w] - ii[y + h, x] + ii[y, x]
            if s > best[0]:
                best = (s, x, y)
    return best[1], best[2], best[0] / (w * h)


def main():
    w, h, pad, cap = 960, 540, 10, 30
    pairs = [(n, label) + load(n) for n, label in SHOTS if os.path.exists(os.path.join(OUT, "s3_%s.png" % n))]
    crops = sorted(((busiest(b, a), n, b, a) for n, label, b, a in pairs), key=lambda c: -c[0][2])[:3]
    top = 96
    height = top + len(pairs) * (h + cap + pad) + 50 + len(crops) * (CROP[1] + cap + pad)
    img = Image.new("RGB", (pad + 2 * (w + pad), height), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Each household its own (IMP-019): left, every house as the kit draws it; right, its household's.", font=FONT, fill=(40, 30, 25))
    d.text((pad, 44), "Upkeep (lime and paint), the woodwork's paint, the lime's warmth, and about a fifth shut: shutters, no smoke, no one on the roof.", font=FONT, fill=(40, 30, 25))
    for i, (name, label, before, after) in enumerate(pairs):
        y = top + i * (h + cap + pad)
        img.paste(before.resize((w, h), Image.LANCZOS), (pad, y))
        img.paste(after.resize((w, h), Image.LANCZOS), (2 * pad + w, y))
        d.text((pad, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    y = top + len(pairs) * (h + cap + pad) + 10
    d.text((pad, y), "At full size, where the most changed: before on the left, after on the right.", font=FONT, fill=(40, 30, 25))
    y += 40
    for (x0, y0, share), name, before, after in crops:
        box = (x0, y0, x0 + CROP[0], y0 + CROP[1])
        img.paste(before.crop(box), (pad, y))
        img.paste(after.crop(box), (2 * pad + CROP[0], y))
        d.text((pad, y + CROP[1] + 4), "%s: %.0f%% of this crop changed" % (name, 100 * share), font=FONT, fill=(40, 30, 25))
        y += CROP[1] + cap + pad
    path = os.path.join(OUT, "households_sheet.jpg")
    img.save(path, quality=88)
    print("households_sheet: %s" % path)


if __name__ == "__main__":
    main()
