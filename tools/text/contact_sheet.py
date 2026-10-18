#!/usr/bin/env python3
"""Lay spike S4's images side by side for Greg: one sheet per row of tests/text/strings.json, with the five Godot
routes (UI label, Label3D with MSDF at 1 m and 20 m, the baked texture at 1 m and 20 m) cropped round the text and
captioned, plus one overview of every row.

Run with the project's Python:  tools/py tools/text/contact_sheet.py
Writes tests/text/out/sheets/<id>.png and tests/text/out/sheets/all.png.
"""
import json
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "tests/text/out/godot")
OUT = os.path.join(ROOT, "tests/text/out/sheets")
ROUTES = [("ui", "UI label (40, 72, 120 px; long lines fitted)"), ("msdf_1m", "Label3D, MSDF, 1 m"), ("msdf_20m", "Label3D, MSDF, 20 m"),
          ("baked_1m", "Baked texture, 1 m"), ("baked_20m", "Baked texture, 20 m")]
CELL = (900, 380)
CAPTION = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 22)
TITLE = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 28)


def crop_to_ink(img, margin=24):
    """Crop a shot to its ink (the dark text) plus a margin, so the letters fill the sheet's cell."""
    g = img.convert("L").point(lambda v: 255 if v < 120 else 0)
    box = g.getbbox()
    if box is None:
        return img
    x0, y0, x1, y1 = box
    return img.crop((max(0, x0 - margin), max(0, y0 - margin), min(img.width, x1 + margin), min(img.height, y1 + margin)))


def row_sheet(row):
    w = CELL[0] * len(ROUTES) + 20 * (len(ROUTES) + 1)
    sheet = Image.new("RGB", (w, CELL[1] + 120), (250, 248, 243))
    d = ImageDraw.Draw(sheet)
    d.text((20, 14), f"{row['id']} · {row['why']}", font=TITLE, fill=(40, 30, 25))
    for k, (route, label) in enumerate(ROUTES):
        path = os.path.join(SRC, f"{row['id']}_{route}.png")
        x = 20 + k * (CELL[0] + 20)
        if not os.path.exists(path):
            d.text((x, 80), f"{label}: missing", font=CAPTION, fill=(180, 30, 30))
            continue
        img = crop_to_ink(Image.open(path).convert("RGB"))
        s = min(CELL[0] / img.width, CELL[1] / img.height)
        img = img.resize((max(1, int(img.width * s)), max(1, int(img.height * s))), Image.LANCZOS)
        sheet.paste(img, (x, 70))
        d.text((x, 80 + CELL[1] - 10), label, font=CAPTION, fill=(60, 50, 45))
    return sheet


def main():
    os.makedirs(OUT, exist_ok=True)
    rows = json.load(open(os.path.join(ROOT, "tests/text/strings.json"), encoding="utf-8"))["rows"]
    sheets = []
    for r in rows:
        s = row_sheet(r)
        s.save(os.path.join(OUT, f"{r['id']}.png"))
        sheets.append(s)
    allh = sum(s.height for s in sheets)
    overview = Image.new("RGB", (sheets[0].width, allh), (250, 248, 243))
    y = 0
    for s in sheets:
        overview.paste(s, (0, y))
        y += s.height
    overview.thumbnail((2400, 99999), Image.LANCZOS)
    overview.save(os.path.join(OUT, "all.png"))
    print(f"contact_sheet: {len(rows)} row sheets and all.png in {OUT}")


if __name__ == "__main__":
    main()
