#!/usr/bin/env python3
"""Lay spike S3's five stills on one captioned sheet for Greg: tests/terrain/out/sheet.png.
Run with the project's Python after tools/terrain/s3.sh shots:  tools/py tools/terrain/s3_sheet.py
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 22)
SHOTS = [("s3_tsongra_ne.png", "Tsongra, looking up the Dungchu gorge (040°)"),
         ("s3_tsongra_w.png", "Tsongra, looking west (265°)"),
         ("s3_tsongra_s.png", "Tsongra, looking south (175°)"),
         ("s3_pharkha_e.png", "Pharkha stand-in, looking back east (080°)"),
         ("s3_high_sw.png", "40 m above the spur, looking down the valley (225°)")]
NOTE = ("The designed valley on the real ground (tools/terrain/build.sh, 25 Sep 2026):\nchapter 02 sculpted on Copernicus 30 m resampled to 1 m, the horizons\nshaped only near the valley (Greg kept the real mountains), and a level pad\nunder every placed building: the flat plateaus are where the kit's houses\nwill stand. The slot's and the gorge's rock walls are still the heightfield's\n(rock meshes come with chapter 11, 8.3). Terrain3D 1.0.2 on Metal: 150\nregions of 256 m, clipmap 32; the ring to 15 km is one mesh. Colour by\nslope, aspect and altitude is a first cut (art step A9).")


def main():
    w, h = 960, 540
    sheet = Image.new("RGB", (2 * w + 30, 3 * (h + 40) + 10), (250, 248, 243))
    d = ImageDraw.Draw(sheet)
    for k, (name, caption) in enumerate(SHOTS):
        im = Image.open(os.path.join(OUT, name)).convert("RGB").resize((w, h), Image.LANCZOS)
        x, y = 10 + (k % 2) * (w + 10), 10 + (k // 2) * (h + 40)
        sheet.paste(im, (x, y))
        d.text((x, y + h + 6), caption, font=FONT, fill=(40, 30, 25))
    d.text((20 + w, 10 + 2 * (h + 40) + 20), NOTE, font=FONT, fill=(40, 30, 25))
    sheet.save(os.path.join(OUT, "sheet.png"))
    print("s3_sheet: " + os.path.join(OUT, "sheet.png"))


if __name__ == "__main__":
    main()
