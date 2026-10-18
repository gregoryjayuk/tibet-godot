#!/usr/bin/env python3
"""Lay out the tea in Dechen-tsang's Tibetan room for Greg (sprint 7, step 4; chapter 07, 7.2): the guest's own view from
the guest bench, poured before anything is said, the libation, a sip refilled, and enough, captioned.
Stills: RETURN_FOCUS=0 STILLS=1 HOUR=14 tools/player/s15.sh route tea
Run: tools/py tools/player/tea_sheet.py   Writes tests/player/out/tea_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s15_tea_01_poured", "Sat on the guest bench: the bowl filled before anything is said, \"Please have tea\""),
         ("s15_tea_02_libation", "E, the first time: the libation, the forefinger dipped and flicked to the four quarters"),
         ("s15_tea_05_pouring", "After a sip she comes to the table and pours again, the copper jug in her right hand (ISS-089)"),
         ("s15_tea_03_refilled", "E, a sip; refilled to the brim with \"Please have tea\" again"),
         ("s15_tea_04_enough", "R: a palm over the bowl, \"No more, thank you\"; she pours no more")]


def main():
    w, h, pad, cap, cols = 900, 506, 10, 32, 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Tea in the Tibetan room (sprint 7, step 4), 14:00: the house's woman pours, the guest drinks.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "tea_sheet.jpg")
    img.save(path, quality=86)
    print("tea_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
