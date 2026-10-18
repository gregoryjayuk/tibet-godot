#!/usr/bin/env python3
"""The dawn horns, V-05a, for Greg (M3 sprint 6, step 5; plan chapter 08, V-05a; world/horns.gd): the novice waiting by the
ladder-stair's head on the Tsokchen's roof terrace in the dark, the two horn players in their yellow crested hats lifting
the dung chen at 05:30 and blowing over the parapet towards the town (its echo off the western ridge 27 s later), and the
gilded roof's first sun at 07:22 over the town still blue in the ridges' shadow.
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=v05a_novice,v05a_players,v05a_horns,v05a_sun,v05a_town
Run: tools/py tools/town/horns_sheet.py   Writes tests/terrain/out/horns_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT_F = os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")
SHOTS = [("s3_v05a_novice.png", "05:27: the novice who led the way up waits by the ladder-stair's head"),
         ("s3_v05a_players.png", "05:31: the two players blow the dung chen, the bells over the parapet towards the town"),
         ("s3_v05a_horns.png", "05:31: behind them, the valley still dark; the call comes back off the western ridge 27 s later"),
         ("s3_v05a_sun.png", "07:24: the gilded roof over the inner chapel in its first sun (07:22)"),
         ("s3_v05a_town.png", "07:24: the town below still blue in the ridges' shadow")]


def main():
    w, h, cap, pad = 900, 506, 34, 10
    f = ImageFont.truetype(FONT_F, 20)
    big = ImageFont.truetype(FONT_F, 26)
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 60 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 16), "V-05a, the dawn horns on the Tsokchen's roof (M3 sprint 6, step 5)", font=big, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 60 + (i // 2) * (h + cap + pad)
        path = os.path.join(OUT, name)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 5), label, font=f, fill=(40, 30, 25))
    path = os.path.join(OUT, "horns_sheet.jpg")
    img.save(path, quality=86)
    print("horns_sheet: %s" % path)


if __name__ == "__main__":
    main()
