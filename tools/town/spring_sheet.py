#!/usr/bin/env python3
"""The Lukhang spring SHL-14 (M2 sprint 6, step 3; plan chapter 02: "yard 12 x 8, women with barrels at dawn, drinking
water for Shöl; no washing at the spring"; chapter 03's naga shrine; chapter 05, A-47 and A-10): the queue at first
light, the milk on the naga's rock, the afternoon's trips and the talk behind the queue, the klu khang's niche, the yard
cut into the slope, the path up to it.
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=spring_queue,spring_milk,spring_afternoon,spring_shrine,spring_above,spring_path
Run: tools/py tools/town/spring_sheet.py   Writes tests/terrain/out/spring_sheet.jpg (the two before sunrise brightened 2x to be read).
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_spring_queue", "05:44, first light (brightened): two filling at the spouts, three in the line with their barrels", 2.0),
         ("s3_spring_milk", "06:00 (brightened): the old woman's milk on the naga's rock, the talk behind the queue", 2.0),
         ("s3_spring_afternoon", "15:44: the afternoon's trips, one at a spout, the others talking before going down", 1.0),
         ("s3_spring_shrine", "The klu khang: its niche blue-green inside, milk and grain, a khatag; the spouts below", 1.0),
         ("s3_spring_above", "The yard at 2,775 m cut into the slope at upper Shöl's top, its walls, flags from its pole", 1.0),
         ("s3_spring_path", "Up the path to it from upper Shöl's lanes, a barrel on her back", 1.0)]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The Lukhang spring SHL-14 (M2 sprint 6, step 3): the naga's spring, the women's queue with their barrels.", font=FONT, fill=(40, 30, 25))
    for i, (name, label, bright) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        im = Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS)
        if bright != 1.0:
            im = ImageEnhance.Brightness(im).enhance(bright)
        img.paste(im, (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "spring_sheet.jpg")
    img.save(path, quality=88)
    print("spring_sheet: %s" % path)


if __name__ == "__main__":
    main()
