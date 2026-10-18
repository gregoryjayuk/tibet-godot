#!/usr/bin/env python3
"""The Gönkor R-10 whole, M3 sprint 7, step 1 on one page (ISS-204; chapter 02, R-10: "round the monastery wall ... a 40 m
timber gallery on the gorge face; monks, pilgrims; clockwise"; tools/town/gonkor.py, docs/town/gonkor-report.md): the face's
way onto its timber gallery under the stacked monks' houses, the gallery from over the gorge, its steps up onto the Gorge
Stair's landing 23, the way from the south into the 1,080 steps' landing 20, round the spur's south-west corner, up the east
side outside the wall past the tsa-tsa house MON-24 to the great wheel house MON-23, behind the Labrang and round the
wall's west end.
Its stills (in a window, some ten minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=gonkor_face_gallery,gonkor_gallery_out,gonkor_l23,gonkor_steps,gonkor_sw,gonkor_east,gonkor_tsatsa,gonkor_east_above,mon23_front,mon23_in,gonkor_north,gonkor_corner
Run: tools/py tools/town/gonkor_sheet.py   Writes tests/terrain/out/gonkor_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_gonkor_face_gallery", "Along the face's way north onto its timber gallery, under the stacked monks' houses"),
         ("s3_gonkor_gallery_out", "The gallery on the gorge face from out over the gorge: half cut in, half on its beams"),
         ("s3_gonkor_l23", "Its north end: steps up onto the Gorge Stair's landing 23, the stair on up to the West Gate"),
         ("s3_gonkor_steps", "From the south along the face into the gap in the 1,080 steps' landing 20"),
         ("s3_gonkor_sw", "Round the spur's south-west corner to the south stretch's west end"),
         ("s3_gonkor_east", "Up the east side outside the wall, its flights broken by landings"),
         ("s3_gonkor_tsatsa", "The tsa-tsa house MON-24 beside the way, its window stacked with clay tsa-tsas"),
         ("s3_gonkor_east_above", "The east side from above: the way outside the wall, the great wheel house on it"),
         ("s3_mon23_front", "The great wheel house MON-23, out on the circuit, its door onto the way"),
         ("s3_mon23_in", "Inside it: the 3.5 m wheel walked round, its bell"),
         ("s3_gonkor_north", "Behind the Labrang: down the north side's flights along the wall"),
         ("s3_gonkor_corner", "Round the wall's west end on the gorge's rim, down towards the West Gate")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The Gönkor whole (M3 sprint 7, step 1): 1.26 km round the monastery, clockwise; its gallery on the gorge face.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        path = os.path.join(TERRAIN, name + ".png")
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "gonkor_sheet.jpg")
    img.save(path, quality=86)
    print("gonkor_sheet: %s" % path)


if __name__ == "__main__":
    main()
