#!/usr/bin/env python3
"""The chest in Dechen-tsang's guest room for Greg (IMP-025; his 1771, 7 Oct 2026): the walker's clothes, three each for the
man and the woman, changed at the chest, the walker turning on a painted ring.
Stills: RETURN_FOCUS=0 STILLS=1 HOUR=15 tools/player/s15.sh route wardrobe
Run: tools/py tools/player/wardrobe_sheet.py   Writes tests/player/out/wardrobe_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT_F = os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")
SHOTS = [("s15_wardrobe_01_road.png", "The man as he came: sheepskin, leather out, for the road"),
         ("s15_wardrobe_02_town.png", "S: dull red serge to the knee, for the town"),
         ("s15_wardrobe_03_best.png", "S: fine dark wool, a turban and a ga'u, for a visit"),
         ("s15_wardrobe_04_woman_road.png", "B: the woman as she came, a blue truk trimmed black"),
         ("s15_wardrobe_05_woman_town.png", "S: undyed wool under the dark over-gown, for the town"),
         ("s15_wardrobe_06_woman_best.png", "S: a striped truk, a silk over-gown and amber, for a visit")]


def main():
    w, h, cap, pad = 900, 506, 34, 10
    f = ImageFont.truetype(FONT_F, 22)
    big = ImageFont.truetype(FONT_F, 26)
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 60 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 16), "The chest in Dechen-tsang's guest room (IMP-025): E by it; W, S the clothes; A, D turn; B the other of you", font=big, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 60 + (i // 2) * (h + cap + pad)
        path = os.path.join(OUT, name)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 5), label, font=f, fill=(40, 30, 25))
    path = os.path.join(OUT, "wardrobe_sheet.jpg")
    img.save(path, quality=86)
    print("wardrobe_sheet: %s" % path)


if __name__ == "__main__":
    main()
