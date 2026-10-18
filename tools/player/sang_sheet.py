#!/usr/bin/env python3
"""Lay out the roof's sang at Dechen-tsang for Greg (sprint 7, step 6; chapter 02, 8.3; CX-050, CX-070): the player up the
Rooftop Way's first pieces, laying juniper on the master range's burner with the household at 17:12, and the roof from
its east end, the thread of smoke going up with the town's.
Stills: RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh route sang
        RETURN_FOCUS=0 TIMEOUT=400 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=dechen_roof_sang
Run: tools/py tools/player/sang_sheet.py   Writes tests/player/out/sang_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("tests/player/out/s15_sang_01_burner.png", "17:12, up the ladders to the roof: juniper laid on the burner, \"The gods are victorious!\""),
         ("tests/terrain/out/s3_dechen_roof_sang.png", "Dolkar and the house's woman at the burner, its thread going up with the town's")]


def main():
    w, h, pad, cap, cols = 900, 506, 10, 32, 2
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + h + cap + pad), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Juniper on Dechen-tsang's roof at five o'clock (sprint 7, step 6), where the Rooftop Way begins.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + i * (w + pad), 56
        img.paste(Image.open(os.path.join(ROOT, name)).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(ROOT, "tests", "player", "out", "sang_sheet.jpg")
    img.save(path, quality=86)
    print("sang_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
