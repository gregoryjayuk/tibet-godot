#!/usr/bin/env python3
"""Lay out the town's first walkers for Greg (sprint 4, step 4): the street graph's map with the twenty walkers' rounds
(tools/town/graph.py) beside the stills of Tsongra, the Sky Stair, the Mani Lane and the great wheel, each at the moment
most walkers are in it (tools/town/walkers.sh stills).
Run: tools/py tools/town/walkers_sheet.py   Writes tests/terrain/out/walkers_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_people_tsongra", "1. Tsongra: its two flights, the talkers' steps"),
         ("s3_people_stair", "2. Down the Sky Stair past the Lhakhang"),
         ("s3_people_mani", "3. The Mani Lane, walked east on the north side"),
         ("s3_people_wheel", "4. A monk turning the great wheel")]


def main():
    w, h, pad, cap = 640, 360, 10, 30
    mp = Image.open(os.path.join(OUT, "street_graph_map.png")).convert("RGB")
    mh = 2 * (h + cap) + pad
    mw = int(mp.width * mh / mp.height)
    mp = mp.resize((mw, mh), Image.LANCZOS)
    img = Image.new("RGB", (pad + mw + pad + 2 * (w + pad), 56 + mh + cap + pad), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The townspeople on the street graph (sprint 4, step 4; the day's drawn since M2 sprint 10): their rounds on the map, and four places at their busiest.",
           font=FONT, fill=(40, 30, 25))
    img.paste(mp, (pad, 56))
    d.text((pad, 56 + mh + 4), "The graph: walkable ground (light: the town's), the rounds, the anchors", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + mw + pad + (i % 2) * (w + pad), 56 + (i // 2) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "walkers_sheet.jpg")
    img.save(path, quality=86)
    print("walkers_sheet: the map and %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
