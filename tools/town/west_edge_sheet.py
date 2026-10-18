#!/usr/bin/env python3
"""The west edge for Greg (chapter 02, SHL-37; the game's ISS-105): Shöl's fifteen poorest households above Hejie's wall,
one-room E houses on the steep slope (tools/town/builder.py's west-edge pass, H-SHL-136 to 150), their yards terraced
by pads.py, and chapter 04's H-SHL-142 from its yard.
Stills: TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=west_edge,west_edge_above,house_142
Run: tools/py tools/town/west_edge_sheet.py   Writes tests/terrain/out/west_edge_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_west_edge_above", "From above on their east: the west edge's one-room houses along the slope, Hejie's plots below"),
         ("s3_house_142", "H-SHL-142, chapter 04's poor family's home, from its yard: dung cakes drying on its wall"),
         ("s3_west_edge", "From below, on the way up from Hejie")]


def main():
    w, h, pad, cap = 960, 540, 10, 32
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The west edge (SHL-37, ISS-105): fifteen poor households above Hejie's wall, at 15:00.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + (i % 2) * (w + pad), 56 + (i // 2) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "west_edge_sheet.jpg")
    img.save(path, quality=86)
    print("west_edge_sheet: %s" % path)


if __name__ == "__main__":
    main()
