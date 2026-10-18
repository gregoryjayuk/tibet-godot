#!/usr/bin/env python3
"""The Caravan Ramp and the Caravan Ground (M2 sprint 9, step 1; plan chapter 02, D02 and R-03; chapter 06, 7.1 and 8.6)
on one page: the ramp's head past the south pavilion, a switchback's landing, its six legs down the ridge foot's face
from above and from the camp, the camp from the ramp at 16:00, CV-02's tea stacked into windbreaks and its hay, the
fodder yard GAR-13, the dung-drying walls GAR-07, CV-01's wool at noon; and the route `camp`'s stills down the ramp.
Its stills (in a window, a few minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=700 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=camp_ramp_head,camp_landing,camp_ramp_above,camp_from_field,camp_overview,camp_windbreaks,camp_fodder,camp_dung,camp_wool
Run: tools/py tools/town/camp_sheet.py   Writes tests/terrain/out/camp_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_camp_ramp_head", "15:00: the Caravan Ramp's head past the south pavilion", 1.0),
         ("s3_camp_landing", "15:00: a switchback's landing, its two legs parting", 1.0),
         ("s3_camp_ramp_above", "15:00: six legs, five switchbacks down the ridge foot", 1.0),
         ("s3_camp_from_field", "15:00: the ramp's legs from the camp", 1.0),
         ("s3_camp_overview", "15:50: the Caravan Ground from the fifth leg", 1.1),
         ("s3_camp_windbreaks", "15:50: CV-02's tea stacked into windbreaks, its hay", 1.1),
         ("s3_camp_fodder", "15:00: the fodder yard GAR-13 from the ramp's foot", 1.0),
         ("s3_camp_dung", "15:00: the dung-drying walls GAR-07", 1.0),
         ("s3_camp_wool", "12:00: CV-01's wool by the black tents' place", 1.0)]


def main():
    w, h, pad, cap = 640, 360, 8, 26
    cols = 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 50 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 12), "M2 sprint 9, step 1: the Caravan Ramp's six legs and five switchbacks down to the Caravan Ground, its windbreaks, fodder yard and dung walls.",
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
    out = os.path.join(TERRAIN, "camp_sheet.jpg")
    img.save(out, quality=88)
    print("camp_sheet:", out)


if __name__ == "__main__":
    main()
