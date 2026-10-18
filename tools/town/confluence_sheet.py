#!/usr/bin/env python3
"""The rivers and the confluence (M2 sprint 5; M2's acceptances 1 and 3: "the river below" the cliff gallery, V-02): the
Golden Slot's water under the gallery, Samkha's slot from V-10, the Conch Fall over its lip, Pema Ö Lhakhang up its
stair and in its hall, Lama Orgyen Dorje at the Conch terrace's lip at the first sun, the 08:00 service, the old woman on
the kora, and V-02: the pool at 07:55, the white water and the gold side by side, the conch's glint in the eddy.
Stills: RETURN_FOCUS=0 TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=rivers_golden,samkha_v10_up,conch_fall,pema_o_front,pema_o_hall,pema_lama_lip,pema_monks_service,pema_kora_woman,v02_mist,v02_conch
Run: tools/py tools/town/confluence_sheet.py   Writes tests/terrain/out/confluence_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [("s3_rivers_golden", "The Golden Slot's water down towards the confluence, the cliff gallery on its wall"),
         ("s3_samkha_v10_up", "V-10 on the chain bridge: Samkha's slot, its water 46 m below"),
         ("s3_conch_fall", "The Conch Fall SAM-13 thrown over its lip, its foam, the two waters below"),
         ("s3_pema_o_front", "Pema Ö Lhakhang from the Conch terrace, up its stair between the chortens"),
         ("s3_pema_o_hall", "In its hall: Guru Rinpoche, his consorts, the altar's lamps, the monks' rows"),
         ("s3_pema_lama_lip", "07:47: Lama Orgyen Dorje at the terrace's lip, the juniper burning, the first sun"),
         ("s3_pema_monks_service", "08:10: the service, the monks on their rows, the lama on his seat"),
         ("s3_pema_kora_woman", "06:35: an old woman on the kora, the 36 wheels turning under her hand"),
         ("s3_v02_mist", "07:30: V-02 before the first sun, the mist on the pool"),
         ("s3_v02_conch", "07:55: the white water and the gold side by side, the conch's glint in the eddy")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The rivers and the confluence (M2 sprint 5): the water, the Conch Fall, Pema Ö Lhakhang, V-02 at first sun.", font=FONT, fill=(40, 30, 25))
    for i, (name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(TERRAIN, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(TERRAIN, "confluence_sheet.jpg")
    img.save(path, quality=88)
    print("confluence_sheet: %s" % path)


if __name__ == "__main__":
    main()
