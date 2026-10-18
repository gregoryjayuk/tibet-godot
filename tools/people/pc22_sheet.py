#!/usr/bin/env python3
"""PC-22's sheet (plan chapter 09): the row of people seen from 40 m, greyed and enlarged 4 times without smoothing (each
figure as the game draws it, about 37 px tall), beside the same row from 10 m in colour, captioned in order.
Run: tools/py tools/people/pc22_sheet.py   Writes tests/people/out/pc22_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "people", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
ORDER = "From the left, each idle then walking: the townsman (TM), the townswoman (TW), a monk (a stand-in), the traveller man and woman (the player)."


def main():
    far = Image.open(os.path.join(OUT, "pc22_40m.png")).convert("RGB")
    grey = ImageOps.grayscale(far)
    # the figures' box: whatever differs from the ground and sky's rows' median, round the middle
    w, h = grey.size
    box = (w // 2 - 160, h // 2 - 60, w // 2 + 160, h // 2 + 40)
    crop = grey.crop(box).resize(((box[2] - box[0]) * 4, (box[3] - box[1]) * 4), Image.NEAREST)
    near = Image.open(os.path.join(OUT, "pc22_10m.png")).convert("RGB")
    near = near.crop((w // 2 - 780, h // 2 - 260, w // 2 + 780, h // 2 + 220))  # the row at 10 m
    nh = crop.height
    near = near.resize((int(near.width * nh / near.height), nh), Image.LANCZOS)
    pad = 12
    img = Image.new("RGB", (pad * 3 + crop.width + near.width, 56 + nh + 40), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "PC-22: the people at 40 m in grey (enlarged 4x, unsmoothed), and at 10 m in colour. " + ORDER, font=FONT, fill=(40, 30, 25))
    img.paste(crop.convert("RGB"), (pad, 56))
    img.paste(near, (pad * 2 + crop.width, 56))
    d.text((pad, 56 + nh + 8), "40 m, grey", font=FONT, fill=(40, 30, 25))
    d.text((pad * 2 + crop.width, 56 + nh + 8), "10 m, colour", font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "pc22_sheet.jpg")
    img.save(path, quality=88)
    print("pc22_sheet: %s" % path)


if __name__ == "__main__":
    main()
