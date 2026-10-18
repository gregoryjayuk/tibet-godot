#!/usr/bin/env python3
"""Spike S7 on one page (plan chapter 11, S7; chapter 04, 8; the game's M3 sprint 5, step 3): the Tsokchen's nave from the
aisle inside the great door at noon and at the 05:30 assembly under each of the five interior lighting stacks, for Greg
to choose the interior look (world/interior_stack.gd): 1 the sky occlusion alone with the room's own lights, 2 with a
ReflectionProbe in interior mode, 3 with VoxelGI baked over the hall, 4 with an AreaLight3D under each long side of the
lantern (as strong as the day beyond it), 5 with the hall's air thickened and the sun's own shadow through the lantern's
lattice (the shafts' cards off). Their GPU cost is a timed turn with the screen awake (Greg's).
Its stills, one window a stack (about a minute each):
  for n in 1 2 3 4 5; do RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --s7=$n --only=s7_noon,s7_dawn; done
Run: tools/py tools/look/s7_sheet.py   Writes tests/look/out/s7_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHOTS = os.path.join(ROOT, "tests", "terrain", "out")
OUT = os.path.join(ROOT, "tests", "look", "out", "s7_sheet.jpg")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
STACKS = ["1: the sky occlusion and the room's own lights (the two lamp-bank clusters, the well's day, the door's)",
          "2: with a ReflectionProbe in interior mode over the hall (S7's fallback: probe and lamps)",
          "3: with VoxelGI baked over the hall, the well and the lantern",
          "4: with an AreaLight3D under each long side of the lantern, as strong as the day beyond it",
          "5: with the hall's air thickened and the sun's shadow through the lantern's lattice, no shaft cards"]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    img = Image.new("RGB", (pad + 2 * (w + pad), 56 + len(STACKS) * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Spike S7, the Tsokchen's nave at noon (left) and at the 05:30 assembly (right), five lighting stacks: Greg chooses one.", font=FONT, fill=(40, 30, 25))
    for k, label in enumerate(STACKS):
        y = 56 + k * (h + cap + pad)
        for c, when in enumerate(("noon", "dawn")):
            p = os.path.join(SHOTS, "s3_s7_%s_s7-%d.png" % (when, k + 1))
            if os.path.exists(p):
                img.paste(Image.open(p).convert("RGB").resize((w, h), Image.LANCZOS), (pad + c * (w + pad), y))
        d.text((pad, y + h + 4), "Stack " + label, font=FONT, fill=(40, 30, 25))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT, quality=86)
    print("s7_sheet: %s" % OUT)


if __name__ == "__main__":
    main()
