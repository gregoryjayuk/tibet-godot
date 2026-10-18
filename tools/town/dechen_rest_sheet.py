#!/usr/bin/env python3
"""The rest of Dechen-tsang (M2 sprint 8; plan chapter 04, 4.3) on one page: Yard 3 with the chapel up its stone stair
and Dolkar's range with its gallery, the chapel's White Tara and its household lama at his reading, her reception room
with its brocade and its five French clocks and Dolkar winding one at dusk, the house's day in Yard 1 (the tea-sewers,
the pieman's dice, the steward out with the tea money), and its night (the chapel's window lit, the bard by the fire in
the guest yard, the gate barred under its lantern).
Its stills (in a window, a few minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=dechen_garden_n,dechen_garden_s,dechen_gallery,dechen_chapel_in,dechen_lama_reading,dechen_dolkar_in,dechen_clocks,dechen_dolkar_clock,dechen_sewers,dechen_dice,dechen_steward_gate,dechen_garden_night,dechen_bard,dechen_mastiffs
Run: tools/py tools/town/dechen_rest_sheet.py   Writes tests/terrain/out/dechen_rest_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_dechen_garden_n", "15:00: Yard 3, the chapel up its stone stair", 1.0),
         ("s3_dechen_garden_s", "15:00: Dolkar's range, its gallery and timber stair", 1.0),
         ("s3_dechen_gallery", "15:00: along her gallery to her door", 1.0),
         ("s3_dechen_chapel_in", "The chapel: White Tara, the lamps, the bowls", 1.0),
         ("s3_dechen_lama_reading", "06:40: the household lama at his reading", 1.1),
         ("s3_dechen_dolkar_in", "Her reception room: brocade, carpets three deep", 1.0),
         ("s3_dechen_clocks", "The five French clocks, none going", 1.0),
         ("s3_dechen_dolkar_clock", "17:28: Dolkar winds the one that ticks for an hour", 1.1),
         ("s3_dechen_sewers", "09:00: the tea-sewers under Yard 1's gallery", 1.1),
         ("s3_dechen_dice", "10:30: the pieman and the dice by the gate", 1.0),
         ("s3_dechen_steward_gate", "10:03: a servant after the steward with the tea money", 1.0),
         ("s3_dechen_garden_night", "20:30: the chapel's window lit", 1.3),
         ("s3_dechen_bard", "21:15: the bard by the fire in the guest yard", 1.1),
         ("s3_dechen_mastiffs", "22:30: the gate barred, its lantern, the dogs loose", 1.3)]


def main():
    w, h, pad, cap = 640, 360, 8, 26
    cols = 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 50 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 12), "M2 sprint 8, the rest of Dechen-tsang: Yard 3, the chapel and Dolkar's reception room, the house's day and its night.",
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
    out = os.path.join(TERRAIN, "dechen_rest_sheet.jpg")
    img.save(out, quality=88)
    print("dechen_rest_sheet:", out)


if __name__ == "__main__":
    main()
