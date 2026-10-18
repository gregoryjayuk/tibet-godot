#!/usr/bin/env python3
"""The chang house SHL-24 (M2 sprint 2): its drinking room, its people, the talk overheard (mission 2, What the town is
saying), the chang poured, and the evening: the muleteer's dranyen from 19:00 (heard), the bard at 19:30, the oil lamp.
Stills: RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=chang_out,chang_in,chang_back,chang_dusk
then `STILLS=1 tools/player/s15.sh route chang_talk` and `STILLS=1 tools/player/s15.sh route chang_tea` (one after the other).
Run: tools/py tools/town/chang_sheet.py   Writes tests/terrain/out/chang_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLAYER = os.path.join(ROOT, "tests", "player", "out")
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [(TERRAIN, "s3_chang_out", "SHL-24 from its lane, 16:30: the stair up to the drinking room's open door"),
         (TERRAIN, "s3_chang_in", "16:45, in at the door: Jiang Deshun on the back bench, Ama Yudrön and her daughter"),
         (PLAYER, "s15_chang_talk_01_order", "Overheard: the room asks the interpreter what the order said"),
         (PLAYER, "s15_chang_talk_02_sixty", "Mission 2: Ama Yudrön gives the number the town can bear to hear"),
         (PLAYER, "s15_chang_tea_02_libation", "Hot chang from the pan's ladle, the drops flicked to the four quarters first"),
         (TERRAIN, "s3_chang_back", "17:15: the post's two soldiers on the bench by the stove"),
         (PLAYER, "s15_chang_talk_03_debts", "Who owes whom: the ledger takes it down"),
         (TERRAIN, "s3_chang_dusk", "19:40, the oil lamp lit: the muleteer whose dranyen is heard, the bard in his hat")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The chang house SHL-24 (M2 sprint 2): its drinking room and people, mission 2 overheard, the chang poured, the evening's dranyen and bard.", font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "chang_sheet.jpg")
    img.save(path, quality=88)
    print("chang_sheet: %s" % path)


if __name__ == "__main__":
    main()
