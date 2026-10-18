#!/usr/bin/env python3
"""The Gorge Stair and the upper bridge, M3 sprint 2 on one page (chapter 12's M3, acceptance 4: "Cross the raw bridge at
noon (V-09), climb the Gorge Stair to the West Gate"; chapter 02, R-07, RNG-02 to RNG-09, V-09, V-17; chapter 08, V-17
and the tulku's afternoon home): the stair's zigzag up the face, the gorge from above with its flags, the raw bridge,
V-09, a gallery on its beams, the houses across the top, the old monk at the rest gallery's wheel, V-17, the water wheel,
the naga shrine, a water carrier at the channel's head, the novices racing down, and on the full moon the tulku over the
bridge and on the terrace with his mother.
Its stills (in a window, some ten minutes; each station at its hour and day, tests/terrain/s3.gd STATION_HOUR, STATION_DAY):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=gorge_face,gorge_above,gorge_bridge_side,gorge_gallery,gorge_houses,gorge_bench,gorge_wheel,gorge_naga,gorge_water_fill,gorge_novices,gorge_tulku_bridge,gorge_tulku_sit
  RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh route viewpoints   (V-09's and V-17's, tests/player/out/s15_viewpoint_v09.png, _v17.png)
Run: tools/py tools/town/gorge_sheet.py   Writes tests/terrain/out/gorge_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
PLAYER = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [(TERRAIN, "s3_gorge_face", "The east leg's zigzag up the face to the monastery, from the west leg across the gorge"),
         (TERRAIN, "s3_gorge_above", "From above Tödé's rim: both legs, the raw bridge, the six flag strings across the gorge"),
         (TERRAIN, "s3_gorge_bridge_side", "The upper bridge RNG-02: the 1902 timber pale and new on its old grey abutments"),
         (PLAYER, "s15_viewpoint_v09", "V-09, seated on the bridge's deck: the face, the galleries and the flags overhead"),
         (TERRAIN, "s3_gorge_gallery", "A gallery of RNG-08 on its beams socketed into the rock, its rope rail"),
         (TERRAIN, "s3_gorge_houses", "The stair's top under two monks' houses built across it on their piers"),
         (TERRAIN, "s3_gorge_bench", "The rest gallery RNG-09: the old monk on its bench turning the wheel, 15:00"),
         (PLAYER, "s15_viewpoint_v17", "V-17, seated on the rest gallery's bench: the strings running away across the gorge"),
         (TERRAIN, "s3_gorge_wheel", "The water wheel RNG-04 on its channel below the bridge, its bell once a turn"),
         (TERRAIN, "s3_gorge_naga", "The naga shrine RNG-05 under its overhang, milk on the rock"),
         (TERRAIN, "s3_gorge_water_fill", "07:26: a Tödé woman filling her barrel at the wheel's channel's head"),
         (TERRAIN, "s3_gorge_novices", "14:41: two novices racing down past the rest gallery (V-17's people)"),
         (TERRAIN, "s3_gorge_tulku_bridge", "5 November, the full moon, 14:01: the tulku and his attendants over the raw bridge"),
         (TERRAIN, "s3_gorge_tulku_sit", "15:00: mother and son on the Lookout's terrace, the attendants standing by")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The Gorge Stair and the upper bridge (M3 sprint 2): the stair, its bridge, galleries, wheel, shrine and flags, who uses it.", font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "gorge_sheet.jpg")
    img.save(path, quality=86)
    print("gorge_sheet: %s" % path)


if __name__ == "__main__":
    main()
