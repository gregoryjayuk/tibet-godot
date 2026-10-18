#!/usr/bin/env python3
"""Life in the yards for Greg (IMP-023 (1) and (2); his 1775 and 1781): washing out to dry, parting round the walker, and
what each household keeps by its walls.
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=laundry_007,laundry_082,corners_002,corners_016,corners_040
        RETURN_FOCUS=0 STILLS=1 HOUR=14 tools/player/s15.sh route laundry   (through H-SHL-007's washing)
Run: tools/py tools/town/yards_life_sheet.py   Writes tests/terrain/out/yards_life_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
PLAYER = os.path.join(ROOT, "tests", "player", "out")
FONT_F = os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")
SHOTS = [(os.path.join(OUT, "s3_laundry_082.png"), "H-SHL-082's washing: robes and a monk's shirt along its yard"),
         (os.path.join(OUT, "s3_corners_040.png"), "H-SHL-040's: striped aprons and a cloth over its firewood"),
         (os.path.join(OUT, "s3_laundry_007.png"), "H-SHL-007's three robes, a son in the monastery"),
         (os.path.join(PLAYER, "s15_laundry_03_out.png"), "Walking through them, the robes swinging back"),
         (os.path.join(OUT, "s3_corners_016.png"), "H-SHL-016's firewood by its door"),
         (os.path.join(OUT, "s3_corners_002.png"), "H-SHL-002's carrying basket, wood in it, by its stair")]


def main():
    w, h, cap, pad = 900, 506, 34, 10
    f = ImageFont.truetype(FONT_F, 22)
    big = ImageFont.truetype(FONT_F, 26)
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 60 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 16), "Life in the yards (IMP-023): washing on a third of the households' lines, things by every household's walls", font=big, fill=(40, 30, 25))
    for i, (path, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 60 + (i // 2) * (h + cap + pad)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 5), label, font=f, fill=(40, 30, 25))
    path = os.path.join(OUT, "yards_life_sheet.jpg")
    img.save(path, quality=86)
    print("yards_life_sheet: %s" % path)


if __name__ == "__main__":
    main()
