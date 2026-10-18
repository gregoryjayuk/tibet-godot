#!/usr/bin/env python3
"""The town houses' crown strips for Greg (ISS-109's last cut; shaders/stylized_static.gdshader, the kit's slots
crown_black_paint and crown_wood_maroon): left, every house as the kit draws it (--off=households); right, each
household's own strip, black or maroon as it paints it, renewed or gone towards dust and brick with its upkeep but a band
still while anyone lives there, flaking off the parapet on a house shut or left.
Stills: TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=crowns_row,crowns_031,flags_roofs,roof_H-SHL-031,roof_H-SHL-022
and the same again with --off=households.
Run: tools/py tools/town/crowns_sheet.py   Writes tests/terrain/out/crowns_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_crowns_row", "Level with the crowns of H-SHL-023 (left for good: flaking), 015 (as the kit drew it) and 009 (maroon now)"),
         ("s3_crowns_031", "H-SHL-031 and its neighbours, from across their lane"),
         ("s3_flags_roofs", "Over the roofs of lower Shöl, looking south to Tsongra"),
         ("s3_roof_H-SHL-031", "H-SHL-031's roof: its black strip, kept poorly"),
         ("s3_roof_H-SHL-022", "H-SHL-022's")]


def main():
    w, h, pad, cap = 800, 450, 10, 30
    img = Image.new("RGB", (pad + 2 * (w + pad), 84 + len(SHOTS) * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The crown strips (ISS-109): left, as the kit draws every house; right, each household's own, black or maroon,", font=FONT, fill=(40, 30, 25))
    d.text((pad, 42), "renewed or faded towards dust and brick with its upkeep, flaking off the parapet on a house shut or left.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        y = 84 + i * (h + cap + pad)
        for j, suffix in enumerate(("_off-households", "")):
            x = pad + j * (w + pad)
            img.paste(Image.open(os.path.join(OUT, name + suffix + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((pad, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "crowns_sheet.jpg")
    img.save(path, quality=88)
    print("crowns_sheet: %s" % path)


if __name__ == "__main__":
    main()
