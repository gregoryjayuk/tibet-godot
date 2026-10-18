#!/usr/bin/env python3
"""Lay out the caravan CV-02 for Greg (sprint 6, step 5): Samkha's north ramp and the Yak Gate, then the ten yak up the
ramp, through the gate, one at a time into Dechen-tsang's passage, in Yard 0 at the unloading and going home, captioned.
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people
        --only=gate_street,ramp_from_bridge,caravan_ramp,caravan_gate,caravan_passage,caravan_yard0,caravan_home
Run: tools/py tools/town/caravan_sheet.py   Writes tests/terrain/out/caravan_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_gate_street", "The Yak Gate (SAM-07) from Nétsang Lam, its chorten outside"),
         ("s3_ramp_from_bridge", "The north ramp's legs from the bridge's deck (SAM-05)"),
         ("s3_caravan_ramp", "15:12, the file climbing the ramp's legs"),
         ("s3_caravan_gate", "15:22, Sengé through the gate, the lead and its drover behind"),
         ("s3_caravan_passage", "15:36, one at a time into Dechen-tsang's passage"),
         ("s3_caravan_yard0", "16:05, Yard 0: the loads coming off onto the platform"),
         ("s3_caravan_home", "16:58, going down the ramp to the camp")]


def main():
    w, h, pad, cap, cols = 640, 360, 10, 30, 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The caravan CV-02 (sprint 6, step 5): ten yak up Samkha's north ramp to Dechen-tsang, and home.",
           font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "caravan_sheet.jpg")
    img.save(path, quality=86)
    print("caravan_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
