#!/usr/bin/env python3
"""Samkha (M2 sprint 4; M2's acceptance 2): the chain bridge and Samkha Khar from V-10 and the south rim, the gate
passage's mouth and its lamp-lit length, the tiled roof pavilion, the mastiffs barking down at a crosser, the castle's
court in its hall of twelve pillars, the south pavilion's toll table, CV-02's mules on the lower bridge, the gate barred
at dusk.
Stills: RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=samkha_castle_v10,samkha_castle_south,samkha_mouth,samkha_deck_people,samkha_dogs,samkha_roof,samkha_court,samkha_sherab,samkha_mules_close,samkha_gate_shut
Run: tools/py tools/town/samkha_sheet.py   Writes tests/terrain/out/samkha_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_samkha_castle_v10", "V-10 on the chain bridge: Samkha Khar rising from the rim, the gate passage's dark mouth"),
         ("s3_samkha_castle_south", "From the south rim: the castle on its rock, the bridge sagging into its gate"),
         ("s3_samkha_mouth", "The mouth: lintels, the monogram's panel, the prayer wheel at the far door"),
         ("s3_samkha_deck_people", "15:16: an old man coming over the deck, the south pavilion beyond"),
         ("s3_samkha_dogs", "The same minute on the roof: the mastiffs barking down at him"),
         ("s3_samkha_roof", "The roof pavilion: grey tiles, its gables, the glass pane, the black banner"),
         ("s3_samkha_court", "09:30: the court in the hall of twelve pillars, the Pönpo on his dais"),
         ("s3_samkha_sherab", "10:00: Sherab at the toll table in the south pavilion, Thangtong Gyalpo's niche"),
         ("s3_samkha_mules_close", "15:16: CV-02's mules and ponies coming over the lower bridge"),
         ("s3_samkha_gate_shut", "17:45: the gate shut and barred at the dusk horns")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Samkha (M2 sprint 4): the chain bridge, Samkha Khar and its gate, who is there, the court hall.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "samkha_sheet.jpg")
    img.save(path, quality=88)
    print("samkha_sheet: %s" % path)


if __name__ == "__main__":
    main()
