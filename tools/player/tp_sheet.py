#!/usr/bin/env python3
"""Lay out the third-person player's stills (tests/player/out/, tools/player/tp.sh) on one sheet for Greg.
Run: tools/py tools/player/tp_sheet.py   Writes tests/player/out/tp_sheet.jpg.
"""
import glob
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 22)
LABELS = {"idle": "Standing", "walk": "Walking away, 1.5 m/s", "turn_walk": "Turned left, walking", "run": "Jogging, 4.5 m/s (the default)",
          "sprint": "Sprinting, 7 m/s (Shift held, the controller's cross)", "woman_sprint": "The woman, sprinting",
          "towards_camera": "Walking towards the camera", "woman_walk": "The woman (B), walking", "woman_run": "The woman, jogging",
          "woman_towards_camera": "The woman, towards the camera", "wall": "A wall behind: the arm shortens",
          "first_person": "First person (V)", "woman_front": "The woman from the front", "man_front": "The man from the front", "man_sits": "C: sitting on a step (time runs 60:1)",
          "winded_pad": "Winded after a sprint: the vignette, back to the jog; the controller's help line"}


def main():
    files = sorted(glob.glob(os.path.join(OUT, "tp_*.png")), key=lambda f: int(os.path.basename(f).split("_")[1]))
    w, h, pad, cap, cols = 640, 360, 10, 34, 5
    rows = (len(files) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The player in third person on the kit street (M1 sprint 2, step 4): MPFB bodies in Kham travelling dress (chapter 05, DS-01 and DS-02).", font=FONT, fill=(40, 30, 25))
    for i, f in enumerate(files):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(f).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        key = os.path.basename(f)[:-4].split("_", 2)[2]
        d.text((x, y + h + 4), LABELS.get(key, key), font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "tp_sheet.jpg")
    img.save(path, quality=86)
    print("tp_sheet: " + path)


if __name__ == "__main__":
    main()
