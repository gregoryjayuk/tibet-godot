#!/usr/bin/env python3
"""Tödé, M3 sprint 4 on one page (chapter 12's M3: "Tödé (68 houses, the tower, the leat, mills, threshing floors, the Bön
chapel and its households)"; chapter 02, D06 and TOD-01 to TOD-26; chapter 08, V-12): the upper quarter from the
monastery across the gorge and from above, the Tödé Stair up the band to its terrace, the tower-houses and the Bön
households' rammed-earth houses, the tower and V-12 on its top, the leat along the contour with its mills and water prayer
wheels, the threshing floors, the walnut grove and the window stall, the Bön chapel and its circuit, and Tödé's people:
the circuit at dawn, the flails on the floors and the roofs, a water carrier at the leat, a porter on the stair.
Its stills (in a window, some twenty minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR):
  RETURN_FOCUS=0 TIMEOUT=1500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=tode_from_gonpa,tode_above,tode_stair_side,tode_terrace,tode_c1,tode_bon,tower_whole,tower_and_gonpa,leat_contour,leat_mill_upper,leat_wheel,tode_floor,tode_walnuts,tode_stall,tode_chapel,tode_bon_circuit,tode_threshing,tode_gyaltsen_roof,tode_carrier,tode_stair_people
  RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh route viewpoints   (V-12's, tests/player/out/s15_viewpoint_v12.png)
Run: tools/py tools/town/tode_sheet.py   Writes tests/terrain/out/tode_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
PLAYER = os.path.join(ROOT, "tests", "player", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [(TERRAIN, "s3_tode_from_gonpa", "Tödé from Dungkar Gönpa across the gorge: the houses dispersed in their fields"),
         (TERRAIN, "s3_tode_above", "From above: the tower-houses, the log houses, the field paths"),
         (TERRAIN, "s3_tode_stair_side", "The Tödé Stair, 476 steps up the band from the Sky Stair's head"),
         (TERRAIN, "s3_tode_terrace", "Its terrace along the contour, where every way into Tödé begins"),
         (TERRAIN, "s3_tode_c1", "A Gyalrong tower-house, its horn merlons with white stones"),
         (TERRAIN, "s3_tode_bon", "The Bön households' rammed-earth houses, their walled yards"),
         (TERRAIN, "s3_tower_whole", "The Tödé tower TOD-01, an eight-pointed star 32 m high"),
         (PLAYER, "s15_viewpoint_v12", "V-12 on its top: the Tsokchen level with the eye across the gorge"),
         (TERRAIN, "s3_tower_and_gonpa", "The tower before the monastery, from the west"),
         (TERRAIN, "s3_leat_contour", "The leat TOD-10 along the contour at 2,978 m, the leat walk on its shelf"),
         (TERRAIN, "s3_leat_mill_upper", "The upper mill TOD-05 below its chute"),
         (TERRAIN, "s3_leat_wheel", "A water prayer wheel house over its channel"),
         (TERRAIN, "s3_tode_floor", "A threshing floor: its kerb, straw and flails"),
         (TERRAIN, "s3_tode_walnuts", "The walnut grove TOD-20 in late October"),
         (TERRAIN, "s3_tode_stall", "The window stall TOD-25 at the Sky Stair's head"),
         (TERRAIN, "s3_tode_chapel", "The Yungdrung Lhakhang TOD-02, its circuit R-24 paved round it"),
         (TERRAIN, "s3_tode_bon_circuit", "06:13: the Bön circuit, anticlockwise past the wheels"),
         (TERRAIN, "s3_tode_threshing", "10:00 at TOD-13: six in a line with their flails"),
         (TERRAIN, "s3_tode_gyaltsen_roof", "Yungdrung Gyaltsen threshing on his roof with a woman of his house"),
         (TERRAIN, "s3_tode_carrier", "A water carrier filling her barrel at the leat"),
         (TERRAIN, "s3_tode_stair_people", "A porter going down the Tödé Stair to Shöl")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Tödé (M3 sprint 4): the upper quarter, the Tödé Stair, the tower and V-12, the leat and its mills, the floors, the Bön chapel, its people.", font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        p = os.path.join(folder, name + ".png")
        if os.path.exists(p):
            img.paste(Image.open(p).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "tode_sheet.jpg")
    img.save(path, quality=86)
    print("tode_sheet: %s" % path)


if __name__ == "__main__":
    main()
