#!/usr/bin/env python3
"""The camera's framing for Greg (IMP-022; his 1773, 1775, 1776 and 1779): walking and running, side on along
Dechen-tsang's gallery, back behind in the yard, a lane's foot. H in play turns the framing off and on.
Stills: tools/player/tp.sh (the walk and the run), RETURN_FOCUS=0 STILLS=1 HOUR=15 tools/player/s15.sh route gallery,
        RETURN_FOCUS=0 STILLS=1 HOUR=14.0 tools/player/s15.sh route rooftop
Run: tools/py tools/player/camera_sheet.py   Writes tests/player/out/camera_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT_F = os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")
SHOTS = [("tp_6_woman_walk", "Walking: the arm as before (2.6 m, 68 degrees)"),
         ("tp_7_woman_run", "Running: lower, 2.05 m, 74 degrees, eased in (1773, 1775)"),
         ("s15_gallery_01_gallery_in", "Dechen-tsang's west gallery: the hint swings it side on (1779)"),
         ("s15_gallery_02_gallery_mid", "... the walker crossing the frame between the posts"),
         ("s15_gallery_04_yard", "Out in the yard: behind again"),
         ("rooftop_16_lane", "At a lane's foot (climbing, it drops and tips up the stair)")]


def main():
    w, h, cap, pad = 900, 506, 34, 10
    f = ImageFont.truetype(FONT_F, 22)
    big = ImageFont.truetype(FONT_F, 26)
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 60 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 16), "The camera (IMP-022): running, climbing and a framing hint; H in play turns the framing off and on", font=big, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 60 + (i // 2) * (h + cap + pad)
        path = os.path.join(OUT, name + ".png")
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 5), label, font=f, fill=(40, 30, 25))
    path = os.path.join(OUT, "camera_sheet.jpg")
    img.save(path, quality=86)
    print("camera_sheet: %s" % path)


if __name__ == "__main__":
    main()
