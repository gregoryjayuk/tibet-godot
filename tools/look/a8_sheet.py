#!/usr/bin/env python3
"""Lay out art step A8's ridge shadow for Greg: one sheet, three rows. The draft street set down at Tsongra from the
street (viewpoint 1) and from above (viewpoint 5), 15:50 to 16:30 (the real ridge takes Tsongra at 16:09); then the
real valley from above the west bank, 15:30 to 17:00, the shadow climbing the monastery's spur.
Run: tools/py tools/look/a8_sheet.py   Writes tests/look/out/a8_sheet.jpg.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "look", "out")
VALLEY = os.path.join(ROOT, "tests", "terrain", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 22)
STREET = [("1550", "15:50"), ("1604", "16:04"), ("1607", "16:07"), ("1609", "16:09, the shadow at Tsongra"), ("1611", "16:11"), ("1630", "16:30")]
RIDGE = [("1530", "15:30"), ("1550", "15:50"), ("1600", "16:00"), ("1610", "16:10"), ("1620", "16:20"), ("1640", "16:40, the crest alone"), ("1700", "17:00")]


def main():
    w, h, pad, cap = 480, 270, 10, 34
    cols = max(len(STREET), len(RIDGE))
    rows = [("The street (viewpoint 1)", [os.path.join(OUT, "a8_v1_%s.png" % t) for t, _ in STREET], [l for _, l in STREET]),
            ("From above (viewpoint 5)", [os.path.join(OUT, "a8_v5_%s.png" % t) for t, _ in STREET], [l for _, l in STREET]),
            ("The real valley from the west bank", [os.path.join(VALLEY, "s3_ridge_%s.png" % t) for t, _ in RIDGE], [l for _, l in RIDGE])]
    img = Image.new("RGB", (cols * (w + pad) + pad, 56 + len(rows) * (h + cap + 40 + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Art step A8: the ridge shadow, 28 October 1903. The street is set down at Tsongra; the valley is the real ground, unsculpted.", font=FONT, fill=(40, 30, 25))
    y = 56
    for title, paths, labels in rows:
        d.text((pad, y + 6), title, font=FONT, fill=(40, 30, 25))
        y += 40
        for i, (p, label) in enumerate(zip(paths, labels)):
            x = pad + i * (w + pad)
            img.paste(Image.open(p).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
            d.text((x, y + h + 4), label, font=FONT, fill=(40, 30, 25))
        y += h + cap + pad
    path = os.path.join(OUT, "a8_sheet.jpg")
    img.save(path, quality=86)
    print("a8_sheet: " + path)


if __name__ == "__main__":
    main()
