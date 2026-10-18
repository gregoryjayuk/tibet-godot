#!/usr/bin/env python3
"""Sitting cross-legged (ISS-088) and H-SHL-142's household (ISS-105; plan chapter 04, 4.2): the guest on a Tibetan bench
or a poor house's floor sits cross-legged (the bodies' Sitting_Cross, the library's Meditate); the households and Ngodrup
sit so on their benches; the poor grandmother spins by her door all day, sits by the fire at dusk, and pours a guest the
thin tea from her copper ladle, crouched at the log's end.
Stills: for each of house_tea_142, house_tea and tea, `RETURN_FOCUS=0 TEA_VIEW=third STILLS=1 HOUR=14 tools/player/s15.sh
route <route>` renamed s15_<route>_third_*.png, then `RETURN_FOCUS=0 STILLS=1 HOUR=14 tools/player/s15.sh route
house_tea_142`; and RETURN_FOCUS=0 TIMEOUT=500 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots
--town --people --only=house_142_back,house_142_dusk,house_007_in,dechen_tibetan_people
Run: tools/py tools/player/cross_tea_sheet.py   Writes tests/player/out/cross_tea_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLAYER = os.path.join(ROOT, "tests", "player", "out")
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [(PLAYER, "s15_house_tea_142_third_05_pouring", "H-SHL-142: the grandmother pours the thin tea from the ladle; the guest cross-legged behind the log"),
         (PLAYER, "s15_house_tea_142_05_pouring", "The guest's own view: the ladle over the bowl on the log, the fire beyond"),
         (TERRAIN, "s3_house_142_back", "15:00: she spins standing by the door"),
         (TERRAIN, "s3_house_142_dusk", "18:00: by the fire, cross-legged; the lamp in the niche lit"),
         (PLAYER, "s15_house_tea_third_05_pouring", "H-SHL-007: the guest cross-legged on the bench, the grandmother pouring"),
         (PLAYER, "s15_tea_third_05_pouring", "Dechen-tsang's Tibetan room: the guest cross-legged on the guest bench"),
         (TERRAIN, "s3_dechen_tibetan_people", "Ngodrup cross-legged at the head of the Tibetan room"),
         (TERRAIN, "s3_house_007_in", "H-SHL-007's grandmother cross-legged on her bench, spinning")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Sitting cross-legged (ISS-088), and the poor family's grandmother at home (ISS-105; chapter 04, 4.2).", font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(PLAYER, "cross_tea_sheet.jpg")
    img.save(path, quality=88)
    print("cross_tea_sheet: %s" % path)


if __name__ == "__main__":
    main()
