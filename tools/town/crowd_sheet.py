#!/usr/bin/env python3
"""Shöl's full crowd and the default day (M2 sprint 10; plan chapter 05, 2.3-2.4, 7.2, 8.1-8.2) on one page: the day's
drawn through the day, from the women's queue at the spring before dawn and Tsongra as the day begins,
through Tsongra's market at 11:00 with its stalls, keepers and buyers on both levels and River Street on Hejie's market
day, to the kora at dusk, Tsongra after supper and the bard's ring in Dechen-tsang's yard.
Its stills (in a window, a few minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=spring_queue,crowd_morning,market_west,market_east,market_tsongra,market_stalls,market_wide,hejie_market,hejie_market_up,crowd_kora,crowd_evening,dechen_bard
Run: tools/py tools/town/crowd_sheet.py   Writes tests/terrain/out/crowd_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_spring_queue", "05:44: the women's queue at the Lukhang spring", 1.2),
         ("s3_crowd_morning", "06:20: the women for water at Tsongra's basin", 1.2),
         ("s3_market_west", "10:30: the upper market's west stalls", 1.0),
         ("s3_market_east", "10:30: its east row", 1.0),
         ("s3_market_tsongra", "11:00: Tsongra's market from its lower level", 1.0),
         ("s3_market_stalls", "11:00: along the lower market's stalls", 1.0),
         ("s3_market_wide", "11:00: the two markets from above", 1.0),
         ("s3_hejie_market", "11:00: River Street on Hejie's market day", 1.0),
         ("s3_hejie_market_up", "11:00: at the teahouse's bend", 1.0),
         ("s3_crowd_kora", "17:42: the kora at its busiest", 1.1),
         ("s3_crowd_evening", "19:15: Tsongra after supper", 1.3),
         ("s3_dechen_bard", "21:15: the bard's ring in Dechen-tsang's yard", 1.1)]


def main():
    w, h, pad, cap = 576, 324, 8, 26
    cols = 4
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 50 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 12), "M2 sprint 10: the day's drawn through the default day, the market at Tsongra and on River Street, the kora at dusk, the bard at night.",
           font=FONT, fill=(40, 30, 25))
    for i, (name, label, bright) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 50 + (i // cols) * (h + cap + pad)
        path = os.path.join(TERRAIN, name + ".png")
        if not os.path.exists(path):
            d.text((x, y + h // 2), "missing: " + name, font=FONT, fill=(160, 40, 30))
            continue
        im = Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS)
        if bright != 1.0:
            im = ImageEnhance.Brightness(im).enhance(bright)
        img.paste(im, (x, y))
        d.text((x, y + h + 3), label, font=FONT, fill=(40, 30, 25))
    out = os.path.join(TERRAIN, "crowd_sheet.jpg")
    img.save(out, quality=88)
    print("crowd_sheet:", out)


if __name__ == "__main__":
    main()
