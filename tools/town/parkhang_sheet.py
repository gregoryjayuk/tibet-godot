#!/usr/bin/env python3
"""The Parkhang carved on one page (M3 sprint 5, step 8; plan chapter 04, 3.6; tibet-blender kit/dungrong.py parkhang
interior=True, kit/rooms_gonpa.py parkhang_printing, parkhang_blocks, parkhang_chapel): its back door from the 1,080
steps' side, the court and its arcade with the new flags drying, the stair hall, the printing room and a pair's place,
the chapel, and the block canyon from both ends and close.
Its stills (a window, about two minutes):
  RETURN_FOCUS=0 TIMEOUT=700 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=parkhang_back,parkhang_gate_in,parkhang_arcade,parkhang_stair,parkhang_printing_in,parkhang_press,parkhang_chapel_in,parkhang_canyon,parkhang_canyon_far,parkhang_blocks_close
Run: tools/py tools/town/parkhang_sheet.py   Writes tests/terrain/out/parkhang_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHOTS = os.path.join(ROOT, "tests", "terrain", "out")
OUT = os.path.join(SHOTS, "parkhang_sheet.jpg")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
STILLS = [("parkhang_back", "From the steps' first landing: the back door into the stair hall, the printing room's windows over it (11:00)"),
          ("parkhang_gate_in", "Out of the gate's passage: the arcade on its twelve pillars, the new flags drying, the stair hall's door"),
          ("parkhang_arcade", "The arcade from the court's south-east, the printing room's windows to the court over its roof"),
          ("parkhang_stair", "The stair hall from its back door: the 4.5 m stair-ladder up through the hatch"),
          ("parkhang_printing_in", "The printing room from its west end: six pairs' places under the north windows, damp sheets, the cutting table"),
          ("parkhang_press", "A pair's place: the bench, the sloping board, the block inked in cinnabar, the roller, the stacks"),
          ("parkhang_chapel_in", "The chapel in the east range: Manjushri and two lesser images, the bowls, its one lamp"),
          ("parkhang_canyon", "The block canyon from the hatch: three aisles 70 cm wide, 22 m of racks, the one window at the far end (15:30)"),
          ("parkhang_canyon_far", "The canyon from the window's end, back down the middle aisle"),
          ("parkhang_blocks_close", "The blocks in the window's light: on edge, a set to a shelf, their handles to the aisle")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    rows = (len(STILLS) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The Parkhang carved (RNG-10; chapter 04, 3.6): the court, the printing room, the chapel and the block canyon", font=FONT, fill=(40, 30, 25))
    for k, (name, label) in enumerate(STILLS):
        x, y = pad + (k % 2) * (w + pad), 56 + (k // 2) * (h + cap + pad)
        p = os.path.join(SHOTS, "s3_%s.png" % name)
        if os.path.exists(p):
            img.paste(Image.open(p).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    img.save(OUT, quality=86)
    print("parkhang_sheet: %s" % OUT)


if __name__ == "__main__":
    main()
