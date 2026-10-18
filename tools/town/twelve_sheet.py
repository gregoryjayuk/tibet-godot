#!/usr/bin/env python3
"""Lay out the slice's twelve generic people for Greg (sprint 6, step 4): the twelve in a line in the game's light, front
and back (tools/people/face.sh), then each at a place and hour its day has it (tests/terrain/s3.gd's NAMED_SHOTS), and
Tsongra at 16:00 and 16:10 with all twenty, captioned, in reading order.
Stills: tools/people/face.sh stall_man,stall_woman,porter,porter_woman,elder_man,elder_woman,boy,girl,drover,drover_b,nomad_woman,han_man
        RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people
        --only=generic_knucklebones,generic_elders,generic_stalls,generic_porter,generic_barkor,generic_clerk,tsongra_1600,tsongra_1610
Run: tools/py tools/town/twelve_sheet.py   Writes tests/terrain/out/twelve_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
PEOPLE = os.path.join(ROOT, "tests", "people", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
LINE = [("face_line_front", "The twelve: two stallholders, two porters, two elders, a boy, a girl, two drovers, a nomad woman, a Han clerk"),
        ("face_line_back", "and from behind: the porters' bales of tea, a drover's matchlock, the girl's plaits")]
SHOTS = [("s3_generic_porter", "08:45, a porter with tea at the west stall, Kalsang behind it"),
         ("s3_generic_stalls", "10:00, Nyima's mother at her stall"),
         ("s3_generic_knucklebones", "12:00, Nyima's band at knucklebones on the steps"),
         ("s3_generic_clerk", "12:10, a Han clerk from Hejie at the east stall"),
         ("s3_generic_barkor", "15:18, an old woman round the mani wall"),
         ("s3_generic_elders", "16:42, an old man beside Sönam on the steps"),
         ("s3_tsongra_1600", "16:00, Tsongra from its lower level, the twenty about it"),
         ("s3_tsongra_1610", "16:10, the ridge's shadow over the square")]


def main():
    w, h, pad, cap, cols = 640, 360, 10, 30, 3
    lw, lh = cols * w + (cols - 1) * pad, 300
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + 2 * (lh + cap + pad) + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The slice's twelve generic people (sprint 6, step 4): each on a day, among the named eight.", font=FONT, fill=(40, 30, 25))
    y = 56
    for name, label in LINE:  # the line, cropped round the figures and enlarged
        im = Image.open(os.path.join(PEOPLE, name + ".png")).convert("RGB").crop((560, 470, 1360, 670))
        img.paste(im.resize((lw, lh), Image.LANCZOS), (pad, y))
        d.text((pad, y + lh + 4), label, font=FONT, fill=(40, 30, 25))
        y += lh + cap + pad
    for i, (name, label) in enumerate(SHOTS):
        x, yy = pad + (i % cols) * (w + pad), y + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, yy))
        d.text((x, yy + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "twelve_sheet.jpg")
    img.save(path, quality=86)
    print("twelve_sheet: %d stills -> %s" % (len(SHOTS) + len(LINE), path))


if __name__ == "__main__":
    main()
