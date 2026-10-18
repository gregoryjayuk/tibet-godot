#!/usr/bin/env python3
"""Lay out the offers carried between Dechen-tsang's two counting rooms for Greg (sprint 7, step 5; chapter 04, 4.3;
CX-052): the Litang agent's price pressed into the sleeve, Yang Shouren's answers across the yard, three times, to the
deal, from the player's own eyes, with the lines in Tibetan and Chinese and their English.
Stills: RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh route message
Run: tools/py tools/player/message_sheet.py   Writes tests/player/out/message_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s15_message_01_agent_1", "The agent from Litang presses his price into your sleeve: not a word said"),
         ("s15_message_02_yang_1", "Across the yard, Yang Shouren: \"Too dear. Come down a bit.\""),
         ("s15_message_03_agent_2", "The agent: \"No.\" He comes down, but not so far"),
         ("s15_message_04_yang_2", "Yang: \"That won't do.\" Neither names a price first"),
         ("s15_message_05_agent_3", "The agent: \"That's fine, it will do\""),
         ("s15_message_06_yang_3", "Yang: \"Agreed!\" Three in a room, and the house stands guarantor")]


def main():
    w, h, pad, cap, cols = 900, 506, 10, 32, 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Carrying the offers between the counting rooms (sprint 7, step 5), 14:33, while Dolkar rides out to the caravan.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "message_sheet.jpg")
    img.save(path, quality=86)
    print("message_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
