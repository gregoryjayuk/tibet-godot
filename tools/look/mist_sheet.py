#!/usr/bin/env python3
"""The valley's mist and the low sun's rays for Greg (IMP-021, after his inspiration of 7 Oct 2026; chapter 09, 9.3;
world/day.gd mist_at, shaders/ink_air.gdshader): the dawn's river mist from V-28 and as it lifts from the top of the
Sky Stair; the mist sea's dawn (one in four, chapter 08's V-22) from the same two places; the evening's haze; the sun
low over the western ridge.
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=mist_v28,mist_v14,rays_v28,haze_v28
   and the same with --mist=sea --only=mist_v28,mist_v14 (written as *_sea.png).
Run: tools/py tools/look/mist_sheet.py   Writes tests/look/out/mist_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHOTS_DIR = os.path.join(ROOT, "tests", "terrain", "out")
OUT = os.path.join(ROOT, "tests", "look", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_mist_v28", "06:45 from V-28: the dawn's river mist in the valley below the town"),
         ("s3_mist_v28_sea", "06:45, the mist sea's dawn (one in four): Tsongra under it, the upper town above"),
         ("s3_mist_v14", "07:10 from the top of the Sky Stair: the river mist lifting"),
         ("s3_mist_v14_sea", "07:10, the mist sea from the top of the Sky Stair"),
         ("s3_rays_v28", "16:05 from V-28: the sun low over the western ridge, its light through the haze"),
         ("s3_haze_v28", "18:00 from V-28: the evening's haze gathering in the valley's bottom")]


def main():
    os.makedirs(OUT, exist_ok=True)
    w, h, pad, cap = 960, 540, 10, 30
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The valley's mist and the low sun (IMP-021): a layer under a lobed top at any distance, lit where the sun reaches it.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 56 + (i // 2) * (h + cap + pad)
        path = os.path.join(SHOTS_DIR, name + ".png")
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "mist_sheet.jpg")
    img.save(path, quality=88)
    print("mist_sheet: %s" % path)


if __name__ == "__main__":
    main()
