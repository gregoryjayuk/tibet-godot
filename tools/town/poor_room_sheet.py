#!/usr/bin/env python3
"""The poor family's one room, H-SHL-142 on the west edge (ISS-105; plan chapter 04, 4.2; ../tibet-blender kit/houses.py
poor_house(interior=True), kit/rooms.py house_room): its door of raw planks, ducked under; inside, the hearth of three
stones under the smoke hole with its shaft of day, the squared log, the sheepskins rolled, the stores, the lamp in its
niche lit at dusk; the door shut, the hole and the fire the only light.
Stills: RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=house_142_door,house_142_in,house_142_back,house_142_back_shut,house_142_back_w,house_142_up,house_142_dusk
and the walk: RETURN_FOCUS=0 STILLS=1 HOUR=15 tools/player/s15.sh route house_142
Run: tools/py tools/town/poor_room_sheet.py   Writes tests/terrain/out/poor_room_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "terrain", "out")
PLAYER = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [(PLAYER, "s15_house_142_01_door", "The door, 1.6 m: the walker ducks under its lintel"),
         (OUT, "s3_house_142_door", "One plank of raw wood on two battens, swung in; the window stopped with rags"),
         (OUT, "s3_house_142_in", "In at the door: the hearth under the smoke hole, the log, the sheepskins rolled"),
         (OUT, "s3_house_142_back", "From the back corner, 15:00: the day in at the door, the shaft over the fire"),
         (OUT, "s3_house_142_back_shut", "The door shut: the smoke hole and the fire the only light"),
         (OUT, "s3_house_142_back_w", "Over the beds: the niche, the churn, the tsampa bag, the dung basket"),
         (OUT, "s3_house_142_up", "Up the smoke hole, 35 cm, through the black poles"),
         (OUT, "s3_house_142_dusk", "18:00, a good day: the lamp in the niche lit"),
         (PLAYER, "s15_house_142_04_hearth", "Round the hearth, never over its stones")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "H-SHL-142, a poor family's one room (chapter 04, 4.2): \"absolutely no furniture\"; a shaft of day through the smoke onto the hearth.", font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(OUT, "poor_room_sheet.jpg")
    img.save(path, quality=88)
    print("poor_room_sheet: %s" % path)


if __name__ == "__main__":
    main()
