#!/usr/bin/env python3
"""M1's reference stills against chapter 09's polish checklist (17): the checks a script can make (sprint 8, step 8).
- PC-06: no pure black or white: under 0.2% of the pixels at 255 or at 0 in every channel.
- PC-09: how much of the frame is strongly coloured (OKLCh chroma over 0.15), and a map of where (tests/m1/out/
  chroma_<still>.png: those pixels in their colour, the rest grey), to see by eye that it is flags, textiles, gold and
  flames.
- PC-01: the squint test, by a script: blurred over 8 px, the luminance in masses (k-means, masses closer than 0.08 in
  value merged) that hold 3% of the frame or more: at most five. A proxy for the eye's squint, no more.
- PC-28: the budgeted settings (QT-BAL, 1920 x 1080), PC-29: 5 s with no pipeline compiled before the shot, PC-30: the
  sidecar's metadata (viewpoint, game time, weather, commit): from each still's sidecar (tests/terrain/s3.gd --meta).
The rest are judged by eye: docs/m1/reference-stills.md.
Stills: TIMEOUT=900 ENGINE_ARGS="res://tests/terrain/s3.tscn" tools/run_windowed.sh --shots --town --people --meta --only=caravan_gate,tsongra_1600,dechen_tibetan_people,slice_stair_foot,slice_v14,guide_ladder,v28_dusk,v28_moon
Run: tools/py tools/look/polish_check.py   Prints the table; writes tests/m1/out/ref_sheet.jpg and the chroma maps.
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHOTS = os.path.join(ROOT, "tests", "terrain", "out")
OUT = os.path.join(ROOT, "tests", "m1", "out")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
# M1's eight reference stills (docs/PLAN.md, sprint 8, step 8; chapter 12, 4.2's walks)
STILLS = [("RS-1", "caravan_gate", "The Yak Gate at 15:25: CV-02 coming through (walk 1)"),
          ("RS-2", "tsongra_1600", "Tsongra at 16:00 among the twenty (walk 2)"),
          ("RS-3", "dechen_tibetan_people", "Dechen-tsang's Tibetan room at tea (walk 3)"),
          ("RS-4", "slice_stair_foot", "Up the Sky Stair through the gateway chorten (walk 4)"),
          ("RS-5", "slice_v14", "The top of the Sky Stair: lower Shöl below (walk 4, V-14)"),
          ("RS-6", "guide_ladder", "The child of the house leading up the Rooftop Way (walk 5)"),
          ("RS-7", "v28_dusk", "V-28 at 17:07: the sang, the roof people (walk 5)"),
          ("RS-8", "v28_moon", "V-28 at 17:40: the half moon, the blue hour (walk 5)")]


def srgb_to_linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def oklab(rgb):
    """sRGB (0-1) to OKLab (Björn Ottosson's matrices)."""
    lin = srgb_to_linear(rgb)
    lms = lin @ np.array([[0.4122214708, 0.2119034982, 0.0883024619],
                          [0.5363325363, 0.6806995451, 0.2817188376],
                          [0.0514459929, 0.1073969566, 0.6299787005]])
    lms = np.cbrt(lms)
    return lms @ np.array([[0.2104542553, 1.9779984951, 0.0259040371],
                           [0.7936177850, -2.4285922050, 0.7827717662],
                           [-0.0040720468, 0.4505937099, -0.8086757660]])


def masses(lum, k=6, iters=20):
    """The squint test's value masses: k-means on the blurred luminance, near centres merged, masses of 3% or more."""
    v = lum.reshape(-1)
    cs = np.quantile(v, np.linspace(0.05, 0.95, k))
    for _ in range(iters):
        lab = np.argmin(np.abs(v[:, None] - cs[None, :]), axis=1)
        for j in range(k):
            if np.any(lab == j):
                cs[j] = v[lab == j].mean()
    order = np.argsort(cs)
    groups = []  # merge centres closer than 0.08
    for j in order:
        if groups and abs(cs[j] - groups[-1][0]) < 0.08:
            groups[-1][1].append(j)
        else:
            groups.append([cs[j], [j]])
    shares = [np.isin(lab, g[1]).mean() for g in groups]
    return sum(1 for s in shares if s >= 0.03)


def main():
    os.makedirs(OUT, exist_ok=True)
    rows = []
    tiles = []
    for rid, name, label in STILLS:
        png = os.path.join(SHOTS, "s3_%s.png" % name)
        if not os.path.exists(png):
            print("polish_check: %s missing (%s)" % (rid, png))
            continue
        side = os.path.join(SHOTS, "s3_%s.json" % name)
        meta = json.load(open(side)) if os.path.exists(side) else {}
        im = Image.open(png).convert("RGB")
        a = np.asarray(im).astype(np.float64) / 255.0
        white = np.all(a >= 254.5 / 255.0, axis=2).mean()
        black = np.all(a <= 0.5 / 255.0, axis=2).mean()
        lab = oklab(a.reshape(-1, 3)).reshape(a.shape)
        chroma = np.sqrt(lab[..., 1] ** 2 + lab[..., 2] ** 2)
        strong = chroma > 0.15
        grey = np.repeat(lab[..., :1], 3, axis=2)
        cmap = np.where(strong[..., None], a, grey * 0.9)
        Image.fromarray((np.clip(cmap, 0, 1) * 255).astype(np.uint8)).resize((960, 540)).save(os.path.join(OUT, "chroma_%s.png" % rid))
        blur = im.filter(ImageFilter.BoxBlur(8)).resize((480, 270))
        lum = np.asarray(blur.convert("L")).astype(np.float64) / 255.0
        n_masses = masses(lum)
        tier_ok = meta.get("tier") == "QT-BAL" and meta.get("size") == [1920, 1080]
        quiet_ok = int(meta.get("quiet_frames", 0)) >= 150
        meta_ok = all(k in meta for k in ("station", "clock", "weather", "commit")) and meta.get("commit", "none") != "none"
        rows.append((rid, name, meta.get("clock", "?"), white, black, strong.mean(), n_masses, tier_ok, quiet_ok, meta_ok))
        tiles.append((rid, label, im))
    print("| still | station | at | PC-06 white/black (<0.2%) | PC-09 chroma>0.15 | PC-01 masses (<=5) | PC-28 | PC-29 | PC-30 |")
    print("|---|---|---|---|---|---|---|---|---|")
    for rid, name, clock, w, b, c, n, t, q, m in rows:
        pc06 = "%s %.2f%% / %.2f%%" % ("pass" if w + b < 0.002 else "FAIL", 100 * w, 100 * b)
        print("| %s | %s | %s | %s | %.1f%% | %s %d | %s | %s | %s |" % (rid, name, clock, pc06, 100 * c, "pass" if n <= 5 else "FAIL", n,
              "pass" if t else "FAIL", "pass" if q else "FAIL", "pass" if m else "FAIL"))
    if tiles:  # the sheet: the eight, two across
        w, h, pad, cap = 960, 540, 10, 30
        rows_n = (len(tiles) + 1) // 2
        sheet = Image.new("RGB", (pad + 2 * (w + pad), 56 + rows_n * (h + cap + pad)), (250, 248, 243))
        d = ImageDraw.Draw(sheet)
        d.text((pad, 14), "M1's eight reference stills (sprint 8, step 8), at QT-BAL, 1920 x 1080.", font=FONT, fill=(40, 30, 25))
        for i, (rid, label, im) in enumerate(tiles):
            x = pad + (i % 2) * (w + pad)
            y = 56 + (i // 2) * (h + cap + pad)
            sheet.paste(im.resize((w, h), Image.LANCZOS), (x, y))
            d.text((x, y + h + 4), "%s  %s" % (rid, label), font=FONT, fill=(40, 30, 25))
        path = os.path.join(OUT, "ref_sheet.jpg")
        sheet.save(path, quality=88)
        print("polish_check: %s" % path)


if __name__ == "__main__":
    main()
