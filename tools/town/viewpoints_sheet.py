#!/usr/bin/env python3
"""The slice's viewpoints for Greg (IMP-021 (5), IMP-024; his 1780, "a peaceful moment"): sat at each, the camera drifted
out to its composed frame, the walker in its foreground.
Stills: RETURN_FOCUS=0 STILLS=1 tools/player/s15.sh route viewpoints   (each at its hour, data/viewpoints.json)
Run: tools/py tools/town/viewpoints_sheet.py   Writes tests/player/out/viewpoints_sheet.jpg.
"""
import json
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "player", "out")
FONT_F = os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf")


def main():
    views = json.load(open(os.path.join(ROOT, "data", "viewpoints.json")))["views"]
    w, h, cap, pad = 900, 506, 34, 10
    f = ImageFont.truetype(FONT_F, 22)
    big = ImageFont.truetype(FONT_F, 26)
    rows = (len(views) + 1) // 2
    img = Image.new("RGB", (pad + 2 * (w + pad), 60 + rows * (h + cap + pad)), (250, 248, 243))
    d = ImageDraw.Draw(img)
    d.text((pad, 16), "Viewpoints (IMP-021 (5), after 1780): sit (C) at one and the camera drifts out to its frame", font=big, fill=(40, 30, 25))
    for i, v in enumerate(views):
        x = pad + (i % 2) * (w + pad)
        y = 60 + (i // 2) * (h + cap + pad)
        path = os.path.join(OUT, "s15_viewpoint_%s.png" % v["id"].lower().replace("-", ""))
        if os.path.exists(path):
            img.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
        hh, mm = int(v["hour"]), int(round((v["hour"] % 1) * 60))
        d.text((x, y + h + 5), "%s, %s at %02d:%02d" % (v["id"], v["name"], hh, mm), font=f, fill=(40, 30, 25))
    path = os.path.join(OUT, "viewpoints_sheet.jpg")
    img.save(path, quality=86)
    print("viewpoints_sheet: %s" % path)


if __name__ == "__main__":
    main()
