#!/usr/bin/env python3
"""V-13a, Dungri Karpo in the notch (M2 sprint 6, step 5; plan chapter 08, V-13a; chapter 02, 2.7 and 2.8): the town's
god raised into the ring at 5,420 m, 12.7 km from the Gorge Rim Lookout in the real gorge's notch (032.5 degrees), at the
normal lens from the terrace's tip, in the viewpoint's frame (sit with C: the camera drifts out to 14 degrees on the
notch), and its alpenglow from 17:00 to the summit's last sun at 17:17.
Stills: RETURN_FOCUS=0 TIMEOUT=700 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=v13a_wide,v13a_1700,v13a_1708,v13a_1713,v13a_1717
and the viewpoint's: RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh route viewpoints (tests/player/out/s15_viewpoint_v13a.png)
Run: tools/py tools/town/v13a_sheet.py   Writes tests/terrain/out/v13a_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
PLAYER = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [(TERRAIN, "s3_v13a_wide", "17:08 from the terrace's tip: the gorge's V, the peak in it, the town gone blue"),
         (PLAYER, "s15_viewpoint_v13a", "Sat at the tip (C): the camera drifts out to the notch, 14 degrees"),
         (TERRAIN, "s3_v13a_1700", "17:00: Dungri Karpo white in the notch, 12.7 km off, 11.7 degrees up"),
         (TERRAIN, "s3_v13a_1708", "17:08: the snow taking the low sun"),
         (TERRAIN, "s3_v13a_1713", "17:13: pink, the last three degrees of the sun"),
         (TERRAIN, "s3_v13a_1717", "17:17: the pink gone from the summit, its last sun by its rays")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "V-13a, Dungri Karpo in the notch (M2 sprint 6, step 5): the town's god from the Gorge Rim Lookout at dusk.", font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "v13a_sheet.jpg")
    img.save(path, quality=88)
    print("v13a_sheet: %s" % path)


if __name__ == "__main__":
    main()
