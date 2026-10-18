#!/usr/bin/env python3
"""Lay out spike S19's stills (fists and the sling; tests/player/out/fight_*.png, tools/player/fight.sh) on one sheet for Greg.
Run: tools/py tools/player/fight_sheet.py   Writes tests/player/out/fight_sheet.jpg.
"""
import glob
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 22)
LABELS = {"face_off": "Face-off: the partner closes in, both guards up", "jab": "A left jab lands: the striker steps in to 0.8 m",
          "partner_jab": "The partner's right jab lands on the player", "far": "The same from 10 m: a jab still reads",
          "dodge": "Space, the guard up: he dodges back and the jab finds nothing",
          "knockdown": "The third blow knocks him down; he gets up again",
          "sling_whirl": "G, then hold the left button: the sling whirls",
          "whirl_close": "The whirl closer: the cord blurs at speed", "sling_loose": "Let go: the stone leaves at 28 m/s, 15 m from the pots",
          "pots": "The stone lies where Pot 3 stood; the pot tumbles off behind"}


def main():
    files = sorted(glob.glob(os.path.join(OUT, "fight_*.png")), key=lambda f: int(os.path.basename(f).split("_")[1]))
    w, h, pad, cap, cols = 720, 405, 10, 34, 4
    cells = [(Image.open(f).convert("RGB"), LABELS.get(os.path.basename(f)[:-4].split("_", 2)[2], f)) for f in files]
    rows = (len(cells) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Spike S19, fists and the sling, in the practice yard on the kit street (plan chapter 11, 13.8): the player and a sparring partner under the same rules.", font=FONT, fill=(40, 30, 25))
    for i, (im, label) in enumerate(cells):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(im.resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "fight_sheet.jpg")
    img.save(path, quality=86)
    print("fight: sheet " + path)


if __name__ == "__main__":
    main()
