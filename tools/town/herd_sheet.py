#!/usr/bin/env python3
"""CV-02's whole herd (M2 sprint 9, step 2; plan chapter 06, 8.4) on one page: the 62 behind the ten in file on the cliff
gallery, abreast past the eight chortens, turning at the south pavilion down the Caravan Ramp, round a switchback two
abreast, spread down the zigzags from above and from Hejie's side, off the ramp onto the Caravan Ground, and halting in a
block by the tea-case windbreaks (world/herd.gd; where it is when: tools/town/herd_probe.gd).
Its stills (in a window, a few minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=herd_gallery,herd_row,herd_pavilion,herd_switchback,herd_ramp_above,herd_from_hejie,herd_ramp_foot,herd_camp
Run: tools/py tools/town/herd_sheet.py   Writes tests/terrain/out/herd_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_herd_gallery", "13:25: in file on the cliff gallery, from across the slot", 1.0),
         ("s3_herd_row", "13:55: abreast past the eight chortens to the toll", 1.0),
         ("s3_herd_pavilion", "14:35: turning at the south pavilion down the ramp", 1.0),
         ("s3_herd_switchback", "15:12: round the second switchback, two abreast", 1.0),
         ("s3_herd_ramp_above", "15:15: spread down the zigzags of the ridge foot", 1.0),
         ("s3_herd_from_hejie", "15:20: a dark ribbon down the ridge foot", 1.0),
         ("s3_herd_ramp_foot", "16:05: off the ramp's last leg onto the camp", 1.1),
         ("s3_herd_camp", "16:40: halted in a block by the windbreaks, the hay brought", 1.1)]


def main():
    w, h, pad, cap = 640, 360, 8, 26
    cols = 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 50 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 12), "M2 sprint 9, step 2: CV-02's whole herd, the 62 behind the ten, from the cliff gallery down the Caravan Ramp to the camp.",
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
    out = os.path.join(TERRAIN, "herd_sheet.jpg")
    img.save(out, quality=88)
    print("herd_sheet:", out)


if __name__ == "__main__":
    main()
