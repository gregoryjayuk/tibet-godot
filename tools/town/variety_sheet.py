#!/usr/bin/env python3
"""The variety pass so far, before and after, for Greg (IMP-019): the same six views with the town as it stood on the
morning of 28 Sep 2026 (every house one of three kit variants a type, as the kit draws it) and as it stands now (nine
log-house variants, six town-house variants with their own stairs and windows, spread so no two alike stand together;
each household's upkeep, paint, lime and shut or lived in). No people, so the houses show.
Stills: the after, RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=tsongra_1600,lower_row,slice_v14,upper_row,upper_over,v28_dusk;
   the before, the same with --off=households appended and data/town_generic.json as it was at 85542b0
   (`git show 85542b0:data/town_generic.json`), put back afterwards.
Run: tools/py tools/town/variety_sheet.py   Writes tests/terrain/out/variety_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("tsongra_1600", "Tsongra at 16:00: the shop houses round the square"),
         ("lower_row", "A lane in lower Shöl: along it, a timber stair and a door at the ground where stone stairs stood"),
         ("slice_v14", "The top of the Sky Stair, the upper town's first rows below"),
         ("upper_row", "Along the Rooftop Way's row of log houses"),
         ("upper_over", "Over the upper town"),
         ("v28_dusk", "From V-28 at 17:07")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    img = Image.new("RGB", (pad + 2 * (w + pad), 96 + len(SHOTS) * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The variety pass (IMP-019): left, the town this morning; right, tonight. The same views, no people.", font=FONT, fill=(40, 30, 25))
    d.text((pad, 44), "77 kit variants for the 104 houses where there were 42 (one stood 14 times, now none more than 4); each household's own upkeep, paint and lime; a fifth shut.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        y = 96 + i * (h + cap + pad)
        for k, suffix in enumerate(("_off-households", "")):
            path = os.path.join(OUT, "s3_%s%s.png" % (name, suffix))
            if os.path.exists(path):
                img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (pad + k * (w + pad), y))
        d.text((pad, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "variety_sheet.jpg")
    img.save(path, quality=88)
    print("variety_sheet: %s" % path)


if __name__ == "__main__":
    main()
