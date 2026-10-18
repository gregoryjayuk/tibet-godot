#!/usr/bin/env python3
"""The general tea's seat in the Tsokchen for Greg (M3 sprint 6, step 4; plan chapter 04, 3.1; world/hall_tea.gd): sat at the
guest's place at the west rows' door end by the aisle, the novice who serves the back rows pours from the big kettle,
the libation, a sip and the bowl filled again, a palm over it, up with a little left; nothing said over the tea.
Stills: RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh route tsokchen_tea, then the same with TEA_VIEW=third (rename those
stills s15_tsokchen_tea_third_*).
Run: tools/py tools/player/hall_tea_sheet.py   Writes tests/player/out/hall_tea_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
BIG = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 26)
SHOTS = [("s15_tsokchen_tea_third_01_poured", "11:03, the general tea: sat at the back of the left row, the novice has poured"),
         ("s15_tsokchen_tea_01_poured", "The guest's view: the bowl full on the book-stand, E the libation first"),
         ("s15_tsokchen_tea_third_05_pouring", "A sip, and he fills the bowl again from the big kettle"),
         ("s15_tsokchen_tea_05_pouring", "The pour, from the guest's place"),
         ("s15_tsokchen_tea_third_04_enough", "R: a palm over the bowl; a last sip, and up with a little left"),
         ("s15_tsokchen_tea_04_enough", "Enough: the novice turns back to his place in the aisle")]


def main():
    w, h, pad, cap, cols = 900, 506, 10, 32, 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 60 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 16), "The general tea's seat in the Tsokchen (M3 sprint 6, step 4)", font=BIG, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 60 + (i // cols) * (h + cap + pad)
        path = os.path.join(OUT, name + ".png")
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 5), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "hall_tea_sheet.jpg")
    img.save(path, quality=86)
    print("hall_tea_sheet: %s" % path)


if __name__ == "__main__":
    main()
