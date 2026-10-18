#!/usr/bin/env python3
"""The room doors that open and shut for Greg (ISS-105; world/doors.gd, the kit's door_leaf types hung at the leaves
../tibet-blender kit/elements.py plank_door marks): each of the three houses to enter and Dechen-tsang's kitchen, its door
open and shut from the same place at 15:00, and H-SHL-007's from inside its kitchen; Dechen-tsang's guest yard's
three rooms (ISS-084: the leaves alone in their plastered passages, each room its own).
Stills: RETURN_FOCUS=0 TIMEOUT=600 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=house_007_door,house_007_shut,house_007_back,house_007_back_shut,house_054_door,house_054_shut,house_004_door,house_004_shut,dechen_kitchen_door,dechen_kitchen_shut,dechen_yard2_e,dechen_yard2_e_shut,dechen_tibetan_door,dechen_tibetan_door_shut
Run: tools/py tools/town/room_doors_sheet.py   Writes tests/terrain/out/room_doors_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_house_007_door", "H-SHL-007 from its landing: the door open, its maroon leaves swung in"),
         ("s3_house_007_shut", "Shut (E by the door): the leaves meet, the doorway barred"),
         ("s3_house_007_back", "From the back of its kitchen, the door open on the afternoon"),
         ("s3_house_007_back_shut", "Shut: the room in the light of its window and its fire"),
         ("s3_house_054_door", "H-SHL-054's, open: a richer house's red leaves"),
         ("s3_house_054_shut", "Shut: the iron straps and the brass ring outside"),
         ("s3_house_004_door", "H-SHL-004's, open: blue leaves"),
         ("s3_house_004_shut", "Shut"),
         ("s3_dechen_kitchen_door", "Dechen-tsang's kitchen from the yard, open"),
         ("s3_dechen_kitchen_shut", "Shut: maroon, its rings and straps"),
         ("s3_dechen_yard2_e", "Its guest yard: the guest room's door and the Chinese room's, open (ISS-084)"),
         ("s3_dechen_yard2_e_shut", "Shut: the guest room's plain maroon, the Chinese room's red with rings"),
         ("s3_dechen_tibetan_door", "In the Tibetan room, towards its door, open"),
         ("s3_dechen_tibetan_door_shut", "Shut: the room in the light of its window and its brazier")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Doors that open and shut (ISS-105): E by a door swings it, and it is heard; whoever of the town comes to a shut door opens it.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(OUT, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "room_doors_sheet.jpg")
    img.save(path, quality=88)
    print("room_doors_sheet: %s" % path)


if __name__ == "__main__":
    main()
