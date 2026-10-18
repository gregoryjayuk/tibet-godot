#!/usr/bin/env python3
"""The camp at dusk (M2 sprint 9, step 3; plan chapter 06, 8.6) on one page: CV-02 unloaded where it halted by its
windbreaks, then at the hay and lying down in twos and threes, the two crews' black tents, the picket line's mules and
ponies with a mastiff at its end, the Caravan Ground at dusk from the ramp, a crew's dung fire and its drovers, the camp's
fires at night, and CV-01's yak at their hay at noon (world/herd.gd, world/camp_animals.gd, world/camp.gd).
Its stills (in a window, a few minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=camp_unloading,camp_hay,camp_tents,camp_picket,camp_dusk,camp_fire,camp_night,camp_cv01
Run: tools/py tools/town/camp_dusk_sheet.py   Writes tests/terrain/out/camp_dusk_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_camp_unloading", "16:25: CV-02 unloaded where it halted", 1.15),
         ("s3_camp_hay", "17:05: at the hay, lying down in twos and threes", 1.15),
         ("s3_camp_tents", "17:20: the two crews' black tents", 1.15),
         ("s3_camp_picket", "17:30: the picket line, a mastiff at its end", 1.15),
         ("s3_camp_dusk", "17:40: the Caravan Ground at dusk", 1.1),
         ("s3_camp_fire", "18:30: a crew's dung fire by the windbreak", 1.0),
         ("s3_camp_night", "21:00: the camp's six fires in the dark", 1.0),
         ("s3_camp_cv01", "12:30: CV-01's yak at their hay by their wool", 1.0)]


def main():
    w, h, pad, cap = 640, 360, 8, 26
    cols = 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 50 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 12), "M2 sprint 9, step 3: the camp at dusk, CV-02 unloaded and to the hay, the tents, the picket line, the fires, CV-01's yak.",
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
    out = os.path.join(TERRAIN, "camp_dusk_sheet.jpg")
    img.save(out, quality=88)
    print("camp_dusk_sheet:", out)


if __name__ == "__main__":
    main()
