#!/usr/bin/env python3
"""Lay out the town's lines at Tsongra's fuel stalls for Greg (sprint 7, step 8; chapter 07, 8.4-8.6): the player
stopping at each counter at nine, and the first line said there, in its script with the English under it, captioned.
Stills: STILLS=1 tools/player/s15.sh route stalls   (BARKS_LOG=1 adds each line said to the log)
Run: tools/py tools/player/stalls_sheet.py   Writes tests/player/out/stalls_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s15_stalls_01_kalsang", "At Kalsang Drolma's stall (she greeted the stranger coming up: \"Come and buy!\"); a boy to another: \"Come quickly!\""),
         ("s15_stalls_02_stall_woman", "The next counter, the stall woman, of her juniper: \"That's good.\""),
         ("s15_stalls_03_stall_man", "The stall man names his price: \"Half a rupee.\"")]


def main():
    w, h, pad, cap = 1200, 675, 10, 32
    img = Image.new("RGB", (w + 2 * pad, 56 + len(SHOTS) * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The town's lines at Tsongra's fuel stalls (sprint 7, step 8), 9:00: in Tibetan script, the English under it.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        y = 56 + i * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (pad, y))
        d.text((pad, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "stalls_sheet.jpg")
    img.save(path, quality=86)
    print("stalls_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
