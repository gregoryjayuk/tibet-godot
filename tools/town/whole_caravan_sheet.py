#!/usr/bin/env python3
"""The whole caravan, its camp and Hejie at a distance (M2 sprint 9; plan chapter 06, 8.4 and 8.6; chapter 02, D02 and
D03) on one page: CV-02's 62 yak in file on the cliff gallery, abreast past the eight chortens and down the Caravan
Ramp's switchbacks, halted in a block by the windbreaks of tea, unloaded and to the hay or lying down in twos and
threes, the crews' black tents, the camp at dusk and its six fires at night; and Hejie beside it, up River Street from
the Water Gate, the Guandi temple, the grey town at dusk, and the town and the camp from Pharkha's bluff.
Its stills (in a window, a few minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=herd_gallery,herd_row,herd_switchback,camp_ramp_above,camp_unloading,herd_camp,camp_hay,camp_tents,camp_dusk,camp_fire,camp_night,hejie_v15,hejie_temple,hejie_dusk,hejie_v03
Run: tools/py tools/town/whole_caravan_sheet.py   Writes tests/terrain/out/whole_caravan_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_herd_gallery", "13:25: CV-02's 62 in file on the cliff gallery", 1.0),
         ("s3_herd_row", "13:55: abreast past the eight chortens", 1.0),
         ("s3_herd_switchback", "15:12: two abreast round a switchback", 1.0),
         ("s3_camp_ramp_above", "15:00: the Caravan Ramp's six legs from above", 1.0),
         ("s3_camp_unloading", "16:25: the block forming by the windbreaks, the first unloaded", 1.15),
         ("s3_herd_camp", "16:40: unloaded, walking to the hay", 1.0),
         ("s3_camp_hay", "17:05: at the hay, lying down in twos and threes", 1.15),
         ("s3_camp_tents", "17:20: the two crews' black tents", 1.15),
         ("s3_camp_dusk", "17:40: the Caravan Ground at dusk", 1.1),
         ("s3_camp_fire", "18:30: a crew's dung fire by the windbreak", 1.0),
         ("s3_camp_night", "21:00: the camp's six fires in the dark", 1.0),
         ("s3_hejie_v15", "16:30, V-15: up River Street from the Water Gate", 1.0),
         ("s3_hejie_temple", "15:30: the Guandi temple's courtyard and hall", 1.0),
         ("s3_hejie_dusk", "18:20: Hejie at dusk, the camp's fires beyond", 1.1),
         ("s3_hejie_v03", "15:00, V-03: Hejie and the camp from Pharkha", 1.0)]


def main():
    w, h, pad, cap = 640, 360, 8, 26
    cols = 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 50 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 12), "M2 sprint 9: the whole caravan down the Caravan Ramp, its camp from the halt to the night's fires, and Hejie beside it.",
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
    out = os.path.join(TERRAIN, "whole_caravan_sheet.jpg")
    img.save(out, quality=88)
    print("whole_caravan_sheet:", out)


if __name__ == "__main__":
    main()
