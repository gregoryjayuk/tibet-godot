#!/usr/bin/env python3
"""The plank-and-rope bridge over the Sky Stair for Greg (IMP-023 (3); his 1773: "a cool view behind the player as they run
across an old bridge joining 2 parts of town (or just buildings)").
Stills: RETURN_FOCUS=0 TIMEOUT=400 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --hour=15 --only=bridge_from_stair,bridge_side; the crossings (IMP-027) at their own hours: TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=bridge_crossing_near,bridge_crossing_up
        RETURN_FOCUS=0 ROUTE_RUN=1 STILLS=1 HOUR=15 tools/player/s15.sh route bridge   (up the east ladder, across at a run, down the west plank)
Run: tools/py tools/town/bridge_sheet.py   Writes tests/terrain/out/bridge_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
PLAYER = os.path.join(ROOT, "tests", "player", "out")
FONT_F = os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")
SHOTS = [(os.path.join(OUT, "s3_bridge_from_stair.png"), "From the Sky Stair: the bridge across it, 4 m and more over the pilgrims"),
         (os.path.join(OUT, "s3_bridge_side.png"), "From the stair's east side: H-SHL-080's roof to H-SHL-061's, 22 m"),
         (os.path.join(PLAYER, "s15_bridge_01_climb.png"), "Up the ladder on H-SHL-080's wall, as at the far end of 1773's bridge"),
         (os.path.join(PLAYER, "s15_bridge_03_bridge_30.png"), "Across at a run, the Sky Stair climbing beside it below"),
         (os.path.join(PLAYER, "s15_bridge_04_bridge_62.png"), "Old planks a hand apart, the town falling away"),
         (os.path.join(PLAYER, "s15_bridge_05_far_roof.png"), "Onto H-SHL-061's roof between its posts; its plank down to the lane"),
         (os.path.join(OUT, "s3_bridge_crossing_near.png"), "14:31, from H-SHL-061's roof: a neighbour stopped half way, looking down at the stair"),
         (os.path.join(OUT, "s3_bridge_crossing_up.png"), "15:26, from the stair: an old man half way across, over the pilgrims")]


def main():
    w, h, cap, pad = 900, 506, 34, 10
    f = ImageFont.truetype(FONT_F, 22)
    big = ImageFont.truetype(FONT_F, 26)
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 60 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 16), "A plank-and-rope bridge over the Sky Stair (IMP-023 (3), after 1773): upper Shöl's two halves joined", font=big, fill=(40, 30, 25))
    for i, (path, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 60 + (i // 2) * (h + cap + pad)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 5), label, font=f, fill=(40, 30, 25))
    path = os.path.join(OUT, "bridge_sheet.jpg")
    img.save(path, quality=86)
    print("bridge_sheet: %s" % path)


if __name__ == "__main__":
    main()
