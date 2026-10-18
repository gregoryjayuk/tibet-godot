#!/usr/bin/env python3
"""The townspeople for Greg (M1 sprint 4, step 5): the four MPFB bodies in Kham dress (people2/body.py; DS-01 and DS-02),
each from the front and the side in its idle pose (Blender's workbench, BODY_RENDER=tests/people/out/bodies), above
PC-22's sheet (tools/people/pc22.sh: the people at 40 m in grey).
Run: tools/py tools/people/townspeople_sheet.py   Writes tests/people/out/townspeople_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "people", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
BODIES = [("townsman", "The townsman (TM): dull red serge"), ("townsman_b", "The townsman: undyed wool, older"),
          ("townswoman", "The townswoman (TW): gown, plate"), ("townswoman_b", "The townswoman: blue truk")]


def main():
    tiles = []
    for name, _ in BODIES:
        for view in ("front", "side"):
            im = Image.open(os.path.join(OUT, "bodies", "%s_idle_%s.png" % (name, view))).convert("RGB")
            tiles.append(im.crop((90, 120, 510, 880)))  # the figure, off the empty margins
    tw, th = tiles[0].size
    s = 0.5
    tw, th = int(tw * s), int(th * s)
    pc = Image.open(os.path.join(OUT, "pc22_sheet.jpg")).convert("RGB")
    W = max(len(tiles) * tw + 20, pc.width)
    pc = pc.resize((W, int(pc.height * W / pc.width)), Image.LANCZOS)
    img = Image.new("RGB", (W, 56 + th + 40 + pc.height), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((10, 14), "The townspeople of Shöl in their everyday dress (sprint 4, step 5): MPFB bodies, each from the front and the side.", font=FONT, fill=(40, 30, 25))
    for i, t in enumerate(tiles):
        img.paste(t.resize((tw, th), Image.LANCZOS), (10 + i * tw, 56))
    for k, (_, label) in enumerate(BODIES):
        d.text((10 + 2 * k * tw, 56 + th + 6), label, font=FONT, fill=(40, 30, 25))
    img.paste(pc, (0, 56 + th + 40))
    path = os.path.join(OUT, "townspeople_sheet.jpg")
    img.save(path, quality=88)
    print("townspeople_sheet: %s" % path)


if __name__ == "__main__":
    main()
