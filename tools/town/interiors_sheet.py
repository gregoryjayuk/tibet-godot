#!/usr/bin/env python3
"""The hero interiors, M3 sprint 5 on one page (chapter 12's M3: "the hero interiors of the monastery"; chapter 04, 3.1-3.8;
chapter 08, V-30): the Tsokchen's nave, its aisle and inner chapel, the well up to the lantern and the noon shafts down
it, the dawn assembly; the Jampa Lhakhang's Maitreya, V-30 and its stair-ladder; the Gönkhang; the library; the Jakhang;
a monk's cell; the Labrang's reception; the Parkhang's court, printing room, a pair's place, its chapel and the block
canyon. Spike S7's five lighting stacks are their own page (tools/look/s7_sheet.py), for Greg's choice.
Its stills (in a window, each station at its hour, tests/terrain/s3.gd STATION_HOUR; the Parkhang's canyon stations in
their order: its block store streams in within 15 m of its hatch):
  RETURN_FOCUS=0 TIMEOUT=1500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=tsokchen_nave_in,tsokchen_aisle,tsokchen_chapel_in,tsokchen_well_up,tsokchen_shaft,assembly_dawn,jampa_up,v30_face,jampa_ladder,gonkhang_room,gonkhang_yak,kangyur_east,jakhang_in,monk_cell_in,labrang_reception
  RETURN_FOCUS=0 TIMEOUT=700 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=parkhang_gate_in,parkhang_printing_in,parkhang_press,parkhang_chapel_in,parkhang_canyon,parkhang_canyon_far
Run: tools/py tools/town/interiors_sheet.py   Writes tests/terrain/out/interiors_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_tsokchen_nave_in", "The Tsokchen's nave from inside the great door: the aisle between the rows, the pillars in their rugs"),
         ("s3_tsokchen_aisle", "Up the aisle: the thrones before the inner chapel's door between the lamp banks"),
         ("s3_tsokchen_chapel_in", "The inner chapel: Tsongkhapa and the two lesser images facing the door"),
         ("s3_tsokchen_well_up", "Up the well past the tall pillars to the lantern's lattice"),
         ("s3_tsokchen_shaft", "The noon shafts from the lantern's south windows down onto the aisle, their dust"),
         ("s3_assembly_dawn", "The dawn assembly at 05:45: the monks in their rows by the lamps"),
         ("s3_jampa_up", "The Jampa Lhakhang: Maitreya seated over three storeys, from his feet"),
         ("s3_v30_face", "V-30: the lantern's sun on Maitreya's face at eye level from the top gallery"),
         ("s3_jampa_ladder", "Its stair-ladder up through the hatch to the gallery"),
         ("s3_gonkhang_room", "The Gönkhang: two lamps, the masks and arms on the pillars, the veiled protectors"),
         ("s3_gonkhang_yak", "The stuffed wild yak hung from its beam"),
         ("s3_kangyur_east", "The library: the canon's pigeonholes, the pillar, the reading table"),
         ("s3_jakhang_in", "The Jakhang: the stove and its three cauldrons, the great one covered"),
         ("s3_monk_cell_in", "A monk's cell up its notched log: the stove, the churn, the window over the gorge"),
         ("s3_labrang_reception", "The Labrang's reception: the tulku's throne, its tiger skin and table, the carpets"),
         ("s3_parkhang_gate_in", "The Parkhang's court: the arcade, the new flags drying, the printing room's windows"),
         ("s3_parkhang_printing_in", "The printing room: six pairs' places under the north windows, the damp sheets"),
         ("s3_parkhang_press", "A pair's place: the sloping board, the block inked in cinnabar, the roller, the stacks"),
         ("s3_parkhang_chapel_in", "The Parkhang's chapel: Manjushri, the bowls, its one lamp"),
         ("s3_parkhang_canyon", "The block canyon from the hatch: 22 m of racks to the one window (15:30)"),
         ("s3_parkhang_canyon_far", "Back down the canyon from the window's end, some 10,000 blocks on edge")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 3
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The hero interiors (M3 sprint 5): the Tsokchen and its assembly, the Jampa Lhakhang and V-30, the Gönkhang, the library, the Jakhang, a monk's cell, the Labrang, the Parkhang.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        p = os.path.join(TERRAIN, name + ".png")
        if os.path.exists(p):
            img.paste(Image.open(p).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "interiors_sheet.jpg")
    img.save(path, quality=86)
    print("interiors_sheet: %s" % path)


if __name__ == "__main__":
    main()
