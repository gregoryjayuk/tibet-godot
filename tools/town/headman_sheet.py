#!/usr/bin/env python3
"""The headman's house SHL-19, every floor (M2 sprint 7; plan chapter 04, 4.1), on one page: its yard and the mastiff on
its chain, the stable with the groom and the beasts, the kitchen's copper wall with the steward and its stove at supper,
the reception room with the Hejie trader and the tea poured, the shrine room with the reader and the grandmother, the
guest room's bay, Pema at her loom in the roof room, the roof at the dusk juniper, the headman's bench refused.
Its stills (in a window, a few minutes):
  RETURN_FOCUS=0 TIMEOUT=700 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=headman_dog_yard,headman_stable_groom,headman_kitchen_polish,headman_supper,headman_reception_trader,headman_shrine_reader,headman_bay_in,headman_roofroom_pema,headman_roof_juniper
  (each at its hour: tests/terrain/s3.gd STATION_HOUR; headman_bay_in at 14:00, the stills' default)
  RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh route headman_tea   and   route headman_seat
Run: tools/py tools/town/headman_sheet.py   Writes tests/terrain/out/headman_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
PLAYER = os.path.join(ROOT, "tests", "player", "out")
SHOTS = [(TERRAIN, "s3_headman_dog_yard", "15:00: the yard from the landing, the mastiff on its chain", 1.0),
         (TERRAIN, "s3_headman_stable_groom", "15:00: the stable (brightened), the groom, the mules eating", 1.6),
         (TERRAIN, "s3_headman_kitchen_polish", "15:00: the copper wall, the steward polishing it", 1.0),
         (TERRAIN, "s3_headman_supper", "18:30: supper by the stove, the family on the bench", 1.3),
         (TERRAIN, "s3_headman_reception_trader", "15:30: the reception room, the Hejie trader on a Han stool", 1.0),
         (PLAYER, "s15_headman_tea_05_pouring", "15:30: tea on the lower bench, the mistress pouring", 1.0),
         (TERRAIN, "s3_headman_shrine_reader", "13:36: the reader at the altar, the grandmother by the door", 1.0),
         (TERRAIN, "s3_headman_bay_in", "The guest room kept for the lama: the bay's sill seat", 1.0),
         (TERRAIN, "s3_headman_roofroom_pema", "15:30: Pema at her loom in the mistress's room on the roof", 1.0),
         (TERRAIN, "s3_headman_roof_juniper", "17:18: juniper on the roof's burner, the town in shadow", 1.4),
         (PLAYER, "s15_headman_seat", "The headman's bench: \"Please, sit on the lower bench.\"", 1.0),
         (TERRAIN, "s3_headman_copper_wall", "The copper wall over the trapdoor to the stable", 1.0)]


def main():
    w, h, pad, cap = 640, 360, 8, 26
    cols = 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 50 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 12), "M2 sprint 7, the headman's house SHL-19, every floor and its household's day: the stable, the kitchen, the reception room, the shrine room, the roof.",
           font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label, bright) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 50 + (i // cols) * (h + cap + pad)
        path = os.path.join(folder, name + ".png")
        if not os.path.exists(path):
            d.text((x, y + h // 2), "missing: " + name, font=FONT, fill=(160, 40, 30))
            continue
        im = Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS)
        if bright != 1.0:
            im = ImageEnhance.Brightness(im).enhance(bright)
        img.paste(im, (x, y))
        d.text((x, y + h + 3), label, font=FONT, fill=(40, 30, 25))
    out = os.path.join(TERRAIN, "headman_sheet.jpg")
    img.save(out, quality=88)
    print("headman_sheet:", out)


if __name__ == "__main__":
    main()
