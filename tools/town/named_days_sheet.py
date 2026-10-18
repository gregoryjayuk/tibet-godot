#!/usr/bin/env python3
"""Lay out the named eight's days for Greg (sprint 6, step 3): each at a place and hour its day has it
(tests/terrain/s3.gd's NAMED_SHOTS), and Nyima following a new player across Tsongra at 16:05 (its --follow), captioned,
in reading order.
Stills: RETURN_FOCUS=0 TIMEOUT=400 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people
        --only=named_talkers,named_pitch,named_stalls,named_gate,named_door,named_spring
        RETURN_FOCUS=0 TIMEOUT=300 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --follow --town --people
Run: tools/py tools/town/named_days_sheet.py   Writes tests/terrain/out/named_days_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_named_stalls", "1. 09:15, Kalsang at her family's stall, Nyima at the next"),
         ("s3_named_pitch", "2. 14:55, Pasang carving; Nyima crouched to paint the letters"),
         ("s3_named_door", "3. 14:00, Kalsang at her doorway (spinning waits for its clip)"),
         ("s3_named_spring", "4. 15:36, Kalsang at the Lukhang spring (not built yet)"),
         ("s3_named_talkers", "5. 16:42, Sönam on the talkers' steps"),
         ("s3_named_gate", "6. 16:42, Dolkar in her gateway, the caravan due"),
         ("s3_follow_1", "7. 16:05, a stranger walks past Nyima on Tsongra"),
         ("s3_follow_2", "8. and he falls in behind"),
         ("s3_follow_3", "9. keeping three metres back, until he tires of it")]


def main():
    w, h, pad, cap, cols = 640, 360, 10, 30, 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The named eight's days (sprint 6, step 3): at their places, and Nyima following the new player.",
           font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "named_days_sheet.jpg")
    img.save(path, quality=86)
    print("named_days_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
