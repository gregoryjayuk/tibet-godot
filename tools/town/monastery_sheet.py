#!/usr/bin/env python3
"""Dungkar Gönpa on the spur, M2 sprint 13 on one page (chapter 12's M2: "kit K9 in part (types M1 and M2 at L1/L2, so the
spur reads from V-01)"; acceptance 1, "turn right and up to the monastery face 27 degrees above"; chapter 02, D08; chapter
03, 6.1-6.9): the monks' houses stacked up the west face and round the south flank, the khamtsen between their ranges, the
halls at their far form with the three gilded roofs, the wall MON-21, from V-01, the Lookout, Tsongra, the Serchu road and
close.
Its stills (in a window, some five minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=700 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --only=mon_v01,mon_from_lookout,mon_face_close,mon_south_flank,mon_wall_south,mon_courtyard,mon_east_gate,mon_upper_gate,mon_from_tsongra,mon_from_road
Run: tools/py tools/town/monastery_sheet.py   Writes tests/terrain/out/monastery_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_mon_v01", "Acceptance 1: out of the Gate Chorten (V-01), turned to the face at 052, 27 degrees up"),
         ("s3_mon_from_lookout", "From the Gorge Rim Lookout across the gorge: the monks' houses stacked up the west face"),
         ("s3_mon_face_close", "The west face close: the M1 on their podia, row over row, the halls above"),
         ("s3_mon_south_flank", "Over the south flank: the khamtsen between their ranges, the M2 and their yards, the chapels, the Labrang"),
         ("s3_mon_wall_south", "The wall MON-21's south run, whitewashed with its red coping, the khamtsen's ranges over it"),
         ("s3_mon_courtyard", "In the courtyard MON-02 before the Tsokchen (AT=gonpa)"),
         ("s3_mon_east_gate", "The East Gate's range from the Yak Road's side, the wall meeting its ends"),
         ("s3_mon_upper_gate", "The Upper Gate's door in the wall's north run; the Labrang's gilded roof"),
         ("s3_mon_from_tsongra", "From Tsongra: the monastery over the town"),
         ("s3_mon_from_road", "From R-01 by the mills: the south flank's rows over the north bank")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Dungkar Gönpa on the spur (M2 sprint 13): the monks' houses, the khamtsen, the halls at their far form, the wall.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "monastery_sheet.jpg")
    img.save(path, quality=86)
    print("monastery_sheet: %s" % path)


if __name__ == "__main__":
    main()
