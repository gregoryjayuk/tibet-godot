#!/usr/bin/env python3
"""The story's ground (M2 sprint 1): mission 1, the letter, given at Achak Dolkar's gateway or behind her Tibetan
room's shut door at dusk; mission 3, the agent's price carried to Yang Shouren in the sleeve or aloud; the ledger.
Stills: `STILLS=1 tools/player/s15.sh route letter_open`, `... route letter_private`, `... route message_aloud`, and
RETURN_FOCUS=0 TIMEOUT=400 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --only=ledger_page
Run: tools/py tools/town/story_sheet.py   Writes tests/player/out/story_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLAYER = os.path.join(ROOT, "tests", "player", "out")
TERRAIN = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SHOTS = [(PLAYER, "s15_letter_open_01_greeting", "16:30, Dechen-tsang's gateway: Achak Dolkar's greeting, and what to do with the letter"),
         (PLAYER, "s15_letter_open_02_given", "Given in the open: the Han clerk passing sees it, Yang Shouren hears within the hour"),
         (PLAYER, "s15_letter_private_01_greeting", "17:42, her Tibetan room, the door shut, no one else by"),
         (PLAYER, "s15_letter_private_03_after", "Given behind the door: only she knows"),
         (PLAYER, "s15_message_aloud_choice", "Day 2, mission 3: the agent's price to Yang Shouren, in the sleeve or aloud"),
         (TERRAIN, "s3_ledger_page", "The ledger (L): errands, debts, notes, words in their script, the purse")]


def main():
    w, h, pad, cap = 960, 540, 10, 30
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    img = Image.new("RGB", (pad + cols * (w + pad), 56 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "The story's ground (M2 sprint 1): saves, conversations, people's memory, the ledger; missions 1 and 3 of The guarantee.", font=FONT, fill=(40, 30, 25))
    for i, (folder, name, label) in enumerate(SHOTS):
        x = pad + (i % cols) * (w + pad)
        y = 56 + (i // cols) * (h + cap + pad)
        img.paste(Image.open(os.path.join(folder, name + ".png")).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
    path = os.path.join(PLAYER, "story_sheet.jpg")
    img.save(path, quality=88)
    print("story_sheet: %s" % path)


if __name__ == "__main__":
    main()
