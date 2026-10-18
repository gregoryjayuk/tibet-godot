#!/usr/bin/env python3
"""The 1,080 steps, M3 sprint 1 on one page (chapter 12's M3, acceptance 1: "climb the 1,080 steps with pilgrims
counting on their rosaries, in about a quarter of an hour"; chapter 02, R-04, RNG-01 to RNG-14, V-04): the stair from
V-01 and from Tsongra, across the face, the Conch Bridge and the tsenkhang, the Lhabab Chorten, landing 12's chorten and
rest house, a niche of wheels, the Parkhang, the pilgrims at 08:30 and the Double Ninth party at 14:45, V-04 seated, and
the way down from the South Gate.
Its stills (in a window, some five minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=700 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=steps_from_v01,steps_from_tsongra,steps_face,conch_bridge_side,steps_lhabab,steps_landing12,steps_niche,parkhang_front,steps_pilgrims,steps_party_close,steps_top_confluence
  RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh route viewpoints   (V-04's, tests/player/out/s15_viewpoint_v04.png)
Run: tools/py tools/town/steps_sheet.py   Writes tests/terrain/out/steps_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
PLAYER = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [(TERRAIN, "s3_steps_from_v01", "From V-01: the Conch Bridge, the Parkhang, the Lhabab Chorten, the stair up the nose and across the face"),
         (TERRAIN, "s3_steps_from_tsongra", "From Tsongra: the steps' zigzag on the spur over the town's roofs"),
         (TERRAIN, "s3_steps_face", "The legs across the face from out over the gorge, the monastery above"),
         (TERRAIN, "s3_conch_bridge_side", "The Conch Bridge over the Dungchu from downstream, the tsenkhang on the prow"),
         (TERRAIN, "s3_steps_lhabab", "The Lhabab Chorten on its terrace beside landing 6's platform"),
         (TERRAIN, "s3_steps_landing12", "Landing 12: its terrace with the byang chub chorten and the rest house"),
         (TERRAIN, "s3_steps_niche", "A niche of three prayer wheels at landing 8, turned by a passing hand"),
         (TERRAIN, "s3_parkhang_front", "The Parkhang at the steps' foot, at its far form on its podium"),
         (TERRAIN, "s3_steps_pilgrims", "08:30: a pilgrim up flight 7, a novice coming down"),
         (TERRAIN, "s3_steps_party_close", "14:45 on the Double Ninth: Hejie's shopkeepers in a ring with their wine"),
         (PLAYER, "s15_viewpoint_v04", "V-04, seated on the Lhabab Chorten's terrace at 16:18"),
         (TERRAIN, "s3_steps_top_confluence", "From over the South Gate down the last flights to the town and the confluence")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The 1,080 steps (M3 sprint 1): the stair, its bridge, chortens, wheels and Parkhang, who climbs it, V-04.", font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "steps_sheet.jpg")
    img.save(path, quality=86)
    print("steps_sheet: %s" % path)


if __name__ == "__main__":
    main()
