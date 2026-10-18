#!/usr/bin/env python3
"""M2 sprint 6, the rest of Shöl, on one page: the ngakpa quarter round Pema Ö and its men to the service, the west edge
at dawn, the Lukhang spring's queue at first light and its afternoon, the garden lane between its walls and the orchards
from above, Dungri Karpo in the notch from the Gorge Rim Lookout, the western mani wall up the lingkor's west side.
Its stills are the steps' own (each step's sheet has its command): tools/town/spring_sheet.py, lookout_sheet.py,
v13a_sheet.py, west_mani_sheet.py, and the stations ngakpa_above, ngakpa_to_service, west_edge_dawn.
Run: tools/py tools/town/rest_of_shol_sheet.py   Writes tests/terrain/out/rest_of_shol_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
PLAYER = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [(TERRAIN, "s3_ngakpa_above", "The ngakpa quarter, 25 households round Pema Ö", 1.0),
         (TERRAIN, "s3_ngakpa_to_service", "07:46: a man of the quarter up Pema Ö's stair to the service", 1.0),
         (TERRAIN, "s3_west_edge_dawn", "06:45: the west edge in the mist, H-SHL-142's family setting out", 1.0),
         (TERRAIN, "s3_spring_queue", "05:44 (brightened): the Lukhang spring's queue at first light", 2.0),
         (TERRAIN, "s3_spring_afternoon", "15:44: the afternoon's water, the talk behind the queue", 1.0),
         (TERRAIN, "s3_lookout_lane", "The garden lane between its walls, 2.5 m high", 1.0),
         (TERRAIN, "s3_gardens_above", "Upper Shöl's walled orchards from the slope above", 1.0),
         (PLAYER, "s15_viewpoint_v13a", "Dungri Karpo in the notch, from the Gorge Rim Lookout at 17:12", 1.0),
         (TERRAIN, "s3_west_mani_side", "The western mani wall up the lingkor's west side", 1.0)]


def main():
    w, h, pad, cap = 640, 360, 8, 26
    cols = 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 50 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 12), "M2 sprint 6, the rest of Shöl: the ngakpa quarter, the west edge, the Lukhang spring, the Gorge Rim Lookout and Dungri Karpo, the western mani wall.", font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label, bright) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 50 + (i // cols) * (h + cap + pad)
        im = Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS)
        if bright != 1.0:
            im = ImageEnhance.Brightness(im).enhance(bright)
        img.paste(im, (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "rest_of_shol_sheet.jpg")
    img.save(path, quality=88)
    print("rest_of_shol_sheet: %s" % path)


if __name__ == "__main__":
    main()
