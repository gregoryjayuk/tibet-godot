#!/usr/bin/env python3
"""Snow for Greg (IMP-021, item 4; his 1781, "I like the snow in this image too"): the weather's presets (world/day.gd
SNOW): a dusting down to 3,500 m after a cold night, the skyline white from Tsongra; the morning after a snowfall down
into the valley, the roofs, copings and steps white and the lanes trodden (beyond the design's calendar); and the snow
still falling.
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --snow=dust --only=tsongra_s,slice_v14
        RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --snow=town --only=yard_row8,upper_over,lane_011_up
        RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --snow=town --only=v28_dusk,tsongra_1600
        RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --snow=falling --only=lane_011_up,yard_row8
Run: tools/py tools/look/snow_sheet.py   Writes tests/look/out/snow_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "tests", "terrain", "out")
OUT = os.path.join(ROOT, "tests", "look", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
BIG = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 26)
SHOTS = [("tsongra_s_snow-dust", "Dust: down to 3,500 m after a cold night, from Tsongra"),
         ("slice_v14_snow-dust", "Dust: the skyline from the Sky Stair's top"),
         ("upper_over_snow-town", "The morning after a snowfall: the upper town"),
         ("yard_row8_snow-town", "Its yards trodden, the parapets capped"),
         ("lane_011_up_snow-town", "A lane's stair, its treads trodden"),
         ("tsongra_1600_snow-town", "Tsongra at 16:00"),
         ("v28_dusk_snow-town", "V-28 at dusk: the sang's smoke, the lamps"),
         ("lane_011_up_snow-falling", "Still falling: between the walls"),
         ("yard_row8_snow-falling", "Still falling: the far side hazed")]


def main():
    w, h, pad, cap, cols = 900, 506, 10, 30, 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 60 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Snow (IMP-021): SNOW=dust, SNOW=town, SNOW=falling (world/day.gd); the season's own lies above 4,300 m",
           font=BIG, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 60 + (i // cols) * (h + cap + pad)
        path = os.path.join(SRC, "s3_%s.png" % name)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, "snow_sheet.jpg")
    img.save(path, quality=86)
    print("snow_sheet: %s %s" % (path, img.size))


if __name__ == "__main__":
    main()
