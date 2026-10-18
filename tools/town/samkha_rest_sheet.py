#!/usr/bin/env python3
"""The rest of Samkha (M2 sprint 11; chapter 12's M2: "Samkha, SAM-01 to SAM-16"; chapter 02, D04) on one page: the
Castle Ramp SAM-10 from the ward's gate down to Hejie's East Gate, Castle Lane between the retainers' houses SAM-14 and
the poor houses SAM-15 under the ward's wall, the stables SAM-08 and the ula yard SAM-09 at the count, the 1861 breach
SAM-16, the Leat Fall SAM-11 and the latrine's midden SAM-12, and Samkha's people: the morning hearing's parties in the
ward and on the hall's felts, the great court on 9 November, the toll counted at Sherab's table.
Its stills (in a window, some ten minutes; each station at its hour, tests/terrain/s3.gd STATION_HOUR, the great court's
on 9 November, STATION_DAY):
  RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=castle_ramp_gate,castle_ramp_landing1,castle_ramp_above,castle_lane,samkha_poor,samkha_houses_above,ula_yard_morning,ula_yard,breach_1861,leat_fall,latrine_midden,samkha_ward_hearing,samkha_court,samkha_great_court,samkha_great_ward,toll_count
Run: tools/py tools/town/samkha_rest_sheet.py   Writes tests/terrain/out/samkha_rest_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 18)
SHOTS = [("s3_castle_ramp_gate", "15:30: the Castle Ramp's foot outside Hejie's East Gate, its last leg climbing the knob"),
         ("s3_castle_ramp_landing1", "At its first switchback, back up the first leg to the castle"),
         ("s3_castle_ramp_above", "Its Z from above: the castle's flank, the three legs at 22%, Hejie below"),
         ("s3_castle_lane", "Castle Lane from its head: the retainers' houses in the castle's colours"),
         ("s3_samkha_poor", "The poor houses against the ward's north wall"),
         ("s3_samkha_houses_above", "Samkha's houses from above, the castle's ward behind"),
         ("s3_ula_yard_morning", "07:45: the morning's count in the ula yard, the animals at their rings"),
         ("s3_ula_yard", "15:45: the afternoon's, the owners arguing, the scribe and the soldier"),
         ("s3_breach_1861", "The 1861 breach: the ruined outwork, broken through and patched, never rebuilt"),
         ("s3_leat_fall", "The Leat Fall spouting from its culvert in the slot's face"),
         ("s3_latrine_midden", "The castle's latrine bay, its stain and its ledge midden"),
         ("s3_samkha_ward_hearing", "08:12: the morning hearing's parties waiting in the ward by the steps"),
         ("s3_samkha_court", "09:30: the dispute over landing dues on the felts, the headman by the west wall"),
         ("s3_samkha_great_court", "9 November, 09:40: the great court, the hamlets' headmen along the west wall"),
         ("s3_samkha_great_ward", "9 November, 08:10: the great cases' parties waiting in the ward"),
         ("s3_toll_count", "09:47: a porter's load counted at Sherab's table in the south pavilion")]


def main():
    w, h, pad, cap = 960, 540, 10, 28
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The rest of Samkha (M2 sprint 11): the Castle Ramp, Samkha's houses, the stables and the ula yard, the rim, Samkha's people.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "samkha_rest_sheet.jpg")
    img.save(path, quality=88)
    print("samkha_rest_sheet: %s" % path)


if __name__ == "__main__":
    main()
