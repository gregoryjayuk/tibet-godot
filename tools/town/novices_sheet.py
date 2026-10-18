#!/usr/bin/env python3
"""The novices for Greg (IMP-024, after his 1776: "little children monks"): two boys of the monastery, 10 and 13, down the
Sky Stair in the afternoon as chapter 05's novices with the reading party, round the great wheel, at the boy's
knucklebones on Tsongra, and back up before half past four.
Stills: RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=novices_stair,novices_wheel,novices_knucklebones
Run: tools/py tools/town/novices_sheet.py   Writes tests/terrain/out/novices_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT_F = os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")
SHOTS = [("s3_novices_stair.png", "13:55, the elder down the Sky Stair"),
         ("s3_novices_wheel.png", "14:21, the younger in at the Mani Lhakhang to turn the great wheel"),
         ("s3_novices_knucklebones.png", "15:18, both at knucklebones on Tsongra with the boy and the girl")]


def main():
    w, h, cap, pad = 600, 338, 30, 10
    f = ImageFont.truetype(FONT_F, 19)
    big = ImageFont.truetype(FONT_F, 24)
    img = Image.new("RGB", (pad + 3 * (w + pad), 56 + h + cap + pad), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Novices in the town (IMP-024, after 1776): down from the monastery for the afternoon", font=big, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + i * (w + pad)
        path = os.path.join(OUT, name)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, 56))
        d.text((x, 56 + h + 4), label, font=f, fill=(40, 30, 25))
    path = os.path.join(OUT, "novices_sheet.jpg")
    img.save(path, quality=86)
    print("novices_sheet: %s" % path)


if __name__ == "__main__":
    main()
