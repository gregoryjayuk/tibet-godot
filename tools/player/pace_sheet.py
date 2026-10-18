#!/usr/bin/env python3
"""The pace (IMP-043; Greg's brief of 14 Oct 2026, docs/brief-movement-controls.md) on one page: the jog that is now the
default, the sprint on the level and up the Sky Stair two treads a stride, the breath run out (the faint vignette, back
to the jog) with the help line as a PS4 controller reads it.
Its stills: RETURN_FOCUS=0 tools/player/tp.sh (the street's), then
  CLIMB_GAIT=sprint RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh (the Sky Stair's at the sprint)
Run: tools/py tools/player/pace_sheet.py   Writes tests/player/out/pace_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("tp_4_run", "The jog, 4.5 m/s: the default now (Option walks)"),
         ("tp_5_sprint", "The sprint, 7 m/s while Shift (the controller's cross) is held: the camera further back, wider"),
         ("tp_9_woman_sprint", "The woman sprinting (her clip 6.5 m/s)"),
         ("s15_sprint_gateway", "Up the Sky Stair at the sprint, two treads a stride (6 a second)"),
         ("s15_sprint_feet", "The sprint's feet on every other tread"),
         ("tp_16_winded_pad", "Winded after about 15 s: a faint vignette, the panting, back to the jog; the controller's help line")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The pace (IMP-043, 14 Oct 2026): a jog by default, a sprint clearly faster, the breath that runs out; the keys and the mouse as World of Warcraft has them, a PS4 controller GTA's way (IMP-044).", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        p = os.path.join(OUT, name + ".png")
        if os.path.exists(p):
            img.paste(Image.open(p).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "pace_sheet.jpg")
    img.save(path, quality=86)
    print("pace_sheet: %s" % path)


if __name__ == "__main__":
    main()
