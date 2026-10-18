#!/usr/bin/env python3
"""Lay out Dechen-tsang's four rooms for Greg (sprint 7, step 1): the guest yard's two ranges with the rooms' doors and
windows, then each room from its door and from inside, at 15:00 with the sun in the west, captioned, in reading order.
Stills: RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town
        --only=dechen_yard2_w,dechen_yard2_e,dechen_tibetan_in,dechen_tibetan_door,dechen_chinese_in,dechen_chinese_desk,dechen_guest_in,dechen_kitchen_in
Run: tools/py tools/town/rooms_sheet.py   Writes tests/terrain/out/rooms_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_dechen_yard2_w", "The guest yard's west range: the Tibetan room's door (left) and its window"),
         ("s3_dechen_yard2_e", "Across the yard: the guest room's door, the Chinese room's window and door"),
         ("s3_dechen_tibetan_in", "The Tibetan counting room: benches with rugs, the low tables, the brazier and tea jug"),
         ("s3_dechen_tibetan_door", "From its head: the pillar and bracket, the window's paper, the door to the yard"),
         ("s3_dechen_chinese_in", "The Chinese counting room: the square table, two armchairs, scroll and couplet"),
         ("s3_dechen_chinese_desk", "Yang's writing table under the window: the ledger, the abacus, a lamp"),
         ("s3_dechen_guest_in", "The player's room: the bed, the chest and its butter lamp, the saddlebags"),
         ("s3_dechen_kitchen_in", "The kitchen: the long stove, the line of kettles, the churns, two pillars")]


def main():
    w, h, pad, cap, cols = 900, 506, 10, 32, 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Dechen-tsang's rooms (sprint 7, step 1), at 15:00: each room's own light, the eye adjusted inside.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x, y = pad + (i % cols) * (w + pad), 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "rooms_sheet.jpg")
    img.save(path, quality=86)
    print("rooms_sheet: %d stills -> %s" % (len(SHOTS), path))


if __name__ == "__main__":
    main()
