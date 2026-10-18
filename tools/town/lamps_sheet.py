#!/usr/bin/env python3
"""The lamps at dusk for Greg (IMP-021 (3), after his 1770: warm points of light against the blue): the Mani Lhakhang's altar
lit from 17:00, the fire in Dechen-tsang's yard for the evening, the embers in the roofs' burners, the tunnel's lamp.
Stills: RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=lamps_lhakhang,lamps_yard,lamps_sang,lamps_tunnel
Run: tools/py tools/town/lamps_sheet.py   Writes tests/terrain/out/lamps_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT_F = os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")
SHOTS = [("s3_lamps_lhakhang.png", "17:51, the Mani Lhakhang: its altar lit from 17:00, warm through its door"),
         ("s3_lamps_yard.png", "18:40, Dechen-tsang's front yard: the evening's fire, for dice and the Gesar bard"),
         ("s3_lamps_sang.png", "17:36, the master roof's burner: an ember under the juniper's smoke"),
         ("s3_lamps_tunnel.png", "19:00, the tunnel under three houses on the Sky Stair: the lamp in its niche")]


def main():
    w, h, cap, pad = 900, 506, 34, 10
    f = ImageFont.truetype(FONT_F, 22)
    big = ImageFont.truetype(FONT_F, 26)
    rows = (len(SHOTS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 60 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 16), "Lamps at dusk (IMP-021 (3)): the altar, the yard's fire, the burners' embers, the tunnel's niche", font=big, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % 2) * (w + pad)
        y = 60 + (i // 2) * (h + cap + pad)
        path = os.path.join(OUT, name)
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 5), label, font=f, fill=(40, 30, 25))
    path = os.path.join(OUT, "lamps_sheet.jpg")
    img.save(path, quality=86)
    print("lamps_sheet: %s" % path)


if __name__ == "__main__":
    main()
