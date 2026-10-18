#!/usr/bin/env python3
"""Lay out who is inside Dechen-tsang this afternoon for Greg (sprint 7, step 3): the Tibetan counting room with Dolkar
and the Litang agent, the Chinese one with Dolkar, Yang Shouren at his ledger and the Han clerk, and the kitchen's cook
and woman, each at its hour, captioned.
Stills: RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people
        --only=dechen_tibetan_people,dechen_chinese_people,dechen_desk_people,dechen_kitchen_people
Run: tools/py tools/town/inside_sheet.py   Writes tests/terrain/out/inside_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_dechen_tibetan_people", "13:57, the Tibetan room: Dolkar with the Litang agent, seated at its head"),
         ("s3_dechen_chinese_people", "14:18, across the yard: Dolkar in the Chinese room"),
         ("s3_dechen_desk_people", "14:00, Yang Shouren at his ledger, the Han clerk on the bench"),
         ("s3_dechen_kitchen_people", "14:00, the kitchen: the cook at the stove, a woman at the kettles")]


def main():
    w, h, pad, cap, cols = 900, 506, 10, 32, 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Who is inside Dechen-tsang this afternoon (sprint 7, step 3): until Dolkar rides out at 14:45.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "inside_sheet.jpg")
    img.save(path, quality=86)
    print("inside_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
