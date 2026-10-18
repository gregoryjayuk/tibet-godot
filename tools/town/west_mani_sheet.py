#!/usr/bin/env python3
"""The western mani wall SHL-10 and the lingkor's west side (M2 sprint 6, step 6; plan chapter 02: "260 m, the lingkor's
west side"; chapter 04, 4.2: the poor family's grandmother at dusk): its four walls stepping up the slope down the middle
of their bed, from its foot, and the grandmother going round the first, up its west side.
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=west_mani_foot,west_mani_side,west_mani_dusk
Run: tools/py tools/town/west_mani_sheet.py   Writes tests/terrain/out/west_mani_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_west_mani_foot", "From its foot by the west edge: up the lingkor's west side, 260 m at 25 degrees"),
         ("s3_west_mani_side", "Its walls stepping up the slope, a pillar at each end, a way between"),
         ("s3_west_mani_dusk", "18:09: the grandmother of H-SHL-142 going round the first wall, up its west side")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    img = Image.new("RGB", (pad + 3 * (w + pad), 56 + h + cap + pad), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The western mani wall SHL-10 (M2 sprint 6, step 6): the lingkor's west side.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + i * (w + pad)
        img.paste(Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, 56))
        d.text((x, 56 + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "west_mani_sheet.jpg")
    img.save(path, quality=88)
    print("west_mani_sheet: %s" % path)


if __name__ == "__main__":
    main()
