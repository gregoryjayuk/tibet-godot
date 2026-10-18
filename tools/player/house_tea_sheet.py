#!/usr/bin/env python3
"""Lay out tea in the houses to enter for Greg (ISS-105; world/tea.gd at each kitchen's BOWL, ../tibet-blender kit/rooms.py
house_kitchen): in each, sat on the bench by the hearth, poured by whoever of the household is at home from where they
sit (the grandmother at H-SHL-007, the mother at H-SHL-054, the man of the house at H-SHL-004), then the libation.
Stills: STILLS=1 HOUR=14 tools/player/s15.sh route house_tea, and the same for house_tea_054 and house_tea_004
Run: tools/py tools/player/house_tea_sheet.py   Writes tests/player/out/house_tea_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s15_house_tea_01_poured", "H-SHL-007: at the end of the bench, the grandmother pours, \"Please have tea\""),
         ("s15_house_tea_05_pouring", "She pours from the copper jug, standing at the guest's table (ISS-089)"),
         ("s15_house_tea_054_01_poured", "H-SHL-054: on the middle of the bench, the mother pours"),
         ("s15_house_tea_054_02_libation", "The libation"),
         ("s15_house_tea_004_01_poured", "H-SHL-004: the man of the house pours"),
         ("s15_house_tea_004_04_enough", "R: a palm over the bowl, \"No more, thank you\"")]


def main():
    w, h, pad, cap, cols = 900, 506, 10, 32, 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Tea in the houses to enter (ISS-105), 14:00: whoever of the household is home pours from where they sit.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "house_tea_sheet.jpg")
    img.save(path, quality=86)
    print("house_tea_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
