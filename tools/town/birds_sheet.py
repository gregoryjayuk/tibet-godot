#!/usr/bin/env python3
"""The town's birds for Greg (sprint 8, step 2; world/birds.gd): each still beside the part of it where the birds are,
at twice its size (they are as small in the frame as birds are: a pigeon 35 m off is a few pixels).
Stills: TIMEOUT=300 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=birds_pigeons,birds_tsongra,birds_close,birds_ritro
Run: tools/py tools/town/birds_sheet.py   Writes tests/terrain/out/birds_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
# still, the middle of its birds in the 1920 x 1080 frame, its caption
SHOTS = [("s3_birds_pigeons", (1090, 460), "From Tsongra at 14:00: a flock of hill pigeons wheeling over the square, 15-25 m over the roofs"),
         ("s3_birds_tsongra", (1080, 480), "From Tsongra: three choughs over Shöl's roofs, rising with the slope"),
         ("s3_birds_close", (960, 540), "A chough 15 m off, banking in its turn"),
         ("s3_birds_ritro", (940, 520), "The ritro flock along the cliff, 90 m out from the Guru's cave")]


def main():
    w, h, side, pad, cap = 960, 540, 540, 10, 32
    img = Image.new("RGB", (pad + w + pad + side + pad, 56 + len(SHOTS) * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The town's birds (sprint 8, step 2): each flock its own; right, the birds at twice the size.", font=FONT, fill=(40, 30, 25))
    for i, (name, (cx, cy), label) in enumerate(SHOTS):
        y = 56 + i * (h + cap + pad)
        full = Image.open(os.path.join(OUT, name + ".png")).convert("RGB")
        img.paste(full.resize((w, h), Image.LANCZOS), (pad, y))
        half = side // 4  # a 270 px square of the full frame, doubled
        box = (max(cx - half, 0), max(cy - half, 0), max(cx - half, 0) + 2 * half, max(cy - half, 0) + 2 * half)
        img.paste(full.crop(box).resize((side, side), Image.LANCZOS), (pad + w + pad, y))
        d.rectangle([pad + box[0] // 2, y + box[1] // 2, pad + box[2] // 2, y + box[3] // 2], outline=(200, 40, 30), width=2)
        d.text((pad, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "birds_sheet.jpg")
    img.save(path, quality=88)
    print("birds_sheet: %s" % path)


if __name__ == "__main__":
    main()
