#!/usr/bin/env python3
"""Bake text to textures with Pillow + libraqm (HarfBuzz shaping), the "baked" route of the plan (chapter 11, 17.3).

Inscriptions in the world (mani stones, lintels, wheel drums, name boards, shop boards, couplets) are rendered once at
build time, because a texture looks the same on every machine. Chinese couplets are laid out top to bottom here, which
Godot's Label cannot do. The tool refuses to run without raqm: without it Pillow falls back to basic layout, which
cannot stack Tibetan.

Run with the project's Python:  tools/py tools/text/bake_text.py tests/text/strings.json tests/text/out/baked
Writes <id>_<size>.png for each row at each size (dark ink on transparent), plus <id>_vertical.png where a row asks
for a vertical bake.
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont, features

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FONTS = {
    "tibetan": os.path.join(ROOT, "assets/source/fonts/jomolhari/Jomolhari-Regular.ttf"),
    "chinese": os.path.join(ROOT, "assets/source/fonts/ar-pl-ukai/ukai.ttc"),  # Kai, the brushiest of three faces (Greg, 25 Sep)
}
FACES = {"chinese": 2}  # ukai.ttc holds four faces, CN, HK, TW and TW MBE; the TW one
LANG = {"tibetan": "bo", "chinese": "zh-Hant"}
INK = (30, 22, 18, 255)
SIZES = [48, 96, 160]
PAD = 0.35  # of the font size, round the text


def bake(text, script, size, direction="ltr", wrap_em=0):
    font = ImageFont.truetype(FONTS[script], size, index=FACES.get(script, 0), layout_engine=ImageFont.Layout.RAQM)
    lines = [text]
    if wrap_em:
        lines = wrap(text, font, wrap_em * size, script)
    kw = {"direction": direction, "language": LANG[script]}
    boxes = [ImageDraw.Draw(Image.new("L", (1, 1))).textbbox((0, 0), ln, font=font, **kw) for ln in lines]
    pad = int(size * PAD)
    line_h = int(size * 1.6)
    if direction == "ttb":
        w = max(b[2] - b[0] for b in boxes) + 2 * pad
        h = max(b[3] - b[1] for b in boxes) + 2 * pad
    else:
        w = max(b[2] - b[0] for b in boxes) + 2 * pad
        h = line_h * (len(lines) - 1) + (boxes[-1][3] - min(0, boxes[-1][1])) + 2 * pad
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, (ln, b) in enumerate(zip(lines, boxes)):
        d.text((pad - b[0], pad - min(0, b[1]) + i * line_h), ln, font=font, fill=INK, **kw)
    return img


def wrap(text, font, width, script):
    """Break after a tsheg or space (Tibetan) when a line would pass `width` pixels."""
    d = ImageDraw.Draw(Image.new("L", (1, 1)))
    tokens, cur = [], ""
    for ch in text:
        cur += ch
        if ch in "་ །":
            tokens.append(cur)
            cur = ""
    if cur:
        tokens.append(cur)
    lines, line = [], ""
    for t in tokens:
        if line and d.textlength(line + t, font=font, language=LANG[script]) > width:
            lines.append(line.rstrip())
            line = t.lstrip()
        else:
            line += t
    if line:
        lines.append(line.rstrip())
    return lines


def main():
    if not features.check("raqm"):
        sys.exit("bake_text: Pillow has no raqm here; it cannot shape Tibetan stacks. Use tools/py (docs/VENDOR.md).")
    spec, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    rows = json.load(open(spec, encoding="utf-8"))["rows"]
    for r in rows:
        for size in SIZES:
            img = bake(r["text"], r["script"], size, wrap_em=r.get("wrap_em", 0))
            img.save(os.path.join(out, f"{r['id']}_{size}.png"))
        if r.get("vertical_bake"):
            bake(r["vertical_bake"], r["script"], 96, direction="ttb").save(os.path.join(out, f"{r['id']}_vertical.png"))
    print(f"bake_text: {len(rows)} rows x {len(SIZES)} sizes -> {out}")


if __name__ == "__main__":
    main()
