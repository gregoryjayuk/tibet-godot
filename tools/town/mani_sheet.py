#!/usr/bin/env python3
"""Lay out the Mani Lhakhang, its great wheel, the barkor's mani wall and Pasang's pitch for Greg (sprint 4, step 3):
the stations' stills (tests/terrain/s3.gd, `--shots --town --only=...`, below) and the wheel walk's (tools/player/s15.sh
route wheel with STILLS=1), captioned, in reading order.
Stills: RETURN_FOCUS=0 TIMEOUT=300 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town
        --only=mani_overview,lhakhang_sw,mani_lane_w,mani_pitch,lhakhang_bell
        STILLS=1 HOUR=15.5 tools/player/s15.sh route wheel
Run: tools/py tools/town/mani_sheet.py   Writes tests/terrain/out/mani_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
WALK = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [(OUT, "s3_mani_overview", "1. The Mani Lane and its wall (SHL-09); the Lhakhang beyond"),
         (OUT, "s3_lhakhang_sw", "2. The Mani Lhakhang (SHL-08), its forecourt on the stair"),
         (WALK, "s15_wheel_01_forecourt", "3. Off the Sky Stair onto the forecourt"),
         (WALK, "s15_wheel_02_door", "4. In at the door, small wheels either side"),
         (WALK, "s15_wheel_03_wheel", "5. Pushing the great wheel round, clockwise"),
         (OUT, "s3_lhakhang_bell", "6. The hall: the wheel and the bell it strikes"),
         (OUT, "s3_mani_lane_w", "7. Up the Mani Lane, the wall on the right"),
         (OUT, "s3_mani_pitch", "8. Pasang's pitch (SHL-27) against the wall")]


def main():
    w, h, pad, cap, cols = 640, 360, 10, 30, 4
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The Mani Lhakhang, its great wheel, the barkor's mani wall and Pasang's pitch (sprint 4, step 3); the walk at 15:30.",
           font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label) in enumerate(SHOTS):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "mani_sheet.jpg")
    img.save(path, quality=86)
    print("mani_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
